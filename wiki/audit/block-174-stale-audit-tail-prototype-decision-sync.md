---
title: Audit Block 174 — Stale Audit Tail Prototype Decision Sync
category: audit
tags: [audit, prototypes, truth-sync, docs]
sources:
  - wiki/audit/block-121-prototypes-link-parity-and-transition-state.md
  - wiki/audit/block-146-delete-legal-transition-prototype-copies.md
  - wiki/audit/block-147-delete-final-combat-history-prototypes.md
updated: 2026-04-17
---

# Audit Block 174 — Stale Audit Tail Prototype Decision Sync

## Why this block exists

`block-121` was written while the prototype cleanup was still mid-flight, so it preserved several records as `Needs review`:

- `prototypes/combat-proto-B2.html`
- `prototypes/combat-proto-B2-v3.html`
- `prototypes/privacy.html`

That was correct at the time.

But later blocks already closed those decisions:

- `block-146` deleted the transitional legal HTML copies
- `block-147` deleted the final retained combat-history prototype files

So `block-121` was still carrying old open-decision wording after the repo had already moved on.

## What changed

- updated the three stale records in `block-121`
- replaced old “needs separate decision” wording with explicit later-resolution notes
- changed their status from `Needs review` to `Fixed`

## Result

The old prototype transition block now reflects the repo’s actual state:

- the prototype/legal move decisions were not left hanging
- they were resolved by later cleanup blocks
- the remaining open questions live in the current docs/operations surfaces, not in deleted-file records
