---
title: Block 088 — iOS social and challenge action typed contracts
category: audit
tags: [audit, ios, social, contracts]
updated: 2026-04-16
---

# Block 088 — iOS social and challenge action typed contracts

## Scope

- `Hexbound/Hexbound/Services/SocialService.swift`
- `Hexbound/Hexbound/Services/ChallengeService.swift`
- `Hexbound/Hexbound/Models/Social.swift`

## Why this block existed

The read side of social had already moved onto typed DTOs, but the live action layer still mixed typed models with `postRaw`, loose request dictionaries, and one-off response parsing. That left the most failure-prone part of the social surface on a parallel contract path even though the shared `APIClient` already owned snake_case encoding and decoding.

It also created a subtle maintenance trap: social status and friendship state already had a canonical shared model, but `SocialService` had started to grow a second local response type with the same name.

## What the files do

### `Hexbound/Hexbound/Services/SocialService.swift`

- Loads friendship badge/status state
- Sends friend, accept, decline, remove, block, and unblock mutations
- Maps backend friendship status to button state

### `Hexbound/Hexbound/Services/ChallengeService.swift`

- Loads incoming/outgoing/completed challenge lists
- Sends, accepts, declines, and cancels challenges

### `Hexbound/Hexbound/Models/Social.swift`

- Defines canonical shared social DTOs such as `FriendshipStatusResponse`
- Provides button-state and friends-list model types used across the social UI

## Dependencies

- `APIClient`
- `APIError`
- `APIEndpoints`
- `FriendshipButtonState`
- `FriendsListResponse`
- social/guild screens under `Views/Social`

## Inbound usage

- `Hexbound/Hexbound/Views/Social/GuildHallViewModel.swift`
- `Hexbound/Hexbound/Views/Social/*`

## Fixes made

1. Replaced raw friend-action posts with typed request/response DTOs.
2. Replaced raw challenge decline/cancel posts with typed request/response DTOs.
3. Moved friendship-status lookup off raw body parsing onto typed request/response flow.
4. Reused the shared `FriendshipStatusResponse` model instead of keeping a duplicate local type.
5. Preserved the existing user-facing error behavior for friend-request failures and quiet fallback behavior for status loads.

## Problems found

### 1. Social mutations still used a second raw contract path

- **Problem:** friend actions and challenge decline/cancel still built `[String: Any]` bodies and posted them through `postRaw`.
- **Risk:** action routes could drift from typed read-side contracts and fail at runtime instead of compile time.
- **Fix:** introduced typed request/response DTOs and moved the calls to `APIClient.post(...)`.

### 2. Friendship status had started to fork locally

- **Problem:** `SocialService` had a second `FriendshipStatusResponse` declared locally while `Models/Social.swift` already owned the canonical type.
- **Risk:** duplicate names caused a real compile failure and would have made future social changes harder to reason about.
- **Fix:** removed the local duplicate and reused the shared model.

## What was intentionally left alone

- This block did not widen into the guild hall message or duel presentation surfaces.
- It also did not rewrite already-typed challenge list loading, because that boundary was already clean.

## Keep / fix / delete

- **Keep:** shared `FriendshipStatusResponse` as the single social-status contract
- **Keep:** typed social/challenge action DTOs
- **Fix next:** the next nearby social-side contract tail is in `GuildHallViewModel`, not in these services themselves
- **Delete later:** no delete candidate in this block

## Status

**Fixed**
