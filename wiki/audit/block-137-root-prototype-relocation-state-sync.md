---
title: Block 137 — root prototype relocation state sync
category: audit
tags: [audit, root, prototypes, relocation, inventory]
sources:
  - combat-proto-A.html
  - combat-proto-B.html
  - combat-proto-B2.html
  - combat-proto-B2-v2.html
  - combat-proto-B2-v3.html
  - combat-proto-C.html
  - combat-prototypes.html
  - gold_mine_minigame_prototype.html
  - hero-card-delete-rings-layout.html
  - hero-card-rings-deepdive.html
  - privacy.html
  - special_offer_widget_prototype.html
  - special_offer_widget_v2_prototype.html
  - special_offer_widget_v3_prototype.html
  - terms.html
  - prototypes/
  - wiki/audit/project-file-inventory.md
  - wiki/audit/block-001-root-files.md
updated: 2026-04-16
status: Fixed
---

# Block 137 — root prototype relocation state sync

## Scope

- deleted root prototype/legal HTML paths:
  - `combat-proto-A.html`
  - `combat-proto-B.html`
  - `combat-proto-B2.html`
  - `combat-proto-B2-v2.html`
  - `combat-proto-B2-v3.html`
  - `combat-proto-C.html`
  - `combat-prototypes.html`
  - `gold_mine_minigame_prototype.html`
  - `hero-card-delete-rings-layout.html`
  - `hero-card-rings-deepdive.html`
  - `privacy.html`
  - `special_offer_widget_prototype.html`
  - `special_offer_widget_v2_prototype.html`
  - `special_offer_widget_v3_prototype.html`
  - `terms.html`
- current `prototypes/` copies
- wiki inventory/root-audit surfaces that still needed state sync

## Why this block

The repo had already moved into a transition state where the old root HTML surfaces were gone from the working tree, while replacement copies were sitting under `prototypes/`.

That state was partly captured in `block-121`, but the main inventory still listed the old root files as if they were just ordinary present files. This block does not delete anything new. It makes the repo map honest again.

## Related pages

- [[block-001-root-files]]
- [[block-121-prototypes-link-parity-and-transition-state]]
- [[block-136-delete-root-orphan-prototype-artifacts]]

## What was updated

### Root inventory state

- marked the deleted root prototype/legal paths in `project-file-inventory.md` as `_(deleted in working tree)_`
- kept them in the inventory because they are still tracked git paths and remain part of the audit/accounting surface

### Root audit state

- added an explicit transition note to `block-001-root-files`
- clarified that the original root-file analysis now coexists with later prototype relocation into `prototypes/`

## Problems resolved

1. **Inventory looked more alive than the tree really is**
   - Risk before: scanning the root block implied those HTML surfaces still physically existed at the repo root.
   - Resolution: marked them as deleted in working tree.

2. **Root audit lacked the later relocation context**
   - Risk before: `block-001` read like a frozen snapshot without acknowledging that the root prototype layer has since moved.
   - Resolution: added a clear transition note linking old root audit semantics to the newer `prototypes/` state.

3. **Prototype transition story was split across blocks**
   - Risk before: `block-121` captured link parity, but not every reader would connect that to the inventory/root-file listing.
   - Resolution: synced the inventory and root audit so the transition state is visible from all entry points.

## Verification

- confirmed the listed root HTML surfaces are absent from the working tree
- confirmed corresponding prototype/legal copies exist under `prototypes/`
- confirmed inventory headings/counts still reconcile after the state sync
- `git diff --check`

## Follow-up

- keep treating the root entries as historical/tracked transition artifacts until the repo decides whether those moved `prototypes/` copies become fully tracked canonical references or remain temporary working-tree mirrors
