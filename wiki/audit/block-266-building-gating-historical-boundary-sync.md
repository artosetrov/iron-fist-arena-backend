---
title: Audit Block 266 — Building Gating Historical Boundary Sync
category: audit
tags: [audit, docs, tutorial, progression, historical-boundary]
sources:
  - docs/07_ui_ux/W2_D4_BUILDING_GATING_DESIGN.md
  - docs/02_product_and_features/GUILD_SYSTEM_SPEC.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 266 — Building Gating Historical Boundary Sync

## Scope

This block cleans the remaining external-memory residue inside the archived
building-gating design proposal.

## Why this block

`W2_D4_BUILDING_GATING_DESIGN.md` had already been reframed as a historical
proposal in earlier audit work, but two small details still depended on
external memory context:

- the no-scale animation rule
- the Guild Hall unlock question pointing at an off-repo guild-spec note

That left the doc mostly archival, but not fully self-contained.

## Changes shipped

- Rewrote the animation note as plain checked-in guidance:
  title/CTA motion uses opacity + blur only.
- Replaced the old guild-spec memory pointer with the checked-in
  [GUILD_SYSTEM_SPEC.md](/Users/artosetrov/Documents/Cursor%20AI/PVP%20RPG/docs/02_product_and_features/GUILD_SYSTEM_SPEC.md)
  plus the live shipped social/Guild Hall runtime question.

## Result

The archived building-gating proposal now stands on repo-owned references only.
It remains historical, but it no longer depends on external memory-note names
to explain its animation or Guild Hall readiness assumptions.
