---
title: Audit Block 259 — Inventory Marker Parity After Late Tracked Rollforward
category: audit
tags: [audit, inventory, git-state, wiki]
sources:
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
  - git status --short
updated: 2026-04-29
status: Fixed
---

# Audit Block 259 — Inventory Marker Parity After Late Tracked Rollforward

## Scope

- `wiki/audit/project-file-inventory.md`
- current tracked/untracked git state

## Why this block

After the latest rollforward, the actual repo state had narrowed to only the
newest audit pages being untracked. But the inventory still marked an older
wave as `_(untracked)_`, including:

- restored backend admin route files
- late retro notes
- audit blocks `247–256`

That meant the top-level counts and the per-file marker layer were disagreeing
with the real git state again.

## Fix applied

- refreshed the inventory summary counts against current `git ls-files` and
  `git ls-files --others --exclude-standard`
- removed stale `_(untracked)_` markers from files that are now tracked again
- left only the genuinely new audit pages marked untracked

## Result

The inventory is back to telling one coherent story:

- summary counts match git
- per-file `_untracked_` markers match git
- the newest audit wave is clearly isolated instead of being buried inside old
  stale marker noise

## Verification

- `git ls-files`
- `git ls-files --others --exclude-standard`
- `git status --short`
- `git diff --check`
