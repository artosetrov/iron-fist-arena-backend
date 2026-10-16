#!/usr/bin/env python3
"""check_audio_levels.py — the shipped audio has to be mixed, not whatever came out of the generator.

Until 2026-10-15 nothing measured the audio. `SFXManager.play` has no
per-sound volume at all — every effect plays at the single global
`settings.sfxVolume` — so the loudness baked into each file IS the mix. It
had drifted 38 dB wide, five clips clipped above 0 dBFS, and the variation
families were the worst of it: `play(_:)` picks a random take, and
`hit_critical`'s four takes spanned 15 dB, so the same critical hit was a
coin flip between a thud and a slam.

Three rules, in order of how objective they are:

  1. VARIATION SPREAD. Takes of one sound (`hit_physical.wav`,
     `hit_physical_2.wav`, …) must land within TAKE_SPREAD_DB of each other.
     Random loudness is not variety — it is a bug by construction, and this
     rule involves no taste at all.

  2. TRUE PEAK. Nothing above PEAK_CEILING_DB. Over 0 dBFS is clipping;
     a sliver of headroom below it also survives lossy re-encode.

  3. CATEGORY BAND. A clip far from its category's median is usually a
     broken asset. Usually — footsteps really are meant to sit 15 dB under
     combat. So this rule carries a baseline of accepted outliers, like
     check_a11y.py: it catches NEW drift and never blocks on the old.

Ambient is exempt from rule 3 on purpose: `AmbientManager` gives every layer
its own volume in code (`AmbientLayer(file:volume:)`), so that mix is
deliberate and lives outside the files. Rules 1 and 2 still apply.

MEASUREMENT. EBU R128 integrated loudness needs at least one 400 ms gated
block, so a clip shorter than SHORT_CLIP_S has no integrated value — twelve
of ours read -70 LUFS purely for that reason, and a naive gate would call
them silent. Those are measured by RMS instead. The two scales are NOT
interchangeable (measured here: median offset +0.9 dB but a 3 dB spread), so
they are never compared against each other: a family is measured one way
throughout, and the bands are per-scale.

Usage:
  python3 scripts/check_audio_levels.py              # the gate
  python3 scripts/check_audio_levels.py --report     # everything measured
  python3 scripts/check_audio_levels.py --write-baseline

Exit: 0 clean, 1 violations.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import statistics
import subprocess
import sys
from pathlib import Path

AUDIO_ROOT = Path("Hexbound/Hexbound/Resources/Audio")
BASELINE = Path("scripts/audio_levels_baseline.txt")
EXTS = (".wav", ".mp3", ".m4a", ".aac", ".caf")

TAKE_SPREAD_DB = 2.0
PEAK_CEILING_DB = -1.0
SHORT_CLIP_S = 0.5
BAND_DB = 10.0          # distance from the category median that counts as drift
BAND_EXEMPT = {"Ambient"}
MIN_AMBIENT_LOOP_S = 8.0   # AmbientManager loops every layer forever:
                           # a short file reads as a metronome, not a room

_I = re.compile(r"^\s*I:\s*(-?[\d.]+|-inf) LUFS", re.M)
_PEAK = re.compile(r"^\s*Peak:\s*(-?[\d.]+|-inf) dBFS", re.M)
_MEAN = re.compile(r"mean_volume:\s*(-?[\d.]+) dB")
_MAX = re.compile(r"max_volume:\s*(-?[\d.]+) dB")
_TAKE = re.compile(r"_(\d+)$")


def _f(value: str | None):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def measure(path: Path) -> dict:
    """Loudness, true peak and duration for one clip.

    `scale` says which number `level` is on: "LUFS" for integrated loudness,
    "RMS" for a clip too short to have one. Never mix the two.
    """
    ebur = subprocess.run(
        ["ffmpeg", "-nostdin", "-hide_banner", "-i", str(path),
         "-af", "ebur128=peak=true", "-f", "null", "-"],
        capture_output=True, text=True,
    ).stderr[-2000:]
    vol = subprocess.run(
        ["ffmpeg", "-nostdin", "-hide_banner", "-i", str(path),
         "-af", "volumedetect", "-f", "null", "-"],
        capture_output=True, text=True,
    ).stderr
    dur = _f(subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=nw=1:nk=1", str(path)],
        capture_output=True, text=True,
    ).stdout.strip())

    lufs = _f(_I.findall(ebur)[-1]) if _I.findall(ebur) else None
    peak = _f(_PEAK.findall(ebur)[-1]) if _PEAK.findall(ebur) else None
    rms = _f(_MEAN.search(vol).group(1)) if _MEAN.search(vol) else None
    if peak is None:
        peak = _f(_MAX.search(vol).group(1)) if _MAX.search(vol) else None

    short = dur is not None and dur < SHORT_CLIP_S
    usable_lufs = lufs is not None and lufs > -70
    if usable_lufs and not short:
        level, scale = lufs, "LUFS"
    else:
        level, scale = rms, "RMS"

    return {
        "path": str(path.relative_to(AUDIO_ROOT)),
        "category": path.relative_to(AUDIO_ROOT).parts[0],
        "level": level, "scale": scale,
        "lufs": lufs, "rms": rms, "peak": peak, "dur": dur,
    }


def family_levels(takes: list[dict]):
    """The comparable takes of one family, and the ruler to read them with.

    Mixed scales inside a family (one take under 400 ms, its siblings over)
    fall back to RMS, which every clip has. The normalizer calls this too —
    it has to equalize on exactly the ruler the gate measures with, or it
    flattens one scale and leaves the other spread.
    """
    usable = [t for t in takes if t["level"] is not None]
    if len({t["scale"] for t in usable}) > 1:
        usable = [t for t in usable if t["rms"] is not None]
        return usable, (lambda t: t["rms"])
    return usable, (lambda t: t["level"])


def family_of(rel: str) -> str:
    """`hit_physical_3.wav` and `hit_physical.wav` are takes of one sound."""
    stem = Path(rel).stem
    return str(Path(rel).parent / _TAKE.sub("", stem))


def scan(root: Path) -> list[dict]:
    files = sorted(p for p in root.rglob("*") if p.suffix.lower() in EXTS)
    return [measure(p) for p in files]


def violations(rows: list[dict]) -> list[str]:
    out: list[str] = []

    # 1 — takes of one sound must match
    families: dict[str, list[dict]] = {}
    for r in rows:
        families.setdefault(family_of(r["path"]), []).append(r)
    for name, takes in sorted(families.items()):
        usable = [t for t in takes if t["level"] is not None]
        if len(usable) < 2:
            continue
        usable, key = family_levels(takes)
        if len(usable) < 2:
            continue
        spread = max(key(t) for t in usable) - min(key(t) for t in usable)
        if spread > TAKE_SPREAD_DB:
            loud = max(usable, key=key)
            quiet = min(usable, key=key)
            out.append(
                f"take-spread {spread:.1f} dB in {name} "
                f"({Path(quiet['path']).name} .. {Path(loud['path']).name}) "
                f"— play(_:) picks a take at random"
            )

    # 2 — nothing may clip
    for r in rows:
        if r["peak"] is not None and r["peak"] > PEAK_CEILING_DB:
            out.append(f"peak {r['peak']:+.1f} dBFS in {r['path']} (ceiling {PEAK_CEILING_DB:+.1f})")

    # 3 — distance from the category median
    for cat in sorted({r["category"] for r in rows}):
        if cat in BAND_EXEMPT:
            continue
        for scale in ("LUFS", "RMS"):
            levels = [r for r in rows
                      if r["category"] == cat and r["scale"] == scale and r["level"] is not None]
            if len(levels) < 4:
                continue
            median = statistics.median(r["level"] for r in levels)
            for r in levels:
                delta = r["level"] - median
                if abs(delta) > BAND_DB:
                    out.append(
                        f"level {r['level']:.1f} {scale} is {delta:+.1f} dB from the "
                        f"{cat} median ({median:.1f}) — {r['path']}"
                    )

    # 4 — ambient layers loop forever, so they must not be one-shots.
    # amb_anvil_ambient was a 0.45 s hammer strike: on the hero screen it hit
    # twice a second until the player left. Fix with scripts/make_sparse_ambient.py.
    for r in rows:
        if r["category"] != "Ambient" or r["dur"] is None:
            continue
        if r["dur"] < MIN_AMBIENT_LOOP_S:
            out.append(
                f"loop {r['dur']:.2f}s in {r['path']} is under {MIN_AMBIENT_LOOP_S:.0f}s "
                f"— looped forever it ticks like a metronome"
            )

    return out


def load_baseline() -> set[str]:
    if not BASELINE.exists():
        return set()
    return {
        line.strip() for line in BASELINE.read_text().splitlines()
        if line.strip() and not line.startswith("#")
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", action="store_true", help="print every measurement")
    ap.add_argument("--write-baseline", action="store_true")
    ap.add_argument("--json", help="also dump measurements here")
    args = ap.parse_args()

    if not shutil.which("ffmpeg"):
        print("[audio-levels] SKIP — ffmpeg not installed")
        return 0
    if not AUDIO_ROOT.is_dir():
        print(f"[audio-levels] FAIL — {AUDIO_ROOT} not found (run from the repo root)")
        return 1

    rows = scan(AUDIO_ROOT)
    if args.json:
        Path(args.json).write_text(json.dumps(rows, indent=1))

    if args.report:
        for r in sorted(rows, key=lambda r: (r["category"], r["level"] if r["level"] is not None else 99)):
            lvl = f"{r['level']:7.1f} {r['scale']:4}" if r["level"] is not None else "      ?     "
            peak = f"{r['peak']:+6.1f}" if r["peak"] is not None else "     ?"
            print(f"{lvl}  peak {peak}  {r['dur']:7.2f}s  {r['path']}")
        print()

    found = violations(rows)

    if args.write_baseline:
        BASELINE.write_text(
            "# Accepted audio-level outliers. Shrinks, never grows.\n"
            "# Written by: python3 scripts/check_audio_levels.py --write-baseline\n"
            + "".join(f"{v}\n" for v in sorted(found))
        )
        print(f"[audio-levels] baseline written — {len(found)} entries")
        return 0

    known = load_baseline()
    new = [v for v in found if v not in known]
    stale = [v for v in known if v not in found]

    if new:
        print(f"[audio-levels] FAIL — {len(new)} new")
        for v in new:
            print(f"  - {v}")
        return 1

    note = f", {len(stale)} baseline entries now fixed (rerun --write-baseline)" if stale else ""
    print(f"[audio-levels] OK — {len(rows)} clips, {len(known)} known{note}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
