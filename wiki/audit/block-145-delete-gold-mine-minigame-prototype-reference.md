---
title: Block 145 — delete Gold Mine minigame prototype reference
category: audit
tags: [audit, prototypes, gold-mine, docs, deletion]
sources:
  - prototypes/gold_mine_minigame_prototype.html
  - GOLD_MINE_MINIGAME_PLAN.md
  - wiki/audit/block-001-root-files.md
updated: 2026-04-17
status: Fixed
---

# Block 145 — delete Gold Mine minigame prototype reference

## Scope

- `prototypes/gold_mine_minigame_prototype.html`
- `GOLD_MINE_MINIGAME_PLAN.md`
- `wiki/audit/block-001-root-files.md`

## Why this block

The Gold Mine minigame prototype was no longer carrying unique live value:

- the plan is already marked as implemented-with-drift
- the shipped feature now lives in backend/iOS code, not in this HTML exploration
- no active review or design workflow still names the prototype directly outside the old plan/audit trail

So the safe move was to keep the plan as historical documentation, but stop pretending the old prototype file still needs to exist.

## What changed

### `prototypes/gold_mine_minigame_prototype.html`

- **Previous role:** standalone Gold Mine minigame visual exploration
- **Why removal was safe:** no current docs/code flow still depended on the HTML file itself
- **Result:** removed from the working tree

### `GOLD_MINE_MINIGAME_PLAN.md`

- replaced the live dependency wording with a historical note
- kept the plan as an implementation record, but stopped implying the removed prototype is still part of the active reference set

### `wiki/audit/block-001-root-files.md`

- updated the row and cleanup summary so root audit no longer treats the Gold Mine prototype as a current retained reference

## Problems resolved

1. **Historical Gold Mine plan still pointed at a removable artifact**
   - Risk before: the plan implied a file dependency that no longer mattered to the shipped feature.
   - Resolution: the plan now keeps the historical context without requiring the artifact to stay in the tree.

2. **Prototype residue outlived its actual owner**
   - Risk before: the prototype layer still mixed current references with already-finished feature history.
   - Resolution: removed the now-ownerless Gold Mine prototype.

## Verification

- confirmed `prototypes/gold_mine_minigame_prototype.html` no longer exists in the working tree
- confirmed the Gold Mine plan now frames the prototype as removed historical context rather than an active dependency
- `git diff --check`

## Follow-up

- After this block, the remaining prototypes are down to combat history plus the legal-transition copies; review those separately, not as part of the generic prototype residue bucket.

