---
title: Audit Block 016 — Daily Login, Battle Pass Reward Contracts, and Client Reward Sync
category: audit
tags: [audit, backend, ios, reward-contracts, daily-login, battle-pass]
sources:
  - backend/src/lib/game/reward-display.ts
  - backend/src/app/api/daily-login/claim/route.ts
  - backend/src/app/api/battle-pass/route.ts
  - backend/src/app/api/battle-pass/claim/[level]/route.ts
  - Hexbound/Hexbound/App/AppState.swift
  - Hexbound/Hexbound/Models/DailyLoginData.swift
  - Hexbound/Hexbound/Services/DailyLoginService.swift
  - Hexbound/Hexbound/Services/BattlePassService.swift
  - Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupViewModel.swift
  - Hexbound/Hexbound/Views/BattlePass/BattlePassViewModel.swift
  - Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift
  - Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift
  - Hexbound/Hexbound/Views/Shop/ShopViewModel.swift
updated: 2026-04-15
---

# Audit Block 016 — Daily Login, Battle Pass Reward Contracts, and Client Reward Sync

## Scope

This block audits the reward contract boundary between backend and iOS for daily login and battle pass, then follows that contract into the client sync layer that updates `AppState.currentCharacter`.

- **Files audited in this block:** 13
- **Primary file types:** Next.js route handlers/helpers, Swift models/services/view-models
- **Status:** Server/client reward contracts are tighter, daily login claim UI is now server-driven, and several duplicated client reward-sync paths were consolidated
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-015-claim-progression-achievements-quests-battle-pass]], [[economy]], [[progression]]

## Summary

- `daily-login/claim` already knew the authoritative reward label/icon via live config, but it threw that information away before returning JSON. iOS rebuilt the reward modal from local reward-table labels, which meant the claim ceremony could drift from the actual server grant.
- The same daily login path also hid the premium daily gems from the modal, because the client only parsed the base reward label and never consumed the premium bonus field semantically.
- Battle pass GET and claim routes each carried their own reward-type label formatter. That is small duplication, but it is exactly the kind that silently drifts once one route learns a new reward type before the other.
- Client reward/progression sync was still repeated in several places (`shop`, `inbox`, `dungeon rush`, `battle pass`, and now daily login). That made level-up handling correct in some screens and merely “close enough” in others.
- `BattlePassService.claimReward()` performed an extra character refresh even though the claim response already contained authoritative `gold/gems/xp/new_level/stat_points_awarded`. That added latency without adding new truth.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Daily login claim response dropped server-authored reward display metadata and partial status. | Claim modal could show the wrong thing, especially for consumables and premium bonus gems. | Daily login claim now returns `displayName`, `displayIcon`, full post-claim status fields, and authoritative currency totals. |
| P1 | iOS daily login flow guessed the reward modal from local labels instead of the claim response. | UI could diverge from server truth and never show premium bonus gems as part of the claim ceremony. | Added typed daily-login claim DTOs and now build the modal from the server-confirmed payload. |
| P1 | Battle pass GET and claim routes duplicated reward-name formatting. | New reward types could drift between overview and claim responses. | Extracted a shared backend reward-display helper and routed both endpoints through it. |
| P1 | Client reward/progression sync still existed as repeated ad hoc code. | Gold/xp/level-up behavior could fork subtly across features. | Added `AppState.applyAuthoritativeRewardState()` and moved touched claim/reward consumers onto the shared path. |
| P2 | Battle pass claim waited on a full character refresh despite already returning authoritative totals. | Unnecessary latency after claim and more room for UI race conditions. | `BattlePassService.claimReward()` now returns the typed claim response directly; the view-model applies server totals locally and still refreshes pass data separately. |
| P2 | Inventory-affecting reward claims did not consistently invalidate cached inventory. | Players could claim consumables/items and still see stale inventory-derived UI until a later refresh. | Touched flows now invalidate inventory cache when they receive item/consumable rewards. |

## Cross-File Safe Fixes Applied

- Added `backend/src/lib/game/reward-display.ts` as the shared reward-type label formatter for battle pass overview and claim responses.
- `backend/src/app/api/daily-login/claim/route.ts` now returns the full reward display contract (`displayName`, `displayIcon`), authoritative `gold/gems`, and post-claim `currentDay/streak/totalClaims/lastClaimDate/canClaim`.
- `Hexbound/Hexbound/Models/DailyLoginData.swift` now includes typed daily-login claim DTOs instead of treating claim as an untyped fire-and-forget action.
- `Hexbound/Hexbound/Services/DailyLoginService.swift` now decodes the typed claim response, applies authoritative `gold/gems` locally, and invalidates cached inventory when the reward is a consumable.
- `Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupViewModel.swift` no longer parses reward labels from the local day table; it builds `ClaimRewardConfig` from the server-confirmed reward and premium bonus.
- `Hexbound/Hexbound/App/AppState.swift` gained `applyAuthoritativeRewardState()`, which centralizes local `gold/gems/xp/level/statPoints` sync plus level-up ceremony triggering.
- `Hexbound/Hexbound/Views/BattlePass/BattlePassViewModel.swift`, `Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift`, `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift`, and `Hexbound/Hexbound/Views/Shop/ShopViewModel.swift` now use that shared helper instead of hand-rolling the same progression patch repeatedly.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/lib/game/reward-display.ts` | Shared reward label helper | Canonical mapping from reward type key to user-facing label. | Used by battle pass GET and claim routes. | Label mapping must stay consistent across overview and claim payloads. | New helper created to remove duplicated reward-name formatting. | Fixed |
| `backend/src/app/api/daily-login/claim/route.ts` | Daily login claim runtime | Grants daily login reward and premium daily gems in one transaction. | Depends on auth, Prisma, daily-login config helper, premium helper. | Claim must stay atomic and return the actual reward the server granted. | Response now includes reward display metadata, post-claim status, and authoritative `gold/gems`. | Fixed |
| `backend/src/app/api/battle-pass/route.ts` | Battle pass overview API | Returns current pass state and reward rows in iOS-facing shape. | Depends on auth, Prisma, BP XP curve, tutorial progress side effect. | Reward labels should match claim responses exactly. | Switched to shared reward-display helper. | Fixed |
| `backend/src/app/api/battle-pass/claim/[level]/route.ts` | Battle pass claim API | Claims all eligible rewards at a BP level. | Depends on auth, reward grants, cosmetics handling, cache invalidation. | Claim payload must use the same reward labels as GET. | Switched to shared reward-display helper so GET/claim cannot drift. | Fixed |
| `Hexbound/Hexbound/App/AppState.swift` | Global client reward/progression sync | Owns current character cache and modal orchestration. | Used by reward-consuming services and view-models across the app. | Server-authoritative totals should be applied in one place; level-up modal still needs the previous level. | Added `applyAuthoritativeRewardState()` to centralize local sync and ceremony triggering. | Fixed |
| `Hexbound/Hexbound/Models/DailyLoginData.swift` | Daily login DTOs | Decodes daily-login status and claim responses. | Used by daily-login service/view-model. | Claim contract should be typed, not reconstructed from raw dictionaries or labels. | Added `DailyLoginClaimReward` and `DailyLoginClaimResponse` with a bridge back to `DailyLoginData`. | Fixed |
| `Hexbound/Hexbound/Services/DailyLoginService.swift` | Daily login API service | Loads daily-login status and claims daily rewards. | Used by `DailyLoginPopupViewModel`. | Claim path should consume server truth directly and update HUD state immediately. | Replaced raw fire-and-forget POST + full character refresh with typed response handling and local authoritative sync. | Fixed |
| `Hexbound/Hexbound/Services/BattlePassService.swift` | Battle pass API service | Loads battle pass data, buys premium, and claims rewards. | Used by `BattlePassViewModel`. | Claim should return server totals immediately; premium buy can still refresh character separately. | Claim no longer waits on a redundant character refresh before returning. | Fixed |
| `Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupViewModel.swift` | Daily login state owner | Drives claim animation, post-claim state, and reward modal. | Depends on `DailyLoginService`, `GameDataCache`, `AppState`. | Confirmation modal should reflect the actual reward granted for the claimed day, including premium gems. | Removed local label parsing and now build the modal from server-confirmed reward DTOs. | Fixed |
| `Hexbound/Hexbound/Views/BattlePass/BattlePassViewModel.swift` | Battle pass state owner | Applies claim results to pass UI and reward modal. | Depends on typed battle-pass claim response and app state. | One claim can update currencies/xp/items and multiple tracks simultaneously. | Now applies authoritative reward totals locally and invalidates inventory cache for item/consumable claims. | Fixed |
| `Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift` | Mail reward consumer | Applies claimed mail rewards to local state. | Depends on mail claim response and `AppState`. | Mail claims should use the same authoritative sync path as other claim flows. | Switched to shared app-state reward sync helper and now invalidates inventory cache for item/consumable mail attachments. | Fixed |
| `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift` | Rush reward consumer | Applies room/fight rewards to local character state. | Depends on rush response payload and `AppState`. | Delta-shaped rush rewards still need to end in a consistent local level-up path. | Now resolves gold/xp locally, then funnels progression updates through shared app-state sync. | Fixed |
| `Hexbound/Hexbound/Views/Shop/ShopViewModel.swift` | Shop reward consumer | Applies contraband/offer claim rewards to local character state. | Depends on shop responses and `AppState`. | Shop reward state should not maintain its own bespoke level-up patcher. | Reused shared app-state reward sync helper instead of duplicating progression mutation logic. | Fixed |

## Duplicate / Split Logic Found

- `AchievementService` and `QuestService` still await full character refresh after claim instead of consuming typed authoritative totals directly. They are safer than before, but they have not yet moved onto the new shared client sync path.
- `ClaimRewardConfig` construction still lives in several feature-specific view-models (`battle pass`, `daily login`, `quests`, `achievements`). The reward payloads are more accurate now, but the ceremony-building layer is still duplicated.
- `Dungeon Rush` still receives a hybrid reward shape (authoritative `current_xp` plus delta-style `rewards.gold/xp` fallback). That contract is now handled more safely on the client, but it is not fully normalized yet.

## Files Without Clear Current Role

- None in this block. Every audited file remains live runtime code.

## Candidates For Refactor

- Move remaining claim services (`achievements`, `quests`, and other reward routes) onto typed authoritative client sync instead of full refresh-after-claim.
- Define a shared iOS reward-ceremony builder so `ClaimRewardConfig` does not keep re-encoding reward type rules in each screen.
- Normalize reward contracts where some endpoints still return deltas while others return authoritative totals.

## Documentation Missing Or Stale

- There is still no dedicated wiki page for “reward response contract conventions” that explains when endpoints return deltas versus authoritative totals.
- The new client rule “patch `AppState.currentCharacter` from authoritative reward responses before opening celebration UI” is now real runtime behavior, but it is only documented implicitly inside audit pages.

## Verification

- Targeted backend `next lint` passes with no warnings or errors for the touched files.
- `python3 scripts/check_schema_drift.py --verbose` passes.
- `git diff --check` passes.
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
