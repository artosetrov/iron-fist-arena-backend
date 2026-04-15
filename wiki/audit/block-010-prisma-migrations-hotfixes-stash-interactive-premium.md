---
title: Audit Block 010 — Prisma Migrations: Hotfixes, Stash, Interactive Combat, and Premium
category: audit
tags: [audit, backend, prisma, migrations, hotfix, stash, pvp, premium]
sources:
  - backend/prisma/migrations/
  - backend/prisma/schema.prisma
  - backend/src/app/api/passives/
  - backend/src/app/api/pvp/
  - backend/src/app/api/shop/
  - scripts/check_schema_drift.py
updated: 2026-04-15
---

# Audit Block 010 — Prisma Migrations: Hotfixes, Stash, Interactive Combat, and Premium

## Scope

This block covers the April 11–14 migration wave where the project moved from emergency Gold Mine repair into stash/contraband storage, interactive combat infrastructure, premium subscription tracking, and the stamina-cap increase.

- **Files audited in this block:** 13
- **Primary file types:** Prisma migration SQL
- **Status:** Core gameplay deltas are mostly coherent; the main risks are migration-history hygiene, manual-first parity files, and one large catch-up migration
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-009-prisma-migrations-onboarding-gold-and-w3d5]], [[block-008-prisma-migrations-baseline-early-deltas]], [[block-006-project-scripts]], [[interactive-combat]], [[gold-mine]], [[economy]]

## Summary

- This batch contains both some of the strongest migrations in the repo and some of the clearest process debt. The active-slot migrations are carefully commented and enforce business rules at the DB layer, while the hotfix/catch-up migrations show that schema changes were still sometimes landing before migration history was clean.
- The biggest concrete cleanup in this block was a hidden duplicate file inside `20260411_hotfix_gold_mine_minigame_variant_d_phase2/`: a nested `_hidden_hotfix/migration.sql` duplicated the real migration byte-for-byte. That kind of artifact does not help Prisma, but it does pollute auditability and invites future confusion.
- `20260413_fix_schema_drift` is functionally useful, but architecturally it is a red flag: one migration is reintroducing many missing admin/content tables and indexes after drift had already happened elsewhere.
- `20260414_premium_subscription` works as parity for the current schema, but because it represents a migration that was applied manually first, it carries operational ambiguity that should be documented more explicitly.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P2 | `20260411_hotfix_gold_mine_minigame_variant_d_phase2/_hidden_hotfix/migration.sql` duplicated the real migration and lived invisibly inside the migration directory. | Humans could trust the wrong artifact, drift tooling would not complain, and migration history would silently accumulate junk Prisma never executes. | Deleted the duplicate file and extended `scripts/check_schema_drift.py` to fail when migration directories contain hidden/nested artifacts. |

## Cross-File Safe Fixes Applied

- Removed `backend/prisma/migrations/20260411_hotfix_gold_mine_minigame_variant_d_phase2/_hidden_hotfix/migration.sql` because it was a dead duplicate of the real migration file.
- Extended `scripts/check_schema_drift.py` so migration history is now checked not just for columns/indexes/enums, but also for unexpected nested artifacts inside migration folders.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/prisma/migrations/20260411_add_loot_relevance/migration.sql` | Loot progression delta | Adds pity-streak and shard-fallback counters to `characters`. | Used by loot-drop logic in `backend/src/lib/game/loot.ts` and character progression reads. | Counters start at zero so existing characters remain valid. | Clean additive migration; no issue found. | OK |
| `backend/prisma/migrations/20260411_hotfix_gold_mine_minigame_variant_d_phase2/migration.sql` | Gold Mine emergency repair | Adds missing Gold Mine / minigame linkage columns and indexes that were present in schema but absent in migration history. | Used by Gold Mine, minigame, character, and social routes touching these relations. | This is a non-destructive hotfix for the 2026-04-11 schema-drift incident. | Main SQL is coherent. Audit found a nested duplicate copy in the same migration directory; duplicate artifact was removed during this block. | Fixed |
| `backend/prisma/migrations/20260411_hotfix_gold_mine_shaft_columns/migration.sql` | Gold Mine shaft-state repair | Adds `active_shaft_key`, `shaft_progress`, and `shaft_total` to `characters`. | Used by Gold Mine variant-D shaft progression flows. | Zero/5 defaults preserve existing rows. | Straightforward targeted hotfix; no issue found. | OK |
| `backend/prisma/migrations/20260412_add_contraband_claims/migration.sql` | Contraband claim ledger | Creates a per-character claim history table for contraband drops. | Used by shop/contraband claim logic and claim history reads. | Contents are stored as JSONB; claim number is sequential per character in runtime logic. | Clear role, sane FK/index setup, no issue found. | OK |
| `backend/prisma/migrations/20260412_add_stash_items/migration.sql` | Account-level stash persistence | Creates shared stash storage at the user level. | Used by stash/inventory transfer flows and item references. | Stash is account-owned, not character-owned. | Clean table/index/FK creation. Capacity/business limits live in runtime code rather than SQL. | OK |
| `backend/prisma/migrations/20260413_active_slot_infrastructure/migration.sql` | Interactive combat foundation | Introduces `TalentSlotAction`, active-skill metadata on passive nodes, and `character_active_slots`. | Used by passive-tree active-slot APIs and PvP interactive combat setup. | One node per slot and one slot assignment per node are enforced at the DB level. | Well-commented and defensive. No bug found in this phase. | OK |
| `backend/prisma/migrations/20260413_fix_schema_drift/migration.sql` | Catch-up schema repair | Recreates admin/content tables, missing indexes, and timestamp columns that had drifted out of migration history. | Used by push, mail, offers, feature flags, quest/admin tooling, and inventory/progress tables. | Intentionally idempotent because some objects may already exist in production. | Functionally useful, but it is a monolithic drift-repair migration spanning many unrelated subsystems. That is architecture/process debt, not a single-schema bug. | Needs review |
| `backend/prisma/migrations/20260413_interactive_actives_snapshot/migration.sql` | PvP snapshot delta | Adds `interactive_actives` JSONB to `pvp_matches` so active-slot state is frozen per match. | Used by `/api/pvp/match/start` and `/api/pvp/strike` style flows. | Match resolution should not depend on mutable live loadouts after match creation. | Clear narrow migration; no issue found. | OK |
| `backend/prisma/migrations/20260413_interactive_combat_v1/migration.sql` | PvP interactive state delta | Adds interactive-match status/choice columns and backfills old rows to `completed`. | Used by interactive PvP orchestration and match status reads. | Old non-interactive rows must read as completed to keep semantics stable. | Good additive/backfill combo. No issue found. | OK |
| `backend/prisma/migrations/20260414_active_slot_consumables/migration.sql` | Active-slot phase 4 extension | Lets an active slot hold either an activatable passive or a consumable, with partial unique indexes and a mutual-exclusion check. | Used by active-slot equip/use flows and consumable combat logic. | Exactly one of `node_id` or `consumable_type` must be present; only one consumable loadout slot per character. | Strong migration with DB-level rule enforcement. Long-term maintainability risk is that Prisma schema cannot express these partial indexes, so docs/runtime must stay aligned. | OK |
| `backend/prisma/migrations/20260414_consumable_type_extras/migration.sql` | Economy catalog enum expansion | Adds `protection_scroll` and `legendary_shard` to `ConsumableType`. | Used by shop bundle logic, balance definitions, and consumable routing. | Enum values must exist before code or seeded offers reference them. | Simple additive enum migration; no issue found. | OK |
| `backend/prisma/migrations/20260414_premium_subscription/migration.sql` | Premium pass persistence | Creates `premium_subscriptions` for auto-renewable subscription tracking. | Used by premium entitlement logic, IAP/webhook flows, and `hasPremium()` checks. | One subscription row per user, refreshed on renewal via receipt/webhook flow. | Works for schema parity, but this is a manual-first migration file and its FK addition is not guarded for re-run. That makes the operational story less clean than the comment implies. | Needs review |
| `backend/prisma/migrations/20260414_stamina_cap_180/migration.sql` | Economy balance migration | Raises stamina defaults/cap from 120 to 180 and tops up legacy full-cap characters. | Used by stamina/regeneration flows across combat, dungeons, PvP, and tutorials. | Existing characters at the old cap should not feel the cap increase as a downgrade. | SQL is coherent. Cross-file follow-up remains: several tests still pin `120` fixtures, so test intent vs. historical default should be reviewed in the later test block. | OK |

## Removed During Audit

- `backend/prisma/migrations/20260411_hotfix_gold_mine_minigame_variant_d_phase2/_hidden_hotfix/migration.sql` — deleted as a dead duplicate of the real migration file in the same directory.

## Duplicate / Split Logic Found

- Gold Mine variant-D repair existed in two places inside the same migration directory: one real migration and one hidden duplicate. The duplicate was removed.
- Active-slot invariants are split between Prisma schema comments/runtime assumptions and raw SQL partial indexes/check constraints, because Prisma cannot model those constraints directly.
- Premium subscription rollout is split between manual production application and committed migration history parity.
- Stamina-cap behavior is now `180` in schema/runtime, while several backend tests still seed `120`, creating cross-file intent drift that needs explicit review later.

## Files Without Clear Current Role

- None remain in this block after duplicate cleanup. The removed `_hidden_hotfix` file had no valid continuing role.

## Candidates For Refactor

- Break future “schema drift repair” work into bounded migrations instead of another `20260413_fix_schema_drift`-style catch-up monolith.
- Document manual-first migrations like `20260414_premium_subscription` with a stronger operational rule: how they are applied, how they are marked applied, and how parity is verified afterward.
- Consider a dedicated documentation page for DB-only invariants that Prisma cannot express, especially for `character_active_slots`.

## Documentation Missing Or Stale

- No migration-history policy currently says that migration directories must remain artifact-clean with exactly one authoritative `migration.sql`.
- No canonical page explains that active-slot partial indexes/check constraints exist only in SQL and cannot be inferred from Prisma schema alone.
- Premium subscription docs note the manual migration, but the repo still lacks one short operational page describing the exact parity workflow and rerun expectations.
- Several backend tests still use `max_stamina = 120` fixtures after the `180` cap migration; later test audit should distinguish intentional legacy scenarios from stale defaults.

## Verification

- `python3 scripts/check_schema_drift.py --verbose` passes after duplicate cleanup and nested-artifact detection.
- `python3 -m py_compile scripts/check_schema_drift.py` passes.
- `git diff --check` passes.
- No DB replay test was run for this block because several migrations are historical/manual-first; validation here is static parity plus cross-file usage review.
