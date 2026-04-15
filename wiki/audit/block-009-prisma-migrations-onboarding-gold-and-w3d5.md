---
title: Audit Block 009 — Prisma Migrations: Onboarding, Gold Account Shift, and W3.D5
category: audit
tags: [audit, backend, prisma, migrations, onboarding, economy, premium]
sources:
  - backend/prisma/migrations/
  - backend/src/app/api/tutorial/
  - backend/src/lib/game/events.ts
  - backend/src/lib/game/premium.ts
updated: 2026-04-15
---

# Audit Block 009 — Prisma Migrations: Onboarding, Gold Account Shift, and W3.D5

## Scope

This block covers the April 7–10 migration wave plus the audit-created follow-up migration needed to close a tutorial completion gap uncovered during review.

- **Files audited in this block:** 9
- **Primary file types:** Prisma migration SQL
- **Status:** Major product changes are represented correctly, but tutorial state and a few indexing/config decisions needed cleanup
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-008-prisma-migrations-baseline-early-deltas]], [[block-007-backend-root-prisma-foundation]], [[economy]], [[interactive-combat]]

## Summary

- This batch is where migration history stops being mostly additive schema work and starts carrying real product transitions: tutorial onboarding state, account-level gold, daily activity caps, guest restore identity, weekly BP challenges, and premium-title support.
- The most important finding was a **cross-file tutorial replay bug**: `20260407_add_tutorial_onboarding` and `20260410_add_tutorial_completed` produced a state space where a character could be logically tutorial-complete (`tutorial_step >= 3` or skipped) while `tutorial_completed = false`. The scripted-fight routes guarded only on the boolean, so some users could replay for rewards.
- `20260409_migrate_gold_to_account_level` is a high-blast-radius migration, but the SQL itself is sane: add `users.gold`, backfill from character sums, then drop `characters.gold`.
- `20260410_w3d5_tiers_weekly_premium` packs several separate product changes into one migration and quietly relies on admin-side live-config seeding for tier rows. That is survivable, but it is not a clean migration boundary.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Tutorial completion state was split across `tutorial_step`, `tutorial_skipped`, and later `tutorial_completed`, but replay guards only checked the boolean. | Legacy users and skip-tutorial users could reach scripted-fight endpoints and claim rewards again. | Added `20260415_backfill_tutorial_completion_state/migration.sql` and patched tutorial skip/preload/resolve routes to treat all completion signals consistently. |

## Cross-File Safe Fixes Applied

These route fixes were applied immediately because the migration audit exposed a live reward-replay path:

- `backend/src/app/api/tutorial/skip/route.ts` now sets `tutorialCompleted` and `tutorialCompletedAt` when the player skips.
- `backend/src/app/api/tutorial/scripted-fight/preload/route.ts` now blocks when `tutorialCompleted`, `tutorialSkipped`, or `tutorialStep >= 3`.
- `backend/src/app/api/tutorial/scripted-fight/resolve/route.ts` now applies the same broader replay guard inside the transaction.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/prisma/migrations/20260407_add_tutorial_onboarding/migration.sql` | Onboarding schema + backfill | Adds tutorial progress fields, referral fields, and `tutorial_quests`, then backfills existing characters to `tutorial_step = 3`. | Used by tutorial onboarding, referral, and analytics flows. | Existing characters are treated as already past onboarding via `tutorial_step = 3`. | This later collided with the separate `tutorial_completed` boolean added on 2026-04-10. The state model needed a follow-up fix. | Needs review |
| `backend/prisma/migrations/20260409_add_stat_purchase_tracking/migration.sql` | Economy/player-progression delta | Adds daily and lifetime stat-purchase counters on characters. | Used by stat-buy flows and anti-abuse logic. | Simple additive counters, zero-safe for existing rows. | No issue found. | OK |
| `backend/prisma/migrations/20260409_fix_consumable_special_effects/migration.sql` | Data correction migration | Reconciles stale consumable `special_effect` text with current potion behavior. | Used indirectly by admin panels / any consumers still showing `special_effect`. | Pure data repair; safe and explicit. | Clear targeted fix, no issue found. | OK |
| `backend/prisma/migrations/20260409_migrate_gold_to_account_level/migration.sql` | Wallet ownership migration | Moves gold ownership from `characters.gold` to `users.gold` by summing per-user balances and then dropping the character column. | Used by essentially all post-migration gold flows across shop, PvP, dungeons, mail, and minigames. | One-time data migration with large blast radius; assumes per-user total is the intended canonical wallet. | SQL is coherent and matches current runtime. Main risk is historical/operational, not a bug in the migration itself. | OK |
| `backend/prisma/migrations/20260410_add_daily_activity_caps/migration.sql` | Retention / anti-farm delta | Adds lazy-reset counters for dungeon clears and stamina refills. | Used by activity-cap logic in gameplay routes. | Counters reset lazily based on `*_date`; no cron required. | Good additive migration with clear rationale. | OK |
| `backend/prisma/migrations/20260410_add_tutorial_completed/migration.sql` | Tutorial replay-prevention delta | Adds `tutorial_completed` and `tutorial_completed_at` plus a partial index. | Used by scripted tutorial fight routes. | Intended to become the replay-prevention flag. | Standalone migration was incomplete for existing/skip users because it did not backfill from prior tutorial state. Fixed later by `20260415_backfill_tutorial_completion_state`. | Needs review |
| `backend/prisma/migrations/20260410_add_user_device_id/migration.sql` | Guest-restore bugfix | Adds `users.device_id` plus unique/index support for guest restore. | Used by guest-login/restore flows. | Device ID must be unique for stable guest-account restoration. | Functional bugfix is good, but the plain `users_device_id_idx` appears redundant because `users_device_id_key` already provides a lookup-capable btree index on the same column. | Needs review |
| `backend/prisma/migrations/20260410_w3d5_tiers_weekly_premium/migration.sql` | Multi-feature product migration | Introduces weekly BP challenges, premium daily-claim date, and title support; tier expansion itself remains code/admin-config only. | Used by weekly challenge routes, premium logic, and cosmetic title support. | Mixed migration: some behavior is in SQL, some in runtime code, some seeded lazily by admin. | Works, but bundles unrelated concerns and has a hidden dependency on admin-side live-config seeding for PvP tier rows. | Needs review |
| `backend/prisma/migrations/20260415_backfill_tutorial_completion_state/migration.sql` | Audit-created repair migration | Backfills `tutorial_completed` for characters already complete/skipped by legacy state. | Used to align live data with current tutorial replay guards. | Marks rows complete when `tutorial_skipped = true` or `tutorial_step >= 3`. | Created during audit to close a real reward-replay gap. | Fixed |

## Duplicate / Split Logic Found

- Tutorial completion is represented by three signals: `tutorial_step`, `tutorial_skipped`, and `tutorial_completed`. That split caused the replay bug.
- `20260410_w3d5_tiers_weekly_premium` spreads one feature wave across migration SQL, runtime code, and admin-side config seeding.
- `users.device_id` currently has both a unique index and a plain secondary index on the same nullable column.

## Files Without Clear Current Role

- None are roleless, but `20260410_w3d5_tiers_weekly_premium` is too broad for a single migration from an auditability standpoint. It is more of a feature bundle than a narrow schema delta.

## Candidates For Refactor

- Consider collapsing tutorial completion onto a single canonical predicate long-term, with `tutorial_completed` as the durable source and `tutorial_step` as UX progression only.
- Consider removing the redundant plain index on `users.device_id` in a future cleanup migration if query plans confirm the unique index already covers the workload.
- Consider splitting future feature-bundle migrations like `20260410_w3d5_tiers_weekly_premium` by concern (schema, config bootstrap, premium cosmetics, weekly BP data).

## Documentation Missing Or Stale

- No current onboarding doc defines which field is the canonical source of truth for "tutorial complete."
- No migration doc calls out the guest-restore index duplication or explains why both indexes would be needed.
- No product/migration doc explains that W3.D5 tier rows are seeded by admin-side config load rather than by the migration itself.

## Verification

- `bash -lc 'cd backend && npx eslint src/app/api/tutorial/skip/route.ts src/app/api/tutorial/scripted-fight/preload/route.ts src/app/api/tutorial/scripted-fight/resolve/route.ts'` passes.
- `python3 scripts/check_schema_drift.py --verbose` passes after the new tutorial backfill migration.
- `git diff --check` passes.
- No dedicated tutorial route tests existed in this block, so replay-guard verification here is static/code-path based rather than test-backed.
