---
title: Achievements
category: systems
tags: [achievements, tracking, progression, rewards]
sources: [docs/features/achievements/, backend/src/lib/game/achievement-catalog.ts]
updated: 2026-04-14
---

# Achievements

3 categories, 18 achievements. Auto-tracked — no manual claim required for progress.

## Categories

| Category | Tab | Tracked in |
|----------|-----|-----------|
| PvP | PvP | pvp/fight, pvp/resolve, pvp/revenge |
| Progression | Progress | applyLevelUp, prestige |
| Ranking | Ranking | pvp/fight, pvp/resolve |

## Tracking Rules

- **`absolute: true`** for stats that fluctuate (streaks, ratings, levels) — SET value, don't increment
- **Atomic increments** via raw SQL for counters (wins, completions)
- Adding new achievement requires: catalog → tracking call → display metadata → verify iOS tab
- **No tracking = stuck at 0/N forever** — this has happened

## Rewards

Claimable rewards can be currency or cosmetics:

- `gold`
- `gems`
- `xp`
- `title`
- `frame`

## Critical Rule

`updateMultipleAchievements()` with `absolute: true` must be called at the correct point in the flow. Missing the call is invisible until a player reports their achievement is stuck.

## See Also

- [[progression]]
- [[pvp-rating]]
- [[economy]] (achievement reward economy context)
