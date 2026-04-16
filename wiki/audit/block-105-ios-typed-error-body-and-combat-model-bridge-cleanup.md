---
title: Block 105 — iOS typed error-body and combat model bridge cleanup
category: audit
tags: [audit, ios, networking, combat, gold-mine, referral]
sources:
  - Hexbound/Hexbound/Network/APIError.swift
  - Hexbound/Hexbound/Models/InteractiveCombatModels.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift
  - Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift
  - Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift
  - Hexbound/Hexbound/Models/CombatData.swift
updated: 2026-04-16
status: Fixed
---

# Block 105 — iOS typed error-body and combat model bridge cleanup

## Scope

- `Hexbound/Hexbound/Network/APIError.swift`
- `Hexbound/Hexbound/Models/InteractiveCombatModels.swift`
- `Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift`
- `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`
- `Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift`
- `Hexbound/Hexbound/Models/CombatData.swift`

## Why this block

By block `104`, the big iOS raw-network migration was already mostly done, but three recoverable client flows still unpacked `APIError.responsePayload` as loose dictionaries:

- interactive combat recoverable `409 OUT_OF_CONSUMABLE`
- Gold Mine `409 NO_PLAYABLE_SLOTS`
- referral apply validation errors

That meant the app had clean success-path DTOs while some of the most player-visible failure/reconcile paths still depended on stringly typed body parsing.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[interactive-combat]]
- [[gold-mine]]
- [[block-101-ios-interactive-combat-reconcile-payload-bridge-cleanup]]
- [[block-104-ios-battle-preloader-combat-engine-typed-handoff]]

## File notes

### `Hexbound/Hexbound/Network/APIError.swift`

- **Zone:** iOS / networking
- **Purpose:** shared typed error wrapper for API transport, decoding, and user-facing network failures
- **Problems found:**
  - recoverable flows still had to reopen raw `responsePayload` and hand-parse it locally
- **What was fixed:**
  - added `decodedResponseBody(_:)` so recoverable 4xx bodies can be read as typed DTOs without reintroducing per-feature dictionary parsing
- **Status:** Fixed

### `Hexbound/Hexbound/Models/InteractiveCombatModels.swift`

- **Zone:** iOS / interactive combat DTOs
- **Purpose:** shared typed payloads for live PvP turns, actives, and server-authoritative strike responses
- **Problems found:**
  - the recoverable strike path still depended on a separate raw payload bridge
- **What was fixed:**
  - added `InteractiveRecoverableStrikePayload`
  - removed the need for a custom raw `actives` bridge outside normal decoding
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift`

- **Zone:** iOS / interactive combat runtime
- **Purpose:** owns client-side turn prediction, reconcile flow, cooldown state, and strike retry handling
- **Problems found:**
  - the recoverable `OUT_OF_CONSUMABLE` branch still manually read `code`, `actives`, and `removed_consumable_type` from raw dictionaries
- **What was fixed:**
  - switched the recoverable strike path to `InteractiveRecoverableStrikePayload`
  - removed the dead local `decodeActivesState(from:)` JSON round-trip
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`

- **Zone:** iOS / Gold Mine runtime
- **Purpose:** handles slot actions, reconcile state, collect-all flow, and Gold Mine live state mutations
- **Problems found:**
  - the `NO_PLAYABLE_SLOTS` error path still inspected raw payload keys for `slots` and `unplayed_ready_slot_indices`
- **What was fixed:**
  - added a typed collect-all error payload and moved this branch onto normal DTO decoding
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift`

- **Zone:** iOS / settings / referral
- **Purpose:** loads referral status and applies referral codes for the active character
- **Problems found:**
  - already-referred / invalid-code validation still depended on raw error dictionaries
- **What was fixed:**
  - added a typed referral apply error payload
  - kept the control flow but removed local dictionary inspection
- **Status:** Fixed

### `Hexbound/Hexbound/Models/CombatData.swift`

- **Zone:** iOS / combat result models
- **Purpose:** shared combat result, reward, and pending-loot presentation models
- **Problems found:**
  - `PendingLootItem` still carried a dead `rawDictionary` initializer even after the typed loot migration was finished
- **What was fixed:**
  - removed the dead raw initializer and its raw parsing helpers
- **Status:** Fixed

## Problems found

1. **Recoverable error flows still lived on raw dictionaries after the success-path migration**
   - Risk: the app could silently drift in the exact places where reconciliation matters most.
   - Fix: added a typed body decode helper on `APIError` and moved recoverable flows onto DTOs.

2. **Interactive combat still carried a second internal payload dialect for actives reconciliation**
   - Risk: client/server contract changes would stay easy to miss on the error path even after the live strike DTOs were already typed.
   - Fix: introduced `InteractiveRecoverableStrikePayload` and deleted the last local raw reconcile helper.

3. **Pending-loot models still preserved a dead raw escape hatch**
   - Risk: future feature work could accidentally reuse a stale dictionary path that no live flow actually needed anymore.
   - Fix: removed the dead initializer from `PendingLootItem`.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`
- `rg -n 'InteractiveCombatPayloadBridge|fromPayload\\(|PendingLootItem\\(rawDictionary|responsePayload' Hexbound/Hexbound -g'*.swift'`

## Follow-up

- Shared networking still intentionally owns one raw JSON extraction point for generic error bodies inside `APIClient` / `APIError`.
- That boundary is now centralized again; the remaining iOS work has shifted away from feature-level error parsing and toward smaller shared-model/cache cleanups.
