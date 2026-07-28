#!/usr/bin/env python3
"""Generate the game's placeholder SFX as small mono WAV files.

Build script (rerun after tweaking): python3 tools/generate_sfx.py
Writes assets/sfx/*.wav — chiptune-flavored, quiet, sub-second sounds that
the actor scenes' animation clips key through their AudioStreamPlayer.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")


def write_wav(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples
        )
        f.writeframes(frames)
    print("wrote", path, len(samples) / RATE, "s")


def env(i, n, attack=0.01, release=0.6):
    t = i / n
    a = min(1.0, t / max(attack, 1e-6))
    r = min(1.0, (1.0 - t) / max(release, 1e-6))
    return min(a, r)


def telegraph_warning():
    # Two rising square beeps: the "look out" tick before a strike.
    samples = []
    for freq, dur in ((880.0, 0.09), (1174.0, 0.11)):
        n = int(RATE * dur)
        for i in range(n):
            s = 1.0 if math.sin(2 * math.pi * freq * i / RATE) > 0 else -1.0
            samples.append(s * 0.22 * env(i, n, 0.02, 0.35))
        samples.extend([0.0] * int(RATE * 0.02))
    write_wav("telegraph_warning.wav", samples)


def sword_whoosh():
    # Filtered noise sweep: a toy sword cutting air.
    random.seed(7)
    n = int(RATE * 0.15)
    samples = []
    last = 0.0
    for i in range(n):
        t = i / n
        cutoff = 0.75 - 0.55 * t
        last += cutoff * (random.uniform(-1, 1) - last)
        samples.append(last * 0.5 * env(i, n, 0.05, 0.45))
    write_wav("sword_whoosh.wav", samples)


def hurt_thud():
    # Low sine knock with fast decay: a piece taking a hit.
    n = int(RATE * 0.12)
    samples = []
    for i in range(n):
        t = i / n
        freq = 150.0 - 60.0 * t
        s = math.sin(2 * math.pi * freq * i / RATE)
        samples.append(s * 0.5 * env(i, n, 0.004, 0.75))
    write_wav("hurt_thud.wav", samples)


def defeat_crumple():
    # Descending buzz + noise: a captured piece toppling off the board.
    random.seed(3)
    n = int(RATE * 0.28)
    samples = []
    phase = 0.0
    last = 0.0
    for i in range(n):
        t = i / n
        freq = 380.0 * (1.0 - t) + 70.0
        phase += freq / RATE
        saw = 2.0 * (phase % 1.0) - 1.0
        last += 0.4 * (random.uniform(-1, 1) - last)
        samples.append((saw * 0.3 + last * 0.25) * env(i, n, 0.01, 0.5))
    write_wav("defeat_crumple.wav", samples)


if __name__ == "__main__":
    telegraph_warning()
    sword_whoosh()
    hurt_thud()
    defeat_crumple()
