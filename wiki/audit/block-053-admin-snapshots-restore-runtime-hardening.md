---
title: Block 053 — admin snapshots restore runtime hardening
category: audit
tags: [audit, admin, snapshots, config, cache, rollback]
sources:
  - backend/src/app/api/admin/config/restore/route.ts
  - backend/tests/api/admin-config-restore.test.ts
  - admin/src/actions/snapshots.ts
  - admin/src/app/(dashboard)/snapshots/page.tsx
  - admin/src/app/(dashboard)/snapshots/snapshots-client.tsx
updated: 2026-04-15
status: Fixed
---

# Block 053 — admin snapshots restore runtime hardening

## Scope

- `backend/src/app/api/admin/config/restore/route.ts`
- `backend/tests/api/admin-config-restore.test.ts`
- `admin/src/actions/snapshots.ts`
- `admin/src/app/(dashboard)/snapshots/page.tsx`
- `admin/src/app/(dashboard)/snapshots/snapshots-client.tsx`

## Why this block

The snapshots surface looked harmless, but the rollback path still had two real runtime problems:

1. `rollbackToSnapshot()` in the admin app replaced `gameConfig` rows directly through Prisma, bypassing the backend process that owns live config cache invalidation;
2. that replacement was not transactional, so a mid-flight failure could leave the config table only partially restored.

There was also a smaller admin-UI cleanup tail around dead props, `any`, and abandoned expand/details state.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[design-principles]]
- [[bug-patterns]]
- [[economy]]

## File notes

### `backend/src/app/api/admin/config/restore/route.ts`

- **Zone:** backend / admin config restore
- **Purpose:** canonical authenticated restore surface for full config snapshot rollback
- **Depends on:** admin auth, Prisma, shared `invalidateGameConfigCache(...)`
- **What was fixed:**
  - added a transaction-backed restore route for full snapshot replacement
  - automatically creates a backup snapshot before restore unless explicitly disabled
  - rejects duplicate keys in the restore payload
  - invalidates the union of old and restored config keys after commit
- **Status:** Fixed

### `backend/tests/api/admin-config-restore.test.ts`

- **Zone:** backend tests / admin config restore
- **Purpose:** locks down atomic restore behavior and cache invalidation contract
- **What it covers now:**
  - successful restore replaces config rows and invalidates both removed and restored keys
  - duplicate-key restore payloads are rejected with a stable `400`
- **Status:** Fixed

### `admin/src/actions/snapshots.ts`

- **Zone:** admin / snapshot actions
- **Purpose:** create, list, rollback, and delete config snapshots
- **Problems found:**
  - rollback mutated `gameConfig` directly from the admin process
  - rollback skipped backend cache invalidation ownership
  - create/delete flows were not wrapped with their matching admin-log writes
- **What was fixed:**
  - rollback now calls the canonical backend restore route
  - create/delete flows are wrapped in transactions with their admin-log writes
  - snapshot list typing is explicit instead of inferred through looser client mapping
- **Status:** Fixed

### `admin/src/app/(dashboard)/snapshots/page.tsx`

- **Zone:** admin / snapshots page shell
- **Purpose:** loads snapshot summaries for the dashboard table
- **Problems found:** `any` in snapshot mapping plus stale `adminId` prop pass-through
- **What was fixed:** removed the weak mapping cast and dead prop wiring
- **Status:** Fixed

### `admin/src/app/(dashboard)/snapshots/snapshots-client.tsx`

- **Zone:** admin / snapshots UI
- **Purpose:** create, rollback, and delete config snapshots
- **Problems found:**
  - dead `adminId` prop
  - abandoned expand/details state that had no visible UI path
  - leftover unused imports and weak local cleanup
- **What was fixed:** removed the dead prop, deleted the abandoned expand/details code path, and cleaned the touched imports/types
- **Status:** Fixed

## Problems found

1. **Snapshot rollback bypassed backend cache ownership**
   - Risk: after rollback, gameplay could still read stale cached config values even though the DB had changed.
   - Fix: moved restore onto a canonical backend route that invalidates live config cache.

2. **Snapshot rollback was not transactional**
   - Risk: a failed restore could leave `gameConfig` partially deleted or partially recreated.
   - Fix: implemented restore inside a backend transaction with backup creation and admin logging.

3. **Restore payloads were not validated for duplicate keys**
   - Risk: duplicate keys could make restore order-dependent and hard to reason about.
   - Fix: reject duplicate-key payloads up front with `400`.

4. **Snapshots UI carried abandoned state and weak typing**
   - Risk: dead UI paths make future maintenance harder and hide the real behavior surface.
   - Fix: removed dead expand/details logic, `any` mapping, and obsolete prop plumbing.

## Verification

- targeted backend `eslint`:
  - `src/app/api/admin/config/restore/route.ts`
  - `tests/api/admin-config-restore.test.ts`
- targeted backend `vitest`:
  - `tests/api/admin-config.test.ts`
  - `tests/api/admin-config-restore.test.ts`
- `npm run build` in `backend/`
- targeted admin `eslint`:
  - `src/actions/snapshots.ts`
  - `src/app/(dashboard)/snapshots/page.tsx`
  - `src/app/(dashboard)/snapshots/snapshots-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`

## Follow-up

- snapshot list/read hydration still uses direct Prisma on the admin side; that is acceptable for now because the high-risk restore path now belongs to the backend runtime
- `settings`, `dashboard`, and a few other admin read-side pages still look like the next consistency pass for lingering direct Prisma shapes and warning-heavy UI debt
