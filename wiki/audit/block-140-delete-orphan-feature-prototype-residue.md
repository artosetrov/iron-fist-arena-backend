---
title: Block 140 — delete orphan feature prototype residue
category: audit
tags: [audit, prototypes, deletion, cleanup]
sources:
  - prototypes/active-skills-picker-prototype.html
  - prototypes/boss-card-prototype.html
  - prototypes/contraband_widget_prototype.html
  - prototypes/daily-login-prototype.html
  - prototypes/gold-mine-prototype.html
  - prototypes/hero-card-hp-energy-prototype.html
updated: 2026-04-17
status: Fixed
---

# Block 140 — delete orphan feature prototype residue

## Scope

- `prototypes/active-skills-picker-prototype.html`
- `prototypes/boss-card-prototype.html`
- `prototypes/contraband_widget_prototype.html`
- `prototypes/daily-login-prototype.html`
- `prototypes/gold-mine-prototype.html`
- `prototypes/hero-card-hp-energy-prototype.html`

## Why this block

After the earlier prototype cleanup, these six files were still sitting in `prototypes/` as local historical residue, but they no longer had a maintained source-of-truth role:

- no live product import path
- no retained reference role in the current prototype bridge set
- no active wiki/docs consumer beyond stale inventory lines

That made them the next safe deletion slice.

## Related pages

- [[block-121-prototypes-link-parity-and-transition-state]]
- [[block-136-delete-root-orphan-prototype-artifacts]]
- [[block-138-delete-deprecated-prototype-residue]]
- [[block-139-delete-superseded-combat-prototype-set]]

## What was removed

### `prototypes/active-skills-picker-prototype.html`

- **Previous role:** early active-skill picker exploration
- **Why removal was safe:** the shipped/native picker flow now lives in code and the spec remains as the higher-value artifact
- **Result:** removed from the working tree

### `prototypes/boss-card-prototype.html`

- **Previous role:** boss-card visual exploration
- **Why removal was safe:** no maintained doc or product surface still pointed at it
- **Result:** removed from the working tree

### `prototypes/contraband_widget_prototype.html`

- **Previous role:** contraband widget exploration
- **Why removal was safe:** no live consumer remained; only a historical retro mentioned it as prior junk
- **Result:** removed from the working tree

### `prototypes/daily-login-prototype.html`

- **Previous role:** daily-login prototype archive
- **Why removal was safe:** current daily-login behavior is already described by live feature/docs surfaces and implemented product code
- **Result:** removed from the working tree

### `prototypes/gold-mine-prototype.html`

- **Previous role:** early Gold Mine UI exploration
- **Why removal was safe:** the retained Gold Mine minigame prototype plus live feature docs already cover the useful history
- **Result:** removed from the working tree

### `prototypes/hero-card-hp-energy-prototype.html`

- **Previous role:** hero-card HP/energy visual exploration
- **Why removal was safe:** no current design or implementation doc still depended on this standalone variant
- **Result:** removed from the working tree

## Problems resolved

1. **Prototype layer still had ownerless feature residue**
   - Risk before: `prototypes/` still mixed intentionally retained history with abandoned one-off explorations.
   - Resolution: removed the six files that no longer carried unique value.

2. **Inventory overstated live prototype surface**
   - Risk before: wiki inventory still suggested a larger retained prototype set than actually mattered.
   - Resolution: inventory now reflects the smaller, intentional prototype set.

## Verification

- confirmed all six target prototype files no longer exist in the working tree
- rechecked repo references and found no remaining live consumers for the removed files
- updated wiki inventory and navigation so the deletion is reflected instead of leaving dead entries
- `git diff --check`

## Follow-up

- Continue shrinking `prototypes/` by keeping only files that still provide unique historical or review value.
