---
title: Block 081 — iOS dungeon rush resolve and shop typed contracts
category: audit
tags: [audit, ios, dungeon-rush, contracts, shop, minigames]
sources:
  - Hexbound/Hexbound/Services/DungeonService.swift
  - Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift
updated: 2026-04-16
status: Fixed
---

# Block 081 — iOS dungeon rush resolve and shop typed contracts

## Scope

- rush mutation service boundary:
  - `Hexbound/Hexbound/Services/DungeonService.swift`
- rush event/treasure/shop runtime:
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift`

## Why this block

`block-080` moved rush `status/start/fight` onto typed contracts, but the other half of the rush runtime still lived on raw dictionaries:

- `resolve`
- `shop-buy`
- the event / treasure / leave-shop paths built on top of them

That meant the rush contract was still split into two dialects inside one view model.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[minigames]]
- [[dungeons]]
- [[block-080-ios-dungeon-combat-and-rush-entry-typed-contracts]]

## File notes

### `Hexbound/Hexbound/Services/DungeonService.swift`

- **Zone:** iOS / services / dungeon rush
- **Purpose:** owns the live rush mutation contract surface
- **Problems found:**
  - `rushResolve(...)` still used raw body assembly and returned `[String: Any]`
  - `rushShopBuy(...)` still returned `[String: Any]`
  - that left the rush service half-typed and half-raw inside the same file
- **What was fixed:**
  - added typed resolve/shop DTOs and request bodies
  - moved `rushResolve(...)` and `rushShopBuy(...)` onto typed `APIClient.post(...)`
  - captured the event/treasure/shop/leave-shop response surface as explicit DTOs instead of ad hoc dictionary reads
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift`

- **Zone:** iOS / minigames / dungeon rush runtime
- **Purpose:** drives rush room progression, reward application, shop purchases, and event/treasure overlays
- **Problems found:**
  - resolve flow still parsed everything by string key
  - shop-buy used raw dictionaries and had a real field drift bug: client looked for `gold`, while backend returned `playerGold`
  - next-room advancement and reward sync were still duplicated in a raw-only path
- **What was fixed:**
  - moved open-shop, leave-shop, resolve-room, and shop-buy flows onto typed responses
  - moved reward application and next-room advancement onto typed resolve DTOs
  - fixed the shop purchase gold-sync bug by switching the client to the real `playerGold` field
  - removed the last now-unused raw buff parser in the rush VM
- **Status:** Fixed

## Problems found

1. **Rush still had a split contract boundary**
   - Risk: `fight` was typed, but `resolve/shop` could still drift independently inside the same runtime.
   - Fix: moved the remaining rush mutations to typed DTOs.

2. **Shop purchase gold sync used the wrong field name**
   - Risk: a successful shop purchase could leave local gold stale even though the backend returned an authoritative total.
   - Fix: switched the client to typed `playerGold`.

3. **Rush reward and next-room logic were duplicated in raw form**
   - Risk: treasure/event/shop paths could diverge from the already-cleaned combat path.
   - Fix: moved those paths onto typed resolve responses and shared typed helpers.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`
- `rg -n 'rushResolve\\(|rushShopBuy\\(' Hexbound/Hexbound/Services/DungeonService.swift`

## Follow-up

- the biggest remaining raw shape around rush is now mostly `pendingLoot` compatibility with the shared app-level loot presentation path
- artifact-pick flow exists on the backend contract and DTO surface, but still deserves a dedicated iOS product pass once the UI for it becomes live
