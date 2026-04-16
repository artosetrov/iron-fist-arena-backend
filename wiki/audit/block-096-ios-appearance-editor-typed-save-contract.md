---
title: Block 096 — iOS appearance editor typed save contract
category: audit
tags: [audit, ios, appearance, profile, contracts]
sources:
  - Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift
  - backend/src/app/api/characters/[id]/appearance/route.ts
updated: 2026-04-16
status: Fixed
---

# Block 096 — iOS appearance editor typed save contract

## Scope

- `Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift`
- `backend/src/app/api/characters/[id]/appearance/route.ts`

## Why this block

Even after the broader auth, onboarding, shop, inventory, and arena cleanup, the live profile appearance editor still had one raw save boundary:

- raw `PATCH` body assembly
- raw `character` extraction from the response
- manual `JSONSerialization` back into `Character`

That was a clear remaining contract tail in a player-facing profile flow.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-095-ios-battle-preloader-typed-pvp-contracts]]
- [[screens]]

## File notes

### `Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift`

- **Zone:** iOS / profile / appearance editing
- **Purpose:** drives origin, gender, and skin selection plus save/revert behavior for hero appearance changes
- **Problems found:**
  - save still used a raw dictionary body
  - response handling still manually re-decoded `character` through `JSONSerialization`
  - the view model owned a network-contract problem instead of just profile UI logic
- **What was fixed:**
  - added a typed `AppearanceChangeRequest`
  - added a typed `AppearanceChangeResponse`
  - moved the save path onto `APIClient.patch(...)`
  - updated the app state from the authoritative typed `Character` snapshot returned by the server
- **Status:** Fixed

### `backend/src/app/api/characters/[id]/appearance/route.ts`

- **Zone:** backend / character customization
- **Purpose:** validates and applies origin/gender/avatar changes, recalculates origin-dependent stats, and returns the updated character snapshot
- **Problems found:**
  - no backend code change was required here in this block; the client was the lagging raw consumer
- **What was fixed:**
  - the route is now consumed through a typed request/response path on iOS
- **Status:** OK

## Problems found

1. **Appearance save still bypassed the typed client boundary**
   - Risk: a profile customization flow could drift independently from the rest of the cleaned-up iOS service layer.
   - Fix: moved the save action onto typed request/response DTOs.

2. **The view model manually re-decoded `Character` from raw JSON**
   - Risk: response-shape failures would be later and less legible than a normal decode failure.
   - Fix: decode the response directly through `APIClient.patch(...)`.

3. **UI logic and transport logic were still entangled**
   - Risk: appearance reverts and save state were harder to reason about than necessary.
   - Fix: left the optimistic/revert UI behavior intact while removing the raw transport plumbing underneath it.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check -- Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift`
- `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization' Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift`

## Follow-up

- The appearance save boundary is typed now, but other profile/editor residual tails still exist in neighboring utility screens.
- The next honest residual list is no longer “profile save is raw”; it is down to smaller contract islands like Dungeon Rush abandon, Gold Mine, and editor-only utilities.
