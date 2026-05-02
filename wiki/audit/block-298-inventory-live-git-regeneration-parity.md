---
title: Audit Block 298 — Inventory Live Git Regeneration Parity
category: audit
tags: [audit, inventory, git, regeneration]
sources:
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
  - Hexbound/Hexbound/Views/Combat/EnemyPortraitResolver.swift
  - docs/retro/RETRO_2026-04-30.md
  - docs/retro/RETRO_2026-05-01.md
  - qa-reports/2026-05-01_talent_modal_redesign.md
  - qa-reports/prototypes/talents-wow-style-2026-04-29.html
updated: 2026-05-01
status: Fixed
---

# Audit Block 298 — Inventory Live Git Regeneration Parity

## Scope

This block rebuilds the project inventory against the current live git-visible
file tree after the late combat, social, retro, and audit waves.

## Why this block

The inventory had drifted past a simple top-count mismatch.

Several real tracked and untracked files were no longer listed at all, while
older deleted-working-tree notes still occupied current-scope space in the
inventory. That left the file map honest in spirit but no longer reliable as a
literal repo snapshot.

## Changes shipped

- Rebuilt `project-file-inventory.md` from the live tracked and untracked file
  set instead of continuing to hand-patch individual omissions.
- Added the missing late-wave live paths, including:
  - `Hexbound/Hexbound/Views/Combat/EnemyPortraitResolver.swift`
  - `docs/retro/RETRO_2026-04-30.md`
  - `docs/retro/RETRO_2026-05-01.md`
  - `qa-reports/2026-05-01_talent_modal_redesign.md`
  - `qa-reports/prototypes/talents-wow-style-2026-04-29.html`
  - the full untracked audit tail through block 298
- Rolled section counts, tracked/untracked totals, and the wiki block summary
  forward so the inventory matches the current repository again.

## Result

The inventory is a literal live file map again instead of a partially
hand-maintained snapshot. Future audit waves can build on a clean baseline
instead of carrying forward stale omissions and count drift.
