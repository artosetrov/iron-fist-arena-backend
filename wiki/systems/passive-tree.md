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
- **3 active slots** by default; a 4th premium slot can be unlocked for **100 gems** (POST `/api/passives/active-slots/unlock-premium`). Per-character count lives on `Character.activeSlotCount` (max 4)

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
