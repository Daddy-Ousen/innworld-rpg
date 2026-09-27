"""Build the UI blips and System chimes as WAV files (M12, ADR 0019).

Each sound is a few sine notes with a short attack and a decay. No randomness,
so the same code always writes the same bytes. Standard library only.

Run: python tools/build_sfx.py            (writes game/assets/audio/ui/*.wav)
     python tools/build_sfx.py --check    (fails if a file on disk differs)
"""

from __future__ import annotations

import argparse
import io
import math
import struct
import sys
import wave
from pathlib import Path

RATE = 22050
PEAK = 0.5  # of full scale, so the mix never clips
DEFAULT_OUT = Path(__file__).resolve().parent.parent / "game" / "assets" / "audio" / "ui"

# A note: (frequency Hz, start s, length s, loudness 0..1). Partials add a
# soft bell colour: (multiple of the frequency, loudness).
BELL = [(1.0, 1.0), (2.0, 0.35), (3.0, 0.12)]
PURE = [(1.0, 1.0)]

SOUNDS: dict[str, dict] = {
    # A short soft tick when the focus moves in a menu.
    "ui_move": {"partials": PURE, "decay": 40.0, "notes": [(1318.5, 0.0, 0.05, 0.5)]},
    # Confirm: two notes going up.
    "ui_ok": {"partials": BELL, "decay": 18.0, "notes": [(659.3, 0.0, 0.09, 0.8), (987.8, 0.06, 0.14, 0.8)]},
    # Back / cancel: two notes going down.
    "ui_back": {"partials": BELL, "decay": 18.0, "notes": [(987.8, 0.0, 0.09, 0.7), (659.3, 0.06, 0.14, 0.7)]},
    # A System page opens: a bright C major arpeggio (the Voice of the World).
    "chime": {"partials": BELL, "decay": 4.5, "notes": [
        (1046.5, 0.0, 0.9, 0.7), (1318.5, 0.09, 0.8, 0.6), (1568.0, 0.18, 0.7, 0.6), (2093.0, 0.27, 0.6, 0.4)]},
    # Levels and Skills page: a longer, higher run up to a held top note.
    "level_up": {"partials": BELL, "decay": 3.0, "notes": [
        (523.3, 0.0, 0.5, 0.6), (659.3, 0.08, 0.5, 0.6), (784.0, 0.16, 0.5, 0.6),
        (1046.5, 0.24, 0.6, 0.7), (1318.5, 0.32, 1.0, 0.8)]},
    # A class offer: an open minor chord that waits for an answer.
    "offer": {"partials": BELL, "decay": 2.2, "notes": [
        (440.0, 0.0, 1.3, 0.6), (659.3, 0.12, 1.2, 0.5), (880.0, 0.24, 1.1, 0.5), (1046.5, 0.5, 0.9, 0.5)]},
    # Knocked out: low notes falling away.
    "knockout": {"partials": BELL, "decay": 3.0, "notes": [
        (392.0, 0.0, 0.5, 0.7), (293.7, 0.2, 0.5, 0.7), (196.0, 0.4, 0.9, 0.8)]},
    # Morning page: two soft notes.
    "morning": {"partials": PURE, "decay": 4.0, "notes": [(784.0, 0.0, 0.6, 0.6), (1046.5, 0.18, 0.8, 0.6)]},
    # The magic door: a fast shimmer going up.
    "portal": {"partials": BELL, "decay": 6.0, "notes": [
        (600.0 * 2 ** (i / 4), i * 0.05, 0.5, 0.5) for i in range(9)]},
    # A Frost Faerie: a few quick high twinkles.
    "sparkle": {"partials": PURE, "decay": 18.0, "notes": [
        (2637.0, 0.0, 0.2, 0.6), (3136.0, 0.07, 0.2, 0.5), (2349.3, 0.14, 0.2, 0.5), (3520.0, 0.21, 0.25, 0.5)]},
    # A death in the news: a slow minor line falling to a low held D.
    "sad_sting": {"partials": BELL, "decay": 1.8, "notes": [
        (440.0, 0.0, 0.6, 0.6), (349.2, 0.3, 0.6, 0.6), (293.7, 0.6, 0.85, 0.7), (146.8, 0.6, 0.85, 0.5)]},
}


def samples(spec: dict) -> list[float]:
    """The sound as floats in -1..1, scaled so its peak is PEAK."""
    end = max(start + length for _, start, length, _ in spec["notes"])
    n = int(math.ceil(end * RATE))
    out = [0.0] * n
    attack = int(0.004 * RATE)
    for freq, start, length, loud in spec["notes"]:
        first = int(start * RATE)
        count = int(length * RATE)
        for i in range(count):
            t = i / RATE
            env = min(1.0, i / attack) if attack else 1.0
            env *= math.exp(-spec["decay"] * t)
            tail = count - i  # a 5 ms fade at the end, so no click
            env *= min(1.0, tail / (0.005 * RATE))
            v = sum(amp * math.sin(2 * math.pi * freq * mul * t) for mul, amp in spec["partials"])
            out[first + i] += loud * env * v
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


def render() -> dict[str, bytes]:
    return {name: wav_bytes(samples(spec)) for name, spec in SOUNDS.items()}


def check(out: Path, files: dict[str, bytes]) -> list[str]:
    """The names whose file on disk is missing or differs."""
    bad = []
    for name, data in files.items():
        p = out / f"{name}.wav"
        if not p.exists() or p.read_bytes() != data:
            bad.append(name)
    return bad


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--check", action="store_true", help="only compare the files on disk")
    args = ap.parse_args(argv)
    files = render()
    if args.check:
        bad = check(args.out, files)
        for name in bad:
            print(f"differs or missing: {name}.wav")
        return 1 if bad else 0
    args.out.mkdir(parents=True, exist_ok=True)
    for name, data in files.items():
        (args.out / f"{name}.wav").write_bytes(data)
        print(f"wrote {name}.wav ({len(data)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
