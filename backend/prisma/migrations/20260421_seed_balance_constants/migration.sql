-- Seed 2026-04-21: idempotently repopulate item balance configuration.
--
-- Source of truth: `backend/prisma/seed-balance.ts` (BALANCE_CONFIGS +
-- ITEM_BALANCE_PROFILES). This .sql mirrors that TS seed 1:1 so a prod /
-- staging snapshot-restore can reseed without needing Node tooling.
--
-- When editing: update BOTH `seed-balance.ts` AND this file in the same
-- commit. Use the seed script to bootstrap a new local DB; use this
-- migration to recover production.
--
-- Idempotency: ON CONFLICT DO NOTHING on the natural key of each table
-- (game_config.key, item_balance_profiles.item_type). Existing rows are
-- NOT overwritten — operator tuning through the admin UI takes precedence
-- over hardcoded seed values.
--
-- Related incidents: Gold Mine (2026-04-11), Stash (2026-04-13), Degon
-- admin role (2026-04-19), Appearance Skins (2026-04-20). See
-- gatekeeper/SKILL.md §6c for the post-restore catalog checklist.

-- ---------------------------------------------------------------------------
-- game_config — key/value balance constants
-- ---------------------------------------------------------------------------

INSERT INTO "game_config" ("key", "value", "category", "description", "updated_at") VALUES
  -- Power Score Weights
  ('item_balance.power_stat_weights',
   '{"str":1.0,"agi":1.0,"vit":0.8,"end":0.7,"int":1.0,"wis":0.7,"luk":0.5,"cha":0.3}'::jsonb,
   'item_balance', 'Weight of each stat in power score calculation', NOW()),
  ('item_balance.power_upgrade_multiplier',
   '0.05'::jsonb,
   'item_balance', 'Power bonus per upgrade level (5% each)', NOW()),
  ('item_balance.power_rarity_multipliers',
   '{"common":1.0,"uncommon":1.3,"rare":1.6,"epic":2.0,"legendary":2.5}'::jsonb,
   'item_balance', 'Rarity multiplier for power score', NOW()),

  -- Stat Ranges by Level
  ('item_balance.stat_ranges',
   '[{"minLevel":1,"maxLevel":5,"minStat":1,"maxStat":8},{"minLevel":6,"maxLevel":10,"minStat":5,"maxStat":16},{"minLevel":11,"maxLevel":20,"minStat":10,"maxStat":30},{"minLevel":21,"maxLevel":35,"minStat":18,"maxStat":50},{"minLevel":36,"maxLevel":50,"minStat":28,"maxStat":75}]'::jsonb,
   'item_balance', 'Allowed stat ranges per level bracket', NOW()),

  -- Rarity Multipliers
  ('item_balance.rarity_multipliers',
   '{"common":1.0,"uncommon":1.3,"rare":1.6,"epic":2.0,"legendary":2.5}'::jsonb,
   'item_balance', 'Stat generation rarity scaling factors', NOW()),

  -- Level Scaling
  ('item_balance.level_scaling_formula',       '"linear"'::jsonb, 'item_balance', 'Formula type: linear, exponential, or logarithmic', NOW()),
  ('item_balance.level_scaling_base',          '2'::jsonb,        'item_balance', 'Base stat multiplier per item level (itemLevel * base)', NOW()),
  ('item_balance.level_scaling_exponent',      '1.0'::jsonb,      'item_balance', 'Exponent for exponential scaling mode', NOW()),
  ('item_balance.level_variance',              '2'::jsonb,        'item_balance', 'Level variance range for dropped items (+/-)', NOW()),

  -- Drop Tuning
  ('item_balance.luk_drop_bonus_per_point',    '0.003'::jsonb,    'item_balance', 'Drop chance bonus per LUK point (+0.3%)', NOW()),
  ('item_balance.drop_chance_cap',             '0.95'::jsonb,     'item_balance', 'Maximum drop chance cap (95%)', NOW()),
  ('item_balance.level_rarity_bonus_per_level','0.2'::jsonb,      'item_balance', 'Rarity bonus shift per player level above 1', NOW()),
  ('item_balance.level_rarity_bonus_distribution',
   '{"rare":0.4,"epic":0.35,"legendary":0.25}'::jsonb,
   'item_balance', 'How level rarity bonus distributes across tiers', NOW()),

  -- Economy
  ('item_balance.sell_price_by_rarity',
   '{"common":10,"uncommon":25,"rare":60,"epic":150,"legendary":400}'::jsonb,
   'item_balance', 'Base sell price per rarity tier (multiplied by level)', NOW()),
  ('item_balance.buy_price_multiplier',        '4'::jsonb,        'item_balance', 'Buy price = sell price * this multiplier', NOW()),
  ('item_balance.power_to_price_ratio',        '5'::jsonb,        'item_balance', 'Gold per power score point for auto-pricing', NOW()),

  -- Upgrade Balance
  ('item_balance.upgrade_stat_bonus_per_level','1'::jsonb,        'item_balance', 'Stat bonus added per upgrade level per stat', NOW()),
  ('item_balance.upgrade_cost_formula',        '"linear"'::jsonb, 'item_balance', 'Upgrade cost formula: linear, exponential, or custom', NOW()),
  ('item_balance.upgrade_cost_base',           '100'::jsonb,      'item_balance', 'Base gold cost multiplier for upgrades', NOW()),
  ('item_balance.upgrade_cost_exponent',       '1.5'::jsonb,      'item_balance', 'Exponent for exponential cost scaling', NOW()),
  ('item_balance.upgrade_failure_downgrade_threshold','5'::jsonb, 'item_balance', 'Upgrade level at which failure causes downgrade', NOW()),
  ('item_balance.upgrade_protection_gem_cost', '30'::jsonb,       'item_balance', 'Gem cost for upgrade protection scroll', NOW()),

  -- Validation Thresholds
  ('item_balance.validation_power_deviation_threshold','0.3'::jsonb,'item_balance','Flag items with power deviation exceeding 30%', NOW()),
  ('item_balance.validation_stat_cap_multiplier',      '3.0'::jsonb,'item_balance','Flag stats exceeding bracket max * this multiplier', NOW()),

  -- Derived Stat Formulas
  ('item_balance.hp_base',        '80'::jsonb, 'item_balance', 'Base HP before stat bonuses', NOW()),
  ('item_balance.hp_per_vit',     '5'::jsonb,  'item_balance', 'HP gained per VIT point', NOW()),
  ('item_balance.hp_per_end',     '3'::jsonb,  'item_balance', 'HP gained per END point', NOW()),
  ('item_balance.armor_per_end',  '2'::jsonb,  'item_balance', 'Armor gained per END point', NOW()),
  ('item_balance.armor_per_str',  '0.5'::jsonb,'item_balance', 'Armor gained per STR point', NOW()),
  ('item_balance.mr_per_wis',     '2'::jsonb,  'item_balance', 'Magic Resist gained per WIS point', NOW()),
  ('item_balance.mr_per_int',     '0.5'::jsonb,'item_balance', 'Magic Resist gained per INT point', NOW()),

  -- Combat Damage Scaling
  ('item_balance.class_damage_scaling',
   '{"warrior":{"stat":"str","multiplier":1.5,"levelBonus":2},"tank":{"stat":"str","multiplier":1.2,"levelBonus":2},"rogue":{"stat":"agi","multiplier":1.5,"levelBonus":2},"mage":{"stat":"int","multiplier":1.5,"levelBonus":2}}'::jsonb,
   'item_balance', 'Per-class damage formula: damage = stat * multiplier + level * levelBonus', NOW())
ON CONFLICT ("key") DO NOTHING;

-- ---------------------------------------------------------------------------
-- item_balance_profiles — per-item-type stat weight profiles
-- ---------------------------------------------------------------------------

INSERT INTO "item_balance_profiles" ("id", "item_type", "stat_weights", "power_weight", "description", "updated_at") VALUES
  (gen_random_uuid(), 'weapon',    '{"str":1.0,"agi":0.3}'::jsonb, 1.2,  'Weapons emphasize STR with secondary AGI',       NOW()),
  (gen_random_uuid(), 'helmet',    '{"vit":0.8,"wis":0.4}'::jsonb, 0.9,  'Helmets emphasize VIT with secondary WIS',       NOW()),
  (gen_random_uuid(), 'chest',     '{"vit":1.0,"end":0.5}'::jsonb, 1.0,  'Chest armor emphasizes VIT with secondary END',  NOW()),
  (gen_random_uuid(), 'gloves',    '{"str":0.6,"agi":0.6}'::jsonb, 0.85, 'Gloves balance STR and AGI equally',             NOW()),
  (gen_random_uuid(), 'legs',      '{"vit":0.7,"end":0.5}'::jsonb, 0.9,  'Leg armor emphasizes VIT with secondary END',    NOW()),
  (gen_random_uuid(), 'boots',     '{"agi":1.0,"end":0.3}'::jsonb, 0.85, 'Boots emphasize AGI with secondary END',         NOW()),
  (gen_random_uuid(), 'accessory', '{"luk":1.0,"cha":0.5}'::jsonb, 0.7,  'Accessories emphasize LUK with secondary CHA',   NOW()),
  (gen_random_uuid(), 'amulet',    '{"int":1.0,"wis":0.5}'::jsonb, 0.8,  'Amulets emphasize INT with secondary WIS',       NOW()),
  (gen_random_uuid(), 'belt',      '{"end":1.0,"vit":0.3}'::jsonb, 0.75, 'Belts emphasize END with secondary VIT',         NOW()),
  (gen_random_uuid(), 'relic',     '{"int":0.7,"wis":0.7}'::jsonb, 0.9,  'Relics balance INT and WIS',                     NOW()),
  (gen_random_uuid(), 'necklace',  '{"cha":1.0,"luk":0.4}'::jsonb, 0.7,  'Necklaces emphasize CHA with secondary LUK',     NOW()),
  (gen_random_uuid(), 'ring',      '{"luk":0.5,"str":0.5}'::jsonb, 0.75, 'Rings balance LUK and STR',                      NOW())
ON CONFLICT ("item_type") DO NOTHING;
