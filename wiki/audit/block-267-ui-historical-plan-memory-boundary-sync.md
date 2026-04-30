---
title: Audit Block 267 — UI Historical Plan Memory Boundary Sync
category: audit
tags: [audit, docs, ui-ux, combat, daily-login, design-system]
sources:
  - docs/07_ui_ux/STRIKE_REVEAL_SHAPE_B_PLAN.md
  - docs/07_ui_ux/DAILY_LOGIN_CAROUSEL_REVIEW.md
  - docs/07_ui_ux/INTEGRATED_CARD_UNIFICATION.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 267 — UI Historical Plan Memory Boundary Sync

## Scope

This block cleans the next set of historical UI design/review docs that still
depended on external memory-note names even though their actual design intent
was already preserved inside the repo.

## Why this block

Three checked-in UI docs still mixed useful historical reasoning with
off-repo shorthand:

- `STRIKE_REVEAL_SHAPE_B_PLAN.md`
- `DAILY_LOGIN_CAROUSEL_REVIEW.md`
- `INTEGRATED_CARD_UNIFICATION.md`

The problem was no longer missing design intent; it was that animation rules,
reusability rationale, and no-scale guidance still pointed to external note
names instead of standing on their own.

## Changes shipped

### `STRIKE_REVEAL_SHAPE_B_PLAN.md`

- Rewrote the top summary so it talks about attack/defense read outcomes
  instead of older RPS shorthand.
- Removed memory-note wording from:
  - no-scale motion rule
  - pbxproj ID guidance
  - static-token verification note
  - caller-check reminders
  - reusability rationale for keeping clash chips private
  - English-only copy note
- Kept the actual implementation guidance intact.

### `DAILY_LOGIN_CAROUSEL_REVIEW.md`

- Rephrased the reusability argument so it stands as direct project guidance
  rather than as a pointer to an external note.
- Rewrote the no-scale animation reminder as plain checked-in motion guidance.

### `INTEGRATED_CARD_UNIFICATION.md`

- Removed the external linked memory reference from the portrait-animation
  discussion.
- Kept the important runtime point: opacity/gradient-only motion does not
  violate the no-scale rule, but future list contexts may still need
  `animated: Bool` for performance control.

## Result

These historical UI docs still read as historical snapshots, but they now
stand on repo-owned reasoning instead of external memory-note breadcrumbs.
