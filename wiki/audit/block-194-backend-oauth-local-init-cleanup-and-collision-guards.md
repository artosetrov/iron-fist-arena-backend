---
title: Audit Block 194 — Backend OAuth Local Init Cleanup And Collision Guards
category: audit
tags: [audit, auth, backend, google, apple, oauth]
sources:
  - backend/src/app/api/auth/google/route.ts
  - backend/src/app/api/auth/apple/route.ts
  - backend/tests/api/auth-google-apple.test.ts
  - wiki/features/auth.md
updated: 2026-04-18
status: Fixed
---

# Audit Block 194 — Backend OAuth Local Init Cleanup And Collision Guards

## Scope

- `backend/src/app/api/auth/google/route.ts`
- `backend/src/app/api/auth/apple/route.ts`
- `backend/tests/api/auth-google-apple.test.ts`
- `wiki/features/auth.md`

## Why this block

Google/Apple sign-in already handled the happy path and tolerated a non-fatal `lastLogin` update failure.

The bad edge was on first-time local initialization:

- Supabase could successfully authenticate/create the OAuth user
- local `prisma.user.create(...)` could then fail
- the route returned `500`
- but the fresh Supabase OAuth identity remained behind without a local `User` row

There was also no explicit duplicate-email guard:

- if the OAuth email already belonged to another local account
- the route fell through to a generic local-create failure
- the player got no clean “log in and link from settings” signal

## Fix applied

### `backend/src/app/api/auth/google/route.ts`

- added a duplicate-email preflight for the first-time local-create path
- on collision:
  - best-effort deletes the fresh Supabase OAuth user
  - returns `409` with explicit Google linking guidance
- on generic first-time local-create failure:
  - best-effort deletes the fresh Supabase OAuth user
  - returns the existing `500 Failed to initialize account`

### `backend/src/app/api/auth/apple/route.ts`

- mirrored the same behavior for Apple sign-in:
  - duplicate-email collision → cleanup + `409`
  - local-create failure → cleanup + `500`

### `backend/tests/api/auth-google-apple.test.ts`

- extended regression coverage for:
  - Google create failure cleanup
  - Apple create failure cleanup
  - Google duplicate-email collision cleanup + `409`
  - Apple duplicate-email collision cleanup + `409`

### `wiki/features/auth.md`

- recorded the new invariant:
  - OAuth first-login collisions now fail cleanly with a linking message
  - first-time local-init failures no longer leave auth-only orphan users behind

## File records

| Path | Role | Status |
|------|------|--------|
| `backend/src/app/api/auth/google/route.ts` | Google Sign-In token exchange + local profile init | Fixed |
| `backend/src/app/api/auth/apple/route.ts` | Apple Sign-In token exchange + local profile init | Fixed |
| `backend/tests/api/auth-google-apple.test.ts` | Regression coverage for OAuth init cleanup and collision handling | Fixed |
| `wiki/features/auth.md` | Auth feature map and gotchas | Fixed |

## Result

The OAuth auth layer is now safer under failure:

- duplicate-email collisions return a stable `409` instead of a vague init failure
- first-time local-create failures clean up the fresh Supabase OAuth user
- Google/Apple no longer silently accumulate auth-only residue when Prisma bootstrap fails

## Verification

- `cd backend && npx vitest run tests/api/auth-upgrade-guest.test.ts tests/api/auth-google-apple.test.ts`
- `cd backend && npx eslint src/app/api/auth/upgrade-guest/route.ts src/app/api/auth/google/route.ts src/app/api/auth/apple/route.ts tests/api/auth-upgrade-guest.test.ts tests/api/auth-google-apple.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
