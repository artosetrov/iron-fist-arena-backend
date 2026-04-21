---
title: Audit Block 248 — Inventory Marker Parity After Tracked-State Rollforward
category: audit
tags: [audit, inventory, git, metadata]
sources:
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
  - git status --short
updated: 2026-04-20
status: Fixed
---

# Audit Block 248 — Inventory Marker Parity After Tracked-State Rollforward

## Scope

- `wiki/audit/project-file-inventory.md`
- current git tracked/untracked state

## Why this block

After the latest rollforward, the repo state shifted again:

- the recent audit blocks `237–246` are now tracked
- only `block-247` remained untracked before this pass

The inventory still carried the older marker set, so its summary counts and `_untracked_` labels were overstating the live untracked surface.

## Fix applied

- refreshed tracked/untracked/in-scope counts from the current git state
- removed stale `_untracked_` markers from `block-237` through `block-246`
- kept the true untracked marker on `block-247`

## Result

The project inventory is back in sync with the repo instead of treating already-tracked audit files as if they were still floating outside version control.

## Verification

- `git ls-files`
- `git ls-files --others --exclude-standard`
- `git status --short`
- `git diff --check`
