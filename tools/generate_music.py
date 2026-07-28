"""Generate the placeholder music loop for The Unbound Pawn.

Writes assets/music/unbound_march.wav — a 16-second chiptune march that loops
seamlessly. The WAV carries an embedded `smpl` loop chunk covering the whole
file, so Godot's default WAV import mode ("Detect From WAV") turns it into a
forward-looping AudioStreamWAV with no import-dock tweaking.

Rerun after tweaking:  python3 tools/generate_music.py
Replace with real music by dropping a new file over the same path.
"""

import math
import os
import struct

SAMPLE_RATE = 22050
BPM = 112
BEAT = 60.0 / BPM          # seconds per quarter note
BARS = 8                   # 4/4, two passes of a four-chord progression
TOTAL_SECONDS = BARS * 4 * BEAT

OUT_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "music", "unbound_march.wav")

# A-minor march: Am, F, C, G — root/third/fifth as MIDI notes, repeated twice.
PROGRESSION = [
    (57, 60, 64),  # Am
    (53, 57, 60),  # F
    (48, 52, 55),  # C
    (55, 59, 62),  # G
] * 2

# One-bar lead pattern per chord: (beat offset, chord tone index, length in beats)
LEAD_PATTERN = [
    (0.0, 2, 0.75),
    (1.0, 1, 0.75),
    (2.0, 0, 0.5),
    (2.5, 1, 0.5),
    (3.0, 2, 1.0),
]


def midi_to_hz(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def square(phase: float, duty: float = 0.5) -> float:
    return 1.0 if (phase % 1.0) < duty else -1.0


def triangle(phase: float) -> float:
    p = phase % 1.0
    return 4.0 * p - 1.0 if p < 0.5 else 3.0 - 4.0 * p


def render() -> list[float]:
    total_samples = int(TOTAL_SECONDS * SAMPLE_RATE)
    samples = [0.0] * total_samples

    # Bass: triangle root on every eighth note, short decay — the march feet.
    for bar, chord in enumerate(PROGRESSION):
        root_hz = midi_to_hz(chord[0] - 12)
        for eighth in range(8):
            start = (bar * 4 + eighth * 0.5) * BEAT
            _add_tone(samples, start, 0.22, root_hz, 0.16, triangle)

    # Lead: 25%-duty square melody walking the chord tones.
    for bar, chord in enumerate(PROGRESSION):
        for beat_offset, tone_index, length in LEAD_PATTERN:
            start = (bar * 4 + beat_offset) * BEAT
            hz = midi_to_hz(chord[tone_index] + 12)
            _add_tone(samples, start, length * BEAT * 0.9, hz, 0.10,
                      lambda p: square(p, 0.25))

    # Offbeat hat: a tick of decaying noise on every "and" — keeps the march moving.
    noise_state = 0x12345678
    for bar in range(BARS):
        for eighth in (1, 3, 5, 7):
            start_sample = int((bar * 4 + eighth * 0.5) * BEAT * SAMPLE_RATE)
            for i in range(int(0.03 * SAMPLE_RATE)):
                noise_state = (noise_state * 1103515245 + 12345) & 0x7FFFFFFF
                noise = (noise_state / 0x3FFFFFFF) - 1.0
                idx = start_sample + i
                if idx < total_samples:
                    samples[idx] += noise * 0.05 * (1.0 - i / (0.03 * SAMPLE_RATE))

    peak = max(abs(s) for s in samples)
    return [s / peak * 0.55 for s in samples]


def _add_tone(samples: list[float], start: float, length: float, hz: float,
              volume: float, wave) -> None:
    start_sample = int(start * SAMPLE_RATE)
    count = int(length * SAMPLE_RATE)
    for i in range(count):
        idx = start_sample + i
        if idx >= len(samples):
            break
        t = i / SAMPLE_RATE
        envelope = min(1.0, t / 0.01) * (1.0 - i / count) ** 0.35
        samples[idx] += wave(hz * t) * volume * envelope


def write_wav_with_loop(path: str, samples: list[float]) -> None:
    """Hand-rolled RIFF writer: fmt + data + smpl (loop over the whole file)."""
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)

    fmt_chunk = struct.pack("<HHIIHH", 1, 1, SAMPLE_RATE, SAMPLE_RATE * 2, 2, 16)
    sample_period_ns = int(1_000_000_000 / SAMPLE_RATE)
    loop = struct.pack("<IIIIII", 0, 0, 0, len(samples) - 1, 0, 0)  # forward loop, whole file
    smpl_chunk = struct.pack("<IIIIIIIII", 0, 0, sample_period_ns, 60, 0, 0, 0, 1, 0) + loop

    chunks = (
        b"fmt " + struct.pack("<I", len(fmt_chunk)) + fmt_chunk
        + b"data" + struct.pack("<I", len(frames)) + frames
        + b"smpl" + struct.pack("<I", len(smpl_chunk)) + smpl_chunk
    )
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks)


if __name__ == "__main__":
    write_wav_with_loop(OUT_PATH, render())
    print("wrote %s (%.1fs loop)" % (os.path.normpath(OUT_PATH), TOTAL_SECONDS))
