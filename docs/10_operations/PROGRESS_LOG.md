Original prompt: Act as a principal game engineer, backend architect, performance engineer, QA lead, and security auditor. Audit and improve the entire project to production standard across architecture, database, APIs, gameplay systems, performance, UX responsiveness, testing, and exploit resistance, then report findings in sections A-J plus a Top 20 priority fix list.

## 2026-03-12

- Started full repo audit using the `develop-web-game` skill workflow.
- Confirmed repo contents do not match the prompt exactly:
  - Product/docs name in code is `Hexbound`, not `Iron Fist Arena`.
  - Mobile client present in the repo is Swift/iOS (`Hexbound/Hexbound/...`), while project knowledge says Godot 4.3+ is the target mobile stack.
  - `backend/package.json` and `admin/package.json` are on Next 15 / React 19, while project knowledge says Next 14 / React 18.
- Initial focus areas:
  - Prisma schema and migrations
  - Core server game logic under `backend/src/lib/game`
  - All API routes under `backend/src/app/api`
  - Admin/frontend integration paths that can affect production safety or latency
- Need to verify:
  - auth / ownership enforcement consistency
  - transaction safety for economy-sensitive routes
  - rate limiting coverage
  - duplicated gameplay formulas across server/mobile/admin
  - schema constraints and missing indexes

- Audit findings confirmed in code:
  - Prisma schema is far ahead of migration history; only 3 backend migrations exist for a much larger schema.
  - Several row-lock fixes were broken by using Prisma model names / camelCase columns in raw SQL (`daily-login/claim`, `achievements/claim`, `shop/buy-gems`).
  - `pvp/prepare` + `pvp/resolve` had no server-issued nonce/ticket, so battle resolution was replayable and rewards could be duplicated.
  - `consumables/use` allowed race-driven quantity underflow because it read quantity before the transaction and decremented without a locked guard.
  - `inventory/equip` ignored class restrictions.
  - `shop/buy` ignored inventory capacity.
  - `combat/buy-extra` could overshoot stamina cap and mobile expected a different gems field than the backend returned.

- Implemented fixes:
  - Added `PvpBattleTicket` model + migration and patched PvP prepare/resolve to use one-time battle tickets.
  - Fixed raw SQL table/column mappings in the broken claim/purchase routes.
  - Added locked consumable use with full-state checks to prevent double-use and negative quantities.
  - Enforced class restriction on equip and inventory-capacity check on shop buy.
  - Fixed extra-fight purchase to use regenerated stamina, cap at max, reject full-stamina buys, and return a backward-compatible gems field.
  - Updated the Swift instant-battle flow to pass `battle_ticket_id` and invalidate cached prepare payloads after use.
  - Updated Swift extra-fight parsing to accept both old and new gems field names.

- Verification:
  - `backend`: `npx prisma validate --schema=prisma/schema.prisma` ✅
  - `admin`: `npx prisma validate --schema=prisma/schema.prisma` ✅
  - `backend`: `npx prisma generate --schema=prisma/schema.prisma` ✅
  - `admin`: `npx prisma generate --schema=prisma/schema.prisma` ✅
  - `backend`: `npx tsc --noEmit` ✅
  - `admin`: `npx tsc --noEmit` ✅

- Remaining high-priority TODOs:
  - Apply the new migration in the real database and backfill production deployment flow away from schema-only drift.
  - Centralize reward application logic (PvP, achievements, battle pass, daily login, shop) into shared transactional helpers.
  - Add automated tests for replay attacks, double claims, consumable races, and PvP ticket expiry/consumption.

- Follow-up hardening completed:
  - Added shared `lockDungeonRunForUpdate(...)` helper for `dungeon_runs`.
  - Patched `backend/src/app/api/dungeons/fight/route.ts` to re-check and mutate the run under `FOR UPDATE` before any reward/progress write.
  - Patched `backend/src/app/api/dungeons/run/[id]/fight/route.ts` to lock the run and reject stale/replayed floor resolves on both win and loss paths.
  - Patched `backend/src/app/api/dungeon-rush/resolve/route.ts` to resolve treasure/event/shop rooms from locked run state, preserving `shopPurchased` and preventing duplicate room rewards.
  - Patched `backend/src/app/api/dungeon-rush/fight/route.ts` to consume combat rooms atomically and reject stale/replayed resolve attempts.

- Verification after dungeon anti-dup patch:
  - `backend`: `npx tsc --noEmit` ✅
  - `backend`: `npm run build` ✅

- Remaining high-priority TODOs after this pass:
  - Prisma migration history is still incomplete relative to the live schema.
  - In-memory cache/rate-limit remains weak under horizontal scale.
  - Test coverage for replay/race scenarios is still missing.

- Battle pass hardening completed:
  - Rewrote `backend/src/app/api/battle-pass/claim/[level]/route.ts` into a single interactive transaction with row locks on `characters`, `users`, and `battle_pass`.
  - Claim route now creates the `battle_pass` row on demand, validates claimable rewards under lock, and rolls back the whole claim on invalid reward config instead of partially paying out.
  - Added support in battle pass claims for `gold`, `gems`, `xp`, `stamina`, `item`, `consumable`, and cosmetic unlocks (`skin`, `title`, `frame`, `effect`, generic `cosmetic`).
  - `item` and `chest` rewards now validate inventory capacity before any claim row is written.
  - Added rate limiting to battle pass claims.
  - Updated `backend/prisma/seed-battle-pass.ts` so premium milestone rewards seed as real `item` rewards instead of unsupported `chest` rows with null `rewardId`.

- Verification after battle pass patch:
  - `backend`: `npx tsc --noEmit` ✅
  - `backend`: `npm run build` ✅

- Remaining high-priority TODOs after battle pass pass:
  - Existing databases seeded with old premium `chest` rewards need a reward data reseed/migration to the new valid `item` config.
  - Prisma migration history is still incomplete relative to the live schema.
  - In-memory cache/rate-limit remains weak under horizontal scale.
  - Replay/race regression tests still need deeper DB-backed integration coverage beyond mocked route-level suites.

- Test infrastructure and exploit regressions completed:
  - Added Vitest test harness in `backend` (`package.json` scripts + `vitest.config.ts`).
  - Added `tests/api/pvp-resolve.test.ts` to verify `battle_ticket_id` can only be consumed once and replayed resolves return 409.
  - Added `tests/api/dungeon-rush-resolve.test.ts` to verify stale retried room resolves are rejected after the room has been consumed under lock.
  - Added `tests/api/battle-pass-claim.test.ts` to verify invalid reward config aborts the entire claim without partial payout or claim-row creation.

- Verification after test pass:
  - `backend`: `npm test` ✅
  - `backend`: `npx tsc --noEmit` ✅
  - `backend`: `npm run build` ✅

- Prisma migration baseline normalization completed:
  - Confirmed the live Supabase database had no `_prisma_migrations` table and therefore no applied Prisma history.
  - Confirmed the live database already matched almost the full schema and was only missing the new `pvp_battle_tickets` table.
  - Generated a real baseline migration at `backend/prisma/migrations/20260306_baseline/migration.sql` from the current live schema.
  - Removed the old point migrations `20260307_add_gender_avatar` and `20260309_add_gear_score` because they are now subsumed by the baseline.
  - Added migration workflow documentation in `backend/prisma/MIGRATIONS.md`.
  - Added package scripts for `db:migrate:status`, `db:migrate:dev`, `db:migrate:deploy`, and `db:migrate:adopt`.
  - Added a guardrail warning on `db:push` so schema-only drift is harder to reintroduce on shared databases.

- Verification after migration baseline pass:
  - `backend`: `npm run db:migrate:status` shows only `20260306_baseline` and `20260312_add_pvp_battle_tickets` as unapplied on the existing schema-only database ✅
  - `backend`: `npx prisma validate --schema=prisma/schema.prisma` ✅
  - `backend`: `npm test` ✅
  - `backend`: `npx tsc --noEmit` ✅
  - `backend`: `npm run build` ✅

- Remaining high-priority TODOs after migration baseline pass:
  - Run `db:migrate:adopt` and `db:migrate:deploy` against the real shared database during a controlled deployment window.
  - Replace in-memory cache/rate-limit with shared infrastructure.
  - Add DB-backed integration tests for replay and transaction safety.

- Shared cache/rate-limit hardening completed:
  - Added Upstash-backed shared KV support in `backend/src/lib/shared-kv.ts` with safe memory fallback and one-time production warning when Redis env is missing.
  - Reworked `backend/src/lib/rate-limit.ts` into async shared rate limiting with `@upstash/ratelimit`, including structured metadata for middleware headers.
  - Reworked `backend/src/lib/cache.ts` into async shared cache with Redis prefix invalidation and memory fallback cleanup timers using `unref()`.
  - Updated `backend/src/middleware.ts` to use the shared rate-limit path and preserve response headers.
  - Converted all route/cache call sites across backend routes, auth, admin, and combat helpers to await the new async cache/rate-limit APIs.
  - Switched the shared Redis client to the fetch-based Upstash Cloudflare export to keep Next middleware edge-safe.

- Battle pass data repair + shared config completed:
  - Added shared battle pass milestone mapping in `backend/prisma/battle-pass-milestones.ts`.
  - Added reusable repair helper in `backend/prisma/battle-pass-reward-repair.ts`.
  - Added executable repair script `backend/prisma/fix-battle-pass-rewards.ts` and package script `db:fix:battle-pass-rewards`.
  - Updated `backend/prisma/seed-battle-pass.ts` to use the shared milestone config instead of duplicating item mappings.

- Performance pass completed:
  - Optimized `backend/src/app/api/game/init/route.ts` to replace achievement row fetches with `count()` queries and narrower `select` payloads for consumables, quests, and active events.
  - Optimized `backend/src/app/api/shop/items/route.ts` to filter owned items in Prisma instead of loading ownership rows and filtering in JS, while narrowing the selected item payload.

- Test coverage expanded:
  - Added `backend/tests/lib/rate-limit.test.ts` for memory-fallback rate-limit contract.
  - Added `backend/tests/lib/cache.test.ts` for shared cache prefix invalidation contract.
  - Added `backend/tests/prisma/battle-pass-reward-repair.test.ts` for legacy reward repair behavior.

- Verification after shared infra / perf / repair pass:
  - `backend`: `npm test` ✅
  - `backend`: `npx tsc --noEmit` ✅
  - `backend`: `npx prisma validate --schema=prisma/schema.prisma` ✅
  - `backend`: `npm run build` ✅

- Remaining operational TODO after this pass:
  - Run `npm run db:migrate:adopt` and `npm run db:migrate:deploy` against the real shared database.
  - Configure `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN` in shared environments so cache/rate-limit stop falling back to per-instance memory.
  - Run `npm run db:fix:battle-pass-rewards` against existing shared data if legacy premium milestone rows are present.

## 2026-03-13

- Investigated live regression where only PvP battles stopped launching from the iOS client.
- Confirmed root cause was infrastructure drift, not the Swift PvP flow:
  - `backend/.env` points at the shared Supabase database.
  - `npm run db:migrate:status` showed `20260306_baseline` and `20260312_add_pvp_battle_tickets` were unapplied there.
  - The current `/api/pvp/prepare` route now requires `pvp_battle_tickets`, so only PvP failed while the rest of the game continued to work.
- Applied the intended production-safe Prisma workflow on the shared database:
  - `backend`: `npm run db:migrate:adopt` ✅
  - `backend`: `npm run db:migrate:deploy` ✅
  - `backend`: `npm run db:migrate:status` → `Database schema is up to date!` ✅
  - `backend`: `npx tsc --noEmit` ✅
- Expected outcome:
  - `/api/pvp/prepare` can now create battle tickets again.
  - PvP combat should launch normally again without further client changes.

- Full audit + verification pass completed across current repo state:
  - `backend`: `npm test` ✅
  - `backend`: `npx tsc --noEmit` ✅ after rebuild; initial run hit stale `.next/types/* 2.ts` / `* 3.ts` duplicate artifacts
  - `backend`: `npm run build` ✅
  - `admin`: `npx tsc --noEmit` ✅ after rebuild; initial run hit the same stale `.next/types` duplicate-artifact issue
  - `admin`: `npm run build` ✅
  - `Hexbound`: `xcodebuild -scheme Hexbound -project Hexbound/Hexbound.xcodeproj -destination 'generic/platform=iOS Simulator' build` ✅
  - `backend` + `admin`: `npm run lint` ❌ both scripts launch interactive `next lint` setup instead of a real non-interactive lint pass

- Audit findings from this pass:
  - `backend/src/app/api/dev/fix-avatars/route.ts` is a production-mutating endpoint with no auth or environment guard; any caller can rewrite character avatars.
  - Hub quick-heal depends on `appState.cachedInventory`; if inventory was never opened it tells the player to "Open inventory first", and after a successful potion use `InventoryService.useItem(...)` clears that cache so the hub potion button effectively disables itself until inventory is reloaded.
  - There is still no automated iOS test target in `Hexbound.xcodeproj`; mobile regressions are only covered by compile success right now.

- Follow-up TODOs from this audit:
  - Lock down or remove `/api/dev/fix-avatars` outside local/dev environments.
  - Decouple hub potion quick-use from `cachedInventory` invalidation by either refreshing the cache after use or maintaining local consumable counts.
  - Replace `next lint` scripts with ESLint CLI config so lint can run in CI.
