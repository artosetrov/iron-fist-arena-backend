---
title: Audit Block 007 — Backend Root and Prisma Foundation
category: audit
tags: [audit, backend, prisma, seeds, config, schema]
sources:
  - backend/
  - backend/prisma/
  - docs/features/dungeons/DUNGEONS_OVERVIEW.md
  - docs/features/combat/INTERACTIVE_COMBAT_PLAN.md
  - docs/10_operations/DEPLOY.md
  - docs/10_operations/PROGRESS_LOG.md
updated: 2026-04-15
---

# Audit Block 007 — Backend Root and Prisma Foundation

## Scope

This block covers the 21 backend root/config files plus top-level Prisma schema, seed, repair, and bootstrap SQL files. Historical migration directories are intentionally excluded and will be audited as a separate block because they need sequence-aware review.

- **Files audited in this block:** 21
- **Primary file types:** env/template, toolchain config, Prisma schema, TypeScript seed/repair scripts, SQL bootstrap scripts
- **Status:** Core foundation is usable, but several "seed" files are actually bootstrap/reset tooling and needed clearer contracts
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-006-project-scripts]], [[economy]], [[dungeons]], [[passive-tree]], [[interactive-combat]]

## Summary

- The block splits into four layers: backend runtime/tooling config, package/toolchain manifests, Prisma schema contract, and operational data bootstrap scripts.
- The biggest risks were not syntax-level bugs but **operator traps**: files named like ordinary seeds while behaving like reset/repair tools, plus incomplete bootstrap documentation around `npm run db:seed`.
- `backend/prisma/schema.prisma` is the central backend contract. It is broadly healthy and validates cleanly, but a few domain-critical fields are still free-form strings (`BattlePassReward.rewardType`, `BossAbility.abilityType`/`specialEffect`) which means some content mistakes can slip past compile-time checks.
- `seed.ts` remains the canonical core catalog/bootstrap entrypoint, but feature data is fragmented across additional manual scripts (`seed-balance.ts`, `seed-dungeons.ts`, `seed-dungeon-drops.ts`, `seed-battle-pass.ts`, passive-tree SQL). That is workable, but it must be documented precisely.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | `backend/.env.example` did not document several env vars that the backend actually reads. | Fresh setup and deploys can look valid while missing rate-limit, bot-ticket, IAP, APNS, CORS, or feature-flag configuration. | Added missing placeholders for app URL, CORS, interactive combat, Upstash, bot-ticket, Apple IAP, and APNS variables. |
| P1 | `backend/prisma/seed-battle-pass.ts` updated Season 1 `startAt`/`endAt` on every re-run. | Re-running the seed could silently move the live season window forward. | Changed the `upsert` to preserve existing season dates and typed the seeded `rewardType` values to the known supported set. |
| P1 | `backend/prisma/MIGRATIONS.md` described `npm run db:seed` like a full fresh bootstrap. | Operators could deploy a "healthy" empty database that still lacks battle pass, balance, dungeon, and passive-tree content. | Clarified that `db:seed` only runs `prisma/seed.ts` and documented the additional feature/bootstrap steps. |
| P1 | `backend/prisma/seeds/passive-tree.sql` is destructive bootstrap SQL but did not say so strongly enough. | Running it against live player data would wipe passive progression. | Added an explicit warning that it deletes `character_passives` and must be treated as bootstrap/reset-only. |
| P2 | `backend/prisma/seed.ts` hardcoded one Supabase asset origin. | Seeded catalog image URLs would drift across environments or future storage moves. | Switched image URL generation to `NEXT_PUBLIC_SUPABASE_URL` with a fallback default. |
| P2 | Several files had implicit operator assumptions only in the author's head. | Misuse risk during manual operations. | Added explicit comments to `seed-balance.ts`, `seed-dungeons.ts`, and `passive-tree-activatable.sql` about create-only behavior, skip-existing behavior, and prerequisite ordering. |
| P3 | `backend/prisma/seed.ts` contained an unused helper; `backend/prisma/seed-dungeon-drops.ts` had avoidable mutable lint noise. | Small but recurring signal loss during maintenance. | Removed dead `pick()` and converted `skippedSlugs` to `const`. |

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/.env.example` | Backend env contract | Documents the expected local/deploy environment for Supabase, DB, CORS, feature flags, Redis, bot tickets, Apple IAP, and push. | Depends on actual env usage in `backend/src/middleware.ts`, `backend/src/lib/apple-iap.ts`, `backend/src/lib/push/send.ts`, auth routes, PvP routes/tests. Used by operators and deploy setup. | Must stay aligned with real runtime env reads; otherwise "works on one machine" setup bugs appear. | Missing real envs were added during audit. Cross-file doc drift still exists in some deploy docs outside this block. | Fixed |
| `backend/.gitignore` | Local backend hygiene | Keeps local env, Next build output, and generated TS state out of Git. | Used by Git and local dev only. | Backend secrets/build artifacts must stay untracked. | Clear and minimal. No issue found. | OK |
| `backend/CLAUDE.md` | Backend contributor rules | Captures backend-specific coding rules: async config, Prisma conventions, economy safety, rate-limit rules, migrate gotchas, and common footguns. | Depends on root `CLAUDE.md`, backend gameplay libs, and economy docs. Used by local AI/dev workflows. | Acts as operational guardrail; should reflect actual code contracts, not aspirations. | Content is strong and mostly current. No safe fix needed in this block. | OK |
| `backend/eslint.config.mjs` | Lint config | Defines backend lint ignores and extends Next/TypeScript lint presets. | Depends on ESLint 9, `@eslint/eslintrc`, `eslint-config-next`. Used by `npm run lint`. | Must match the repo's Next/TS stack and exclude generated Prisma/Next output. | Config is coherent. Remaining broader lint debt belongs to source files, not this config. | OK |
| `backend/next.config.ts` | Next runtime/build config | Keeps the backend in API-only mode and excludes optional `sharp` binaries from Next tracing. | Used by `next dev`, `next build`, `next start`. | Build should not fail because optional image binaries are absent on server targets. | Clear and aligned with current backend role. | OK |
| `backend/package-lock.json` | Dependency lockfile | Pins the backend dependency graph (`lockfileVersion: 3`, 494 packages). | Depends on `backend/package.json`. Used by npm install/CI reproducibility. | Must stay in sync with declared dependencies. | Parsed cleanly; no direct issue found in this block. | OK |
| `backend/package.json` | Backend manifest | Declares backend scripts, runtime deps, dev deps, and Prisma workflows. | Used by npm, local dev, CI, and deployment. | `build` must run `prisma generate` first; `db:push` is local-only; migration scripts must keep schema history coherent. | Scripts are sensible. One architectural note: `db:seed` only covers `prisma/seed.ts`, so full feature bootstrap is intentionally fragmented. | OK |
| `backend/prisma/MIGRATIONS.md` | Prisma operator doc | Explains baseline adoption, deploy flow, `db:push` restrictions, Redis cache envs, and legacy battle-pass repair. | Depends on current migration strategy and package scripts. Used by operators during setup/deploy. | Must describe the real bootstrap path, especially around baseline adoption and seed scope. | Fresh-bootstrap section was incomplete. Updated to document additional feature/bootstrap steps beyond `db:seed`. | Fixed |
| `backend/prisma/battle-pass-milestones.ts` | Shared battle-pass catalog map | Maps premium milestone levels to item catalog IDs. | Depends on item catalog IDs from `prisma/seed.ts`. Used by `seed-battle-pass.ts`, `battle-pass-reward-repair.ts`, and repair tests. | Single source of truth for curated premium milestone items. | Good deduplication point; no issue found. | OK |
| `backend/prisma/battle-pass-reward-repair.ts` | Battle-pass repair helper | Repairs legacy premium milestone rewards so they point at valid item rows. | Depends on Prisma `item` + `battlePassReward`, milestone map. Used by CLI wrapper and tests. | Only premium milestone rows should be rewritten; missing catalog items must fail loudly. | Transaction-wrapped and test-covered. No safe fix needed. | OK |
| `backend/prisma/fix-battle-pass-rewards.ts` | Repair CLI wrapper | Runs the battle-pass repair helper with a real `PrismaClient`. | Depends on `battle-pass-reward-repair.ts`. Used by `npm run db:fix:battle-pass-rewards`. | Thin operator entrypoint; should stay boring and explicit. | Good wrapper, no issue found. | OK |
| `backend/prisma/schema.prisma` | Authoritative DB contract | Declares all Prisma models/enums and maps app names to live Postgres names. | Depends on `DATABASE_URL`/`DIRECT_URL`. Used by `prisma generate/validate/migrate`, all backend Prisma calls, tests, and drift guards. | This is the canonical schema source of truth; migrations must stay in lockstep. | Validates cleanly. Important review note: some domain-critical content fields remain free-form strings (`BattlePassReward.rewardType`, `BossAbility.abilityType`, `BossAbility.specialEffect`), so invalid content can still bypass compile-time safety. | Needs review |
| `backend/prisma/seed-balance.ts` | Economy config bootstrap | Seeds default `GameConfig` values and `ItemBalanceProfile` rows used by item-balance logic/admin. | Depends on `GameConfig`/`ItemBalanceProfile` tables. Used manually; runtime consumers include `backend/src/lib/game/config.ts`, `backend/src/lib/game/item-balance.ts`, and admin item-balance routes. | Intentionally create-only: fills missing defaults but does not overwrite live-tuned config on re-run. | Added explicit comments documenting create-only semantics. Architectural gap remains: no first-class reconcile/update path when defaults evolve. | Needs review |
| `backend/prisma/seed-battle-pass.ts` | Season + reward bootstrap | Ensures Season 1 exists and recreates the per-level battle-pass reward rows. | Depends on `Season`, `BattlePassReward`, item catalog from `seed.ts`, milestone map. Used manually; data is consumed by battle-pass routes and admin seasons tools. | Season dates should not move on re-run; premium milestone rewards must map to supported item rewards only. | Fixed season-window drift, added stronger live-data warning, and narrowed seeded `rewardType` to supported literals. Still a reset-style script because it deletes and recreates season rewards. | Fixed |
| `backend/prisma/seed-dungeon-drops.ts` | Dungeon drop-table bootstrap | Rebuilds `DungeonDrop` rows per dungeon slug from a catalog-based definition map. | Depends on `Dungeon` rows, item catalog from `seed.ts`. Used manually; runtime dungeon rewards depend on its output. | Idempotent by replacement: existing drop rows for a dungeon are deleted and recreated from definitions. | Logic is coherent. Removed a small lint smell; otherwise acceptable as config-rebuild tooling. | Fixed |
| `backend/prisma/seed-dungeons.ts` | Dungeon content bootstrap | Creates the post-baseline dungeon catalog, bosses, and boss ability definitions for the feature set. | Depends on `Dungeon`, `DungeonBoss`, `BossAbility` schema and manual operator execution. Referenced by dungeon docs. | Existing slugs are skipped entirely; re-runs add missing dungeons but do not reconcile changed live definitions. | Added explicit skip-existing warning. Important unresolved risk: boss ability content is stringly typed (`abilityType`, `specialEffect`) and existing rows are never updated by re-run. | Needs review |
| `backend/prisma/seed.ts` | Core bootstrap seed | Seeds core item catalog, item imagery, and PvP bot roster; this is the `db:seed` entrypoint. | Depends on Prisma enums/models and optional `NEXT_PUBLIC_SUPABASE_URL`. Used by `npm run db:seed`; downstream consumers include shop, inventory, dungeon drops, battle pass, and PvP bot flows. | Acts as the base catalog seed that other feature seeds assume already ran. | Fixed hardcoded asset host and removed dead code. Larger architectural note: it is only the *core* seed, not the full feature bootstrap. | Fixed |
| `backend/prisma/seeds/passive-tree-activatable.sql` | Interactive-combat overlay seed | Marks 8 passive nodes as activatable and fills active-slot metadata. | Depends on `passive-tree.sql` having already seeded matching `node_key` rows and on active-slot schema columns. Used by interactive-combat rollout docs/manual ops. | Safe to re-run because it is update-only, but it is not self-sufficient. | Added prerequisite note clarifying that missing base nodes will be silently skipped. | Fixed |
| `backend/prisma/seeds/passive-tree.sql` | Passive-tree bootstrap/reset SQL | Recreates the passive-tree catalog and graph edges from scratch. | Depends on passive-tree tables/enums in schema. Used by passive-tree feature rollout/manual bootstrap. | Destructive reset: deletes `character_passives`, `passive_connections`, and `passive_nodes` before insert. | Added a strong live-data warning. It is still intentionally destructive and must stay out of casual production workflows. | Fixed |
| `backend/tsconfig.json` | TS compiler config | Configures strict TypeScript, Next plugin integration, incremental typing, and the `@/*` alias. | Used by TypeScript, Next, Vitest, editors, and ESLint resolution. | Alias and strictness must match source layout. | Clean and conventional. No issue found. | OK |
| `backend/vitest.config.ts` | Test runner config | Defines node/globals test environment and `@` alias for backend tests. | Depends on Vitest and `backend/src` alias. Used by `npm run test`. | Test alias must match runtime/source alias to avoid false green tests. | Small and correct. No issue found. | OK |

## Duplicate Logic Found

- `seed-battle-pass.ts` and `battle-pass-reward-repair.ts` both manipulate premium milestone reward rows; the shared `battle-pass-milestones.ts` map is the right deduped source, but the presence of a dedicated repair path confirms this domain already suffered from bad seed data once.
- `seed.ts`, `seed-balance.ts`, `seed-dungeons.ts`, `seed-dungeon-drops.ts`, and the passive-tree SQL together form one conceptual "bootstrap dataset", but they are split across manual entrypoints. This is not wrong, but it is operationally fragmented.
- `schema.prisma` leaves several content contracts as plain strings while seed scripts and routes implicitly assume closed sets. This is duplication between code expectations and untyped database content.

## Files Without Clear Current Role

- No file in this block is truly roleless, but three files need sharper labeling in the project mental model:
  - `backend/prisma/fix-battle-pass-rewards.ts` is a one-off repair utility, not part of normal bootstrap.
  - `backend/prisma/seeds/passive-tree.sql` is destructive reset/bootstrap SQL, not a casual repeatable seed.
  - `backend/prisma/seeds/passive-tree-activatable.sql` is a feature overlay step, not a standalone bootstrap.

## Candidates For Removal / De-Tracking

- No direct deletion candidates in this block.
- Review candidate: move repair/bootstrap-only artifacts into clearer folders or naming (`repairs/`, `bootstrap/`, `destructive/`) so they are harder to mistake for safe everyday seeds.

## Documentation Missing Or Stale

- `docs/04_database/MIGRATIONS.md` and `docs/10_operations/DATABASE_MIGRATIONS.md` still describe `npm run db:seed` generically; they should be reconciled later with the clarified `backend/prisma/MIGRATIONS.md`.
- `docs/features/dungeons/DUNGEONS_OVERVIEW.md` names the dungeon seeds but does not explain that `seed-dungeons.ts` is add-only and `seed-dungeon-drops.ts` is replace-by-dungeon.
- No current operator page clearly lists the full recommended bootstrap order for all backend feature data in one place.
- No current schema-level doc explains which free-form string fields are content DSLs versus human-readable descriptions.

## Verification

- `bash -lc 'cd backend && npx prisma validate --schema=prisma/schema.prisma'` passes.
- `npm --prefix backend run test -- tests/prisma/battle-pass-reward-repair.test.ts` passes (`2/2` tests).
- Targeted ESLint passes for the audited TypeScript/config files in this block when run from `backend/`.
- Earlier shared guards still pass after these changes: `python3 scripts/check_schema_drift.py --verbose`, `python3 scripts/ds-drift-check.py`, `bash scripts/check_ios_backend_drift.sh`.
