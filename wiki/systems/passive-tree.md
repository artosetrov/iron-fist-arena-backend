---
title: Passive Tree
category: systems
tags: [passives, talents, tree, progression, builds]
sources: [Hexbound/Hexbound/Models/PassiveTree.swift, Hexbound/Hexbound/Views/Hero/Talents/PassiveTreeViewModel.swift]
updated: 2026-04-14
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
- `activeActionType`: burst_damage / heal_self / shield_self / stun_enemy / execute
- `activeCooldown` — turns between uses
- `activeMagnitude` — power of the ability
- Max **3 active slots** by default

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

- `TalentNodeView` with 4 states: `unlocked`, `pending`, `unlockable`, `locked`
- Pending nodes pulse (gold dashed outline)
- Connections rendered as lines between nodes on `TalentTreeCanvas`
- Node size scales by tier (44pt → 50pt → 56pt) — all ≥ 44pt touch target per Apple HIG

## See Also

- [[progression]]
- [[classes]] (stat synergies)
- [[combat]] (active abilities in combat)
