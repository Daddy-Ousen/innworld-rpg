"""Tests for tools/build_windows.py.

Run: python -m unittest discover -s tools/tests
"""

import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import build_windows as bw  # noqa: E402


class BuildWindowsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.img = bw.render()
        sheet = Image.open(bw.SOURCE).convert("RGBA")
        x0, y0 = bw.WALL_CELL[0] * bw.CELL, bw.WALL_CELL[1] * bw.CELL
        cls.wall = sheet.crop((x0, y0, x0 + bw.CELL, y0 + bw.CELL))

    def test_one_opaque_cell(self):
        self.assertEqual(self.img.size, (bw.CELL, bw.CELL))
        self.assertEqual(self.img.getchannel("A").getextrema(), (255, 255))

    def test_the_window_is_glass_and_the_rest_is_still_wall(self):
        x, y, w, h = bw.WINDOW
        self.assertEqual(self.img.getpixel((x + 2 + 1, y + h - 4)), bw.GLASS)
        self.assertEqual(self.img.getpixel((x, y)), bw.OUTLINE)
        for corner in [(0, 0), (bw.CELL - 1, 0), (0, bw.CELL - 1), (bw.CELL - 1, bw.CELL - 1)]:
            self.assertEqual(self.img.getpixel(corner), self.wall.getpixel(corner))

    def test_the_window_fits_the_cell(self):
        x, y, w, h = bw.WINDOW
        self.assertLessEqual(x + w + 1, bw.CELL)
        self.assertLessEqual(y + h + 2, bw.CELL)


if __name__ == "__main__":
    unittest.main()
