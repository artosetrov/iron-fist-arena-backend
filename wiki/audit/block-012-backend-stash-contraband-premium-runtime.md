---
title: Audit Block 012 — Backend Stash, Contraband, and Premium Runtime
category: audit
tags: [audit, backend, stash, contraband, premium, rewards]
sources:
  - backend/src/app/api/stash/
  - backend/src/app/api/shop/contraband/
  - backend/src/app/api/daily-login/
  - backend/src/lib/game/premium.ts
updated: 2026-04-15
---

# Audit Block 012 — Backend Stash, Contraband, and Premium Runtime

## Scope

This block covers the backend runtime that sits on top of the stash, contraband-claim, and premium-subscription migrations: stash read/move routes, contraband claim logic, premium entitlement helpers, and daily-login premium gem claims.

- **Files audited in this block:** 6
- **Primary file types:** Next.js route handlers, TypeScript gameplay helpers
- **Status:** Core flows are straightforward, but stash operations had race windows and premium subscription adoption is still incomplete across reward routes
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-010-prisma-migrations-hotfixes-stash-interactive-premium]], [[economy]], [[stamina]]

## Summary

- The stash routes are intentionally simple, but they originally enforced capacity outside the move transaction. That creates a classic race where two concurrent deposit/withdraw requests can both pass the capacity check and overfill the stash or character inventory.
- `premium.ts` already knows about both legacy `premiumUntil` and the new `premiumSubscription.expiresAt` path, but `daily-login/claim` was still checking only `premiumUntil`. In practice, Premium Pass subscribers could miss their daily premium gems.
- `shop/contraband` is mostly coherent and does a better job than the stash routes on concurrency by locking the character row and using a serializable transaction. The main remaining concern is broader reward-path consistency: it increments XP directly and, like `shop/offers`, does not explicitly run level-up handling in the same route.
- Premium entitlement rollout is still partially split across the codebase: some callers use `hasPremium()` properly, while several other reward routes still fetch only `user.premiumUntil`.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | `daily-login/claim` checked only `premiumUntil` even though `premium.ts` already supports subscription entitlement via `premiumSubscription.expiresAt`. | Premium Pass subscribers could lose their daily premium gem claim despite having an active paid subscription. | Extended the route to read `premiumSubscription`, pass `activeSubscriptionExpiresAt` into `hasPremium()`, and keep the UTC daily-claim guard unchanged. |
| P1 | `stash/deposit` and `stash/withdraw` checked capacity outside the move transaction. | Parallel requests could overfill the stash or character inventory because both requests could pass the same stale count check. | Moved capacity/item checks into interactive transactions with row locks on the owning user/character and locked item rows before the move. |

## Cross-File Safe Fixes Applied

- `backend/src/app/api/stash/deposit/route.ts` now serializes per-user stash deposits and validates capacity/item state under lock.
- `backend/src/app/api/stash/withdraw/route.ts` now serializes per-character withdrawals and validates capacity/stash ownership under lock.
- `backend/src/app/api/daily-login/claim/route.ts` now honors both Premium Forever and active Premium Pass subscriptions when awarding daily premium gems.
- Removed a few local `any` usages in `daily-login/claim` and `shop/contraband` while touching the runtime.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/lib/game/premium.ts` | Premium entitlement helper | Centralizes Premium Forever / Premium Pass entitlement checks, gold bonus multiplier, and once-per-UTC-day premium gem logic. | Used by daily-login and reward routes that need premium checks. | Premium is active if either `premiumUntil` or an active/grace subscription expiry is in the future. | Helper itself is good. Main problem is incomplete adoption by callers elsewhere in the codebase. | OK |
| `backend/src/app/api/daily-login/claim/route.ts` | Daily reward claim API | Claims daily login reward, updates streak/progression, and awards premium daily gems when eligible. | Depends on auth, daily-login helpers, Prisma, `premium.ts`, rate limiting. | Claim is 20h-gated; premium bonus gems are once per UTC day and must be awarded atomically with the base claim. | Fixed premium entitlement gap so active Premium Pass subscribers now receive the premium daily-gem bonus too. Also tightened local typing while touching the route. | Fixed |
| `backend/src/app/api/stash/route.ts` | Stash read API | Returns the user's account-level stash with item metadata and effective upgraded stats. | Depends on auth, stash items, item catalog, upgrade-stat helper. Used by inventory/stash UI. | Stash is shared per user and capped at 100 slots. | Read path is fine. `STASH_MAX_SLOTS` is duplicated across stash routes and should move to a shared constant later. | OK |
| `backend/src/app/api/stash/deposit/route.ts` | Equipment → stash move API | Moves one unequipped equipment item from character inventory into account stash. | Depends on auth, equipment inventory, stash storage, user ownership. | Equipped items cannot be deposited; stash cap is 100. | Fixed capacity race and item-state TOCTOU by rechecking everything inside a locked transaction. | Fixed |
| `backend/src/app/api/stash/withdraw/route.ts` | Stash → equipment move API | Moves one stash item back into a character's equipment inventory. | Depends on auth, character inventory capacity, stash ownership. | Character inventory cap must not be exceeded; withdrawn items are created unequipped. | Fixed capacity race and stash-item TOCTOU by rechecking everything inside a locked transaction. | Fixed |
| `backend/src/app/api/shop/contraband/route.ts` | Contraband claim API | Serves the deterministic contraband offer and atomically claims/grants its contents. | Depends on auth, contraband claim table, user/character balances, consumable inventory. | 2-hour cooldown, alternating free/paid claims, deterministic seeded loot by character + claim number. | Route is mostly coherent and already uses stronger transaction discipline than stash. Main remaining concern: XP rewards are incremented directly here, and the same pattern exists in `shop/offers`, without explicit level-up handling in this route family. | Needs review |

## Duplicate / Split Logic Found

- `STASH_MAX_SLOTS` is duplicated in multiple stash routes instead of living in a single inventory/stash constant source.
- Premium entitlement rollout is split: `premium.ts` supports subscriptions, but many reward routes outside this block still select only `premiumUntil`.
- Shop-style reward routes (`contraband`, and based on grep also `shop/offers`) increment XP directly without a shared “grant XP + level-up” helper.

## Files Without Clear Current Role

- None in this block. Every file has a live product role.

## Candidates For Refactor

- Extract shared stash constants and maybe a small stash move service so deposit/withdraw stay symmetric.
- Introduce a shared reward-grant helper for shop/contraband style flows that can apply XP, level-up, currencies, and consumables consistently.
- Audit every premium reward/gold-bonus caller and migrate them to the same entitlement shape used by `premium.ts`.

## Documentation Missing Or Stale

- No current page documents stash concurrency rules or why stash moves must be serialized at the DB level.
- No current premium rollout doc lists which backend routes already honor `premiumSubscription` and which still rely on `premiumUntil` only.
- No current shop-rewards doc explains whether XP-granting reward routes are responsible for calling level-up logic themselves or whether that is deferred elsewhere.

## Verification

- `bash -lc 'cd backend && npx eslint src/app/api/stash/deposit/route.ts src/app/api/stash/withdraw/route.ts src/app/api/daily-login/claim/route.ts src/app/api/stash/route.ts src/app/api/shop/contraband/route.ts src/lib/game/premium.ts'` passes.
- `git diff --check` passes.
- No dedicated stash/contraband tests existed in the current test tree, so this block is verified by code-path analysis and targeted lint rather than route-level regression tests.
