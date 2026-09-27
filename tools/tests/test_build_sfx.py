"""Tests for tools/build_sfx.py.

Run: python -m unittest discover -s tools/tests
"""

import io
import sys
import tempfile
import unittest
import wave
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import build_sfx as bs  # noqa: E402


class BuildSfxTest(unittest.TestCase):
    def test_render_is_fixed(self):
        self.assertEqual(bs.render(), bs.render(), "same code, same bytes")

    def test_every_sound_is_a_short_mono_wav_that_does_not_clip(self):
        for name, data in bs.render().items():
            with wave.open(io.BytesIO(data)) as w:
                self.assertEqual(w.getnchannels(), 1, name)
                self.assertEqual(w.getsampwidth(), 2, name)
                self.assertEqual(w.getframerate(), bs.RATE, name)
                self.assertLess(w.getnframes() / bs.RATE, 1.5, f"{name} is short")
            peak = max(abs(v) for v in bs.samples(bs.SOUNDS[name]))
            self.assertAlmostEqual(peak, bs.PEAK, places=6, msg=name)

    def test_check_finds_missing_and_changed_files(self):
        files = bs.render()
        with tempfile.TemporaryDirectory() as d:
            out = Path(d)
            self.assertEqual(sorted(bs.check(out, files)), sorted(files))
            self.assertEqual(bs.main(["--out", d]), 0)
            self.assertEqual(bs.check(out, files), [])
            (out / "ui_ok.wav").write_bytes(b"x")
            self.assertEqual(bs.check(out, files), ["ui_ok"])

    def test_the_game_files_are_up_to_date(self):
        self.assertEqual(bs.check(bs.DEFAULT_OUT, bs.render()), [])


if __name__ == "__main__":
    unittest.main()
