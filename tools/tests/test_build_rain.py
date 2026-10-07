"""Tests for tools/build_rain.py.

Run: python -m unittest discover -s tools/tests
"""

import io
import sys
import unittest
import wave
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import build_rain as br  # noqa: E402


class BuildRainTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.values = br.render()

    def test_render_is_fixed(self):
        self.assertEqual(br.render(), self.values, "same seed, same samples")

    def test_it_is_a_mono_wav_of_the_set_length_that_does_not_clip(self):
        with wave.open(io.BytesIO(br.wav_bytes(self.values))) as w:
            self.assertEqual(w.getnchannels(), 1)
            self.assertEqual(w.getsampwidth(), 2)
            self.assertEqual(w.getframerate(), br.RATE)
            self.assertEqual(w.getnframes(), br.SAMPLES)
        self.assertAlmostEqual(max(abs(v) for v in self.values), br.PEAK, places=6)

    def test_the_loop_has_no_click(self):
        # The step from the last sample to the first is no bigger than a normal step.
        steps = sorted(abs(self.values[i + 1] - self.values[i]) for i in range(len(self.values) - 1))
        seam = abs(self.values[0] - self.values[-1])
        self.assertLess(seam, steps[int(len(steps) * 0.999)])


if __name__ == "__main__":
    unittest.main()
