---
title: Block 036 — Backend dungeon-rush resolve test contracts
category: audit
tags: [audit, backend, tests, dungeon-rush, rewards]
sources:
  - backend/tests/api/dungeon-rush-resolve.test.ts
  - backend/src/app/api/dungeon-rush/resolve/route.ts
updated: 2026-04-15
status: Fixed
---

# Block 036 — Backend dungeon-rush resolve test contracts

## Scope

- `backend/tests/api/dungeon-rush-resolve.test.ts`
- `backend/src/app/api/dungeon-rush/resolve/route.ts`

## Why this block

This test had the same drift pattern we just fixed in `battle-pass-claim`:

- only one test existed
- the file still mocked an old `getBattlePassConfig` dependency that the route no longer imports
- the replay test implicitly depended on the real shared `grantRewardEntries(...)` helper instead of clearly mocking the current reward contract boundary

That made the test look broader than it really was.

## File notes

### `backend/tests/api/dungeon-rush-resolve.test.ts`

- **Zone:** backend / dungeon rush / tests
- **Purpose:** verifies non-combat room resolution behavior
- **What it does now:** covers stale-room replay protection and leveled-up success behavior with explicit shared reward-grant and cache invalidation mocks
- **Depends on:** auth, rate limit, guild challenges, premium gold multiplier, dungeon-run locking, shared reward grants, combat cache invalidators
- **Used by:** Vitest backend API test suite
- **Main issues found:**
  - stale mock for `getBattlePassConfig`
  - replay test leaned on real reward helper behavior instead of a clear boundary mock
  - no direct assertion that leveled-up room rewards invalidate combat caches
- **What was fixed:**
  - removed the dead live-config mock
  - mocked `grantRewardEntries(...)` explicitly
  - added a success-path test that asserts cache invalidation and guild challenge incrementing
- **Status:** Fixed

### `backend/src/app/api/dungeon-rush/resolve/route.ts`

- **Zone:** backend / dungeon rush / runtime
- **Purpose:** resolves non-combat rush rooms under lock, grants rewards, advances run state, and invalidates combat caches after level-up
- **Key business rules in this slice:**
  - stale or already-resolved room requests must fail with a conflict response
  - room reward grants must happen from the locked run snapshot
  - gold earned from non-combat rooms increments the guild challenge counter
  - level-up side effects invalidate skill/passive caches after the resolve completes
- **Status:** Fixed

## Problems found

1. **Stale mock for removed runtime dependency**
   - Risk: the test hides real collaborator drift and gives false confidence.
   - Fix: remove the dead `getBattlePassConfig` mock and align the file with current imports.

2. **Implicit dependence on real shared reward helper**
   - Risk: test intent becomes muddy and breaks for the wrong reason when shared reward logic changes.
   - Fix: mock `grantRewardEntries(...)` directly at the route boundary.

3. **Missing cache invalidation coverage after level-up**
   - Risk: future refactors could drop post-level-up invalidation without a failing test.
   - Fix: add a success-path test that asserts both invalidators run.

## Verification

- `npx vitest run tests/api/dungeon-rush-resolve.test.ts`
- `npx vitest run`
- `git diff --check`

## Follow-up

- Continue the same contract-alignment pass on the remaining one-test resolve file: `backend/tests/api/pvp-resolve.test.ts`.
