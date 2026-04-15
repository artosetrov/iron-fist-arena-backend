---
title: Audit Block 015 — Claim Progression for Achievements, Quests, and Battle Pass
category: audit
tags: [audit, backend, ios, progression, achievements, quests, battle-pass]
sources:
  - backend/src/lib/game/achievement-claims.ts
  - backend/src/app/api/achievements/claim/route.ts
  - backend/src/app/api/achievements/[key]/claim/route.ts
  - backend/src/app/api/achievements/route.ts
  - backend/src/app/api/quests/daily/route.ts
  - backend/src/app/api/quests/daily/bonus/route.ts
  - backend/src/app/api/battle-pass/claim/[level]/route.ts
  - Hexbound/Hexbound/App/AppState.swift
  - Hexbound/Hexbound/Models/Achievement.swift
  - Hexbound/Hexbound/Models/BattlePassData.swift
  - Hexbound/Hexbound/Services/AchievementService.swift
  - Hexbound/Hexbound/Services/BattlePassService.swift
  - Hexbound/Hexbound/Services/QuestService.swift
  - Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift
  - Hexbound/Hexbound/Views/BattlePass/BattlePassViewModel.swift
  - Hexbound/Hexbound/Views/Components/ActiveQuestBanner.swift
  - Hexbound/Hexbound/Views/Hub/HubBannerCards.swift
  - Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift
  - Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift
  - Hexbound/Hexbound/Views/Quests/DailyQuestsViewModel.swift
  - Hexbound/Hexbound/Views/Shop/ShopViewModel.swift
updated: 2026-04-15
---

# Audit Block 015 — Claim Progression for Achievements, Quests, and Battle Pass

## Scope

This block audits the remaining claim-style progression flows that still hand-rolled XP, level-up, and client reward sync: achievements, daily quests, daily quest bonus, and battle pass claims, plus the iOS view-models and state objects that consume those responses.

- **Files audited in this block:** 21
- **Primary file types:** Next.js route handlers, TypeScript progression helper, Swift models/services/view-models
- **Status:** Claim flows are now transaction-safe, level-up-aware, and client-synchronized; some legacy typing debt and reward-name duplication still remain
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-014-shared-reward-grants-shop-mail-rush-sync]], [[achievements]], [[progression]], [[economy]]

## Summary

- Achievements and daily quests still had an old pattern: write `gold/gems/xp` manually, then call `applyLevelUp()` later or not at all. That made claim state authoritative, but progression side effects were not.
- Daily quest bonus had a real TOCTOU race. It checked `dailyBonusDate` before the transaction, then granted the bonus later. Two concurrent requests could both pass the pre-check and double-claim.
- Battle pass claim was partially safer because XP level-up already happened in-transaction, but reward granting was still duplicated, cache invalidation was missing, and the iOS claim modal only reflected the tapped track even when the backend claimed both free and premium rewards.
- iOS had another subtle but important drift: several flows updated `appState.currentCharacter.level` first and only then opened the level-up modal. That broke building-unlock queuing because the modal no longer knew the real previous level.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Achievement and daily-quest claims granted XP outside the shared reward path. | Players could receive XP but miss atomic level-up, stat points, and cache invalidation. | Moved these claims onto shared reward grants and made battle-pass XP award part of the same transaction where applicable. |
| P1 | Daily quest bonus used a pre-transaction claim check. | Concurrent requests could double-claim the bonus. | Moved bonus eligibility and reward grant into a single locked transaction on the character row. |
| P1 | Battle pass claim duplicated mixed reward logic and never invalidated skill/passive cache after a level-up. | Same reward bugs could reappear in a second code path; cached combat state could lag behind earned levels. | Reused shared reward grants for `gold/gems/xp/item/chest/consumable` and now invalidate combat caches on level-up. |
| P1 | Battle pass iOS claim UI only marked one tapped track as claimed and built the modal from that single reward. | Premium users could receive both tracks from the server but see only one reward locally until a refresh. | Switched iOS claim flow to server-first response handling, mark all returned rewards claimed locally, and build the modal from the full claim payload. |
| P2 | Achievements and daily bonus iOS flows still used false-positive optimistic claim behavior or hardcoded reward values. | UI could celebrate rewards that never landed, and daily bonus always showed `0 XP` despite awarding XP. | Switched to API-first confirmation and consume real server reward values. |
| P2 | Level-up modal callers often fired after mutating local character level. | Unlock ceremonies could miss thresholds because `fromLevel` was already overwritten. | Added `previousLevel` support to `AppState.triggerLevelUpModal()` and passed it through the touched reward flows. |

## Cross-File Safe Fixes Applied

- Added `backend/src/lib/game/achievement-claims.ts` so both achievement claim routes now share the same locking, reward grant, and battle-pass XP behavior instead of duplicating it.
- `backend/src/app/api/achievements/claim/route.ts` and `backend/src/app/api/achievements/[key]/claim/route.ts` now use the shared helper, return explicit `reward_gold/reward_gems/reward_xp`, and invalidate combat caches on level-up.
- `backend/src/app/api/achievements/route.ts` now exposes `xp` rewards in the iOS-facing reward payload instead of silently dropping that type.
- `backend/src/app/api/quests/daily/route.ts` now grants quest rewards through `grantRewardEntries()`, awards battle-pass XP inside the transaction, and invalidates combat caches on level-up.
- `backend/src/app/api/quests/daily/bonus/route.ts` now serializes bonus claim with `FOR UPDATE`, uses shared reward grants, and no longer has a double-claim race.
- `backend/src/app/api/battle-pass/claim/[level]/route.ts` now routes item/chest/consumable/currency rewards through the shared grant helper, keeps stamina/cosmetics local, returns richer reward metadata for the client, and invalidates caches after level-up.
- iOS achievement/quest/battle-pass services now await character refresh inline, return structured claim payloads, and stop treating successful HTTP completion as enough on its own.
- `AppState.triggerLevelUpModal()` now accepts `previousLevel`, and the touched reward consumers pass that value before mutating the local character model.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/lib/game/achievement-claims.ts` | Shared achievement claim helper | Centralizes achievement reward claim transaction logic. | Used by both achievement claim routes. | Achievement claim must lock row, verify completion, grant reward, mark claimed, and award battle-pass XP atomically. | New helper created to remove duplicated route logic and stop split transaction behavior. | Fixed |
| `backend/src/app/api/achievements/claim/route.ts` | Legacy achievement claim endpoint | Claims achievement reward by body payload. | Depends on auth, rate limit, achievement catalog/helper, cache invalidation. | Must preserve body-based API contract while staying server-authoritative. | Moved to shared claim helper; now returns explicit reward fields and cache invalidation on level-up. | Fixed |
| `backend/src/app/api/achievements/[key]/claim/route.ts` | REST-style achievement claim endpoint | Claims achievement reward by URL key. | Depends on auth, rate limit, shared helper, live config. | Must behave identically to the legacy claim endpoint. | Removed duplicated reward logic and aligned response/side effects with the legacy endpoint. | Fixed |
| `backend/src/app/api/achievements/route.ts` | Achievement list API | Returns achievement definitions + progress in iOS shape. | Depends on auth, Prisma, achievement catalog. | Reward payload must match the actual reward type so the client can render it correctly. | Added `xp` reward mapping; previously future XP achievements would have rendered with empty reward data. | Fixed |
| `backend/src/app/api/quests/daily/route.ts` | Daily quest runtime | Lists/generates quests and claims individual quest rewards. | Depends on auth, Prisma, battle-pass XP, shared reward grants. | Quest claim must be single-claim, atomic, and progression-aware. | Replaced manual gold/gems/xp writes with shared grant flow and moved BP XP into the transaction. Legacy `any` typing still remains in this file. | Fixed |
| `backend/src/app/api/quests/daily/bonus/route.ts` | Daily quest meta-bonus claim | Grants the “all quests claimed” bonus. | Depends on auth, Prisma, shared reward grants, cache invalidation. | Bonus may be claimed once per UTC day only after all quest rewards are claimed. | Closed the double-claim race and unified bonus XP with normal level-up logic. | Fixed |
| `backend/src/app/api/battle-pass/claim/[level]/route.ts` | Battle pass reward claim runtime | Claims all eligible rewards at a target BP level. | Depends on auth, stamina helper, shared reward grants, cosmetics logic. | Claiming a level must collect every eligible reward at that level, not just the tapped one. | Replaced duplicated mixed reward logic, added level-up cache invalidation, and returned richer reward payload for iOS. Reward-name formatting is still duplicated with GET route. | Fixed |
| `Hexbound/Hexbound/App/AppState.swift` | Global iOS app/session state | Owns modals, current character, unlock queues, and navigation state. | Used by nearly every view-model. | Level-up modal must know the pre-level state to queue unlock ceremonies correctly. | Added optional `previousLevel` input and clamped fallback logic so touched flows can preserve unlock sequencing. | Fixed |
| `Hexbound/Hexbound/Models/Achievement.swift` | iOS achievement model | Decodes achievement list payload and reward display data. | Used by achievement service/view-model/UI. | Reward text should reflect all supported reward types. | Added `xp` to reward decoding and text rendering. | Fixed |
| `Hexbound/Hexbound/Models/BattlePassData.swift` | iOS battle pass models | Decodes battle pass overview and now claim payloads too. | Used by `BattlePassService` / `BattlePassViewModel`. | Client claim handling needs structured reward details, not a fire-and-forget void. | Added typed claim response/reward models. | Fixed |
| `Hexbound/Hexbound/Services/AchievementService.swift` | iOS achievement API service | Loads achievements and claims achievement rewards. | Used by `AchievementsViewModel`. | Client should wait for authoritative character refresh before UI treats claim as complete. | Claim now returns structured reward/level-up result and awaits character refresh inline. | Fixed |
| `Hexbound/Hexbound/Services/BattlePassService.swift` | iOS battle pass API service | Loads pass state, buys premium, and claims rewards. | Used by `BattlePassViewModel`. | Claim should surface the full server response because backend may claim multiple rewards at once. | Claim now decodes typed response and awaits character refresh inline. | Fixed |
| `Hexbound/Hexbound/Services/QuestService.swift` | iOS quest API service | Loads quests and claims quest/bonus rewards. | Used by quest screens and hub/banner claimers. | Bonus and quest claim should both return server-confirmed rewards and level-up metadata. | Added structured daily-bonus claim result and made refresh synchronous for caller-facing state. | Fixed |
| `Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift` | iOS achievement state owner | Drives list tabs, claim state, and reward modal. | Depends on `AchievementService`, cache, app state. | UI should not celebrate a claim until server and character state are both updated. | Removed false optimistic commit, now uses real reward values and passes `previousLevel` to level-up modal. | Fixed |
| `Hexbound/Hexbound/Views/BattlePass/BattlePassViewModel.swift` | iOS battle pass state owner | Drives pass screen, claim actions, and premium buy UX. | Depends on `BattlePassService`, cache, app state. | One BP level claim may return multiple rewards across tracks. | Removed single-track optimistic claim, now consumes full claim response, marks all returned rewards claimed, and builds modal from all rewards. | Fixed |
| `Hexbound/Hexbound/Views/Components/ActiveQuestBanner.swift` | iOS contextual quest banner | Lets users claim relevant quests inline from other screens. | Depends on `QuestService` and app state cache. | Inline claims should still honor the same level-up UX as the full quest screen. | Added `previousLevel` capture so banner claims no longer lose unlock context. | Fixed |
| `Hexbound/Hexbound/Views/Hub/HubBannerCards.swift` | iOS hub quest/banner cards | Handles inline quest claim on the hub. | Depends on `QuestService`, app state, cached quests. | Hub claim path should stay behaviorally equivalent to daily quests screen. | Added server-confirmed level-up handling with `previousLevel`. | Fixed |
| `Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift` | iOS inbox state owner | Applies claimed mail rewards and local character sync. | Depends on mail claim response and app state. | Reward flows that mutate local character before modal display must preserve previous level. | Now passes `previousLevel` into the level-up modal path instead of relying on already-mutated app state. | Fixed |
| `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift` | iOS Dungeon Rush state owner | Applies rush rewards to local character state. | Depends on rush response payload and app state. | Same previous-level rule as other reward flows. | Added preserved previous-level handling for rush level-up modal. | Fixed |
| `Hexbound/Hexbound/Views/Quests/DailyQuestsViewModel.swift` | iOS daily quests state owner | Drives quest list, bonus claim, and reward modal. | Depends on `QuestService`, cache, app state. | Bonus and quest claim UX must use real server values, not hardcoded reward guesses. | Bonus no longer hardcodes `xpReward = 0`; quest/bonus claims now trigger level-up with preserved previous level. | Fixed |
| `Hexbound/Hexbound/Views/Shop/ShopViewModel.swift` | iOS shop state owner | Applies shop/contraband reward state locally. | Depends on shop service and app state. | Shared reward sync must also preserve correct unlock sequencing. | Added previous-level capture when opening level-up modal after shop rewards. | Fixed |

## Duplicate / Split Logic Found

- `battle-pass/route.ts` and `battle-pass/claim/[level]/route.ts` both format reward names from raw reward type strings. This should become a shared helper before names drift.
- `quests/daily/route.ts` still carries multiple legacy `any` payload shapes in GET/formatting code. Claim safety is much better now, but the file still deserves a typing pass.
- Swift claim services still do some manual dictionary parsing from `APIClient.shared.postRaw(...)` rather than fully typed endpoint adapters.
- A few level-up modal callers outside this block still do not pass `previousLevel`, so unlock-queue correctness is improved here but not globally finished.

## Files Without Clear Current Role

- None in this block. Every audited file is live production runtime or shared state/UI support.

## Candidates For Refactor

- Extract a shared reward-name formatter for battle pass GET/claim responses.
- Create a typed claim DTO layer in iOS services so reward parsing is not repeated ad hoc.
- Continue the `previousLevel` cleanup through combat and dungeon victory surfaces, not just claim-based reward flows.
- Type `quests/daily/route.ts` end-to-end to remove the remaining `any` hotspots.

## Documentation Missing Or Stale

- No wiki page yet describes claim-response contracts as a system-wide API surface, especially where responses return deltas vs authoritative totals.
- No runtime doc names `achievement-claims.ts` as the canonical achievement claim path.
- The level-up/unlock contract between `AppState` and reward-consuming view-models is implicit in code, not documented as a shared client rule.

## Verification

- Targeted `next lint` over the touched backend files passes with only pre-existing `quests/daily/route.ts` legacy `any` warnings.
- `python3 scripts/check_schema_drift.py --verbose` passes.
- `git diff --check` passes.
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
- A broader backend TypeScript compile still reports unrelated pre-existing issues: duplicated `.next/types` declarations and older passives/contraband typing drift outside this block.
