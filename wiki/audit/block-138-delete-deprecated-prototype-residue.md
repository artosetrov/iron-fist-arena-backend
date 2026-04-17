---
title: Block 138 — delete deprecated prototype residue
category: audit
tags: [audit, prototypes, deletion, cleanup, ui]
sources:
  - prototypes/hero-card-delete-rings-layout.html
  - prototypes/hero-card-rings-deepdive.html
  - prototypes/special_offer_widget_prototype.html
  - prototypes/special_offer_widget_v2_prototype.html
  - wiki/audit/block-121-prototypes-link-parity-and-transition-state.md
  - wiki/audit/block-001-root-files.md
updated: 2026-04-16
status: Fixed
---

# Block 138 — delete deprecated prototype residue

## Scope

- `prototypes/hero-card-delete-rings-layout.html`
- `prototypes/hero-card-rings-deepdive.html`
- `prototypes/special_offer_widget_prototype.html`
- `prototypes/special_offer_widget_v2_prototype.html`

## Why this block

After the root-orphan cleanup and the root-to-`prototypes/` transition sync, a smaller residue class was left behind:

- hero-card exploratory prototypes with no live consumer
- superseded Special Offer prototype generations (`v1` and `v2`) while `v3` remained as the only kept historical reference

These files were already documented as deprecated or candidate-delete material. With the user's explicit delete instruction, this became a high-confidence cleanup step.

## Related pages

- [[block-001-root-files]]
- [[block-121-prototypes-link-parity-and-transition-state]]
- [[block-137-root-prototype-relocation-state-sync]]

## What was removed

### `prototypes/hero-card-delete-rings-layout.html`

- **Previous role:** manual layout study for hero-card delete affordance and ring placement
- **Why removal was safe:** no live screen, no active docs consumer, and no maintained design workflow depended on it
- **Result:** removed from the working tree

### `prototypes/hero-card-rings-deepdive.html`

- **Previous role:** deeper exploration of hero-card ring/stat presentation
- **Why removal was safe:** same orphan profile as the layout study; only audit history still mentioned it
- **Result:** removed from the working tree

### `prototypes/special_offer_widget_prototype.html`

- **Previous role:** Special Offer widget prototype `v1`
- **Why removal was safe:** explicitly superseded by later variants and no maintained docs/code pointed to it
- **Result:** removed from the working tree

### `prototypes/special_offer_widget_v2_prototype.html`

- **Previous role:** Special Offer banner prototype `v2`
- **Why removal was safe:** superseded by `v3`, no active consumer, no unique product-contract role
- **Result:** removed from the working tree

## Problems resolved

1. **Deprecated prototype generations were still hanging around**
   - Risk before: old design experiments kept competing with the smaller set of prototype files that still matter.
   - Resolution: deleted the clearly superseded/orphaned generations.

2. **Hero-card exploratory residue had no real owner**
   - Risk before: the tree still implied unresolved significance for files that only existed as manual experiments.
   - Resolution: removed them and left the decision trail in audit history.

3. **Special Offer history was noisier than necessary**
   - Risk before: `v1`, `v2`, and `v3` all coexisted, even though only the latest variant still makes sense as a retained reference.
   - Resolution: kept `v3`, removed `v1`/`v2`.

## Verification

- confirmed the four target prototype files no longer exist in the working tree
- confirmed `prototypes/special_offer_widget_v3_prototype.html` still remains as the kept reference variant
- updated inventory/audit surfaces so they no longer list the deleted untracked hero-card files as present
- `git diff --check`

## Follow-up

- Continue treating prototype cleanup conservatively: keep the latest or uniquely informative reference, remove only the generations already proven superseded or ownerless.
