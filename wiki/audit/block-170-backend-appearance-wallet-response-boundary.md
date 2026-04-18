---
title: Audit Block 170 — Backend Appearance Wallet Response Boundary
category: audit
tags: [audit, backend, ios, characters, appearance, api-contracts]
sources:
  - backend/src/app/api/characters/[id]/appearance/route.ts
  - Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift
  - wiki/audit/block-038-backend-utility-routes-and-character-warning-cleanup.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 170 — Backend Appearance Wallet Response Boundary

## Scope

- `backend/src/app/api/characters/[id]/appearance/route.ts`
- `Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift`
- `wiki/audit/block-038-backend-utility-routes-and-character-warning-cleanup.md`

## Why this block

[[block-038-backend-utility-routes-and-character-warning-cleanup]] left one narrow but real contract smell open:

- the appearance route returned top-level `gold`
- and also injected the same wallet value into `character.gold`
- which was convenient for the current iOS caller,
- but muddled the boundary between entity payload and wallet state

This did not break gameplay, but it kept the contract fuzzy in exactly the kind of user-facing route that tends to become sticky over time.

## What changed

### `backend/src/app/api/characters/[id]/appearance/route.ts`

- kept the current payload compatible for existing callers:
  - `character.gold`
  - top-level `gold`
- added a canonical top-level wallet boundary:
  - `wallet: { gold }`

This means newer callers can read wallet state explicitly, while old callers keep working during the transition.

### `Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift`

- extended the local response DTO with typed `wallet`
- made the view model prefer:
  - `wallet.gold`
  - then top-level `gold`
  - then the legacy nested `character.gold`
- continues to publish a full `Character` back into `appState.currentCharacter`

### `wiki/audit/block-038-backend-utility-routes-and-character-warning-cleanup.md`

- replaced the old open warning with the new truth:
  - the route now has a canonical wallet boundary
  - nested `character.gold` remains only as a compatibility alias

## Problems resolved

1. **Appearance response had no explicit wallet boundary**
   - Resolution: added `wallet.gold` as the canonical response field.

2. **Current iOS caller still depended on legacy mixed payload**
   - Resolution: kept compatibility aliases while teaching the client to prefer the new typed wallet field.

## Verification

- `cd backend && npx eslint 'src/app/api/characters/[id]/appearance/route.ts'`
- `cd backend && npm run build`
- `xcodebuild -project /Users/artosetrov/Documents/Cursor\ AI/PVP\ RPG/Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`

## Follow-up

- The only remaining cleanup here is optional: once all callers are confirmed on the canonical path, `character.gold` and top-level `gold` can be retired and the route can return just:
  - `character`
  - `wallet`
