---
title: Audit Block 305 — Inventory Rollforward and Combat-Strike Prototype Boundary Sync
category: audit
tags: [audit, inventory, combat, prototypes, wiki]
sources:
  - wiki/audit/project-file-inventory.md
  - docs/retro/RETRO_2026-05-04.md
  - prototypes/combat-strike-anatomy.html
  - wiki/features/interactive-combat.md
  - docs/07_ui_ux/COMBAT_SCREEN_REDESIGN.md
  - git ls-files
  - git ls-files --others --exclude-standard
updated: 2026-05-04
status: Fixed
---

# Audit Block 305 — Inventory Rollforward and Combat-Strike Prototype Boundary Sync

## Scope

This block rolls the inventory forward after the late tracked git shift that
landed immediately after block 304 and gives the newly checked-in
`combat-strike-anatomy.html` prototype an explicit checked-in boundary in the
combat docs/wiki layer.

## Why this block

Block 304 closed the combat-v3 retro and feature-map drift, but the repo moved
again right after that pass:

- `docs/retro/RETRO_2026-05-04.md` was now tracked
- `prototypes/combat-strike-anatomy.html` was now tracked
- `block-303` was no longer untracked

`project-file-inventory.md` still reflected the older state, so the top counts,
the `docs` / `prototypes` / `wiki` section totals, and one stale
`_(untracked)_` marker had already fallen behind live git again.

At the same time, the new strike-anatomy prototype was checked into the repo
with a solid local header comment, but the live combat docs/wiki layer was not
yet naming it as a discussion-only follow-up surface. That left it visible in
git but still a little under-explained in the source-of-truth map.

## Changes shipped

- Rolled `project-file-inventory.md` forward to the current tracked/untracked
  git state.
- Added the two missing tracked files:
  - `docs/retro/RETRO_2026-05-04.md`
  - `prototypes/combat-strike-anatomy.html`
- Removed the stale `_(untracked)_` marker from `block-303`.
- Re-synced the `docs`, `prototypes`, and `wiki` section totals inside the
  inventory.
- Updated `wiki/features/interactive-combat.md` so the checked-in combat
  follow-up prototype set now explicitly includes `combat-strike-anatomy.html`
  as a discussion-only surface.
- Updated `docs/07_ui_ux/COMBAT_SCREEN_REDESIGN.md` so the same prototype is
  clearly grouped with the newer discussion-only combat explorations rather
  than being left as an implicit live direction.

## Result

The inventory is back to matching live git again, the late tracked rollforward
is no longer invisible at the file-catalog layer, and the newest checked-in
combat anatomy prototype now has an explicit checked-in boundary in the live
combat docs/wiki map instead of floating as an orphaned tracked artifact.
