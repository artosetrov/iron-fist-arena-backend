---
title: Audit Block 270 — UI Playtest and Badge Plan Memory Boundary Sync
category: audit
tags: [audit, docs, ui-ux, historical-boundary, design-system]
sources:
  - docs/07_ui_ux/QA_PLAYTHROUGH_2026-04-10.md
  - docs/07_ui_ux/W2_D5_BADGE_PRIORITY_DESIGN.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 270 — UI Playtest and Badge Plan Memory Boundary Sync

## Scope

This block cleans the last small memory-note remnants from one historical
playtest report and one historical badge-design proposal.

## Why this block

These files were already correctly framed as historical material, but they
still depended on external note names for two very small ideas:

- no-custom-font-size recurrence
- no-scale animation guidance

The useful lesson was still valid; the off-repo shorthand was no longer needed.

## Changes shipped

### `docs/07_ui_ux/QA_PLAYTHROUGH_2026-04-10.md`

- Rewrote the "repeating bug" note so it stands directly on the checked-in CI /
  scanner argument, without naming an external font-size memory note.

### `docs/07_ui_ux/W2_D5_BADGE_PRIORITY_DESIGN.md`

- Rewrote the motion note as direct checked-in guidance:
  opacity pulse only, no scale animation.

## Result

The historical playtest and badge-design docs now preserve the same engineering
lesson in repo-owned prose, without needing external memory-note names.
