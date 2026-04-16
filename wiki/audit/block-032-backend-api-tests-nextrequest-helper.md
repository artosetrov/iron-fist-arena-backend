---
title: Block 032 — backend API tests NextRequest helper
category: audit
tags: [audit, backend, tests, nextrequest, contracts]
sources:
  - backend/tests/helpers/next-request.ts
  - backend/tests/api/auth-login.test.ts
  - backend/tests/api/auth-register.test.ts
  - backend/tests/api/stamina-refill.test.ts
  - backend/tests/api/shell-game-start.test.ts
  - backend/tests/api/shell-game-play-deprecated.test.ts
  - backend/tests/api/battle-pass-claim.test.ts
updated: 2026-04-15
status: Fixed
---

# Block 032 — backend API tests NextRequest helper

## Scope

- `backend/tests/helpers/next-request.ts`
- `backend/tests/api/auth-login.test.ts`
- `backend/tests/api/auth-register.test.ts`
- `backend/tests/api/stamina-refill.test.ts`
- `backend/tests/api/shell-game-start.test.ts`
- `backend/tests/api/shell-game-play-deprecated.test.ts`
- `backend/tests/api/battle-pass-claim.test.ts`

## Why this block

These route tests were still exercising App Router handlers through `new Request(...) as any`, which hid the real boundary contract and made it easier for tests to drift away from the `NextRequest` runtime they are supposed to validate.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[bug-patterns]]

## File notes

### `backend/tests/helpers/next-request.ts`

- **Zone:** backend / test helpers
- **Purpose:** canonical helper for creating real `NextRequest` instances in API route tests
- **What was added:**
  - shared request builder for JSON body + URL setup
  - one place to keep App Router request-shape assumptions
- **Status:** Fixed

### `backend/tests/api/auth-login.test.ts`

- **Zone:** backend / API route tests
- **Purpose:** login route regression coverage
- **Problems found:**
  - test created casted `Request` objects instead of real `NextRequest`
- **What was fixed:**
  - moved route invocation onto the shared helper
- **Status:** Fixed

### `backend/tests/api/auth-register.test.ts`

- **Zone:** backend / API route tests
- **Purpose:** register route regression coverage
- **Problems found:**
  - same request-boundary cast drift as login tests
- **What was fixed:**
  - replaced `Request as any` setup with the shared `NextRequest` helper
- **Status:** Fixed

### `backend/tests/api/stamina-refill.test.ts`

- **Zone:** backend / API route tests
- **Purpose:** stamina refill cost/diminishing-return coverage
- **Problems found:**
  - casted request boundary and slightly loose local fixture typing
- **What was fixed:**
  - migrated to the shared request helper
  - tightened touched fixture typing
- **Status:** Fixed

### `backend/tests/api/shell-game-start.test.ts`

- **Zone:** backend / API route tests
- **Purpose:** shell-game start route coverage
- **Problems found:**
  - casted request boundary and loose fixture shape
- **What was fixed:**
  - switched to the shared helper
  - cleaned touched fixture typing
- **Status:** Fixed

### `backend/tests/api/shell-game-play-deprecated.test.ts`

- **Zone:** backend / deprecated API route tests
- **Purpose:** deprecated shell-game play path regression coverage
- **Problems found:**
  - test was still depending on a casted request shape
- **What was fixed:**
  - moved route invocation onto the shared request helper
- **Status:** Fixed

### `backend/tests/api/battle-pass-claim.test.ts`

- **Zone:** backend / API route tests
- **Purpose:** battle-pass claim regression coverage
- **Problems found:**
  - App Router request boundary was still mocked with `Request as any`
- **What was fixed:**
  - switched to the shared helper so request setup matches the live route contract
- **Status:** Fixed

## Problems found

1. **Route tests used casted `Request` objects instead of `NextRequest`**
   - Risk: tests can pass while the real App Router boundary behaves differently.
   - Fix: introduced one shared helper that constructs real `NextRequest` objects and migrated the touched route tests onto it.

2. **Boundary setup was duplicated across unrelated tests**
   - Risk: every route test had its own mini request shim, which makes future request-contract changes noisy and easy to miss.
   - Fix: centralized request construction in `backend/tests/helpers/next-request.ts`.

## Verification

- targeted `vitest` for the touched test files
- full backend `npx vitest run`
- `git diff --check`

## Follow-up

- local transaction fixtures still intentionally stay local to each test file until the full `backend/tests/api` pass is complete
- later API test blocks continue this same cleanup for the remaining route tests that were still using casted requests
