-- =============================================================================
-- 20260912_stamina_potion_daily_cap
--
-- Adds the per-character daily counter for stamina potions.
--
-- Why: stamina is the only throttle on how long a session can run, and gem
-- refills were already capped at 4/day (STAMINA_REFILL_DR.DAILY_CAP). Potions
-- restore the same bar — a large one restores it entirely — and had no cap at
-- all, while contraband handed out roughly 24 of them per character per day.
-- The result was ~430 PvP fights/day against a stamina budget meant for ~21.
--
-- Lazy reset, same pattern as dungeon_clears_today / stamina_refills_today:
-- the companion *_date column is compared to today on read, so no cron job.
--
-- Run this against prod via Supabase MCP BEFORE deploying the backend.
-- =============================================================================

ALTER TABLE "characters"
  ADD COLUMN IF NOT EXISTS "stamina_potions_today" INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "characters"
  ADD COLUMN IF NOT EXISTS "stamina_potions_date" TIMESTAMP(3);
