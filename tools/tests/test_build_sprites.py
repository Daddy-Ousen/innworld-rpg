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
LEMON = "#e0e040"


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


def _frames_png(path: Path, frames: int, rows: int, colour: str, box) -> None:
    """A box of `colour` at the same place in every 64x64 frame."""
    path.parent.mkdir(parents=True, exist_ok=True)
    img = Image.new("RGBA", (frames * 64, rows * 64), (0, 0, 0, 0))
    block = Image.new("RGBA", (box[2] - box[0], box[3] - box[1]), bs.hex_rgb(colour) + (255,))
    for r in range(rows):
        for c in range(frames):
            img.paste(block, (c * 64 + box[0], r * 64 + box[1]))
    img.save(path)


def make_ulpc(root: Path) -> None:
    _write(root / "palette_definitions/body/meta_body.json", {"default": "ulpc", "base": "light"})
    _write(root / "palette_definitions/body/body_ulpc.json", {"light": [LIGHT], "green": [GREEN]})
    _write(root / "palette_definitions/cloth/meta_cloth.json", {"default": "ulpc", "base": "white"})
    _write(root / "palette_definitions/cloth/cloth_ulpc.json", {"white": [WHITE], "blue": [BLUE]})
    _write(root / "palette_definitions/all/meta_all.json", {"default": "lpcr", "base": "white"})
    _write(root / "palette_definitions/all/all_lpcr.json", {"lemon": [LEMON]})
    _write(root / "sheet_definitions/head/heads_round.json", {
        "layer_1": {"zPos": 100, "male": "head/round/"}, "match_body_color": True,
        "recolors": {"material": "body"}, "credits": []})
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
    for anim, frames, rows in bs.ANIMS + [("slash", 6, 4), ("thrust", 8, 4)]:
        mode = "P" if anim == "walk" else "RGBA"
        _png(root / f"spritesheets/body/male/{anim}.png", frames * 64, rows * 64, LIGHT, mode=mode)
        _png(root / f"spritesheets/torso/shirt/{anim}.png", frames * 64, rows * 64, WHITE, box=(4, 4, 8, 8))
        # A person shape in every frame: head 26..37 x 10..21, body 20..43 x 22..55.
        _frames_png(root / f"spritesheets/body/person/{anim}.png", frames, rows, LIGHT, (20, 22, 44, 56))
        _frames_png(root / f"spritesheets/head/round/{anim}.png", frames, rows, LIGHT, (26, 10, 38, 22))
    _write(root / "sheet_definitions/body/body_person.json", {
        "layer_1": {"zPos": 10, "male": "body/person/"}, "match_body_color": True,
        "recolors": {"material": "body"}, "credits": []})
    # Tail: one file per colour, walk only.
    _png(root / "spritesheets/tail/walk/red.png", 9 * 64, 4 * 64, "#c02020", box=(0, 0, 2, 2))
    # A spear: walk and thrust (no slash). A sword: walk, plus an oversize slash in
    # 128 px frames (its own layers, the LPC "custom_animation").
    _write(root / "sheet_definitions/weapons/weapon_spear.json", {
        "layer_1": {"zPos": 140, "male": "weapon/spear/"}, "animations": ["walk", "thrust"], "credits": []})
    _png(root / "spritesheets/weapon/spear/walk/iron.png", 9 * 64, 4 * 64, BLUE, box=(60, 0, 64, 4))
    _frames_png(root / "spritesheets/weapon/spear/thrust/iron.png", 8, 4, BLUE, (60, 60, 64, 64))
    _write(root / "sheet_definitions/weapons/weapon_sword.json", {
        "layer_1": {"zPos": 140, "male": "weapon/sword/fg/"},
        "layer_2": {"zPos": 150, "custom_animation": "slash_128", "male": "weapon/sword/attack/"},
        "animations": ["walk", "slash_128"], "credits": []})
    _png(root / "spritesheets/weapon/sword/fg/walk/steel.png", 9 * 64, 4 * 64, WHITE, box=(60, 0, 64, 4))
    img = Image.new("RGBA", (6 * 128, 4 * 128), (0, 0, 0, 0))
    for r in range(4):
        for c in range(6):
            img.paste(Image.new("RGBA", (4, 4), bs.hex_rgb(LEMON) + (255,)), (c * 128 + 120, r * 128))
    (root / "spritesheets/weapon/sword/attack").mkdir(parents=True, exist_ok=True)
    img.save(root / "spritesheets/weapon/sword/attack/steel.png")


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
        self.assertEqual(sheet.size, (768, 1088))
        self.assertEqual((bs.SHEET_W, bs.SHEET_H), (768, 1088))
        rows = bs.anim_offsets()
        for anim in ("walk", "hurt", "idle"):
            self.assertEqual(sheet.getpixel((1, rows[anim] * 64 + 1)), bs.hex_rgb(GREEN) + (255,), anim)
        # The attack block: the 64 px slash frame in the middle of a 128 px frame.
        self.assertEqual(sheet.getpixel((32 + 1, bs.ATTACK_Y + 32 + 1)), bs.hex_rgb(GREEN) + (255,))
        self.assertEqual(sheet.getpixel((1, bs.ATTACK_Y + 1))[3], 0, "the frame's rim is empty")

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

    def test_any_lpc_colour_with_the_all_palette(self):
        self.assertEqual(self._build({"y": {"body": "male", "skin": "all.lpcr.lemon"}}), [])
        sheet = Image.open(self.out / "y.png").convert("RGBA")
        self.assertEqual(sheet.getpixel((1, 1)), bs.hex_rgb(LEMON) + (255,))

    def test_antinium_edits_add_antennae_mandibles_and_arms(self):
        ant = {"body": "male", "skin": "light", "base": "body_person",
               "parts": [{"part": "heads_round"}]}
        self.assertEqual(self._build({"plain": ant}), [])
        edited = dict(ant, parts=ant["parts"] + [{"part": p} for p in bs.EDITS])
        self.assertEqual(self._build({"ant": edited}), [])
        plain = Image.open(self.out / "plain.png").convert("RGBA")
        sheet = Image.open(self.out / "ant.png").convert("RGBA")
        down = 2 * 64  # walk, facing down, frame 0
        def opaque(img, x0, x1, y0, y1):
            return sum(1 for y in range(y0, y1) for x in range(x0, x1) if img.getpixel((x, down + y))[3])
        self.assertEqual(opaque(plain, 0, 64, 0, 10), 0)
        self.assertGreater(opaque(sheet, 0, 64, 0, 10), 4, "antennae above the head")
        self.assertGreater(opaque(sheet, 0, 20, 22, 56), 0, "lower arms out beside the body")
        # Back view (walk row 0): antennae and arms, no mandibles.
        up = Image.open(self.out / "ant.png").convert("RGBA").crop((0, 0, 64, 64))
        self.assertGreater(sum(1 for y in range(10) for x in range(64) if up.getpixel((x, y))[3]), 4)
        # The attack frames get the edits too (facing down, in the middle of the frame).
        swing = sheet.crop((32, bs.ATTACK_Y + 2 * 128 + 32, 96, bs.ATTACK_Y + 2 * 128 + 96))
        self.assertGreater(sum(1 for y in range(10) for x in range(64) if swing.getpixel((x, y))[3]), 4)
        credits = self.credits.read_text(encoding="utf-8")
        self.assertNotIn("innworld", credits, "edits are not LPC parts")

    def test_attack_kind_follows_the_weapon(self):
        u = bs.Ulpc(self.ulpc)
        self.assertEqual(bs.attack_kind(u, {"parts": []}), "slash")
        self.assertEqual(bs.attack_kind(u, {"parts": [{"part": "weapon_spear"}]}), "thrust")
        self.assertEqual(bs.attack_kind(u, {"parts": [{"part": "weapon_sword"}]}), "slash_128")
        self.assertEqual(bs.attack_kind(u, {"parts": [{"part": "innworld_antennae"}]}), "slash")

    def test_weapons_stay_in_the_swing(self):
        self.assertEqual(self._build({
            "spear": {"body": "male", "skin": "light", "parts": [{"part": "weapon_spear", "color": "iron"}]},
            "sword": {"body": "male", "skin": "light", "parts": [{"part": "weapon_sword", "color": "steel"}]}}), [])
        blue, lemon, white = bs.hex_rgb(BLUE) + (255,), bs.hex_rgb(LEMON) + (255,), bs.hex_rgb(WHITE) + (255,)
        spear = Image.open(self.out / "spear.png").convert("RGBA")
        self.assertEqual(spear.getpixel((32 + 61, bs.ATTACK_Y + 32 + 61)), blue, "the thrust frames")
        sword = Image.open(self.out / "sword.png").convert("RGBA")
        self.assertEqual(sword.getpixel((121, bs.ATTACK_Y + 1)), lemon, "the 128 px slash, not cut to 64")
        attack = sword.crop((0, bs.ATTACK_Y, bs.SHEET_W, bs.SHEET_H))
        self.assertNotIn(white, attack.getdata(), "no walking sword in the swing")
        # The tail has no slash frames: it keeps its standing frame (at the frame's top left).
        layer = bs.part_layers(bs.Ulpc(self.ulpc), {"part": "tail", "color": "red"}, {"body": "male"})[0]
        tail = bs.layer_sheet(layer, "slash")
        self.assertEqual(tail.getpixel((32, bs.ATTACK_Y + 32))[:3], (0xc0, 0x20, 0x20))

    def test_edits_need_a_head(self):
        errors = self._build({"x": {"body": "male", "parts": [{"part": "innworld_antennae"}]}})
        self.assertEqual(len(errors), 1)
        self.assertIn("needs a body and a heads_* part", errors[0])

    def test_only_writes_the_named_looks(self):
        self._build({"a": {"body": "male"}, "b": {"body": "male"}}, only={"b"})
        self.assertFalse((self.out / "a.png").exists())
        self.assertTrue((self.out / "b.png").exists())


if __name__ == "__main__":
    unittest.main()
