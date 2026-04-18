---
title: Audit Block 195 — Backend Upgrade Guest OAuth Transaction Cleanup
category: audit
tags: [audit, auth, backend, oauth, cleanup]
sources:
  - backend/src/app/api/auth/upgrade-guest-oauth/route.ts
  - backend/tests/api/auth-upgrade-guest-oauth.test.ts
  - wiki/features/auth.md
  - wiki/audit/block-186-backend-guest-oauth-wallet-merge-parity.md
updated: 2026-04-18
status: Fixed
---

# Audit Block 195 — Backend Upgrade Guest OAuth Transaction Cleanup

## Scope

- `backend/src/app/api/auth/upgrade-guest-oauth/route.ts`
- `backend/tests/api/auth-upgrade-guest-oauth.test.ts`
- `wiki/features/auth.md`
- `wiki/audit/block-186-backend-guest-oauth-wallet-merge-parity.md`

## Why this block

Block 186 made the guest→OAuth merge rules correct for wallet and premium state.

One failure seam still remained:

- Supabase `signInWithIdToken(...)` could succeed
- the guest→OAuth transfer transaction could then fail before the local attach completed
- the route returned `500`
- but a fresh OAuth auth user could remain behind with no local row yet attached

That is the same half-created identity pattern we already cleaned up in the other auth flows.

## Fix applied

### `backend/src/app/api/auth/upgrade-guest-oauth/route.ts`

- records whether a local Prisma row already existed for the OAuth user id before the transfer begins
- wraps the guest→OAuth transfer transaction in an explicit `try/catch`
- on transaction failure:
  - logs the failure
  - if there was no pre-existing local OAuth row, deletes the fresh Supabase OAuth user
  - returns a stable `500 Failed to link account. Please try again.`

This keeps the route from leaving behind a brand-new auth-only OAuth identity when the attach/transfer path never committed.

### `backend/tests/api/auth-upgrade-guest-oauth.test.ts`

- added regression coverage for:
  - transaction failure after successful OAuth sign-in
  - expected cleanup of the fresh OAuth auth user
  - stable `500` response

### `wiki/features/auth.md`

- recorded the new invariant so the auth truth layer states that guest→OAuth now cleans up fresh OAuth auth residue when the transfer transaction fails before local attach

## File records

| Path | Role | Status |
|------|------|--------|
| `backend/src/app/api/auth/upgrade-guest-oauth/route.ts` | Guest → Google/Apple upgrade runtime | Fixed |
| `backend/tests/api/auth-upgrade-guest-oauth.test.ts` | Regression coverage for transfer-failure cleanup | Fixed |
| `wiki/features/auth.md` | Auth feature map and gotchas | Fixed |
| `wiki/audit/block-186-backend-guest-oauth-wallet-merge-parity.md` | Earlier guest→OAuth merge block, now linked to the cleanup follow-up | Fixed |

## Result

`upgrade-guest-oauth` is now safer under failure:

- merge semantics from block 186 stay intact
- failed transfer transactions no longer leave a fresh auth-only OAuth identity behind when no local OAuth row existed yet
- guest upgrade now behaves more like the other cleaned-up auth flows: success links both sides, failure cleans the fresh side back up

## Verification

- `cd backend && npx vitest run tests/api/auth-upgrade-guest-oauth.test.ts`
- `cd backend && npx eslint src/app/api/auth/upgrade-guest-oauth/route.ts tests/api/auth-upgrade-guest-oauth.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
