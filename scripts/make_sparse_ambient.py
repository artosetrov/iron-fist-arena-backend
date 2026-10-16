#!/usr/bin/env python3
"""Turn one-shot ambient samples into sparse, loopable beds.

Some Ambient/*.wav files are single hits half a second long (an anvil strike,
a bone rattle, a pickaxe blow). AmbientManager loops every layer forever, so a
0.45 s one-shot becomes a metronome: two hammer blows a second, which is what
a player hears on the hero screen as "a sound ticking".

The fix is not volume — it is rhythm. Each hit is scattered across a long bed
with randomised gaps and gain, and anything running past the end wraps back to
the start so the loop seam carries no gap and no click.

Run from the repo root:  python3 scripts/make_sparse_ambient.py [--dry-run]
"""
from __future__ import annotations

import argparse
import array
import math
import os
import random
import sys
import wave

AUDIO_ROOT = "Hexbound/Hexbound/Resources/Audio/Ambient"

# file -> (bed seconds, min gap, max gap, min gain, max gain)
PLANS = {
    "amb_anvil_ambient.wav":   (48.0, 3.0,  8.0, 0.45, 0.85),
    "amb_bone_rattle.wav":     (48.0, 5.0, 13.0, 0.35, 0.75),
    "amb_pickaxe_distant.wav": (48.0, 3.5,  9.0, 0.45, 0.85),
    # Not a one-shot but a 4.4 s texture that fades in and out, so looping it
    # pulses every 4.4 s. Scattered, it becomes coins clinking across a shop.
    "amb_coins_ambient.wav":   (60.0, 5.0, 12.0, 0.40, 0.80),
}

PEAK_CEILING = 0.70          # linear, ~-3.1 dBFS — ambient beds sit low
SEED = 20261016              # deterministic output, so reruns are no-ops


def read_wav(path):
    with wave.open(path, "rb") as w:
        if w.getsampwidth() != 2:
            raise SystemExit(f"{path}: only 16-bit PCM supported")
        a = array.array("h")
        a.frombytes(w.readframes(w.getnframes()))
        return a, w.getnchannels(), w.getframerate()


def write_wav(path, samples, channels, rate):
    tmp = os.path.join(os.environ.get("TMPDIR", "/tmp"), os.path.basename(path) + ".tmp")
    with wave.open(tmp, "wb") as w:
        w.setnchannels(channels)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(samples.tobytes())
    # The device mount refuses unlink/rename, so copy the bytes in place.
    with open(tmp, "rb") as src, open(path, "wb") as dst:
        dst.write(src.read())
    os.remove(tmp)


def build(src, channels, rate, bed_s, gap_lo, gap_hi, gain_lo, gain_hi, rng):
    frames = int(bed_s * rate)
    bed = [0.0] * (frames * channels)
    src_frames = len(src) // channels
    # A DC offset in the source would stack with every overlap and thump
    # at each loop seam; strip it before anything is placed.
    dc = sum(src) / len(src) if len(src) else 0.0

    pos = rng.uniform(0, gap_hi)
    placed = 0
    while pos < bed_s:
        gain = rng.uniform(gain_lo, gain_hi)
        # Slight stereo placement so repeats do not land in the same spot.
        pan = rng.uniform(-0.35, 0.35)
        gl = gain * min(1.0, 1.0 - pan)
        gr = gain * min(1.0, 1.0 + pan)
        start = int(pos * rate)
        for i in range(src_frames):
            dst = (start + i) % frames          # wrap: the seam stays seamless
            for c in range(channels):
                g = gl if c == 0 else gr
                bed[dst * channels + c] += (src[i * channels + c] - dc) * g
        placed += 1
        pos += rng.uniform(gap_lo, gap_hi)

    peak = max((abs(v) for v in bed), default=0.0) / 32768.0
    if peak > PEAK_CEILING:
        scale = PEAK_CEILING / peak
        bed = [v * scale for v in bed]

    out = array.array("h", (max(-32768, min(32767, int(round(v)))) for v in bed))
    return out, placed, min(peak, PEAK_CEILING)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not os.path.isdir(AUDIO_ROOT):
        print(f"run me from the repo root (missing {AUDIO_ROOT})", file=sys.stderr)
        return 2

    for name, (bed_s, gap_lo, gap_hi, gain_lo, gain_hi) in PLANS.items():
        path = os.path.join(AUDIO_ROOT, name)
        src, channels, rate = read_wav(path)
        src_s = len(src) / channels / rate
        if src_s > bed_s / 3:
            print(f"{name}: already {src_s:.1f}s long — skipped")
            continue
        rng = random.Random(f"{SEED}:{name}")
        out, placed, peak = build(src, channels, rate, bed_s, gap_lo, gap_hi,
                                  gain_lo, gain_hi, rng)
        db = 20 * math.log10(max(peak, 1e-6))
        print(f"{name}: {src_s:.2f}s one-shot -> {bed_s:.0f}s bed, "
              f"{placed} hits, peak {db:.1f} dBFS")
        if not args.dry_run:
            write_wav(path, out, channels, rate)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
