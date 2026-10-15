#!/usr/bin/env python3
"""normalize_audio.py — make the shipped audio a mix instead of an accident.

Companion to check_audio_levels.py; read that file first for why this is
needed at all (short version: `SFXManager` has no per-sound volume, so the
level baked into each file IS the mix, and it had drifted 38 dB wide).

This does exactly two things, both of which are objectively wrong today and
neither of which requires a taste call:

  1. EQUALIZE TAKES. Every take of one sound is moved onto the family's
     median level. `play(_:)` picks a take at random, so a family spanning
     17 dB (hit_critical did) means the same critical hit is a coin flip
     between a thud and a slam. Takes are meant to vary in timbre, never in
     volume.

  2. DUCK UNDER THE CEILING. Anything peaking above the ceiling comes down
     to it. Five clips were over 0 dBFS outright.

The two interact: raising a quiet take onto the family median can push it
into the ceiling. Rather than let one take sit lower than its siblings — the
exact bug being fixed — the WHOLE family moves down by the worst overshoot,
so it stays equal and stays clean.

What this does NOT touch, on purpose:

  - Loudness differences BETWEEN sounds. Footsteps really are meant to sit
    well under combat, and no script can tell that apart from a broken
    asset. check_audio_levels.py reports those against a baseline and a
    human decides.
  - Ambient. `AmbientManager` gives every layer its own volume in code, so
    that mix is deliberate and lives outside the files. Peak safety only.

Lossless in, lossless out for WAV. MP3 and AAC are re-encoded at their
source bitrate, which is unavoidable for a gain change and inaudible at the
256k/128k/64k this project ships.

Usage:
  python3 scripts/normalize_audio.py --dry-run     # what would change
  python3 scripts/normalize_audio.py               # do it
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_audio_levels import (  # noqa: E402
    AUDIO_ROOT, EXTS, PEAK_CEILING_DB, family_levels, family_of, measure,
)

MIN_GAIN_DB = 0.3      # below this the change is inaudible and not worth a re-encode

# Aim below the gate's ceiling rather than exactly at it. Two reasons: a
# lossy re-encode moves peaks by a few tenths of a dB in either direction,
# and landing exactly on the line means MIN_GAIN_DB later refuses the 0.1 dB
# nudge that would fix it. PCM has no re-encode drift, so it needs less room.
CEILING_MARGIN_DB = {"pcm": 0.2, "lossy": 1.0}


def ceiling_for(path: Path) -> float:
    lossy = path.suffix.lower() in (".mp3", ".m4a", ".aac")
    return PEAK_CEILING_DB - CEILING_MARGIN_DB["lossy" if lossy else "pcm"]


def encode_args(path: Path) -> list[str]:
    """Keep the file in the format it arrived in."""
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "a:0",
         "-show_entries", "stream=codec_name,bit_rate,sample_fmt",
         "-of", "default=nw=1:nk=1", str(path)],
        capture_output=True, text=True,
    ).stdout.split()
    codec = probe[0] if probe else ""
    fmt = probe[1] if len(probe) > 1 else ""
    rate = next((p for p in probe if p.isdigit() and int(p) > 8000), None)

    if codec.startswith("pcm"):
        return ["-c:a", codec]
    if codec == "mp3":
        return ["-c:a", "libmp3lame", "-b:a", rate or "192k"]
    if codec == "aac":
        return ["-c:a", "aac", "-b:a", rate or "128k"]
    return []  # let ffmpeg decide


def apply_gain(path: Path, gain_db: float) -> None:
    """Rewrite `path` `gain_db` louder, in place.

    Written through a temp file and then copied back by TRUNCATING the
    original rather than renaming over it: the repo lives on a mount where
    unlink is refused, and rename would need one.
    """
    with tempfile.NamedTemporaryFile(suffix=path.suffix, delete=False) as tmp:
        tmp_path = Path(tmp.name)
    try:
        subprocess.run(
            ["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
             "-i", str(path), "-af", f"volume={gain_db:.2f}dB",
             *encode_args(path), str(tmp_path)],
            check=True, capture_output=True,
        )
        data = tmp_path.read_bytes()
        with open(path, "wb") as dst:
            dst.write(data)
    finally:
        tmp_path.unlink(missing_ok=True)


def plan(rows: list[dict]) -> dict[str, float]:
    """Gain in dB per relative path. Absent means leave it alone."""
    gains: dict[str, float] = {}

    families: dict[str, list[dict]] = {}
    for r in rows:
        families.setdefault(family_of(r["path"]), []).append(r)

    for takes in families.values():
        usable = [t for t in takes if t["rms"] is not None and t["peak"] is not None]
        if not usable:
            continue

        comparable, key = family_levels(usable)
        if len(comparable) > 1:
            # The gate's ruler, not a second one of our own: equalizing RMS
            # while the gate reads LUFS leaves the spread it came to remove.
            levels = sorted(key(t) for t in comparable)
            target = levels[len(levels) // 2]
            family_gain = {t["path"]: target - key(t) for t in comparable}
        else:
            comparable = usable
            family_gain = {t["path"]: 0.0 for t in usable}

        # Would equalising push anyone past the ceiling? Move the family,
        # not the individual — otherwise we reintroduce the spread we came
        # to remove. The test is the gate's ceiling; only once something
        # actually fails it do we aim for the margin below, so a clip that
        # already passes is never re-encoded for a tenth of a dB.
        worst = max(t["peak"] + family_gain[t["path"]] for t in comparable)
        if worst > PEAK_CEILING_DB:
            hottest = max(comparable, key=lambda t: t["peak"] + family_gain[t["path"]])
            trim = ceiling_for(AUDIO_ROOT / hottest["path"]) - worst
        else:
            trim = 0.0

        for t in comparable:
            g = family_gain[t["path"]] + trim
            # A ceiling fix always applies; only cosmetic equalising is
            # skipped as too small to be worth a re-encode.
            if abs(g) >= MIN_GAIN_DB or trim < 0:
                gains[t["path"]] = g

    return gains


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not AUDIO_ROOT.is_dir():
        print(f"[normalize-audio] FAIL — {AUDIO_ROOT} not found (run from the repo root)")
        return 1

    files = sorted(p for p in AUDIO_ROOT.rglob("*") if p.suffix.lower() in EXTS)
    rows = [measure(p) for p in files]
    gains = plan(rows)

    if not gains:
        print("[normalize-audio] nothing to change")
        return 0

    for rel, g in sorted(gains.items(), key=lambda kv: -abs(kv[1])):
        print(f"  {g:+6.2f} dB  {rel}")
    print(f"[normalize-audio] {len(gains)} of {len(rows)} clips"
          + (" (dry run)" if args.dry_run else ""))

    if args.dry_run:
        return 0

    for rel, g in gains.items():
        apply_gain(AUDIO_ROOT / rel, g)
    print("[normalize-audio] done — rerun check_audio_levels.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
