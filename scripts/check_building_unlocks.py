#!/usr/bin/env python3
"""check_building_unlocks.py — building unlock levels must agree across iOS and backend.

Two tables decide when a hub building opens, and they are written in
different files, in different languages, with different key spellings:

  - Hexbound/Hexbound/Views/Components/BuildingLockOverlay.swift
        BuildingUnlockConfig.levels   — keys are CityBuilding.id ("gold-mine")
  - backend/src/lib/game/tutorial.ts
        BUILDING_UNLOCK_LEVELS        — keys are snake_case ("gold_mine")

Character level is server-authoritative, so when they disagree the client
either shows a lock on a building the server already opened (dead tap) or
shows an open building the server still refuses (a 403 the player cannot
explain). The black market sat at 99 in both for months precisely because
nothing compared them.

Not a mechanical slug conversion: "ranks" maps to "leaderboard" and
"guild-hall" to "guild". KEY_MAP below is the authority for that, and a key
present on one side but missing from the map is itself an error — a new
building has to be taught to both tables.

Usage:  python3 scripts/check_building_unlocks.py [project_root]
Exit:   0 clean, 1 mismatch
"""
import re
import subprocess
import sys
from pathlib import Path

# CityBuilding.id (iOS)  ->  BUILDING_UNLOCK_LEVELS key (backend)
KEY_MAP = {
    "arena": "arena",
    "shop": "shop",
    "achievements": "achievements",
    "dungeon": "dungeon",
    "gold-mine": "gold_mine",
    "tavern": "tavern",
    "battlepass": "battle_pass",
    "ranks": "leaderboard",
    "guild-hall": "guild",
    "black-market": "black_market",
}

SWIFT = "Hexbound/Hexbound/Views/Components/BuildingLockOverlay.swift"
TS = "backend/src/lib/game/tutorial.ts"


def repo_root(argv):
    if len(argv) > 1:
        return Path(argv[1])
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        )
        return Path(out.stdout.strip())
    except Exception:
        return Path(".")


def block(text, header, path):
    """Return the text after `header` up to the matching closing bracket.

    The search starts past the header on purpose: the Swift one ends in
    "[String: Int] = [", so looking for "]" from the header's start finds the
    type annotation's bracket and returns nothing.
    """
    i = text.find(header)
    if i < 0:
        sys.exit(f"[building-unlocks] FAIL — {header!r} not found in {path}")
    start = i + len(header)
    closer = "]" if header.rstrip().endswith("[") else "}"
    j = text.index(closer, start)
    return text[start:j]


def main():
    root = repo_root(sys.argv)
    swift = (root / SWIFT).read_text()
    ts = (root / TS).read_text()

    ios = {
        m.group(1): int(m.group(2))
        for m in re.finditer(
            r'"([a-z-]+)"\s*:\s*(\d+)',
            block(swift, "static let levels: [String: Int] = [", SWIFT),
        )
    }
    backend = {
        m.group(1): int(m.group(2))
        for m in re.finditer(
            r"(\w+)\s*:\s*(\d+)",
            block(ts, "export const BUILDING_UNLOCK_LEVELS: Record<string, number> = {", TS),
        )
    }

    if not ios or not backend:
        sys.exit("[building-unlocks] FAIL — parsed an empty table; the file shape changed")

    problems = []
    for bid, lvl in sorted(ios.items()):
        key = KEY_MAP.get(bid)
        if key is None:
            problems.append(f"iOS building {bid!r} is not in KEY_MAP — add its backend key")
        elif key not in backend:
            problems.append(f"iOS building {bid!r} (lv {lvl}) has no {key!r} in {TS}")
        elif backend[key] != lvl:
            problems.append(f"{bid!r}: iOS says lv {lvl}, backend {key!r} says lv {backend[key]}")

    reverse = {v: k for k, v in KEY_MAP.items()}
    for key, lvl in sorted(backend.items()):
        if key not in reverse:
            problems.append(f"backend key {key!r} (lv {lvl}) is not in KEY_MAP — add its iOS id")
        elif reverse[key] not in ios:
            problems.append(f"backend key {key!r} (lv {lvl}) has no {reverse[key]!r} in {SWIFT}")

    if problems:
        print("[building-unlocks] FAIL")
        for p in problems:
            print(f"  - {p}")
        return 1

    print(f"[building-unlocks] OK — {len(ios)} buildings agree across iOS and backend")
    return 0


if __name__ == "__main__":
    sys.exit(main())
