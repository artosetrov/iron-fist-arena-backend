---
title: Block 079 — iOS dungeon list and progress typed contracts
category: audit
tags: [audit, ios, dungeons, contracts, hub]
sources:
  - Hexbound/Hexbound/Services/DungeonService.swift
  - Hexbound/Hexbound/Views/Dungeon/DungeonSelectViewModel.swift
  - Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift
  - Hexbound/Hexbound/Views/Hub/HubView.swift
updated: 2026-04-16
status: Fixed
---

# Block 079 — iOS dungeon list and progress typed contracts

## Scope

- dungeon service boundary:
  - `Hexbound/Hexbound/Services/DungeonService.swift`
- dungeon list and active-run resume consumers:
  - `Hexbound/Hexbound/Views/Dungeon/DungeonSelectViewModel.swift`
  - `Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift`
- hub prefetch cache:
  - `Hexbound/Hexbound/Views/Hub/HubView.swift`

## Why this block

After `block-078`, the next obvious iOS raw-contract holdout was the dungeon list/progress path.

The app already had a stable `DungeonInfo` model and stable backend dungeon routes, but the live service boundary still depended on:

- raw `getRaw(...)`
- `[String: Any]`
- repeated per-screen parsing of the same `progress` and `activeRun` payload

That left dungeon select, room resume, and hub prefetch on a weaker contract than the rest of the recent iOS cleanup.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[dungeons]]
- [[block-047-backend-dungeon-item-balance-live-config-hardening]]
- [[block-078-ios-tutorial-manager-typed-contract-cleanup]]

## File notes

### `Hexbound/Hexbound/Services/DungeonService.swift`

- **Zone:** iOS / services / dungeons
- **Purpose:** loads dungeon catalog, progress snapshot, and live dungeon mutations
- **Problems found:**
  - `listDungeons()` still decoded backend data through raw dictionaries
  - `getProgress()` returned `[String: Any]`, forcing every consumer to reinterpret the same snapshot
  - catalog parsing logic was spread between the service and downstream screens
- **What was fixed:**
  - added typed DTOs for dungeon catalog rows, bosses, drops, active run, and progress snapshot
  - moved `listDungeons()` onto typed `APIClient.get(...)`
  - moved `getProgress()` onto typed `DungeonProgressSnapshot`
  - centralized catalog-to-`DungeonInfo` mapping in one typed conversion helper
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Dungeon/DungeonSelectViewModel.swift`

- **Zone:** iOS / dungeons / selection
- **Purpose:** loads dungeon list, saved progress, and current active run for the dungeon selection screen
- **Problems found:**
  - `currentRun` used raw dictionaries
  - progress parsing duplicated the backend snapshot contract locally
  - list loading still had to branch between typed local fallback and raw server data
- **What was fixed:**
  - converted `currentRun` to typed `DungeonActiveRunSnapshot`
  - switched progress loading onto typed `DungeonProgressSnapshot`
  - kept the existing merge with local fallback dungeons, but only after the server list is typed
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift`

- **Zone:** iOS / dungeons / room runtime
- **Purpose:** resumes the active dungeon run and syncs current floor/run identity into room combat
- **Problems found:**
  - room resume still unpacked `activeRun` and `progress` through string keys
  - resume safety depended on matching raw dictionary shapes across service and view model
- **What was fixed:**
  - switched the resume path to typed `DungeonProgressSnapshot`
  - switched active-run reads to typed `dungeonId`, `id`, and `currentFloor`
  - preserved the existing local gating behavior for mismatched dungeon IDs
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Hub/HubView.swift`

- **Zone:** iOS / hub / warm cache
- **Purpose:** opportunistically prefetches dungeon progress for hub-adjacent UX
- **Problems found:**
  - prefetch still unpacked progress through raw dictionaries even after other recent typed-contract cleanup
- **What was fixed:**
  - switched prefetch to the typed `DungeonProgressSnapshot`
  - now caches the authoritative `[String: Int]` progress map directly
- **Status:** Fixed

## Problems found

1. **Dungeon progress lived on raw dictionaries**
   - Risk: three different iOS surfaces could silently drift from the same backend contract.
   - Fix: introduced a shared typed progress snapshot and moved service consumers onto it.

2. **Dungeon catalog parsing was only half-typed**
   - Risk: compile-time safety stopped at the network boundary even though downstream UI already used stable models.
   - Fix: added typed catalog DTOs and one conversion path into `DungeonInfo`.

3. **Hub prefetch still used the old parsing style**
   - Risk: subtle regressions could survive because the visible dungeon screens and the prefetch cache no longer spoke the same language.
   - Fix: moved hub prefetch onto the same typed progress contract.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`

## Follow-up

- `DungeonService.start(...)` and `DungeonService.fight(...)` still return raw payloads
- `DungeonRushViewModel.swift` remains the next larger iOS raw-contract holdout
- once the remaining dungeon result contracts are typed, `DungeonInfo.from(serverData:)` becomes a candidate for consolidation or removal
