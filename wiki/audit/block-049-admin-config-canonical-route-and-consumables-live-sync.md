---
title: Block 049 — admin config canonical route and consumables live sync
category: audit
tags: [audit, admin, config, consumables, cache, backend-proxy]
sources:
  - backend/src/lib/game/config.ts
  - backend/src/app/api/admin/config/route.ts
  - backend/src/app/api/admin/item-balance/config/route.ts
  - backend/src/app/api/dev/balance/route.ts
  - backend/tests/api/admin-config.test.ts
  - admin/src/lib/backend-admin.ts
  - admin/src/actions/config.ts
  - admin/src/app/(dashboard)/consumables/consumables-client.tsx
  - admin/src/app/(dashboard)/consumables/page.tsx
updated: 2026-04-15
status: Fixed
---

# Block 049 — admin config canonical route and consumables live sync

## Scope

- `backend/src/lib/game/config.ts`
- `backend/src/app/api/admin/config/route.ts`
- `backend/src/app/api/admin/item-balance/config/route.ts`
- `backend/src/app/api/dev/balance/route.ts`
- `backend/tests/api/admin-config.test.ts`
- `admin/src/lib/backend-admin.ts`
- `admin/src/actions/config.ts`
- `admin/src/app/(dashboard)/consumables/consumables-client.tsx`
- `admin/src/app/(dashboard)/consumables/page.tsx`

## Why this block

This pass started from the `Consumables` admin screen, but it exposed a more important contract issue underneath:

1. admin config writes were still going straight to Prisma from the admin app, bypassing the backend process that owns live `GameConfig` cache invalidation;
2. the consumables screen saved 12 config keys one by one, so a mid-flight failure could leave potion pricing/effect balance only half applied;
3. the player-facing admin copy still claimed consumable config did not affect runtime, even though the backend had already been migrated to live `GameConfig` readers.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[economy]]
- [[bug-patterns]]
- [[design-principles]]

## File notes

### `backend/src/lib/game/config.ts`

- **Zone:** backend / config runtime
- **Purpose:** shared `GameConfig` readers with cache for live balance values
- **Depends on:** Prisma `gameConfig`, shared cache layer
- **Problems found:** the write-side invalidation story was duplicated and incomplete, which made it too easy for admin save paths to forget batch-cache cleanup
- **What was fixed:** added canonical `invalidateGameConfigCache(...)` so config mutation routes stop re-implementing cache invalidation ad hoc
- **Status:** Fixed

### `backend/src/app/api/admin/config/route.ts`

- **Zone:** backend / admin config mutation surface
- **Purpose:** canonical authenticated write path for generic `GameConfig` edits and default seeding
- **Depends on:** admin auth, Prisma, `invalidateGameConfigCache(...)`
- **What was fixed:**
  - added single-key `PUT`, batch `POST`, filtered `GET`, and `DELETE`
  - batch writes can seed defaults with `skipExisting: true`
  - all mutations now invalidate both single-key and batch config caches
  - admin actions are logged centrally
- **Status:** Fixed

### `backend/src/app/api/admin/item-balance/config/route.ts`

- **Zone:** backend / item-balance config
- **Purpose:** canonical item-balance config mutation surface
- **Problems found:** it still owned its own manual cache invalidation logic
- **What was fixed:** moved it to the shared `invalidateGameConfigCache(...)` helper so generic config and item-balance config use the same cache contract
- **Status:** Fixed

### `backend/src/app/api/dev/balance/route.ts`

- **Zone:** backend / dev tooling
- **Purpose:** dev-only balance inspection and override surface
- **Problems found:** config edits here could update DB state without invalidating runtime cache
- **What was fixed:** dev balance writes now invalidate the same live config cache as admin routes
- **Status:** Fixed

### `backend/tests/api/admin-config.test.ts`

- **Zone:** backend tests / admin config
- **Purpose:** protects generic config mutation and seeding contract
- **What it covers now:**
  - single-key updates invalidate config caches
  - batch seeding skips existing keys and still invalidates the touched key set
- **Status:** Fixed

### `admin/src/lib/backend-admin.ts`

- **Zone:** admin / backend integration
- **Purpose:** server-side helper for authenticated admin fetches into the backend app
- **Depends on:** admin cookie auth, backend base URL, `admin-token`
- **What was fixed:** added a reusable server-only helper so admin actions can stop mutating shared gameplay config by talking to Prisma directly
- **Status:** Fixed

### `admin/src/actions/config.ts`

- **Zone:** admin / config actions
- **Purpose:** powers generic config editing, daily login config, loot config, and seeding flows from the admin app
- **Problems found:**
  - writes bypassed backend cache ownership
  - bulk config flows had no atomic batch path
- **What was fixed:**
  - `updateConfig(...)` now goes through the canonical backend admin route
  - added `updateConfigsBatch(...)` for grouped config writes
  - `seedDefaultConfigs()` now seeds through the backend batch route instead of direct Prisma writes
- **Status:** Fixed

### `admin/src/app/(dashboard)/consumables/consumables-client.tsx`

- **Zone:** admin / consumables config UI
- **Purpose:** edits potion prices plus stamina/HP restore magnitudes
- **Problems found:**
  - saved 12 config keys one by one, risking partially applied economy state
  - warning banner was outdated and factually wrong after backend live-config migration
  - a pair of dead filtered arrays only added lint noise
- **What was fixed:**
  - switched save-all to a single batch config write
  - updated the banner so it now correctly says backend reads these `GameConfig` keys live
  - removed the dead locals
- **Status:** Fixed

### `admin/src/app/(dashboard)/consumables/page.tsx`

- **Zone:** admin / consumables page shell
- **Purpose:** loads catalog consumables plus `consumable.*` config rows
- **Status:** OK

## Problems found

1. **Admin config writes bypassed backend cache ownership**
   - Risk: admin users could save a balance value and keep observing stale runtime behavior for up to the cache TTL.
   - Fix: added a canonical backend admin config route and pointed admin write actions at it.

2. **Consumables “Save All” could partially apply**
   - Risk: one failed request midway through the loop could leave potion price/effect balance in a mixed state.
   - Fix: added a batch config write path and moved the consumables screen onto it.

3. **Admin UI copy was lying about live runtime behavior**
   - Risk: teammates would avoid or distrust a working tuning surface because the screen still described the pre-migration backend.
   - Fix: updated the consumables banner to match the actual backend contract.

## Verification

- targeted backend `eslint`:
  - `src/lib/game/config.ts`
  - `src/app/api/admin/config/route.ts`
  - `src/app/api/admin/item-balance/config/route.ts`
  - `src/app/api/dev/balance/route.ts`
  - `tests/api/admin-config.test.ts`
- targeted admin `eslint`:
  - `src/actions/config.ts`
  - `src/lib/backend-admin.ts`
  - `src/app/(dashboard)/consumables/consumables-client.tsx`
- targeted backend `vitest`:
  - `tests/api/admin-config.test.ts`
- full backend `npx vitest run` (`42/42` files, `286/286` tests)
- `npm run build` in `backend/`
- `npx next build` in `admin/`
- `git diff --check`

## Follow-up

- `admin/src/app/(dashboard)/skills/skills-client.tsx` and `admin/src/app/(dashboard)/passives/passives-client.tsx` are not broken, but they still perform direct browser-to-backend fetches with manual `admin-token` parsing and duplicated API base URL logic; that remains the next clean proxy-alignment block
- `getAllConfigs()` / `getConfig()` in `admin/src/actions/config.ts` still read Prisma directly, which is acceptable for list/detail reads today, but the write path is now intentionally centralized in backend
