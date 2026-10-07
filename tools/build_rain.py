"""Build the rain ambience loop as a WAV file (M19.0, ADR 0030).

Filtered noise: a soft hiss, a low rumble and sparse drops. The fixed seed makes
the same bytes every run. The tail is cross-faded into the head, so the loop
has no click. Standard library only.

Run: python tools/build_rain.py --out <file>.wav
Then (ffmpeg, once, on a dev machine):
     ffmpeg -i <file>.wav -c:a libvorbis -q:a 3 game/assets/audio/ambience/amb_rain.ogg
The `.import` file of the OGG needs `loop=true` (like the other beds).
"""

from __future__ import annotations

import argparse
import io
import math
import random
import struct
import sys
import wave
from pathlib import Path

RATE = 22050
SECONDS = 12.0
FADE = 1.5  # seconds of tail cross-faded into the head
SEED = 19
PEAK = 0.7  # of full scale
SAMPLES = int(RATE * SECONDS)


def render(seed: int = SEED) -> list[float]:
    """The loop: SAMPLES floats in -1..1. Its last sample runs into its first."""
    rng = random.Random(seed)
    n = SAMPLES
    fade = int(RATE * FADE)
    total = n + fade
    hiss: list[float] = []
    rumble: list[float] = []
    prev = 0.0
    low = 0.0
    slow = 0.0
    for _ in range(total):
        white = rng.uniform(-1.0, 1.0)
        # High-pass (difference) then a light smoothing: the hiss of many drops.
        hiss.append(white - prev)
        prev = white
        # A heavy low-pass: the rumble of rain on the ground.
        low += (white - low) * 0.02
        rumble.append(low)
        slow += (white - slow) * 0.0004
    drops = [0.0] * total
    for _ in range(int(SECONDS * 55)):
        at = rng.randrange(total - 400)
        amp = rng.uniform(0.15, 0.6)
        for k in range(400):
            drops[at + k] += amp * rng.uniform(-1.0, 1.0) * math.exp(-k / 60.0)
    mixed = [0.30 * hiss[i] + 3.2 * rumble[i] + 0.35 * drops[i] for i in range(total)]
    out = mixed[:n]
    for i in range(fade):
        w = i / fade
        # Equal power: the head and the tail are uncorrelated noise.
        out[i] = mixed[i] * math.sin(w * math.pi / 2) + mixed[n + i] * math.cos(w * math.pi / 2)
    # A slow swell, an exact number of cycles, so it loops.
    for i in range(n):
        out[i] *= 1.0 + 0.12 * math.sin(2 * math.pi * 3 * i / n) + 0.06 * math.sin(2 * math.pi * 7 * i / n)
    top = max(abs(v) for v in out) or 1.0
    return [v / top * PEAK for v in out]


def wav_bytes(values: list[float]) -> bytes:
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(round(v * 32767))) for v in values))
    return buf.getvalue()


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", type=Path, required=True, help="the WAV file to write")
    args = ap.parse_args(argv)
    data = wav_bytes(render())
    args.out.write_bytes(data)
    print(f"wrote {args.out} ({len(data)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
