---
title: Audit Block 296 — Inventory and Audit-Trail Self-Reference Parity
category: audit
tags: [audit, inventory, cleanup]
sources:
  - wiki/audit/block-295-audit-trail-token-and-placeholder-wording-scrub.md
  - wiki/audit/audit-index.md
  - wiki/index.md
  - wiki/log.md
  - wiki/audit/project-file-inventory.md
  - qa-reports/prototypes/talents-horizontal-only-2026-04-29.html
updated: 2026-05-01
status: Fixed
---

# Audit Block 296 — Inventory and Audit-Trail Self-Reference Parity

## Scope

This block closes the self-referential residue left behind after block 295 and
refreshes inventory truth against the live git state.

## Why this block

Two tiny issues remained after the first scrub:

- the new block-295 summaries still repeated the same stale token language
  they had just removed from older docs
- `project-file-inventory.md` was still one file behind live git because the
  untracked QA prototype under `qa-reports/prototypes/` was not listed yet

That meant repo-wide greps still had a little self-inflicted noise, and the
inventory counts were off by one.

## Changes shipped

- Reworded block-295 and its linked summary lines in `audit-index.md`,
  `index.md`, and `log.md` so they describe external-note residue generically
  instead of restating the old token strings literally.
- Added the real untracked
  `qa-reports/prototypes/talents-horizontal-only-2026-04-29.html` entry to the
  inventory.
- Rolled the tracked/untracked/in-scope/wiki totals forward again so the top
  counts and block summaries match the live repository state.

## Result

The audit trail now describes its own cleanup without reintroducing stale token
noise, and the inventory once again matches the actual git-visible file set.
