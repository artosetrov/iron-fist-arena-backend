---
title: Balance Audit Findings (Open Issues)
category: decisions
tags: [balance, audit, agi, xp, poison, cha, open-issues]
sources: [docs/11_archive/BALANCE_AUDIT_REPORT_2026-03-09.md, docs/retro/*]
updated: 2026-04-14
---

# Balance Audit Findings (Open Issues)

Critical findings from the 2026-03-09 balance audit. Some addressed, some still open.

## AGI Overpowered (OPEN)

AGI provides crit + dodge + initiative + Rogue damage bonus simultaneously. Rogues win ~85% of mirror matches. AGI is the only stat that affects 4 combat dimensions at once.

**Possible fixes:** Cap AGI contribution to dodge separately from crit. Or: split AGI into two stats (speed/dexterity).

## XP Progression Too Slow (PARTIALLY FIXED)

Original quadratic formula: level 50 = ~5.5 years of daily play. `LEVEL_REWARD_SCALE` doubled from 0.02 → 0.04 in Economy v3, but the core XP curve may still be too aggressive.

## Poison Ignores Too Much Armor (OPEN)

Poison penetrates 30% armor → Rogue vs Tank deals ~50% more effective damage than intended. Tank passive (15% reduction) partially compensates, but poison builds are disproportionately strong against the class designed to counter physical damage.

## CHA Gold Bonus Nerfed (ADDRESSED)

Originally +125% cap was too high — CHA-stacking builds broke economy. Capped to +80% in [[rebalance-w3d3]]. Still under observation.

## Gold Mine Income vs PvP (OPEN)

3-slot mine produces ~6,300 gold/day passively. Active PvP (21 fights/day) produces ~1,600 gold/day. Passive income is **4× higher** than active gameplay. This creates a perverse incentive against playing the game.

**Possible fixes:** Reduce mine output, increase PvP rewards, or make mine require active play (bonus minigame in Variant D is a step in this direction).

## See Also

- [[economy]]
- [[combat]]
- [[classes]] (AGI problem)
- [[minigames]] (mine income)
- [[rebalance-w3d3]]
