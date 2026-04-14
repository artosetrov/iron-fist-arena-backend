---
title: Stamina
category: systems
tags: [stamina, energy, gating, monetization]
sources: [docs/06_game_systems/BALANCE_CONSTANTS.md]
updated: 2026-04-14
---

# Stamina

Energy gating system. Controls play session length.

## Constants

| Param | Value |
|-------|-------|
| Max stamina | 180 (was 120) |
| Regen rate | 1 per 8 min (24h full regen) |
| PvP cost | 10 |
| Training cost | 5 |
| Dungeon cost | 15–25 |
| Free PvP/day | 3 (no stamina cost) |

## Refill (Gems)

Diminishing cost per refill per day:
- 1st: 50 gems (was 30)
- 2nd: 80 gems
- 3rd: 140 gems
- 4th: 240 gems

This curve intentionally punishes binge refilling. See [[why-diminishing-refills]].

## Design Intent

- F2P players get ~18 PvP fights/day (180 stamina ÷ 10 per fight) + 3 free
- Stamina potions exist as gold sink alternative to gem refills
- Max raised from 120→180 to reduce "login anxiety" — casual players don't feel punished for not logging in every 16 hours

## See Also

- [[economy]] (gem sinks)
- [[pvp-rating]]
- [[gold-mine]] (no stamina cost)
