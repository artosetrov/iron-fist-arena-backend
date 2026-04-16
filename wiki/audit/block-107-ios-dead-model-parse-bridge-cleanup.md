---
title: Block 107 — iOS dead model parse-bridge cleanup
category: audit
tags: [audit, ios, models, gold-mine, dungeons, cleanup]
sources:
  - Hexbound/Hexbound/Models/MinigameSession.swift
  - Hexbound/Hexbound/Models/DailyLoginRewardDef.swift
  - Hexbound/Hexbound/Models/DungeonInfo.swift
updated: 2026-04-16
status: Fixed
---

# Block 107 — iOS dead model parse-bridge cleanup

## Scope

- `Hexbound/Hexbound/Models/MinigameSession.swift`
- `Hexbound/Hexbound/Models/DailyLoginRewardDef.swift`
- `Hexbound/Hexbound/Models/DungeonInfo.swift`

## Why this block

After the recent Gold Mine, dungeon, and bootstrap migrations, a few model files still carried old raw parsing helpers even though the live callers had already moved on:

- `MinigameSession.swift` still contained payload constructors and legacy dictionary exports for Gold Mine slot models
- `DungeonInfo.swift` still had an old `/dungeons/list` raw parser that no runtime path used anymore
- `DailyLoginRewardDef.swift` looked like a dead raw helper candidate, but one narrow dictionary initializer was still legitimately used by `GameConfig` cache fallback

So this block was mostly about deleting what was truly dead while keeping the one compatibility helper that still has a real caller.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[gold-mine]]
- [[dungeons]]
- [[block-079-ios-dungeon-list-and-progress-typed-contracts]]
- [[block-103-ios-gold-mine-typed-state-and-cache-parity]]

## File notes

### `Hexbound/Hexbound/Models/MinigameSession.swift`

- **Zone:** iOS / Gold Mine and tavern DTOs
- **Purpose:** typed minigame/session models for Gold Mine, Fortune Wheel, and Shell Game
- **Problems found:**
  - Gold Mine slot models still carried raw `payload` initializers, legacy dictionary exports, and legacy slot-array bridges with no remaining callers
- **What was fixed:**
  - removed the dead raw payload initializers for `GoldMineSlotStatsResponse` and `GoldMineSlotResponse`
  - removed legacy dictionary / legacy slot exports
  - removed the old `GoldMinePayload` raw value helpers, keeping only the date parsing the typed runtime still needs
- **Status:** Fixed

### `Hexbound/Hexbound/Models/DailyLoginRewardDef.swift`

- **Zone:** iOS / daily login models
- **Purpose:** typed reward definition model shared by bootstrap and daily-login UI
- **Problems found:**
  - during this block, the file still appeared to need a dictionary compatibility initializer because `GameConfig` fallback parsing had not yet been retired
- **What was fixed:**
  - kept the helper temporarily while confirming the true caller set
  - that compatibility path was later removed in `[[block-108-ios-intentional-raw-boundaries-and-dead-apiresponse-removal]]`
- **Status:** Fixed

### `Hexbound/Hexbound/Models/DungeonInfo.swift`

- **Zone:** iOS / dungeon presentation models
- **Purpose:** player-facing dungeon card/boss/loot presentation plus bundled fallback data
- **Problems found:**
  - an old `from(serverData:)` parser remained even though `DungeonService` already owns the live typed mapping
- **What was fixed:**
  - removed the dead raw parser and its private icon helper
  - left the bundled fallback/static dungeon catalog intact
- **Status:** Fixed

## Problems found

1. **Gold Mine model files still implied a live raw model dialect**
   - Risk: future work could accidentally resurrect dictionary paths that no typed caller actually needed anymore.
   - Fix: deleted the unused raw constructors and legacy dictionary bridges from `MinigameSession.swift`.

2. **`DungeonInfo` still advertised a raw server parser even after the live service migration**
   - Risk: model ownership would stay blurred between `DungeonService` and the presentation model.
   - Fix: removed the dead `from(serverData:)` parser from `DungeonInfo.swift`.

3. **One dictionary helper looked dead but still had a hidden caller at audit time**
   - Risk: deleting it immediately would have broken the remaining raw `GameConfig` fallback path.
   - Fix: restored it during this block, then removed the actual dead caller in `[[block-108-ios-intentional-raw-boundaries-and-dead-apiresponse-removal]]`.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`
- `rg -n 'legacyDictionary|legacySlots|init\\(payload: \\[String: Any\\]\\)|GoldMinePayload\\.|DungeonInfo\\.from\\(serverData' Hexbound/Hexbound -g'*.swift'`

## Follow-up

- The remaining iOS tail is now even more obviously about live callers and shared contracts, not dead raw model layers.
- `DailyLoginRewardDef.init(dictionary:)` was revisited and removed in `[[block-108-ios-intentional-raw-boundaries-and-dead-apiresponse-removal]]` once the dead `GameConfig` raw fallback path was retired.
