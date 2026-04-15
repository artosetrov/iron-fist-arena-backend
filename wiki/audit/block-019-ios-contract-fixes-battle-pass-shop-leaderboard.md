---
title: Audit Block 019 — iOS Contract Fixes for Battle Pass, Shop, and Leaderboard
category: audit
tags: [audit, ios, dto, api-contracts, battle-pass, shop, leaderboard, rewards]
sources:
  - backend/src/app/api/battle-pass/route.ts
  - backend/src/app/api/battle-pass/buy-premium/route.ts
  - backend/src/app/api/shop/items/route.ts
  - backend/src/app/api/leaderboard/route.ts
  - Hexbound/Hexbound/Models/BattlePassData.swift
  - Hexbound/Hexbound/Models/ContrabandState.swift
  - Hexbound/Hexbound/Models/MailMessage.swift
  - Hexbound/Hexbound/Models/Quest.swift
  - Hexbound/Hexbound/Models/ShopItem.swift
  - Hexbound/Hexbound/Models/ShopOffer.swift
  - Hexbound/Hexbound/Services/BattlePassService.swift
  - Hexbound/Hexbound/Services/GameInitService.swift
  - Hexbound/Hexbound/Services/LeaderboardService.swift
  - Hexbound/Hexbound/Services/ShopService.swift
updated: 2026-04-15
---

# Audit Block 019 — iOS Contract Fixes for Battle Pass, Shop, and Leaderboard

## Scope

This block continued the typed-loader pass after [[block-018-ios-typed-achievements-quests-loaders]], but it uncovered a more important systemic issue first: several iOS DTOs still defined explicit `snake_case` `CodingKeys` even though `APIClient` decodes with `.convertFromSnakeCase`. That is the exact double-conversion bug documented in [[bug-patterns]].

Instead of only “cleaning up loaders,” this block first closed that contract risk on live reward flows, then moved the stable battle pass, shop, and leaderboard read paths to typed `APIClient.get(...)`.

- **Files audited in this block:** 14
- **Primary file types:** Next.js route handlers, Swift models, Swift services
- **Status:** Stable battle pass/shop/leaderboard loaders are now typed, and the active reward DTOs for contraband, mail, and shop offers no longer risk silent decode drift from `CodingKeys` double conversion
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-018-ios-typed-achievements-quests-loaders]], [[bug-patterns]], [[progression]]

## Summary

- `BattlePassService`, `ShopService`, and `LeaderboardService` still had classic raw-loader patterns: fetch JSON as `[String: Any]`, manually peel arrays, then re-serialize back into JSON to decode the same DTOs. That is noisy, less type-safe, and easy to drift.
- While converting those services, a deeper pattern surfaced: `Quest`, `BattlePassData`, `ShopItem`, and several reward response DTOs were mixed across two decoding models at once. Some expected `APIClient` snake_case conversion, others still hardcoded `snake_case` `CodingKeys`.
- The most dangerous cases were not list models but live reward responses: `ContrabandClaimResponse`, `MailClaimResponse`, and `OfferPurchaseResponse`. Those are used on claim/purchase actions where `leveled_up`, `new_level`, and `stat_points_awarded` directly drive local progression sync. If those fields stop decoding, the user can buy/claim successfully but the client can quietly skip level-up UX or stat-point sync.
- `GameInitService` also needed a small compatibility fix after the DTO cleanup: once `Quest` became plain camelCase, the local ad hoc decoder in `/game/init` needed to explicitly enable `.convertFromSnakeCase` too.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Live reward DTOs still used explicit `snake_case` `CodingKeys` while decoding through `APIClient`. | Silent loss of `leveledUp/newLevel/statPointsAwarded` on real contraband, mail, and special-offer reward flows. | Removed conflicting `CodingKeys` from `ContrabandClaimResponse`, `MailClaimResponse`, and `OfferPurchaseResponse`. |
| P1 | Battle pass DTOs mixed typed API decoding with explicit snake_case coding keys. | Claims and list payloads could decode inconsistently depending on call path, making recent typed-service work brittle. | Removed explicit snake_case `CodingKeys` from `BattlePassData`, `BPReward`, and `BattlePassClaimResponse`. |
| P2 | `BattlePassService.loadBattlePass()` still used raw parsing. | More glue code, weaker compile-time checks, and easier contract drift. | Switched to typed `APIClient.get(...)` and retained track-tag injection in one place. |
| P2 | `ShopService.getItems()` still used raw parsing and compatibility branching inside service logic. | Repeated ad hoc parsing around a stable backend contract. | Added typed `ShopItemsResponse` and kept `items ?? shopItems` compatibility explicit in DTO space. |
| P2 | `LeaderboardService.loadLeaderboard()` still used raw parsing and per-array decode plumbing. | Harder maintenance and weaker validation of the route contract. | Added typed `LeaderboardResponse` and preserved only the intentional rank fallback for `rank == 0`. |
| P2 | `GameInitService` had a local quest decoder that no longer matched the cleaned DTO contract. | `game/init` could regress after removing explicit quest coding keys. | Enabled `.convertFromSnakeCase` on the local quest decoder. |

## Cross-File Safe Fixes Applied

- `Hexbound/Hexbound/Services/BattlePassService.swift` now uses typed GET decoding for the main battle pass payload and typed POST decoding for premium purchase without the old refresh-after-buy path.
- `Hexbound/Hexbound/Services/ShopService.swift` now uses a typed response wrapper for shop item loading.
- `Hexbound/Hexbound/Services/LeaderboardService.swift` now uses a typed response wrapper for leaderboard loading.
- `Hexbound/Hexbound/Models/Quest.swift`, `BattlePassData.swift`, and `ShopItem.swift` were simplified back to plain camelCase DTOs so they align with `APIClient` decoder rules.
- `Hexbound/Hexbound/Models/ContrabandState.swift`, `MailMessage.swift`, and `ShopOffer.swift` were corrected on live reward-response DTOs so progression fields decode reliably.
- `Hexbound/Hexbound/Services/GameInitService.swift` was updated so its local decoder still matches the new DTO contract assumptions.
- Re-audited `backend/src/app/api/battle-pass/route.ts`, `battle-pass/buy-premium/route.ts`, `shop/items/route.ts`, and `leaderboard/route.ts` to confirm their current response shapes are stable enough for typed client decoding.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/app/api/battle-pass/route.ts` | Backend battle pass GET API | Returns season status, current BP progress, and free/premium reward tracks. | Used by `BattlePassService`. Depends on auth, Prisma, BP balance helpers, reward label formatter. | Keeps snake_case response keys stable for iOS and computes claimability from BP level plus premium ownership. | Re-audited here; no code change required for the typed client loader. | OK |
| `backend/src/app/api/battle-pass/buy-premium/route.ts` | Backend premium purchase API | Sells premium battle pass and returns updated pass summary plus gems remainder. | Used by `BattlePassService.buyPremium()`. Depends on auth, Prisma transaction, live gem-cost config, rate limit. | Must stay transactional so gem spend and premium flag are updated atomically. | Re-audited here; current contract is stable enough for typed decoding. | OK |
| `backend/src/app/api/shop/items/route.ts` | Backend shop catalog API | Returns shop equipment and consumables filtered by character ownership/class/level. | Used by `ShopService`. Depends on auth, Prisma, config helpers, gem pack constants. | Emits snake_case item DTOs and currently returns `items` plus `character_level`. | Re-audited here for typed client decoding; later follow-up in [[block-026-backend-shop-consumable-pricing-parity]] fixed direct-sale consumable filtering and listing/transaction fallback-price parity. | Fixed |
| `backend/src/app/api/leaderboard/route.ts` | Backend leaderboard API | Returns rating, level, and gold leaderboards with server-side tier metadata. | Used by `LeaderboardService`. Depends on Prisma, cache, rate limit, tier helper. | Response shape is three typed arrays keyed by board category. | Re-audited here; typed client wrapper now consumes this contract directly. | OK |
| `Hexbound/Hexbound/Models/Quest.swift` | iOS quest DTO | Typed quest model shared by quest screens, hub banners, and init prefetch. | Used by `QuestService`, `GameInitService`, cache/UI consumers. | DTO should stay plain camelCase and rely on decoder strategy for snake_case payloads. | Removed explicit snake_case coding-key dependence and documented the contract rule inline. | Fixed |
| `Hexbound/Hexbound/Models/BattlePassData.swift` | iOS battle pass DTOs | Typed models for battle pass list and claim responses. | Used by `BattlePassService` and battle pass UI/view models. | Must decode stable BP progress and reward payloads from snake_case backend keys through `APIClient`. | Removed explicit snake_case `CodingKeys` that conflicted with typed API decoding. | Fixed |
| `Hexbound/Hexbound/Models/ShopItem.swift` | iOS shop item DTO | Typed item/catalog model for shop screens. | Used by `ShopService`, shop UI, and item-detail consumers. | DTO should map stable snake_case backend keys through shared decoder behavior, not local overrides. | Removed explicit snake_case coding-key dependence and documented the contract rule inline. | Fixed |
| `Hexbound/Hexbound/Models/ContrabandState.swift` | iOS contraband DTO + UI state | Models scavenger/contraband state plus claim response for reward sync. | Used by `ShopViewModel`. | Claim response fields drive authoritative gold/gems/xp/level sync after reward claim. | Removed conflicting snake_case `CodingKeys` from `ContrabandClaimResponse`. | Fixed |
| `Hexbound/Hexbound/Models/MailMessage.swift` | iOS mail/inbox DTO | Models inbox messages, attachments, and mail reward claims. | Used by `InboxViewModel`, inbox UI, and unified feed consumers. | Mail claim response must preserve reward and progression fields for authoritative local sync. | Removed conflicting snake_case `CodingKeys` from `MailClaimResponse`. | Fixed |
| `Hexbound/Hexbound/Models/ShopOffer.swift` | iOS special offers DTO | Models time-limited offers and offer-purchase response data. | Used by `ShopViewModel` and shop offer UI. | Offer purchase response drives currency/progression sync after special-offer checkout. | Removed conflicting snake_case `CodingKeys` from `OfferPurchaseResponse`. | Fixed |
| `Hexbound/Hexbound/Services/GameInitService.swift` | iOS init/prefetch service | Loads initial character, inventory, and quest data during game bootstrap. | Used by app startup and hub preload flows. Depends on local JSON flattening for mixed payloads. | Local decoders must mirror the global API contract assumptions used elsewhere. | Added `.convertFromSnakeCase` to the local quest decoder so init stays compatible after DTO cleanup. | Fixed |
| `Hexbound/Hexbound/Services/BattlePassService.swift` | iOS battle pass service | Loads pass state, claims rewards, and buys premium. | Used by `BattlePassViewModel`. Depends on `APIClient` and `AppState`. | Read/write paths should use typed contracts and keep premium-buy sync authoritative. | Replaced raw load path with typed GET, added typed buy-premium DTO, and removed stale refresh-after-buy behavior. | Fixed |
| `Hexbound/Hexbound/Services/ShopService.swift` | iOS shop service | Loads shop items and performs multiple shop purchase flows. | Used by shop screens and item purchase UI. Depends on `APIClient`, `AppState`, quest refresh. | Stable catalog reads should use typed contracts even if some purchase actions are still raw. | Added `ShopItemsResponse` and replaced raw item loader with typed GET decoding. | Fixed |
| `Hexbound/Hexbound/Services/LeaderboardService.swift` | iOS leaderboard service | Loads leaderboard tabs and player search results. | Used by leaderboard screens. Depends on `APIClient`. | Response is a fixed three-array contract; only fallback logic should be rank normalization. | Added `LeaderboardResponse` and replaced raw parsing with typed GET decoding. | Fixed |

## Duplicate / Split Logic Found

- Raw JSON parsing is still widespread in other iOS services, especially where backend payloads are nested or polymorphic (`InventoryService`, parts of `CharacterService`, some PvP/dungeon callers).
- The repo now has two decoding styles in active use: shared `APIClient` decoding and local/manual `JSONDecoder` flows. That is fine only when the local decoder explicitly mirrors the same key strategy, otherwise the project drifts back into the exact bug pattern this block fixed.

## Files Without Clear Current Role

- None in this block. Every touched file has a live runtime role.

## Candidates For Refactor

- `InventoryService.swift` is the next obvious candidate for typed-contract cleanup, but it should be handled separately because it also normalizes nested equipment payloads and consumables.
- A small “client contract conventions” wiki page would help document where typed DTOs are expected, when raw parsing is still allowed, and how `convertFromSnakeCase` interacts with `CodingKeys`.

## Documentation Missing Or Stale

- The project documents the double-conversion bug in [[bug-patterns]], but it still lacks a dedicated source-of-truth page for iOS/backend contract conventions and DTO authoring rules.

## Verification

- `rg -n "leveled_up|new_level|stat_points_awarded" Hexbound/Hexbound/Models -g '*.swift'` no longer reports the active reward DTOs fixed in this block.
- `git diff --check` passes after the DTO and service changes.
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
