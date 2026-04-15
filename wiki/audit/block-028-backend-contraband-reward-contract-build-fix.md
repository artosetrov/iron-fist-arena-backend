---
title: Audit Block 028 — Backend Contraband Reward Contract Build Fix
category: audit
tags: [audit, backend, shop, contraband, rewards, types, build]
sources:
  - backend/src/app/api/shop/contraband/route.ts
  - backend/src/lib/game/reward-grants.ts
  - wiki/audit/block-014-shared-reward-grants-shop-mail-rush-sync.md
  - wiki/audit/block-012-backend-stash-contraband-premium-runtime.md
updated: 2026-04-15
---

# Audit Block 028 — Backend Contraband Reward Contract Build Fix

## Scope

This block was triggered by a real production build failure on Vercel. `shop/contraband` already used the shared reward-grant runtime, but one local helper still widened reward literals into plain `string`, so TypeScript no longer recognized contraband loot as valid `RewardGrantEntry[]`.

- **Files audited in this block:** 2 code files + audit/wiki sync
- **Primary file types:** backend route and shared reward contract
- **Status:** build blocker fixed; contraband loot now stays on the same typed reward contract as the rest of shared reward runtime
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-014-shared-reward-grants-shop-mail-rush-sync]], [[block-012-backend-stash-contraband-premium-runtime]], [[economy]]

## Summary

- `generateLoot(...)` in `backend/src/app/api/shop/contraband/route.ts` returned `{ type: string; ... }[]`.
- `grantRewardEntries(...)` correctly requires `readonly RewardGrantEntry[]`.
- That mismatch did not change runtime behavior, but it did break production compilation once the stricter shared reward path was in place.
- The safe fix was to keep contraband loot on the canonical reward type instead of weakening the shared contract.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Contraband loot helper widened reward `type` to raw `string`. | Vercel/Next production builds failed, blocking deployment despite valid runtime logic. | Imported `RewardGrantEntry`, narrowed `LootItem.type` to the shared reward union subset, and made `generateLoot(...)` return `RewardGrantEntry[]`. |
| P2 | Contraband route had a local pseudo-contract for rewards instead of reusing the shared runtime contract directly. | Future reward changes could compile in one path and silently drift in another. | Reused the shared contract in the route so `GET`, `POST`, and persisted claim contents all stay aligned with the reward-grant helper. |

## Cross-File Safe Fixes Applied

- `backend/src/app/api/shop/contraband/route.ts`
  - imports `type RewardGrantEntry` from the shared reward runtime,
  - narrows `LootItem.type` to the exact shared reward subset used by contraband,
  - returns `RewardGrantEntry[]` from `generateLoot(...)`,
  - and builds reward objects without widening them back to `string`.
- `backend/src/lib/game/reward-grants.ts`
  - re-audited as the canonical reward contract for contraband; no code change needed.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/app/api/shop/contraband/route.ts` | Backend contraband API | Generates deterministic contraband offers, enforces cooldown/payment, grants rewards, and persists claim history. | Depends on auth, Prisma, reward grants, cooldown rules, passive/skill cache invalidation. Used by shop/contraband client flows. | Contraband loot must be deterministic per `characterId + claimNumber`, valid for shared reward grants, and safe to persist in claim history. | Fixed the local loot helper so it no longer widens reward entries into `{ type: string }[]`. | Fixed |
| `backend/src/lib/game/reward-grants.ts` | Shared backend reward grant contract/runtime | Canonical mixed-reward grant path for gold, gems, XP, items, and consumables with level-up handling. | Used by shop/mail/quest/battle-pass/rush/contraband reward flows. | Callers must provide `RewardGrantEntry[]`; the shared helper stays strict so broken callers fail at compile time. | Re-verified as the correct shared contract; no code change required. | OK |

## Duplicate / Split Logic Found

- The issue here was not duplicate runtime logic, but duplicate typing intent: contraband described its reward objects locally instead of reusing the shared reward type directly.
- That kind of drift is easy to miss because runtime behavior still works until a stricter build or refactor surfaces it.

## Files Without Clear Current Role

- None in this block.

## Candidates For Refactor

- If contraband reward pools grow beyond gold/gems/xp/consumables, the loot table itself should likely move closer to shared reward DTO/helpers rather than continuing as a route-local structure.

## Documentation Missing Or Stale

- No doc drift here; the main missing source of truth was a type-level one inside the route.

## Requires Separate Decision

- No product decision is blocked. This was a pure contract/build correctness fix.

## Verification

- `npm run build` in `backend/` completed successfully after the fix; the previous `shop/contraband` type error is gone.
- `git diff --check` passes after the patch.
