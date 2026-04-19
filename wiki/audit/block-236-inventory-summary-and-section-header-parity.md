---
title: Audit Block 236 — Inventory Summary and Section Header Parity
category: audit
tags: [audit, wiki, inventory, counts]
sources:
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
updated: 2026-04-19
status: Fixed
---

# Audit Block 236 — Inventory Summary and Section Header Parity

## Scope

- `wiki/audit/project-file-inventory.md`
- `git ls-files`
- `git ls-files --others --exclude-standard`

## Why this block

After the late admin/wiki cleanup wave, the inventory had drifted in two visible ways:

- top-level tracked/untracked/in-scope counts lagged behind real `git` state
- several section headers still carried older counts, so the inventory contradicted itself even before you got to the file list

## Fix applied

- refreshed top-level counts from current `git` state
- refreshed category summary counts
- refreshed stale section headers so they now match the current category totals

## Result

`project-file-inventory.md` is internally consistent again at the summary/header layer and no longer reports obviously stale category sizes after the late cleanup wave.

## Verification

- compared `project-file-inventory.md` summary counts against:
  - `git ls-files`
  - `git ls-files --others --exclude-standard`
- checked section-header counts against the current category summary block
- `git diff --check`

This closes the next inventory drift tail adjacent to the recent wiki/admin cleanup blocks.
