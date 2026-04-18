---
title: Block 186 — backend guest OAuth wallet merge parity
category: audit
tags: [audit, backend, auth, oauth, wallet, premium]
sources:
  - backend/src/app/api/auth/upgrade-guest-oauth/route.ts
  - backend/tests/api/auth-upgrade-guest-oauth.test.ts
  - wiki/features/auth.md
  - wiki/audit/block-013-backend-reward-premium-parity.md
updated: 2026-04-17
status: Fixed
---

# Block 186 — backend guest OAuth wallet merge parity

## Scope

- `backend/src/app/api/auth/upgrade-guest-oauth/route.ts`
- `backend/tests/api/auth-upgrade-guest-oauth.test.ts`
- `wiki/features/auth.md`
- `wiki/audit/block-013-backend-reward-premium-parity.md`

## Why this block

[[block-013-backend-reward-premium-parity]] had already fixed the worst premium-loss bug in guest→OAuth upgrades, but one real account-migration hole remained: the route still did not carry `gold` at all, overwrote `gems` instead of merging them, ignored `premiumGemClaimDate`, and unconditionally replaced an existing OAuth `dailyGemCard` with the guest row.

That meant the “broader merge semantics” tail was no longer theoretical. The route could still silently drop wallet value or clobber the better daily-card state when an OAuth-side `User` row already existed without a character. This block makes that merge deterministic instead of hand-wavy.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[auth]]
- [[block-013-backend-reward-premium-parity]]

## File notes

### `backend/src/app/api/auth/upgrade-guest-oauth/route.ts`

- **Zone:** backend / auth / account upgrade
- **Purpose:** migrates a guest account onto a Google/Apple identity
- **Problems found:**
  - guest `gold` was not carried into the OAuth row at all
  - guest `gems` overwrote existing OAuth gems instead of merging wallet state
  - `premiumGemClaimDate` was ignored during merge
  - guest `dailyGemCard` always displaced the OAuth card even if the OAuth card was longer-lived
- **What was fixed:**
  - wallet merge is now deterministic:
    - `gold` = guest + existing OAuth
    - `gems` = guest + existing OAuth
    - `premiumUntil` = later expiry wins
    - `premiumGemClaimDate` = later claim date wins
  - `dailyGemCard` now keeps the longer-lived row when both sides already have one
- **Status:** Fixed

### `backend/tests/api/auth-upgrade-guest-oauth.test.ts`

- **Zone:** backend tests / auth
- **Purpose:** route-level regression coverage for guest→OAuth upgrade
- **What it now proves:**
  - wallet state is merged instead of overwritten/dropped
  - the route keeps the better `dailyGemCard` when both accounts already have one
- **Status:** Fixed

### `wiki/features/auth.md`

- **Zone:** wiki / features
- **Purpose:** source-of-truth feature map for auth and upgrade flows
- **What was fixed:** auth gotchas now document the actual merge policy for guest→OAuth upgrades instead of stopping at “atomic”
- **Status:** Fixed

### `wiki/audit/block-013-backend-reward-premium-parity.md`

- **Zone:** wiki / audit history
- **Purpose:** original premium-parity block that first surfaced the merge-policy concern
- **What was fixed:** the old open merge-policy tail now points at this block as the closure for wallet/premium-card merge behavior
- **Status:** Fixed

## Problems found

1. **Guest→OAuth upgrade could still lose wallet value**
   - Risk: guest gold disappeared entirely and guest gems could overwrite existing OAuth gems.
   - Fix: merged both balances deterministically.

2. **Premium daily-claim state and daily gem card selection were under-specified**
   - Risk: the upgrade could preserve premium expiry but still keep the worse daily-card/claim state.
   - Fix: later date wins for premium claim date, and the longer-lived daily gem card now wins when both exist.

## Verification

- targeted backend `vitest`:
  - `tests/api/auth-upgrade-guest-oauth.test.ts`
- targeted backend `eslint`:
  - `src/app/api/auth/upgrade-guest-oauth/route.ts`
  - `tests/api/auth-upgrade-guest-oauth.test.ts`
- `npm run build` in `backend/`
- `git diff --check`

## Follow-up

- push-token dedupe during guest→OAuth upgrade is still a future hardening candidate if duplicate `(userId, platform, token)` collisions ever show up in the wild
