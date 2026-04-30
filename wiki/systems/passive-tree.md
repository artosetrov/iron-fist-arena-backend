---
title: Passive Tree
category: systems
tags: [passives, talents, tree, progression, builds]
sources: [Hexbound/Hexbound/Models/PassiveTree.swift, Hexbound/Hexbound/Views/Hero/Talents/PassiveTreeViewModel.swift, backend/prisma/seeds/passives-warrior-v2.sql, backend/prisma/seeds/passives-rogue-v2.sql, backend/prisma/seeds/passives-mage-v2.sql, backend/prisma/seeds/passives-tank-v2.sql]
updated: 2026-04-29
---

# Passive Tree

Node-based talent tree. 1 passive point per level.

## Node Structure

Each node has:
- `id`, `nodeKey`, `name`, `description`
- `bonusType`: stat / keystone / ultimate
- `bonusStat`, `bonusValue` — the actual bonus
- `tier` — determines visual size (tier 3 = keystone 50pt, tier 5+ = ultimate 56pt, default = 44pt)
- `positionX/Y` — arbitrary coordinates (infinite canvas)
- `cost` — point cost to unlock
- `icon` — visual identifier

## Active Abilities

Some nodes grant active abilities (not just passives):
- `activeActionType` — Postgres enum, 9 values total (5 base + 4 Talents v2 ults shipped 2026-04-29):
  - **Base:** `burst_damage`, `heal_self`, `shield_self`, `stun_enemy` (1 round), `execute`
  - **Talents v2 ults:** `stealth` (next attack auto-crits — Rogue Vanish, CD 75), `aoe_damage` (1v1 alias of burst with distinct VFX — Mage Meteor, CD 90), `cooldown_reset` (zero other non-consumable slots — Mage Timewarp, CD 180), `aoe_stun` (multi-round opp stun via `interactiveActives.{p1,p2}_buffs.stunRoundsRemaining` — Tank Earthshatter, CD 120)
- `activeCooldown` — turns between uses
- `activeMagnitude` — power of the ability (interpretation depends on action type — fraction for damage, rounds for `aoe_stun`)
- **3 active slots** by default; a 4th premium slot can be unlocked for **100 gems** (POST `/api/passives/active-slots/unlock-premium`). Per-character count lives on `Character.activeSlotCount` (max 4)
- See `wiki/audit/block-262-talents-v2-ult-action-types-and-class-trees` for the strike-resolver handler details and `docs/06_game_systems/SKILL_TREE_DESIGN_V2.md` §8 for the action-type spec.

## Unlock Rules

- Start nodes (no parent) — unlockable immediately
- Other nodes require **adjacent unlocked parent** (BFS adjacency check)
- **Staged unlock pattern:** select nodes → preview cost → commit all at once
- Commit uses BFS from unlocked frontier to ensure dependency order

## Respec

- Returns all points
- **Costs gems** (server-configured amount)
- Same staged UI pattern as Stats tab

## Visual Design

- `TalentNodeView` — square tile language (44×44, keystone 54×54), 3px gold left-bar on unlocked, rank/cost pill top-right; 4 states: `unlocked`, `pending`, `unlockable`, `locked`
- Pending nodes pulse (gold dashed outline); unlockable nodes have a gold glow pulse
- `TalentTreeCanvas` — radial top glow, 24pt grid backdrop, corner brackets, solid gold connections between unlocked nodes, animated dashed lines onto unlockable neighbors
- `TalentsSummaryCard` — top card on the TALENTS tab (SP counter + 4 slot tiles); premium 4th slot shows purple gem + cost until bought

## See Also

- [[progression]]
- [[classes]] (stat synergies)
- [[combat]] (active abilities in combat)
