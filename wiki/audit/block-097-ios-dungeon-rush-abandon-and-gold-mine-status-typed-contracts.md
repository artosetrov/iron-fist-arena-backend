---
title: Block 097 — iOS dungeon rush abandon and gold mine status typed contracts
category: audit
tags: [audit, ios, dungeon-rush, gold-mine, hub, contracts]
sources:
  - Hexbound/Hexbound/Models/MinigameSession.swift
  - Hexbound/Hexbound/Services/GameDataCache.swift
  - Hexbound/Hexbound/Services/DungeonService.swift
  - Hexbound/Hexbound/Views/Hub/HubView.swift
  - Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift
  - backend/src/app/api/dungeon-rush/abandon/route.ts
  - backend/src/app/api/minigames/gold-mine/status/route.ts
updated: 2026-04-16
status: Fixed
---

# Block 097 — iOS dungeon rush abandon and gold mine status typed contracts

## Scope

- `Hexbound/Hexbound/Models/MinigameSession.swift`
- `Hexbound/Hexbound/Services/GameDataCache.swift`
- `Hexbound/Hexbound/Services/DungeonService.swift`
- `Hexbound/Hexbound/Views/Hub/HubView.swift`
- `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`
- `backend/src/app/api/dungeon-rush/abandon/route.ts`
- `backend/src/app/api/minigames/gold-mine/status/route.ts`

## Why this block

After the broader dungeon, rush, onboarding, and profile cleanup, two small but still live iOS raw-contract tails were left behind:

- `DungeonService.rushAbandon()` still posted a raw body to a player-facing live route
- both `HubView` and `GoldMineViewModel` still fetched gold mine status through `getRaw(...)`

Those were not the biggest remaining surfaces, but they were real live paths and were worth closing before the larger Gold Mine action flows.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-079-ios-dungeon-list-and-progress-typed-contracts]]
- [[block-081-ios-dungeon-rush-resolve-and-shop-typed-contracts]]
- [[systems/gold-mine]]
- [[systems/dungeons]]

## File notes

### `Hexbound/Hexbound/Models/MinigameSession.swift`

- **Zone:** iOS / minigames / shared DTOs
- **Purpose:** holds typed payloads shared by Gold Mine and other minigame flows
- **Problems found:**
  - gold mine status still had no typed transport model even though the backend payload shape was stable
- **What was fixed:**
  - added `GoldMineSlotStatus`
  - added `GoldMineSlotStatsResponse`
  - added `GoldMineSlotResponse`
  - added `GoldMineStatusResponse`
  - added a narrow `legacyDictionary` bridge so old slot UI and cache surfaces can keep working while the network boundary is now typed
- **Status:** Fixed

### `Hexbound/Hexbound/Services/GameDataCache.swift`

- **Zone:** iOS / cache / hub + minigame prefetch
- **Purpose:** stores short-lived snapshots for hub hints and instant screen open
- **Problems found:**
  - gold mine cache only accepted raw slot dictionaries
- **What was fixed:**
  - added `cacheGoldMine(status:)` so typed status responses can be cached without repeating bridge code in multiple callers
- **Status:** Fixed

### `Hexbound/Hexbound/Services/DungeonService.swift`

- **Zone:** iOS / dungeons + dungeon rush
- **Purpose:** owns typed transport for dungeon and rush service calls
- **Problems found:**
  - `rushAbandon()` was still a raw mutation body
- **What was fixed:**
  - added typed `DungeonRushAbandonRequest`
  - added typed `DungeonRushAbandonResponse`
  - moved `rushAbandon()` onto `APIClient.post(...)`
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Hub/HubView.swift`

- **Zone:** iOS / hub / background prefetch
- **Purpose:** preloads nearby runtime data so hub hints and first opens are accurate
- **Problems found:**
  - gold mine prefetch still used `getRaw(...)`
  - hub hint quality depended on a raw parsing path even though the backend status payload was stable
- **What was fixed:**
  - moved `prefetchGoldMine()` onto typed `GoldMineStatusResponse`
  - cached the typed response through the shared cache bridge
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`

- **Zone:** iOS / gold mine / status load
- **Purpose:** loads and manages the gold mine screen state
- **Problems found:**
  - initial status load was still raw even though the route is a stable read-side contract
- **What was fixed:**
  - moved `loadStatus()` onto typed `GoldMineStatusResponse`
  - kept the existing slot UI untouched through the shared bridge so this block stays safe and narrow
- **Status:** Fixed

### `backend/src/app/api/dungeon-rush/abandon/route.ts`

- **Zone:** backend / dungeon rush
- **Purpose:** abandons a rush run and returns the kept rewards summary
- **Problems found:**
  - no backend code change was required here; the client was the lagging raw consumer
- **What was fixed:**
  - the iOS client now consumes the route through a typed request/response path
- **Status:** OK

### `backend/src/app/api/minigames/gold-mine/status/route.ts`

- **Zone:** backend / gold mine
- **Purpose:** returns the canonical gold mine slot status snapshot used by hub and minigame screens
- **Problems found:**
  - no backend code change was required here; the payload shape was already stable enough for a typed client
- **What was fixed:**
  - iOS status consumers now use a typed `GoldMineStatusResponse`
- **Status:** OK

## Problems found

1. **Live iOS routes still had small raw transport tails**
   - Risk: these paths could drift from the rest of the cleaned-up service layer and fail later than a normal typed decode would.
   - Fix: moved `rushAbandon()` and gold mine status reads onto typed DTOs.

2. **Gold mine status parsing logic was duplicated across hub and gold mine entry**
   - Risk: the same stable backend contract was being interpreted twice through raw dictionaries.
   - Fix: introduced shared gold mine status DTOs plus one cache bridge.

3. **The cache layer forced repeated raw bridging at each call site**
   - Risk: every new typed consumer would have to reinvent the same conversion step.
   - Fix: centralized that bridge in `GameDataCache.cacheGoldMine(status:)`.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check -- Hexbound/Hexbound/Models/MinigameSession.swift Hexbound/Hexbound/Services/GameDataCache.swift Hexbound/Hexbound/Services/DungeonService.swift Hexbound/Hexbound/Views/Hub/HubView.swift Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`
- `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization' Hexbound/Hexbound/Services/DungeonService.swift Hexbound/Hexbound/Views/Hub/HubView.swift`

## Follow-up

- Gold mine **status** is typed now, but the heavier mutation paths in `GoldMineViewModel` still use raw action payloads and one internal `MinigameSession` decode bridge.
- This block intentionally stopped at the stable read-side and rush abandon mutation, so the next honest residual list is narrower: gold mine `start / collect / collect-all / slot-minigame / boost / buy-slot`, plus editor-only utility surfaces.
