---
title: Character Classes
category: entities
tags: [classes, warrior, rogue, mage, tank, balance]
sources: [docs/06_game_systems/COMBAT.md, docs/06_game_systems/BALANCE_CONSTANTS.md]
updated: 2026-04-14
---

# Character Classes

4 classes: `warrior`, `rogue`, `mage`, `tank`

## Stat Scaling

| Class | Primary | Secondary | Damage Formula |
|-------|---------|-----------|---------------|
| Warrior | STR | — | STR × 1.5 + Level × 2 |
| Tank | STR, VIT | — | STR × 1.3 + VIT × 0.3 + Level × 2 |
| Rogue | AGI | — | AGI × 1.5 + Level × 2 |
| Mage | INT | WIS | INT × 1.4 + WIS × 0.25 + Level × 2 |

## Class Passives

| Class | Passive |
|-------|---------|
| Warrior | — (highest base damage) |
| Tank | 15% flat damage reduction |
| Rogue | +4% inherent dodge, Execute (+15% damage when target ≤35% HP) |
| Mage | — (magic damage, harder to mitigate) |

## Design Philosophy

- No hard counters — any class can beat any class
- Asymmetric strengths: Warrior = burst, Tank = sustain, Rogue = finisher, Mage = consistent magic damage
- CHA is class-neutral (affects gold, not combat directly)

## Origins (Cosmetic)

5 origins: `human`, `orc`, `skeleton`, `demon`, `dogfolk`

**NOT** elf, **NOT** dwarf. Origins are cosmetic only — no stat modifiers.

## See Also

- [[combat]]
- [[progression]]
