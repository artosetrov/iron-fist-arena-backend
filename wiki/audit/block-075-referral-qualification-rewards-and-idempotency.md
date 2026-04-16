---
title: Block 075 — referral qualification rewards and idempotency
category: audit
tags: [audit, backend, tutorial, referral, progression, rewards, prisma]
sources:
  - backend/prisma/schema.prisma
  - backend/prisma/migrations/20260415_add_referral_reward_claims/migration.sql
  - backend/src/lib/game/tutorial.ts
  - backend/src/lib/game/progression.ts
  - backend/tests/lib/tutorial-referral-rewards.test.ts
  - backend/tests/api/tutorial-referral.test.ts
updated: 2026-04-15
status: Fixed
---

# Block 075 — referral qualification rewards and idempotency

## Scope

- Prisma referral reward persistence:
  - `backend/prisma/schema.prisma`
  - `backend/prisma/migrations/20260415_add_referral_reward_claims/migration.sql`
- backend referral reward runtime:
  - `backend/src/lib/game/tutorial.ts`
  - `backend/src/lib/game/progression.ts`
- backend regression coverage:
  - `backend/tests/lib/tutorial-referral-rewards.test.ts`
  - `backend/tests/api/tutorial-referral.test.ts`

## Why this block

Block 074 cleaned up referral storage and rate limiting, but it also exposed the bigger product/runtime hole:

- the codebase already had `qualifiedCount`
- the analytics enum already had `referral_qualified`
- the config already declared `referrerGold` and `referrerGems`

What it did **not** have was the actual one-time reward grant when the invitee reached the required level.

That meant the project was describing a live reward system that simply did not exist.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-074-tutorial-referral-rate-limit-and-storage-parity]]
- [[progression]]
- [[economy]]

## File notes

### `backend/prisma/schema.prisma`

- **Zone:** backend / Prisma schema
- **Purpose:** canonical data model
- **Problems found:**
  - there was no durable record for "this invitee already triggered the referral qualification payout"
  - without an idempotency record, any future reward implementation would either double-pay or depend on fragile heuristics
- **What was fixed:**
  - added `ReferralRewardClaim`
  - modeled one-time qualification with a unique pair:
    - `referrerCharacterId`
    - `inviteeCharacterId`
  - attached the model back to `Character` through explicit relations
- **Status:** Fixed

### `backend/prisma/migrations/20260415_add_referral_reward_claims/migration.sql`

- **Zone:** backend / Prisma migrations
- **Purpose:** persistent rollout of referral qualification claims
- **What was fixed:**
  - created `referral_reward_claims`
  - added unique constraint over `(referrer_character_id, invitee_character_id)`
  - added indexes and foreign keys to `characters`
- **Status:** Fixed

### `backend/src/lib/game/tutorial.ts`

- **Zone:** backend / tutorial and referral helpers
- **Purpose:** shared tutorial constants and tutorial-side business rules
- **Problems found:**
  - referral qualification reward logic did not exist
  - there was no canonical helper for "invitee reached threshold, pay referrer once"
- **What was fixed:**
  - added `awardReferralQualificationIfEligible(...)`
  - helper now:
    - exits early below `inviteeLevelThreshold`
    - resolves legacy code-based and canonical character-id referral links
    - creates a unique claim row
    - awards referrer gold and gems once
    - logs `referral_qualified`
  - duplicate-claim races are treated as already processed via `P2002`
- **Status:** Fixed

### `backend/src/lib/game/progression.ts`

- **Zone:** backend / shared progression runtime
- **Purpose:** global level-up authority
- **Problems found:**
  - referral qualification reward would have been easy to wire into only one or two routes, which would recreate drift immediately
- **What was fixed:**
  - hooked referral qualification payout into shared `applyLevelUp(...)`
  - now any route that levels the character through the common progression path can trigger the reward exactly once
  - surfaced the result in `LevelUpResult.referralRewardAwarded` for future consumers
- **Status:** Fixed

### `backend/tests/lib/tutorial-referral-rewards.test.ts`

- **Zone:** backend / tests / tutorial
- **Purpose:** regression coverage for referral qualification payout logic
- **What was fixed:**
  - added direct tests for:
    - successful one-time qualification payout
    - idempotent duplicate handling through unique-claim collision
- **Status:** Fixed

### `backend/tests/api/tutorial-referral.test.ts`

- **Zone:** backend / tests / tutorial API
- **Purpose:** boundary coverage for referral dashboard and apply route
- **Why it mattered here:**
  - block 074 route tests remain part of the referral safety net
  - they still verify the mixed legacy/canonical storage behavior that this reward block depends on
- **Status:** Fixed

## Problems found

1. **The project exposed referral reward constants and analytics without any live payout path**
   - Risk: product/docs/UI promised referrer rewards that were never actually granted.
   - Fix: added one-time qualification payout logic.

2. **There was no idempotency record for qualified referrals**
   - Risk: any naïve implementation would either double-pay or depend on brittle read-side checks.
   - Fix: added `ReferralRewardClaim` with a unique referrer/invitee pair.

3. **A route-local fix would have recreated progression drift**
   - Risk: payout would work for some level-up flows and silently fail for others.
   - Fix: attached the logic to shared `applyLevelUp(...)`.

## Verification

- `npx eslint src/lib/game/tutorial.ts src/lib/game/progression.ts tests/lib/tutorial-referral-rewards.test.ts tests/api/tutorial-referral.test.ts` in `backend/`
- `npx vitest run tests/lib/tutorial-referral-rewards.test.ts tests/api/tutorial-referral.test.ts` in `backend/`
- `npx vitest run` in `backend/`
- `npm run build` in `backend/`
- `python3 scripts/check_schema_drift.py --verbose`
- `git diff --check`

## Follow-up

- this fixes **future** qualification payouts cleanly, but it does not automatically backfill old invitees who had already crossed the threshold before this block landed
- that backfill should be treated as a separate repair decision, because it changes real player currency state and may need product visibility before execution
