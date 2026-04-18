-- Unified Interactive Combat — opponent can be a real player, bot, or dungeon boss.
-- When opponent_type != 'pvp', player2_id is null and opponent_snapshot carries stats.
-- All changes are ADDITIVE and backwards-compatible with the existing PvP flow
-- (existing rows keep player2_id NOT NULL-behavior via application logic).

-- 1) Make player2_id nullable at the column level. FK constraint stays;
--    PostgreSQL FKs permit NULL values by default.
ALTER TABLE "pvp_matches" ALTER COLUMN "player2_id" DROP NOT NULL;

-- 2) New nullable columns.
ALTER TABLE "pvp_matches" ADD COLUMN "opponent_type" TEXT DEFAULT 'pvp';
ALTER TABLE "pvp_matches" ADD COLUMN "opponent_snapshot" JSONB;
ALTER TABLE "pvp_matches" ADD COLUMN "dungeon_run_id" TEXT;
ALTER TABLE "pvp_matches" ADD COLUMN "boss_key" TEXT;
ALTER TABLE "pvp_matches" ADD COLUMN "bot_key" TEXT;

-- 3) Backfill existing rows so `opponent_type = 'pvp'` is explicit
--    (the column default only applies to new rows).
UPDATE "pvp_matches" SET "opponent_type" = 'pvp' WHERE "opponent_type" IS NULL;

-- 4) Index for the common query pattern: list in-progress matches by mode.
CREATE INDEX "pvp_matches_opponent_type_status_idx" ON "pvp_matches"("opponent_type", "status");
