---
title: Audit Block 178 — Stale Audit Tail Tutorial Migration Sync
category: audit
tags: [audit, prisma, migrations, tutorial, truth-sync]
sources:
  - wiki/audit/block-009-prisma-migrations-onboarding-gold-and-w3d5.md
  - backend/prisma/migrations/20260407_add_tutorial_onboarding/migration.sql
  - backend/prisma/migrations/20260410_add_tutorial_completed/migration.sql
  - backend/prisma/migrations/20260415_backfill_tutorial_completion_state/migration.sql
  - backend/src/app/api/tutorial/skip/route.ts
  - backend/src/app/api/tutorial/scripted-fight/preload/route.ts
  - backend/src/app/api/tutorial/scripted-fight/resolve/route.ts
updated: 2026-04-17
---

# Audit Block 178 — Stale Audit Tail Tutorial Migration Sync

## Why this block exists

`block-009` correctly documented the original tutorial replay-state split:

- `20260407_add_tutorial_onboarding` backfilled legacy rows to `tutorial_step = 3`
- `20260410_add_tutorial_completed` later introduced a separate boolean replay flag
- old tutorial guards only checked the boolean, which left some legacy/skipped rows replayable

That was a real bug.

But after the later repair landed, two migration records inside `block-009` were still left as `Needs review` even though the block itself already cited the fix:

- `20260415_backfill_tutorial_completion_state`
- patched tutorial skip/preload/resolve guards

So the file still carried an open-status tail for a bug that had already been resolved in the actual repo.

## What changed

- updated the `20260407_add_tutorial_onboarding` record in `block-009`
- updated the `20260410_add_tutorial_completed` record in `block-009`
- replaced the older “needs review” wording with explicit later-resolution notes pointing at the backfill migration and replay-guard fixes
- changed both file statuses from `Needs review` to `Fixed`

## Result

`block-009` now reflects the real state of the tutorial migration chain:

- the original split-state bug existed
- it was later repaired with a dedicated backfill migration plus route guard fixes
- the remaining `Needs review` records in that block are now only the ones that still represent real open questions
