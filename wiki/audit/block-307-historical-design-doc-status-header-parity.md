---
title: Audit Block 307 — Historical Design-Doc Status-Header Parity
category: audit
tags: [audit, docs, ui-ux, combat, systems]
sources:
  - docs/07_ui_ux/COMBAT_SCREEN_REDESIGN.md
  - docs/07_ui_ux/W2_D5_BADGE_PRIORITY_DESIGN.md
  - docs/06_game_systems/SKILL_TREE_DESIGN.md
  - docs/06_game_systems/SKILL_TREE_DESIGN_V2.md
  - wiki/features/passive-tree.md
updated: 2026-05-04
status: Fixed
---

# Audit Block 307 — Historical Design-Doc Status-Header Parity

## Scope

This block aligns the top-line status wording of a few historical design docs
with the archival boundaries those same files already carry deeper in the page.

## Why this block

The repo had reached a slightly awkward state:

- several design docs were already correctly treated as historical/proposal
  references by the audit trail
- some of those same files already carried explicit "historical" boundary notes
- but their headline status lines still sounded like active present-tense
  approval was pending

That kind of mismatch is small, but it quietly makes the source-of-truth layer
feel less trustworthy than it really is.

## Changes shipped

- Updated `COMBAT_SCREEN_REDESIGN.md` so its header now matches its own
  historical status boundary.
- Updated `W2_D5_BADGE_PRIORITY_DESIGN.md` so the header reads as an archived
  badge-priority proposal instead of a currently pending design review.
- Updated `SKILL_TREE_DESIGN.md` so the header no longer presents the file as a
  still-pending live design draft.
- Added an explicit live-vs-historical boundary note to `SKILL_TREE_DESIGN.md`,
  handing current truth back to:
  - `docs/06_game_systems/SKILL_TREE_DESIGN_V2.md`
  - `wiki/features/passive-tree.md`

## Result

These historical design docs now introduce themselves honestly at the top of
the file instead of relying on later paragraphs to correct the first
impression. That keeps the docs layer calmer and makes the repo's own
source-of-truth boundaries easier to trust on first read.
