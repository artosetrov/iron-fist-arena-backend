---
title: Audit Block 315 — Delete Orphan ActiveSlotsBar and Doc Parity
category: audit
tags: [audit, ios, passive-tree, docs, cleanup]
sources:
  - Hexbound/Hexbound/Views/Hero/Talents/ActiveSlotsBar.swift
  - Hexbound/Hexbound.xcodeproj/project.pbxproj
  - docs/retro/RETRO_2026-05-05.md
  - docs/02_product_and_features/ACTIVE_SKILL_PICKER_SPEC.md
  - docs/features/combat/INTERACTIVE_COMBAT_PLAN.md
  - wiki/audit/block-022-ios-active-skill-picker-passive-tree-contracts.md
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
updated: 2026-05-06
status: Fixed
---

# Audit Block 315 — Delete Orphan ActiveSlotsBar and Doc Parity

## Scope

This block closes the next concrete cleanup seam after the Active Slot unification
wave: `ActiveSlotsBar.swift` was still physically present in the repo tree even
though it had already been replaced in runtime, removed from `project.pbxproj`,
and described as dead/orphaned in retro notes.

## Why this block

The repo had drifted into an awkward half-state:

- runtime truth had already moved to `TalentsSummaryCard` + shared
  `ActiveSlotTile`
- `ActiveSlotsBar.swift` had **0 pbxproj references** and **0 call sites**
- docs/specs still pointed at the old file in a few places
- the retro explicitly said the file should be removed, but the working tree
  still carried it

That meant the repo was still shipping a dead file plus a doc layer that had
not fully caught up.

## Changes shipped

- Deleted `Hexbound/Hexbound/Views/Hero/Talents/ActiveSlotsBar.swift` from the
  working tree after confirming it was orphaned.
- Updated `RETRO_2026-05-05.md` so the orphan cleanup is now recorded as done in
  the working tree rather than deferred to "later on Mac".
- Replaced the stale "Current `ActiveSlotsBar`" reference in
  `ACTIVE_SKILL_PICKER_SPEC.md` with the live `TalentsSummaryCard` +
  `ActiveSlotTile` surface.
- Updated `INTERACTIVE_COMBAT_PLAN.md` so its historical `ActiveSlotsBar`
  references are explicitly marked as superseded rather than sounding live.
- Expanded `block-022` so its audit record now preserves the historical role of
  `ActiveSlotsBar.swift` while also naming the current live host/primitives that
  replaced it.
- Rolled the inventory forward again so it records the file as deleted from the
  working tree and includes block `315`.

## Result

The old `ActiveSlotsBar.swift` is no longer lingering as silent dead code in the
working tree, and the remaining docs now point at the real live Active Slot
surface instead of a file that had already fallen out of runtime.
