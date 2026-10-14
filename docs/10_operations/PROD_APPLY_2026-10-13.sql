-- =============================================================================
-- Hexbound — production migrations, 2026-10-13
--
-- HOW TO RUN: Supabase → project PVP_RPG (gqnyozmqbhgzprsftdzp) → SQL Editor →
-- paste this whole file → Run. One transaction: either everything applies or
-- nothing does. Every statement is idempotent, so re-running is safe.
--
-- Run BEFORE `git push` of backend (Vercel deploys the code that needs this).
-- Concatenation of backend/prisma/migrations/{7 dirs} in order — do not edit
-- here; edit the migration files and regenerate.
-- =============================================================================
BEGIN;

-- ───────────────────────────── 20260912_stamina_potion_daily_cap ─────────────────────────────

ALTER TABLE "characters"
  ADD COLUMN IF NOT EXISTS "stamina_potions_today" INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "characters"
  ADD COLUMN IF NOT EXISTS "stamina_potions_date" TIMESTAMP(3);

-- ───────────────────────────── 20260912_gold_mine_active_slot_unique ─────────────────────────────

CREATE UNIQUE INDEX IF NOT EXISTS "gold_mine_sessions_active_slot_uniq"
  ON "gold_mine_sessions" ("character_id", "slot_index")
  WHERE "collected" = false;

-- ───────────────────────────── 20260915_rank_achievement_targets ─────────────────────────────

UPDATE "achievement_definitions" SET "target" = 750  WHERE "key" = 'rank_silver'      AND "target" <> 750;
UPDATE "achievement_definitions" SET "target" = 1500 WHERE "key" = 'rank_gold'        AND "target" <> 1500;
UPDATE "achievement_definitions" SET "target" = 3000 WHERE "key" = 'rank_diamond'     AND "target" <> 3000;
UPDATE "achievement_definitions" SET "target" = 4250 WHERE "key" = 'rank_grandmaster' AND "target" <> 4250;

UPDATE "achievements" SET "target" = 750  WHERE "achievement_key" = 'rank_silver'      AND "target" <> 750;
UPDATE "achievements" SET "target" = 1500 WHERE "achievement_key" = 'rank_gold'        AND "target" <> 1500;
UPDATE "achievements" SET "target" = 3000 WHERE "achievement_key" = 'rank_diamond'     AND "target" <> 3000;
UPDATE "achievements" SET "target" = 4250 WHERE "achievement_key" = 'rank_grandmaster' AND "target" <> 4250;

UPDATE "achievements"
   SET "completed" = true,
       "completed_at" = COALESCE("completed_at", NOW())
 WHERE "achievement_key" IN ('rank_silver', 'rank_gold', 'rank_diamond', 'rank_grandmaster')
   AND "completed" = false
   AND "progress" >= "target";

-- ───────────────────────────── 20261013_deactivate_over_cap_dungeons ─────────────────────────────
UPDATE "dungeons"
SET "is_active" = false, "updated_at" = NOW()
WHERE "level_req" > 50 AND "is_active" = true;

-- ───────────────────────────── 20261013_premium_renewal_gems_idempotency ─────────────────────────────
ALTER TABLE "premium_subscriptions"
  ADD COLUMN IF NOT EXISTS "renewal_gems_tx_id" TEXT;

-- ───────────────────────────── 20261013_analytics_events ─────────────────────────────
CREATE TABLE IF NOT EXISTS "analytics_events" (
  "id"           TEXT PRIMARY KEY,
  "name"         TEXT NOT NULL,
  "user_id"      TEXT,
  "character_id" TEXT,
  "source"       TEXT NOT NULL DEFAULT 'server',
  "props"        JSONB,
  "created_at"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "analytics_events_name_created_at_idx" ON "analytics_events" ("name", "created_at");
CREATE INDEX IF NOT EXISTS "analytics_events_user_id_created_at_idx" ON "analytics_events" ("user_id", "created_at");
CREATE INDEX IF NOT EXISTS "analytics_events_created_at_idx" ON "analytics_events" ("created_at");

-- ───────────────────────────── 20261013_user_reports ─────────────────────────────
CREATE TABLE IF NOT EXISTS "user_reports" (
  "id"                    TEXT PRIMARY KEY,
  "reporter_user_id"      TEXT NOT NULL,
  "reporter_character_id" TEXT,
  "target_user_id"        TEXT NOT NULL,
  "target_character_id"   TEXT,
  "category"              TEXT NOT NULL,
  "reason"                VARCHAR(500),
  "context_type"          TEXT NOT NULL DEFAULT 'profile',
  "context_id"            TEXT,
  "snapshot"              VARCHAR(500),
  "status"                TEXT NOT NULL DEFAULT 'open',
  "resolution"            VARCHAR(500),
  "resolved_by"           TEXT,
  "resolved_at"           TIMESTAMP(3),
  "created_at"            TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "user_reports_status_created_at_idx" ON "user_reports" ("status", "created_at");
CREATE INDEX IF NOT EXISTS "user_reports_target_user_id_idx" ON "user_reports" ("target_user_id");
CREATE INDEX IF NOT EXISTS "user_reports_reporter_user_id_created_at_idx" ON "user_reports" ("reporter_user_id", "created_at");

COMMIT;

-- ───────────────────────────── verification ─────────────────────────────
-- Expect: 7 rows, every `ok` = true.
SELECT 'characters.stamina_potions_today' AS what,
       EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='characters' AND column_name='stamina_potions_today') AS ok
UNION ALL SELECT 'gold_mine_sessions_active_slot_uniq',
       EXISTS (SELECT 1 FROM pg_indexes WHERE indexname='gold_mine_sessions_active_slot_uniq')
UNION ALL SELECT 'achievement_definitions.rank_silver=750',
       EXISTS (SELECT 1 FROM achievement_definitions WHERE key='rank_silver' AND target=750)
UNION ALL SELECT 'dungeons level_req>50 inactive',
       NOT EXISTS (SELECT 1 FROM dungeons WHERE level_req>50 AND is_active)
UNION ALL SELECT 'premium_subscriptions.renewal_gems_tx_id',
       EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='premium_subscriptions' AND column_name='renewal_gems_tx_id')
UNION ALL SELECT 'analytics_events table',
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='analytics_events')
UNION ALL SELECT 'user_reports table',
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='user_reports');
