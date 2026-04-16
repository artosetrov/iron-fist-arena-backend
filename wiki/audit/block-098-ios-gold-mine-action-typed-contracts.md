---
title: Block 098 — iOS gold mine action typed contracts
category: audit
tags: [audit, ios, gold-mine, contracts]
sources:
  - Hexbound/Hexbound/Models/MinigameSession.swift
  - Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift
  - Hexbound/Hexbound/Views/Minigames/GoldMineMiniGameView.swift
  - backend/src/app/api/minigames/gold-mine/start/route.ts
  - backend/src/app/api/minigames/gold-mine/collect/route.ts
  - backend/src/app/api/minigames/gold-mine/collect-all/route.ts
  - backend/src/app/api/minigames/gold-mine/slot-minigame/start/route.ts
  - backend/src/app/api/minigames/gold-mine/slot-minigame/submit/route.ts
  - backend/src/app/api/minigames/gold-mine/boost/route.ts
  - backend/src/app/api/minigames/gold-mine/buy-slot/route.ts
updated: 2026-04-16
status: Fixed
---

# Block 098 — iOS gold mine action typed contracts

## Scope

- `Hexbound/Hexbound/Models/MinigameSession.swift`
- `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`
- `Hexbound/Hexbound/Views/Minigames/GoldMineMiniGameView.swift`
- backend gold mine action routes for `start`, `collect`, `collect-all`, `slot-minigame/start`, `slot-minigame/submit`, `boost`, and `buy-slot`

## Why this block

After `[[block-097-ios-dungeon-rush-abandon-and-gold-mine-status-typed-contracts]]`, the read-side gold mine status contract was clean, but the player-facing mutation layer still lived on raw dictionaries. That was the last big live Gold Mine transport tail on iOS.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-097-ios-dungeon-rush-abandon-and-gold-mine-status-typed-contracts]]
- [[systems/gold-mine]]

## File notes

### `Hexbound/Hexbound/Models/MinigameSession.swift`

- **Zone:** iOS / minigames / shared DTOs
- **Purpose:** shared typed contracts for Gold Mine sessions and action responses
- **Problems found:**
  - action routes still had no canonical typed request/response DTO layer
- **What was fixed:**
  - added typed request DTOs for slot actions, character actions, collect-all, minigame start, and minigame submit
  - added typed response DTOs for start, collect, collect-all, slot-minigame start/submit, boost, and buy-slot
  - kept the narrow `legacySlots` bridge so old slot rendering can stay stable while the transport boundary is now typed
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`

- **Zone:** iOS / gold mine / runtime
- **Purpose:** owns the main Gold Mine player flow
- **Problems found:**
  - core player actions still used raw mutation payloads
  - collect-all / shaft-picker / minigame handoff still depended on weakly typed route responses
- **What was fixed:**
  - moved `startMining`, `collect`, `collectAll`, `startSlotMinigame`, `boost`, and `buySlot` onto typed `APIClient.post(...)`
  - replaced the raw minigame result bridge with `GoldMineSlotMinigameSubmitResponse`
  - removed local `JSONSerialization`-based minigame session decoding
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Minigames/GoldMineMiniGameView.swift`

- **Zone:** iOS / gold mine / slot bonus minigame
- **Purpose:** submits the timed slot-bonus minigame result and hands the reward back to the parent flow
- **Problems found:**
  - submit flow still used `postRaw(...)`
  - the result callback still moved a raw dictionary through the view boundary
- **What was fixed:**
  - switched submit to typed `GoldMineSlotMinigameSubmitResponse`
  - changed `onFinish` and local state from raw dictionaries to the typed response
- **Status:** Fixed

## Problems found

1. **The live Gold Mine action layer still depended on raw payloads**
   - Risk: it was one of the last heavy player-facing contract tails where server changes would fail late and opaquely.
   - Fix: migrated the whole action layer to typed request/response DTOs.

2. **Bonus minigame submit still crossed a raw dictionary boundary**
   - Risk: the typed transport cleanup would still leak back into a raw view contract.
   - Fix: made the minigame result callback typed end-to-end.

3. **Gold Mine had already cleaned its read-side but not its write-side**
   - Risk: future drift would cluster exactly where the player spends taps and currency.
   - Fix: aligned the mutation layer to the same typed model strategy as status loading.

## Verification

- `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization' Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift Hexbound/Hexbound/Views/Minigames/GoldMineMiniGameView.swift Hexbound/Hexbound/Models/MinigameSession.swift`
- `git diff --check -- Hexbound/Hexbound/Models/MinigameSession.swift Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift Hexbound/Hexbound/Views/Minigames/GoldMineMiniGameView.swift`
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`

## Follow-up

- Gold Mine no longer holds a live raw network tail on iOS.
- The remaining residual raw usage in `Hexbound` after this block is no longer the Gold Mine product flow; it is down to shared cache/config bridges and one interactive-combat recoverable-error bridge.
