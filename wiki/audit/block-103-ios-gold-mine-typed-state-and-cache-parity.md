---
title: Block 103 — iOS Gold Mine typed state and cache parity
category: audit
tags: [audit, ios, gold-mine, cache, state]
sources:
  - Hexbound/Hexbound/Models/MinigameSession.swift
  - Hexbound/Hexbound/Services/GameDataCache.swift
  - Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift
  - Hexbound/Hexbound/Views/Minigames/GoldMineCards.swift
  - Hexbound/Hexbound/Views/Minigames/GoldMineDetailView.swift
  - Hexbound/Hexbound/Views/Hub/HubView.swift
  - Hexbound/Hexbound/Views/Hub/CityMapView.swift
updated: 2026-04-16
status: Fixed
---

# Block 103 — iOS Gold Mine typed state and cache parity

## Scope

- `Hexbound/Hexbound/Models/MinigameSession.swift`
- `Hexbound/Hexbound/Services/GameDataCache.swift`
- `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`
- `Hexbound/Hexbound/Views/Minigames/GoldMineCards.swift`
- `Hexbound/Hexbound/Views/Minigames/GoldMineDetailView.swift`
- `Hexbound/Hexbound/Views/Hub/HubView.swift`
- `Hexbound/Hexbound/Views/Hub/CityMapView.swift`

## Why this block

After blocks `097–098`, the live Gold Mine network boundary was already typed, but the local state on top of it was still dictionary-shaped. `GoldMineViewModel`, `GameDataCache`, hub badges, and mine cards continued to read and mutate slot state as `[[String: Any]]`, which meant the transport contract had been cleaned up while the state/render layer still carried the old loose shape.

That kind of half-migration is exactly where UI drift likes to survive.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[gold-mine]]
- [[block-097-ios-dungeon-rush-abandon-and-gold-mine-status-typed-contracts]]
- [[block-098-ios-gold-mine-action-typed-contracts]]
- [[block-102-ios-network-infrastructure-raw-surface-retirement]]

## File notes

### `Hexbound/Hexbound/Models/MinigameSession.swift`

- **Zone:** iOS / Gold Mine DTOs
- **Purpose:** canonical typed slot/session payloads for Gold Mine
- **What was fixed:**
  - made `GoldMineSlotResponse` locally mutable for optimistic state updates
  - added typed payload bridges for `GoldMineSlotResponse` and `GoldMineSlotStatsResponse`
  - added `resolvedStatus`, `hasPlayedMinigame`, `hasInFlightMinigameSession`, and `isBoosted`
- **Status:** Fixed

### `Hexbound/Hexbound/Services/GameDataCache.swift`

- **Zone:** iOS / shared cache
- **Purpose:** holds cached Gold Mine state used by hub and minigame entry points
- **Problems found:**
  - cached Gold Mine slots were still stored as `[[String: Any]]`
- **What was fixed:**
  - changed the cache surface to `[GoldMineSlotResponse]`
  - kept the cached tuple contract the same shape, but with typed slot entries
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`

- **Zone:** iOS / Gold Mine runtime state
- **Purpose:** owns live slot state, optimistic actions, timers, reward celebrations, and shaft routing
- **Problems found:**
  - slot state was still modeled as raw dictionaries even after the action routes were typed
  - the 409 collect-all reconcile path still trusted raw slot arrays from `APIError.responsePayload`
- **What was fixed:**
  - moved local state to `[GoldMineSlotResponse]`
  - updated optimistic start/collect/buy-slot mutations to typed slot structs
  - switched the `NO_PLAYABLE_SLOTS` reconcile path to a narrow typed slot parser
  - removed the dead `activeSlots: [[String: Any]]` tail
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Minigames/GoldMineCards.swift`

- **Zone:** iOS / Gold Mine presentation
- **Purpose:** renders the mine shaft cards and their action CTAs
- **What was fixed:**
  - switched card-local slot access from raw dictionaries to typed slots
  - replaced raw boosted checks with typed slot state
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Minigames/GoldMineDetailView.swift`

- **Zone:** iOS / Gold Mine screen
- **Purpose:** assembles the full Gold Mine experience, mining header, claim flows, and hint state
- **What was fixed:**
  - moved hint counters off raw `status` dictionary reads and onto typed slot helpers
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Hub/HubView.swift`

- **Zone:** iOS / hub surface
- **Purpose:** derives contextual hints from cached progression, dungeon, and mine state
- **What was fixed:**
  - updated mine ready/idle counting to use typed cached slots plus `resolvedStatus()`
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Hub/CityMapView.swift`

- **Zone:** iOS / hub map badges
- **Purpose:** computes actionable building badges like “READY” for Gold Mine
- **What was fixed:**
  - moved the Gold Mine badge count off raw dictionary reads and onto typed cache state
- **Status:** Fixed

## Problems found

1. **Gold Mine state was still dictionary-shaped after the network cleanup**
   - Risk: the client could still drift locally even though the API boundary was already typed.
   - Fix: moved slot state, cache state, and hub consumers onto `GoldMineSlotResponse`.

2. **Collect-all reconcile still trusted raw slot arrays from generic error payloads**
   - Risk: the hardest-to-debug path would stay the loosest one.
   - Fix: added a narrow typed payload bridge for slot arrays.

3. **Hub badges and hints were reading stale local keys directly**
   - Risk: a product-facing “READY” nudge could diverge from the same state shown inside the Gold Mine screen.
   - Fix: routed those surfaces through the same typed slot status logic.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check -- Hexbound/Hexbound/Models/MinigameSession.swift Hexbound/Hexbound/Services/GameDataCache.swift Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift Hexbound/Hexbound/Views/Minigames/GoldMineCards.swift Hexbound/Hexbound/Views/Minigames/GoldMineDetailView.swift Hexbound/Hexbound/Views/Hub/HubView.swift Hexbound/Hexbound/Views/Hub/CityMapView.swift`
- `rg -n '\\[String: Any\\]|legacySlots|gold_accumulated|gold_mined|slot\\[\"' Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift Hexbound/Hexbound/Views/Minigames/GoldMineCards.swift Hexbound/Hexbound/Views/Minigames/GoldMineDetailView.swift Hexbound/Hexbound/Views/Hub/HubView.swift Hexbound/Hexbound/Views/Hub/CityMapView.swift`

## Follow-up

- `GameDataCache` still intentionally keeps generic dictionaries for dynamic feature flags and some admin-layout hydration helpers.
- The next honest iOS tail is no longer Gold Mine state itself; it is the smaller set of internal bridge surfaces like `CombatEngine` and adjacent typed-vs-foundation conversion helpers.
