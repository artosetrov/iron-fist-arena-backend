---
title: Audit Block 238 — Inventory Untracked Marker Parity After Git State Shift
category: audit
tags: [audit, wiki, inventory, git]
sources:
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
updated: 2026-04-19
status: Fixed
---

# Audit Block 238 — Inventory Untracked Marker Parity After Git State Shift

## Scope

- `wiki/audit/project-file-inventory.md`
- `git ls-files`
- `git ls-files --others --exclude-standard`

## Why this block

After the latest repo state shift, the inventory still carried a large tail of stale `_(untracked)_` markers from older wiki/admin waves even though most of those files were now tracked.

At the same time, one real untracked backend test file was missing from the inventory list.

## Fix applied

- refreshed tracked/untracked summary counts against current `git` state
- refreshed the `backend` and `User` category totals that moved with the new git state
- removed stale `_(untracked)_` markers from files that are now tracked
- kept the real remaining `_(untracked)_` markers
- added the missing `backend/tests/api/characters-list.test.ts` entry as the current untracked backend test file

## Result

The inventory no longer implies that the late admin/wiki audit wave is still broadly untracked, and it now reflects the current narrow set of genuinely untracked files.

## Verification

- compared inventory markers against `git ls-files --others --exclude-standard`
- verified the newly listed backend test file exists
- `git diff --check`

This closes the next inventory marker drift tail after the recent git-state shift.
