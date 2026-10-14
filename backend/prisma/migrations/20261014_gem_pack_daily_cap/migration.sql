-- =============================================================================
-- 20261014_gem_pack_daily_cap
--
-- Per-account counter for gold→gem pack purchases, lazily reset per UTC day
-- (same shape as premium_gem_claim_date). Uncapped, gem_pack_large made every
-- gem price in the game cost ~30 gold per gem with no limit, so nothing priced
-- in gems was ever out of reach (2026-10-14 balance audit).
--
-- Additive. Run against prod via Supabase MCP BEFORE deploying the backend.
-- =============================================================================

ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "gem_pack_purchases_today" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "gem_pack_purchase_date" TIMESTAMP(3);
