---
title: Audit Block 196 — Backend Register Local Init Cleanup
category: audit
tags: [audit, auth, backend, register, cleanup]
sources:
  - backend/src/app/api/auth/register/route.ts
  - backend/tests/api/auth-register.test.ts
  - wiki/features/auth.md
updated: 2026-04-18
status: Fixed
---

# Audit Block 196 — Backend Register Local Init Cleanup

## Scope

- `backend/src/app/api/auth/register/route.ts`
- `backend/tests/api/auth-register.test.ts`
- `wiki/features/auth.md`

## Why this block

`register` already handled:

- validation
- rate limiting
- duplicate-email rejection
- Supabase user creation
- immediate sign-in

But its local bootstrap failure path was too soft:

- Supabase user creation could succeed
- sign-in could already return a real session
- local `prisma.user.create(...)` could then fail
- the route only logged a warning and still returned success

That left behind an auth-only email account with no local `User` row.

## Fix applied

### `backend/src/app/api/auth/register/route.ts`

- upgraded the local create failure from warning-only to a real failure path
- if local `User` creation fails after Supabase create/sign-in:
  - best-effort deletes the fresh Supabase auth user
  - returns `500 Failed to initialize account`

### `backend/tests/api/auth-register.test.ts`

- added regression coverage for:
  - successful Supabase create
  - successful sign-in
  - failed local `User` create
  - expected cleanup of the fresh Supabase auth user
  - stable `500` response

### `wiki/features/auth.md`

- recorded the new invariant so the auth truth layer states that email register now cleans up auth residue when local bootstrap fails

## File records

| Path | Role | Status |
|------|------|--------|
| `backend/src/app/api/auth/register/route.ts` | Email/password register runtime | Fixed |
| `backend/tests/api/auth-register.test.ts` | Register route regression coverage | Fixed |
| `wiki/features/auth.md` | Auth feature map and gotchas | Fixed |

## Result

The email register path now behaves like the other cleaned-up auth flows:

- full success creates both the auth identity and the local `User`
- local bootstrap failure no longer returns a misleading success response
- fresh auth-only email identities are cleaned up instead of being left behind

## Verification

- `cd backend && npx vitest run tests/api/auth-register.test.ts`
- `cd backend && npx eslint src/app/api/auth/register/route.ts tests/api/auth-register.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
