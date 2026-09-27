"""Build one character sheet per look in game/data/appearance.json (ADR 0018).

Usage (PowerShell, from repo root):
    python tools/build_sprites.py --ulpc <path to a Universal-LPC-Spritesheet-Character-Generator clone>
    python tools/build_sprites.py --ulpc <path> --only player,relc

The LPC generator repo is not part of this repo. A part clone is enough:
    git clone --depth 1 --filter=blob:none --sparse <repo url> ulpc
    git -C ulpc sparse-checkout set --no-cone /CREDITS.csv /LICENSE /palette_definitions/ /sheet_definitions/
    git -C ulpc sparse-checkout add /spritesheets/<folder of each part used>/

appearance.json:
    {"schema_version": 1, "looks": {id: look}}
    look = {"body": "male", "skin": "light", "base": "body",
            "parts": [{"part": "<sheet definition name>", "color": "<palette colour>"}]}
    body   LPC body type: male, female, muscular, teen, child (picks each part's folder)
    skin   body colour (palette name, "green" or "ulpc.green"); parts made of skin use it
    base   the body part, default "body" (a skeleton look uses "body_skeleton")
    parts  drawn in LPC zPos order, whatever order they are listed in
The id is an NPC id, an enemy type, or "player". The game draws
game/assets/characters/<id>.png for it, and a square when there is none.

Sheet layout (64×64 frames, rows up/left/down/right as in LPC):
    rows 0-3   walk  9 frames (frame 0 = standing)
    rows 4-7   slash 6 frames
    row  8     hurt  6 frames (the fall)
    rows 9-12  idle  2 frames

The credits of every LPC file used go into CREDITS.md between the
build_sprites markers. Exit code 0 = built, 1 = errors.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image

FRAME = 64
# (animation, frames, rows) in sheet order.
ANIMS = [("walk", 9, 4), ("slash", 6, 4), ("hurt", 6, 1), ("idle", 2, 4)]
COLUMNS = 9
ROWS = sum(r for _, _, r in ANIMS)
SCHEMES = ["ulpc", "lpcr"]
TOLERANCE = 1
BEGIN = "<!-- build_sprites:begin -->"
END = "<!-- build_sprites:end -->"

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_APPEARANCE = ROOT / "game" / "data" / "appearance.json"
DEFAULT_OUT = ROOT / "game" / "assets" / "characters"
DEFAULT_CREDITS = ROOT / "CREDITS.md"


class BuildError(Exception):
    pass


def anim_offsets() -> dict[str, int]:
    """Animation → first row in the sheet."""
    out, row = {}, 0
    for name, _, rows in ANIMS:
        out[name] = row
        row += rows
    return out


class Ulpc:
    """Reads sheet definitions, palettes and sprite files from an LPC generator clone."""

    def __init__(self, root: Path):
        self.root = Path(root)
        self.defs: dict[str, dict] = {}
        for f in sorted((self.root / "sheet_definitions").rglob("*.json")):
            if f.name.startswith("meta_"):
                continue
            self.defs[f.stem] = json.loads(f.read_text(encoding="utf-8"))
        self._palettes: dict[str, dict] = {}

    def definition(self, name: str) -> dict:
        if name not in self.defs:
            raise BuildError(f"unknown LPC part '{name}'")
        return self.defs[name]

    def material_meta(self, material: str) -> dict:
        f = self.root / "palette_definitions" / material / f"meta_{material}.json"
        return json.loads(f.read_text(encoding="utf-8")) if f.exists() else {}

    def palette(self, material: str, colour: str) -> list[tuple[int, int, int]]:
        """Colours of `colour` ("green" or "ulpc.green") in `material`."""
        scheme, _, name = colour.rpartition(".")
        for s in [scheme] if scheme else SCHEMES:
            key = f"{material}_{s}"
            if key not in self._palettes:
                f = self.root / "palette_definitions" / material / f"{key}.json"
                self._palettes[key] = json.loads(f.read_text(encoding="utf-8")) if f.exists() else {}
            if name in self._palettes[key]:
                return [hex_rgb(h) for h in self._palettes[key][name]]
        raise BuildError(f"no colour '{colour}' in palette '{material}'")

    def commit(self) -> str:
        try:
            r = subprocess.run(["git", "-C", str(self.root), "rev-parse", "HEAD"],
                               capture_output=True, text=True, check=True)
            return r.stdout.strip()
        except (OSError, subprocess.CalledProcessError):
            return "unknown"


def hex_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def recolor(img: Image.Image, src: list, dst: list) -> Image.Image:
    """Swaps each colour of `src` (±TOLERANCE per channel) for the same index of `dst`."""
    pairs = list(zip(src, dst))

    def swap(rgb):
        for s, d in pairs:
            if all(abs(a - b) <= TOLERANCE for a, b in zip(rgb[:3], s)):
                return d
        return None

    if img.mode == "P":
        pal = img.getpalette() or []
        for i in range(0, len(pal) - 2, 3):
            d = swap(pal[i:i + 3])
            if d:
                pal[i:i + 3] = list(d)
        img = img.copy()
        img.putpalette(pal)
        return img.convert("RGBA")
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a:
                d = swap((r, g, b))
                if d:
                    px[x, y] = (*d, a)
    return img


def part_layers(ulpc: Ulpc, part: dict, look: dict) -> list[dict]:
    """The layers of one part: [{"z", "dir", "material", "src", "dst", "colour"}]."""
    name = part["part"]
    d = ulpc.definition(name)
    body = look.get("body", "male")
    recolors = d.get("recolors", {})
    material = recolors.get("material") or ("body" if d.get("match_body_color") else "")
    colour = part.get("color") or (look.get("skin", "") if material == "body" else "")
    out = []
    for key in sorted(k for k in d if k.startswith("layer_")):
        layer = d[key]
        if body not in layer:
            raise BuildError(f"part '{name}' has no '{body}' body in {key}")
        folder = ulpc.root / "spritesheets" / layer[body]
        src = dst = None
        if colour and material and not variant_folder(folder):
            meta = ulpc.material_meta(material)
            base = recolors.get("base") or f"{meta.get('default', 'ulpc')}.{meta.get('base', '')}"
            src = ulpc.palette(material, base)
            dst = ulpc.palette(material, colour)
        out.append({"z": int(layer.get("zPos", 0)), "dir": folder, "rel": layer[body].rstrip("/"),
                    "src": src, "dst": dst, "colour": colour, "part": name})
    return out


def variant_folder(folder: Path) -> bool:
    """True when the part keeps one file per colour (walk/<colour>.png)."""
    return (folder / "walk").is_dir()


def load_anim(layer: dict, anim: str) -> Image.Image | None:
    folder: Path = layer["dir"]
    if variant_folder(folder):
        f = folder / anim / f"{layer['colour']}.png"
        if not layer["colour"]:
            raise BuildError(f"part '{layer['part']}' needs a color")
        if (folder / "walk").is_dir() and not (folder / "walk" / f"{layer['colour']}.png").exists():
            raise BuildError(f"part '{layer['part']}' has no colour '{layer['colour']}'")
    else:
        f = folder / f"{anim}.png"
    if not f.exists():
        return None
    img = Image.open(f)
    if layer["src"]:
        return recolor(img, layer["src"], layer["dst"])
    return img.convert("RGBA")


def build_look(ulpc: Ulpc, look: dict) -> tuple[Image.Image, list[str]]:
    """The sheet for one look, and the LPC folders it used."""
    parts = [{"part": look.get("base", "body")}] + list(look.get("parts", []))
    layers = []
    for i, p in enumerate(parts):
        for layer in part_layers(ulpc, p, look):
            layers.append((layer["z"], i, layer))
    layers.sort(key=lambda t: (t[0], t[1]))
    sheet = Image.new("RGBA", (COLUMNS * FRAME, ROWS * FRAME), (0, 0, 0, 0))
    rows = anim_offsets()
    used = []
    for _, _, layer in layers:
        used.append(layer["rel"])
        for anim, frames, nrows in ANIMS:
            img = load_anim(layer, anim)
            if img is None:
                continue
            img = img.crop((0, 0, frames * FRAME, nrows * FRAME))
            piece = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
            piece.paste(img, (0, rows[anim] * FRAME))
            sheet = Image.alpha_composite(sheet, piece)
    return sheet, used


def credits_for(ulpc: Ulpc, parts: set[str], used: set[str]) -> list[dict]:
    """Credit entries of the used parts whose file is (a prefix of) a used folder."""
    seen, out = set(), []
    for name in sorted(parts):
        for c in ulpc.definition(name).get("credits", []):
            f = c.get("file", "").rstrip("/")
            if not any(u == f or u.startswith(f + "/") for u in used):
                continue
            if f in seen:
                continue
            seen.add(f)
            out.append(c)
    return sorted(out, key=lambda c: c.get("file", ""))


def credits_block(entries: list[dict], commit: str) -> str:
    lines = [BEGIN,
             "Built by `tools/build_sprites.py` from the Universal LPC Spritesheet Character Generator",
             f"(https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator, commit `{commit}`).",
             "The sheets in `game/assets/characters/` combine these files. Do not edit this block by hand.",
             ""]
    for c in entries:
        lines.append(f"- `{c.get('file', '')}` by {', '.join(c.get('authors', []))}."
                     f" Licence: {' / '.join(c.get('licenses', []))}.")
        for u in c.get("urls", []):
            lines.append(f"  - {u}")
        if c.get("notes"):
            lines.append(f"  - Notes: {c['notes']}")
    lines.append(END)
    return "\n".join(lines)


def write_credits(path: Path, block: str) -> None:
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    if BEGIN in text and END in text:
        head, _, rest = text.partition(BEGIN)
        _, _, tail = rest.partition(END)
        text = head + block + tail
    else:
        text = (text.rstrip("\n") + "\n\n" if text else "# Credits\n\n") + block + "\n"
    path.write_text(text, encoding="utf-8", newline="\r\n" if "\r\n" in text else None)


def build(ulpc_dir: Path, appearance: Path, out_dir: Path, credits: Path,
          only: set[str] | None = None) -> list[str]:
    """Builds the sheets; returns the errors (empty = all built)."""
    ulpc = Ulpc(ulpc_dir)
    data = json.loads(appearance.read_text(encoding="utf-8"))
    looks: dict = data.get("looks", {})
    errors, used, parts = [], set(), set()
    out_dir.mkdir(parents=True, exist_ok=True)
    for look_id in sorted(looks):
        look = looks[look_id]
        try:
            sheet, folders = build_look(ulpc, look)
        except BuildError as e:
            errors.append(f"{look_id}: {e}")
            continue
        used.update(folders)
        parts.add(look.get("base", "body"))
        parts.update(p["part"] for p in look.get("parts", []))
        if only is None or look_id in only:
            sheet.save(out_dir / f"{look_id}.png")
    if not errors:
        write_credits(credits, credits_block(credits_for(ulpc, parts, used), ulpc.commit()))
    return errors


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ulpc", required=True, type=Path)
    ap.add_argument("--appearance", type=Path, default=DEFAULT_APPEARANCE)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--credits", type=Path, default=DEFAULT_CREDITS)
    ap.add_argument("--only", default="", help="comma-separated look ids to write (credits still cover all)")
    a = ap.parse_args(argv)
    only = {s for s in a.only.split(",") if s} or None
    errors = build(a.ulpc, a.appearance, a.out, a.credits, only)
    for e in errors:
        print("ERROR", e)
    print(f"{len(errors)} errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
