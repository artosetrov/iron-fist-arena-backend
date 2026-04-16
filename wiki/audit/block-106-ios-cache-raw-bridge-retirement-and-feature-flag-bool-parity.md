---
title: Block 106 — iOS cache raw-bridge retirement and feature-flag bool parity
category: audit
tags: [audit, ios, cache, bootstrap, feature-flags]
sources:
  - Hexbound/Hexbound/App/AppState.swift
  - Hexbound/Hexbound/Services/GameDataCache.swift
  - Hexbound/Hexbound/Services/GameInitService.swift
updated: 2026-04-16
status: Fixed
---

# Block 106 — iOS cache raw-bridge retirement and feature-flag bool parity

## Scope

- `Hexbound/Hexbound/App/AppState.swift`
- `Hexbound/Hexbound/Services/GameDataCache.swift`
- `Hexbound/Hexbound/Services/GameInitService.swift`

## Why this block

After the typed bootstrap work in blocks `085`, `100`, and `102`, the main startup flow was already running on DTOs, but the cache/state layer still kept a few leftover raw bridges:

- unused raw quest/achievement caches in `AppState`
- dead dictionary-based layout cache entry points in `GameDataCache`
- a feature-flag cache stored as `[String: Any]` even though the live iOS client only consumed booleans

This was no longer giving us flexibility. It was just leaving a quiet `[String: Any]` shadow behind an otherwise typed bootstrap path.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-085-ios-game-init-typed-bootstrap-and-cache-parity]]
- [[block-100-ios-game-config-daily-login-parse-bridge-cleanup]]
- [[block-102-ios-network-infrastructure-raw-surface-retirement]]

## File notes

### `Hexbound/Hexbound/App/AppState.swift`

- **Zone:** iOS / shared app session state
- **Purpose:** root state container for auth, character, combat, modal, and cache-adjacent values
- **Problems found:**
  - raw `cachedQuests` and `cachedAchievements` were still declared even though live flows had already moved to typed cache/state
- **What was fixed:**
  - removed the dead raw quest and achievement caches
  - narrowed cache invalidation to the typed values that still exist
- **Status:** Fixed

### `Hexbound/Hexbound/Services/GameDataCache.swift`

- **Zone:** iOS / shared cache
- **Purpose:** in-memory plus persisted cache for init/bootstrap data, hub layout, dungeon map layout, and screen-level payloads
- **Problems found:**
  - `featureFlags` still used `[String: Any]`
  - `featureFlagValue<T>` had become dead generic surface
  - dictionary-based `cacheHubLayout(from:)` and `cacheDungeonMapLayout(from:)` were no longer called
- **What was fixed:**
  - narrowed feature flags to `[String: Bool]`
  - removed the dead generic accessor
  - removed the dead dictionary layout cache entry points
- **Status:** Fixed

### `Hexbound/Hexbound/Services/GameInitService.swift`

- **Zone:** iOS / bootstrap
- **Purpose:** owns `/game/init` load, startup cache population, and server-time/bootstrap hydration
- **Problems found:**
  - the feature-flag path still re-expanded typed JSON into foundation `Any`
- **What was fixed:**
  - changed feature-flag caching to keep only boolean flags that the iOS client actually consumes
  - replaced `foundationValue` bridging with a narrower `boolValue` extraction
- **Status:** Fixed

## Problems found

1. **The typed bootstrap path still ended in `[String: Any]` for feature flags**
   - Risk: startup code would keep a misleadingly generic cache surface even though the app only used boolean enablement.
   - Fix: made feature flags boolean-only in the cache and removed the unused generic accessor.

2. **Dead raw cache properties were still present in `AppState`**
   - Risk: future work could accidentally write to or rely on stale raw cache lanes that no live feature still used.
   - Fix: removed the unused raw quest/achievement caches.

3. **Dictionary layout cache entry points were still hanging around after the typed layout migration**
   - Risk: these methods kept implying that the layout layer still needed raw hydration from feature code when it no longer did.
   - Fix: removed the dead raw layout cache bridges.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`
- `rg -n 'cachedQuests|cachedAchievements|featureFlagValue\\(|cacheHubLayout\\(from|cacheDungeonMapLayout\\(from|foundationValue' Hexbound/Hexbound -g'*.swift'`

## Follow-up

- This deliberately narrows iOS feature-flag caching to boolean flags because that is the only live contract the client currently consumes.
- If the app later needs non-bool flag payloads, it should add a typed model for that use instead of reopening `[String: Any]`.
