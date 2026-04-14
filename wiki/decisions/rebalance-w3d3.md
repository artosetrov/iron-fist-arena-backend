---
title: "W3.D3 Economy Rebalance (2026-04-10)"
category: decisions
tags: [economy, balance, rebalance, gold, cha]
sources: [docs/06_game_systems/BALANCE_CONSTANTS.md, docs/02_product_and_features/ECONOMY.md]
updated: 2026-04-14
---

# W3.D3 Economy Rebalance

**Date:** 2026-04-10

## What Changed

| Parameter | Before | After | Why |
|-----------|--------|-------|-----|
| Win streak cap | +100% at 8+ | +50% at 5+ | Top players farming too much gold via streaks |
| CHA gold bonus cap | +125% | +80% | CHA-stacking builds broke economy simulation |
| Repair costs | base formula | +25% | Durability system needed stronger sink |
| Consumable prices | base | +25% | Potions were too cheap relative to gold income |
| Stamina refill (1st) | 30 gems | 50 gems | Refills were too accessible, compress session length |
| Gold mine boost | 3 gems | 15 gems | Was essentially free, no real decision |
| Protection scroll | 50 gems | 40 gems | Slight buff to offset repair cost increase |
| Battle pass premium | 500 gems | 700 gems | Align with new gem pricing |

## Rationale

Monte Carlo simulator showed sink ratios drifting below targets for Active and Whale archetypes. CHA-stacking warriors were earning 2.5× intended gold per fight. Win streak system rewarded the already-winning disproportionately.

## Impact

Post-rebalance simulation results:
- Casual: 57.9% (target 55–65%) ✓
- Active: 62.3% (target 60–70%) ✓
- Whale: 74.3% (target 70–80%) ✓

## See Also

- [[economy]]
- [[stamina]]
- [[why-exponential-upgrades]]
