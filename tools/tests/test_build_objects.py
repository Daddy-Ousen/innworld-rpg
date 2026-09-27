"""Tests for tools/build_objects.py (reads the real LPC sheets in game/assets).

Run: python -m unittest discover -s tools/tests
"""

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import build_objects as bo  # noqa: E402


class BuildObjectsTest(unittest.TestCase):
    def test_render_is_fixed_and_every_edit_has_pixels(self):
        img, layout = bo.render()
        img2, layout2 = bo.render()
        self.assertEqual(layout, layout2)
        self.assertEqual(img.tobytes(), img2.tobytes(), "same input, same sheet")
        self.assertEqual(img.height, bo.HEIGHT)
        for name, (x, y, w, h) in layout.items():
            self.assertEqual(y + h, bo.HEIGHT, f"{name} sits on the bottom line")
            box = img.crop((x, y, x + w, y + h)).getchannel("A").getbbox()
            self.assertIsNotNone(box, f"{name} is not empty")

    def test_frames_follow_to_the_right(self):
        img, layout = bo.render()
        x, y, w, h = layout["brazier"]
        frames = [img.crop((x + i * w, y, x + (i + 1) * w, y + h)).tobytes() for i in range(4)]
        self.assertEqual(len(set(frames)), 4, "four different flame frames")

    def test_objects_json_matches_the_layout(self):
        _, layout = bo.render()
        self.assertEqual(bo.check(bo.DEFAULT_OBJECTS, layout), [])

    def test_check_reports_a_wrong_or_unknown_edit(self):
        _, layout = bo.render()
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "objects.json"
            p.write_text(json.dumps({"kinds": {
                "wagon": {"sheet": "edits", "region": [1, 2, 3, 4]},
                "ufo": {"sheet": "edits", "region": [0, 0, 8, 8]},
                "table": {"sheet": "tavern_furniture", "region": [0, 0, 8, 8]},
            }}), encoding="utf-8")
            errs = bo.check(p, layout)
        self.assertEqual(len(errs), 2)
        self.assertIn("wagon", errs[0])
        self.assertIn("ufo", errs[1])


if __name__ == "__main__":
    unittest.main()
