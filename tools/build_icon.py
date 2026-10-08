"""Draw the game icon (game/icon.png): a lit inn on a hill under a night sky.
Original pixel art, drawn at 64x64 and scaled up 8x with no smoothing.
Run: python tools/build_icon.py
"""
from pathlib import Path
from PIL import Image, ImageDraw

S = 64
img = Image.new("RGB", (S, S))
d = ImageDraw.Draw(img)

# sky: vertical bands, dark to warm at the horizon
bands = [(18, 24, 56), (26, 32, 70), (38, 44, 88), (58, 58, 104), (96, 78, 118)]
for i, c in enumerate(bands):
    d.rectangle([0, i * 9, S, S if i == len(bands) - 1 else i * 9 + 9], fill=c)

# stars
for x, y in [(6, 5), (14, 12), (22, 4), (40, 7), (52, 3), (58, 14), (47, 17), (9, 21), (31, 11)]:
    d.point((x, y), fill=(240, 236, 200))

# moon
d.ellipse([46, 8, 55, 17], fill=(236, 232, 200))
d.ellipse([49, 7, 58, 16], fill=(38, 44, 88))

# hill
d.ellipse([-20, 44, 84, 100], fill=(34, 62, 52))
d.ellipse([-6, 50, 70, 100], fill=(44, 78, 60))

# inn body
d.rectangle([17, 30, 46, 50], fill=(104, 72, 52))
d.rectangle([17, 30, 46, 31], fill=(124, 88, 62))
# roof
d.polygon([(13, 31), (31, 16), (50, 31)], fill=(122, 48, 44))
d.polygon([(16, 31), (31, 19), (47, 31)], fill=(146, 60, 52))
# chimney + smoke
d.rectangle([38, 16, 42, 25], fill=(90, 80, 84))
for x, y in [(41, 13), (43, 10), (42, 7)]:
    d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=(150, 150, 170))
# door
d.rectangle([28, 40, 35, 50], fill=(60, 38, 30))
d.rectangle([29, 41, 34, 50], fill=(240, 176, 80))
d.point((33, 46), fill=(60, 38, 30))
# windows (lit)
for x in (20, 39):
    d.rectangle([x, 35, x + 5, 40], fill=(252, 204, 104))
    d.line([x + 2, 35, x + 2, 40], fill=(104, 72, 52))
    d.line([x, 37, x + 5, 37], fill=(104, 72, 52))
# lantern glow on ground
d.ellipse([26, 49, 37, 53], fill=(120, 110, 70))

# dark outline for the whole house, drawn last as a frame
d.rectangle([0, 0, S - 1, S - 1], outline=(12, 14, 30))

out = Path(__file__).resolve().parent.parent / "game" / "icon.png"
img.resize((512, 512), Image.NEAREST).save(out)
print("wrote", out)
