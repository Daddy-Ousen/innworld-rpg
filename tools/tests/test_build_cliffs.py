"""Tests for tools/build_cliffs.py (reads the real LPC atlas in game/assets).

Run: python -m unittest discover -s tools/tests
"""

import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import build_cliffs as bc  # noqa: E402


class BuildCliffsTest(unittest.TestCase):
    def test_sheet_size_and_the_earth_block_is_the_atlas_plateau(self):
        img = bc.render()
        self.assertEqual(img.size, (bc.BLOCK_W * bc.CELL * len(bc.LOOKS), bc.BLOCK_H * bc.CELL))
        atlas = Image.open(bc.SOURCE).convert("RGBA")
        ox, oy = bc.ORIGIN
        plateau = atlas.crop((ox * bc.CELL, oy * bc.CELL, (ox + bc.BLOCK_W) * bc.CELL, (oy + bc.BLOCK_H) * bc.CELL))
        earth = img.crop((0, 0, plateau.width, plateau.height))
        self.assertEqual(earth.tobytes(), plateau.tobytes())

    def test_recolours_keep_the_shape_and_change_the_colour(self):
        img = bc.render()
        w = bc.BLOCK_W * bc.CELL
        earth = img.crop((0, 0, w, img.height))
        for i in range(1, len(bc.LOOKS)):
            block = img.crop((i * w, 0, (i + 1) * w, img.height))
            self.assertEqual(block.getchannel("A").tobytes(), earth.getchannel("A").tobytes(), bc.LOOKS[i])
            self.assertNotEqual(block.tobytes(), earth.tobytes(), bc.LOOKS[i])

    def test_stone_is_grey_and_snow_makes_the_top_light(self):
        self.assertLess(max(bc.stone((200, 150, 80, 255))[:3]) - min(bc.stone((200, 150, 80, 255))[:3]), 30)
        self.assertGreater(bc.snow((210, 165, 90, 255))[2], 200)
        self.assertEqual(bc.snow((40, 28, 20, 255)), (40, 28, 20, 255), "outline stays")


if __name__ == "__main__":
    unittest.main()
