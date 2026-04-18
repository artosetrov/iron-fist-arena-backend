---
title: Audit Block 018 — Typed Achievement and Quest Loaders
category: audit
tags: [audit, ios, achievements, quests, dto, api-contracts]
sources:
  - backend/src/app/api/achievements/route.ts
  - backend/src/app/api/quests/daily/route.ts
  - Hexbound/Hexbound/Models/Achievement.swift
  - Hexbound/Hexbound/Models/Quest.swift
  - Hexbound/Hexbound/Services/AchievementService.swift
  - Hexbound/Hexbound/Services/QuestService.swift
updated: 2026-04-17
---

# Audit Block 018 — Typed Achievement and Quest Loaders

## Scope

This block continues the achievement/quest contract cleanup after [[block-017-ios-claim-services-authoritative-reward-sync]], but focuses on read paths instead of claim paths. The goal here was to remove the remaining `getRaw(...) + JSONSerialization` loaders for achievements and daily quests now that the backend routes are stable enough to support typed DTOs.

- **Files audited in this block:** 6
- **Primary file types:** Next.js route handlers, Swift models, Swift services
- **Status:** Achievement and daily-quest list loading now use typed API decoding, while preserving backward compatibility for the legacy `data` wrapper on achievements
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-017-ios-claim-services-authoritative-reward-sync]], [[achievements]], [[progression]]

## Summary

- The last achievement and quest read paths on iOS still fetched raw dictionaries and manually re-serialized them back into JSON just to decode the same models. That is a classic “weak contract in the middle” smell: extra glue code, fewer compile-time checks, and harder-to-read failure behavior.
- `AchievementService.loadAchievements()` was especially telling: it had a compatibility branch for both `achievements` and `data` payload keys, but all of that compatibility lived in ad hoc raw parsing rather than in an explicit DTO.
- `QuestService.loadQuests()` also lost some semantic clarity in the raw path because the service had a real `QuestServiceError.decoding` case, but the decoding boundary itself was mostly hand-managed instead of explicitly modeled.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P2 | Achievement list loading still used raw dictionaries plus JSON re-encoding before decoding `Achievement`. | More brittle loader logic, harder maintenance, weaker compile-time guarantees. | Added a typed `AchievementListResponse` and switched to `APIClient.get(...)`. |
| P2 | Daily quest loading still used raw dictionary parsing and manual quest-array decoding. | Same brittle path, plus unnecessary parsing steps around a stable response contract. | Added a typed `DailyQuestsResponse` and switched to `APIClient.get(...)`. |
| P2 | `QuestServiceError.decoding` risked becoming vestigial after moving to typed GET. | Future debugging would lose the useful distinction between “bad payload shape” and “network/server problem.” | Explicitly mapped `APIError.decodingError` / `DecodingError` back to `QuestServiceError.decoding`. |
| P3 | Achievement compatibility for legacy `data` wrapper was implicit in raw parsing. | Easy to accidentally delete backward compatibility during future refactors. | Preserved it explicitly in the typed `AchievementListResponse` via `achievements ?? data`. |

## Cross-File Safe Fixes Applied

- `Hexbound/Hexbound/Services/AchievementService.swift` now uses `AchievementListResponse` and `APIClient.get(...)` for the achievements list while preserving compatibility with both `achievements` and `data`.
- `Hexbound/Hexbound/Services/QuestService.swift` now uses `DailyQuestsResponse` and `APIClient.get(...)` for daily quests instead of raw parsing.
- `Hexbound/Hexbound/Services/QuestService.swift` now maps decoding failures back into `QuestServiceError.decoding` so UI callers can still distinguish malformed payloads from transport issues.
- Re-audited `backend/src/app/api/achievements/route.ts` and `backend/src/app/api/quests/daily/route.ts` to confirm their current payloads are stable enough for typed client loaders.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/app/api/achievements/route.ts` | Backend achievements list API | Returns the player achievement catalog/status in iOS-facing form. | Used by `AchievementService`. Depends on auth, Prisma, achievement catalog metadata. | Route must keep reward metadata and `rewardClaimed` shape stable for the client. | Re-audited here; no code change required for the typed client migration. | OK |
| `backend/src/app/api/quests/daily/route.ts` | Backend daily quest list/claim API | Returns the daily quest list and handles claim POST. | Used by `QuestService`. Depends on auth, Prisma, reward grants, battle-pass XP. | GET shape must remain decodable into `Quest` plus bonus-claimed flag. | Re-audited here and again in [[block-156-stale-audit-tail-quests-and-interactive-pvp-sync]]; the GET shape is stable for typed decoding and the old legacy `any` debt is no longer present in the live file. | OK |
| `Hexbound/Hexbound/Models/Achievement.swift` | Achievement DTO/model | Strongly typed client model for achievement list payloads. | Used by achievements screens, cache, hub prefetch, and now typed loader wrappers. | Model must stay compatible with server response keys and reward subtypes. | Re-audited; existing model already supported the typed loader move cleanly. | OK |
| `Hexbound/Hexbound/Models/Quest.swift` | Quest DTO/model | Strongly typed client model for daily quest payloads. | Used by quests screens, hub banner surfaces, cache, and typed list loader. | Custom coding keys must continue matching backend `reward_*` and `reward_claimed` fields. | Re-audited; existing model already fit the typed loader migration. | OK |
| `Hexbound/Hexbound/Services/AchievementService.swift` | iOS achievements service | Loads and claims achievements. | Used by `AchievementsViewModel` and hub prefetch. Depends on `APIClient` and `AppState`. | Loader should stay compatible with legacy wrapper keys without falling back to raw dictionaries. | Added `AchievementListResponse` and switched `loadAchievements()` to typed GET decoding. | Fixed |
| `Hexbound/Hexbound/Services/QuestService.swift` | iOS quests service | Loads daily quests and claims daily quest/bonus rewards. | Used by quests screens and inline quest consumers. Depends on `APIClient` and `AppState`. | Loader should surface typed quest data and preserve semantic error mapping for decode failures. | Added `DailyQuestsResponse`, switched `loadQuests()` to typed GET decoding, and restored `decoding` error semantics. | Fixed |

## Duplicate / Split Logic Found

- Other iOS services still rely on `getRaw(...)` and `postRaw(...)` broadly across the app. This block intentionally kept scope tight to achievements/quests because those contracts were already stabilized by the previous reward-sync work.
- The backend achievements route still hardcodes large display metadata inside the route file. It works, but it remains a maintainability hotspot if achievement copy changes frequently.

## Files Without Clear Current Role

- None in this block.

## Candidates For Refactor

- Continue the typed-loader pass into other stable read surfaces such as battle pass, shop, inventory, leaderboard, and referral where raw JSON is still common.
- Consider moving achievement display metadata out of `backend/src/app/api/achievements/route.ts` into a shared catalog/helper if copy churn continues.

## Documentation Missing Or Stale

- The project still has no central wiki page that defines which backend endpoints are considered typed-contract-stable for iOS and which are still intentionally raw.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
- `git diff --check` passes after the loader changes.
