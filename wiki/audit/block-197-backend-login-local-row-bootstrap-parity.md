---
title: Audit Block 197 — Backend Login Local Row Bootstrap Parity
category: audit
tags: [audit, auth, backend, login, bootstrap]
sources:
  - backend/src/app/api/auth/login/route.ts
  - backend/tests/api/auth-login.test.ts
  - wiki/features/auth.md
updated: 2026-04-18
status: Fixed
---

# Audit Block 197 — Backend Login Local Row Bootstrap Parity

## Scope

- `backend/src/app/api/auth/login/route.ts`
- `backend/tests/api/auth-login.test.ts`
- `wiki/features/auth.md`

## Why this block

`login` already handled:

- rate limiting
- invalid credentials
- auto-confirm retry for older unconfirmed email accounts

But its local identity step was too loose:

- it used a single `upsert(...)`
- any local failure only logged a warning
- the route still returned tokens

That meant email login could succeed against Supabase while the local `User` row stayed missing or conflicted, leaving the player with a token and no trustworthy local profile bootstrap.

## Fix applied

### `backend/src/app/api/auth/login/route.ts`

- split the local path into two explicit branches:
  - existing local row → best-effort `lastLogin` update, still tolerant of update-only failure
  - missing local row → explicit bootstrap path
- on missing local row:
  - checks for duplicate email tied to another local user id
  - returns `409 Email already registered with another account.` on collision
  - otherwise creates the missing local `User` row
  - returns `500 Failed to initialize account` if bootstrap still fails

### `backend/tests/api/auth-login.test.ts`

- updated existing success tests to the new `findUnique + update` shape
- added regression coverage for:
  - duplicate-email collision while recreating a missing local row → `409`
  - missing local-row bootstrap failure → `500`
  - successful local-row recreation on login when auth succeeds but the row is absent

### `wiki/features/auth.md`

- recorded the new invariant so the auth truth layer now says login either:
  - updates an existing local user,
  - recreates a missing one,
  - or fails cleanly instead of silently issuing tokens into a broken local identity state

## File records

| Path | Role | Status |
|------|------|--------|
| `backend/src/app/api/auth/login/route.ts` | Email/password login runtime | Fixed |
| `backend/tests/api/auth-login.test.ts` | Login route regression coverage | Fixed |
| `wiki/features/auth.md` | Auth feature map and gotchas | Fixed |

## Result

The email login path is now much more honest:

- existing accounts still log in even if `lastLogin` update flakes
- missing local rows are rebuilt explicitly instead of hidden behind a warning
- duplicate-email collisions and bootstrap failures no longer return success with a half-broken local identity

## Verification

- `cd backend && npx vitest run tests/api/auth-login.test.ts`
- `cd backend && npx eslint src/app/api/auth/login/route.ts tests/api/auth-login.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
