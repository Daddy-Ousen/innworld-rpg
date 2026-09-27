"""Tests for tools/build_sprites.py. Uses a tiny synthetic LPC tree (no real art).

Run: python -m unittest discover -s tools/tests
"""

import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import build_sprites as bs  # noqa: E402

LIGHT = "#cc8665"
GREEN = "#3c8a3c"
WHITE = "#ffffff"
BLUE = "#2040c0"


def _write(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data), encoding="utf-8")


def _png(path: Path, w: int, h: int, colour: str, box=(0, 0, 8, 8), mode="RGBA") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    img.paste(Image.new("RGBA", (box[2] - box[0], box[3] - box[1]), bs.hex_rgb(colour) + (255,)), box[:2])
    if mode == "P":
        img = img.convert("P")
    img.save(path)


def make_ulpc(root: Path) -> None:
    _write(root / "palette_definitions/body/meta_body.json", {"default": "ulpc", "base": "light"})
    _write(root / "palette_definitions/body/body_ulpc.json", {"light": [LIGHT], "green": [GREEN]})
    _write(root / "palette_definitions/cloth/meta_cloth.json", {"default": "ulpc", "base": "white"})
    _write(root / "palette_definitions/cloth/cloth_ulpc.json", {"white": [WHITE], "blue": [BLUE]})
    _write(root / "sheet_definitions/body/body.json", {
        "layer_1": {"zPos": 10, "male": "body/male/"}, "match_body_color": True,
        "recolors": {"material": "body"},
        "credits": [{"file": "body/male", "authors": ["A"], "licenses": ["CC-BY-SA 3.0"], "urls": ["u1"]},
                    {"file": "body/female", "authors": ["Z"], "licenses": ["GPL 3.0"], "urls": []}]})
    _write(root / "sheet_definitions/torso/shirt.json", {
        "layer_1": {"zPos": 35, "male": "torso/shirt/"}, "recolors": {"material": "cloth"},
        "credits": [{"file": "torso/shirt", "authors": ["B"], "licenses": ["OGA-BY 3.0"], "urls": []}]})
    _write(root / "sheet_definitions/body/tail.json", {
        "layer_1": {"zPos": 5, "male": "tail/"}, "credits": []})
    # Body: skin block at the top left of every animation; walk as a palette image.
    for anim, frames, rows in bs.ANIMS:
        mode = "P" if anim == "walk" else "RGBA"
        _png(root / f"spritesheets/body/male/{anim}.png", frames * 64, rows * 64, LIGHT, mode=mode)
        _png(root / f"spritesheets/torso/shirt/{anim}.png", frames * 64, rows * 64, WHITE, box=(4, 4, 8, 8))
    # Tail: one file per colour, walk only.
    _png(root / "spritesheets/tail/walk/red.png", 9 * 64, 4 * 64, "#c02020", box=(0, 0, 2, 2))


class BuildSpritesTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.ulpc = self.root / "ulpc"
        make_ulpc(self.ulpc)
        self.out = self.root / "out"
        self.credits = self.root / "CREDITS.md"
        self.appearance = self.root / "appearance.json"

    def tearDown(self):
        self.tmp.cleanup()

    def _build(self, looks, only=None):
        _write(self.appearance, {"schema_version": 1, "looks": looks})
        return bs.build(self.ulpc, self.appearance, self.out, self.credits, only)

    def test_sheet_layout_and_skin_recolour(self):
        errors = self._build({"lizard": {"body": "male", "skin": "green"}})
        self.assertEqual(errors, [])
        sheet = Image.open(self.out / "lizard.png").convert("RGBA")
        self.assertEqual(sheet.size, (bs.COLUMNS * 64, bs.ROWS * 64))
        rows = bs.anim_offsets()
        for anim in ("walk", "slash", "hurt", "idle"):
            self.assertEqual(sheet.getpixel((1, rows[anim] * 64 + 1)), bs.hex_rgb(GREEN) + (255,), anim)

    def test_layers_follow_z_order_and_cloth_colour(self):
        # The shirt (z 35) is listed first but drawn over the body (z 10).
        self.assertEqual(self._build({"p": {"body": "male", "skin": "light",
                                            "parts": [{"part": "shirt", "color": "blue"}]}}), [])
        sheet = Image.open(self.out / "p.png").convert("RGBA")
        self.assertEqual(sheet.getpixel((5, 5)), bs.hex_rgb(BLUE) + (255,))
        self.assertEqual(sheet.getpixel((1, 1)), bs.hex_rgb(LIGHT) + (255,))

    def test_variant_folder_part_uses_the_colour_file(self):
        self.assertEqual(self._build({"t": {"body": "male", "skin": "light",
                                            "parts": [{"part": "tail", "color": "red"}]}}), [])
        sheet = Image.open(self.out / "t.png").convert("RGBA")
        # Tail z 5 is under the body z 10, so the body colour shows on top.
        self.assertEqual(sheet.getpixel((0, 0)), bs.hex_rgb(LIGHT) + (255,))

    def test_errors_for_unknown_part_colour_and_body(self):
        errors = self._build({
            "a": {"body": "male", "parts": [{"part": "nope"}]},
            "b": {"body": "male", "parts": [{"part": "shirt", "color": "mauve"}]},
            "c": {"body": "child"},
            "d": {"body": "male", "parts": [{"part": "tail", "color": "blue"}]},
        })
        self.assertEqual(len(errors), 4)
        self.assertIn("unknown LPC part 'nope'", errors[0])
        self.assertIn("no colour 'mauve'", errors[1])
        self.assertIn("no 'child' body", errors[2])
        self.assertIn("no colour 'blue'", errors[3])
        self.assertFalse(self.credits.exists())

    def test_credits_block_lists_used_files_only_and_is_replaced(self):
        self.credits.write_text("# Credits\n\n## Tiles\nhand\n", encoding="utf-8")
        self._build({"p": {"body": "male", "skin": "light", "parts": [{"part": "shirt", "color": "blue"}]}})
        text = self.credits.read_text(encoding="utf-8")
        self.assertIn("## Tiles\nhand", text)
        self.assertIn("`body/male` by A. Licence: CC-BY-SA 3.0.", text)
        self.assertIn("`torso/shirt` by B.", text)
        self.assertNotIn("body/female", text)
        self._build({"p": {"body": "male", "skin": "light"}})
        text = self.credits.read_text(encoding="utf-8")
        self.assertEqual(text.count(bs.BEGIN), 1)
        self.assertNotIn("torso/shirt", text)

    def test_only_writes_the_named_looks(self):
        self._build({"a": {"body": "male"}, "b": {"body": "male"}}, only={"b"})
        self.assertFalse((self.out / "a.png").exists())
        self.assertTrue((self.out / "b.png").exists())


if __name__ == "__main__":
    unittest.main()
