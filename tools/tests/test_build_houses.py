"""Tests for tools/build_houses.py (reads the real LPC house sheet in game/assets).

Run: python -m unittest discover -s tools/tests
"""

import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import build_houses as bh  # noqa: E402


class BuildHousesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.img = bh.render()

    def block(self, i: int) -> Image.Image:
        w = bh.BLOCK_W * bh.CELL
        return self.img.crop((i * w, 0, (i + 1) * w, self.img.height))

    def piece(self, i: int, col: int, row: int) -> Image.Image:
        return self.block(i).crop((col * bh.CELL, row * bh.CELL, (col + 1) * bh.CELL, (row + 1) * bh.CELL))

    def test_sheet_size_is_eight_blocks(self):
        self.assertEqual(self.img.size, (bh.BLOCK_W * bh.CELL * len(bh.STYLES) * 2, bh.BLOCK_H * bh.CELL))

    def test_house_pieces_are_opaque_except_ruin_tops(self):
        for i, style in enumerate(bh.STYLES):
            for col in (bh.LEFT, bh.MID, bh.RIGHT):
                for row in (1, 2, 3):
                    self.assertEqual(self.piece(i, col, row).getchannel("A").getextrema()[0], 255, f"{style} {col},{row}")
            if style != "ruin":
                for col in (bh.LEFT, bh.MID, bh.RIGHT):
                    self.assertEqual(self.piece(i, col, 0).getchannel("A").getextrema()[0], 255, f"{style} roof top {col}")

    def test_ruin_tops_are_broken(self):
        ruin = bh.STYLES.index("ruin")
        for col in (bh.LEFT, bh.MID, bh.RIGHT):
            self.assertEqual(self.piece(ruin, col, 0).getchannel("A").getextrema()[0], 0, f"col {col}")

    def test_snow_roofs_are_lighter_and_walls_stay_the_same(self):
        n = len(bh.STYLES)
        for i, style in enumerate(bh.STYLES):
            if style == "ruin":
                continue
            summer, winter = self.piece(i, bh.MID, 1), self.piece(n + i, bh.MID, 1)
            self.assertGreater(bh.lum(winter.resize((1, 1)).getpixel((0, 0))), bh.lum(summer.resize((1, 1)).getpixel((0, 0))), style)
            self.assertEqual(self.piece(i, bh.MID, 3).tobytes(), self.piece(n + i, bh.MID, 3).tobytes(), style)

    def test_a_door_is_brown_and_windows_differ_from_plain_wall(self):
        for i in range(3):
            self.assertNotEqual(self.piece(i, bh.WINDOW, 2).tobytes(), self.piece(i, bh.MID, 2).tobytes())
            self.assertNotEqual(self.piece(i, bh.DOOR, 3).tobytes(), self.piece(i, bh.MID, 3).tobytes())
            r, g, b, _ = self.piece(i, bh.DOOR, 3).resize((1, 1)).getpixel((0, 0))
            self.assertGreater(r, b, "door is warm brown")


if __name__ == "__main__":
    unittest.main()
