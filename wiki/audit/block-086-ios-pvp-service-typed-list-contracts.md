---
title: Block 086 — iOS PvP service typed list contracts
category: audit
tags: [audit, ios, pvp, contracts]
updated: 2026-04-16
---

# Block 086 — iOS PvP service typed list contracts

## Scope

- `Hexbound/Hexbound/Services/PvPService.swift`
- `Hexbound/Hexbound/Models/RevengeEntry.swift`

## Why this block existed

`PvPService` was still one of the remaining live iOS services using `getRaw + JSONSerialization` for stable backend envelopes. That was especially noisy here because the backend already returned clean top-level shapes for opponents, revenge entries, and match history.

There was also one model-level mismatch keeping this raw bridge alive: `RevengeEntry` still depended on explicit snake_case coding keys, which fought the app-wide `APIClient` decoder strategy.

## What the files do

### `Hexbound/Hexbound/Services/PvPService.swift`

- Loads arena opponents
- Loads revenge entries
- Loads PvP match history
- Surfaces retry/error feedback for opponent loading

### `Hexbound/Hexbound/Models/RevengeEntry.swift`

- Represents a single revenge candidate
- Powers revenge list rendering and relative-time display

## Dependencies

- `APIClient`
- `APIError`
- `Opponent`
- `RevengeEntry`
- `MatchHistory`
- `AppState`

## Inbound usage

- `Hexbound/Hexbound/Views/Arena/ArenaViewModel.swift`
- `Hexbound/Hexbound/Views/Hub/HubView.swift` opponent prefetch

## Fixes made

1. Replaced raw PvP list loading with typed response envelopes:
   - `PvPOpponentsResponse`
   - `PvPRevengeListResponse`
   - `PvPHistoryResponse`
2. Removed `getRaw(...)` and `JSONSerialization` from `PvPService`.
3. Preserved the existing retry-once behavior for opponent loading, including toast-based retry UX.
4. Preserved decode-failure behavior as a quiet empty-state return with `#if DEBUG` logging instead of turning schema drift into noisy player-facing toasts.
5. Removed legacy snake_case `CodingKeys` from `RevengeEntry` so it now decodes cleanly through the shared `APIClient` `convertFromSnakeCase` strategy.

## Problems found

### 1. Raw JSON bridge on a stable PvP envelope

- **Problem:** arena list loading was still manually extracting `opponents`, `revenge_list`, and `history` arrays from raw dictionaries.
- **Risk:** contract drift stayed hidden behind manual JSON bridging and duplicated decode logic.
- **Fix:** moved all three list surfaces to typed `APIClient.get(...)` responses.

### 2. `RevengeEntry` was pinned to a decoder-local snake_case dialect

- **Problem:** `RevengeEntry` used explicit snake_case coding keys even though the app’s shared decoder already normalizes snake_case automatically.
- **Risk:** the model could only decode correctly through ad hoc local decoders, which kept `PvPService` from joining the shared typed path.
- **Fix:** removed the stale coding-key layer and let the shared decoder own the normalization.

### 3. Decode-failure handling was duplicated inside the service

- **Problem:** the old code manually built JSON data and locally instantiated decoders for the same list endpoints.
- **Risk:** every future field change would need to be reconciled in multiple places, not just in the DTOs.
- **Fix:** centralized decoding back through `APIClient`, keeping only small error-policy differences inside `PvPService`.

## What was intentionally left alone

- This block did not widen into PvP match-start, revenge execution, or opponent-profile flows.
- `Opponent` and `MatchHistory` stayed structurally unchanged because their current typed shapes already align with the live backend payloads.

## Keep / fix / delete

- **Keep:** typed list envelopes for stable PvP endpoints
- **Keep:** one-retry cold-start mitigation for opponent loading
- **Fix next:** move the remaining PvP mutation/profile surfaces onto the same typed-contract standard if any raw path still survives nearby
- **Delete later:** no delete candidate in this block; this was a service cleanup, not a dead-surface removal

## Status

**Fixed**
