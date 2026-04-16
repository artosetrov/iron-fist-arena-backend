---
title: Audit Block 030 — Backend CI Contract Hardening and Actions Upgrade
category: audit
tags: [audit, backend, ci, tests, github-actions, premium, contracts]
sources:
  - .github/workflows/ci.yml
  - backend/tests/api/pvp-resolve.test.ts
  - backend/tests/api/dungeon-rush-resolve.test.ts
  - backend/src/lib/game/premium.ts
updated: 2026-04-15
---

# Audit Block 030 — Backend CI Contract Hardening and Actions Upgrade

## Scope

This block follows [[block-029-backend-ci-premium-mock-drift-tests]]. Block 029 made GitHub CI green again. This pass hardens the same surface so the same class of break is less likely to come back:

1. stop test mocks from drifting every time `premium.ts` gains a new export;
2. remove the GitHub Actions deprecation warnings caused by `actions/*@v4`.

- **Files audited in this block:** 4
- **Primary file types:** backend API tests, CI workflow, shared premium contract source
- **Status:** tests now use safer partial mocks, CI workflow upgraded off deprecated `actions/*@v4`, and the full local CI-equivalent suite still passes
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-029-backend-ci-premium-mock-drift-tests]], [[block-013-backend-reward-premium-parity]]

## Summary

- `pvp-resolve` and `dungeon-rush-resolve` no longer hand-maintain a fake `premium.ts` export list.
- Both tests now partially import the real premium module and override only `goldBonusMultiplier`.
- That means future additions like `PREMIUM_ENTITLEMENT_USER_SELECT` do not require another emergency test patch.
- The GitHub workflow now uses `actions/checkout@v5` and `actions/setup-node@v5`, removing the runner deprecation warnings shown in Actions.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Premium module mocks in backend route tests were manual full mocks. | Every new export in `premium.ts` risked silently breaking CI again. | Switched both route tests to partial mocks via `importOriginal`, overriding only the behavior under test. |
| P2 | Dungeon Rush test still described the selected user fields as if only `premiumUntil` mattered. | The comment and fixture shape encouraged future drift away from the shared premium selector. | Updated the test fixture/comment so it reflects the current premium entitlement shape more honestly. |
| P2 | GitHub Actions still used deprecated `actions/checkout@v4` and `actions/setup-node@v4`. | CI stayed noisy with deprecation warnings and would eventually require a rushed migration. | Upgraded the workflow to `@v5` for checkout and setup-node. |

## Cross-File Safe Fixes Applied

- `.github/workflows/ci.yml`
  - upgraded `actions/checkout` from `v4` to `v5`
  - upgraded `actions/setup-node` from `v4` to `v5`
- `backend/tests/api/pvp-resolve.test.ts`
  - premium mock now uses `importOriginal` partial mocking
- `backend/tests/api/dungeon-rush-resolve.test.ts`
  - same partial mock pattern
  - fixture/comment updated so the mocked user shape stays aligned with the shared entitlement selector
- `backend/src/lib/game/premium.ts`
  - re-audited as the shared contract that test mocks should inherit from instead of recreating

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `.github/workflows/ci.yml` | CI workflow | Runs backend tests/build checks, admin build, and Prisma drift checks in GitHub Actions. | Used on `push`/`pull_request` for backend/admin/scripts/workflow/balance-doc changes. | CI should stay both green and maintainable; avoid deprecated runner actions when a safe major upgrade exists. | Upgraded workflow actions from `v4` to `v5`. | Fixed |
| `backend/tests/api/pvp-resolve.test.ts` | Backend route test | Verifies battle-ticket consumption and replay safety in PvP resolve. | Imports route runtime and mocks supporting modules. | Tests should inherit shared module exports unless they truly need to replace them. | Converted premium mock from fragile full replacement to partial mock. | Fixed |
| `backend/tests/api/dungeon-rush-resolve.test.ts` | Backend route test | Verifies stale rush-room resolves do not double-grant rewards. | Imports route runtime and mocks supporting modules. | Shared contract mocks should stay close to real runtime exports and reward-grant transaction shape. | Converted premium mock to partial mock and clarified entitlement fixture shape. | Fixed |
| `backend/src/lib/game/premium.ts` | Shared premium contract helper | Defines premium selector and reward/entitlement helpers across backend runtime. | Used by reward routes and their tests. | Runtime contract should be inherited by tests instead of copy-pasted into mocks. | No code change; used as the canonical module surface for safer partial mocks. | OK |

## Duplicate / Split Logic Found

- The previous problem was duplicated contract knowledge inside tests. Partial mocks remove that duplication for the premium module.
- Shared reward transaction behavior is still hand-built in some tests, but the highest-risk premium export drift is now removed.

## Files Without Clear Current Role

- None in this block.

## Candidates For Refactor

- If more route tests start hitting `grantRewardEntries(...)`, consider a small shared backend test helper for reward-grant-capable transaction mocks so those fixtures do not drift one-by-one.

## Documentation Missing Or Stale

- No product docs were stale here. The drift lived in tests and workflow config.

## Requires Separate Decision

- No product decision needed.

## Verification

- `npx vitest run` passes in `backend/` with `26/26` files and `236/236` tests green.
- `npm run docs:balance:check` passes in `backend/`.
- `npm run build` passes in `backend/`.
- `npx next build` passes in `admin/`.
- `diff backend/prisma/schema.prisma admin/prisma/schema.prisma` returns clean.
- `python3 scripts/check_schema_drift.py` passes.
