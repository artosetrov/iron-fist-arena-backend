---
title: Audit Block 308 — Historical Planning-Header Parity Wave Two
category: audit
tags: [audit, docs, planning, ui-ux, combat]
sources:
  - docs/07_ui_ux/W3_D5_REVIEW_PLAN.md
  - docs/07_ui_ux/W2_D3_SCRIPTED_FIGHT_DESIGN.md
  - docs/07_ui_ux/W2_D2_REALITY_CHECK.md
  - docs/features/combat/INTERACTIVE_COMBAT_PLAN.md
updated: 2026-05-04
status: Fixed
---

# Audit Block 308 — Historical Planning-Header Parity Wave Two

## Scope

This block aligns another small cluster of historical W2/W3/combat planning
docs whose headline wording still sounded present-tense even though the body
already framed them as historical planning artifacts.

## Why this block

After block 307, a second little wave of the same pattern was still visible:

- the archival boundary note deeper in the file said "historical"
- but the opening line still implied that approval or execution was paused
  right now

That kind of mismatch is easy to ignore, but it makes these files read as more
active than they really are.

## Changes shipped

- Updated `W3_D5_REVIEW_PLAN.md` so the drafted line now reads like preserved
  planning context instead of a still-open approval request.
- Updated `W2_D3_SCRIPTED_FIGHT_DESIGN.md` so the status line now matches the
  already-historical tutorial-fight boundary note.
- Updated `W2_D2_REALITY_CHECK.md` so the status line now reads as a preserved
  plan-correction note rather than an active paused execution state.
- Updated `INTERACTIVE_COMBAT_PLAN.md` so its top status line now matches the
  existing historical boundary instead of sounding like a currently active
  planning document.

## Result

These historical planning docs now introduce themselves in the same archival
tense that the rest of the page already uses, which makes the docs layer read
more consistently and keeps the source-of-truth map calmer on first contact.
