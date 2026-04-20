---
title: Audit Block 008 — Prisma Migrations: Baseline and Early Delta Chain
category: audit
tags: [audit, backend, prisma, migrations, database]
sources:
  - backend/prisma/migrations/
  - backend/prisma/schema.prisma
  - backend/src/lib/game/events.ts
  - docs/04_database/SCHEMA_REFERENCE.md
updated: 2026-04-19
---

# Audit Block 008 — Prisma Migrations: Baseline and Early Delta Chain

## Scope

This block covers the migration history foundation plus the first wave of post-baseline deltas. It includes the baseline snapshot, March schema/data migrations, and the audit-created follow-up fixes that were required to make migration history self-consistent again.

- **Files audited in this block:** 11
- **Primary file types:** Prisma migration SQL, Prisma migration metadata
- **Status:** Early chain is coherent; data-migration duplication still needs tighter policy
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-007-backend-root-prisma-foundation]], [[block-006-project-scripts]], [[social]], [[dungeons]], [[economy]]

## Summary

- The early migration chain mixes three very different kinds of changes in one stream: schema migrations, data/content bootstrap migrations, and operator-friendly idempotent patches. That is workable, but the repo currently does not document the boundary between them well enough.
- Two real defects surfaced during this audit:
  1. `backend/prisma/migrations/` was missing `migration_lock.toml`, which prevented Prisma from treating the folder as a normal migration history for tooling such as migration diff.
  2. Migration history never added the extra `EventType` enum values that exist in `schema.prisma` and are already handled by runtime code (`double_xp`, `drop_rate_boost`, `weekend_warrior`).
- The March data migrations (`20260320_*`, `20260322_*`) duplicate catalog content that also lives in `prisma/seed.ts` and code-side gem-pack definitions. That duplication is now one of the clearest database-layer technical debt seams in the repo.
- Follow-up reconcile on `2026-04-19` closed the earlier native-type / constraint-name drift: Prisma history was restored on the shared DB, and `schema.prisma` now explicitly models the long-lived Postgres reality for `guild_challenges`, `milestone_claims`, legacy index names, FK actions, and selected `updated_at` defaults.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | `backend/prisma/migrations/` lacked `migration_lock.toml`. | Prisma could not fully reason about migration history as a standard migrations directory. | Added `backend/prisma/migrations/migration_lock.toml` with `provider = "postgresql"`. |
| P1 | Migration history never added the current `EventType` enum values used by code and documented in `schema.prisma`. | Fresh DBs built from migrations could not represent valid event rows for `double_xp`, `drop_rate_boost`, or `weekend_warrior`, and the old drift guard did not catch it. | Added `20260415_add_missing_event_type_values/migration.sql` and extended `scripts/check_schema_drift.py` to cover enum values. |

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/prisma/migrations/migration_lock.toml` | Prisma migration metadata | Declares the provider for the migrations directory so Prisma can treat it as a valid migration history. | Used by Prisma CLI migration tooling. | Must match the datasource provider (`postgresql`). | File was missing and was added during audit. | Fixed |
| `backend/prisma/migrations/20260306_baseline/migration.sql` | Baseline schema snapshot | Captures the pre-existing live schema as the baseline starting point for Prisma Migrate adoption. | Depends on baseline adoption flow in `backend/prisma/MIGRATIONS.md`; used by `db:migrate:adopt` and fresh-db bootstraps. | Should be treated as historical snapshot, not hand-edited business logic. | Healthy as a baseline. Important context only: several stringly typed domain fields originate here and rely on later discipline in code/seeds. | OK |
| `backend/prisma/migrations/20260312_add_pvp_battle_tickets/migration.sql` | PvP schema delta | Adds `pvp_battle_tickets` plus indexes and FKs used by prepare/resolve flows. | Used by PvP ticket creation/consumption in backend routes/tests. | Ticket rows must stay unique per `(character_id, battle_seed)` and clean up with character/revenge deletion rules. | Coherent migration with appropriate indexes and cascades. | OK |
| `backend/prisma/migrations/20260316_add_daily_gem_card/migration.sql` | Monetization schema delta | Adds `daily_gem_cards` with one row per user. | Used by IAP receipt verification and guest-account upgrade flows. | Exactly one active card row per user via unique `user_id`. | Straightforward and correct. | OK |
| `backend/prisma/migrations/20260320_seed_consumable_items/migration.sql` | Content data migration | Seeds potions and gem-pack catalog rows into `items`. | Depends on `items` table; fresh DB bootstraps consume it. Runtime gem-pack logic also lives in `backend/src/lib/game/gem-packs.ts`. | Uses `ON CONFLICT (catalog_id) DO UPDATE` to keep base consumable catalog present. | Architectural duplication remains: consumable/gem-pack catalog data is split between migration SQL, `prisma/seed.ts`, and code-side gem-pack definitions. | Needs review |
| `backend/prisma/migrations/20260322_catalog_drop_system/migration.sql` | Catalog/drop-system data migration | Backfills `drop_chance`, inserts higher-tier catalog items, adds drop lookup index, and removes orphaned procedural `loot_%` rows. | Depends on `items` + `equipment_inventory`; used indirectly by dungeon/drop/shop systems. | Preserves `loot_%` items still referenced by inventory, but deletes truly orphaned procedural catalog rows. | Powerful but heavy migration: mixes large content inserts, data backfill, and cleanup in one file, and duplicates item catalog content later repeated in `prisma/seed.ts`. | Needs review |
| `backend/prisma/migrations/20260323_add_social_system/migration.sql` | Social schema delta | Adds friendships, direct messages, and `characters.last_active_at`. | Used by social friends/status/message routes. | Friendship uniqueness and message expiry/query indexes are core to the feature. | Migration is structurally sound. Only minor inconsistency: enums/tables are not schema-qualified the same way as baseline SQL. | OK |
| `backend/prisma/migrations/20260324_add_challenges/migration.sql` | Social challenge schema delta | Adds duel/challenge rows linked to PvP matches. | Used by social challenge routes and related PvP flows. | Challenge lifecycle depends on status enum, expiry indexing, and nullable `match_id` once completed. | Clear and coherent. | OK |
| `backend/prisma/migrations/20260327_guild_challenges_milestones/migration.sql` | Guild/milestone schema delta | Adds `guild_challenges` and `milestone_claims` with idempotent raw SQL. | Used by guild challenge logic and milestone claim tracking. | Uses `IF NOT EXISTS`, inline unique constraint, and character cascade deletion. | Follow-up reconcile on `2026-04-19` aligned Prisma to the live DB: `dbgenerated` ids, `@db.Timestamptz(6)` timestamps, preserved legacy index names, and matching FK actions. | Fixed |
| `backend/prisma/migrations/20260329_add_updated_at/migration.sql` | Timestamp harmonization | Adds missing `updated_at` columns to core tables. | Supports Prisma `@updatedAt` fields and asset/API response freshness logic. | Idempotent `ADD COLUMN IF NOT EXISTS` avoids reapply hazards. | Good corrective migration; no issue found. | OK |
| `backend/prisma/migrations/20260415_add_missing_event_type_values/migration.sql` | Audit-created repair migration | Adds missing `EventType` enum values required by current schema and runtime event handling. | Used by event runtime (`backend/src/lib/game/events.ts`) and schema parity tooling. | Additive enum values only; safe to apply repeatedly with `IF NOT EXISTS`. | Created during audit to repair real migration-history drift. | Fixed |

## Duplicate Logic Found

- `20260320_seed_consumable_items` and `prisma/seed.ts` both seed consumable catalog rows.
- `20260322_catalog_drop_system` and `prisma/seed.ts` both own high-tier item catalog content.
- Gem-pack semantics are split between DB rows seeded in `20260320_seed_consumable_items` and code-side definitions in `backend/src/lib/game/gem-packs.ts`.

## Files Without Clear Current Role

- None are roleless, but `20260320_seed_consumable_items` and `20260322_catalog_drop_system` behave more like content bootstrap snapshots than pure schema migrations. They should be treated as such in docs and reviews.

## Candidates For Removal / Refactor

- No deletion candidates in this block.
- Refactor candidates:
  - `20260320_seed_consumable_items` content ownership should eventually collapse into either canonical seed logic or canonical migration/data-pack policy.
  - `20260322_catalog_drop_system` likely wants follow-up documentation or a future extraction policy because it mixes backfill, content insert, indexing, and cleanup.

## Documentation Missing Or Stale

- No current operator doc explains when data belongs in a migration versus in `prisma/seed.ts`.
- No current migration doc warns that column/index drift checks alone are insufficient; enum values matter too.
- Running `prisma migrate diff --from-migrations ...` safely requires a shadow database URL; that operational requirement is not documented in the local migration guidance.

## Follow-up (2026-04-19)

- The shared database referenced by `backend/.env` still had no `_prisma_migrations` table even after later feature work had landed.
- Restored Prisma history with `db:migrate:adopt` + `prisma migrate resolve --applied` for every repo migration already present in the live schema.
- Aligned `backend/prisma/schema.prisma` to the actual long-lived Postgres shape instead of replaying risky historical DDL:
  - `guild_challenges` / `milestone_claims` now use `dbgenerated("(gen_random_uuid())::text")` ids and `@db.Timestamptz(6)` timestamps in Prisma.
  - Legacy index / unique names remain explicit in Prisma (`idx_guild_challenges_dates`, `idx_milestone_claims_character`, `referral_reward_claims_referrer_character_id_invitee_character_`, `pvp_matches_status_idx`).
  - Relation actions now match the live DB on `character_active_slots`, `milestone_claims`, and `pvp_matches.player2_id`.
  - Prisma-side `updatedAt` defaults now match the current DB reality, including removing the extra default from `PremiumSubscription.updatedAt`.
- Result:
  - `npm run db:migrate:status` → `Database schema is up to date!`
  - `npx prisma migrate diff --from-url "$DIRECT_URL" --to-schema-datamodel prisma/schema.prisma --exit-code` → `No difference detected.`

## Verification

- `python3 scripts/check_schema_drift.py --verbose` now passes and reports `64 models, 692 scalar/enum columns, 102 @@index/@@unique decls, 19 enums / 114 enum values`.
- A custom enum-history check confirms migration enum coverage now matches `schema.prisma`.
- `git diff --check` passes after the migration fixes in this block.
- `prisma migrate diff --from-migrations ...` could not be fully run in this environment without a safe shadow database URL; that remains an operational verification gap, not a schema parse failure.
