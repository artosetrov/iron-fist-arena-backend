---
title: Block 082 — iOS pending loot typed presentation contract
category: audit
tags: [audit, ios, loot, combat, dungeons, pvp, contracts]
sources:
  - Hexbound/Hexbound/Models/CombatData.swift
  - Hexbound/Hexbound/App/AppState.swift
  - Hexbound/Hexbound/Services/BattlePreloader.swift
  - Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift
  - Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift
  - Hexbound/Hexbound/Views/Combat/LootDetailView.swift
  - Hexbound/Hexbound/Views/Combat/CombatResultDetailView.swift
updated: 2026-04-16
status: Fixed
---

# Block 082 — iOS pending loot typed presentation contract

## Scope

- shared loot presentation model:
  - `Hexbound/Hexbound/Models/CombatData.swift`
  - `Hexbound/Hexbound/App/AppState.swift`
- live resolve / reward service boundary:
  - `Hexbound/Hexbound/Services/BattlePreloader.swift`
- loot producers:
  - `Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift`
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift`
- loot consumers:
  - `Hexbound/Hexbound/Views/Combat/LootDetailView.swift`
  - `Hexbound/Hexbound/Views/Combat/CombatResultDetailView.swift`

## Why this block

`block-081` finished the rush service cleanup, but one shared raw seam still cut across arena, dungeon, and rush flows:

- `AppState.pendingLoot` still stored `[[String: Any]]`
- `BattlePreloader.resolve(...)` still returned raw loot dictionaries
- both loot detail screens still rendered by stringly typed keys

That meant typed services were already landing back in an untyped presentation bucket before the user ever saw the reward.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[combat]]
- [[dungeons]]
- [[block-079-ios-dungeon-list-and-progress-typed-contracts]]
- [[block-080-ios-dungeon-combat-and-rush-entry-typed-contracts]]
- [[block-081-ios-dungeon-rush-resolve-and-shop-typed-contracts]]

## File notes

### `Hexbound/Hexbound/Models/CombatData.swift`

- **Zone:** iOS / models / combat and rewards
- **Purpose:** shared typed combat and loot payload definitions
- **Problems found:**
  - `CombatLootItem` covered combat DTOs, but there was no typed model for the shared app-level pending loot bucket
  - arena resolve loot, dungeon loot, and rush loot all had to downcast into dictionaries before reaching the UI
- **What was fixed:**
  - added `PendingLootItem` and `PendingLootShard`
  - added robust raw-dictionary normalization for legacy resolve payloads
  - added shared computed fields for display title, rarity/type keys, quantity, sell price, stats, and shard detection
- **Status:** Fixed

### `Hexbound/Hexbound/App/AppState.swift`

- **Zone:** iOS / app shell / shared state
- **Purpose:** owns app-level cross-screen navigation and transient reward state
- **Problems found:**
  - `pendingLoot` still used `[[String: Any]]`, which kept one of the most reused reward surfaces untyped
- **What was fixed:**
  - changed `pendingLoot` to `[PendingLootItem]`
- **Status:** Fixed

### `Hexbound/Hexbound/Services/BattlePreloader.swift`

- **Zone:** iOS / services / PvP resolve
- **Purpose:** resolves arena and PvP fights and returns server-verified rewards
- **Problems found:**
  - `ResolveResult.loot` still returned raw dictionaries even though the rest of the result had already been typed
- **What was fixed:**
  - mapped `response["loot"]` into `[PendingLootItem]`
  - updated `ResolveResult.loot` to the typed model
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift`

- **Zone:** iOS / dungeon runtime
- **Purpose:** applies dungeon fight results and parks loot for the shared result flow
- **Problems found:**
  - converted typed combat loot back into raw dictionaries before storing it in app state
- **What was fixed:**
  - replaced the dictionary bridge with `PendingLootItem(item)`
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift`

- **Zone:** iOS / dungeon rush runtime
- **Purpose:** applies rush combat and non-combat rewards and manages shared loot presentation
- **Problems found:**
  - same raw-dictionary bridge as the normal dungeon path
- **What was fixed:**
  - replaced the bridge with typed `PendingLootItem`
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Combat/LootDetailView.swift`

- **Zone:** iOS / combat result UI
- **Purpose:** standalone loot screen for pending rewards
- **Problems found:**
  - every render path still depended on string keys like `image_key`, `upgrade_level`, and `sell_price`
  - shard fallback loot had no explicit type-aware icon path
- **What was fixed:**
  - moved the screen onto `PendingLootItem`
  - kept the existing UI behavior, but now through typed properties
  - added shard-aware icon/color fallback so shard rewards no longer look like generic boxes
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Combat/CombatResultDetailView.swift`

- **Zone:** iOS / combat result UI
- **Purpose:** victory/defeat summary screen with reward presentation
- **Problems found:**
  - same raw-string parsing as `LootDetailView`
  - reward display stayed vulnerable to field-name drift even after the service layers were typed
- **What was fixed:**
  - moved loot display and detail modal onto `PendingLootItem`
  - kept the same UX, but removed the raw string-key dependency
- **Status:** Fixed

## Problems found

1. **Typed loot still collapsed into raw dictionaries at the app-state boundary**
   - Risk: service cleanup kept getting undone before the result screen, so one field drift could still break multiple reward surfaces at once.
   - Fix: introduced `PendingLootItem` as the shared typed presentation model.

2. **Arena resolve had a half-typed contract**
   - Risk: `ResolveResult` looked typed everywhere except the loot field, which made arena reward UI easier to drift than the rest of the combat result.
   - Fix: typed `ResolveResult.loot`.

3. **Loot screens still parsed string keys directly**
   - Risk: reward UI could silently regress on renamed fields like `sell_price`, `image_key`, or shard payloads.
   - Fix: moved both loot screens to typed properties and kept raw parsing only inside one normalization initializer.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`
- `rg -n 'pendingLoot: \\[\\[String: Any\\]\\]|lootDetailModal\\(_ item: \\[String: Any\\]\\)' Hexbound/Hexbound`

## Follow-up

- `pendingLoot` is now typed, but the broader `AppState` still carries other legacy dictionary caches (`currentUser`, `cachedQuests`, `cachedAchievements`, `cachedDailyLogin`)
- `LootDetailView` and `CombatResultDetailView` still duplicate the modal layout; the runtime contract is now safe, but the presentation duplication still deserves its own keep/simplify pass later
