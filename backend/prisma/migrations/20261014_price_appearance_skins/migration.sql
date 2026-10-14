-- =============================================================================
-- 20261014_price_appearance_skins
--
-- All 48 appearance skins shipped at price_gold 0 / price_gems 0. Cosmetics
-- are the one sink that can absorb a gold surplus without touching power, and
-- the 2026-10-14 audit measured that surplus at +4 500–9 000 gold/day with
-- everything else bought out by day 10. Server-side enforcement of skin prices
-- already exists (AUDIT-2026-10-13 H5); this gives it prices to enforce.
--
-- Ladder per (origin, gender), alphabetical by skin_key, matching the seed:
--   1st  default   free
--   2nd  uncommon  2 500 gold
--   3rd  rare      8 000 gold
--   4th  epic      400 gems
--
-- Only rows still at 0/0 are touched, so an operator's manual pricing is kept.
-- Run against prod via Supabase MCP BEFORE deploying the backend.
-- =============================================================================

WITH ranked AS (
  SELECT "id",
         ROW_NUMBER() OVER (PARTITION BY "origin", "gender" ORDER BY "skin_key") AS pos
    FROM "appearance_skins"
)
UPDATE "appearance_skins" s
   SET "rarity"     = CASE r.pos WHEN 1 THEN 'common' WHEN 2 THEN 'uncommon' WHEN 3 THEN 'rare' ELSE 'epic' END,
       "price_gold" = CASE r.pos WHEN 2 THEN 2500 WHEN 3 THEN 8000 ELSE 0 END,
       "price_gems" = CASE WHEN r.pos >= 4 THEN 400 ELSE 0 END,
       "is_default" = (r.pos = 1),
       "updated_at" = NOW()
  FROM ranked r
 WHERE s."id" = r."id"
   AND s."price_gold" = 0
   AND s."price_gems" = 0;
