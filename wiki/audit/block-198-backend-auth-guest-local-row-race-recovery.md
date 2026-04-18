---
title: Audit Block 198 — Backend Auth Guest Local Row Race Recovery
category: audit
tags: [audit, auth, backend, guest, race-condition]
sources:
  - backend/src/lib/auth.ts
  - backend/src/app/api/auth/guest/route.ts
  - backend/tests/api/auth-guest.test.ts
  - wiki/features/auth.md
updated: 2026-04-18
status: Fixed
---

# Audit Block 198 — Backend Auth Guest Local Row Race Recovery

## Scope

- `backend/src/lib/auth.ts`
- `backend/src/app/api/auth/guest/route.ts`
- `backend/tests/api/auth-guest.test.ts`
- `wiki/features/auth.md`

## Why this block

`POST /api/auth/guest` was supposed to create the local guest `User` row when a valid auth token existed without local persistence.

But the route was calling `getAuthUser(req)`, and that helper intentionally returns `null` when the local row is missing.

So the route could:

- reject valid guest auth with `401`
- fail to recreate the missing local row at all
- still lose a concurrent create race with no recovery path

That made the endpoint much less useful exactly in the recovery scenario it existed to handle.

## Fix applied

### `backend/src/lib/auth.ts`

- extracted raw Supabase token validation into `getSupabaseAuthUser(req)`
- kept `getAuthUser(req)` behavior unchanged for the rest of the authed route surface

### `backend/src/app/api/auth/guest/route.ts`

- switched to `getSupabaseAuthUser(req)` so valid guest auth can bootstrap a missing local row
- preserved the old ban behavior by rejecting banned existing rows with `401`
- when local create loses an id race:
  - reload the row by `user.id`
  - return the recovered row instead of leaking a generic `500`

### `backend/tests/api/auth-guest.test.ts`

- added regression coverage for:
  - invalid token → `401`
  - existing local guest row → `200`
  - missing row bootstrap → `200`
  - concurrent create race → reload and `200`

### `wiki/features/auth.md`

- recorded the new invariant so the auth map now says `/auth/guest` can really self-heal a missing local row

## Result

`/auth/guest` now behaves like an actual recovery/bootstrap endpoint:

- valid guest auth can recreate the missing local row
- concurrent create races recover cleanly
- the old helper-level “missing row means unauthorized” trap no longer blocks the route

## Verification

- `cd backend && npx vitest run tests/api/auth-guest.test.ts`
- `cd backend && npx eslint src/lib/auth.ts src/app/api/auth/guest/route.ts tests/api/auth-guest.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
