---
title: Block 076 — referral reward backfill tooling
category: audit
tags: [audit, backend, tutorial, referral, progression, repair, prisma]
sources:
  - backend/prisma/referral-reward-backfill.ts
  - backend/prisma/fix-referral-rewards.ts
  - backend/tests/prisma/referral-reward-backfill.test.ts
  - backend/prisma/MIGRATIONS.md
  - backend/package.json
updated: 2026-04-16
status: Fixed
---

# Block 076 — referral reward backfill tooling

## Scope

- repair tooling:
  - `backend/prisma/referral-reward-backfill.ts`
  - `backend/prisma/fix-referral-rewards.ts`
- regression coverage:
  - `backend/tests/prisma/referral-reward-backfill.test.ts`
- operator docs and script surface:
  - `backend/prisma/MIGRATIONS.md`
  - `backend/package.json`

## Why this block

Block 075 fixed **future** referral qualification payouts, but it intentionally did not mutate old player state.

That left one real product/economy gap:

- invitees who had already crossed the qualification threshold before the fix still existed
- their referrers still had not been paid
- historical `referredBy` storage was mixed between legacy referral codes and canonical character IDs

This needed a repair path, but it needed to be:

- idempotent
- explicit
- dry-run first
- safe against mixed legacy/current storage

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-074-tutorial-referral-rate-limit-and-storage-parity]]
- [[block-075-referral-qualification-rewards-and-idempotency]]
- [[economy]]
- [[progression]]

## File notes

### `backend/prisma/referral-reward-backfill.ts`

- **Zone:** backend / Prisma repair tooling
- **Purpose:** canonical repair helper for historical referral qualification payouts
- **Problems found:**
  - there was no safe operator path to reconcile invitees who had already qualified before block 075
  - historical `referredBy` data still required mixed legacy-code and canonical-character matching
  - a naïve row-by-row repair would risk duplicate payouts and noisy partial currency updates
- **What was fixed:**
  - added `backfillReferralRewardClaims(...)`
  - helper scans already-qualified invitees, resolves referrers from both storage shapes, and skips:
    - already claimed pairs
    - invalid referrers
    - self-referrals
  - default mode is dry-run and returns a detailed summary
  - apply mode creates one-time claim rows and aggregates currency updates per referrer user inside a transaction
  - historical repair deliberately avoids tutorial analytics side effects
- **Status:** Fixed

### `backend/prisma/fix-referral-rewards.ts`

- **Zone:** backend / Prisma CLI tooling
- **Purpose:** operator-facing entrypoint for the referral repair helper
- **Problems found:**
  - there was no explicit script surface for running the repair safely
- **What was fixed:**
  - added a thin CLI wrapper
  - defaults to dry-run
  - requires explicit `--apply` for live mutations
  - prints JSON summary for auditability
- **Status:** Fixed

### `backend/tests/prisma/referral-reward-backfill.test.ts`

- **Zone:** backend / tests / Prisma repair tooling
- **Purpose:** regression coverage for historical referral repair logic
- **What was fixed:**
  - added coverage for:
    - mixed canonical and legacy referral resolution
    - existing claim dedupe
    - invalid referrer handling
    - self-referral skip behavior
    - apply-mode aggregated user currency updates
- **Status:** Fixed

### `backend/prisma/MIGRATIONS.md`

- **Zone:** backend / operator docs
- **Purpose:** documented operational migration and repair procedures
- **Problems found:**
  - the new repair path would have been discoverable only from code
- **What was fixed:**
  - documented dry-run and apply commands for referral reward repair
  - made the intended safety sequence explicit
- **Status:** Fixed

### `backend/package.json`

- **Zone:** backend / script surface
- **Purpose:** developer/operator command catalog
- **What was fixed:**
  - added `db:fix:referral-rewards`
  - keeps the repair path consistent with the rest of the Prisma maintenance tooling
- **Status:** Fixed

## Problems found

1. **Block 075 fixed only future payouts**
   - Risk: historical invitees remained qualified-but-unpaid, which is a real economy fairness gap.
   - Fix: added explicit backfill tooling.

2. **Historical referral storage was mixed**
   - Risk: manual SQL or a simplistic script could miss valid referrals or pay the wrong referrer.
   - Fix: repair helper resolves both legacy referral-code links and canonical character-ID links.

3. **A blunt repair path could double-pay**
   - Risk: duplicate claims or repeated user-currency increments under retries and races.
   - Fix: reuse `ReferralRewardClaim` idempotency and aggregate user updates transactionally.

4. **Repair needed to be operator-safe**
   - Risk: running live state mutation without preview would make economy repair harder to reason about.
   - Fix: dry-run is the default; live mutation requires explicit `--apply`.

## Verification

- `npx eslint prisma/referral-reward-backfill.ts prisma/fix-referral-rewards.ts tests/prisma/referral-reward-backfill.test.ts` in `backend/`
- `npx vitest run tests/prisma/referral-reward-backfill.test.ts tests/lib/tutorial-referral-rewards.test.ts tests/api/tutorial-referral.test.ts` in `backend/`
- `npx vitest run` in `backend/`
- `npm run build` in `backend/`
- `python3 scripts/check_schema_drift.py --verbose`
- `git diff --check`

## Follow-up

- the code path is now ready, but the actual **apply** decision still needs liveops/product coordination because it changes real player currency state
- if this repair is executed in production, the dry-run JSON output should be archived alongside the rollout note for future economy traceability
