---
title: Audit Block 264 — Active Skill Picker Memory Boundary Sync
category: audit
tags: [audit, docs, passive-tree, interactive-combat, source-of-truth]
sources:
  - docs/02_product_and_features/ACTIVE_SKILL_PICKER_SPEC.md
  - wiki/features/passive-tree.md
  - wiki/features/interactive-combat.md
  - wiki/systems/passive-tree.md
  - wiki/audit/block-010-prisma-migrations-hotfixes-stash-interactive-premium.md
  - wiki/audit/block-022-ios-active-skill-picker-passive-tree-contracts.md
  - wiki/audit/block-262-talents-v2-ult-action-types-and-class-trees.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 264 — Active Skill Picker Memory Boundary Sync

## Scope

This block removes the last external memory-note references from the historical
Active Skill Picker spec and reanchors it to checked-in repo truth.

## Why this block

`ACTIVE_SKILL_PICKER_SPEC.md` had already been reframed as a historical
implementation snapshot in `block-256`, but several sections still depended on
external note names:

- optimistic-UI behavior
- migration-before-deploy guidance
- "Phase 1 shipped" / "Phase 3.B shipped" provenance

That left the doc half historical snapshot, half off-repo shorthand.

## Changes shipped

### `docs/02_product_and_features/ACTIVE_SKILL_PICKER_SPEC.md`

- Rephrased the optimistic-save note as a direct description of the live iOS
  mutation pattern, without depending on an external optimistic-UI note.
- Rewrote the migration step so it points at the project-wide
  migration-before-deploy rule directly instead of an external note.
- Replaced the old off-repo rollout references with checked-in repo anchors:
  - `wiki/features/interactive-combat.md`
  - `wiki/audit/block-022-ios-active-skill-picker-passive-tree-contracts.md`
  - `wiki/audit/block-010-prisma-migrations-hotfixes-stash-interactive-premium.md`
  - `wiki/audit/block-262-talents-v2-ult-action-types-and-class-trees.md`

### Companion sync

- `wiki/systems/passive-tree.md` was also corrected while this wave was open:
  Rogue Vanish now reflects the shipped `75s` cooldown and the Talents v2
  ult labels match the current seeded class trees.
- `block-262` itself no longer ends on an external memory pointer; its
  cross-round buff-state lesson now lives directly in checked-in wiki/audit
  surfaces.

## Result

The Active Skill Picker historical spec now stands entirely on repo-owned
references. It still preserves rollout history, but it no longer asks the
reader to reconstruct live behavior or migration policy from external memory
files.
