---
title: Audit Block 277 — Inventory Marker Parity After PvP Wave Rollforward
category: audit
tags: [audit, inventory, git, parity]
sources:
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
  - git status --short
updated: 2026-04-30
status: Fixed
---

# Audit Block 277 — Inventory Marker Parity After PvP Wave Rollforward

## Scope

This block refreshes `project-file-inventory.md` after the latest tracked-state
rollforward around blocks `263–275`.

## Why this block

The inventory had drifted in three ways:

- it still claimed blocks `263–274` were untracked even though they are now in
  `git ls-files`
- it still listed the deleted QA prototype HTML
- it had duplicated `block-275`

That made the top-level counts and the marker layer disagree with the real git
state.

## Changes shipped

- Refreshed tracked/untracked/in-scope counts from live git:
  - `5210 tracked`
  - `3 untracked`
  - `5213 in-scope`
- Removed stale `_(untracked)_` markers from `block-263` through `block-274`.
- Removed the deleted QA prototype entry.
- Removed the duplicate `block-275` line.
- Added the real current untracked audit tail:
  - `block-275`
  - `block-276`
  - `block-277`

## Result

`project-file-inventory.md` once again matches the real repository state
instead of an older pre-rollforward snapshot.
