---
title: Audit Block 314 — Combat Anatomy Generic Silhouette Boundary Sync
category: audit
tags: [audit, combat, ios, prototypes, retro]
sources:
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift
  - docs/retro/RETRO_2026-05-05.md
  - docs/07_ui_ux/COMBAT_SCREEN_REDESIGN.md
  - prototypes/combat-strike-anatomy.html
  - wiki/features/interactive-combat.md
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
updated: 2026-05-06
status: Fixed
---

# Audit Block 314 — Combat Anatomy Generic Silhouette Boundary Sync

## Scope

This block closes the next bounded combat-follow-up seam around the new anatomy
matrix:

- the live Swift comment, retro note, prototype header, and combat docs were
  all describing the middle silhouette slightly differently
- some of that wording still sounded closer to a generic placeholder than to
  the more precise repo truth: the anatomy matrix is shipped, but the current
  body art is still a temporary generic silhouette rather than final
  class-aware combat art

## Why this block

The important distinction is now:

- **Shipped:** anatomy matrix layout, zone readability, glow feedback, and the
  middle-column neutral silhouette path
- **Still open:** swapping that neutral silhouette for class-aware combat art

That distinction already existed in the code, but not in one clean shared
sentence across code comments, retro notes, docs, and the discussion prototype.

## Changes shipped

- Reworded `InteractiveBattleView.swift` so the body silhouette is now described
  as a temporary generic silhouette path rather than a looser placeholder note.
- Reworded `RETRO_2026-05-05.md` to the same runtime-vs-art boundary.
- Added the same clarification to `wiki/features/interactive-combat.md`.
- Tightened the status-boundary note in `COMBAT_SCREEN_REDESIGN.md`.
- Updated the header note in `prototypes/combat-strike-anatomy.html` so the
  discussion prototype matches the shipped Swift/runtime wording.
- Rolled the inventory forward again so it includes block `314`.

## Result

The anatomy branch now has one consistent checked-in truth: the new spatial
matrix is live, and the remaining art follow-up is specifically the swap from a
temporary generic silhouette to class-aware combat art.
