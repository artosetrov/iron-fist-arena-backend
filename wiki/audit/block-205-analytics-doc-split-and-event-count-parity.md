---
title: Audit Block 205 — Analytics Doc Split And Event Count Parity
category: audit
tags: [audit, analytics, docs, tutorial, gold-mine]
sources:
  - backend/src/lib/analytics.ts
  - backend/src/lib/game/tutorial-analytics.ts
  - docs/02_product_and_features/ONBOARDING_SPEC.md
  - docs/features/gold-mine/GOLD_MINE_MINIGAME_PLAN.md
  - wiki/features/tutorial.md
updated: 2026-04-19
status: Fixed
---

# Audit Block 205 — Analytics Doc Split And Event Count Parity

## Scope

- `backend/src/lib/analytics.ts`
- `backend/src/lib/game/tutorial-analytics.ts`
- `docs/02_product_and_features/ONBOARDING_SPEC.md`
- `docs/features/gold-mine/GOLD_MINE_MINIGAME_PLAN.md`
- `wiki/features/tutorial.md`

## Why this block

The analytics layer had drifted into two dialects:

- the provider-agnostic core analytics surface in `backend/src/lib/analytics.ts`
- the tutorial-specific structured JSON funnel logs in `backend/src/lib/game/tutorial-analytics.ts`

Docs were still mixing them:

- `ONBOARDING_SPEC` said tutorial analytics emitted **7** events, but the live helper now emits **8**
- the Gold Mine plan still pointed at a non-existent `backend/src/lib/analytics/events.ts`

## Fix applied

### `docs/02_product_and_features/ONBOARDING_SPEC.md`

- updated the tutorial analytics count from `7` to `8`
- kept the wording anchored to the structured tutorial log helper, not the core provider-agnostic analytics union

### `docs/features/gold-mine/GOLD_MINE_MINIGAME_PLAN.md`

- replaced the stale `backend/src/lib/analytics/events.ts` reference
- now points future instrumentation work at the real extension point: `backend/src/lib/analytics.ts`

### `wiki/features/tutorial.md`

- clarified the split explicitly:
  - tutorial funnel events live in `tutorial-analytics.ts`
  - they are separate from the 7-event core analytics contract in `backend/src/lib/analytics.ts`

## Result

Analytics docs are back in sync with the live code shape:

- tutorial funnel logging is documented as its own structured log surface
- the tutorial event count matches the actual helper
- feature plans no longer reference a backend analytics file that does not exist

## Verification

- compared `backend/src/lib/analytics.ts` vs `backend/src/lib/game/tutorial-analytics.ts`
- `git diff --check`

Docs now match the live analytics split.
