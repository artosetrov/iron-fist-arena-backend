---
title: Audit Block 159 — iOS Game Init and Item Stat Preview Parity
category: audit
tags: [audit, ios, backend, game-init, inventory, items, stats]
sources:
  - backend/src/app/api/game/init/route.ts
  - Hexbound/Hexbound/Models/Item.swift
  - Hexbound/Hexbound/Services/GameInitService.swift
  - wiki/audit/block-021-item-stat-authority-consumable-catalog.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 159 — iOS Game Init and Item Stat Preview Parity

## Scope

- `backend/src/app/api/game/init/route.ts`
- `Hexbound/Hexbound/Models/Item.swift`
- `Hexbound/Hexbound/Services/GameInitService.swift`
- `wiki/audit/block-021-item-stat-authority-consumable-catalog.md`

## Why this block

[[block-158-backend-item-stat-authority-rolled-stats-parity]] fixed the backend stat-authority core, but one client-side seam was still open:

- `/api/game/init` did not include `effectiveStats`, so cold-start inventory hydrated into the app without authoritative stat snapshots
- `Item.upgradeBonusPerStat` still compared authoritative stats against `baseStats` only, which overcounted upgrade bonus on rolled gear

That left a subtle but very live UX drift: freshly booted inventory could fall back to local stat math, and rolled items could show inflated upgrade preview deltas even after the backend fix.

## What changed

### `backend/src/app/api/game/init/route.ts`

- imported the shared stat-authority helper
- computed authoritative `effectiveStats` for each equipment row in the init payload
- used the same merged `baseStats + rolledStats + config-driven upgrade bonus` rule already adopted by inventory/stash/upgrade routes

### `Hexbound/Hexbound/Services/GameInitService.swift`

- added `effectiveStats` to the init equipment DTO
- threaded the authoritative snapshot through to `Item.authoritativeEffectiveStats`

### `Hexbound/Hexbound/Models/Item.swift`

- corrected `upgradeBonusPerStat` to compare authoritative stats against the merged stat set (`base + rolled`), not `baseStats` alone
- kept the existing local fallback behavior for truly partial/non-authoritative item contexts

## Problems resolved

1. **Cold-start inventory hydration could lose authoritative item stats**
   - Resolution: `game/init` equipment rows now carry `effectiveStats`.

2. **Rolled items could show inflated upgrade preview deltas on iOS**
   - Resolution: preview bonus derivation now uses merged stats before subtracting from authoritative totals.

## Verification

- `cd backend && npx eslint src/app/api/game/init/route.ts`
- `cd backend && npm run build`
- `xcodebuild -project /Users/artosetrov/Documents/Cursor\ AI/PVP\ RPG/Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check -- backend/src/app/api/game/init/route.ts Hexbound/Hexbound/Models/Item.swift Hexbound/Hexbound/Services/GameInitService.swift wiki/audit/block-159-ios-game-init-item-stat-preview-parity.md wiki/audit/block-021-item-stat-authority-consumable-catalog.md wiki/audit/audit-index.md wiki/audit/project-file-inventory.md wiki/index.md wiki/log.md`

All passed after the change.

## Follow-up

- The stat-authority chain is now much tighter end-to-end:
  - backend snapshots
  - backend `game/init`
  - iOS inventory hydration
  - iOS upgrade preview for rolled gear
- The remaining open question in this area is narrower: whether zero-level / partial item contexts should continue using best-effort local preview at all, or wait for authoritative backend values.
