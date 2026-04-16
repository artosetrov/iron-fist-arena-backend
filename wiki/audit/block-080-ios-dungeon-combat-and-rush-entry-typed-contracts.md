---
title: Block 080 — iOS dungeon combat and rush entry typed contracts
category: audit
tags: [audit, ios, dungeons, dungeon-rush, contracts, combat]
sources:
  - Hexbound/Hexbound/Services/DungeonService.swift
  - Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift
  - Hexbound/Hexbound/Views/Dungeon/DungeonVictoryView.swift
  - Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift
updated: 2026-04-16
status: Fixed
---

# Block 080 — iOS dungeon combat and rush entry typed contracts

## Scope

- dungeon/rush service boundary:
  - `Hexbound/Hexbound/Services/DungeonService.swift`
- normal dungeon combat flow:
  - `Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift`
  - `Hexbound/Hexbound/Views/Dungeon/DungeonVictoryView.swift`
- dungeon rush start/status/fight flow:
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift`

## Why this block

After `block-079`, the next real holdout was not the dungeon list anymore, but the dungeon result path itself.

Two related flows were still weaker than the rest of the app:

- normal dungeon `start/fight`
- dungeon rush `status/start/fight`

The service boundary still returned raw dictionaries for those operations, and both view models still had to reinterpret the same network shape locally.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[dungeons]]
- [[block-079-ios-dungeon-list-and-progress-typed-contracts]]

## File notes

### `Hexbound/Hexbound/Services/DungeonService.swift`

- **Zone:** iOS / services / dungeons
- **Purpose:** owns live dungeon and dungeon-rush network contracts
- **Problems found:**
  - normal dungeon `start/fight` still returned `[String: Any]`
  - rush `status/start/fight` still returned `[String: Any]`
  - the typed cleanup done in `block-079` stopped exactly where the more important combat mutations began
- **What was fixed:**
  - added typed DTOs for dungeon start/fight payloads and rush state/fight payloads
  - moved `start(...)`, `fight(...)`, `rushStatus(...)`, `rushStart(...)`, and `rushFight(...)` onto typed `APIClient.get/post(...)`
  - added typed request bodies for dungeon and rush mutations
  - exposed typed `combatData` bridging helpers on the fight DTOs so consumers no longer need to round-trip through `JSONSerialization`
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift`

- **Zone:** iOS / dungeons / combat runtime
- **Purpose:** starts dungeon runs, launches boss fights, handles victory/defeat state, and feeds the dungeon combat animation
- **Problems found:**
  - normal dungeon fight flow still depended on raw dictionary parsing even after typed list/progress cleanup
  - `pendingFightResult` and victory reward handling stayed stringly-typed
  - combat animation handoff still relied on ad hoc JSON decoding
- **What was fixed:**
  - switched dungeon start/fight calls to typed service responses
  - replaced raw `pendingFightResult` with typed `DungeonFightResponse`
  - replaced manual JSON combat decoding with the typed `combatData` bridge from the service DTO
  - replaced raw victory loot arrays with typed `CombatLootItem`
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Dungeon/DungeonVictoryView.swift`

- **Zone:** iOS / dungeons / victory ceremony
- **Purpose:** renders dungeon reward, XP, loot, and level-up feedback after a successful boss kill
- **Problems found:**
  - still expected loot rows as raw dictionaries from the view model
  - that made the typed fight cleanup above stop just short of the visible reward screen
- **What was fixed:**
  - moved the reward-card mapping onto typed `CombatLootItem`
  - preserved the same rarity/icon/image fallback behavior
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift`

- **Zone:** iOS / minigames / dungeon rush
- **Purpose:** starts rush runs, resumes active runs, launches combat rooms, and advances room-to-room state
- **Problems found:**
  - rush status/start/fight still depended on raw dictionaries
  - combat handoff to the shared combat screen still went through a local JSON round-trip
  - rush entry/resume and rush combat used a different contract hygiene level than normal dungeons
- **What was fixed:**
  - switched rush status/start/fight onto typed DTOs
  - replaced typed-room/buff/enemy parsing in those live paths
  - replaced combat animation handoff with the same typed `combatData` bridge used by normal dungeons
  - kept raw resolve/shop paths in place for now so the cleanup stayed scoped and safe
- **Status:** Fixed

## Problems found

1. **The typed dungeon cleanup stopped before the mutation boundary**
   - Risk: compile-time safety existed for list/progress, but the actual combat flow could still drift silently.
   - Fix: moved dungeon `start/fight` to typed contracts.

2. **Rush entry and combat used a weaker API language than the rest of iOS**
   - Risk: the biggest live minigame flow still depended on repeated local dictionary parsing.
   - Fix: moved rush `status/start/fight` onto typed DTOs and typed combat handoff.

3. **Victory/loot UI still depended on raw loot dictionaries**
   - Risk: typed service work would stop short of the player-facing reward ceremony.
   - Fix: moved dungeon victory loot onto `CombatLootItem`.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`
- `rg -n 'func start\\(|func fight\\(|func rushStatus\\(|func rushStart\\(|func rushFight\\(' Hexbound/Hexbound/Services/DungeonService.swift`

## Follow-up

- `DungeonService.rushResolve(...)` and `DungeonService.rushShopBuy(...)` are still raw
- `DungeonRushViewModel` still has raw resolve/shop/event/treasure handling around those endpoints
- once those resolve/shop contracts are typed too, the remaining rush runtime can be closed as a separate block instead of a broad rewrite
