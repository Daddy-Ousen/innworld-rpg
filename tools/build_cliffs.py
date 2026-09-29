"""Build game/assets/tiles/cliffs.png: cliff pieces made from the LPC Tile Atlas (ADR 0023, M16.1).

Usage (PowerShell, from repo root):
    python tools/build_cliffs.py

The LPC atlas has one earth plateau, 3 cells wide and 4 high, at cell (5, 0): row 0 the top rim,
row 1 the top surface, row 2 the top turning into the face, row 3 the face. Columns 0 and 2 are the
left and right ends. This tool copies it and makes three more looks by recolouring:
    block 0  earth (as it is)          block 1  stone (grey, for caves and dungeons)
    block 2  earth under snow          block 3  stone under snow
Each block is 3 cells wide (BLOCK_W); the sheet is 4 blocks wide and 4 cells high. Edits of CC-BY-SA
art are CC-BY-SA too (CREDITS.md). game/data/tiles.json names a block with {"sheet": "cliffs",
"block": [block * 3, 0]}.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "game" / "assets" / "tiles"
SOURCE = ASSETS / "lpc_atlas.png"
DEFAULT_OUT = ASSETS / "cliffs.png"
CELL = 32
ORIGIN = (5, 0)  # cell of the plateau in lpc_atlas
BLOCK_W = 3
BLOCK_H = 4
LOOKS = ("earth", "stone", "snow_earth", "snow_stone")
# A tan top pixel is lighter than this (0-255 luminance); the brown face is darker.
TOP_LUM = 125


def lum(r: int, g: int, b: int) -> float:
    return 0.3 * r + 0.59 * g + 0.11 * b


def stone(px: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    """Brown to slate grey, cooler and dark: the top surface darker still, so a cave wall is not pale."""
    r, g, b, a = px
    v = lum(r, g, b)
    v *= 0.6 if v >= TOP_LUM else 0.8
    return (min(255, int(v * 0.93)), min(255, int(v * 0.96)), min(255, int(v * 1.08)), a)


def snow(px: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    """A light (top surface) pixel becomes snow; darker pixels (outline, face) stay."""
    r, g, b, a = px
    v = lum(r, g, b)
    if v < TOP_LUM:
        return px
    k = 0.72 + 0.28 * min(1.0, (v - TOP_LUM) / 90.0)
    return (int(228 * k), int(238 * k), int(248 * k), a)


def render(source: Path = SOURCE) -> Image.Image:
    atlas = Image.open(source).convert("RGBA")
    ox, oy = ORIGIN
    base = atlas.crop((ox * CELL, oy * CELL, (ox + BLOCK_W) * CELL, (oy + BLOCK_H) * CELL))
    out = Image.new("RGBA", (BLOCK_W * CELL * len(LOOKS), BLOCK_H * CELL), (0, 0, 0, 0))
    looks = {
        "earth": lambda p: p,
        "stone": stone,
        "snow_earth": snow,
        "snow_stone": lambda p: stone(snow(p)),
    }
    for i, name in enumerate(LOOKS):
        f = looks[name]
        block = Image.new("RGBA", base.size)
        block.putdata([f(p) if p[3] > 0 else p for p in base.getdata()])
        out.paste(block, (i * BLOCK_W * CELL, 0))
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    a = ap.parse_args(argv)
    img = render()
    img.save(a.out)
    print(f"wrote {a.out} ({img.width}x{img.height}, {len(LOOKS)} looks)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
