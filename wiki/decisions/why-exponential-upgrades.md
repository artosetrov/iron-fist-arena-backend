---
title: "Decision: Exponential Upgrade Costs"
category: decisions
tags: [economy, upgrades, whale, gold-sink]
sources: [docs/06_game_systems/BALANCE_CONSTANTS.md, docs/02_product_and_features/ECONOMY.md]
updated: 2026-04-14
---

# Why Exponential Upgrade Costs

## Decision

Equipment upgrade cost follows `150 × 1.4^N` where N is the current level.

| Level | Cost |
|-------|------|
| +1 | 210g |
| +5 | 808g |
| +8 | 2,216g |
| +10 | 4,344g |

Combined with decreasing success rates (+6 = 80%, +10 = 20%), reaching +10 costs ~20,000–50,000g in expected value.

## Rationale

This is the **primary gold sink** and the **dominant whale spend channel**. Without gem → gold conversion, whales spend by playing more (stamina refills) and sinking gold into upgrades. The exponential curve means:

- +5 is achievable for everyone (100% success, reasonable cost)
- +7 is a meaningful mid-game goal
- +10 is an endgame flex — requires massive gold investment
- The gap between +5 and +10 is large enough to motivate grinding, but not so large that it's P2W (stats scale linearly, not exponentially)

## Tradeoffs

**Pros:**
- Natural gold sink that scales with player progression
- Creates aspirational goals without hard walls
- Protection scrolls (40 gems) create secondary gem sink

**Cons:**
- RNG frustration at high levels (20% success at +10)
- Failed upgrades feel punishing — mitigated by protection scrolls

## See Also

- [[economy]]
- [[progression]]
- [[why-no-gem-to-gold]]
