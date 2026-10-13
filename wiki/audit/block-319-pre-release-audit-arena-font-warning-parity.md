---
title: Audit Block 319 — Pre-release Audit Arena Font Warning Parity
category: audit
tags: [audit, docs, ios, design-system, arena]
sources:
  - docs/10_operations/HEXBOUND_PRE_RELEASE_AUDIT.md
  - Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift
updated: 2026-05-06
status: Fixed
---

# Audit Block 319 — Pre-release Audit Arena Font Warning Parity

## Scope

This block closes a stale release-audit warning that was still calling out two
hardcoded system-font violations in `ArenaDetailView.swift` even though the
current checked-in file no longer contains those calls.

## Why this block

`HEXBOUND_PRE_RELEASE_AUDIT.md` still reported:

- `System fonts in Views` → `⚠️ 2 violations`
- `DS-1` → `ArenaDetailView.swift:585, 660`

But the live file no longer matches that claim:

- the cited lines are no longer font calls at all
- a direct grep for `.font(.system(size:` in `ArenaDetailView.swift` returns no
  matches

That made the release audit itself the drifting surface.

## Changes shipped

- Updated the design-system summary row from:
  - `⚠️ 2 violations | ArenaDetailView lines 585, 660`
  to:
  - `✅ CLEAN | 0 violations in current checked-in Views scan`
- Removed the stale `DS-1` issue row for the no-longer-present Arena system
  font problem.

## Result

The pre-release audit no longer reports an Arena font warning that the live
repo has already outgrown. The remaining design-system issues list is narrower
and closer to the actual checked-in app state.
