"""Tests for tools/build_creatures.py (M11.4). Uses tiny synthetic art where it can.

Run: python -m unittest discover -s tools/tests
"""

import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import build_creatures as bc  # noqa: E402
import build_sprites as bs  # noqa: E402


def _opaque(img: Image.Image, box) -> bool:
    return img.crop(box).getchannel("A").getbbox() is not None


class BuildCreaturesTest(unittest.TestCase):
    def test_ramp_maps_dark_to_first_and_light_to_last(self):
        img = Image.new("RGBA", (3, 1), (0, 0, 0, 0))
        img.putpixel((0, 0), (10, 10, 10, 255))
        img.putpixel((1, 0), (200, 200, 200, 255))
        out = bc.ramp_recolor(img, ["#ff0000", "#0000ff"])
        self.assertEqual(out.getpixel((0, 0)), (255, 0, 0, 255))
        self.assertEqual(out.getpixel((1, 0)), (0, 0, 255, 255))
        self.assertEqual(out.getpixel((2, 0))[3], 0, "clear pixels stay clear")
        with self.assertRaises(bc.BuildError):
            bc.ramp_recolor(img, ["#ffffff"])

    def test_hue_turns_colours_and_light_paints_white(self):
        img = Image.new("RGBA", (2, 1), (255, 0, 0, 255))
        img.putpixel((1, 0), (255, 255, 255, 255))
        out = bc.colour(img, {"hue": 120, "light": "#0000ff"})
        r, g, b, _ = out.getpixel((0, 0))
        self.assertGreater(g, 200)
        self.assertLess(r, 10)
        self.assertEqual(out.getpixel((1, 0)), (0, 0, 255, 255), "white takes the light colour")

    def test_a_creature_sheet_has_the_character_layout(self):
        with tempfile.TemporaryDirectory() as tmp:
            art = Path(tmp)
            sheet = Image.new("RGBA", (6 * 32, 4 * 32), (0, 0, 0, 0))
            for r in range(4):
                for c in range(6):
                    sheet.paste(Image.new("RGBA", (8, 10), (200, 150, 40, 255)), (c * 32 + 12, r * 32 + 20))
            sheet.save(art / "bee.png")
            out = bc.build_creature({"creature": "bee"}, art)
        self.assertEqual(out.size, (bs.SHEET_W, bs.SHEET_H))
        off = bs.anim_offsets()
        for r in range(4):
            y = (off["walk"] + r) * bs.FRAME
            self.assertTrue(_opaque(out, (0, y, 64, y + 64)), f"walk row {r}")
            self.assertTrue(_opaque(out, (8 * 64, y, 9 * 64, y + 64)), "all 9 walk frames")
            ay = bs.ATTACK_Y + r * bs.BIG
            self.assertTrue(_opaque(out, (5 * 128, ay, 6 * 128, ay + 128)), "all 6 attack frames")
        # the 32 px creature stands on the bottom middle of the 64 px frame
        box = out.crop((0, 2 * 64, 64, 3 * 64)).getchannel("A").getbbox()
        self.assertEqual(box, (28, 52, 36, 62))
        # in the attack block it stands where a 64 px frame in the middle would end (y 96)
        box = out.crop((0, bs.ATTACK_Y, 128, bs.ATTACK_Y + 128)).getchannel("A").getbbox()
        self.assertEqual(box[3], 94)
        # a made fall: the last hurt frame is lower and fainter than the first
        hy = off["hurt"] * bs.FRAME
        first = out.crop((0, hy, 64, hy + 64))
        last = out.crop((5 * 64, hy, 6 * 64, hy + 64))
        self.assertLess(last.getchannel("A").getbbox()[3] - last.getchannel("A").getbbox()[1],
                        first.getchannel("A").getbbox()[3] - first.getchannel("A").getbbox()[1])
        self.assertLess(max(last.getchannel("A").getdata()), 255)

    def test_drawn_creatures_need_no_art_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            for name in ("rock_crab", "snowman", "goat"):
                out = bc.build_creature({"creature": name}, Path(tmp))
                self.assertTrue(_opaque(out, (0, 2 * 64, 64, 3 * 64)), name)
                self.assertTrue(_opaque(out, (0, bs.ATTACK_Y, 128, bs.ATTACK_Y + 128)), name)
        crab_s, crab_e = bc.crab_frame("s"), bc.crab_frame("e")
        self.assertNotEqual(crab_s.tobytes(), crab_e.tobytes(), "the facings differ")
        self.assertNotEqual(bc.crab_frame("s", 0, 4).tobytes(), crab_s.tobytes(), "the attack reaches out")
        goat_s, goat_w = bc.goat_frame("s"), bc.goat_frame("w")
        self.assertNotEqual(goat_s.tobytes(), goat_w.tobytes(), "the goat's facings differ")
        self.assertNotEqual(bc.goat_frame("w", 0, 5).tobytes(), goat_w.tobytes(), "the goat's head lunges")
        self.assertNotEqual(bc.goat_frame("w", 1).tobytes(), goat_w.tobytes(), "the goat's legs move")

    def test_errors_for_unknown_creature_fall_and_missing_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(bc.BuildError):
                bc.build_creature({"creature": "dragon"}, Path(tmp))
            with self.assertRaises(bc.BuildError):
                bc.build_creature({"creature": "bee"}, Path(tmp))  # no bee.png
            with self.assertRaises(bc.BuildError):
                bc.build_creature({"creature": "rock_crab", "die": "melt"}, Path(tmp))

    def test_build_writes_only_creature_looks_and_build_sprites_skips_them(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            app = tmp / "appearance.json"
            app.write_text(json.dumps({"schema_version": 1, "looks": {
                "crab": {"creature": "rock_crab"}, "person": {"body": "male", "skin": "light"}}}), encoding="utf-8")
            out = tmp / "out"
            self.assertEqual(bc.build(app, out, art=tmp), [])
            self.assertEqual(sorted(p.name for p in out.iterdir()), ["crab.png"])
            ulpc = tmp / "ulpc"
            (ulpc / "sheet_definitions").mkdir(parents=True)
            errors = bs.build(ulpc, app, tmp / "out2", tmp / "CREDITS.md", {"crab"})
            self.assertFalse(any(e.startswith("crab") for e in errors), errors)

    def test_real_creature_looks_build(self):
        data = json.loads(bs.DEFAULT_APPEARANCE.read_text(encoding="utf-8"))
        creatures = {k: v for k, v in data["looks"].items() if bc.is_creature(v)}
        self.assertEqual(len(creatures), 12)  # M18.1: eater_goat; M13.6: creler_hatchling, creler_juvenile; M13.0: crypt_worm, giant_leech, shield_spider
        for look in creatures.values():
            self.assertEqual(bc.build_creature(look).size, (bs.SHEET_W, bs.SHEET_H))


if __name__ == "__main__":
    unittest.main()
