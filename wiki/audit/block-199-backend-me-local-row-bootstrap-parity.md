---
title: Audit Block 199 — Backend Me Local Row Bootstrap Parity
category: audit
tags: [audit, auth, backend, me, bootstrap]
sources:
  - backend/src/app/api/me/route.ts
  - backend/tests/api/me.test.ts
  - wiki/features/auth.md
  - docs/03_backend_and_api/API_REFERENCE.md
updated: 2026-04-18
status: Fixed
---

# Audit Block 199 — Backend Me Local Row Bootstrap Parity

## Scope

- `backend/src/app/api/me/route.ts`
- `backend/tests/api/me.test.ts`
- `wiki/features/auth.md`
- `docs/03_backend_and_api/API_REFERENCE.md`

## Why this block

`GET /api/me` was still living in an awkward auth gap:

- if the token was valid and the local row existed, it worked
- if the token was valid but the local row was missing, the caller could fall into `401`/`404` ambiguity
- there was no explicit collision guard if the incoming auth email already belonged to another local user id

That made the current-account surface less trustworthy than the auth routes around it.

## Fix applied

### `backend/src/app/api/me/route.ts`

- switched to raw Supabase user validation via `getSupabaseAuthUser(req)`
- preserved explicit `401` for banned rows
- when the local row is missing:
  - checks for duplicate-email ownership first
  - returns `409 Email already registered with another account.` on collision
  - otherwise bootstraps a minimal local `User` row
- if a concurrent create race wins first:
  - reload the row and continue instead of failing the whole response

### `backend/tests/api/me.test.ts`

- added regression coverage for:
  - invalid token → `401`
  - existing row → `200`
  - missing-row bootstrap → `200`
  - duplicate-email collision → `409`
  - bootstrap create race → reload and `200`

### Docs

- `wiki/features/auth.md` now includes `/api/me` in the auth/account surface
- `docs/03_backend_and_api/API_REFERENCE.md` now lists `GET /me`

## Result

`/api/me` now behaves much more like the rest of the hardened auth layer:

- it can self-heal a missing local row
- it does not silently blur collisions into generic auth failure
- it recovers cleanly when another request wins the bootstrap race

## Verification

- `cd backend && npx vitest run tests/api/me.test.ts`
- `cd backend && npx eslint src/app/api/me/route.ts tests/api/me.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
