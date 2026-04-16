---
title: Audit Block 033 — Backend API Tests Request Cast Elimination
category: audit
tags: [audit, backend, tests, vitest, nextrequest, cleanup]
sources:
  - backend/tests/helpers/next-request.ts
  - backend/tests/api/shop-buy.test.ts
  - backend/tests/api/inventory-sell.test.ts
  - backend/tests/api/pvp-resolve.test.ts
  - backend/tests/api/dungeon-rush-resolve.test.ts
  - backend/tests/api/pvp-prepare-bot-ticket.test.ts
updated: 2026-04-15
---

# Audit Block 033 — Backend API Tests Request Cast Elimination

## Scope

This block finishes the immediate follow-up to [[block-032-backend-api-tests-nextrequest-helper]]. After introducing the shared `makeNextRequest(...)` helper, the remaining obvious cleanup target was the last cluster of API route tests still calling App Router handlers via `new Request(...) as any`.

- **Files audited in this block:** 5 backend API tests
- **Primary file types:** backend route regression tests
- **Status:** remaining live API tests in this slice no longer rely on `Request as any`, and the touched route-test subset plus full backend suite stay green
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-032-backend-api-tests-nextrequest-helper]], [[block-031-backend-route-tests-transaction-and-premium-fixtures]]

## Summary

- `shop-buy`, `inventory-sell`, `pvp-resolve`, `dungeon-rush-resolve`, and `pvp-prepare-bot-ticket` still carried the older request-cast pattern.
- Those tests already had the right business assertions; the weak point was the request boundary itself.
- Moving them onto the shared `NextRequest` helper removes the last obvious mismatch between those tests and the actual route signatures.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P2 | Several core backend API tests still used `new Request(...) as any` despite the new shared helper existing. | Mixed patterns make the test layer harder to trust and encourage future copy-paste of the weaker approach. | Migrated the remaining touched tests to `makeNextRequest(...)`. |
| P2 | `pvp-prepare-bot-ticket` still cast its request as `never` to satisfy the route call. | Another small boundary mismatch that hides the real handler input type. | Switched the test to pass a real `NextRequest` from the shared helper. |

## Cross-File Safe Fixes Applied

- Moved these tests onto the shared request helper:
  - [shop-buy.test.ts](/Users/artosetrov/Documents/Cursor%20AI/PVP%20RPG/backend/tests/api/shop-buy.test.ts)
  - [inventory-sell.test.ts](/Users/artosetrov/Documents/Cursor%20AI/PVP%20RPG/backend/tests/api/inventory-sell.test.ts)
  - [pvp-resolve.test.ts](/Users/artosetrov/Documents/Cursor%20AI/PVP%20RPG/backend/tests/api/pvp-resolve.test.ts)
  - [dungeon-rush-resolve.test.ts](/Users/artosetrov/Documents/Cursor%20AI/PVP%20RPG/backend/tests/api/dungeon-rush-resolve.test.ts)
  - [pvp-prepare-bot-ticket.test.ts](/Users/artosetrov/Documents/Cursor%20AI/PVP%20RPG/backend/tests/api/pvp-prepare-bot-ticket.test.ts)
- Re-checked the `backend/tests/api` tree for the specific `Request as any` smell after the migration.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/tests/api/shop-buy.test.ts` | Backend route test | Guards shop item purchase flow, ownership, inventory cap, and gold deduction. | Depends on auth, item catalog, transaction lock row, and quest progress mocks. | Route tests should call handlers with the same request class the runtime receives. | Replaced the remaining request casts with `makeNextRequest(...)`. | Fixed |
| `backend/tests/api/inventory-sell.test.ts` | Backend route test | Guards item selling, ownership, equipped-item rejection, and sell-price math. | Depends on inventory lock row, character ownership, item data, and user gold update mocks. | Same route-boundary rule as other API tests. | Replaced the remaining request casts with `makeNextRequest(...)`. | Fixed |
| `backend/tests/api/pvp-resolve.test.ts` | Backend route test | Guards ticket consumption and replay safety in PvP resolve. | Depends on mocked combat/runtime helpers and transaction fixtures. | Replay-safety tests should also use the real request type at the handler boundary. | Replaced the remaining request casts with `makeNextRequest(...)`. | Fixed |
| `backend/tests/api/dungeon-rush-resolve.test.ts` | Backend route test | Guards stale-room replay safety in Dungeon Rush resolve. | Depends on auth/prisma/guild/reward fixtures and transaction lock behavior. | Same boundary rule as PvP resolve. | Replaced the remaining request casts with `makeNextRequest(...)`. | Fixed |
| `backend/tests/api/pvp-prepare-bot-ticket.test.ts` | Backend route test | Guards graceful degradation when bot ticket secret is absent. | Depends on auth/rate-limit/combat loader/bot helpers. | Tests should not rely on `as never` to satisfy a route signature that can be modeled directly. | Replaced the old request cast with the shared helper. | Fixed |

## Duplicate / Split Logic Found

- Before this block, the `NextRequest` helper existed but was only partially adopted. This block removes that split for the remaining touched live API tests.

## Files Without Clear Current Role

- None in this block.

## Candidates For Refactor

- `backend/tests/api` is now much cleaner on request-boundary typing, but some tests still rely on direct fixture duplication for transaction rows and rate-limit wiring. That stays a future helper-extraction candidate only after the file-by-file pass is complete; current audit decision is to keep those helpers local for now.

## Documentation Missing Or Stale

- No docs drift here; this is test-infrastructure cleanup.

## Requires Separate Decision

- No product decision needed.

## Verification

- `rg -n "\\) as any,?$|Request as any|new Request\\(" backend/tests/api -g '*.test.ts'` no longer finds the old cast pattern in this API test slice.
- `npx vitest run tests/api/shop-buy.test.ts tests/api/inventory-sell.test.ts tests/api/pvp-resolve.test.ts tests/api/dungeon-rush-resolve.test.ts tests/api/pvp-prepare-bot-ticket.test.ts` passes in `backend/`.
- Full `npx vitest run` passes in `backend/` with `26/26` files and `236/236` tests green.
- `git diff --check` passes after the cleanup.
