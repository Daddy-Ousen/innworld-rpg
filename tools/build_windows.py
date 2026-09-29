"""Build game/assets/tiles/windows.png: a wall cell with a window (ADR 0026, M16.6.4).

Usage (PowerShell, from repo root):
    python tools/build_windows.py

The sheet is one 32 px cell: the plank wall cell of game/assets/objects/lpc_interior.png (cell 0,3, the
`wood_wall` tile) with a small window painted over it: dark outline, wood frame, sky glass, a cross bar and
a highlight. Original pixel art on top of the existing wall; no outside art. Not book text.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "game" / "assets" / "objects" / "lpc_interior.png"
DEFAULT_OUT = ROOT / "game" / "assets" / "tiles" / "windows.png"
CELL = 32
WALL_CELL = (0, 3)  # the `wood_wall` tile in tiles.json
WINDOW = (9, 7, 14, 17)  # x, y, w, h of the window in the cell

OUTLINE = (50, 33, 37, 255)
FRAME = (161, 124, 80, 255)
BAR = (137, 111, 66, 255)
GLASS = (118, 168, 200, 255)
GLASS_LIGHT = (176, 212, 230, 255)
SILL = (200, 160, 100, 255)


def render(source: Path = SOURCE) -> Image.Image:
    sheet = Image.open(source).convert("RGBA")
    x0, y0 = WALL_CELL[0] * CELL, WALL_CELL[1] * CELL
    cell = sheet.crop((x0, y0, x0 + CELL, y0 + CELL))
    x, y, w, h = WINDOW
    for j in range(y, y + h):
        for i in range(x, x + w):
            edge = i in (x, x + w - 1) or j in (y, y + h - 1)
            frame = i in (x + 1, x + w - 2) or j in (y + 1, y + h - 2)
            cell.putpixel((i, j), OUTLINE if edge else FRAME if frame else GLASS)
    cx, cy = x + w // 2, y + h // 2
    for i in range(x + 2, x + w - 2):  # cross bar
        cell.putpixel((i, cy), BAR)
    for j in range(y + 2, y + h - 2):
        cell.putpixel((cx, j), BAR)
    for k in range(3):  # highlight in the top-left pane
        cell.putpixel((x + 3 + k, y + 3 + k), GLASS_LIGHT)
        cell.putpixel((x + 4 + k, y + 3 + k), GLASS_LIGHT)
    for i in range(x - 1, x + w + 1):  # sill under the frame
        cell.putpixel((i, y + h), SILL)
        cell.putpixel((i, y + h + 1), OUTLINE)
    return cell


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = ap.parse_args(argv)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    render().save(args.out)
    print(f"wrote {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
