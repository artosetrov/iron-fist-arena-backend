---
title: Block 040 — Backend IAP receipt idempotency and webhook contracts
category: audit
tags: [audit, backend, iap, subscriptions, apple]
sources:
  - backend/src/app/api/iap/verify-receipt/route.ts
  - backend/src/app/api/iap/apple-notifications/route.ts
  - backend/tests/api/iap-verify-receipt.test.ts
  - backend/tests/api/iap-apple-notifications.test.ts
updated: 2026-04-15
status: Fixed
---

# Block 040 — Backend IAP receipt idempotency and webhook contracts

## Scope

- `backend/src/app/api/iap/verify-receipt/route.ts`
- `backend/src/app/api/iap/apple-notifications/route.ts`
- `backend/tests/api/iap-verify-receipt.test.ts`
- `backend/tests/api/iap-apple-notifications.test.ts`

## Why this block

The next warning-heavy backend slice included the live Apple IAP entrypoints. A deeper read found one real production bug and one coverage hole:

1. `verify-receipt` did a duplicate transaction pre-check before write, but still wrote into a unique `transactionId` column later inside a transaction. Two parallel identical receipts could both pass the pre-check, then one would hit Prisma `P2002` and bubble out as a generic `500`.
2. Neither the receipt route nor the Apple webhook route had focused API tests, so this contract drift could easily come back through refactors.

## File notes

### `backend/src/app/api/iap/verify-receipt/route.ts`

- **Zone:** backend / IAP
- **Purpose:** verifies Apple purchases, records the transaction, grants currencies/items, and seeds subscription state
- **What it does now:** still short-circuits already-known duplicate receipts with a fast `409`, but now also catches the unique `transactionId` race during transaction write and returns the same `409` instead of a generic `500`
- **Problems found:**
  - pre-check duplicate logic was not enough to make the route idempotent under parallel retries
  - `operations: any[]` hid the transaction contract and made the route look safer than it really was
- **What was fixed:**
  - added a narrow Prisma duplicate-error guard for `transactionId`
  - replaced `any[]` with a typed first operation plus typed Prisma promise rest-array
- **Status:** Fixed

### `backend/src/app/api/iap/apple-notifications/route.ts`

- **Zone:** backend / IAP webhook
- **Purpose:** applies Apple Server Notifications v2 subscription lifecycle updates
- **What it does now:** decodes the Apple JWS payload, resolves the local subscription by `originalTransactionId`, and applies idempotent status/expiry updates
- **Problem found:** `updates` stayed mutable for no reason, which added warning noise to an already risk-heavy file
- **What was fixed:** made the update payload `const`
- **Status:** Fixed

### `backend/tests/api/iap-verify-receipt.test.ts`

- **Zone:** backend tests / IAP
- **Purpose:** locks the receipt route to the current idempotency and subscription-grant contract
- **What it covers now:**
  - early duplicate receipt rejection
  - concurrent unique-constraint collision returning `409`, not `500`
  - subscription purchase seeding `PremiumSubscription` and returning authoritative expiry + monthly gem grant
- **Status:** Fixed

### `backend/tests/api/iap-apple-notifications.test.ts`

- **Zone:** backend tests / IAP webhook
- **Purpose:** checks the webhook’s core happy path and safe no-op path
- **What it covers now:**
  - `DID_RENEW` updates the local subscription with new expiry and latest transaction id
  - unknown subscription rows still return `200` and skip mutation
- **Status:** Fixed

## Problems found

1. **Receipt duplicate race**
   - Risk: App Store retries or client double-submits could produce a user-visible `500` even though the purchase was already being processed successfully elsewhere.
   - Fix: map Prisma `P2002` on `transactionId` to the same `409 Transaction already processed` response as the early duplicate path.

2. **Untyped IAP transaction operation list**
   - Risk: the earlier `any[]` masked transaction result typing and made future refactors easier to break silently.
   - Fix: typed the first transaction create operation and the remaining Prisma promises explicitly.

3. **Missing focused route tests on live Apple IAP surfaces**
   - Risk: IAP regressions can pass local smoke checks but fail only in deploy/production flows.
   - Fix: added narrow route tests for both receipt verification and Apple webhook handling.

## Verification

- targeted `vitest`:
  - `tests/api/iap-verify-receipt.test.ts`
  - `tests/api/iap-apple-notifications.test.ts`
- full backend `npx vitest run` (`28/28` files, `255/255` tests)
- backend `npm run build`
- `git diff --check`

## Follow-up

- `apple-notifications` still decodes Apple JWS payloads without certificate-chain signature verification; that remains a real Phase 3 hardening item, but it is already called out in code/docs and is separate from this idempotency fix.
- Alias and restore surfaces (`/api/iap/verify`, `/api/iap/restore`, `/api/iap/restore-purchases`) still need their own file-by-file pass.
