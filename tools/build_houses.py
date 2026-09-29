"""Build game/assets/tiles/houses.png: house pieces made from the LPC house sheet (ADR 0023, M16.2).

Usage (PowerShell, from repo root):
    python tools/build_houses.py

The sheet is a row of blocks, each 5 cells wide and 4 high (BLOCK_W, BLOCK_H). A block holds one house style:
    row 0  roof, top edge:  left end, middle, right end
    row 1  roof, fill:      left end, middle, right end
    row 2  wall, upper:     left end, middle, right end, window, door top
    row 3  wall, lower:     left end, middle, right end, (middle), door
The game picks the piece from the cell's place in the house (game/world/ground_art.gd `house_piece`).
Styles (STYLES): stone (Drake city), brick (human city), plain (village), ruin (broken walls, no roof). Blocks
0..3 are summer, blocks 4..7 the same styles with snow on the roofs. game/data/tiles.json names a block with
{"sheet": "houses", "block": [block * 5, 0]}. Walls, windows and doors are cut from lpc_house.png; roofs are
drawn from its slate shingle cell. Edits of CC-BY-SA art are CC-BY-SA too (CREDITS.md).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "game" / "assets" / "tiles"
SOURCE = ASSETS / "lpc_house.png"
DEFAULT_OUT = ASSETS / "houses.png"
CELL = 32
BLOCK_W = 5
BLOCK_H = 4
STYLES = ("stone", "brick", "plain", "ruin")

# Piece columns.
LEFT, MID, RIGHT, WINDOW, DOOR = range(5)

Px = tuple[int, int, int, int]
Palette = tuple[tuple[int, int, int], tuple[int, int, int], tuple[int, int, int]]  # dark, mid, light

ROOF_PALETTES: dict[str, Palette] = {
    "stone": ((38, 40, 56), (84, 88, 108), (132, 136, 156)),  # slate
    "brick": ((70, 30, 24), (138, 62, 44), (190, 108, 74)),  # clay tile
    "plain": ((80, 60, 30), (150, 118, 62), (204, 174, 104)),  # thatch
}
SNOW_PALETTE: Palette = ((120, 134, 158), (208, 220, 236), (246, 250, 255))
PLASTER: Palette = ((104, 84, 60), (196, 178, 140), (232, 220, 190))
DOOR_H = 48  # px: an LPC door is a cell and a half high
ROOF_EDGE = 3  # px of outline on a roof end
SHADOW = 4  # px of eave shadow at the top of an upper wall


def lum(px: Px) -> float:
    return 0.3 * px[0] + 0.59 * px[1] + 0.11 * px[2]


def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (int(a[0] + (b[0] - a[0]) * t), int(a[1] + (b[1] - a[1]) * t), int(a[2] + (b[2] - a[2]) * t))


def tint(img: Image.Image, pal: Palette) -> Image.Image:
    """Recolour by brightness: dark pixels get pal[0], middle pal[1], light pal[2]."""
    out = img.copy()
    data = []
    for px in img.getdata():
        if px[3] == 0:
            data.append(px)
            continue
        t = min(1.0, max(0.0, lum(px) / 200.0))
        c = lerp(pal[0], pal[1], t * 2) if t < 0.5 else lerp(pal[1], pal[2], (t - 0.5) * 2)
        data.append((*c, px[3]))
    out.putdata(data)
    return out


def darken(img: Image.Image, k: float, rows: range | None = None, cols: range | None = None) -> None:
    px = img.load()
    for y in rows or range(img.height):
        for x in cols or range(img.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (int(r * k), int(g * k), int(b * k), a)


def lighten(img: Image.Image, k: float, rows: range | None = None, cols: range | None = None) -> None:
    px = img.load()
    for y in rows or range(img.height):
        for x in cols or range(img.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (min(255, int(r + (255 - r) * k)), min(255, int(g + (255 - g) * k)), min(255, int(b + (255 - b) * k)), a)


def cell(sheet: Image.Image, x: int, y: int) -> Image.Image:
    return sheet.crop((x * CELL, y * CELL, (x + 1) * CELL, (y + 1) * CELL))


def over(base: Image.Image, top: Image.Image) -> Image.Image:
    out = base.copy()
    out.alpha_composite(top)
    return out


def roof_pieces(sheet: Image.Image, pal: Palette) -> dict[str, Image.Image]:
    """Roof top (t*) and fill (f*) pieces, each left / middle / right, from the slate shingle cell."""
    shingle = tint(cell(sheet, 1, 5), pal)
    out: dict[str, Image.Image] = {}
    edge = tuple(int(c * 0.55) for c in pal[0])
    for row, name in ((0, "t"), (1, "f")):
        for col in (LEFT, MID, RIGHT):
            img = shingle.copy()
            px = img.load()
            for y in range(CELL):
                for x in range(CELL):
                    on_left = col == LEFT and x < ROOF_EDGE
                    on_right = col == RIGHT and x >= CELL - ROOF_EDGE
                    on_top = row == 0 and y < ROOF_EDGE
                    if on_left or on_right or on_top:
                        px[x, y] = (*edge, 255)
            # a light ridge line inside the outline
            if row == 0:
                lighten(img, 0.35, rows=range(ROOF_EDGE, ROOF_EDGE + 3),
                        cols=range(ROOF_EDGE if col == LEFT else 0, CELL - (ROOF_EDGE if col == RIGHT else 0)))
            if col == LEFT:
                lighten(img, 0.3, cols=range(ROOF_EDGE, ROOF_EDGE + 2), rows=range(ROOF_EDGE if row == 0 else 0, CELL))
            if col == RIGHT:
                darken(img, 0.8, cols=range(CELL - ROOF_EDGE - 4, CELL - ROOF_EDGE), rows=range(CELL))
            out[f"{name}{col}"] = img
    return out


def brick_walls(sheet: Image.Image) -> dict[str, Image.Image]:
    """Red brick with sandstone corner blocks; stone base course on the lower row."""
    # the end cells have see-through corners: put them on the middle piece so a house is opaque
    up = {col: over(cell(sheet, 1, 1), cell(sheet, col, 1)) for col in (LEFT, MID, RIGHT)}
    low = {col: over(cell(sheet, 1, 2), cell(sheet, col, 2)) for col in (LEFT, MID, RIGHT)}
    return _wall_set(sheet, up, low, door_image(sheet, 3))


def door_image(sheet: Image.Image, col: int) -> Image.Image:
    """The LPC door at sheet column `col`: 32 wide and 48 high (a cell and a half)."""
    return sheet.crop((col * CELL, 0, (col + 1) * CELL, DOOR_H))


def _wall_set(sheet: Image.Image, up: dict[int, Image.Image], low: dict[int, Image.Image],
              door: Image.Image) -> dict[str, Image.Image]:
    """The door stands on the ground line: its top 16 px show at the bottom of the upper wall cell."""
    door_top = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    door_top.paste(door.crop((0, 0, CELL, DOOR_H - CELL)), (0, CELL - (DOOR_H - CELL)))
    door_low = door.crop((0, DOOR_H - CELL, CELL, DOOR_H))
    window = over(up[MID], cell(sheet, 7, 0))
    out: dict[str, Image.Image] = {}
    for col in (LEFT, MID, RIGHT):
        out[f"u{col}"] = up[col].copy()
        out[f"l{col}"] = low[col].copy()
    out[f"u{WINDOW}"] = window
    out[f"l{WINDOW}"] = low[MID].copy()
    out[f"u{DOOR}"] = over(up[MID], door_top)
    out[f"l{DOOR}"] = over(low[MID], door_low)
    for col in (LEFT, MID, RIGHT, WINDOW, DOOR):
        darken(out[f"u{col}"], 0.62, rows=range(0, SHADOW))  # eave shadow
    return out


def flat_walls(sheet: Image.Image, fill: Image.Image, foot: Image.Image) -> dict[str, Image.Image]:
    """Walls from a plain fill cell: dark outline on the ends, a footing on the lower row."""
    up: dict[int, Image.Image] = {}
    low: dict[int, Image.Image] = {}
    for col in (LEFT, MID, RIGHT):
        u = fill.copy()
        lo = foot.copy()
        for img in (u, lo):
            if col == LEFT:
                darken(img, 0.45, cols=range(0, 2))
                lighten(img, 0.25, cols=range(2, 4))
            if col == RIGHT:
                darken(img, 0.45, cols=range(CELL - 2, CELL))
                darken(img, 0.8, cols=range(CELL - 6, CELL - 2))
        up[col] = u
        low[col] = lo
    return _wall_set(sheet, up, low, door_image(sheet, 5))


def stone_walls(sheet: Image.Image) -> dict[str, Image.Image]:
    fill = cell(sheet, 4, 4)
    foot = cell(sheet, 4, 6).copy()
    darken(foot, 0.75, rows=range(CELL - 5, CELL))
    return flat_walls(sheet, fill, foot)


def plain_walls(sheet: Image.Image) -> dict[str, Image.Image]:
    """Plaster from the brick cell (recoloured), with a dark timber footing."""
    fill = tint(cell(sheet, 1, 1), PLASTER)
    foot = fill.copy()
    darken(foot, 0.55, rows=range(CELL - 8, CELL))
    walls = flat_walls(sheet, fill, foot)
    # timber posts on the ends, so a village house reads as timber and plaster
    for col in (LEFT, RIGHT):
        for key in (f"u{col}", f"l{col}"):
            darken(walls[key], 0.6, cols=range(0, 6) if col == LEFT else range(CELL - 6, CELL))
    return walls


def ruin_pieces(sheet: Image.Image) -> tuple[dict[str, Image.Image], dict[str, Image.Image]]:
    """Broken stone walls: (roof-row pieces, wall pieces). The top row has a jagged top edge (see-through)."""
    fill = tint(cell(sheet, 4, 4), ((30, 30, 36), (76, 76, 82), (118, 116, 118)))
    foot = fill.copy()
    darken(foot, 0.7, rows=range(CELL - 5, CELL))
    walls = flat_walls(sheet, fill, foot)
    tops: dict[str, Image.Image] = {}
    heights = {LEFT: (18, 12, 14, 20, 16, 8, 6, 10), MID: (10, 14, 6, 8, 16, 18, 12, 9), RIGHT: (12, 6, 10, 14, 22, 16, 20, 18)}
    for col in (LEFT, MID, RIGHT):
        top = walls[f"u{col}"].copy()
        px = top.load()
        hs = heights[col]
        for x in range(CELL):
            cut = hs[x // 4]
            for y in range(cut):
                px[x, y] = (0, 0, 0, 0)
        tops[f"t{col}"] = top
        tops[f"f{col}"] = walls[f"u{col}"].copy()
    return tops, walls


def build_block(sheet: Image.Image, style: str, snow: bool) -> Image.Image:
    if style == "ruin":
        roofs, walls = ruin_pieces(sheet)
    else:
        pal = SNOW_PALETTE if snow else ROOF_PALETTES[style]
        roofs = roof_pieces(sheet, pal)
        walls = {"stone": stone_walls, "brick": brick_walls, "plain": plain_walls}[style](sheet)
    block = Image.new("RGBA", (BLOCK_W * CELL, BLOCK_H * CELL), (0, 0, 0, 0))
    for col in (LEFT, MID, RIGHT):
        block.paste(roofs[f"t{col}"], (col * CELL, 0))
        block.paste(roofs[f"f{col}"], (col * CELL, CELL))
    for col in range(BLOCK_W):
        block.paste(walls[f"u{col}"], (col * CELL, 2 * CELL))
        block.paste(walls[f"l{col}"], (col * CELL, 3 * CELL))
    return block


def render(source: Path = SOURCE) -> Image.Image:
    sheet = Image.open(source).convert("RGBA")
    blocks = [(s, False) for s in STYLES] + [(s, True) for s in STYLES]
    out = Image.new("RGBA", (BLOCK_W * CELL * len(blocks), BLOCK_H * CELL), (0, 0, 0, 0))
    for i, (style, snow) in enumerate(blocks):
        out.paste(build_block(sheet, style, snow), (i * BLOCK_W * CELL, 0))
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    a = ap.parse_args(argv)
    img = render()
    img.save(a.out)
    print(f"wrote {a.out} ({img.width}x{img.height}, {len(STYLES) * 2} blocks)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
