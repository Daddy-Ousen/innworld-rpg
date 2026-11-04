"""Make the Microsoft Store art in export/store_windows/ (gitignored). See docs/WINDOWS_STORE.md.

- assets/   the MSIX package logos (no text, the house icon only): Square44x44Logo, Square150x150Logo,
            Wide310x150Logo, Square71x71Logo, Square310x310Logo, StoreLogo, each at scales 100/125/150/200/400,
            plus Square44x44Logo target sizes (16, 24, 32, 48, 256, and the "unplated" copies for the taskbar).
            tools/windows_store.ps1 copies them into the package and makes resources.pri from them.
- listing/  the files for the Partner Center "Store listings" page:
              icon_300.png         1:1 app tile icon, 300 x 300
              box_art_1080.png     1:1 box art, 1080 x 1080 (title in the top two thirds)
              poster_720x1080.png  2:3 poster art, 720 x 1080 (title in the top two thirds)
              screenshot_<n>.png   desktop screenshots, 2304 x 1296 (the Store minimum is 1366 x 768)

The screenshots come from export/itch/ (made by export/itch/capture_shots.gd), the same ones as the Play art.
Marketing text says "pirateaba's Innworld", never a book title (docs/DESIGN.md section 7).
Run: python tools/build_windows_store_art.py [screenshot dir] [out dir]
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_store_art import FONT, ICON, TAGLINE, TITLE, load, scale_shot  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
BG = (12, 14, 30)  # the dark night blue of the icon border and the title screen
SCALES = {100: 1.0, 125: 1.25, 150: 1.5, 200: 2.0, 400: 4.0}
# (file stem, width, height) at scale 100
TILES = [
    ("Square44x44Logo", 44, 44),
    ("Square150x150Logo", 150, 150),
    ("Wide310x150Logo", 310, 150),
    ("Square71x71Logo", 71, 71),
    ("Square310x310Logo", 310, 310),
    ("StoreLogo", 50, 50),
]
TARGET_SIZES = [16, 24, 32, 48, 256]


def icon_square(size):
    """The 64 x 64 pixel-art icon at size x size. Whole multiples of 64 stay sharp; others use Lanczos."""
    src = load(ICON).convert("RGBA")
    if size % 64 == 0:
        return src.resize((64, 64), Image.NEAREST).resize((size, size), Image.NEAREST)
    return src.resize((size, size), Image.LANCZOS)


def tile(width, height):
    """Square: the icon fills it. Wide: the icon centred on the night blue, 80 % of the height."""
    if width == height:
        return icon_square(width)
    img = Image.new("RGBA", (width, height), BG + (255,))
    side = round(height * 0.8)
    img.paste(icon_square(side), ((width - side) // 2, (height - side) // 2))
    return img


def build_assets(out_dir):
    out_dir.mkdir(parents=True, exist_ok=True)
    made = []
    for stem, w, h in TILES:
        for scale, f in SCALES.items():
            path = out_dir / f"{stem}.scale-{scale}.png"
            tile(round(w * f), round(h * f)).save(path)
            made.append(path)
    for size in TARGET_SIZES:
        img = icon_square(size)
        for name in (f"Square44x44Logo.targetsize-{size}.png", f"Square44x44Logo.targetsize-{size}_altform-unplated.png"):
            img.save(out_dir / name)
            made.append(out_dir / name)
    return made


def backdrop(shot, size):
    """A screenshot cropped to size and darkened, like the Play feature graphic."""
    w, h = size
    bg = shot.convert("RGB")
    scale = max(w / bg.width, h / bg.height)
    bg = bg.resize((round(bg.width * scale), round(bg.height * scale)), Image.NEAREST)
    left, top = (bg.width - w) // 2, (bg.height - h) // 2
    img = bg.crop((left, top, left + w, top + h))
    return Image.blend(img, Image.new("RGB", size, BG), 0.7)


def centred(draw, text, font, y, width, fill, shadow=True):
    x = (width - draw.textlength(text, font=font)) // 2
    if shadow:
        draw.text((x + 4, y + 4), text, font=font, fill=(0, 0, 0))
    draw.text((x, y), text, font=font, fill=fill)


def fit_font(draw, text, max_width, start):
    font = ImageFont.truetype(str(FONT), start)
    while draw.textlength(text, font=font) > max_width and font.size > 12:
        font = ImageFont.truetype(str(FONT), font.size - 2)
    return font


def box_art(shot):
    """1080 x 1080. Icon, title and tagline stay inside the top two thirds (y < 720): the Store can overlay the rest."""
    size = (1080, 1080)
    img = backdrop(shot, size)
    img.paste(icon_square(384).convert("RGB"), ((1080 - 384) // 2, 70))
    d = ImageDraw.Draw(img)
    centred(d, TITLE, fit_font(d, TITLE, 960, 110), 500, 1080, (246, 222, 150))
    centred(d, TAGLINE, fit_font(d, TAGLINE, 960, 40), 635, 1080, (232, 232, 232), shadow=False)
    return img


def poster_art(shot):
    """720 x 1080. Same rule: everything above y = 720."""
    size = (720, 1080)
    img = backdrop(shot, size)
    img.paste(icon_square(320).convert("RGB"), ((720 - 320) // 2, 70))
    d = ImageDraw.Draw(img)
    centred(d, TITLE, fit_font(d, TITLE, 640, 80), 430, 720, (246, 222, 150))
    tag = ImageFont.truetype(str(FONT), 28)
    centred(d, "A free fan-made RPG", tag, 560, 720, (232, 232, 232), shadow=False)
    centred(d, "in pirateaba's Innworld", tag, 600, 720, (232, 232, 232), shadow=False)
    return img


def build(shot_dir, out_dir):
    shots = sorted(shot_dir.glob("screenshot_*.png"))
    if not shots:
        raise SystemExit(f"No screenshot_*.png in {shot_dir}")
    assets = build_assets(out_dir / "assets")
    listing = out_dir / "listing"
    listing.mkdir(parents=True, exist_ok=True)
    made = list(assets)
    icon_square(300).save(listing / "icon_300.png")
    first = load(shots[0])
    box_art(first).save(listing / "box_art_1080.png")
    poster_art(first).save(listing / "poster_720x1080.png")
    made += [listing / "icon_300.png", listing / "box_art_1080.png", listing / "poster_720x1080.png"]
    for n, path in enumerate(shots, 1):
        dest = listing / f"screenshot_{n}.png"
        scale_shot(load(path)).save(dest)
        made.append(dest)
    return made


if __name__ == "__main__":
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "export" / "itch"
    dst = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "export" / "store_windows"
    made = build(src, dst)
    print(f"made {len(made)} files in {dst}")
