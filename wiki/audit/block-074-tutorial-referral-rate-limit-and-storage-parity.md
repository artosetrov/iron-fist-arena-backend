---
title: Block 074 — tutorial referral rate-limit and storage parity
category: audit
tags: [audit, backend, tutorial, referral, onboarding, rate-limit, contracts]
sources:
  - backend/src/app/api/tutorial/referral/route.ts
  - backend/src/app/api/tutorial/route.ts
  - backend/src/app/api/tutorial/skip/route.ts
  - backend/src/lib/game/tutorial.ts
  - backend/src/lib/rate-limit.ts
  - backend/tests/api/tutorial-referral.test.ts
  - Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift
updated: 2026-04-15
status: Fixed
---

# Block 074 — tutorial referral rate-limit and storage parity

## Scope

- backend tutorial referral API:
  - `backend/src/app/api/tutorial/referral/route.ts`
- backend tutorial onboarding entry points:
  - `backend/src/app/api/tutorial/route.ts`
  - `backend/src/app/api/tutorial/skip/route.ts`
- backend tutorial helper surface:
  - `backend/src/lib/game/tutorial.ts`
  - `backend/src/lib/rate-limit.ts`
- backend regression coverage:
  - `backend/tests/api/tutorial-referral.test.ts`
- client consumer reference:
  - `Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift`

## Why this block

The referral flow had drifted in three different directions at once:

- `/api/tutorial/referral` used the rate limiter with inverted boolean semantics
- that same route used a `60` millisecond window instead of `60_000`
- `referredBy` was stored as a referral code in one route and as a referrer `character_id` in two others

That combination meant the referral system looked fine on the surface, but the real runtime behavior was inconsistent:

- some valid referral submissions could be rate-limited incorrectly
- analytics and max-referral checks could undercount real referrals
- onboarding init/skip and the standalone referral endpoint were not enforcing the same storage or max-use rules

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-045-backend-tutorial-achievement-and-weekly-contracts]]
- [[block-073-tutorial-scripted-fight-contract-and-victory-parity]]
- [[economy]]

## File notes

### `backend/src/app/api/tutorial/referral/route.ts`

- **Zone:** backend / tutorial / referral
- **Purpose:** load referral stats and apply a friend's referral code after character creation
- **Problems found:**
  - rate limiting was wired backwards: `true` was treated as "blocked"
  - rate limit window was `60` instead of `60_000`
  - GET counted referrals only where `referredBy === referralCode`, even though other tutorial paths stored `referredBy === referrerCharacterId`
  - POST saved `referredBy` as the referral code instead of the canonical referrer `character_id`
  - POST performed max-referral validation outside a locked transaction
- **What was fixed:**
  - restored the normal `rateLimit(...) === allowed` contract
  - corrected the rate-limit window to 60 seconds
  - GET now counts both legacy code-based links and canonical character-id links
  - GET resolves `referredBy` back into a friendly referral code when possible and also exposes `referredByCharacterId`
  - POST now runs under a transaction with row locks, stores canonical `referredBy: referrer.id`, and still returns the friend code to the client
- **Status:** Fixed

### `backend/src/app/api/tutorial/route.ts`

- **Zone:** backend / tutorial / onboarding start
- **Purpose:** claim the welcome gift and initialize tutorial state
- **Problems found:**
  - referral code input was not normalized
  - onboarding-start referral linking did not enforce the same max-referral policy as `/api/tutorial/referral`
- **What was fixed:**
  - referral code is now normalized before lookup
  - referral linking now counts both legacy and canonical referral records before applying the referral
  - canonical `referredBy: referrer.id` behavior is preserved
- **Status:** Fixed

### `backend/src/app/api/tutorial/skip/route.ts`

- **Zone:** backend / tutorial / onboarding skip
- **Purpose:** skip the guided tutorial while still granting the starter package
- **Problems found:**
  - same referral normalization and max-referral parity drift as the main tutorial start route
- **What was fixed:**
  - normalized referral input
  - aligned referral-cap enforcement with the main start route and standalone referral endpoint
- **Status:** Fixed

### `backend/src/lib/game/tutorial.ts`

- **Zone:** backend / tutorial helpers
- **Purpose:** holds tutorial constants and helper functions
- **Problems found:**
  - referral code normalization and legacy-vs-canonical link resolution were duplicated ad hoc across routes
- **What was fixed:**
  - added `normalizeReferralCode(...)`
  - added `getReferralLinkValues(...)`
  - added `isReferralCodeLike(...)`
- **Status:** Fixed

### `backend/tests/api/tutorial-referral.test.ts`

- **Zone:** backend / tests / tutorial
- **Purpose:** regression coverage for the referral API boundary
- **Problems found:**
  - there was no direct coverage for referral rate-limit semantics or mixed legacy/canonical storage
- **What was fixed:**
  - added focused tests for:
    - mixed referral counting on GET
    - correct rate-limit boolean/window handling on POST
    - canonical `referredBy` storage with code-shaped client response
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift`

- **Zone:** iOS / settings / referral
- **Purpose:** player-facing referral panel
- **Why it mattered here:**
  - the client only needs to know whether a referral already exists
  - server-side cleanup had to preserve that contract while fixing storage under the hood
- **Status:** OK

## Problems found

1. **Referral POST used the rate limiter backwards**
   - Risk: valid referral submissions could get `429` incorrectly while abusive traffic slipped through the wrong branch.
   - Fix: restored the standard `if (!(await rateLimit(...)))` pattern.

2. **Referral POST used a 60 millisecond window instead of 60 seconds**
   - Risk: the limit was effectively meaningless in production traffic.
   - Fix: changed the window to `60_000`.

3. **`referredBy` storage drifted between referral code and referrer character ID**
   - Risk: referral counts, max-referral enforcement, and downstream reporting could disagree depending on which route created the link.
   - Fix: canonicalized new writes to `referrer.id` and made read/count paths legacy-compatible.

4. **Onboarding start/skip were not enforcing the same referral cap as the standalone referral endpoint**
   - Risk: max-referral rules could be bypassed simply by entering the code during FTUE instead of later in Settings.
   - Fix: aligned init/skip with the shared mixed-storage count logic.

5. **Standalone referral application was not serialized around referrer-cap checks**
   - Risk: concurrent uses of the same code could oversubscribe the cap.
   - Fix: moved the apply flow into a transaction with row locks on the invitee and referrer records.

## Verification

- `npx eslint src/app/api/tutorial/referral/route.ts src/app/api/tutorial/route.ts src/app/api/tutorial/skip/route.ts src/lib/game/tutorial.ts tests/api/tutorial-referral.test.ts` in `backend/`
- `npx vitest run tests/api/tutorial-referral.test.ts tests/api/tutorial-scripted-fight-contracts.test.ts tests/api/tutorial-quest.test.ts` in `backend/`
- `npx vitest run` in `backend/`
- `npm run build` in `backend/`
- `git diff --check`

## Follow-up

- referral stats are now counted correctly, but the actual **referrer payout** when an invitee reaches `level >= 5` still does not exist anywhere in live runtime
- the codebase already exposes `qualifiedCount`, `referrerGold`, and `referrerGems`, so the missing reward grant should be treated as a separate product/runtime block rather than left implicit
