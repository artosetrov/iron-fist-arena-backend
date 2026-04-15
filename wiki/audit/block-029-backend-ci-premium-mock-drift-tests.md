---
title: Audit Block 029 — Backend CI Premium Mock Drift Tests
category: audit
tags: [audit, backend, ci, tests, premium, vitest]
sources:
  - .github/workflows/ci.yml
  - backend/tests/api/pvp-resolve.test.ts
  - backend/tests/api/dungeon-rush-resolve.test.ts
  - backend/src/lib/game/premium.ts
updated: 2026-04-15
---

# Audit Block 029 — Backend CI Premium Mock Drift Tests

## Scope

This block was triggered by a real GitHub Actions failure after Vercel had already gone green. The important distinction was environmental scope:

- Vercel validated backend production build.
- GitHub Actions validated backend tests, balance docs, admin build, and schema drift.

The production build blocker had already been fixed in [[block-028-backend-contraband-reward-contract-build-fix]], but CI still failed because two backend route tests mocked `@/lib/game/premium` too narrowly.

- **Files audited in this block:** 4
- **Primary file types:** CI workflow, backend route tests, shared premium helper
- **Status:** GitHub-only failure reproduced locally and fixed by aligning test mocks with the current premium contract
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-028-backend-contraband-reward-contract-build-fix]], [[block-013-backend-reward-premium-parity]], [[interactive-combat]]

## Summary

- `backend/src/lib/game/premium.ts` now exports `PREMIUM_ENTITLEMENT_USER_SELECT`.
- `pvp/resolve` and `dungeon-rush/resolve` import that constant in runtime code.
- Their Vitest files still mocked only `goldBonusMultiplier`, so route imports failed inside tests and returned 500.
- After fixing that mock drift, one test still failed because its transaction mock had not kept up with the newer `grantRewardEntries(...)` contract.
- Once both mocks were aligned, the entire backend test suite passed again.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | GitHub CI ran `vitest`, but the premium module mocks in two route tests no longer matched the runtime module exports. | Backend CI stayed red even though Vercel production build was green, creating a confusing “works in deploy, fails in Actions” state. | Added `PREMIUM_ENTITLEMENT_USER_SELECT` to the mocked premium module in both tests. |
| P1 | `dungeon-rush-resolve` test used a stale transaction mock after the route moved onto shared `grantRewardEntries(...)`. | Test still failed with `tx.$queryRaw is not a function`, masking the actual route behavior under an outdated mock shape. | Extended the test transaction mock with the minimal `grantRewardEntries` contract: `$queryRaw`, `character.findUnique`, and `user.findUnique`. |
| P2 | CI signal was easy to misread because Vercel and GitHub were validating different surfaces. | Time can be wasted debugging build config instead of the actual failing step. | Reconfirmed the exact GitHub workflow steps from `.github/workflows/ci.yml` and verified that only the Vitest step was red. |

## Cross-File Safe Fixes Applied

- `backend/tests/api/pvp-resolve.test.ts`
  - mock for `@/lib/game/premium` now exports `PREMIUM_ENTITLEMENT_USER_SELECT` alongside `goldBonusMultiplier`.
- `backend/tests/api/dungeon-rush-resolve.test.ts`
  - same premium mock export added,
  - transaction mock updated for the current shared reward-grant path.
- `.github/workflows/ci.yml`
  - re-audited; no workflow code change needed because the workflow itself was correct.
- `backend/src/lib/game/premium.ts`
  - re-audited as the shared contract source; no runtime change needed.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `.github/workflows/ci.yml` | CI workflow | Defines GitHub Actions checks for backend/admin/schema drift. | Used by pushes and PRs touching backend/admin/scripts/workflow/docs balance files. | CI validates more than Vercel: tests, docs drift, admin build, and schema sync. | Re-verified that the failing step was `backend vitest`, not build/deploy config. | OK |
| `backend/tests/api/pvp-resolve.test.ts` | Backend API test | Verifies PvP resolve idempotency and battle-ticket consumption behavior. | Imports `POST` route and mocks auth/prisma/game helpers. | Route tests that mock a module must keep parity with its exported contract. | Added missing mocked `PREMIUM_ENTITLEMENT_USER_SELECT`. | Fixed |
| `backend/tests/api/dungeon-rush-resolve.test.ts` | Backend API test | Verifies stale dungeon-rush room resolves do not double-pay out rewards. | Imports `POST` route and mocks auth/prisma/game helpers. | Transaction mocks must follow the live route contract, especially after shared reward runtime changes. | Added missing premium export plus reward-grant-compatible transaction mock methods. | Fixed |
| `backend/src/lib/game/premium.ts` | Shared premium helper | Canonical premium entitlement selection and reward helpers. | Used by PvP, dungeon rush, daily login, shop/reward routes, and tests via mocks. | Tests should either partially import or fully mirror all accessed exports. | No code change; re-affirmed as the source-of-truth contract that tests must track. | OK |

## Duplicate / Split Logic Found

- The real drift here was between runtime contract and test contract, not between two runtime implementations.
- This is the same family of issue as other audit findings where typed contracts evolve safely in production code but stale mocks keep pretending the old surface still exists.

## Files Without Clear Current Role

- None in this block.

## Candidates For Refactor

- If more tests begin mocking `premium.ts`, consider a shared test helper for the canonical premium mock shape so future exports do not require multi-file manual cleanup.

## Documentation Missing Or Stale

- No product/docs drift here. The stale layer was the test harness.

## Requires Separate Decision

- No product decision needed.

## Verification

- `npx vitest run tests/api/pvp-resolve.test.ts tests/api/dungeon-rush-resolve.test.ts` passes in `backend/`.
- `npx vitest run` passes in `backend/` with `26/26` test files and `236/236` tests green.
- Earlier verification in the same debugging pass also confirmed:
  - `npm run docs:balance:check` passes in `backend/`
  - `npx next build` passes in `admin/`
  - `python3 scripts/check_schema_drift.py` passes
  - `diff backend/prisma/schema.prisma admin/prisma/schema.prisma` returns clean
  - `npm run build` passes in `backend/`
