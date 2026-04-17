---
title: Block 141 — prototype reference doc sync
category: audit
tags: [audit, docs, prototypes, source-of-truth]
sources:
  - docs/02_product_and_features/ACTIVE_SKILL_PICKER_SPEC.md
  - docs/retro/RETRO_2026-04-12.md
updated: 2026-04-17
status: Fixed
---

# Block 141 — prototype reference doc sync

## Scope

- `docs/02_product_and_features/ACTIVE_SKILL_PICKER_SPEC.md`
- `docs/retro/RETRO_2026-04-12.md`

## Why this block

`block-140` removed the last ownerless feature prototypes from `prototypes/`, but one live spec still talked as if one of those deleted files remained available, and one historical retro still carried an unresolved cleanup checkbox.

That was small, but it made the docs layer less honest than the repository state.

## What changed

### `docs/02_product_and_features/ACTIVE_SKILL_PICKER_SPEC.md`

- removed the stale claim that `active-skills-picker-prototype.html` still exists as the live prototype reference
- replaced it with a historical note that the prototype was removed during repo cleanup
- pointed the reader back to the shipped/native picker implementation and current ruleset instead of a dead HTML artifact

### `docs/retro/RETRO_2026-04-12.md`

- updated the junk-file follow-up checklist so it no longer reads as an unresolved present-tense task
- kept the retro itself historical, but made the cleanup state truthful: the junk-file residue discussed there has since been removed

## Problems resolved

1. **Live spec referenced deleted artifact**
   - Risk before: a reader could go looking for a prototype file that no longer exists.
   - Resolution: the spec now treats that prototype as removed history, not an active reference.

2. **Historical retro kept one cleanup task artificially open**
   - Risk before: the retro implied a cleanup question that has already been resolved by later audit work.
   - Resolution: the retrospective now explicitly records that later cleanup happened.

## Verification

- confirmed `ACTIVE_SKILL_PICKER_SPEC.md` no longer claims the deleted prototype is present
- confirmed the retro checklist now reflects the later cleanup instead of leaving the junk-file task open forever
- `git diff --check`

## Follow-up

- Apply the same “resolved later” cleanup whenever a historical note still carries open TODOs that have already been closed by later audit blocks.
