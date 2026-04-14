---
title: "Decision: Rogue Execute (+15% at ≤35% HP)"
category: decisions
tags: [combat, rogue, execute, balance, finisher]
sources: [docs/06_game_systems/COMBAT.md, backend/src/lib/game/balance.ts, backend/tests/lib/rogue-execute.test.ts]
updated: 2026-04-14
---

# Why Rogue Execute

## Decision

Rogues deal **+15% final damage** when attacking a defender whose current HP is at or below **35% of max HP**. Added in W3.D2.

## Problem It Solved

Rogues were kiting forever instead of closing kills. High dodge + moderate damage meant Rogues excelled at surviving but couldn't finish opponents efficiently. Fights dragged out, often hitting [[why-battle-fatigue|Battle Fatigue]] territory.

## Why This Design

- **Thematic:** Assassin finishing move — established RPG pattern (Diablo, Path of Exile, Genshin Impact, Raid: Shadow Legends)
- **Applied after all mitigation** — scales with actual floor damage, not raw. This means armor still matters.
- **35% threshold** — low enough that it only triggers in the kill window, not during normal trading
- **+15%** — meaningful but not overwhelming. A 100 damage hit becomes 115 — enough to tip the scales, not enough to one-shot

## Interaction with CHA Miss Chance

CHA stat gates the hit via pre-hit miss chance (not damage reduction). So a high-CHA defender can dodge the execute entirely — creating a natural counter. Introduced in W3.D1 rebalance.

## Unit Tested

`backend/tests/lib/rogue-execute.test.ts` — confirms the mechanic works correctly at boundary conditions.

## See Also

- [[combat]]
- [[classes]] (Rogue passive: +4% dodge + Execute)
- [[why-battle-fatigue]]
