"""Build game/assets/objects/edits.png: map object art that no LPC pack has (ADR 0018, M11.1).

Usage (PowerShell, from repo root):
    python tools/build_objects.py            # write edits.png
    python tools/build_objects.py --check    # exit 1 if objects.json and the layout disagree

Each edit is a small pixel edit of LPC art already in game/assets (a table, a tree, a flame)
or simple shapes drawn in the LPC palette. Edits of CC-BY-SA art are CC-BY-SA too (CREDITS.md).
The layout is fixed: the edits sit side by side in EDITS order, each in a box of its own size,
bottom-aligned at y = HEIGHT. game/data/objects.json names an edit with
{"sheet": "edits", "region": layout()[name]} (the region of a "frames" edit is frame 0; the
other frames follow to the right). --check compares the two.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "game" / "assets"
DEFAULT_OUT = ASSETS / "objects" / "edits.png"
DEFAULT_OBJECTS = ROOT / "game" / "data" / "objects.json"
HEIGHT = 128

# LPC-like colours.
OUTLINE = (40, 28, 20, 255)
WOOD = (133, 88, 52, 255)
WOOD_DARK = (92, 58, 34, 255)
WOOD_LIGHT = (170, 120, 72, 255)
IRON = (58, 58, 64, 255)
IRON_LIGHT = (104, 104, 112, 255)
STEEL = (150, 150, 158, 255)
STEEL_LIGHT = (196, 196, 204, 255)
PAPER = (232, 224, 196, 255)
INK = (90, 80, 70, 255)
STRAW = (208, 170, 84, 255)
STRAW_DARK = (160, 120, 50, 255)
HONEY = (232, 170, 40, 255)
HONEY_DARK = (170, 106, 20, 255)
HONEY_LIGHT = (252, 214, 110, 255)
WAX = (120, 76, 22, 255)
BLUE_FRUIT = (70, 110, 220, 255)
BLUE_FRUIT_LIGHT = (150, 190, 255, 255)
CLOTH = (84, 104, 140, 255)
CLOTH_DARK = (56, 70, 98, 255)
CLOTH_LIGHT = (122, 144, 180, 255)
MAT = (150, 60, 50, 255)
MAT_LIGHT = (196, 110, 80, 255)
BONE = (226, 218, 194, 255)
CAP = (96, 176, 214, 255)
CAP_LIGHT = (196, 236, 250, 255)
CAP_DARK = (56, 112, 156, 255)


def sheet(rel: str) -> Image.Image:
    return Image.open(ASSETS / rel).convert("RGBA")


def crop(rel: str, box: tuple[int, int, int, int]) -> Image.Image:
    x, y, w, h = box
    return sheet(rel).crop((x, y, x + w, y + h))


def canvas(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def wheel(d: ImageDraw.ImageDraw, cx: int, cy: int, r: int) -> None:
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=WOOD_DARK, outline=OUTLINE)
    d.ellipse((cx - r + 3, cy - r + 3, cx + r - 3, cy + r - 3), outline=WOOD_LIGHT)
    d.line((cx - r + 2, cy, cx + r - 2, cy), fill=WOOD)
    d.line((cx, cy - r + 2, cx, cy + r - 2), fill=WOOD)
    d.rectangle((cx - 1, cy - 1, cx + 1, cy + 1), fill=IRON)


def wagon() -> Image.Image:
    """A cart: the long tavern table top as the bed, two wheels and a shaft."""
    img, d = canvas(96, 56)
    d.line((0, 34, 12, 34), fill=OUTLINE, width=3)
    d.line((0, 34, 12, 34), fill=WOOD_LIGHT, width=1)
    bed = crop("objects/tavern_furniture.png", (192, 208, 96, 22))
    img.alpha_composite(bed.resize((80, 22)), (10, 16))
    d.rectangle((10, 12, 89, 17), fill=WOOD_DARK, outline=OUTLINE)  # back rail
    d.rectangle((10, 36, 89, 40), fill=WOOD_DARK, outline=OUTLINE)  # side board
    wheel(d, 26, 44, 11)
    wheel(d, 74, 44, 11)
    return img


def chess_table() -> Image.Image:
    """The round tavern table with the chessboard from the tavern deco on it."""
    img, _ = canvas(64, 44)
    img.alpha_composite(crop("objects/tavern_furniture.png", (320, 192, 64, 42)), (0, 2))
    img.alpha_composite(crop("objects/tavern_deco.png", (355, 70, 27, 21)), (18, 4))
    return img


def market_stall() -> Image.Image:
    """The long tavern table with food from the tavern deco on it."""
    img, _ = canvas(96, 48)
    img.alpha_composite(crop("objects/tavern_furniture.png", (192, 208, 96, 40)), (0, 8))
    deco = "objects/tavern_deco.png"
    for i, (x, y) in enumerate([(0, 800), (96, 800), (160, 800), (192, 800)]):
        img.alpha_composite(crop(deco, (x, y, 32, 32)), (4 + i * 22, 0))
    return img


def notice_board() -> Image.Image:
    """Two posts, a framed board and pinned notes."""
    img, d = canvas(48, 56)
    d.rectangle((6, 20, 9, 55), fill=WOOD_DARK, outline=OUTLINE)
    d.rectangle((38, 20, 41, 55), fill=WOOD_DARK, outline=OUTLINE)
    d.rectangle((2, 4, 45, 40), fill=WOOD_DARK, outline=OUTLINE)
    d.rectangle((5, 7, 42, 37), fill=WOOD)
    for x, y, w, h in [(8, 10, 10, 12), (21, 9, 9, 10), (32, 12, 8, 11), (12, 25, 11, 9), (27, 23, 10, 11)]:
        d.rectangle((x, y, x + w, y + h), fill=PAPER, outline=INK)
        for ly in range(y + 3, y + h - 1, 3):
            d.line((x + 2, ly, x + w - 2, ly), fill=INK)
        d.point((x + w // 2, y + 1), fill=(200, 40, 40, 255))
    return img


def broom() -> Image.Image:
    img, d = canvas(16, 40)
    d.line((8, 1, 8, 26), fill=OUTLINE, width=3)
    d.line((8, 1, 8, 26), fill=WOOD_LIGHT, width=1)
    d.polygon([(4, 26), (12, 26), (15, 39), (1, 39)], fill=STRAW, outline=STRAW_DARK)
    for x in (4, 7, 10, 13):
        d.line((8, 27, x, 38), fill=STRAW_DARK)
    d.line((4, 28, 12, 28), fill=WOOD_DARK)
    return img


def horseshoe() -> Image.Image:
    img, d = canvas(20, 18)
    d.arc((2, 1, 18, 17), 180, 360, fill=OUTLINE, width=5)
    d.arc((3, 2, 17, 16), 180, 360, fill=STEEL, width=3)
    for x in (2, 14):
        d.rectangle((x, 9, x + 4, 16), fill=OUTLINE)
        d.rectangle((x + 1, 9, x + 3, 15), fill=STEEL)
    d.point((10, 3), fill=STEEL_LIGHT)
    d.point((5, 7), fill=IRON)
    d.point((15, 7), fill=IRON)
    return img


def _comb(d: ImageDraw.ImageDraw, x0: int, y0: int, cols: int, rows: int) -> None:
    for r in range(rows):
        for c in range(cols):
            x = x0 + c * 7 + (3 if r % 2 else 0)
            y = y0 + r * 6
            d.regular_polygon((x + 3, y + 3, 4), 6, fill=HONEY, outline=HONEY_DARK)
            d.point((x + 2, y + 2), fill=HONEY_LIGHT)


def honeycomb() -> Image.Image:
    """A slab of honeycomb on a cave wall."""
    img, d = canvas(32, 32)
    d.ellipse((1, 3, 31, 31), fill=WAX, outline=OUTLINE)
    _comb(d, 5, 7, 3, 4)
    return img


def bee_nest() -> Image.Image:
    """A huge nest: stacked combs in a waxy shell."""
    img, d = canvas(64, 64)
    d.ellipse((2, 6, 62, 63), fill=WAX, outline=OUTLINE)
    d.ellipse((6, 2, 58, 30), fill=WAX, outline=OUTLINE)
    _comb(d, 10, 8, 6, 8)
    d.ellipse((26, 48, 38, 58), fill=OUTLINE)
    return img


def fruit_tree() -> Image.Image:
    """The small atlas tree with blue fruit (the Floodplains blue fruit)."""
    img, d = canvas(64, 96)
    img.alpha_composite(crop("tiles/lpc_atlas.png", (864, 928, 64, 96)), (0, 0))
    for x, y in [(14, 20), (30, 12), (44, 22), (22, 34), (38, 38), (50, 34), (12, 44), (28, 48)]:
        d.ellipse((x, y, x + 5, y + 5), fill=BLUE_FRUIT, outline=OUTLINE)
        d.point((x + 1, y + 1), fill=BLUE_FRUIT_LIGHT)
    return img


def dead_tree() -> Image.Image:
    """A bare tree: no leaves, a forked trunk and branches drawn in the LPC wood colours.
    The roots come from the big atlas tree (its trunk is the only non-leaf part)."""
    img, d = canvas(96, 128)

    def limb(pts: list[tuple[int, int]], width: int) -> None:
        d.line(pts, fill=OUTLINE, width=width + 2, joint="curve")
        d.line(pts, fill=WOOD, width=width, joint="curve")
        d.line([(x - 1, y) for x, y in pts], fill=WOOD_LIGHT, width=max(1, width // 3), joint="curve")

    limb([(48, 112), (47, 88), (46, 64), (48, 44)], 9)  # trunk
    limb([(47, 84), (34, 70), (24, 50), (20, 36)], 5)  # left fork
    limb([(24, 52), (12, 46)], 3)
    limb([(30, 62), (30, 44), (34, 30)], 3)
    limb([(47, 66), (62, 54), (72, 40), (76, 24)], 5)  # right fork
    limb([(72, 42), (86, 38)], 3)
    limb([(62, 54), (64, 36), (58, 22)], 3)
    limb([(48, 46), (46, 28), (48, 12)], 4)  # crown
    limb([(46, 32), (38, 20)], 2)
    limb([(48, 26), (56, 14)], 2)
    src = crop("tiles/lpc_atlas.png", (928, 896, 96, 128))
    px = src.load()
    for y in range(100, src.height):
        for x in range(src.width):
            r, g, b, a = px[x, y]
            if a and not (g > r and g > b):  # trunk and roots, not leaves
                img.putpixel((x, y), (r, g, b, a))
    return img


def bedroll() -> Image.Image:
    img, d = canvas(28, 44)
    d.rectangle((2, 8, 25, 43), fill=CLOTH, outline=OUTLINE)
    d.line((5, 12, 5, 40), fill=CLOTH_LIGHT)
    d.line((22, 12, 22, 40), fill=CLOTH_DARK)
    d.rounded_rectangle((0, 1, 27, 12), radius=5, fill=CLOTH_DARK, outline=OUTLINE)
    d.line((3, 5, 24, 5), fill=CLOTH_LIGHT)
    d.rectangle((9, 0, 11, 13), fill=WOOD_DARK)
    d.rectangle((17, 0, 19, 13), fill=WOOD_DARK)
    return img


def mat() -> Image.Image:
    img, d = canvas(32, 24)
    d.rectangle((1, 2, 30, 21), fill=MAT, outline=OUTLINE)
    for y in range(5, 20, 3):
        d.line((3, y, 28, y), fill=MAT_LIGHT)
    for y in (2, 21):
        for x in range(2, 30, 3):
            d.point((x, y), fill=STRAW)
    return img


def rope_anchor() -> Image.Image:
    """A stake with the wall rope from the house interior tied to it."""
    img, d = canvas(32, 40)
    d.polygon([(13, 8), (19, 8), (18, 38), (14, 38)], fill=WOOD, outline=OUTLINE)
    d.line((14, 10, 14, 36), fill=WOOD_LIGHT)
    img.alpha_composite(crop("objects/lpc_interior.png", (230, 224, 22, 32)), (5, 6))
    return img


def brazier(frame: int) -> Image.Image:
    """An iron bowl on three legs; the flame is one frame of the tavern cooking fire."""
    img, d = canvas(32, 48)
    for x0, x1 in [(9, 5), (16, 16), (23, 27)]:
        d.line((x0, 30, x1, 47), fill=OUTLINE, width=3)
        d.line((x0, 30, x1, 46), fill=IRON_LIGHT, width=1)
    flame = crop("objects/tavern_cooking.png", (384 + 32 * frame, 0, 32, 32))
    img.alpha_composite(flame, (0, 2))
    d.pieslice((4, 18, 28, 38), 0, 180, fill=IRON, outline=OUTLINE)
    d.rectangle((4, 26, 28, 29), fill=IRON_LIGHT, outline=OUTLINE)
    return img


def stone_doors() -> Image.Image:
    """The atlas arched double doors, recoloured to stone, dark behind the bars."""
    door = crop("tiles/lpc_atlas.png", (544, 682, 64, 54))
    img, d = canvas(64, 54)
    d.rounded_rectangle((4, 6, 59, 53), radius=10, fill=(24, 22, 28, 255))
    px = door.load()
    for y in range(door.height):
        for x in range(door.width):
            r, g, b, a = px[x, y]
            if a:
                v = (r + g + b) // 3
                px[x, y] = (v + 40, v + 40, v + 46, a)
    img.alpha_composite(door)
    return img


# name → (width, height, [frames]) in layout order. Never reorder: objects.json uses the regions.
def cobweb() -> Image.Image:
    """A web in a corner: threads fan out from the top-left corner, joined by sagging arcs."""
    img, d = canvas(32, 32)
    thread = (226, 226, 232, 220)
    tips = [(31, 2), (29, 11), (23, 21), (14, 28), (3, 31)]
    for tx, ty in tips:
        d.line((0, 0, tx, ty), fill=thread)
    for r in (9, 17, 25):
        pts = [(round(tx * r / 31), round(ty * r / 31)) for tx, ty in tips]
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            mx, my = (ax + bx) // 2 - 1, (ay + by) // 2 - 1
            d.line((ax, ay, mx, my), fill=thread)
            d.line((mx, my, bx, by), fill=thread)
    return img


def bones() -> Image.Image:
    """Two crossed bones and a small skull, on the floor."""
    img, d = canvas(32, 20)
    for a, b in [((3, 15), (22, 8)), ((4, 8), (24, 17))]:
        d.line((*a, *b), fill=OUTLINE, width=4)
        d.line((*a, *b), fill=BONE, width=2)
        for x, y in (a, b):
            d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=BONE, outline=OUTLINE)
    d.ellipse((17, 1, 29, 11), fill=BONE, outline=OUTLINE)
    d.rectangle((20, 9, 26, 13), fill=BONE, outline=OUTLINE)
    for x, y in [(21, 5), (21, 6), (25, 5), (25, 6)]:
        d.point((x, y), fill=OUTLINE)
    return img


def glow_mushrooms() -> Image.Image:
    """Three cave mushrooms with pale blue caps."""
    img, d = canvas(32, 28)
    for cx, top, w in [(9, 10, 8), (20, 4, 10), (26, 15, 6)]:
        d.rectangle((cx - 1, top + 6, cx + 1, 26), fill=BONE, outline=OUTLINE)
        d.pieslice((cx - w, top, cx + w, top + 14), 180, 360, fill=CAP, outline=OUTLINE)
        d.point((cx - w // 2, top + 4), fill=CAP_LIGHT)
        d.point((cx + w // 3, top + 3), fill=CAP_LIGHT)
        d.line((cx - w + 1, top + 7, cx + w - 1, top + 7), fill=CAP_DARK)
    return img


EDITS: list[tuple[str, list]] = [
    ("wagon", [wagon]),
    ("chess_table", [chess_table]),
    ("market_stall", [market_stall]),
    ("notice_board", [notice_board]),
    ("broom", [broom]),
    ("horseshoe", [horseshoe]),
    ("honeycomb", [honeycomb]),
    ("bee_nest", [bee_nest]),
    ("fruit_tree", [fruit_tree]),
    ("dead_tree", [dead_tree]),
    ("bedroll", [bedroll]),
    ("mat", [mat]),
    ("rope_anchor", [rope_anchor]),
    ("brazier", [lambda f=f: brazier(f) for f in range(4)]),
    ("stone_doors", [stone_doors]),
    ("cobweb", [cobweb]),
    ("bones", [bones]),
    ("glow_mushrooms", [glow_mushrooms]),
]


def render() -> tuple[Image.Image, dict[str, list[int]]]:
    """The edits sheet and name → [x, y, w, h] (frame 0)."""
    parts = []
    for name, makers in EDITS:
        frames = [m() for m in makers]
        parts.append((name, frames))
    width = sum(f[0].width * len(f) for _, f in parts)
    out = Image.new("RGBA", (width, HEIGHT), (0, 0, 0, 0))
    layout: dict[str, list[int]] = {}
    x = 0
    for name, frames in parts:
        w, h = frames[0].size
        if h > HEIGHT:
            raise ValueError(f"{name}: taller than {HEIGHT}")
        layout[name] = [x, HEIGHT - h, w, h]
        for f in frames:
            out.alpha_composite(f, (x, HEIGHT - h))
            x += w
    return out, layout


def check(objects_path: Path, layout: dict[str, list[int]]) -> list[str]:
    """Errors where objects.json names an edit that is not in the layout, or a wrong region."""
    data = json.loads(objects_path.read_text(encoding="utf-8"))
    errs = []
    for kind, art in data.get("kinds", {}).items():
        for key in ("region", "winter_region"):
            if art.get("sheet") != "edits" or key not in art:
                continue
            name = kind
            if name not in layout:
                errs.append(f"objects.json kind '{kind}': no edit '{name}' in tools/build_objects.py")
            elif art[key] != layout[name]:
                errs.append(f"objects.json kind '{kind}': {key} {art[key]} != edits layout {layout[name]}")
    return errs


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--objects", type=Path, default=DEFAULT_OBJECTS)
    ap.add_argument("--check", action="store_true", help="only compare objects.json with the layout")
    ap.add_argument("--print", action="store_true", help="print the layout as JSON")
    a = ap.parse_args(argv)
    img, layout = render()
    if a.print:
        print(json.dumps(layout))
    if not a.check:
        a.out.parent.mkdir(parents=True, exist_ok=True)
        img.save(a.out)
        print(f"wrote {a.out} ({img.width}x{img.height}, {len(layout)} edits)")
    errs = check(a.objects, layout) if a.objects.exists() else []
    for e in errs:
        print(f"ERROR {e}")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
