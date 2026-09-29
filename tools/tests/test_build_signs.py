"""Tests for tools/build_signs.py.

Run: python -m unittest discover -s tools/tests
"""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import build_signs as bs  # noqa: E402


class BuildSignsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.img = bs.render()

    def cell(self, name: str):
        x, y, w, h = bs.region(name)
        return self.img.crop((x, y, x + w, y + h))

    def test_sheet_has_one_cell_per_icon_and_an_empty_one(self):
        self.assertEqual(self.img.size, (bs.SIGN_W * (len(bs.ICONS) + 1), bs.SIGN_H))
        self.assertEqual(self.cell(bs.NONE).getchannel("A").getextrema(), (0, 0))

    def test_every_icon_is_drawn_and_differs(self):
        seen = set()
        for name in bs.ICONS:
            c = self.cell(name)
            self.assertGreater(c.getchannel("A").getextrema()[1], 0, name)
            seen.add(c.tobytes())
        self.assertEqual(len(seen), len(bs.ICONS))

    def test_icons_fit_the_icon_square(self):
        for name, rows in bs.ICONS.items():
            self.assertLessEqual(max(len(r) for r in rows), bs.ICON, name)
            self.assertLessEqual(len(rows), bs.ICON, name)
            for r in rows:
                for ch in r:
                    self.assertTrue(ch == "." or ch in bs.PALETTE, f"{name}: '{ch}'")

    def test_board_is_opaque_and_bracket_is_on_top(self):
        for name in bs.ICONS:
            c = self.cell(name)
            self.assertEqual(c.getpixel((bs.SIGN_W // 2, bs.SIGN_H - 1))[3], 255, name)
            self.assertEqual(c.getpixel((bs.SIGN_W // 2, 0))[3], 255, name)
            self.assertEqual(c.getpixel((0, bs.SIGN_H - 1))[3], 0, name)

    def test_objects_json_matches_the_sheet(self):
        self.assertEqual(bs.check(), [])

    def test_the_plaque_kind_is_the_empty_cell(self):
        import json

        kinds = json.loads(bs.OBJECTS_JSON.read_text(encoding="utf-8"))["kinds"]
        self.assertEqual(kinds["plaque"]["region"], bs.region(bs.NONE))


if __name__ == "__main__":
    unittest.main()
