---
title: Audit Block 203 — Inventory Tracked Marker Parity For Recent Runtime Wave
category: audit
tags: [audit, inventory, tracking, backend, ios, docs]
sources:
  - wiki/audit/project-file-inventory.md
  - backend/src/lib/game/item-stats.ts
  - backend/tests/api/auth-guest.test.ts
  - docs/07_ui_ux/STRIKE_REVEAL_SHAPE_B_PLAN.md
  - Hexbound/Hexbound/Services/AnalyticsService.swift
  - prototypes/strike-reveal-b.html
  - wiki/audit/block-152-root-bootstrap-and-ignore-parity.md
updated: 2026-04-19
status: Fixed
---

# Audit Block 203 — Inventory Tracked Marker Parity For Recent Runtime Wave

## Scope

- `wiki/audit/project-file-inventory.md`
- recent backend runtime/test files
- recent iOS/runtime files
- retained strike-reveal prototype references
- newer audit block pages already committed to the repository

## Why this block

The inventory had accumulated a stale second-order drift:

- several files created during recent runtime/auth/iOS cleanup waves were already tracked in Git
- but `project-file-inventory` still labeled them `_(untracked)_`

That left the file list internally inconsistent even though the files themselves were already normalized.

## Fix applied

Removed stale `_(untracked)_` markers for the tracked files in this slice, including:

- backend runtime/docs/tests:
  - `backend/email-templates/reset-password.html`
  - `backend/src/lib/game/item-stats.ts`
  - `backend/tests/api/auth-guest.test.ts`
  - `backend/tests/api/me.test.ts`
  - `backend/tests/api/auth-forgot-password.test.ts`
  - `backend/tests/api/auth-google-apple.test.ts`
  - `backend/tests/api/auth-guest-login.test.ts`
  - `backend/tests/api/auth-upgrade-guest.test.ts`
  - `backend/tests/api/auth-link-account.test.ts`
  - `backend/tests/api/auth-sync-user.test.ts`
  - `backend/tests/api/auth-upgrade-guest-oauth.test.ts`
  - `backend/tests/api/achievement-claim.test.ts`
  - `backend/tests/api/achievement-list.test.ts`
  - `backend/tests/api/character-progression-derived-stats.test.ts`
  - `backend/tests/api/pvp-history.test.ts`
  - `backend/tests/lib/item-stats.test.ts`
- docs / retained prototype references:
  - `docs/07_ui_ux/STRIKE_REVEAL_SHAPE_B_PLAN.md`
  - `prototypes/strike-reveal-b.html`
  - `prototypes/strike-reveal-compact.html`
  - `prototypes/strike-reveal-integration.html`
- iOS/runtime files:
  - `Hexbound/Hexbound/Services/AnalyticsService.swift`
  - `Hexbound/Hexbound/Models/RoundVerdict.swift`
  - `Hexbound/Hexbound/Views/Combat/VFX/CombatVerdictFlash.swift`
- audit pages already tracked in Git:
  - `wiki/audit/block-152-root-bootstrap-and-ignore-parity.md`
  - through `wiki/audit/block-173-admin-design-system-dead-preview-export-removal.md`

## Result

The inventory is now honest again about this recent wave of files:

- tracked files are listed as tracked
- only genuinely untracked files keep the marker
- recent runtime/audit work no longer looks half-normalized on paper

## Verification

- `git ls-files` over the corrected file set
- `git diff --check`

Both confirm the markers were stale, not the files.
