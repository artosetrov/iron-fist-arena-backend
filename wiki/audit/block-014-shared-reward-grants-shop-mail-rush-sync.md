---
title: Audit Block 014 — Shared Reward Grants, Shop/Mail Claims, and Rush Reward Sync
category: audit
tags: [audit, backend, ios, rewards, shop, mail, dungeon-rush]
sources:
  - backend/src/lib/game/reward-grants.ts
  - backend/src/app/api/shop/offers/route.ts
  - backend/src/app/api/shop/contraband/route.ts
  - backend/src/app/api/mail/[id]/claim/route.ts
  - backend/src/app/api/dungeon-rush/fight/route.ts
  - backend/src/app/api/dungeon-rush/resolve/route.ts
  - Hexbound/Hexbound/Models/ShopOffer.swift
  - Hexbound/Hexbound/Models/ContrabandState.swift
  - Hexbound/Hexbound/Models/MailMessage.swift
  - Hexbound/Hexbound/Views/Shop/ShopViewModel.swift
  - Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift
  - Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift
updated: 2026-04-15
---

# Audit Block 014 — Shared Reward Grants, Shop/Mail Claims, and Rush Reward Sync

## Scope

This block audits reward-grant runtime that still bypassed the shared progression rules: shop offers, contraband, mail attachment claiming, and Dungeon Rush reward paths, plus the iOS models/view-models that consume those responses.

- **Files audited in this block:** 12
- **Primary file types:** Next.js route handlers, TypeScript reward helper, Swift models/view-models
- **Status:** Reward claims now level up correctly, item rewards no longer disappear silently, and iOS state now stays in sync for shop/mail/rush flows; JSON reward payloads are still only lightly validated at route boundaries
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-013-backend-reward-premium-parity]], [[economy]], [[progression]], [[dungeons]]

## Summary

- The main systemic bug in this block was that several claim/reward routes incremented `currentXp` directly and stopped there. Gold/gems changed, XP changed, but level-up rules, stat-point grants, and cache invalidation were missing or inconsistent.
- `shop/offers` and `mail/[id]/claim` each had a worse correctness bug on top of that: both schemas allowed richer rewards, but runtime silently ignored some of them. Offers documented `item` contents but skipped them. Mail claimed the whole message even if non-currency attachments were never granted.
- Dungeon Rush had split behavior between combat and non-combat rooms. Non-combat resolve had no level-up path at all, and combat used a post-transaction `applyLevelUp()` call, which meant reward persistence and progression were not truly atomic.
- iOS had parallel drift: shop/mail claim responses gained richer reward state over time, but several screens still updated only toast/UI state and not the authoritative local character model.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | `shop/offers`, `mail/[id]/claim`, `shop/contraband`, and `dungeon-rush/resolve` granted XP without running shared level-up logic. | Players could receive XP but miss level-ups, stat points, modal feedback, and cache invalidation. | Introduced shared `grantRewardEntries()` and moved these flows onto it so XP, currency, items, consumables, and level-up all resolve together. |
| P1 | `shop/offers` documented `item` contents but runtime skipped them; `mail/[id]/claim` marked messages claimed even when non-currency attachments were never granted. | Paid offer contents or inbox rewards could vanish permanently. | Shared reward helper now grants equipment items and consumables; mail claim now processes the full attachment list before marking the message claimed. |
| P1 | `dungeon-rush/fight` awarded XP in one transaction and leveled up later in a separate call. | Reward persistence and progression could drift if the follow-up level-up step failed or if client sync landed between the two writes. | Moved rush combat gold/xp into `grantRewardEntries()` inside the locked transaction and now return authoritative `current_xp` plus level-up metadata. |
| P2 | iOS shop/mail/rush flows did not consistently apply returned XP/level/stat-point state to `appState.currentCharacter`. | UI could show stale XP/level after a successful reward claim until the next full refresh. | Extended response models and updated `ShopViewModel`, `InboxViewModel`, and `DungeonRushViewModel` to apply reward state immediately and show level-up modal from authoritative response data. |
| P3 | Reward quantities were only checked for finiteness/non-negativity. | Misconfigured JSON could grant fractional amounts or create partial item loops. | Tightened reward helper validation to require integer quantities. |

## Cross-File Safe Fixes Applied

- Added `backend/src/lib/game/reward-grants.ts` as a shared helper for `gold`, `gems`, `xp`, `item`, and `consumable` grants. It locks the character row, enforces capacity for equipment items, applies level-up, and returns authoritative post-grant state.
- `backend/src/app/api/shop/offers/route.ts` now uses the shared helper, returns level-up metadata, invalidates skill/passive cache on level-up, and no longer silently drops `item` rewards.
- `backend/src/app/api/shop/contraband/route.ts` now uses the same helper for gold/gems/xp/consumable rewards and returns level-up metadata to the client.
- `backend/src/app/api/mail/[id]/claim/route.ts` now supports `item` and `consumable` attachments end-to-end and only marks the mail claimed after reward grant succeeds.
- `backend/src/app/api/dungeon-rush/resolve/route.ts` now grants event/treasure XP through the shared progression path and returns authoritative `current_xp` plus level-up data.
- `backend/src/app/api/dungeon-rush/fight/route.ts` now grants combat-room gold/xp atomically inside the run transaction, returns `current_xp`, and no longer depends on a separate post-transaction level-up step.
- iOS response models for offers, contraband, and mail claims now decode returned level-up state; `ShopViewModel`, `InboxViewModel`, and `DungeonRushViewModel` apply it to the local character model immediately.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/lib/game/reward-grants.ts` | Shared reward runtime helper | Grants mixed reward payloads atomically and returns authoritative post-grant state. | Used by shop, contraband, mail, and rush routes. | XP grants must flow through `applyLevelUp`; equipment rewards must respect inventory capacity. | New helper created; added integer quantity validation, item resolution by `id`/`catalogId`, consumable validation, and capacity checks. | Fixed |
| `backend/src/app/api/shop/offers/route.ts` | Limited-time offer runtime | Lists active offers and purchases a selected offer atomically. | Depends on auth, Prisma, reward helper, combat cache invalidation. | Offer contents JSON is the runtime source of truth for purchase rewards. | Fixed silent `item` reward drop, fixed XP-without-level-up, and now returns level-up metadata. Offer-contents JSON is still trusted more than ideal. | Fixed |
| `backend/src/app/api/shop/contraband/route.ts` | Contraband/scavenger reward runtime | Generates deterministic timed drops and claims them atomically. | Depends on auth, Prisma, reward helper, cooldown rules. | Odd claims are free, even claims cost gold; rewards must match GET preview deterministically. | Fixed XP-without-level-up and unified reward application with other claim routes. | Fixed |
| `backend/src/app/api/mail/[id]/claim/route.ts` | Mail reward claim runtime | Claims attachments from inbox mail and marks the message claimed/read. | Depends on auth, Prisma, rate limit, reward helper. | Never mark mail claimed before rewards are actually granted. | Fixed attachment-type drift: `item` and `consumable` are now processed instead of being silently lost. | Fixed |
| `backend/src/app/api/dungeon-rush/resolve/route.ts` | Rush non-combat-room runtime | Resolves treasure, event, and shop rooms and advances rush state. | Depends on rush helpers, lock helper, premium gold helper, reward helper. | Non-combat room rewards must still use the same XP/level-up rules as combat rewards. | Fixed missing level-up path and added authoritative XP/level metadata to response. | Fixed |
| `backend/src/app/api/dungeon-rush/fight/route.ts` | Rush combat-room runtime | Runs rush combat, persists rewards/HP/run progression, and returns fight outcome. | Depends on rush helpers, combat loader, loot, reward helper, cache invalidation. | Reward persistence and progression should be atomic with the locked run update. | Fixed split transaction/progression behavior by moving gold/xp grant + level-up into the transaction; now returns `current_xp` too. | Fixed |
| `Hexbound/Hexbound/Models/ShopOffer.swift` | iOS shop offer models | Decodes offer list and offer purchase responses. | Used by `ShopService` / `ShopViewModel`. | Response model must match backend reward metadata without breaking snake_case decoding. | Added purchase response level-up fields so shop claims can update local character state. | Fixed |
| `Hexbound/Hexbound/Models/ContrabandState.swift` | iOS contraband models | Decodes contraband widget state and claim responses. | Used by `ShopViewModel` / Contraband widget. | Claim response must surface reward totals and progression fields. | Added claim response level-up fields. | Fixed |
| `Hexbound/Hexbound/Models/MailMessage.swift` | iOS inbox/mail models | Decodes inbox messages and mail-claim responses. | Used by `InboxViewModel` and inbox screens. | Mail claim response must carry enough state to sync the local character after claim. | Added returned gold/gems/xp + level-up fields for reward claim sync. | Fixed |
| `Hexbound/Hexbound/Views/Shop/ShopViewModel.swift` | iOS shop state owner | Drives shop tabs, offers, contraband, purchases, and reward modal state. | Depends on `ShopService`, `InventoryService`, app state, new claim response models. | Successful claims should update authoritative local gold/gems/xp/level before UI feedback. | Added shared reward-state applier for offer and contraband claims. | Fixed |
| `Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift` | iOS inbox state owner | Drives mail/feed state and mail actions. | Depends on `APIClient`, `MessageService`, `MailClaimResponse`, app state. | Optimistic claim UI must reconcile against server reward data, not just mark the message claimed. | Now decodes claim response, updates local character progression, and triggers level-up modal. | Fixed |
| `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift` | iOS Dungeon Rush state owner | Drives rush room progression, combat transitions, event/treasure/shop state, and reward summaries. | Depends on `DungeonService`, app state, rush route responses. | Both fight and resolve responses must keep local gold/xp/level/stat points aligned with backend. | Fixed missing local sync after non-combat resolve and aligned combat-room sync to the new authoritative `current_xp` response. | Fixed |

## Duplicate / Split Logic Found

- Reward payloads still enter the system as loosely-typed JSON blobs in several places (`shopOffer.contents`, `mailMessage.attachments`). Runtime is safer now, but schema-level validation is still weak.
- `ShopViewModel`, `InboxViewModel`, and `DungeonRushViewModel` each still contain their own small flavor of “apply reward state to local character.” That duplication is smaller now, but a shared client-side helper may eventually be worth it.
- Dungeon reward logic is still split between classic dungeons and rush. This block unified the rush paths internally, but a broader “combat reward grant” service still does not exist.

## Files Without Clear Current Role

- None in this block. Every file audited here has a live production role.

## Candidates For Refactor

- Add stricter DTO validation for `shopOffer.contents` and `mailMessage.attachments` before route runtime starts, so malformed JSON becomes an explicit configuration error instead of a late runtime failure.
- Extract a small iOS reward-sync utility that updates `AppState.currentCharacter` from authoritative reward responses, so inbox/shop/rush do not keep reimplementing the same patching logic.
- Consider migrating more combat routes onto `grantRewardEntries()` where they still hand-roll `gold/gems/xp` writes and level-up calls separately.

## Documentation Missing Or Stale

- No current backend doc names `grantRewardEntries()` as the canonical mixed-reward path for claim routes.
- No reward contract page documents which APIs return authoritative totals (`gold`, `gems`, `current_xp`) versus deltas (`rewards.gold`, `rewards.xp`) for iOS consumers.
- Mail attachment JSON shape is still implicit in runtime code rather than documented as a stable payload contract.

## Verification

- Targeted backend ESLint passes for `reward-grants`, `shop/offers`, `shop/contraband`, `mail/[id]/claim`, `dungeon-rush/resolve`, and `dungeon-rush/fight`.
- `python3 scripts/check_schema_drift.py --verbose` passes.
- `git diff --check` passes.
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
