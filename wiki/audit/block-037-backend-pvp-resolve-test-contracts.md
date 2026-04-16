---
title: Block 037 — Backend PvP resolve test contracts
category: audit
tags: [audit, backend, tests, pvp, anti-cheat, stamina]
sources:
  - backend/tests/api/pvp-resolve.test.ts
  - backend/src/app/api/pvp/resolve/route.ts
updated: 2026-04-15
status: Fixed
---

# Block 037 — Backend PvP resolve test contracts

## Scope

- `backend/tests/api/pvp-resolve.test.ts`
- `backend/src/app/api/pvp/resolve/route.ts`

## Why this block

`pvp-resolve` is one of the heavier backend routes: anti-cheat verification, ticket locking, stamina revalidation, rewards, ranking, quests, battle pass, loot, and bot-fight special handling.

Before this pass the test file only protected one branch: replayed battle-ticket rejection. That was useful, but too narrow for a route with this much state and concurrency logic.

## File notes

### `backend/tests/api/pvp-resolve.test.ts`

- **Zone:** backend / PvP / tests
- **Purpose:** verifies server-authoritative PvP resolve behavior
- **What it does now:** covers replayed ticket rejection, client/server winner mismatch handling, locked-row stamina TOCTOU protection, battle-ticket mismatch rejection, and bot-ticket guard behavior
- **Depends on:** auth, rate limit, combat engine, stamina, ELO, battle pass, achievements, durability, battle mail, premium helper, and Prisma transaction mocks
- **Used by:** Vitest backend API test suite
- **Main issues found:**
  - one-test file guarding only the replay branch
  - no direct coverage for the anti-cheat `client_matches: false` contract
  - no direct coverage for the locked-row stamina recheck that protects against race conditions
  - no test for bot-ticket validation in the special bot-fight branch
- **What was fixed:**
  - added a local transaction helper to keep fixture logic readable without extracting shared transaction helpers
  - added authoritative success-path assertions for mismatched client winner reports
  - added locked-stamina rejection coverage to protect the TOCTOU guard
  - added battle-ticket mismatch and invalid bot-ticket guard coverage
- **Status:** Fixed

### `backend/src/app/api/pvp/resolve/route.ts`

- **Zone:** backend / PvP / runtime
- **Purpose:** replays combat server-side, validates the resolve request, atomically spends resources, persists match results, and runs post-match side effects
- **Key business rules in this slice:**
  - the server result wins if the client reports the wrong winner
  - the battle ticket must match the exact prepared fight and can only be consumed once
  - stamina is revalidated under lock before spending it
  - bot fights use a signed hash-style ticket instead of a DB battle-ticket row
- **Status:** Fixed

## Problems found

1. **Thin test surface on a high-risk route**
   - Risk: concurrency or anti-cheat regressions slip through while the route still appears “covered”.
   - Fix: add focused tests around the actual guard rails.

2. **Missing TOCTOU stamina coverage**
   - Risk: a race between prepare-time optimism and resolve-time state could allow extra fights or produce unstable failures.
   - Fix: add a locked-row stamina test that proves the transaction-time recheck wins.

3. **Missing bot-ticket guard coverage**
   - Risk: a regression in the bot-fight special path could bypass the intended ticket validation.
   - Fix: add an explicit invalid bot-ticket test.

## Verification

- `npx vitest run tests/api/pvp-resolve.test.ts`
- `npx vitest run`
- `git diff --check`

## Follow-up

- The remaining backend API route tests are now much less lopsided; after this, the next logical pass is to revisit any remaining one-test files or shift into backend runtime files outside `backend/tests/api`.
