---
title: Block 043 — backend shell-game transaction and session hardening
category: audit
tags: [audit, backend, minigames, shell-game, tests]
sources:
  - backend/src/app/api/minigames/shell-game/start/route.ts
  - backend/src/app/api/minigames/shell-game/guess/route.ts
  - backend/tests/api/shell-game-start.test.ts
  - backend/tests/api/shell-game-guess.test.ts
  - backend/tests/api/shell-game-play-deprecated.test.ts
updated: 2026-04-15
status: Fixed
---

# Block 043 — backend shell-game transaction and session hardening

## Scope

- `backend/src/app/api/minigames/shell-game/start/route.ts`
- `backend/src/app/api/minigames/shell-game/guess/route.ts`
- `backend/tests/api/shell-game-start.test.ts`
- `backend/tests/api/shell-game-guess.test.ts`
- `backend/tests/api/shell-game-play-deprecated.test.ts`

## Why this block

This shell-game slice looked small from lint output, but there was still real runtime risk inside it:

1. `/shell-game/start` checked the daily play limit before the gold-deduction transaction, so two parallel requests could both pass the limit check and create one extra paid session.
2. `/shell-game/guess` still trusted `secret_data` via a blind cast from JSON, which meant a corrupted session payload could fall through as undefined behavior.
3. The live `guess` route had no focused test coverage even though it is the lock-sensitive half of the two-step game flow.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[minigames]]
- [[economy]]
- [[bug-patterns]]
- [[block-034-backend-auth-bot-minigame-guardrail-tests]]

## File notes

### `backend/src/app/api/minigames/shell-game/start/route.ts`

- **Zone:** backend / minigames
- **Purpose:** spends gold to create a locked shell-game session
- **Depends on:** `getAuthUser`, `rateLimit`, Prisma serializable transaction, daily quest and weekly challenge progression
- **Used by:** iOS tavern / shell-game start flow
- **Problems found:**
  - daily limit was checked outside the locked spend/create transaction
  - the transaction catch path still used `any`
- **What was fixed:**
  - moved the daily-limit count under the same user-row lock as gold validation and session creation
  - returned `plays_remaining` from transaction-local state instead of pre-transaction count
  - replaced the `any` catch branch with a narrow typed error shape
- **Status:** Fixed

### `backend/src/app/api/minigames/shell-game/guess/route.ts`

- **Zone:** backend / minigames
- **Purpose:** resolves the active shell-game session under a row lock
- **Depends on:** `getAuthUser`, `rateLimit`, Prisma transaction, daily/weekly/tutorial progression helpers
- **Used by:** iOS tavern / shell-game guess flow
- **Problems found:**
  - `secret_data` was still typed as `any`
  - corrupted session JSON could flow through a blind cast instead of failing explicitly
- **What was fixed:**
  - introduced a small parser for `secret_data.correctShell`
  - now returns a clear `Session state is invalid` failure when the stored session payload is corrupted
- **Status:** Fixed

### `backend/tests/api/shell-game-start.test.ts`

- **Zone:** backend tests / minigames
- **Purpose:** protects the start-route spend/session contract
- **What it covers now:**
  - daily limit rejection inside the transaction
  - active session creation without revealing the winning cup
  - insufficient gold rejection from the locked user row
- **Status:** Fixed

### `backend/tests/api/shell-game-guess.test.ts`

- **Zone:** backend tests / minigames
- **Purpose:** gives the live guess route direct coverage for the first time
- **What it covers now:**
  - successful locked guess with gold payout
  - non-active session rejection
  - corrupted session payload rejection
- **Status:** Fixed

### `backend/tests/api/shell-game-play-deprecated.test.ts`

- **Zone:** backend tests / compatibility
- **Purpose:** keeps the one-step deprecated route fenced off
- **What was verified again:** the route still returns `410` and points callers to the two-step start/guess flow
- **Status:** OK

## Problems found

1. **Daily shell-game limit had a TOCTOU gap**
   - Risk: parallel start requests could overshoot the 20/day cap and charge for an extra session.
   - Fix: moved the daily-limit count under the same serializable, locked transaction as gold deduction and session creation.

2. **Guess route trusted corrupted JSON session state**
   - Risk: malformed `secret_data` could silently behave like a loss or produce undefined payout logic.
   - Fix: added explicit parsing and a dedicated invalid-session-state failure path.

3. **Live guess route had no focused regression tests**
   - Risk: lock-sensitive gameplay logic could drift without a direct route-level signal.
   - Fix: added `shell-game-guess.test.ts`.

## Verification

- targeted backend `eslint`:
  - `src/app/api/minigames/shell-game/start/route.ts`
  - `src/app/api/minigames/shell-game/guess/route.ts`
  - `tests/api/shell-game-start.test.ts`
  - `tests/api/shell-game-guess.test.ts`
- targeted backend `vitest`:
  - `tests/api/shell-game-start.test.ts`
  - `tests/api/shell-game-guess.test.ts`
  - `tests/api/shell-game-play-deprecated.test.ts`
- full backend `npx vitest run`
- `npm run build` in `backend/`
- `git diff --check`

## Follow-up

- the next warning-heavy backend slice is still `social/*`.
- shell-game now has the right lock boundary, but a future minigame framework pass should probably extract the repeated “lock session, validate owner, parse JSON payload” pattern into a shared helper only after the remaining minigame routes are audited file by file.
