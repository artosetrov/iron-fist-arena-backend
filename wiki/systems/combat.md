---
title: Combat System
category: systems
tags: [combat, pvp, damage, balance]
sources: [docs/06_game_systems/COMBAT.md, docs/06_game_systems/BALANCE_CONSTANTS.md]
updated: 2026-04-14
---

# Combat System

Turn-based 1v1 combat. Max 15 turns per fight. Turn order determined by AGI. Draw condition: higher HP% wins.

## Damage Formulas (by class)

| Class | Formula |
|-------|---------|
| Warrior | STR × 1.5 + Level × 2 |
| Tank | STR × 1.3 + VIT × 0.3 + Level × 2 |
| Rogue | AGI × 1.5 + Level × 2 |
| Mage | INT × 1.4 + WIS × 0.25 + Level × 2 |

**Mitigation:** `damage × 100 / (100 + armor)`

**Special damage types:**
- Poison: penetrates 30% armor
- True damage: ignores mitigation entirely
- Tank passive: 15% flat damage reduction

## Crit System

- Crit chance = `min(LUK × 0.6 + AGI × 0.2 + stance_bonus, 50%)`
- Crit damage: 1.5×

## Dodge System

- Dodge = `min(AGI × 0.2 + LUK × 0.1 + class_bonus + stance, 30%)`
- Rogue inherent: +4% dodge
- CHA Miss Chance (separate from dodge): `min(defender_CHA × 0.2, 20%)` — misses deal zero damage

## Rogue Execute

+15% final damage when defender HP ≤ 35%. See [[why-rogue-execute]].

## Stance System

Three zones: head / chest / legs.
- Zone mismatch (attacker hits undefended zone): +5% offense
- Zone match (defender guards attacked zone): +15% defense
- Zone icons: `icon-helmet`, `icon-chest`, `icon-legs`

## Battle Fatigue

Turn 11+: escalating +10% damage per turn. Turn 15 = +50%. Prevents stall builds. See [[why-battle-fatigue]].

## See Also

- [[pvp-rating]]
- [[economy]] (gold rewards from combat)
- [[classes]]
- [[stance-system]]
