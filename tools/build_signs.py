"""Build game/assets/objects/signs.png: hanging shop and door signs (ADR 0023, M16.3).

Usage (PowerShell, from repo root):
    python tools/build_signs.py            # write the sheet
    python tools/build_signs.py --print    # print the regions for game/data/objects.json "signs"
    python tools/build_signs.py --check     # fail if objects.json "signs" does not match ICONS

The sheet is one row of cells, each SIGN_W x SIGN_H px, one per icon in ICONS order, then one empty cell
("none"). A sign is a small iron bracket, two chains and a wooden board with a 14 px icon in the middle.
The icons are drawn here from pixel maps (no outside art). Not book text; original pixel art.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_OUT = ROOT / "game" / "assets" / "objects" / "signs.png"
OBJECTS_JSON = ROOT / "game" / "data" / "objects.json"
SIGN_W = 24
SIGN_H = 28
ICON = 14  # px, the square the icon is centred in
BOARD_TOP = 6
NONE = "none"

PALETTE: dict[str, tuple[int, int, int, int]] = {
    "k": (40, 30, 28, 255),  # outline
    "w": (244, 240, 226, 255),  # white / foam / highlight
    "y": (232, 184, 56, 255),  # gold
    "o": (196, 128, 60, 255),  # crust / orange
    "n": (110, 68, 36, 255),  # dark brown
    "g": (150, 154, 164, 255),  # steel
    "l": (206, 212, 224, 255),  # light steel
    "b": (56, 96, 170, 255),  # blue
    "r": (188, 56, 48, 255),  # red
    "e": (78, 138, 68, 255),  # green
}

# Pixel maps. '.' is empty; rows may differ in length (padded right), the shape is centred in the icon square.
ICONS: dict[str, list[str]] = {
    "bread": [
        "..nnnnnnnn..",
        ".noooooooon.",
        "nooyooyooyon",
        "noooooooooon",
        "noooooooooon",
        ".noooooooon.",
        "..nnnnnnnn..",
    ],
    "mug": [
        ".wwwwwww....",
        "wwwwwwwww...",
        "kyyyyyyyk...",
        "kyyyyyyyk.gg",
        "kyyyyyyyk.g.g",
        "kyyyyyyyk.g.g",
        "kyyyyyyyk.gg",
        "kyyyyyyyk...",
        ".kkkkkkk....",
    ],
    "bed": [
        "nn............",
        "nnwwwbbbbbbbbb",
        "nnwwwbbbbbbbbb",
        "nnnnnnnnnnnnnn",
        "nn..........nn",
        "nn..........nn",
    ],
    "anvil": [
        "lllllllllllll.",
        "gggggggggggggg",
        ".kggggggggkkk.",
        "...kggggggk...",
        "....kggggk....",
        "...kkggggkk...",
        "..kkkkkkkkkk..",
    ],
    "potion": [
        "...nnn....",
        "...kwk....",
        "...kwk....",
        "..kwwwk...",
        ".krrrrrk..",
        ".krwrrrk..",
        ".krrrrrk..",
        "..kkkkk...",
    ],
    "badge": [
        "kkkkkkkkkkk",
        "kbbbbbbbbbk",
        "kbbbbybbbbk",
        "kbbbyyybbbk",
        "kbbbbybbbbk",
        ".kbbbbbbbk.",
        "..kbbbbbk..",
        "...kbbbk...",
        "....kkk....",
    ],
    "coin": [
        "..kkkkkk..",
        ".kyyyyyyk.",
        "kyywyyyyok",
        "kyywyyyyok",
        "kyyyyyyyok",
        "kyyyyyyyok",
        ".kyyyyook.",
        "..kkkkkk..",
    ],
    "home": [
        "....rrr....",
        "...rrrrr...",
        "..rrrrrrr..",
        ".rrrrrrrrr.",
        "rrrrrrrrrrr",
        ".wwwwwwwww.",
        ".wwwnnnwww.",
        ".wwwnnnwww.",
        ".wwwnnnwww.",
    ],
    "closed": [
        "rr......rr",
        ".rr....rr.",
        "..rr..rr..",
        "...rrrr...",
        "....rr....",
        "...rrrr...",
        "..rr..rr..",
        ".rr....rr.",
        "rr......rr",
    ],
    "outhouse": [
        "nnnnnnnnnn",
        "noooooooon",
        "nooyyyooon",
        "noyoooooon",
        "noyoooooon",
        "nooyyyooon",
        "noooooooon",
        "nnnnnnnnnn",
    ],
}

IRON = (58, 52, 50, 255)
CHAIN = (120, 118, 116, 255)
WOOD = (176, 132, 78, 255)
WOOD_LIGHT = (204, 160, 100, 255)
WOOD_DARK = (138, 98, 56, 255)
EDGE = (60, 40, 24, 255)


def names() -> list[str]:
    """Icon ids in sheet order, then NONE."""
    return list(ICONS) + [NONE]


def region(name: str) -> list[int]:
    """[x, y, w, h] in pixels of `name` on the sheet."""
    return [names().index(name) * SIGN_W, 0, SIGN_W, SIGN_H]


def draw_icon(img: Image.Image, rows: list[str], ox: int, oy: int) -> None:
    """Paint a pixel map centred in the ICON square whose top-left is (ox, oy)."""
    w = max(len(r) for r in rows)
    h = len(rows)
    x0 = ox + (ICON - w) // 2
    y0 = oy + (ICON - h) // 2
    px = img.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != "." and ch in PALETTE:
                px[x0 + x, y0 + y] = PALETTE[ch]


def draw_sign(name: str) -> Image.Image:
    """One sign cell: bracket, chains, board, icon."""
    img = Image.new("RGBA", (SIGN_W, SIGN_H), (0, 0, 0, 0))
    px = img.load()
    for x in range(SIGN_W):
        px[x, 0] = IRON
        px[x, 1] = IRON
    for x in (4, 19):
        for y in range(2, BOARD_TOP):
            px[x, y] = CHAIN
    for y in range(BOARD_TOP, SIGN_H):
        for x in range(1, SIGN_W - 1):
            edge = y in (BOARD_TOP, SIGN_H - 1) or x in (1, SIGN_W - 2)
            if edge:
                px[x, y] = EDGE
            elif y == BOARD_TOP + 1:
                px[x, y] = WOOD_LIGHT
            elif y == SIGN_H - 2:
                px[x, y] = WOOD_DARK
            else:
                px[x, y] = WOOD
    if name in ICONS:
        draw_icon(img, ICONS[name], (SIGN_W - ICON) // 2, BOARD_TOP + 4)
    return img


def render() -> Image.Image:
    order = names()
    sheet = Image.new("RGBA", (SIGN_W * len(order), SIGN_H), (0, 0, 0, 0))
    for i, name in enumerate(order):
        if name != NONE:
            sheet.paste(draw_sign(name), (i * SIGN_W, 0))
    return sheet


def check() -> list[str]:
    """Problems between ICONS and game/data/objects.json "signs" (empty = fine)."""
    data = json.loads(OBJECTS_JSON.read_text(encoding="utf-8"))
    have = data.get("signs", {})
    errors = []
    for name in names():
        if have.get(name) != region(name):
            errors.append(f"signs.{name}: objects.json has {have.get(name)}, sheet has {region(name)}")
    for name in have:
        if name not in names():
            errors.append(f"signs.{name}: no such icon in build_signs.py")
    return errors


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--print", action="store_true", dest="show")
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args(argv)
    if args.show:
        print(json.dumps({n: region(n) for n in names()}))
        return 0
    if args.check:
        errors = check()
        for e in errors:
            print(e)
        return 1 if errors else 0
    args.out.parent.mkdir(parents=True, exist_ok=True)
    render().save(args.out)
    print(f"wrote {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
