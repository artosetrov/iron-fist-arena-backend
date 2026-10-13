---
title: Audit Block 316 — Historical ActiveSlotsBar Naming Boundary Sync
category: audit
tags: [audit, docs, passive-tree, combat, history]
sources:
  - docs/02_product_and_features/ACTIVE_SKILL_PICKER_SPEC.md
  - docs/features/combat/INTERACTIVE_COMBAT_PLAN.md
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
updated: 2026-05-06
status: Fixed
---

# Audit Block 316 — Historical ActiveSlotsBar Naming Boundary Sync

## Scope

This block closes the next tiny but real naming seam left after
`ActiveSlotsBar.swift` was removed from the working tree: a couple of historical
spec/plan docs still used `ActiveSlotsBar` as if it were the obvious current
surface name instead of a historical one.

## Why this block

After block `315`, the repo truth is now:

- live runtime surface = `TalentsSummaryCard` + shared `ActiveSlotTile`
- `ActiveSlotsBar` = historical rollout name / old file / old Figma naming

The remaining references in the historical picker and combat plans were not
wrong, but they still needed a small boundary note so readers would not treat
that name as the current active file surface.

## Changes shipped

- Reworded the historical problem/entry-point/implementation lines in
  `ACTIVE_SKILL_PICKER_SPEC.md` so `ActiveSlotsBar` is explicitly framed as the
  earlier host that later gave way to `TalentsSummaryCard`.
- Reworded the corresponding historical rollout/Figma references in
  `INTERACTIVE_COMBAT_PLAN.md` to the same model.
- Rolled the inventory forward again so it includes block `316`.

## Result

The old `ActiveSlotsBar` name now survives only as explicit history. The docs
no longer casually sound like that file is still the live slot-host surface.
