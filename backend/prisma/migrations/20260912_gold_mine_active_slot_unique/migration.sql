-- =============================================================================
-- 20260912_gold_mine_active_slot_unique
--
-- One uncollected mining session per (character, slot) — enforced by the
-- database, not by a read-then-write check in the route.
--
-- Why: POST /api/minigames/gold-mine/start did `findFirst({ collected: false })`
-- and then `create()`, outside any transaction, with nothing in the schema
-- preventing duplicates. Two concurrent taps both saw "no active session" and
-- both created one; /collect-all then paid out for each. N taps = N× passive
-- gold from one slot.
--
-- A partial unique index is the right shape here: it constrains only the
-- ACTIVE rows, so the history of collected sessions can grow freely.
-- Prisma's schema language cannot express a partial index, so it lives here in
-- SQL — see the note on model GoldMineSession in schema.prisma.
--
-- If this fails with a duplicate-key error, prod already contains duplicate
-- active sessions from the old race. Collapse them first, keeping the earliest:
--
--   DELETE FROM gold_mine_sessions a
--    USING gold_mine_sessions b
--    WHERE a.collected = false AND b.collected = false
--      AND a.character_id = b.character_id
--      AND a.slot_index = b.slot_index
--      AND (a.created_at, a.ctid) > (b.created_at, b.ctid);
--
-- The ctid tiebreak matters: duplicates created by a double-tap often share a
-- created_at to the millisecond, and comparing created_at alone would delete
-- nothing while the index still refuses to build. Note this discards the
-- duplicate's `reward` / `gem_reward` — that gold was never legitimately
-- earned, but say so if anyone asks where it went.
--
-- Run this against prod via Supabase MCP BEFORE deploying the backend.
-- =============================================================================

CREATE UNIQUE INDEX IF NOT EXISTS "gold_mine_sessions_active_slot_uniq"
  ON "gold_mine_sessions" ("character_id", "slot_index")
  WHERE "collected" = false;
