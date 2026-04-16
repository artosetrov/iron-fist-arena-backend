---
title: Block 035 — Backend battle-pass claim test contracts
category: audit
tags: [audit, backend, tests, battle-pass, rewards, progression]
sources:
  - backend/tests/api/battle-pass-claim.test.ts
  - backend/src/app/api/battle-pass/claim/[level]/route.ts
updated: 2026-04-15
status: Fixed
---

# Block 035 — Backend battle-pass claim test contracts

## Scope

- `backend/tests/api/battle-pass-claim.test.ts`
- `backend/src/app/api/battle-pass/claim/[level]/route.ts`

## Why this block

This file had become one of the thinnest API tests in the backend suite:

- only one test remained
- the test still mocked `applyLevelUp`, even though the route no longer uses that runtime path
- several important claim branches were unprotected: level gate, no-claimable state, and success response shape

That is a classic contract-drift smell: the route evolves, the test still looks busy, but it is no longer guarding the right thing.

## File notes

### `backend/tests/api/battle-pass-claim.test.ts`

- **Zone:** backend / battle pass / tests
- **Purpose:** verifies reward claim behavior for `POST /api/battle-pass/claim/[level]`
- **What it does:** now covers invalid reward config rollback, level-not-reached rejection, no-claimable-rewards rejection, and successful claim response with cache invalidation on level-up
- **Depends on:** auth, rate limit, stamina calc, shared reward grants, reward display labels, cache invalidators, Prisma transaction mocks
- **Used by:** Vitest backend API test suite
- **Main issues found:**
  - stale mock for `applyLevelUp` from an older claim flow
  - only a single rollback test despite a multi-branch route
  - no direct assertions around the new shared `grantRewardEntries(...)` contract
- **What was fixed:**
  - removed the dead progression mock
  - mocked the actual current collaborators: `grantRewardEntries`, `invalidateSkillCache`, `invalidatePassiveCache`
  - added focused local transaction fixtures for the important route branches
- **Status:** Fixed

### `backend/src/app/api/battle-pass/claim/[level]/route.ts`

- **Zone:** backend / battle pass / runtime
- **Purpose:** validates eligibility, claims the correct reward rows atomically, applies reward grants, stamina rewards, cosmetics, and cache invalidation
- **Key business rules in this slice:**
  - claim only if the requested battle-pass level has been reached
  - premium rewards require premium entitlement on the battle-pass row
  - already claimed or unavailable rewards collapse to a single no-claimable response
  - invalid reward config must fail atomically with no partial payouts
  - level-up side effects invalidate skill/passive caches after the transaction
- **Test outcome:** the current contract is now covered in a way that matches the real runtime collaborators
- **Status:** Fixed

## Problems found

1. **Stale test dependency on old progression path**
   - Risk: test stays green while the real reward-grant contract drifts.
   - Fix: swap from dead `applyLevelUp` mocking to `grantRewardEntries(...)` and cache invalidator mocks.

2. **Thin branch coverage on a transaction-heavy route**
   - Risk: regressions around level gating, premium filtering, or success payload shape escape unnoticed.
   - Fix: add direct tests for the main decision points.

3. **Success path lacked cache invalidation assertions**
   - Risk: future refactors could silently drop post-level-up cache invalidation.
   - Fix: assert both cache invalidators run after a leveled-up claim.

## Verification

- `npx vitest run tests/api/battle-pass-claim.test.ts`
- `npx vitest run`
- `git diff --check`

## Follow-up

- Continue through the remaining single-test backend route files (`pvp-resolve`, `dungeon-rush-resolve`) with the same “runtime contract first” approach.
