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
    skin   body colour (palette name, "green" or "ulpc.green", or "all.lpcr.lemon" for any
           LPC colour); parts made of skin use it
    base   the body part, default "body" (a skeleton look uses "body_skeleton")
    parts  drawn in LPC zPos order, whatever order they are listed in. A part can also be
           one of our edits (EDITS: innworld_extra_arms, innworld_antennae,
           innworld_mandibles), drawn from the look's body and heads_* part
The id is an NPC id, an enemy type, "player", or "race_<race>" (the look of an
NPC with no own look). The game draws game/assets/characters/<id>.png for it,
and a square when there is none.

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
        """Colours of `colour` ("green", "ulpc.green", or "all.lpcr.lemon" for a
        palette of another material, as the LPC generator's "all.lpcr" list)."""
        bits = colour.split(".")
        if len(bits) == 3:
            material = bits[0]
        scheme, _, name = colour.rpartition(".")
        scheme = scheme.rpartition(".")[2]
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


def layer_sheet(layer: dict) -> Image.Image:
    """One layer laid out as a whole sheet (empty where an animation is missing)."""
    sheet = Image.new("RGBA", (COLUMNS * FRAME, ROWS * FRAME), (0, 0, 0, 0))
    rows = anim_offsets()
    for anim, frames, nrows in ANIMS:
        img = load_anim(layer, anim)
        if img is None:
            continue
        img = img.crop((0, 0, frames * FRAME, nrows * FRAME))
        sheet.paste(img, (0, rows[anim] * FRAME))
    return sheet


def build_look(ulpc: Ulpc, look: dict) -> tuple[Image.Image, list[str]]:
    """The sheet for one look, and the LPC folders it used."""
    parts = [{"part": look.get("base", "body")}] + list(look.get("parts", []))
    layers, edits, used = [], [], []
    body = head = None
    for i, p in enumerate(parts):
        if p["part"] in EDITS:
            edits.append(p["part"])
            continue
        for layer in part_layers(ulpc, p, look):
            img = layer_sheet(layer)
            used.append(layer["rel"])
            layers.append((layer["z"], i, img))
            if i == 0 and body is None:
                body = img
            if p["part"].startswith("heads_") and head is None:
                head = img
    for name in edits:
        z, make = EDITS[name]
        if body is None or head is None:
            raise BuildError(f"edit '{name}' needs a body and a heads_* part")
        layers.append((z, len(parts), make(body, head)))
    layers.sort(key=lambda t: (t[0], t[1]))
    sheet = Image.new("RGBA", (COLUMNS * FRAME, ROWS * FRAME), (0, 0, 0, 0))
    for _, _, img in layers:
        sheet = Image.alpha_composite(sheet, img)
    return sheet, used


# --- Our own edits (Antinium). Drawn from the body and head of the same look.

def frames_of_sheet():
    """(column, row, facing) of every frame in the sheet; the hurt row faces down."""
    dirs = ["n", "w", "s", "e"]
    row = 0
    for anim, frames, nrows in ANIMS:
        for r in range(nrows):
            for c in range(frames):
                yield c, row + r, dirs[r] if nrows == 4 else "s"
        row += nrows


def bbox(img: Image.Image, x0: int, y0: int) -> tuple[int, int, int, int] | None:
    """Opaque box (left, top, right, bottom; inclusive) of the frame at x0, y0."""
    b = img.crop((x0, y0, x0 + FRAME, y0 + FRAME)).getchannel("A").getbbox()
    return None if b is None else (b[0], b[1], b[2] - 1, b[3] - 1)


def shades(img: Image.Image, box: tuple[int, int, int, int]) -> tuple[tuple, tuple]:
    """The darkest colour (the outline) and a lighter colour of the opaque pixels in `box`."""
    px = [p for p in img.crop(box).getdata() if p[3] > 200]
    if not px:
        return (0, 0, 0, 255), (160, 160, 160, 255)
    px.sort(key=lambda p: p[0] + p[1] + p[2])
    return px[0], px[len(px) * 3 // 4]


def _plot(img: Image.Image, x0: int, y0: int, pts, colour) -> None:
    for x, y in pts:
        if 0 <= x < FRAME and 0 <= y < FRAME:
            img.putpixel((x0 + x, y0 + y), colour)


def _outlined(img: Image.Image, x0: int, y0: int, core, rim_colour, core_colour) -> None:
    """`core` pixels with a one-pixel rim round them (8 neighbours)."""
    inside = set(core)
    rim = {(x + dx, y + dy) for x, y in core for dx in (-1, 0, 1) for dy in (-1, 0, 1)} - inside
    _plot(img, x0, y0, sorted(rim), rim_colour)
    _plot(img, x0, y0, sorted(inside), core_colour)


def edit_antennae(body: Image.Image, head: Image.Image) -> Image.Image:
    """Two thin feelers on the top of the head, bent out (to the front from the side)."""
    out = Image.new("RGBA", head.size, (0, 0, 0, 0))
    for c, r, d in frames_of_sheet():
        x0, y0 = c * FRAME, r * FRAME
        b = bbox(head, x0, y0)
        if b is None:
            continue
        dark, _ = shades(head, (x0 + b[0], y0 + b[1], x0 + b[2] + 1, y0 + b[3] + 1))
        cx, top = (b[0] + b[2]) // 2, b[1]
        one = [(0, 0), (-1, -1), (-2, -2), (-3, -3), (-4, -4), (-5, -4)]
        if d in ("s", "n"):
            _plot(out, x0, y0, [(cx - 2 + x, top + 1 + y) for x, y in one], dark)
            _plot(out, x0, y0, [(cx + 2 - x, top + 1 + y) for x, y in one], dark)
        else:
            k = -1 if d == "w" else 1
            _plot(out, x0, y0, [(cx + k * (1 - x), top + 1 + y) for x, y in one], dark)
            _plot(out, x0, y0, [(cx + k * (3 - x), top + 2 + y) for x, y in one[:-1]], dark)
    return out


def edit_mandibles(body: Image.Image, head: Image.Image) -> Image.Image:
    """Two small pincers at the jaw (one from the side, none from behind)."""
    out = Image.new("RGBA", head.size, (0, 0, 0, 0))
    for c, r, d in frames_of_sheet():
        if d == "n":
            continue
        x0, y0 = c * FRAME, r * FRAME
        b = bbox(head, x0, y0)
        if b is None:
            continue
        dark, light = shades(head, (x0 + b[0], y0 + b[1], x0 + b[2] + 1, y0 + b[3] + 1))
        cx, bot = (b[0] + b[2]) // 2, b[3]
        # One long pincer, curving down and in (x grows outward, y down), as a
        # light core with a dark rim. From the front there are two, from the side one.
        core = [(2, -1), (3, 0), (3, 1), (3, 2), (2, 3)]
        if d == "s":
            for k in (-1, 1):
                _outlined(out, x0, y0, [(cx + k * (1 + x), bot - 1 + y) for x, y in core], dark, light)
        else:
            k = -1 if d == "w" else 1
            front = b[0] if d == "w" else b[2]
            _outlined(out, x0, y0, [(front + k * (x - 2), bot - 2 + y) for x, y in core], dark, light)
    return out


ARM_DROP = 6
ARM_OUT = 2


def edit_extra_arms(body: Image.Image, head: Image.Image) -> Image.Image:
    """A second, darker pair of arms under the first: the sides of the body from the
    shoulders to the hips, moved down ARM_DROP px and out ARM_OUT px. Drawn behind
    the body, so only the part below and beside the first pair shows. Front and
    back views only."""
    out = Image.new("RGBA", body.size, (0, 0, 0, 0))
    for c, r, d in frames_of_sheet():
        if d not in ("s", "n"):
            continue
        x0, y0 = c * FRAME, r * FRAME
        hb = bbox(head, x0, y0)
        if hb is None:
            continue
        cx, neck = (hb[0] + hb[2]) // 2, hb[3]
        for y in range(neck + 2, min(neck + 18, FRAME - ARM_DROP)):
            for x in range(FRAME):
                if abs(x - cx) < 5:
                    continue
                p = body.getpixel((x0 + x, y0 + y))
                tx = x + (ARM_OUT if x > cx else -ARM_OUT)
                if p[3] > 0 and 0 <= tx < FRAME:
                    dark = (p[0] * 4 // 5, p[1] * 4 // 5, p[2] * 4 // 5, p[3])
                    out.putpixel((x0 + tx, y0 + y + ARM_DROP), dark)
    return out


# name → (zPos, maker). The body is zPos 10 and heads 100 (LPC).
EDITS = {
    "innworld_extra_arms": (5, edit_extra_arms),
    "innworld_antennae": (105, edit_antennae),
    "innworld_mandibles": (105, edit_mandibles),
}


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
        parts.update(p["part"] for p in look.get("parts", []) if p["part"] not in EDITS)
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
