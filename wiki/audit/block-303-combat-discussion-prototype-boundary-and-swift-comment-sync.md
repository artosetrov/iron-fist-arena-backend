---
title: Audit Block 303 — Combat Discussion Prototype Boundary and Swift Comment Sync
category: audit
tags: [audit, combat, prototypes, ios, docs]
sources:
  - Hexbound/Hexbound/Views/Hero/Talents/TalentsTabView.swift
  - wiki/features/interactive-combat.md
  - docs/07_ui_ux/COMBAT_SCREEN_REDESIGN.md
  - docs/features/combat/COMBAT_V3_IMPLEMENTATION_PLAN.md
  - prototypes/combat-proto-v3.html
  - prototypes/combat-duel-header-compact.html
updated: 2026-05-04
status: Fixed
---

# Audit Block 303 — Combat Discussion Prototype Boundary and Swift Comment Sync

## Scope

This block aligns the newest checked-in combat discussion prototypes with the
surrounding combat docs/wiki layer and removes the last external feedback token
still sitting inside active Swift UI comments.

## Why this block

After the late tracked rollforward, two combat discussion prototypes were now
checked into the repo:

- `prototypes/combat-proto-v3.html`
- `prototypes/combat-duel-header-compact.html`

They already carried local comments explaining that they were exploratory, but
the surrounding combat docs/wiki still barely acknowledged them. That made the
repo slightly lopsided: the files were real, tracked artifacts, yet the
checked-in source-of-truth layer did not clearly say how they relate to the
older historical combat branches.

Separately, one active Swift comment still depended on an old external
feedback-note shorthand instead of preserving the motion rule directly in
checked-in prose.

## Changes shipped

- Rewrote the `TalentsTabView.swift` overlay comment so it now states the
  no-scale-motion rule directly instead of naming the old external feedback
  shorthand.
- Updated `wiki/features/interactive-combat.md` so the combat feature map now
  points at the newer `combat-proto-v3` and `combat-duel-header-compact`
  surfaces as discussion-only follow-up prototypes.
- Updated `COMBAT_SCREEN_REDESIGN.md` so its status boundary names the current
  checked-in combat prototype set explicitly instead of gesturing vaguely at
  “current prototypes”.
- Updated `COMBAT_V3_IMPLEMENTATION_PLAN.md` so the older B2-v3 implementation
  record no longer risks being conflated with the newer readability/compactness
  prototype pair.

## Result

The combat docs/wiki layer now gives the newer checked-in prototype files a
clear place in the repo narrative, and active Swift comments no longer depend
on external feedback-token shorthand to explain the motion rule they follow.
