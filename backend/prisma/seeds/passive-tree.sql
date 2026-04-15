-- =============================================================================
-- passive-tree.sql — MVP passive-tree catalog (50 nodes, ~78 edges)
-- Phase 1 of Talents feature.
-- Idempotent: wipes passive_connections + passive_nodes before re-inserting.
-- NOT safe on a live database with real player progression: it also deletes
-- `character_passives`, so treat this as bootstrap / controlled reset only.
-- =============================================================================
--
-- Structure:
--   Universal core (6 tier-1 nodes, hexagon around center 500,500)
--   + 4 class starts (tier 0) at radius 200 in cardinal directions
--   + 10 nodes per class branch (3×T2 + 3×T3 keystones + 3×T4 + 1×T5 ultimate)
--
-- Layout is laid out on a 1000×1000 canvas; iOS canvas auto-fits.
-- Balance numbers intentionally conservative for MVP; tune later.
-- =============================================================================

BEGIN;

-- Wipe (child first, then parent)
DELETE FROM character_passives;
DELETE FROM passive_connections;
DELETE FROM passive_nodes;

-- ---------------------------------------------------------------------------
-- NODES
-- ---------------------------------------------------------------------------
INSERT INTO passive_nodes
  (id, node_key, name, description, bonus_type, bonus_stat, bonus_value,
   tier, position_x, position_y, cost, class_restriction, is_start_node, is_active)
VALUES
  -- Universal core (tier 1) --------------------------------------------------
  (gen_random_uuid(), 'core_vitality',  'Vitality',  '+20 Maximum HP',           'flat_hp'::"PassiveBonusType",          NULL, 20, 1, 500, 400, 1, NULL, FALSE, TRUE),
  (gen_random_uuid(), 'core_might',     'Might',     '+3 Damage',                'flat_damage'::"PassiveBonusType",      NULL,  3, 1, 587, 450, 1, NULL, FALSE, TRUE),
  (gen_random_uuid(), 'core_precision', 'Precision', '+1% Critical Strike Chance','flat_crit_chance'::"PassiveBonusType",NULL,  1, 1, 587, 550, 1, NULL, FALSE, TRUE),
  (gen_random_uuid(), 'core_evasion',   'Evasion',   '+1% Dodge Chance',         'flat_dodge_chance'::"PassiveBonusType",NULL,  1, 1, 500, 600, 1, NULL, FALSE, TRUE),
  (gen_random_uuid(), 'core_fortitude', 'Fortitude', '+5 Armor',                 'flat_armor'::"PassiveBonusType",       NULL,  5, 1, 413, 550, 1, NULL, FALSE, TRUE),
  (gen_random_uuid(), 'core_wards',     'Wards',     '+5 Magic Resist',          'flat_magic_resist'::"PassiveBonusType",NULL,  5, 1, 413, 450, 1, NULL, FALSE, TRUE),

  -- Class starts (tier 0, isStartNode) --------------------------------------
  (gen_random_uuid(), 'warrior_start', 'Warrior''s Resolve', '+5 Strength',     'flat_stat'::"PassiveBonusType",'str', 5, 0, 300, 500, 1, 'warrior'::"CharacterClass", TRUE, TRUE),
  (gen_random_uuid(), 'mage_start',    'Mage''s Insight',    '+5 Intelligence', 'flat_stat'::"PassiveBonusType",'int', 5, 0, 500, 300, 1, 'mage'::"CharacterClass",    TRUE, TRUE),
  (gen_random_uuid(), 'rogue_start',   'Rogue''s Finesse',   '+5 Agility',      'flat_stat'::"PassiveBonusType",'agi', 5, 0, 700, 500, 1, 'rogue'::"CharacterClass",   TRUE, TRUE),
  (gen_random_uuid(), 'tank_start',    'Tank''s Bulwark',    '+5 Endurance',    'flat_stat'::"PassiveBonusType",'end', 5, 0, 500, 700, 1, 'tank'::"CharacterClass",    TRUE, TRUE),

  -- WARRIOR branch (grows WEST) ---------------------------------------------
  (gen_random_uuid(), 'warrior_2a',          'Iron Fists',     '+4 Strength',        'flat_stat'::"PassiveBonusType",       'str', 4, 2, 250, 460, 1, 'warrior'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'warrior_2b',          'War Hammer',     '+4 Damage',          'flat_damage'::"PassiveBonusType",     NULL,  4, 2, 250, 540, 1, 'warrior'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'warrior_2c',          'Berserker''s Eye','+1% Critical Strike','flat_crit_chance'::"PassiveBonusType",NULL, 1, 2, 200, 500, 1, 'warrior'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'warrior_3_fury',      'Bloodlust',      '+6% Damage',         'percent_damage'::"PassiveBonusType",  NULL,  6, 3, 160, 440, 2, 'warrior'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'warrior_3_lifesteal', 'Blood Drinker',  '+3% Lifesteal',      'lifesteal'::"PassiveBonusType",       NULL,  3, 3, 160, 560, 2, 'warrior'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'warrior_3_str_pct',   'Titanic Might',  '+8% Strength',       'percent_stat'::"PassiveBonusType",    'str', 8, 3, 115, 500, 2, 'warrior'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'warrior_4a',          'Reaper''s Edge', '+8 Damage',          'flat_damage'::"PassiveBonusType",     NULL,  8, 4,  80, 440, 2, 'warrior'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'warrior_4b',          'Executioner',    '+2% Critical Strike','flat_crit_chance'::"PassiveBonusType",NULL, 2, 4,  80, 560, 2, 'warrior'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'warrior_4c',          'Savage Assault', '+6% Damage',         'percent_damage'::"PassiveBonusType",  NULL,  6, 4,  50, 500, 2, 'warrior'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'warrior_5_ult',       'Warlord''s Wrath','+15% Damage',       'percent_damage'::"PassiveBonusType",  NULL, 15, 5,  15, 500, 3, 'warrior'::"CharacterClass", FALSE, TRUE),

  -- MAGE branch (grows NORTH) ------------------------------------------------
  (gen_random_uuid(), 'mage_2a',          'Arcane Wisdom',    '+4 Intelligence',    'flat_stat'::"PassiveBonusType",         'int', 4, 2, 460, 250, 1, 'mage'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'mage_2b',          'Mage''s Ward',     '+6 Magic Resist',    'flat_magic_resist'::"PassiveBonusType", NULL, 6, 2, 540, 250, 1, 'mage'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'mage_2c',          'Spell Power',      '+3 Damage',          'flat_damage'::"PassiveBonusType",       NULL, 3, 2, 500, 200, 1, 'mage'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'mage_3_arcane',    'Arcane Surge',     '+6% Damage',         'percent_damage'::"PassiveBonusType",    NULL, 6, 3, 440, 160, 2, 'mage'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'mage_3_ward',      'Runic Barrier',    '+10% Magic Resist',  'percent_magic_resist'::"PassiveBonusType",NULL,10,3, 560, 160, 2, 'mage'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'mage_3_int_pct',   'Enlightenment',    '+8% Intelligence',   'percent_stat'::"PassiveBonusType",      'int', 8, 3, 500, 115, 2, 'mage'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'mage_4a',          'Mystic Focus',     '+5 Intelligence',    'flat_stat'::"PassiveBonusType",         'int', 5, 4, 440,  80, 2, 'mage'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'mage_4b',          'Mana Shield',      '+8 Magic Resist',    'flat_magic_resist'::"PassiveBonusType", NULL, 8, 4, 560,  80, 2, 'mage'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'mage_4c',          'Swift Cast',       '-5% Ability Cooldown','cooldown_reduction'::"PassiveBonusType",NULL,5, 4, 500,  50, 2, 'mage'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'mage_5_ult',       'Archon''s Ascension','+15% Intelligence','percent_stat'::"PassiveBonusType",      'int',15,5, 500,  15, 3, 'mage'::"CharacterClass", FALSE, TRUE),

  -- ROGUE branch (grows EAST) ------------------------------------------------
  (gen_random_uuid(), 'rogue_2a',          'Nimble',          '+4 Agility',           'flat_stat'::"PassiveBonusType",       'agi', 4, 2, 740, 460, 1, 'rogue'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'rogue_2b',          'Keen Edge',       '+1% Critical Strike',  'flat_crit_chance'::"PassiveBonusType",NULL,  1, 2, 740, 540, 1, 'rogue'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'rogue_2c',          'Elusive',         '+1% Dodge',            'flat_dodge_chance'::"PassiveBonusType",NULL, 1, 2, 800, 500, 1, 'rogue'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'rogue_3_shadow',    'Shadow Strike',   '+6% Damage',           'percent_damage'::"PassiveBonusType",  NULL,  6, 3, 840, 460, 2, 'rogue'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'rogue_3_precision', 'Assassin''s Mark','+3% Critical Strike',  'flat_crit_chance'::"PassiveBonusType",NULL,  3, 3, 840, 540, 2, 'rogue'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'rogue_3_agi_pct',   'Perfect Form',    '+8% Agility',          'percent_stat'::"PassiveBonusType",    'agi', 8, 3, 885, 500, 2, 'rogue'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'rogue_4a',          'Ghost Step',      '+2% Dodge',            'flat_dodge_chance'::"PassiveBonusType",NULL, 2, 4, 920, 460, 2, 'rogue'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'rogue_4b',          'Backstab',        '+6 Damage',            'flat_damage'::"PassiveBonusType",     NULL,  6, 4, 920, 540, 2, 'rogue'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'rogue_4c',          'Killing Edge',    '+6% Damage',           'percent_damage'::"PassiveBonusType",  NULL,  6, 4, 950, 500, 2, 'rogue'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'rogue_5_ult',       'Death''s Whisper','+10% Critical Strike','flat_crit_chance'::"PassiveBonusType",NULL, 10, 5, 985, 500, 3, 'rogue'::"CharacterClass", FALSE, TRUE),

  -- TANK branch (grows SOUTH) ------------------------------------------------
  (gen_random_uuid(), 'tank_2a',          'Steadfast',         '+4 Endurance',       'flat_stat'::"PassiveBonusType",       'end', 4, 2, 460, 740, 1, 'tank'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'tank_2b',          'Plated',            '+6 Armor',           'flat_armor'::"PassiveBonusType",      NULL,  6, 2, 540, 740, 1, 'tank'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'tank_2c',          'Heart of Stone',    '+20 Maximum HP',     'flat_hp'::"PassiveBonusType",         NULL, 20, 2, 500, 800, 1, 'tank'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'tank_3_iron',      'Iron Skin',         '+10% Armor',         'percent_armor'::"PassiveBonusType",   NULL, 10, 3, 460, 840, 2, 'tank'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'tank_3_fortress',  'Living Fortress',   '+8% Maximum HP',     'percent_hp'::"PassiveBonusType",      NULL,  8, 3, 540, 840, 2, 'tank'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'tank_3_end_pct',   'Unyielding',        '+8% Endurance',      'percent_stat'::"PassiveBonusType",    'end', 8, 3, 500, 885, 2, 'tank'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'tank_4a',          'Stalwart',          '-3% Damage Taken',   'damage_reduction'::"PassiveBonusType",NULL,  3, 4, 460, 920, 2, 'tank'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'tank_4b',          'Bulwark',           '+8 Armor',           'flat_armor'::"PassiveBonusType",      NULL,  8, 4, 540, 920, 2, 'tank'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'tank_4c',          'Unbroken',          '+30 Maximum HP',     'flat_hp'::"PassiveBonusType",         NULL, 30, 4, 500, 950, 2, 'tank'::"CharacterClass", FALSE, TRUE),
  (gen_random_uuid(), 'tank_5_ult',       'Immovable Object',  '+15% Maximum HP',    'percent_hp'::"PassiveBonusType",      NULL, 15, 5, 500, 985, 3, 'tank'::"CharacterClass", FALSE, TRUE);

-- ---------------------------------------------------------------------------
-- CONNECTIONS (resolved via node_key → id)
-- ---------------------------------------------------------------------------
INSERT INTO passive_connections (id, from_id, to_id)
SELECT gen_random_uuid(),
       (SELECT id FROM passive_nodes WHERE node_key = edge.from_key),
       (SELECT id FROM passive_nodes WHERE node_key = edge.to_key)
FROM (VALUES
  -- Core hexagon ring
  ('core_vitality',  'core_might'),
  ('core_might',     'core_precision'),
  ('core_precision', 'core_evasion'),
  ('core_evasion',   'core_fortitude'),
  ('core_fortitude', 'core_wards'),
  ('core_wards',     'core_vitality'),

  -- Starts → core (each start to 1-2 nearest core nodes)
  ('warrior_start', 'core_wards'),
  ('warrior_start', 'core_fortitude'),
  ('mage_start',    'core_vitality'),
  ('mage_start',    'core_wards'),
  ('rogue_start',   'core_might'),
  ('rogue_start',   'core_precision'),
  ('tank_start',    'core_evasion'),
  ('tank_start',    'core_fortitude'),

  -- Warrior branch
  ('warrior_start',       'warrior_2a'),
  ('warrior_start',       'warrior_2b'),
  ('warrior_start',       'warrior_2c'),
  ('warrior_2a',          'warrior_2c'),
  ('warrior_2b',          'warrior_2c'),
  ('warrior_2a',          'warrior_3_fury'),
  ('warrior_2b',          'warrior_3_lifesteal'),
  ('warrior_2c',          'warrior_3_str_pct'),
  ('warrior_3_fury',      'warrior_3_str_pct'),
  ('warrior_3_lifesteal', 'warrior_3_str_pct'),
  ('warrior_3_fury',      'warrior_4a'),
  ('warrior_3_lifesteal', 'warrior_4b'),
  ('warrior_3_str_pct',   'warrior_4c'),
  ('warrior_4a',          'warrior_5_ult'),
  ('warrior_4b',          'warrior_5_ult'),
  ('warrior_4c',          'warrior_5_ult'),

  -- Mage branch
  ('mage_start',       'mage_2a'),
  ('mage_start',       'mage_2b'),
  ('mage_start',       'mage_2c'),
  ('mage_2a',          'mage_2c'),
  ('mage_2b',          'mage_2c'),
  ('mage_2a',          'mage_3_arcane'),
  ('mage_2b',          'mage_3_ward'),
  ('mage_2c',          'mage_3_int_pct'),
  ('mage_3_arcane',    'mage_3_int_pct'),
  ('mage_3_ward',      'mage_3_int_pct'),
  ('mage_3_arcane',    'mage_4a'),
  ('mage_3_ward',      'mage_4b'),
  ('mage_3_int_pct',   'mage_4c'),
  ('mage_4a',          'mage_5_ult'),
  ('mage_4b',          'mage_5_ult'),
  ('mage_4c',          'mage_5_ult'),

  -- Rogue branch
  ('rogue_start',       'rogue_2a'),
  ('rogue_start',       'rogue_2b'),
  ('rogue_start',       'rogue_2c'),
  ('rogue_2a',          'rogue_2c'),
  ('rogue_2b',          'rogue_2c'),
  ('rogue_2a',          'rogue_3_shadow'),
  ('rogue_2b',          'rogue_3_precision'),
  ('rogue_2c',          'rogue_3_agi_pct'),
  ('rogue_3_shadow',    'rogue_3_agi_pct'),
  ('rogue_3_precision', 'rogue_3_agi_pct'),
  ('rogue_3_shadow',    'rogue_4a'),
  ('rogue_3_precision', 'rogue_4b'),
  ('rogue_3_agi_pct',   'rogue_4c'),
  ('rogue_4a',          'rogue_5_ult'),
  ('rogue_4b',          'rogue_5_ult'),
  ('rogue_4c',          'rogue_5_ult'),

  -- Tank branch
  ('tank_start',       'tank_2a'),
  ('tank_start',       'tank_2b'),
  ('tank_start',       'tank_2c'),
  ('tank_2a',          'tank_2c'),
  ('tank_2b',          'tank_2c'),
  ('tank_2a',          'tank_3_iron'),
  ('tank_2b',          'tank_3_fortress'),
  ('tank_2c',          'tank_3_end_pct'),
  ('tank_3_iron',      'tank_3_end_pct'),
  ('tank_3_fortress',  'tank_3_end_pct'),
  ('tank_3_iron',      'tank_4a'),
  ('tank_3_fortress',  'tank_4b'),
  ('tank_3_end_pct',   'tank_4c'),
  ('tank_4a',          'tank_5_ult'),
  ('tank_4b',          'tank_5_ult'),
  ('tank_4c',          'tank_5_ult')
) AS edge(from_key, to_key);

COMMIT;

-- Verification --
-- Expected: 50 nodes, 78 connections
SELECT
  (SELECT COUNT(*) FROM passive_nodes)             AS nodes,
  (SELECT COUNT(*) FROM passive_nodes WHERE is_start_node = TRUE) AS starts,
  (SELECT COUNT(*) FROM passive_connections)       AS edges;
