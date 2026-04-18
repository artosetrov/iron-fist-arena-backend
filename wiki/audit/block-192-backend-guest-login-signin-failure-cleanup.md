---
title: Audit Block 192 — Backend Guest Login Sign-In Failure Cleanup
category: audit
tags: [audit, auth, backend, guest, cleanup]
sources:
  - backend/src/app/api/auth/guest-login/route.ts
  - backend/tests/api/auth-guest-login.test.ts
  - wiki/features/auth.md
  - wiki/audit/block-191-backend-guest-login-device-race-recovery.md
updated: 2026-04-18
status: Fixed
---

# Audit Block 192 — Backend Guest Login Sign-In Failure Cleanup

## Scope

- `backend/src/app/api/auth/guest-login/route.ts`
- `backend/tests/api/auth-guest-login.test.ts`
- `wiki/features/auth.md`
- `wiki/audit/block-191-backend-guest-login-device-race-recovery.md`

## Why this block

Block 191 already fixed the big `deviceId` race where a fresh Supabase guest could be returned without a local profile row.

One smaller residue still remained:

- if fresh local guest creation succeeded
- and the subsequent Supabase sign-in failed
- the route deleted the fresh Supabase auth user
- but it still left the local `User` row behind

That produced the mirror-image orphan of the earlier bug.

## Fix applied

### `backend/src/app/api/auth/guest-login/route.ts`

- added explicit cleanup for the fresh local `User` row when sign-in fails after local guest creation
- kept the existing Supabase guest deletion
- the route now rolls back both sides of the fresh guest bootstrap instead of only the auth row

### `backend/tests/api/auth-guest-login.test.ts`

- added regression coverage for:
  - sign-in failure after successful local guest creation
  - expected cleanup of both:
    - `supabase.auth.admin.deleteUser(...)`
    - `prisma.user.delete(...)`

### `wiki/features/auth.md`

- recorded the new invariant so the auth truth layer now reflects cleanup on both sides of the failed fresh-guest path

## File records

| Path | Role | Status |
|------|------|--------|
| `backend/src/app/api/auth/guest-login/route.ts` | Guest auth + restore flow keyed by `deviceId` | Fixed |
| `backend/tests/api/auth-guest-login.test.ts` | Regression coverage for race and cleanup behavior | Fixed |
| `wiki/features/auth.md` | Auth feature map and gotchas | Fixed |
| `wiki/audit/block-191-backend-guest-login-device-race-recovery.md` | Earlier race-recovery block, now linked to this cleanup follow-up | Fixed |

## Result

The fresh guest bootstrap is now symmetric under failure:

- if local guest create fails, the auth row is cleaned up
- if sign-in fails after local guest create, both the auth row and the local row are cleaned up
- the route no longer leaves either flavor of half-created guest identity behind

## Verification

- `cd backend && npx vitest run tests/api/auth-guest-login.test.ts`
- `cd backend && npx eslint src/app/api/auth/guest-login/route.ts tests/api/auth-guest-login.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
