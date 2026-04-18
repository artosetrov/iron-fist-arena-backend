---
title: Audit Block 190 — Backend Sync User Duplicate Email Guard
category: audit
tags: [audit, auth, backend, compatibility]
sources:
  - backend/src/app/api/auth/sync-user/route.ts
  - backend/tests/api/auth-sync-user.test.ts
  - wiki/features/auth.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 190 — Backend Sync User Duplicate Email Guard

## Scope

- `backend/src/app/api/auth/sync-user/route.ts`
- `backend/tests/api/auth-sync-user.test.ts`
- `wiki/features/auth.md`

## Why this block

`/auth/sync-user` is a small route, but it still writes identity fields into the local `User` table.

Before this fix it had the same sharp edge that `link-account` had:

- if the target email already belonged to another user row, the route could fall through to a later database conflict instead of returning a stable application-level response

That is bad identity hygiene even for a helper surface.

## Fix applied

### `backend/src/app/api/auth/sync-user/route.ts`

- added an explicit preflight lookup for the target email
- the route now returns:
  - `409 Email already registered with another account.`
- successful sync behavior stays unchanged

### `backend/tests/api/auth-sync-user.test.ts`

- added coverage for:
  - unauthenticated caller → `401`
  - duplicate-email collision → `409`
  - free email → successful upsert

### `wiki/features/auth.md`

- recorded the collision behavior in the auth gotchas section so the written contract matches the runtime

## File records

| Path | Role | Status |
|------|------|--------|
| `backend/src/app/api/auth/sync-user/route.ts` | Local auth-user sync helper route | Fixed |
| `backend/tests/api/auth-sync-user.test.ts` | Regression coverage for auth/conflict/upsert paths | Fixed |
| `wiki/features/auth.md` | Auth feature map and gotchas | Fixed |

## Result

`sync-user` now behaves like a clean helper route instead of a DB-exception trap:

- auth is explicit
- duplicate-email collisions return `409`
- successful local user sync still upserts as before

## Verification

- `cd backend && npx vitest run tests/api/auth-sync-user.test.ts`
- `cd backend && npx eslint src/app/api/auth/sync-user/route.ts tests/api/auth-sync-user.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
