---
title: "Decision: Diminishing Stamina Refill Costs"
category: decisions
tags: [stamina, economy, gems, whales, monetization]
sources: [backend/src/lib/game/balance.ts, docs/06_game_systems/ECONOMY_RULES.md]
updated: 2026-04-14
---

# Why Diminishing Stamina Refill Costs

## Decision

Stamina refill cost escalates per refill per day: **50 → 80 → 140 → 240 gems**. Hard cap at **4 refills/day**.

## Rationale

Prevents whales from buying unlimited stamina at a flat rate. The 4th refill costs ~5× the 1st, creating a natural spending cap.

**Industry precedent:** Clash Royale (gem-for-gold), League of Legends (boosts), Genshin Impact (Fragile Resin) — all prevent unlimited energy buying at flat rate.

## Why Not Flat Rate?

A flat 50 gems per refill with no cap would let a whale buy 20 refills/day = 3,600 stamina = 360 PvP fights. This would:
- Destroy PvP matchmaking (whale farms 360 fights, free player does 21)
- Inflate gold supply (360 wins × 150g = 54,000g/day)
- Make leaderboard a spending contest, not a skill contest

As documented in balance.ts: *"there is no price that makes a 20-refill day healthy for the economy."*

## The Curve

| Refill # | Cost | Cumulative |
|----------|------|-----------|
| 1st | 50 gems | 50 |
| 2nd | 80 gems | 130 |
| 3rd | 140 gems | 270 |
| 4th | 240 gems | 510 |

510 gems total for 4 refills = 720 extra stamina = 72 extra PvP fights. That's substantial but bounded.

## Economy v3 Change

Base cost raised from 30 → 50 gems ([[rebalance-w3d3]]). The old 30-gem first refill was too accessible — players treated it as "free" rather than a meaningful decision.

## See Also

- [[stamina]]
- [[economy]]
- [[why-no-gem-to-gold]]
