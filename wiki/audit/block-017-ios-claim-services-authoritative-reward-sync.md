---
title: Audit Block 017 — iOS Claim Services and Authoritative Reward Sync
category: audit
tags: [audit, ios, achievements, quests, reward-contracts, reward-sync]
sources:
  - backend/src/app/api/achievements/claim/route.ts
  - backend/src/app/api/quests/daily/route.ts
  - backend/src/app/api/quests/daily/bonus/route.ts
  - Hexbound/Hexbound/App/AppState.swift
  - Hexbound/Hexbound/Services/AchievementService.swift
  - Hexbound/Hexbound/Services/QuestService.swift
  - Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift
  - Hexbound/Hexbound/Views/Quests/DailyQuestsViewModel.swift
  - Hexbound/Hexbound/Views/Hub/HubBannerCards.swift
  - Hexbound/Hexbound/Views/Components/ActiveQuestBanner.swift
updated: 2026-04-17
---

# Audit Block 017 — iOS Claim Services and Authoritative Reward Sync

## Scope

This block closes the remaining refresh-based iOS claim flows left after [[block-016-backend-daily-login-battle-pass-reward-contracts]]. The backend achievement and quest claim routes were re-audited first to confirm that they already return authoritative `gold/gems/xp/leveled_up/new_level/stat_points_awarded` fields, then the client claim services and all touched quest claim consumers were moved onto that contract.

- **Files audited in this block:** 10
- **Primary file types:** Next.js route handlers, Swift services, Swift view-models/views
- **Status:** Achievement and quest claims now use typed authoritative reward sync instead of refresh-after-claim, and duplicate level-up modal triggers were removed from all touched consumers
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-015-claim-progression-achievements-quests-battle-pass]], [[block-016-backend-daily-login-battle-pass-reward-contracts]], [[progression]], [[achievements]]

## Summary

- `AchievementService` and `QuestService` were the last major reward claim services still using raw dictionary parsing plus a follow-up character refresh pattern. That created unnecessary latency and kept the client dependent on an extra round-trip even though the backend already returned authoritative totals in the claim response.
- The iOS quest reward was claimed from three separate UI surfaces: the full Daily Quests screen, the hub reward widget, and the active quest banner. Once the app started trusting authoritative reward totals, every one of those surfaces had to stop manually firing its own level-up modal path or the player would get duplicate ceremony behavior.
- The backend contract in these routes turned out to be good enough already. The real drift was client-side: weak DTOs, repeated raw parsing, repeated reward sync logic, and comments/documentation that still described the old refresh-based flow.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | `AchievementService.claim()` still used `postRaw` and then refreshed the whole character after claim. | Slower claim UX, weaker typing, and more chances for HUD state to lag or race. | Added typed `AchievementClaimResult` and now return the authoritative claim payload directly. |
| P1 | `QuestService.claimQuest()` and `claimBonus()` still depended on raw parsing plus refresh-after-claim. | Same stale-HUD / extra round-trip pattern remained in the quests surface even after block 016 introduced shared sync. | Added typed quest claim DTOs and removed refresh-after-claim entirely. |
| P1 | Quest claim happened from multiple screens, each with its own progression update path. | Easy to reintroduce duplicate level-up modals or diverging local state updates. | Moved all touched consumers onto `AppState.applyAuthoritativeRewardState(...)` and removed duplicate ceremony triggers. |
| P2 | Comments in reward flows still described the pre-fix refresh-based architecture. | Future maintainers could follow stale guidance and accidentally reintroduce the old pattern. | Updated touched comments to describe authoritative response sync instead of refresh-after-claim. |

## Cross-File Safe Fixes Applied

- `Hexbound/Hexbound/Services/AchievementService.swift` now defines a typed `AchievementClaimResult` and decodes the claim response through `APIClient.post(...)` instead of `postRaw(...)`.
- `Hexbound/Hexbound/Services/QuestService.swift` now exposes typed `QuestClaimResult` and `QuestBonusClaimResult` models, both carrying reward deltas plus authoritative totals.
- `Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift` now applies authoritative `gold/gems/xp/level/stat_points` immediately after a successful claim, then opens the reward modal from the real server reward delta.
- `Hexbound/Hexbound/Views/Quests/DailyQuestsViewModel.swift`, `Hexbound/Hexbound/Views/Hub/HubBannerCards.swift`, and `Hexbound/Hexbound/Views/Components/ActiveQuestBanner.swift` now all route claim results through `AppState.applyAuthoritativeRewardState(...)` instead of maintaining their own level-up path.
- Re-audited `backend/src/app/api/achievements/claim/route.ts`, `backend/src/app/api/quests/daily/route.ts`, and `backend/src/app/api/quests/daily/bonus/route.ts` to confirm the backend contract already matched the client migration and did not require a risky contract rewrite in this block.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/app/api/achievements/claim/route.ts` | Backend claim contract | Claims achievement rewards and returns reward deltas plus authoritative progression totals. | Used by `AchievementService`. Depends on auth, achievement catalog, shared achievement-claim helper, cache invalidation. | Claim must stay server-authoritative and invalidate combat caches on level-up. | Re-audited here; contract already matched the new client DTO needs. | OK |
| `backend/src/app/api/quests/daily/route.ts` | Backend daily quests API | Returns daily quest list and handles quest reward claims. | Used by `QuestService`. Depends on Prisma, battle-pass XP, reward grant helper, cache invalidation. | Claim response must include deltas and authoritative totals; GET still formats quest rows for iOS. | Re-audited after later backend cleanup; quest pool/meta shaping is now explicitly typed and no legacy `any` debt remains in the live route. | OK |
| `backend/src/app/api/quests/daily/bonus/route.ts` | Backend daily bonus claim API | Claims the bonus after all quests are finished and claimed. | Used by `QuestService.claimBonus()`. Depends on Prisma transaction, reward grants, cache invalidation. | Bonus must stay atomic and only claim once per day. | Re-audited here; contract already matched the client migration. | OK |
| `Hexbound/Hexbound/App/AppState.swift` | Shared client progression sync | Owns `currentCharacter` and the shared authoritative reward-state updater introduced in block 016. | Used by achievement, quest, shop, mail, rush, and battle-pass consumers. | Local HUD/progression state should be patched from server truth before celebration UI. | No new code change in this block, but this helper became the single path for touched claim consumers. | OK |
| `Hexbound/Hexbound/Services/AchievementService.swift` | iOS achievement claim service | Loads achievements and claims achievement rewards. | Used by `AchievementsViewModel`. Depends on `APIClient` and `AppState`. | Claim should return typed server truth, not force a full character refresh. | Replaced raw claim parsing + refresh with typed `AchievementClaimResult`. | Fixed |
| `Hexbound/Hexbound/Services/QuestService.swift` | iOS daily quest service | Loads daily quests, claims quest rewards, and claims daily bonus. | Used by `DailyQuestsViewModel`, `HubBannerCards`, `ActiveQuestBanner`. Depends on `APIClient` and `AppState`. | Claim flows should surface authoritative totals immediately and keep claim callers thin. | Added typed quest claim DTOs, removed refresh-after-claim, and cleaned stale comments. | Fixed |
| `Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift` | Achievement reward consumer | Drives achievement tabs, claim state, and reward modal presentation. | Uses `AchievementService`, `GameDataCache`, `AppState`. | Claim UI should update only after server confirmation and keep level-up handling consistent. | Now applies authoritative totals locally and uses server reward deltas for the modal. | Fixed |
| `Hexbound/Hexbound/Views/Quests/DailyQuestsViewModel.swift` | Daily quests screen state owner | Owns quest list, daily bonus state, and claim ceremony for the main quests screen. | Uses `QuestService`, `GameDataCache`, `AppState`. | One confirmed claim should update quest state, HUD state, cache, and reward modal exactly once. | Switched to authoritative reward sync and removed the old manual level-up path. | Fixed |
| `Hexbound/Hexbound/Views/Hub/HubBannerCards.swift` | Hub inline quest claim consumer | Allows claiming a quest reward directly from the hub card widget. | Uses `QuestService` and cached quests from `AppState`. | Inline claim must mutate cached quest state and HUD state without drifting from the main quests screen. | Now uses shared authoritative reward sync instead of a bespoke local progression path. | Fixed |
| `Hexbound/Hexbound/Views/Components/ActiveQuestBanner.swift` | Active quest inline claim consumer | Shows and claims the currently active quest from a compact banner. | Uses `QuestService`, `AppState`, banner-local animation state. | Claim loader/animation must remain responsive while the final progression update stays server-authoritative. | Now uses shared authoritative reward sync and avoids duplicate level-up ceremony logic. | Fixed |

## Duplicate / Split Logic Found

- `AchievementService.loadAchievements()` and `QuestService.loadQuests()` still rely on `getRaw(...)` + JSONSerialization decoding. That is tolerable for now, but these read paths are still weaker than the newer typed claim DTOs.
- Reward ceremony construction is still duplicated across multiple view-models and views via repeated `ClaimRewardConfig` assembly.
- The original quest-route typing concern is now resolved: `backend/src/app/api/quests/daily/route.ts` no longer carries the legacy `any` shaping that was present earlier in the audit sequence.

## Files Without Clear Current Role

- None in this block. Every audited file remains part of active runtime behavior.

## Candidates For Refactor

- Move achievement and quest list-loading paths onto fully typed GET DTOs instead of `getRaw(...)`.
- Extract a shared iOS reward-ceremony builder so `ClaimRewardConfig` stops being rebuilt ad hoc in each screen.
- Document one explicit project rule for reward responses: which endpoints return authoritative totals, which still return deltas, and which need normalization next.

## Documentation Missing Or Stale

- There is still no dedicated wiki page that defines the app-wide reward response contract conventions for iOS and backend.
- Earlier docs/comments around quest claims still assumed “refresh character after claim” until this block; the touched code is now updated, but the broader architecture is still not documented in one place.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
- `git diff --check` passes after the client/service/comment cleanup.
- Wiki link check passes after adding this block page.
