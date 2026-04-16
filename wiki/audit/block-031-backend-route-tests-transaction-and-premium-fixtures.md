---
title: Audit Block 031 — Backend Route Tests Transaction and Premium Fixtures
category: audit
tags: [audit, backend, tests, vitest, premium, transactions]
sources:
  - backend/tests/api/pvp-resolve.test.ts
  - backend/tests/api/dungeon-rush-resolve.test.ts
  - backend/tests/api/shop-buy.test.ts
  - backend/tests/api/inventory-sell.test.ts
  - backend/tests/api/battle-pass-claim.test.ts
updated: 2026-04-15
---

# Audit Block 031 — Backend Route Tests Transaction and Premium Fixtures

## Scope

This block continues the backend test audit after [[block-030-backend-ci-contract-hardening-and-actions-upgrade]]. Once the premium mocks were hardened, the next adjacent cleanup was the route-test fixture layer itself:

- premium fixture shapes,
- transaction callback typing,
- and raw `any` hiding useful contract information in shop/inventory tests.

- **Files audited in this block:** 5
- **Primary file types:** backend API route regression tests
- **Status:** transaction mocks are typed more honestly, premium fixture shape is aligned with runtime, and route tests remain green
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-030-backend-ci-contract-hardening-and-actions-upgrade]], [[block-029-backend-ci-premium-mock-drift-tests]]

## Summary

- `pvp-resolve` still carried the old premium fixture shape even after the premium selector moved beyond `premiumUntil`.
- `pvp-resolve`, `dungeon-rush-resolve`, `shop-buy`, and `inventory-sell` all had route-transaction callback mocks typed as `any`.
- `shop-buy` also used an `inventoryItem?: any` escape hatch in a helper where the actual shape is small and stable enough to type directly.
- These were not runtime bugs, but they reduced the value of the tests as architectural guards.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P2 | `pvp-resolve` test fixture still modeled premium user data as `premiumUntil` only. | Future entitlement-selector changes could look “compatible” in tests while already diverging from the live route contract. | Updated the fixture to include `premiumSubscription: null` and clarified the intent. |
| P2 | Several route tests used `callback: any` for mocked transactions. | `any` hides drift in transaction shape and weakens the tests exactly where they should describe route contracts most clearly. | Replaced `any` transaction callback types with concrete `typeof tx` / `ReturnType<typeof makeTx>` signatures. |
| P3 | `shop-buy` helper accepted `inventoryItem?: any`. | Minor type escape hatch around a stable fixture shape makes later fixture drift easier to miss. | Replaced with a typed minimal inventory-item shape and added a typed `mockTransaction(...)` helper. |

## Cross-File Safe Fixes Applied

- `backend/tests/api/pvp-resolve.test.ts`
  - aligned premium user fixture with the current shared selector shape
  - typed the mocked `$transaction` callback
- `backend/tests/api/dungeon-rush-resolve.test.ts`
  - typed the mocked `$transaction` callback
- `backend/tests/api/shop-buy.test.ts`
  - replaced `inventoryItem?: any` with a typed fixture shape
  - added a typed `mockTransaction(...)` helper
- `backend/tests/api/inventory-sell.test.ts`
  - added a typed `mockTransaction(...)` helper and removed repeated `callback: any` usage
- `backend/tests/api/battle-pass-claim.test.ts`
  - re-audited as still valid after the surrounding test-fixture cleanup; no code change needed in this pass

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/tests/api/pvp-resolve.test.ts` | Backend route test | Guards ticket consumption and replay-safe PvP resolve behavior. | Depends on mocked auth/prisma/combat/premium helpers. | Test fixtures should match the live route’s premium entitlement shape. | Added `premiumSubscription: null` and typed the transaction callback. | Fixed |
| `backend/tests/api/dungeon-rush-resolve.test.ts` | Backend route test | Guards stale-room replay safety in Dungeon Rush resolve. | Depends on mocked auth/prisma/guild/premium/reward-grant interactions. | Transaction mocks should describe the real shared reward runtime shape instead of hiding behind `any`. | Typed the transaction callback after the earlier reward-grant mock update. | Fixed |
| `backend/tests/api/shop-buy.test.ts` | Backend route test | Guards account-gold purchase flow, inventory capacity, and ownership checks in shop buy. | Depends on mocked item catalog, transaction lock row, inventory count, and user update. | Shop test helpers should make the purchased inventory shape explicit because it is returned to the client. | Replaced `inventoryItem?: any` with a typed fixture and centralized typed transaction mocking. | Fixed |
| `backend/tests/api/inventory-sell.test.ts` | Backend route test | Guards item-selling ownership, equipped-item protection, and sell-price math. | Depends on mocked inventory lock row, character ownership, item sell price, and user gold update. | Transaction mock typing should stay close to route expectations. | Centralized typed transaction mocking and removed repeated `callback: any`. | Fixed |
| `backend/tests/api/battle-pass-claim.test.ts` | Backend route test | Guards rollback behavior when battle-pass reward config is invalid. | Depends on mocked season/character locks and reward rows. | Invalid config path should fail without partial rewards or claim rows. | Re-audited; still valid and already typed well enough for its narrow rollback target. | OK |

## Duplicate / Split Logic Found

- `shop-buy` and `inventory-sell` both carried the same pattern of ad hoc transaction-mock wiring. This block does not merge them across files yet, but each file now at least uses a typed local helper instead of repeated `any` callbacks.

## Files Without Clear Current Role

- None in this block.

## Candidates For Refactor

- If more route tests start modeling transaction-heavy shared reward flows, a tiny `backend/tests/helpers/transaction-mocks.ts` could be worthwhile so the same typed helper pattern does not get re-copied file by file. Current audit decision: keep these transaction helpers local until the file-by-file pass is complete, then evaluate extraction with full repo context.
- Several backend route tests still cast `Request` to `any`; that is a lower-priority cleanup candidate once the transaction/mock contract layer is fully settled.

## Documentation Missing Or Stale

- No product-doc drift here; the stale layer was entirely in the tests.

## Requires Separate Decision

- Resolved during audit: keep transaction helpers local until the file-by-file pass is complete; do not extract a shared transaction-helper layer yet.

## Verification

- `npx vitest run` passes in `backend/` with `26/26` files and `236/236` tests green after the fixture cleanup.
- `git diff --check` passes after the edits.
