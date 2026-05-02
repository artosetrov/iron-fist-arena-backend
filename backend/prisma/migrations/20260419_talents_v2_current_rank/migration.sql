-- Talents v2 — adds per-character rank progression on passive nodes and
-- a weekly-free-respec timestamp. Design doc: docs/06_game_systems/SKILL_TREE_DESIGN_V2.md
--
-- Invariants:
--   * current_rank = 0 means "unlocked (row exists) but no magnitudes applied" — only
--     temporarily true during a rank-up transaction; the unlock endpoint always writes
--     current_rank >= 1 atomically, so 0 should never persist across a request boundary.
--   * current_rank must be within [0, 3]. Keystones and Ultimates always stay at 1
--     once purchased — their `PassiveNode.cost` is still the total SP outlay (3 or 5).
--
-- IF NOT EXISTS keeps this idempotent if prod already has the column applied out-of-band
-- via Supabase MCP. Apply the DDL to prod BEFORE deploying code that
-- references `current_rank`.

ALTER TABLE "character_passives"
  ADD COLUMN IF NOT EXISTS "current_rank" INTEGER NOT NULL DEFAULT 1;

ALTER TABLE "character_passives"
  DROP CONSTRAINT IF EXISTS "character_passives_current_rank_range_chk";

ALTER TABLE "character_passives"
  ADD CONSTRAINT "character_passives_current_rank_range_chk"
  CHECK ("current_rank" >= 0 AND "current_rank" <= 3);

ALTER TABLE "characters"
  ADD COLUMN IF NOT EXISTS "last_free_respec_at" TIMESTAMP(3);
