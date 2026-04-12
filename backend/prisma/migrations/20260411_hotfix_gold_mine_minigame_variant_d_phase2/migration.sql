-- Hotfix 2026-04-11: Gold Mine Variant D Phase 2 schema drift.
-- Commit d4450b4 added fields to schema.prisma (GoldMineSession, MinigameSession)
-- without a migration file. Prod was returning 500 for:
--   /api/characters (via Character-related queries touching relations)
--   /api/gold-mine/*
--   /api/minigames/*
--   /api/social/messages/*
-- This migration adds ALL missing columns + indexes discovered by a full
-- schema.prisma <-> information_schema diff. Non-destructive, idempotent.

-- gold_mine_sessions: per-slot mini-game linkage
ALTER TABLE "gold_mine_sessions" ADD COLUMN IF NOT EXISTS "minigame_session_id" TEXT;
ALTER TABLE "gold_mine_sessions" ADD COLUMN IF NOT EXISTS "minigame_played_at" TIMESTAMP(3);

-- minigame_sessions: Gold Mine Rush falling-coins mini-game fields
ALTER TABLE "minigame_sessions" ADD COLUMN IF NOT EXISTS "shaft_key" TEXT;
ALTER TABLE "minigame_sessions" ADD COLUMN IF NOT EXISTS "passive_gold_amount" INTEGER;
ALTER TABLE "minigame_sessions" ADD COLUMN IF NOT EXISTS "cap_gold" INTEGER;
ALTER TABLE "minigame_sessions" ADD COLUMN IF NOT EXISTS "expires_at" TIMESTAMP(3);
ALTER TABLE "minigame_sessions" ADD COLUMN IF NOT EXISTS "claimed_gold" INTEGER;
ALTER TABLE "minigame_sessions" ADD COLUMN IF NOT EXISTS "claimed_gems" INTEGER;
ALTER TABLE "minigame_sessions" ADD COLUMN IF NOT EXISTS "caught_count" INTEGER;
ALTER TABLE "minigame_sessions" ADD COLUMN IF NOT EXISTS "spawned_count" INTEGER;
ALTER TABLE "minigame_sessions" ADD COLUMN IF NOT EXISTS "claimed_at" TIMESTAMP(3);

-- Missing indexes from schema.prisma
CREATE INDEX IF NOT EXISTS "minigame_sessions_character_id_game_type_status_idx" ON "minigame_sessions" ("character_id", "game_type", "status");
CREATE INDEX IF NOT EXISTS "minigame_sessions_expires_at_idx" ON "minigame_sessions" ("expires_at");
