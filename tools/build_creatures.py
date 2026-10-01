"""Build the sheets of creature looks in game/data/appearance.json (M11.4, ADR 0018).

Usage (PowerShell, from repo root):
    python tools/build_creatures.py
    python tools/build_creatures.py --only snow_golem,rock_crab

A creature look has a "creature" key instead of LPC body parts:
    look = {"creature": "golem", "ramp": ["#1d2a33", ..., "#ffffff"], "hue": 0, "sat": 1.0,
            "val": 1.0, "die": "melt", "confidence": ..., "note": ...}
    creature  a source in CREATURES (the art files in tools/art/creatures/, or "rock_crab"
              "snowman" and "goat", which this tool draws itself)
    ramp      optional: colours dark → light; every pixel takes the ramp colour at its
              brightness (the darkest pixel of the source = the first colour)
    hue       optional: turn the hue by this many degrees; sat and val scale the
              saturation and brightness (after the ramp)
    light     optional: white and pale grey pixels take this colour (kept as light or
              dark as they were), after hue
    die       optional: which fall the source has ("melt" or "crumble" for the golem)

The sheet has the layout of tools/build_sprites.py (768x1088: walk rows 0-3, hurt row 4,
idle rows 5-8 in 64 px frames; the 128 px attack block from y 576), so the game draws a
creature like any character. The creature stands on the bottom middle of each frame.
A source with no fall frames gets a made one: the standing frame sinks and fades.
build_sprites.py skips creature looks. Exit code 0 = built, 1 = errors.
"""

from __future__ import annotations

import argparse
import colorsys
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

import build_sprites as bs

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "tools" / "art" / "creatures"
DIRS = ["n", "w", "s", "e"]
HURT_FRAMES = 6
IDLE_FRAMES = 2


class BuildError(Exception):
    pass


# Source → animation → (file, frame w, frame h, {facing: row}, [columns]).
# LPC order is up, left, down, right; the bird's walk rows are not.
LPC_ROWS = {"n": 0, "w": 1, "s": 2, "e": 3}
CREATURES: dict[str, dict] = {
    "golem": {
        "walk": ("golem-walk.png", 64, 64, LPC_ROWS, list(range(7))),
        "attack": ("golem-atk.png", 64, 96, LPC_ROWS, list(range(7))),
        "melt": ("golem-die.png", 64, 64, {"s": 0}, [1, 2, 3, 4, 5, 6]),
        "crumble": ("golem-die.png", 64, 64, {"s": 1}, [0, 1, 2, 3, 4, 5]),
    },
    "bee": {
        "walk": ("bee.png", 32, 32, LPC_ROWS, [0, 1, 2, 3]),
        "attack": ("bee.png", 32, 32, LPC_ROWS, [3, 4, 4, 5]),
    },
    "big_worm": {
        "walk": ("big_worm.png", 64, 64, LPC_ROWS, [0, 1, 2, 3]),
        "attack": ("big_worm.png", 64, 64, LPC_ROWS, [3, 4, 4, 5]),
    },
    # bird_2_eagle.png: 32 px frames, rows 0-3 fly (w, n, s, e), rows 4-7 walk (e, n, s, w).
    "eagle": {
        "scale": 2,
        "walk": ("bird_2_eagle.png", 32, 32, {"n": 5, "w": 7, "s": 6, "e": 4}, [0, 1, 2]),
        "attack": ("bird_2_eagle.png", 32, 32, {"n": 1, "w": 0, "s": 2, "e": 3}, [0, 1, 2]),
    },
    "rock_crab": {"drawn": "rock_crab"},
    "snowman": {"drawn": "snowman"},
    "goat": {"drawn": "goat"},
}


# --- colours

def ramp_recolor(img: Image.Image, ramp: list[str]) -> Image.Image:
    """Every opaque pixel takes the colour of `ramp` at its brightness (stretched
    from the darkest to the lightest pixel of `img`)."""
    stops = [bs.hex_rgb(h) for h in ramp]
    if len(stops) < 2:
        raise BuildError("a ramp needs at least 2 colours")
    img = img.convert("RGBA")
    px = img.load()
    lums = [_lum(p) for p in img.getdata() if p[3]]
    if not lums:
        return img
    lo, hi = min(lums), max(lums)
    span = max(hi - lo, 1e-6)
    for y in range(img.height):
        for x in range(img.width):
            p = px[x, y]
            if not p[3]:
                continue
            t = (_lum(p) - lo) / span * (len(stops) - 1)
            i = min(int(t), len(stops) - 2)
            f = t - i
            a, b = stops[i], stops[i + 1]
            px[x, y] = tuple(round(a[k] + (b[k] - a[k]) * f) for k in range(3)) + (p[3],)
    return img


def _lum(p) -> float:
    return (0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]) / 255.0


def hsv_shift(img: Image.Image, hue: float, sat: float, val: float) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            h = (h + hue / 360.0) % 1.0
            s = min(s * sat, 1.0)
            v = min(v * val, 1.0)
            rr, gg, bb = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (round(rr * 255), round(gg * 255), round(bb * 255), a)
    return img


def light_to(img: Image.Image, hex_colour: str) -> Image.Image:
    """White and pale grey pixels (low saturation, bright) take `hex_colour`, scaled by
    their brightness."""
    to = bs.hex_rgb(hex_colour)
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            _, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s < 0.25 and v > 0.6:
                px[x, y] = tuple(min(round(c * (0.55 + 0.45 * v)), 255) for c in to) + (a,)
    return img


def colour(img: Image.Image, look: dict) -> Image.Image:
    if "ramp" in look:
        img = ramp_recolor(img, look["ramp"])
    if any(k in look for k in ("hue", "sat", "val")):
        img = hsv_shift(img, float(look.get("hue", 0)), float(look.get("sat", 1)), float(look.get("val", 1)))
    if "light" in look:
        img = light_to(img, look["light"])
    return img


# --- frames: {"walk"|"attack"|"hurt": {facing: [frame images]}}

def load_frames(src: dict, anim: str, art: Path) -> dict[str, list[Image.Image]]:
    file, fw, fh, rows, cols = src[anim]
    path = art / file
    if not path.exists():
        raise BuildError(f"missing art file {path.name}")
    sheet = Image.open(path).convert("RGBA")
    scale = int(src.get("scale", 1))
    out = {}
    for d, r in rows.items():
        frames = []
        for c in cols:
            f = sheet.crop((c * fw, r * fh, c * fw + fw, r * fh + fh))
            if scale != 1:
                f = f.resize((fw * scale, fh * scale), Image.NEAREST)
            frames.append(f)
        out[d] = frames
    return out


def sink(frame: Image.Image, n: int = HURT_FRAMES) -> list[Image.Image]:
    """A made fall: the frame sinks into the ground and fades (bottom stays put)."""
    out = []
    for k in range(n):
        h = max(round(frame.height * (1.0 - 0.16 * k)), 1)
        f = frame.resize((frame.width, h), Image.NEAREST)
        if k:
            alpha = f.getchannel("A").point(lambda a, k=k: round(a * (1.0 - 0.12 * k)))
            f.putalpha(alpha)
        c = Image.new("RGBA", frame.size, (0, 0, 0, 0))
        c.alpha_composite(f, (0, frame.height - h))
        out.append(c)
    return out


def creature_frames(look: dict, art: Path = ART) -> dict[str, dict[str, list[Image.Image]]]:
    name = look.get("creature", "")
    if name not in CREATURES:
        raise BuildError(f"unknown creature '{name}'")
    src = CREATURES[name]
    die = look.get("die", "")
    if die and (die in ("walk", "attack") or die not in src):
        raise BuildError(f"creature '{name}' has no fall '{die}'")
    if src.get("drawn"):
        anims = DRAWN[src["drawn"]]()
    else:
        anims = {"walk": load_frames(src, "walk", art), "attack": load_frames(src, "attack", art)}
        if die:
            anims["hurt"] = load_frames(src, die, art)
    if "hurt" not in anims:
        anims["hurt"] = {"s": sink(anims["walk"]["s"][0])}
    return {a: {d: [colour(f, look) for f in fs] for d, fs in by_dir.items()} for a, by_dir in anims.items()}


def stretch(frames: list, n: int) -> list:
    """`n` frames spread over `frames` (repeats when there are fewer)."""
    return [frames[i * len(frames) // n] for i in range(n)]


def walk_cycle(frames: list, n: int = 9) -> list:
    """Frame 0 stands; frames 1..n-1 loop over the rest (or all, when there are few)."""
    loop = frames[1:] if len(frames) > 2 else frames
    return [frames[0]] + [loop[k % len(loop)] for k in range(n - 1)]


def _paste(sheet: Image.Image, frame: Image.Image, x0: int, y0: int, size: int) -> None:
    """Puts `frame` on the bottom middle of the `size` px slot at x0, y0; in a 128 px
    slot the bottom is where a 64 px frame in its middle ends."""
    bottom = y0 + (size + bs.FRAME) // 2 if size > bs.FRAME else y0 + size
    x = x0 + (size - frame.width) // 2
    y = bottom - frame.height
    box = frame
    if y < y0:  # taller than the slot: cut the top
        box = frame.crop((0, y0 - y, frame.width, frame.height))
        y = y0
    sheet.alpha_composite(box, (x, y))


def build_creature(look: dict, art: Path = ART) -> Image.Image:
    anims = creature_frames(look, art)
    off = bs.anim_offsets()
    sheet = Image.new("RGBA", (bs.SHEET_W, bs.SHEET_H), (0, 0, 0, 0))
    for r, d in enumerate(DIRS):
        walk = anims["walk"].get(d) or anims["walk"]["s"]
        for c, f in enumerate(walk_cycle(walk, 9)):
            _paste(sheet, f, c * bs.FRAME, (off["walk"] + r) * bs.FRAME, bs.FRAME)
        for c, f in enumerate(stretch(walk[:IDLE_FRAMES], IDLE_FRAMES)):
            _paste(sheet, f, c * bs.FRAME, (off["idle"] + r) * bs.FRAME, bs.FRAME)
        attack = anims["attack"].get(d) or anims["attack"]["s"]
        for c, f in enumerate(stretch(attack, bs.ATTACK_FRAMES)):
            _paste(sheet, f, c * bs.BIG, bs.ATTACK_Y + r * bs.BIG, bs.BIG)
    hurt = anims["hurt"].get("s") or next(iter(anims["hurt"].values()))
    for c, f in enumerate(stretch(hurt, HURT_FRAMES)):
        _paste(sheet, f, c * bs.FRAME, off["hurt"] * bs.FRAME, bs.FRAME)
    return sheet


# --- the Rock Crab, drawn here in the LPC rock colours (the rock of lpc_atlas.png)

CRAB_OUTLINE = (29, 18, 28, 255)
CRAB_TONES = [(49, 38, 49, 255), (55, 50, 59, 255), (74, 68, 78, 255), (93, 82, 83, 255), (128, 111, 102, 255)]
CRAB_LEG = (40, 30, 40, 255)
CRAB_EYE = (20, 12, 18, 255)
# The pincers are dark brown chitin (1.01).
CLAW_OUTLINE = (33, 20, 14, 255)
CLAW_TONES = [(74, 44, 28, 255), (104, 66, 40, 255), (140, 96, 60, 255)]


def _shell(d: ImageDraw.ImageDraw, cx: int, cy: int, rx: int, ry: int) -> None:
    """A boulder: dark rim, a darker lower half, lighter top-left lumps."""
    d.ellipse((cx - rx - 1, cy - ry - 1, cx + rx + 1, cy + ry + 1), fill=CRAB_OUTLINE)
    d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=CRAB_TONES[1])
    d.ellipse((cx - rx + 1, cy - ry, cx + rx - 2, cy + ry - 3), fill=CRAB_TONES[2])
    d.ellipse((cx - rx + 3, cy - ry + 1, cx + 2, cy - 1), fill=CRAB_TONES[3])
    d.ellipse((cx - rx + 5, cy - ry + 2, cx - 4, cy - ry + 5), fill=CRAB_TONES[4])
    d.line((cx + 3, cy - 2, cx + 7, cy + 2), fill=CRAB_TONES[0])  # cracks
    d.line((cx - 6, cy + 3, cx - 2, cy + 5), fill=CRAB_TONES[0])
    d.line((cx - rx + 2, cy + ry - 2, cx + rx - 2, cy + ry - 2), fill=CRAB_TONES[0])


def _claw(d: ImageDraw.ImageDraw, x: int, y: int, open_: int, flip: bool) -> None:
    """A big pincer centred on x, y; its tips point right (left with `flip`) and
    spread `open_` px more."""
    d.ellipse((x - 5, y - 4, x + 5, y + 4), fill=CLAW_OUTLINE)
    d.ellipse((x - 4, y - 3, x + 4, y + 3), fill=CLAW_TONES[1])
    d.ellipse((x - 3, y - 3, x, y - 1), fill=CLAW_TONES[2])
    d.line((x - 3, y + 2, x + 3, y + 2), fill=CLAW_TONES[0])
    tip = -1 if flip else 1
    d.polygon([(x + 3 * tip, y - 2), (x + 8 * tip, y - 4 - open_), (x + 7 * tip, y - 1)], fill=CLAW_OUTLINE)
    d.polygon([(x + 3 * tip, y + 2), (x + 8 * tip, y + 3 + open_), (x + 7 * tip, y + 1)], fill=CLAW_OUTLINE)


def _stalk(d: ImageDraw.ImageDraw, x: int, y: int, lean: int) -> None:
    """A curved eye stalk from x, y up 5 px, with a dark eye on top."""
    d.line((x, y, x + lean, y - 3), fill=CLAW_OUTLINE, width=1)
    d.line((x + lean, y - 3, x + lean, y - 5), fill=CLAW_OUTLINE, width=1)
    d.rectangle((x + lean - 1, y - 7, x + lean, y - 6), fill=CRAB_EYE)


def _legs(d: ImageDraw.ImageDraw, cx: int, cy: int, rx: int, phase: int, sides=(-1, 1)) -> None:
    for side in sides:
        for k in range(3):
            lift = (k + phase) % 2
            x0 = cx + side * (rx - 3)
            y0 = cy - 4 + k * 5
            knee = (x0 + side * 7, y0 - 1 - lift)
            d.line((x0, y0) + knee, fill=CRAB_LEG, width=2)
            d.line(knee + (knee[0] + side * 3, knee[1] + 6), fill=CRAB_LEG, width=2)


def crab_frame(facing: str, phase: int = 0, reach: int = 0) -> Image.Image:
    """One 64 px frame. `phase` moves the legs; `reach` pushes the claws out (attack)."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy, rx, ry = 32, 44, 17, 12
    if facing in ("w", "e"):
        s = -1 if facing == "w" else 1
        _legs(d, cx - s * 2, cy, rx, phase, sides=(-s,))
        _shell(d, cx, cy, rx, ry)
        _claw(d, cx + s * (rx + 3 + reach), cy + 2, reach // 2, s < 0)
        _claw(d, cx + s * (rx - 3 + reach), cy + 9, reach // 2, s < 0)
        _stalk(d, cx + s * (rx - 5), cy - ry + 3, s)
    else:
        _legs(d, cx, cy, rx, phase)
        _shell(d, cx, cy, rx, ry)
        if facing == "s":
            y = cy + ry + 2 + reach
            _claw(d, cx - 10, y, reach // 2, True)
            _claw(d, cx + 10, y, reach // 2, False)
            _stalk(d, cx - 3, cy + ry - 2, -1)
            _stalk(d, cx + 3, cy + ry - 2, 1)
        else:  # back: only the tips of the claws show at the top
            for x in (cx - 11, cx + 11):
                d.ellipse((x - 2, cy - ry - 3 - reach, x + 2, cy - ry + 1 - reach), fill=CRAB_OUTLINE)
    return img


def draw_rock_crab() -> dict[str, dict[str, list[Image.Image]]]:
    walk = {d: [crab_frame(d, p) for p in (0, 1, 0, 1)] for d in DIRS}
    attack = {d: [crab_frame(d, 0, r) for r in (0, 2, 4, 4, 2, 0)] for d in DIRS}
    return {"walk": walk, "attack": attack}


# --- the Snow Golem: a snowman with blobby snow hands and stick teeth (2.42)

SNOW_OUTLINE = (58, 74, 104, 255)
SNOW_TONES = [(150, 172, 204, 255), (201, 216, 234, 255), (236, 243, 250, 255), (255, 255, 255, 255)]
STICK = (92, 62, 38, 255)


def _snowball(d: ImageDraw.ImageDraw, cx: int, cy: int, r: int) -> None:
    d.ellipse((cx - r - 1, cy - r - 1, cx + r + 1, cy + r + 1), fill=SNOW_OUTLINE)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=SNOW_TONES[0])
    d.ellipse((cx - r, cy - r, cx + r - 2, cy + r - 3), fill=SNOW_TONES[1])
    d.ellipse((cx - r + 2, cy - r + 1, cx + r // 2, cy), fill=SNOW_TONES[2])
    d.ellipse((cx - r + 3, cy - r + 2, cx - r // 3, cy - r // 2), fill=SNOW_TONES[3])


def snowman_frame(facing: str, bob: int = 0, reach: int = 0) -> Image.Image:
    """One 64 px frame. `bob` lifts the upper body; `reach` swings the hands forward."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = 32
    body_y, head_y = 33 - bob, 17 - bob
    side = {"w": -1, "e": 1}.get(facing, 0)
    arm_y = body_y - 1 - (reach if facing != "n" else 0)
    hands = [cx - 14, cx + 14] if side == 0 else [cx + side * (9 + reach * 2)]
    _snowball(d, cx, 50, 13)
    if side:  # the hand on the far side, behind the body
        _snowball(d, cx - side * 9, arm_y + 2, 4)
    _snowball(d, cx, body_y, 10)
    _snowball(d, cx + side * 2, head_y, 8)
    for hx in hands:
        _snowball(d, hx, arm_y + (reach if facing == "s" else 0), 4)
    if facing == "s":  # a mouth of stick teeth
        d.line((cx - 4, head_y + 3, cx + 4, head_y + 3), fill=SNOW_OUTLINE)
        for x in range(cx - 3, cx + 4, 2):
            d.line((x, head_y + 2, x, head_y + 4), fill=STICK)
    elif side:
        mx = cx + side * 7
        d.line((mx - 1, head_y + 3, mx + 1, head_y + 3), fill=SNOW_OUTLINE)
        d.line((mx, head_y + 2, mx, head_y + 4), fill=STICK)
    return img


def draw_snowman() -> dict[str, dict[str, list[Image.Image]]]:
    walk = {d: [snowman_frame(d, b) for b in (0, 1, 0, 1)] for d in DIRS}
    attack = {d: [snowman_frame(d, 0, r) for r in (0, 2, 4, 5, 3, 0)] for d in DIRS}
    return {"walk": walk, "attack": attack}


# --- the Eater Goat: a scrawny black-and-brown goat with curved horns and a bloody
# mouth (4.34). Drawn here: no goat in the art sources (M18.1).

GOAT_OUTLINE = (20, 14, 10, 255)
GOAT_BLACK = (38, 30, 26, 255)
GOAT_BROWN = (104, 68, 40, 255)
GOAT_LIGHT = (138, 96, 60, 255)
GOAT_HORN = (176, 160, 124, 255)
GOAT_HORN_DARK = (112, 98, 72, 255)
GOAT_EYE = (196, 160, 84, 255)
GOAT_BLOOD = (140, 24, 24, 255)
GOAT_TOOTH = (226, 214, 188, 255)


def _goat_leg(d: ImageDraw.ImageDraw, x: int, top: int, swing: int) -> None:
    """A thin leg from `top` down to the ground (y 60), its hoof moved by `swing`."""
    d.line((x, top, x + swing, 59), fill=GOAT_OUTLINE, width=3)
    d.line((x, top, x + swing, 58), fill=GOAT_BLACK, width=1)


def _goat_horns(d: ImageDraw.ImageDraw, x: int, y: int, back: int) -> None:
    """A slightly curved horn from x, y sweeping back (`back` = -1 left, 1 right)."""
    pts = [(x, y), (x + back * 2, y - 4), (x + back * 5, y - 6), (x + back * 8, y - 5)]
    d.line(pts, fill=GOAT_HORN_DARK, width=3)
    d.line(pts[:3], fill=GOAT_HORN, width=1)


def goat_frame(facing: str, phase: int = 0, reach: int = 0) -> Image.Image:
    """One 64 px frame. `phase` moves the legs; `reach` thrusts the head and opens the
    bloody mouth (attack)."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 32, 41
    swing = (-2, 2)[phase % 2]
    if facing in ("w", "e"):
        s = -1 if facing == "w" else 1
        # far legs, body, near legs
        _goat_leg(d, cx - s * 8, cy + 4, -swing)
        _goat_leg(d, cx + s * 9, cy + 4, swing)
        d.ellipse((cx - 14, cy - 7, cx + 14, cy + 7), fill=GOAT_OUTLINE)
        d.ellipse((cx - 13, cy - 6, cx + 13, cy + 6), fill=GOAT_BLACK)
        d.ellipse((cx - 10, cy - 6, cx + 6, cy + 3), fill=GOAT_BROWN)   # brown patches
        d.ellipse((cx - 7, cy - 5, cx + 1, cy - 1), fill=GOAT_LIGHT)
        d.line((cx - s * 13, cy - 4, cx - s * 16, cy - 8), fill=GOAT_OUTLINE, width=2)  # tail
        _goat_leg(d, cx - s * 10, cy + 4, swing)
        _goat_leg(d, cx + s * 7, cy + 4, -swing)
        # neck and head, thrust forward on attack
        hx, hy = cx + s * (16 + reach), cy - 12 + reach // 2
        d.line((cx + s * 10, cy - 3, hx - s * 2, hy + 2), fill=GOAT_OUTLINE, width=6)
        d.line((cx + s * 10, cy - 3, hx - s * 2, hy + 2), fill=GOAT_BLACK, width=4)
        d.ellipse((hx - 5, hy - 4, hx + 5, hy + 4), fill=GOAT_OUTLINE)
        d.ellipse((hx - 4, hy - 3, hx + 4, hy + 3), fill=GOAT_BROWN)
        d.polygon([(hx + s * 3, hy - 1), (hx + s * 8, hy + 2), (hx + s * 3, hy + 4)], fill=GOAT_BROWN,
                  outline=GOAT_OUTLINE)  # muzzle
        d.line((hx - s * 1, hy + 4, hx - s * 1, hy + 7), fill=GOAT_BLACK, width=2)  # beard
        d.point((hx + s * 1, hy - 1), fill=GOAT_EYE)
        if reach:
            d.line((hx + s * 4, hy + 3, hx + s * 8, hy + 3), fill=GOAT_BLOOD, width=2)
            d.point((hx + s * 6, hy + 2), fill=GOAT_TOOTH)
        _goat_horns(d, hx - s * 1, hy - 3, -s)
    elif facing == "s":
        _goat_leg(d, cx - 6, cy + 2, swing // 2)
        _goat_leg(d, cx + 6, cy + 2, -swing // 2)
        d.ellipse((cx - 11, cy - 8, cx + 11, cy + 7), fill=GOAT_OUTLINE)
        d.ellipse((cx - 10, cy - 7, cx + 10, cy + 6), fill=GOAT_BLACK)
        d.ellipse((cx - 6, cy - 6, cx + 6, cy + 2), fill=GOAT_BROWN)
        hy = cy - 10 + reach
        d.ellipse((cx - 6, hy - 6, cx + 6, hy + 7), fill=GOAT_OUTLINE)
        d.ellipse((cx - 5, hy - 5, cx + 5, hy + 6), fill=GOAT_BROWN)
        d.ellipse((cx - 3, hy + 1, cx + 3, hy + 6), fill=GOAT_LIGHT)
        for ex in (cx - 3, cx + 2):  # bar pupils
            d.rectangle((ex, hy - 2, ex + 1, hy - 1), fill=GOAT_EYE)
            d.point((ex, hy - 2), fill=GOAT_OUTLINE)
        d.line((cx - 2, hy + 5, cx + 2, hy + 5), fill=GOAT_BLOOD if reach else GOAT_OUTLINE, width=1 + (reach > 0))
        _goat_horns(d, cx - 3, hy - 5, -1)
        _goat_horns(d, cx + 3, hy - 5, 1)
    else:  # back: the rump and tail, the horns over the head
        _goat_leg(d, cx - 6, cy + 2, swing // 2)
        _goat_leg(d, cx + 6, cy + 2, -swing // 2)
        hy = cy - 11 - reach // 2
        d.ellipse((cx - 5, hy - 4, cx + 5, hy + 5), fill=GOAT_OUTLINE)
        d.ellipse((cx - 4, hy - 3, cx + 4, hy + 4), fill=GOAT_BLACK)
        _goat_horns(d, cx - 3, hy - 3, -1)
        _goat_horns(d, cx + 3, hy - 3, 1)
        d.ellipse((cx - 11, cy - 8, cx + 11, cy + 7), fill=GOAT_OUTLINE)
        d.ellipse((cx - 10, cy - 7, cx + 10, cy + 6), fill=GOAT_BLACK)
        d.ellipse((cx - 7, cy - 6, cx + 5, cy + 1), fill=GOAT_BROWN)
        d.line((cx, cy - 6, cx, cy - 10), fill=GOAT_OUTLINE, width=2)  # tail
    return img


def draw_goat() -> dict[str, dict[str, list[Image.Image]]]:
    walk = {d: [goat_frame(d, p) for p in (0, 1, 0, 1)] for d in DIRS}
    attack = {d: [goat_frame(d, 0, r) for r in (0, 2, 5, 6, 3, 0)] for d in DIRS}
    return {"walk": walk, "attack": attack}


DRAWN = {"rock_crab": draw_rock_crab, "snowman": draw_snowman, "goat": draw_goat}


# --- build

def is_creature(look: dict) -> bool:
    return "creature" in look


def build(appearance: Path, out_dir: Path, only: set[str] | None = None, art: Path = ART) -> list[str]:
    data = json.loads(appearance.read_text(encoding="utf-8"))
    errors = []
    out_dir.mkdir(parents=True, exist_ok=True)
    for look_id, look in sorted(data.get("looks", {}).items()):
        if not is_creature(look) or (only is not None and look_id not in only):
            continue
        try:
            sheet = build_creature(look, art)
        except BuildError as e:
            errors.append(f"{look_id}: {e}")
            continue
        sheet.save(out_dir / f"{look_id}.png")
    return errors


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--appearance", type=Path, default=bs.DEFAULT_APPEARANCE)
    ap.add_argument("--out", type=Path, default=bs.DEFAULT_OUT)
    ap.add_argument("--only", default="", help="comma-separated look ids to write")
    a = ap.parse_args(argv)
    only = {s for s in a.only.split(",") if s} or None
    errors = build(a.appearance, a.out, only)
    for e in errors:
        print("ERROR", e)
    print(f"{len(errors)} errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
