---
title: Audit Block 193 — Backend Upgrade Guest Full Supabase Rollback
category: audit
tags: [audit, auth, backend, guest, rollback]
sources:
  - backend/src/app/api/auth/upgrade-guest/route.ts
  - backend/tests/api/auth-upgrade-guest.test.ts
  - wiki/features/auth.md
updated: 2026-04-18
status: Fixed
---

# Audit Block 193 — Backend Upgrade Guest Full Supabase Rollback

## Scope

- `backend/src/app/api/auth/upgrade-guest/route.ts`
- `backend/tests/api/auth-upgrade-guest.test.ts`
- `wiki/features/auth.md`

## Why this block

`upgrade-guest` already retried the local Prisma write and tried to revert Supabase if both attempts failed.

But the rollback was incomplete:

- Supabase email/password could already be upgraded
- Prisma could still say the account is anonymous
- the revert path only restored guest metadata
- it did **not** restore the previous guest email or a guest-only credential state

That left the two identity layers disagreeing about what kind of account the player actually had.

## Fix applied

### `backend/src/app/api/auth/upgrade-guest/route.ts`

- imported `crypto`
- widened the rollback payload after repeated Prisma failure
- rollback now always restores:
  - `user_metadata: { is_guest: true, username: undefined }`
- and, when the guest already had an email recorded locally, also restores:
  - previous guest email
  - `email_confirm: true`
  - a fresh random password so the reverted auth record no longer keeps the just-upgraded credentials

### `backend/tests/api/auth-upgrade-guest.test.ts`

- added regression coverage for:
  - successful Supabase email/password upgrade
  - repeated Prisma failure
  - full rollback back to guest auth state
- the test verifies that the second `updateUserById(...)` call restores:
  - legacy guest email
  - fresh rollback password
  - guest metadata

### `wiki/features/auth.md`

- recorded the new invariant so the auth truth layer states that guest→email upgrade now rolls back the full Supabase identity, not just metadata cosmetics

## File records

| Path | Role | Status |
|------|------|--------|
| `backend/src/app/api/auth/upgrade-guest/route.ts` | Guest → email/password upgrade runtime | Fixed |
| `backend/tests/api/auth-upgrade-guest.test.ts` | Regression coverage for repeated local-write failure rollback | Fixed |
| `wiki/features/auth.md` | Auth feature map and gotchas | Fixed |

## Result

`upgrade-guest` now fails symmetrically:

- if local persistence succeeds, the account is upgraded end to end
- if local persistence fails twice, Supabase is put back into guest state materially
- backend no longer risks an “email account in auth / anonymous account in Prisma” split-brain identity

## Verification

- `cd backend && npx vitest run tests/api/auth-upgrade-guest.test.ts`
- `cd backend && npx eslint src/app/api/auth/upgrade-guest/route.ts tests/api/auth-upgrade-guest.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
