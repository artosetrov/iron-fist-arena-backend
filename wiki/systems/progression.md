---
title: Progression
category: systems
tags: [levels, stats, prestige, experience]
sources: [docs/06_game_systems/BALANCE_CONSTANTS.md, docs/02_product_and_features/GAME_SYSTEMS.md]
updated: 2026-04-14
---

# Progression

## Leveling

- Max level: **50**
- Stat points per level: **3** (147 total at L50)
- Level reward scale: **0.04** (doubled from 0.02 in Economy v3)

## Stats

6 base stats: STR, AGI, VIT, INT, WIS, LUK, CHA

Each class has primary/secondary scaling — see [[combat]] for damage formulas. CHA uniquely affects gold income — see [[economy]].

## Prestige

Reset at L50. Retain all gear. Prestige multiplier: `1 + (Prestige × 0.05)` — infinite scaling.

Design intent: endgame goal for dedicated players. +5% per prestige is meaningful but not overwhelming. Gear retention removes the "I lose everything" anxiety.

## Equipment Upgrades

8 equipment slots. Rarities: common → uncommon → rare → epic → legendary.

Upgrade system +0 to +10:
- **Cost:** 150 × 1.4^N (exponential) — see [[why-exponential-upgrades]]
- **Success rates:** +1 to +5 = 100%, +6 = 80%, +7 = 60%, +8 = 40%, +9 = 30%, +10 = 20%
- Protection scroll: 40 gems (prevents downgrade on fail)

## Skills

- 4 equippable skill slots
- Cooldowns: 1–5 turns
- Upgradeable ranks 1–5
- Learn cost: 200g, upgrade: 500 + 500 × rank

## Passive Tree

Node-based tree, 1 point per level. See [[passive-tree]].

## Drop Rates

| Source | Rate |
|--------|------|
| PvP win | 15% |
| Dungeon (easy) | 20% |
| Dungeon (hard) | 40% |
| Boss | 75% |

## See Also

- [[combat]]
- [[economy]]
- [[classes]]
- [[dungeons]]
