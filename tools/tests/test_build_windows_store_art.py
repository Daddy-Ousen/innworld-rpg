"""Tests for tools/build_windows_store_art.py (Microsoft Store art, docs/WINDOWS_STORE.md).

Run: python -m unittest discover -s tools/tests
"""

import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import build_windows_store_art as bws  # noqa: E402


def load(path):
    with Image.open(path) as im:  # close the file: Windows can not delete an open temp file
        im.load()
        return im


class BuildWindowsStoreArtTest(unittest.TestCase):
    def test_sizes(self):
        with tempfile.TemporaryDirectory() as tmp:
            src, out = Path(tmp) / "src", Path(tmp) / "out"
            src.mkdir()
            Image.new("RGB", (1152, 648), (40, 60, 80)).save(src / "screenshot_1_inn.png")
            Image.new("RGB", (1152, 648), (80, 60, 40)).save(src / "screenshot_2_fight.png")
            bws.build(src, out)
            a, lst = out / "assets", out / "listing"
            self.assertEqual(load(a / "Square44x44Logo.scale-100.png").size, (44, 44))
            self.assertEqual(load(a / "Square44x44Logo.scale-200.png").size, (88, 88))
            self.assertEqual(load(a / "Square150x150Logo.scale-400.png").size, (600, 600))
            self.assertEqual(load(a / "Wide310x150Logo.scale-100.png").size, (310, 150))
            self.assertEqual(load(a / "StoreLogo.scale-100.png").size, (50, 50))
            self.assertEqual(load(a / "Square44x44Logo.targetsize-16_altform-unplated.png").size, (16, 16))
            self.assertEqual(load(a / "Square44x44Logo.targetsize-256.png").size, (256, 256))
            self.assertEqual(load(lst / "icon_300.png").size, (300, 300))
            self.assertEqual(load(lst / "box_art_1080.png").size, (1080, 1080))
            self.assertEqual(load(lst / "poster_720x1080.png").size, (720, 1080))
            self.assertEqual(load(lst / "screenshot_1.png").size, (2304, 1296))  # Store minimum is 1366 x 768
            self.assertEqual(load(lst / "screenshot_2.png").size, (2304, 1296))

    def test_icon_is_sharp_at_whole_multiples(self):
        # 128 = 2 x 64: every pixel of the 64 px art becomes a 2 x 2 block, so the colour count does not grow
        small = bws.icon_square(64)
        big = bws.icon_square(128)
        self.assertEqual(len(set(small.getdata())), len(set(big.getdata())))

    def test_wide_tile_is_centred_on_the_night_blue(self):
        img = bws.tile(310, 150).convert("RGB")
        self.assertEqual(img.getpixel((0, 0)), bws.BG)
        self.assertEqual(img.getpixel((309, 149)), bws.BG)


if __name__ == "__main__":
    unittest.main()
