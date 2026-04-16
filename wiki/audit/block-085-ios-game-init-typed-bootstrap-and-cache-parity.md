---
title: Block 085 — iOS game/init typed bootstrap and cache parity
category: audit
tags: [audit, ios, bootstrap, contracts, cache]
updated: 2026-04-16
---

# Block 085 — iOS game/init typed bootstrap and cache parity

## Scope

- `Hexbound/Hexbound/Services/GameInitService.swift`
- `Hexbound/Hexbound/App/AppState.swift`

## Why this block existed

`GameInitService` was still one of the last large iOS bootstrap surfaces living on `getRaw + JSONSerialization + [String: Any]`. That left startup state brittle in exactly the place where the app hydrates character, inventory, daily login, feature flags, layouts, and config in one shot.

It also had a real data-parity hole: `/api/game/init` already returned `consumables`, but the client only flattened equipment into `cachedInventory`, so the bootstrap inventory snapshot could quietly disagree with the live inventory screen until a later refresh.

## What the files do

### `Hexbound/Hexbound/Services/GameInitService.swift`

- Calls `/api/game/init`
- Hydrates `AppState` and `GameDataCache`
- Restores hub/dungeon layout caches from disk before network
- Falls back to `CharacterService.loadCharacter()` if the unified bootstrap fails

### `Hexbound/Hexbound/App/AppState.swift`

- Holds the currently authenticated user snapshot
- Holds cached bootstrap slices such as daily login and quests
- Owns the shared “auto-open daily login once per day” decision

## Dependencies

- `APIClient`
- `Character`
- `Item`
- `Quest`
- `DailyLoginData`
- `GameDataCache`
- `ConsumableCatalog`
- `AppearancesResponse`

## Inbound usage

- `HexboundApp` / app bootstrap flows
- hub entry and first-screen hydration
- daily login modal gating through `AppState.maybeEnqueueDailyLogin()`
- any surface reading `cache.gameConfig`, `cache.featureFlags`, hub layout, dungeon map layout, or `cachedInventory`

## Fixes made

1. Migrated `GameInitService` from raw JSON parsing to a typed `GameInitResponse`.
2. Added typed bootstrap DTOs for:
   - user snapshot
   - equipment inventory entries
   - consumable inventory entries
   - config payload
   - feature-flag JSON values
   - layout overrides
3. Moved `AppState.currentUser` off `[String: Any]` onto `CurrentUserSnapshot`.
4. Moved `AppState.cachedDailyLogin` off `[String: Any]` onto `DailyLoginData`.
5. Updated `AppState.isAdmin` and `maybeEnqueueDailyLogin()` to use typed state.
6. Fixed bootstrap inventory parity by including `consumables` from `/api/game/init`, not just equipment.
7. Removed raw `JSONSerialization` and `getRaw(...)` usage from `GameInitService`.
8. Kept `featureFlags` flexible by decoding arbitrary JSON values into a local `JSONValue` bridge and only converting to Foundation at the cache edge.
9. Preserved existing fallback behavior: failed unified bootstrap still falls back to `CharacterService.loadCharacter()`.

## Problems found

### 1. Raw bootstrap contract in a high-risk service

- **Problem:** Startup hydration used dictionary parsing for character, user, quests, daily login, config, feature flags, and layouts.
- **Risk:** silent drift whenever backend field names or shapes moved; brittle startup; harder debugging.
- **Fix:** replaced with typed DTOs and localized JSON bridging only where truly needed (`featureFlags`).

### 2. Consumables were dropped from bootstrap inventory

- **Problem:** `/api/game/init` returned `consumables`, but the client only flattened `equipment`.
- **Risk:** app launch could show an incomplete inventory until a later explicit inventory refresh.
- **Fix:** mapped bootstrap consumables through the same `ConsumableCatalog` logic used by inventory runtime and merged them into `cachedInventory`.

### 3. Typed daily-login state was lagging behind the rest of the client

- **Problem:** `cachedDailyLogin` stayed raw even after daily-login runtime already had DTOs.
- **Risk:** duplicated parsing rules and unnecessary string-key coupling in the bootstrap path.
- **Fix:** switched `cachedDailyLogin` to `DailyLoginData` and updated `maybeEnqueueDailyLogin()`.

### 4. Admin-role check depended on raw dictionary access

- **Problem:** `isAdmin` read `currentUser?["role"]`.
- **Risk:** trivial contract drift and harder refactors around auth/bootstrap.
- **Fix:** switched `currentUser` to `CurrentUserSnapshot`.

## What was intentionally left alone

- `cachedQuests` still exists as a legacy raw cache slot, but bootstrap now writes only the typed quest cache that live consumers actually use.
- `activeEvents` and `achievementsSummary` still come down from `/api/game/init`, but this block did not widen scope into unused consumer wiring just to “use every field.”

## Keep / fix / delete

- **Keep:** unified `/api/game/init` bootstrap path
- **Keep:** fallback to `CharacterService` on unified bootstrap failure
- **Fix next:** either consume `activeEvents` from bootstrap or stop shipping them in the init payload
- **Fix next:** remove dead `cachedQuests` if no remaining live consumer appears in later audit blocks

## Status

**Fixed**
