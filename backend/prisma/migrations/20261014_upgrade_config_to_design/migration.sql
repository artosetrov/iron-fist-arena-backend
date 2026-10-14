-- =============================================================================
-- 20261014_upgrade_config_to_design
--
-- Bring the live upgrade config in line with what balance.ts and
-- ECONOMY_RULES.md R7.3 specify. The routes read game_config, and these rows
-- were seeded with pre-v3 values the seeders never revisit (both skip keys
-- that already exist), so the design never reached production:
--
--   cost formula   linear, base 100     -> 'exponential' mode, 150 × N^1.4
--                  (+1..+10 = 5,500 gold; designed ~17,600 — the endgame sink
--                   was three times too cheap)
--   downgrade from attempt +6 (5)        -> attempts +9/+10 (8)
--   protection     30 gems               -> 40 gems (balance.ts GEM_COSTS)
--   upgrade_chances (absent -> v2 25/15) -> v3 30/20, which is what the client
--                  already displays. Until now the UI showed 30/20 and the
--                  server rolled 25/15.
--
-- Values are JSON. Idempotent: every statement is a plain upsert to the
-- designed value. Run against prod via Supabase MCP BEFORE deploying.
-- =============================================================================

INSERT INTO "game_config" ("key", "value", "category", "description", "updated_at")
VALUES
  ('item_balance.upgrade_cost_formula',               '"exponential"'::jsonb, 'item_balance', 'Upgrade cost formula: linear, exponential, or custom', NOW()),
  ('item_balance.upgrade_cost_base',                  '150'::jsonb,           'item_balance', 'Base gold cost multiplier for upgrades', NOW()),
  ('item_balance.upgrade_cost_exponent',              '1.4'::jsonb,           'item_balance', 'Exponent for exponential cost scaling', NOW()),
  ('item_balance.upgrade_failure_downgrade_threshold','8'::jsonb,             'item_balance', 'Upgrade level at which failure causes downgrade (8 = attempts at +9/+10)', NOW()),
  ('item_balance.upgrade_protection_gem_cost',        '40'::jsonb,            'item_balance', 'Gem cost for upgrade protection scroll', NOW()),
  ('upgrade_chances',                                 '[100,100,100,100,100,80,60,40,30,20]'::jsonb, 'upgrade', 'Success rate (%) for each upgrade level (+1 through +10)', NOW())
ON CONFLICT ("key") DO UPDATE
  SET "value" = EXCLUDED."value",
      "description" = EXCLUDED."description",
      "updated_at" = NOW();
