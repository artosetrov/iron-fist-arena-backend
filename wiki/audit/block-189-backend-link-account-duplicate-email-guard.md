---
title: Audit Block 189 — Backend Link Account Duplicate Email Guard
category: audit
tags: [audit, auth, backend, compatibility]
sources:
  - backend/src/app/api/auth/link-account/route.ts
  - backend/tests/api/auth-link-account.test.ts
  - wiki/features/auth.md
  - wiki/audit/block-188-auth-link-account-surface-parity.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 189 — Backend Link Account Duplicate Email Guard

## Scope

- `backend/src/app/api/auth/link-account/route.ts`
- `backend/tests/api/auth-link-account.test.ts`
- `wiki/features/auth.md`
- `wiki/audit/block-188-auth-link-account-surface-parity.md`

## Why this block

Block 188 already clarified that `/auth/link-account` is only a narrower compatibility surface.

But even as a compatibility route it still had one sharp edge:

- if the target email already belonged to another user, the route could fall through to a Prisma unique constraint failure and return a generic `500`

That is the wrong contract for a user-facing identity collision.

## Fix applied

### `backend/src/app/api/auth/link-account/route.ts`

- added an explicit duplicate-email preflight lookup
- the route now returns:
  - `409 Email already registered with another account.`
- successful local profile sync behavior stays unchanged

### `backend/tests/api/auth-link-account.test.ts`

- added coverage for:
  - unauthenticated caller → `401`
  - duplicate-email collision → `409`
  - free email → successful local profile sync

### `wiki/features/auth.md`

- updated the auth gotcha note so the compatibility route’s duplicate-email behavior is part of the written contract

## File records

| Path | Role | Status |
|------|------|--------|
| `backend/src/app/api/auth/link-account/route.ts` | Compatibility route for local profile sync after provider linking | Fixed |
| `backend/tests/api/auth-link-account.test.ts` | Regression coverage for compatibility-route auth and duplicate-email behavior | Fixed |
| `wiki/features/auth.md` | Auth feature map and gotchas | Fixed |
| `wiki/audit/block-188-auth-link-account-surface-parity.md` | Earlier truth-sync block, now linked to this runtime hardening follow-up | Fixed |

## Result

The route is still a compatibility surface, but now it behaves like one responsibly:

- caller auth is explicit
- duplicate-email conflicts return a stable `409`
- local sync no longer relies on a database exception to explain a common identity collision

## Verification

- `cd backend && npx vitest run tests/api/auth-link-account.test.ts`
- `cd backend && npx eslint src/app/api/auth/link-account/route.ts tests/api/auth-link-account.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
