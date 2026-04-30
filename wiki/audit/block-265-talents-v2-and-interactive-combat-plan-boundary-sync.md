---
title: Audit Block 265 — Talents V2 and Interactive Combat Plan Boundary Sync
category: audit
tags: [audit, docs, passive-tree, interactive-combat, combat, runtime]
sources:
  - docs/06_game_systems/SKILL_TREE_DESIGN_V2.md
  - docs/features/combat/INTERACTIVE_COMBAT_PLAN.md
  - backend/prisma/seeds/passives-rogue-v2.sql
  - backend/prisma/seeds/passives-tank-v2.sql
  - wiki/audit/block-262-talents-v2-ult-action-types-and-class-trees.md
  - wiki/features/passive-tree.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 265 — Talents V2 and Interactive Combat Plan Boundary Sync

## Scope

This block closes the next design-doc truth tail around Talents v2 and the
historical Interactive Combat plan.

## Why this block

After `block-262`, the runtime had already moved ahead of two older design
surfaces:

- `SKILL_TREE_DESIGN_V2.md` still mixed active design with pre-ship ultimate
  assumptions and old memory-note wording.
- `INTERACTIVE_COMBAT_PLAN.md` already had a historical boundary banner, but
  its opening vision still described the superseded RPS stance model.
- Two checked-in Talents v2 seed comments had also drifted from the live
  shipped values.

## Changes shipped

### `docs/06_game_systems/SKILL_TREE_DESIGN_V2.md`

- Reframed the file as an active design reference with shipped deltas
  revalidated on `2026-04-29`.
- Added an explicit live-authority handoff to the checked-in seeds, strike
  resolver, `block-262`, and the passive-tree feature map.
- Updated shipped ult details where the design doc had drifted:
  - Rogue `Vanish` now reflects the shipped `75s` cooldown.
  - Tank `Fortress` now documents the shipped `shield_self` implementation as
    the live equivalent of the original Bastion reduction concept.
  - Tank `Earthshatter` now reflects the shipped `1 round` stun.
- Rewrote the active-skill-type reference so it describes the already-shipped
  9-type runtime instead of treating Talents v2 handlers as still pending.
- Removed the last pbxproj memory-note dependency.

### `docs/features/combat/INTERACTIVE_COMBAT_PLAN.md`

- Kept the file as a historical plan, but corrected the opening Vision section
  so it no longer contradicts its own later zone-based revision.
- Added an explicit note that the `§3 RPS Rules` section is preserved as a
  superseded branch, with the real replacement living in `§13.2`.
- Removed the old no-scale memory-note wording from the prototype checklist.

### Seed comment parity

- `backend/prisma/seeds/passives-rogue-v2.sql` comment now matches the shipped
  `Vanish` cooldown (`75`, not `60`).
- `backend/prisma/seeds/passives-tank-v2.sql` comment now matches the shipped
  `Earthshatter` magnitude (`1`, not `2`).

## Result

Talents v2 design docs now line up much more closely with the 2026-04-29
runtime landing, and the older Interactive Combat plan no longer opens by
re-stating a superseded RPS model as if it were still the active direction.
