---
title: Block 034 — Backend auth, bot-ticket, shell-game, and stamina-refill guardrail tests
category: audit
tags: [audit, backend, tests, auth, pvp, minigames, stamina]
sources:
  - backend/tests/api/auth-login.test.ts
  - backend/tests/api/auth-register.test.ts
  - backend/tests/api/pvp-prepare-bot-ticket.test.ts
  - backend/tests/api/shell-game-start.test.ts
  - backend/tests/api/stamina-refill.test.ts
  - backend/src/app/api/auth/login/route.ts
  - backend/src/app/api/auth/register/route.ts
  - backend/src/app/api/pvp/prepare/route.ts
  - backend/src/app/api/minigames/shell-game/start/route.ts
  - backend/src/app/api/stamina/refill/route.ts
updated: 2026-04-15
status: Fixed
---

# Block 034 — Backend auth, bot-ticket, shell-game, and stamina-refill guardrail tests

## Scope

- `backend/tests/api/auth-login.test.ts`
- `backend/tests/api/auth-register.test.ts`
- `backend/tests/api/pvp-prepare-bot-ticket.test.ts`
- `backend/tests/api/shell-game-start.test.ts`
- `backend/tests/api/stamina-refill.test.ts`
- supporting runtime routes for login/register, PvP prepare, shell-game start, and stamina refill

## Why this block

After the request-boundary cleanup, this next slice still had several thin or brittle areas:

- `auth-login.test.ts` still used an odd `vi.hoisted(...)` call inside a test body just to get at the shared Supabase mock.
- `auth-register` had no direct test for the runtime email-format guard.
- `pvp-prepare-bot-ticket` only covered the missing-secret degradation path, not the happy path that issues hashed bot tickets.
- `shell-game-start` covered the main success flow, but not the guard rails that stop daily-limit or insufficient-gold regressions.
- `stamina-refill` covered the base refill path, but not the newer diminishing-returns and daily-cap rules.

These are exactly the sort of small, high-value branches that quietly drift while the runtime evolves.

## File notes

### `backend/tests/api/auth-login.test.ts`

- **Zone:** backend / auth / tests
- **Purpose:** verifies login route behavior against Supabase + Prisma mocks
- **What it does:** covers missing credentials, rate limiting, invalid credentials, happy path, and auto-confirm retry
- **Depends on:** `createAdminClient`, `rateLimit`, Prisma user mocks, `makeNextRequest(...)`
- **Used by:** Vitest backend API test suite
- **Key issue found:** one test re-entered `vi.hoisted(...)` from inside the test body. It worked accidentally, but made the fixture ownership harder to understand.
- **What was fixed:** replaced that inline hoisted call with the normal shared mock client path.
- **Status:** Fixed

### `backend/tests/api/auth-register.test.ts`

- **Zone:** backend / auth / tests
- **Purpose:** verifies register route validation and Supabase registration flow
- **What it does:** covers missing inputs, weak password, rate limit, duplicate email, successful registration, and username fallback
- **Depends on:** `createAdminClient`, `rateLimit`, Prisma user mocks, `makeNextRequest(...)`
- **Used by:** Vitest backend API test suite
- **Key issue found:** the runtime had an explicit invalid-email guard, but there was no direct test for it.
- **What was fixed:** added explicit coverage for malformed email rejection.
- **Status:** Fixed

### `backend/tests/api/pvp-prepare-bot-ticket.test.ts`

- **Zone:** backend / PvP prepare / tests
- **Purpose:** verifies bot-fight ticket issuance behavior
- **What it does:** exercises bot-fight prepare requests against mocked stamina/combat loaders
- **Depends on:** auth, rate limit, stamina, combat-loader, NPC bot helpers, live config, bot-ticket helper
- **Used by:** Vitest backend API test suite
- **Key issue found:** only the missing-secret failure branch was protected; the success path for hashed bot ticket issuance was untested.
- **What was fixed:** added a bot-fight happy-path test that verifies a hashed `bot_...` ticket is issued and marked as a bot fight.
- **Status:** Fixed

### `backend/tests/api/shell-game-start.test.ts`

- **Zone:** backend / minigames / shell game / tests
- **Purpose:** verifies the locked two-step shell-game session creation flow
- **What it does:** checks session creation, gold deduction, and session secrecy
- **Depends on:** auth, rate limit, Prisma minigame transaction mocks, daily/weekly quest progress helpers
- **Used by:** Vitest backend API test suite
- **Key issue found:** daily-limit and insufficient-gold guard rails were not covered directly.
- **What was fixed:** added tests for daily-limit rejection and locked insufficient-gold rejection without session creation.
- **Status:** Fixed

### `backend/tests/api/stamina-refill.test.ts`

- **Zone:** backend / stamina / tests
- **Purpose:** verifies gem-based stamina refill logic
- **What it does:** covers ownership, not-found, full-stamina, not-enough-gems, and successful refill
- **Depends on:** auth, rate limit, stamina calc, live config, transaction row locks
- **Used by:** Vitest backend API test suite
- **Key issue found:** the W3.D4 refill diminishing returns and hard daily cap had almost no direct regression coverage.
- **What was fixed:** added direct tests for second-refill escalated cost and daily-cap rejection.
- **Status:** Fixed

## Problems found

1. **Brittle auth fixture access**
   - Risk: future fixture refactors become confusing because test-local `vi.hoisted(...)` hides where the real mock object comes from.
   - Fix: use the existing shared mocked client directly.

2. **Missing bot-ticket success coverage**
   - Risk: a regression in hashed bot ticket issuance could slip through while only the degraded path stays green.
   - Fix: verify the happy path with `BOT_TICKET_SECRET` set.

3. **Missing shell-game guard-rail coverage**
   - Risk: daily-limit or insufficient-gold regressions could turn into economy exploits or noisy 500s.
   - Fix: add dedicated rejection-path tests.

4. **Missing stamina-refill DR coverage**
   - Risk: the newer economy rules around escalating refill cost and hard cap could silently drift from runtime.
   - Fix: add direct tests for both branches.

## Verification

- `npx vitest run tests/api/auth-login.test.ts tests/api/auth-register.test.ts tests/api/pvp-prepare-bot-ticket.test.ts tests/api/shell-game-start.test.ts tests/api/stamina-refill.test.ts`
- `npx vitest run`
- `git diff --check`

## Follow-up

- Keep transaction helpers local until the end of the file-by-file pass, per audit policy for this phase.
- Continue through the remaining backend API tests in the same style: one file at a time, adding branch coverage where runtime guards have drifted ahead of tests.
