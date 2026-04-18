---
title: Block 047 — backend dungeon item balance and live config hardening
category: audit
tags: [audit, backend, dungeons, item-balance, live-config, tests]
sources:
  - backend/src/lib/game/dungeon.ts
  - backend/src/lib/game/item-balance.ts
  - backend/src/lib/game/live-config.ts
  - backend/src/app/api/admin/item-balance/profiles/route.ts
  - backend/tests/lib/dungeon.test.ts
  - backend/tests/lib/item-balance.test.ts
updated: 2026-04-15
status: Fixed
---

# Block 047 — backend dungeon item balance and live config hardening

## Scope

- `backend/src/lib/game/dungeon.ts`
- `backend/src/lib/game/item-balance.ts`
- `backend/src/lib/game/live-config.ts`
- `backend/src/app/api/admin/item-balance/profiles/route.ts`
- `backend/tests/lib/dungeon.test.ts`
- `backend/tests/lib/item-balance.test.ts`

## Why this block

This pass started from the last warning-heavy backend helpers, but it quickly turned into a real runtime-correctness block:

1. DB-backed dungeon generation was not applying the same scheduled variety-room logic as the hardcoded fallback generator, so live dungeon runs could behave differently depending on whether boss data came from Prisma or from the embedded fallback table.
2. item-balance trusted admin JSON too loosely for both profile stat weights and class damage scaling, which meant malformed config could silently leak invalid keys and values into runtime formulas.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[dungeons]]
- [[progression]]
- [[bug-patterns]]

## File notes

### `backend/src/lib/game/dungeon.ts`

- **Zone:** backend / dungeon generation
- **Purpose:** generates boss floors and scheduled non-combat variety rooms for dungeon runs
- **Depends on:** Prisma dungeon tables and hardcoded fallback boss data
- **Used by:** `/api/dungeons/start`, `/api/dungeons/fight`, and DB-fallback runtime paths
- **Problems found:**
  - DB-backed floor generation skipped scheduled variety rooms entirely
  - the shared helper still carried an unused `dungeonId` parameter
- **What was fixed:**
  - DB-backed generation now short-circuits through the same variety-room schedule as the fallback generator
  - the dead helper parameter was removed
  - focused tests now lock in both variety-room parity and regular DB boss loading
- **Status:** Fixed

### `backend/src/lib/game/item-balance.ts`

- **Zone:** backend / balance engine
- **Purpose:** computes item power, stat rolls, class damage formulas, and pricing helpers
- **Depends on:** `GameConfig`, `ItemBalanceProfile`, Prisma item catalog
- **Used by:** loot generation, validation, combat stat helpers, admin balance tooling
- **Problems found:**
  - `ItemBalanceProfile.statWeights` was trusted as raw JSON without stat-key validation
  - `item_balance.class_damage_scaling` trusted arbitrary config JSON
  - module cache could stay stale indefinitely after profile edits
- **What was fixed:**
  - profile stat weights are now sanitized to canonical stat keys with numeric positive values only
  - malformed class-damage config now falls back to the class default instead of poisoning runtime math
  - cache entries now have a TTL, and the backend admin profile update route invalidates the touched item-type cache immediately in-process
  - focused tests cover cache refresh behavior, malformed profile weights, and malformed class-damage scaling
- **Later follow-up:** [[block-177-stale-audit-tail-item-balance-cross-process-sync]] confirmed the old cross-process write concern was resolved after [[block-048-admin-item-balance-backend-proxy-alignment]] moved admin profile writes onto the backend canonical route
- **Status:** Fixed

### `backend/src/lib/game/live-config.ts`

- **Zone:** backend / config readers
- **Purpose:** exposes typed readers for live balance config with fallbacks
- **Depends on:** `GameConfig` and `balance.ts`
- **Problems found:** stale unused `STANCE_ZONES` import hid the fact that this file had already been cleaned up elsewhere
- **What was fixed:** removed the dead import so warning noise stops masking real config issues
- **Status:** Fixed

### `backend/src/app/api/admin/item-balance/profiles/route.ts`

- **Zone:** backend / admin balance mutation
- **Purpose:** upserts `ItemBalanceProfile` rows for item-type tuning
- **Depends on:** admin auth, Prisma, item-balance runtime
- **Problems found:** successful profile updates did not invalidate the runtime cache in the same backend process
- **What was fixed:** the touched item-type cache is now invalidated right after upsert
- **Status:** Fixed

### `backend/tests/lib/dungeon.test.ts`

- **Zone:** backend tests / dungeon runtime
- **Purpose:** protects DB-backed dungeon generation parity
- **What it covers now:**
  - scheduled variety floors short-circuit before any DB lookup
  - non-variety floors still use DB boss rows and keep scaling intact
- **Status:** Fixed

### `backend/tests/lib/item-balance.test.ts`

- **Zone:** backend tests / balance runtime
- **Purpose:** protects sanitization and cache behavior in item-balance helpers
- **What it covers now:**
  - profile cache stays stable until explicit invalidation
  - malformed profile stat weights are sanitized
  - malformed class-damage config falls back to canonical defaults
- **Status:** Fixed

## Problems found

1. **DB-backed dungeons and fallback dungeons did not agree on variety floors**
   - Risk: the same dungeon floor could be a merchant/rest/treasure room in fallback mode but a forced boss fight in live Prisma-backed mode.
   - Fix: apply the shared variety-room schedule before any DB boss lookup.

2. **item-balance accepted malformed admin JSON as if it were valid runtime config**
   - Risk: invalid stat keys or non-numeric values could quietly distort power score, stat generation, or damage formulas.
   - Fix: sanitize profile weights and class damage scaling before runtime use, with explicit fallbacks.

3. **Item balance profile cache had no freshness boundary**
   - Risk: balance edits could stick in-process until a restart.
   - Fix: added TTL-based cache expiry plus direct invalidation in the backend admin mutation route.

## Verification

- targeted backend `eslint`:
  - `src/lib/game/dungeon.ts`
  - `src/lib/game/item-balance.ts`
  - `src/lib/game/live-config.ts`
  - `src/app/api/admin/item-balance/profiles/route.ts`
  - `tests/lib/dungeon.test.ts`
  - `tests/lib/item-balance.test.ts`
- targeted backend `vitest`:
  - `tests/lib/dungeon.test.ts`
  - `tests/lib/item-balance.test.ts`
- full backend `npx vitest run` (`41/41` files, `284/284` tests)
- `npm run build` in `backend/`
- `git diff --check`

## Follow-up

- `item-balance` now has bounded cache staleness, but the separate admin app still updates profiles from a different process; if sub-minute freshness becomes important, this should move to an evented invalidation path
- `DungeonRoom.floor` still reflects the internal zero-based scheduled index for variety rooms, which is consistent with current behavior but worth documenting more explicitly if client consumers start displaying it directly
