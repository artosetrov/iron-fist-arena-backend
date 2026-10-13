#!/usr/bin/env python3
"""
check_ladder_parity.py — PvP tier ladder drift detector.

The 2026-09-10 audit found the same ladder written out four times:

  * backend/src/lib/game/tier.ts        8 tiers x 3 divisions, Silver at 750
  * Hexbound/.../Enums/PvPRank.swift    6 tiers, no divisions, Silver at 1200
  * Hexbound/.../DarkFantasyTheme.swift a third set of colour thresholds
  * admin .../balance-client.tsx        editable floors nothing ever read

On one account the leaderboard said "Silver II" while the arena badge beside
it said "Bronze". The client now renders a ladder the server sends
(`PvPLadderContract` -> `PvPLadder`), so tier.ts is the only classifier. Two
copies of the *numbers* necessarily remain:

  1. `PvPLadder.fallback` in Swift — drawn on a cold start, before the first
     /api/game/init answers.
  2. The `defaultValue` shown for each `pvp_ranks.*` field in the admin balance
     panel — what an operator sees as "the current value" before overriding it.
  3. The `rank_*` achievement targets in the admin seeder. An achievement called
     "Silver" has to unlock where Silver starts; it shipped unlocking at 1200,
     which is Silver I.

Neither can import from tier.ts (different app, different language), so this
script is what keeps them honest.

Usage:
  python3 scripts/check_ladder_parity.py
  python3 scripts/check_ladder_parity.py --verbose

Exit codes:
  0 — all three tables agree
  1 — drift detected
  2 — a file or table could not be parsed (treated as failure: a checker that
      silently finds nothing is worse than no checker)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

TIER_TS = ROOT / "backend/src/lib/game/tier.ts"
LADDER_SWIFT = ROOT / "Hexbound/Hexbound/Models/PvPLadder.swift"
ADMIN_BALANCE = ROOT / "admin/src/app/(dashboard)/balance/balance-client.tsx"
ADMIN_ACHIEVEMENTS = ROOT / "admin/src/actions/achievement-definitions.ts"

# Achievements named after a tier must unlock at that tier's floor. The backend
# catalog derives them from tier.ts; the admin seeder cannot import it.
RANK_ACHIEVEMENT_TIERS = {
    "rank_silver": "silver",
    "rank_gold": "gold",
    "rank_diamond": "diamond",
    "rank_grandmaster": "grandmaster",
}

VERBOSE = "--verbose" in sys.argv


def fail(message: str, code: int = 1) -> None:
    print(f"[ladder-parity] {message}")
    sys.exit(code)


def read(path: Path) -> str:
    if not path.is_file():
        fail(f"missing file: {path.relative_to(ROOT)}", 2)
    return path.read_text(encoding="utf-8")


def parse_tier_ts() -> list[dict]:
    """TIER_RANGES in tier.ts — the authority."""
    text = read(TIER_TS)
    match = re.search(
        r"const TIER_RANGES: readonly TierRange\[\] = \[(.*?)\n\] as const",
        text,
        re.S,
    )
    if not match:
        fail("could not locate TIER_RANGES in tier.ts", 2)

    tiers = []
    for row in re.finditer(
        r"\{\s*key:\s*'([a-z]+)'\s*,\s*displayName:\s*'([^']+)'\s*,"
        r"\s*ratingStart:\s*(\d+)\s*,\s*ratingEnd:\s*([^,]+?)\s*,"
        r"\s*divisions:\s*(\d+)\s*\}",
        match.group(1),
    ):
        key, display, start, end, divisions = row.groups()
        tiers.append(
            {
                "key": key,
                "displayName": display,
                "ratingStart": int(start),
                "ratingEnd": None if "INFINITY" in end.upper() else int(end),
                "divisions": int(divisions),
            }
        )

    if not tiers:
        fail("TIER_RANGES parsed as empty — the row pattern no longer matches", 2)
    return tiers


def parse_ladder_swift() -> list[dict]:
    """PvPLadder.fallback — the cold-start mirror."""
    text = read(LADDER_SWIFT)
    match = re.search(r"static let fallback = PvPLadder\((.*?)\n    \)", text, re.S)
    if not match:
        fail("could not locate PvPLadder.fallback in PvPLadder.swift", 2)

    tiers = []
    for row in re.finditer(
        r'Tier\(key:\s*"([a-z]+)",\s*displayName:\s*"([^"]+)",'
        r"\s*ratingStart:\s*(\d+),\s*ratingEnd:\s*(nil|\d+),"
        r"\s*divisions:\s*(\d+)\)",
        match.group(1),
    ):
        key, display, start, end, divisions = row.groups()
        tiers.append(
            {
                "key": key,
                "displayName": display,
                "ratingStart": int(start),
                "ratingEnd": None if end == "nil" else int(end),
                "divisions": int(divisions),
            }
        )

    if not tiers:
        fail("PvPLadder.fallback parsed as empty — the Tier(...) pattern no longer matches", 2)
    return tiers


def parse_admin_floors() -> dict[str, int]:
    """`pvp_ranks.*` defaultValue in the admin balance panel."""
    text = read(ADMIN_BALANCE)
    floors = {
        key: int(value)
        for key, value in re.findall(
            r"key:\s*'pvp_ranks\.([a-z]+)'.*?defaultValue:\s*(\d+)", text
        )
    }
    if not floors:
        fail("no pvp_ranks.* fields found in the admin balance panel", 2)
    return floors


def parse_admin_rank_achievements() -> dict[str, int]:
    """`rank_*` targets in the admin achievement seeder."""
    text = read(ADMIN_ACHIEVEMENTS)
    targets = {
        key: int(target)
        for key, target in re.findall(
            r"key:\s*'(rank_[a-z]+)',\s*target:\s*(\d+)", text
        )
    }
    if not targets:
        fail("no rank_* achievements found in the admin achievement seeder", 2)
    return targets


def main() -> None:
    server = parse_tier_ts()
    client = parse_ladder_swift()
    admin = parse_admin_floors()
    admin_achievements = parse_admin_rank_achievements()

    problems: list[str] = []

    if len(server) != len(client):
        problems.append(
            f"tier count: tier.ts has {len(server)}, PvPLadder.fallback has {len(client)}"
        )

    for index, expected in enumerate(server):
        if index >= len(client):
            problems.append(f"PvPLadder.fallback is missing tier '{expected['key']}'")
            continue
        actual = client[index]
        for field in ("key", "displayName", "ratingStart", "ratingEnd", "divisions"):
            if expected[field] != actual[field]:
                problems.append(
                    f"tier #{index} ({expected['key']}): {field} is "
                    f"{expected[field]!r} in tier.ts but {actual[field]!r} in PvPLadder.fallback"
                )

    server_floors = {t["key"]: t["ratingStart"] for t in server}

    for key, floor in sorted(server_floors.items()):
        if key not in admin:
            problems.append(f"admin balance panel has no 'pvp_ranks.{key}' field")
        elif admin[key] != floor:
            problems.append(
                f"pvp_ranks.{key}: defaultValue {admin[key]} in the admin panel "
                f"but {floor} in tier.ts — operators would see the wrong current value"
            )

    for key in sorted(set(admin) - set(server_floors)):
        problems.append(f"admin balance panel edits 'pvp_ranks.{key}', which is not a tier")

    for achievement, tier in sorted(RANK_ACHIEVEMENT_TIERS.items()):
        if tier not in server_floors:
            problems.append(f"'{achievement}' names tier '{tier}', which is not on the ladder")
        elif achievement not in admin_achievements:
            problems.append(f"admin achievement seeder has no '{achievement}'")
        elif admin_achievements[achievement] != server_floors[tier]:
            problems.append(
                f"{achievement}: target {admin_achievements[achievement]} in the admin seeder "
                f"but {tier} starts at {server_floors[tier]} — the badge would be awarded "
                f"at the wrong tier"
            )

    if VERBOSE:
        for tier in server:
            end = "open" if tier["ratingEnd"] is None else tier["ratingEnd"]
            print(
                f"  {tier['key']:<12} {tier['ratingStart']:>5} .. {end:<5} "
                f"divisions={tier['divisions']}"
            )

    if problems:
        print("[ladder-parity] DRIFT — the PvP ladder is written down more than once "
              "and the copies disagree:")
        for problem in problems:
            print(f"  - {problem}")
        print("\n  tier.ts is the authority. Update the other copies to match it.")
        sys.exit(1)

    print(
        f"[ladder-parity] OK — {len(server)} tiers agree across tier.ts, "
        f"PvPLadder.fallback, the admin balance panel and "
        f"{len(RANK_ACHIEVEMENT_TIERS)} rank achievements"
    )


if __name__ == "__main__":
    main()
