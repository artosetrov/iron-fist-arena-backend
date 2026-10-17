-- =============================================================================
-- 20261017_gem_economy_prices
--
-- Balance audit 2026-10-16 §6. The shop CHARGES from code (GEM_PACKS and
-- consumable-pricing.ts), so these rows only make the items catalog agree with
-- what the player is actually charged: large stamina potion 500 → 2,000 and
-- the gem-pack ladder 500 / 3,000 / 7,500 (50 → 60 → 75 gold per gem).
-- The rows previously said 500 / 150 / 750 / 1,500.
--
-- Idempotent. Run against prod via Supabase MCP BEFORE deploying the backend.
-- =============================================================================

UPDATE "items" SET "buy_price" = 2000 WHERE "catalog_id" = 'stamina_potion_large' AND "buy_price" <> 2000;
UPDATE "items" SET "buy_price" = 500  WHERE "catalog_id" = 'gem_pack_small'  AND "buy_price" <> 500;
UPDATE "items" SET "buy_price" = 3000 WHERE "catalog_id" = 'gem_pack_medium' AND "buy_price" <> 3000;
UPDATE "items" SET "buy_price" = 7500 WHERE "catalog_id" = 'gem_pack_large'  AND "buy_price" <> 7500;
