---
title: Interactive Combat (v2)
category: systems
tags: [combat, interactive, predict, reveal, pvp]
sources: [docs/features/combat/, docs/retro/RETRO_2026-04-13.md]
updated: 2026-04-14
---

# Interactive Combat (v2)

Layer interactive choices over existing turn-based resolver. **Not a rewrite** — reuse-first philosophy.

## Core Loop

Per-strike cycle:
1. **Predict** (6s window) — player picks attack zone, defense zone, optional skill
2. **Auto-submit** on timeout (AI picks based on opponent read strip — deterministic, not random)
3. **Reveal** (1.4s animation) — show outcome
4. Three input channels converge into existing `resolveAttack()` pipeline

**Target fight length:** 45–75 seconds total.

## 9 Outcome States

miss, dodge, glancing, hit, anti-read, crit, execute, blocked, fatigue — all map to existing resolver flags, no new formulas.

## Telemetry Gates (Beta → Live)

| Metric | Target | Action if failed |
|--------|--------|-----------------|
| Average fight length | 45–75s | If >90s, cut timeout to 5s |
| Auto-submit rate | <20% of strikes | If >30%, UI too harsh |
| Skill usage rate | >40% when ready | If <40%, skills unreadable |
| Zone-match rate | 28–40% | Baseline 33% random |
| Win rate at ±200 ELO | 70–85% for higher side | If <60%, too random |
| Forfeit rate | <5% | If >10%, disconnect broken |

## Excluded from v1

- Ultimate Meter (deferred to v2) — too much to ship with new Predict/Reveal UI
- Custom animations per skill
- Spectator mode

## Feature Flag

Enabled by default but can be toggled server-side for rollback.

## See Also

- [[combat]]
- [[stance-system]] (zone choices per strike, not per fight)
- [[pvp-rating]]
