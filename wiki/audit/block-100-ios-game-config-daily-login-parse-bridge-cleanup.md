---
title: Block 100 — iOS game config daily login parse bridge cleanup
category: audit
tags: [audit, ios, cache, config, daily-login]
sources:
  - Hexbound/Hexbound/Models/DailyLoginRewardDef.swift
  - Hexbound/Hexbound/Services/GameDataCache.swift
updated: 2026-04-16
status: Fixed
---

# Block 100 — iOS game config daily login parse bridge cleanup

## Scope

- `Hexbound/Hexbound/Models/DailyLoginRewardDef.swift`
- `Hexbound/Hexbound/Services/GameDataCache.swift`

## Why this block

By this point the live network contract tails in `Hexbound` were nearly gone. One of the remaining internal bridges was `GameConfig.parseDailyRewards(...)`, which still used `JSONSerialization` to re-encode raw dictionaries before decoding them back into `DailyLoginRewardDef`.

That was not a product bug anymore, but it was noisy, indirect, and exactly the kind of bridge that tends to survive long after the boundary is already understood.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-016-backend-daily-login-battle-pass-reward-contracts]]
- [[block-071-ios-hub-daily-login-and-levelup-contract-cleanup]]

## File notes

### `Hexbound/Hexbound/Models/DailyLoginRewardDef.swift`

- **Zone:** iOS / shared reward DTOs
- **Purpose:** canonical daily login reward definition consumed from game config
- **What was fixed:**
  - added a dictionary initializer that accepts both snake_case and camelCase keys
  - localized primitive parsing for `amount`, `itemId`, `displayName`, and `displayIcon`
- **Status:** Fixed

### `Hexbound/Hexbound/Services/GameDataCache.swift`

- **Zone:** iOS / cache / bootstrap config
- **Purpose:** holds the game config snapshot used by startup and daily-login UI
- **Problems found:**
  - `parseDailyRewards(...)` still performed a JSON round-trip only to get back to a typed reward list
- **What was fixed:**
  - replaced the JSON round-trip with direct dictionary-to-model parsing
  - preserved the existing `count == 7` safety gate and fallback behavior
- **Status:** Fixed

## Problems found

1. **Config parsing still used an unnecessary JSON round-trip**
   - Risk: not correctness-critical anymore, but it obscured the real accepted payload shape and kept a needless bridge alive.
   - Fix: moved to direct typed parsing.

2. **The accepted key shape was implicit**
   - Risk: future readers would have to reverse-engineer whether this path expected snake_case or camelCase.
   - Fix: made the accepted keys explicit in the model-side bridge.

## Verification

- `git diff --check -- Hexbound/Hexbound/Models/DailyLoginRewardDef.swift Hexbound/Hexbound/Services/GameDataCache.swift`
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `rg -n 'JSONSerialization' Hexbound/Hexbound/Services/GameDataCache.swift Hexbound/Hexbound/Models/DailyLoginRewardDef.swift`

## Follow-up

- `GameDataCache` still contains legacy cache dictionaries for a few old local-state surfaces, but the daily login reward parse path is now explicit and typed.
- This block intentionally narrowed the remaining residual raw usage to even smaller internal bridges.
