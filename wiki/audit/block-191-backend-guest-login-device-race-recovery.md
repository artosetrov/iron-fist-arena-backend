---
title: Audit Block 191 — Backend Guest Login Device Race Recovery
category: audit
tags: [audit, auth, backend, guest, race-condition]
sources:
  - backend/src/app/api/auth/guest-login/route.ts
  - backend/tests/api/auth-guest-login.test.ts
  - wiki/features/auth.md
updated: 2026-04-18
status: Fixed
---

# Audit Block 191 — Backend Guest Login Device Race Recovery

> Later follow-up: [block-192-backend-guest-login-signin-failure-cleanup](/Users/artosetrov/Documents/Cursor%20AI/PVP%20RPG/wiki/audit/block-192-backend-guest-login-signin-failure-cleanup.md) completed the rollback story by cleaning up the local `User` row too when fresh guest sign-in fails after local creation.

## Scope

- `backend/src/app/api/auth/guest-login/route.ts`
- `backend/tests/api/auth-guest-login.test.ts`
- `wiki/features/auth.md`

## Why this block

`guest-login` already had a restore path keyed by `deviceId`, but the fresh-create branch still had a bad race outcome:

- if Supabase guest creation succeeded
- and local `prisma.user.create(...)` then lost a `deviceId` race
- the route could still return a valid session for the brand-new Supabase guest even though no local `User` row existed for that identity

That is exactly the kind of bug that leaves the player “logged in” with no coherent local profile behind the token.

## Fix applied

### `backend/src/app/api/auth/guest-login/route.ts`

- extracted the restore logic into `tryRestoreGuestSession(...)`
- moved fresh guest sign-in to after successful local `User` creation
- if local guest creation fails:
  - delete the just-created Supabase guest
  - if a `deviceId` exists, retry the restore path against the already-linked guest
  - otherwise return a clean `500`
- if sign-in fails after local create:
  - delete the just-created Supabase guest instead of leaving an orphan auth row behind

### `backend/tests/api/auth-guest-login.test.ts`

- added regression coverage for:
  - `deviceId` race on local user create → delete fresh Supabase guest and restore existing guest
  - local create failure without a restore path → delete fresh Supabase guest and return `500`

### `wiki/features/auth.md`

- recorded the new invariant in the auth gotchas section so the route’s recovery behavior is explicit in the truth layer

## File records

| Path | Role | Status |
|------|------|--------|
| `backend/src/app/api/auth/guest-login/route.ts` | Guest auth + restore flow keyed by `deviceId` | Fixed |
| `backend/tests/api/auth-guest-login.test.ts` | Regression coverage for device-race recovery and cleanup paths | Fixed |
| `wiki/features/auth.md` | Auth feature map and gotchas | Fixed |

## Result

`guest-login` is now much safer under concurrency:

- no session is returned for a fresh guest if the local user row never materialized
- the route prefers restoring the already-linked guest identity when a `deviceId` race occurs
- failed fresh-create attempts no longer leave behind silent Supabase auth residue

## Verification

- `cd backend && npx vitest run tests/api/auth-guest-login.test.ts`
- `cd backend && npx eslint src/app/api/auth/guest-login/route.ts tests/api/auth-guest-login.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
