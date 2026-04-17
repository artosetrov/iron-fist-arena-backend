---
title: Block 146 — delete legal transition prototype copies
category: audit
tags: [audit, prototypes, legal, operations, deletion]
sources:
  - prototypes/privacy.html
  - prototypes/terms.html
  - docs/10_operations/GIT_AND_DEPLOY_AUDIT.md
  - wiki/audit/block-121-prototypes-link-parity-and-transition-state.md
updated: 2026-04-17
status: Fixed
---

# Block 146 — delete legal transition prototype copies

## Scope

- `prototypes/privacy.html`
- `prototypes/terms.html`
- `docs/10_operations/GIT_AND_DEPLOY_AUDIT.md`

## Why this block

The local `prototypes/privacy.html` and `prototypes/terms.html` files were only surviving as transition-state copies after the old root legal pages disappeared from the working tree.

By now that transition had outlived its purpose:

- iOS settings already open the hosted production URLs
- no current repo-local landing/static deploy contract exists
- the only remaining references were audit/history notes and one stale operations sentence

So keeping local HTML copies was more misleading than helpful.

## What changed

### `prototypes/privacy.html`

- **Previous role:** temporary working-tree copy of the deleted root privacy page
- **Why removal was safe:** no live app/docs flow consumes the local HTML; the shipped app opens the hosted privacy URL
- **Result:** removed from the working tree

### `prototypes/terms.html`

- **Previous role:** temporary working-tree copy of the deleted root terms page
- **Why removal was safe:** same as privacy; the shipped app opens the hosted terms URL
- **Result:** removed from the working tree

### `docs/10_operations/GIT_AND_DEPLOY_AUDIT.md`

- removed stale wording that implied this repo still contains an active local legal/static page surface
- clarified that the unresolved gap is documentation for the hosted landing/legal surface, not a repo-local static deployment contract

## Problems resolved

1. **Legal transition copies were lingering as pseudo-source-of-truth**
   - Risk before: the repo suggested a local legal HTML surface still existed and might matter operationally.
   - Resolution: removed the copies and kept only the historical/audit record.

2. **Operations docs overstated repo-local landing/legal reality**
   - Risk before: the docs implied the repo still ships local legal pages.
   - Resolution: the runbook now describes the real gap more honestly.

## Verification

- confirmed `prototypes/privacy.html` and `prototypes/terms.html` no longer exist in the working tree
- confirmed iOS legal buttons still target hosted production URLs
- `git diff --check`

## Follow-up

- After this block, only the combat-history pair remains in `prototypes/`; that layer is no longer a general cleanup bucket.

