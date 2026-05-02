-- =============================================================================
-- passives-mage-v2.sql — Mage talent tree, Talents v2 (2026-04-29)
-- Canonical spec: docs/06_game_systems/SKILL_TREE_DESIGN_V2.md §6
-- =============================================================================
--
-- Scope: 20 Mage-class PassiveNode rows + connections, prefixed
--   `mage.(found|pyro|arc|cryo|key|ult).<name>`. Non-mage classes untouched.
--
-- Active ultimates (require migration 20260429_talent_action_v2_ults applied):
--   * mage.ult.meteor   → aoe_damage     magnitude 0.70 CD 90
--   * mage.ult.timewarp → cooldown_reset magnitude 0    CD 180
--
-- PassiveBonusType proxies (spec effect → enum value):
--   "spell power"          → percent_damage
--   "max mana"             → percent_hp        (no mana stat in v1)
--   "cast speed"           → percent_damage    (no cast-speed stat)
--   "shield strength"      → damage_reduction
--   "burn DoT"             → percent_damage    (no DoT type)
--   "AoE spell damage"     → percent_damage
--   "burn crit chance"     → flat_crit_chance
--   "mana regen"           → percent_damage    (substitute, mana not modeled)
--   "slow magnitude"       → percent_damage    (substitute, slow not modeled)
--   "freeze chance on crit"→ flat_crit_chance
--   "shield on freeze"     → damage_reduction
-- =============================================================================

BEGIN;

DELETE FROM character_passives
 WHERE node_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'mage.%');

DELETE FROM passive_connections
 WHERE from_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'mage.%')
    OR to_id   IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'mage.%');

DELETE FROM character_active_slots
 WHERE node_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'mage.%');

DELETE FROM passive_nodes WHERE node_key LIKE 'mage.%';

INSERT INTO passive_nodes
  (id, node_key, name, description, bonus_type, bonus_stat, bonus_value,
   tier, position_x, position_y, cost, class_restriction, is_start_node, is_active,
   is_activatable, active_action_type, active_cooldown, active_magnitude)
VALUES
  -- Foundation (tier 1, y=520) ---------------------------------------------
  (gen_random_uuid(), 'mage.found.intellect',     'Intellect',    '+3%/+6%/+9% Damage',                'percent_damage'::"PassiveBonusType",     NULL,  3, 1,  0, 0, 6, 'mage'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: spell power
  (gen_random_uuid(), 'mage.found.mana_pool',     'Mana Pool',    '+3%/+6%/+9% Max HP',                'percent_hp'::"PassiveBonusType",         NULL,  3, 1,  80, 0, 6, 'mage'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: max mana → max HP substitute
  (gen_random_uuid(), 'mage.found.focus',         'Focus',        '+3%/+6%/+9% Damage',                'percent_damage'::"PassiveBonusType",     NULL,  3, 1,  160, 0, 6, 'mage'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: cast speed
  (gen_random_uuid(), 'mage.found.resonance',     'Resonance',    '+2%/+4%/+6% Cooldown Reduction',    'cooldown_reduction'::"PassiveBonusType", NULL,  2, 1,  240, 0, 6, 'mage'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'mage.found.arcane_armor',  'Arcane Armor', '+2/+4/+6 Magic Resist',             'flat_magic_resist'::"PassiveBonusType",  NULL,  2, 1,  320, 0, 6, 'mage'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'mage.found.ward',          'Ward',         '+5%/+10%/+15% Damage Reduction',    'damage_reduction'::"PassiveBonusType",   NULL,  5, 1, 400, 0, 6, 'mage'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: shield strength

  -- Pyromancer lane (offense, tier 2) ---------------------------------------
  (gen_random_uuid(), 'mage.pyro.kindle',         'Kindle',         '+5%/+10%/+15% Damage',            'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  120, 80, 6, 'mage'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: burn DoT
  (gen_random_uuid(), 'mage.pyro.conflagration',  'Conflagration',  '+5%/+10%/+15% Damage',            'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  120, 160, 6, 'mage'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: AoE damage
  (gen_random_uuid(), 'mage.pyro.inferno',        'Inferno',        '+4%/+8%/+12% Critical Strike Chance', 'flat_crit_chance'::"PassiveBonusType", NULL, 4, 2,  120, 240, 6, 'mage'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: burn crit chance

  -- Arcanist lane (balance, tier 2) -----------------------------------------
  (gen_random_uuid(), 'mage.arc.focus_flow',      'Focus Flow',     '+5%/+10%/+15% Damage',            'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  200, 80, 6, 'mage'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: mana regen
  (gen_random_uuid(), 'mage.arc.arcane_might',    'Arcane Might',   '+5%/+10%/+15% Damage',            'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  200, 160, 6, 'mage'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'mage.arc.chronomancy',     'Chronomancy',    '+3%/+6%/+9% Cooldown Reduction',  'cooldown_reduction'::"PassiveBonusType", NULL,  3, 2,  200, 240, 6, 'mage'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),

  -- Cryomancer lane (defense, tier 2) ---------------------------------------
  (gen_random_uuid(), 'mage.cryo.frost',          'Frost',          '+5%/+10%/+15% Damage',            'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  280, 80, 6, 'mage'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: slow magnitude
  (gen_random_uuid(), 'mage.cryo.freeze',         'Freeze',         '+3%/+6%/+9% Critical Strike Chance', 'flat_crit_chance'::"PassiveBonusType", NULL, 3, 2,  280, 160, 6, 'mage'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: freeze chance on crit
  (gen_random_uuid(), 'mage.cryo.glacial',        'Glacial',        '+10%/+20%/+30% Damage Reduction', 'damage_reduction'::"PassiveBonusType",   NULL, 10, 2,  280, 240, 6, 'mage'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: shield on freeze

  -- Keystones (tier 3, single-rank, cost 3) ---------------------------------
  (gen_random_uuid(), 'mage.key.ignite',          'Ignite',         '+15% Damage (burn spread on kill)','percent_damage'::"PassiveBonusType",    NULL, 15, 3,  120, 320, 3, 'mage'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'mage.key.manaflow',        'Manaflow',       '+10% Cooldown Reduction (free spell every 3rd)', 'cooldown_reduction'::"PassiveBonusType", NULL, 10, 3, 200, 320, 3, 'mage'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'mage.key.frostbite',       'Frostbite',      '+25% Damage (vs frozen targets)', 'percent_damage'::"PassiveBonusType",     NULL, 25, 3,  280, 320, 3, 'mage'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),

  -- Ultimates (tier 4, single-rank, cost 5, isActivatable) ------------------
  (gen_random_uuid(), 'mage.ult.meteor',          'Meteor',         '+15% Damage. Active: Cataclysm.', 'percent_damage'::"PassiveBonusType",     NULL, 15, 4, 160, 400, 5, 'mage'::"CharacterClass", FALSE, TRUE, TRUE, 'aoe_damage'::"TalentSlotAction",      90,  0.7),
  (gen_random_uuid(), 'mage.ult.timewarp',        'Timewarp',       '+10% Cooldown Reduction. Active: Rewind.', 'cooldown_reduction'::"PassiveBonusType", NULL, 10, 4, 240, 400, 5, 'mage'::"CharacterClass", FALSE, TRUE, TRUE, 'cooldown_reset'::"TalentSlotAction", 180,  0);

WITH n AS (SELECT id, node_key FROM passive_nodes WHERE node_key LIKE 'mage.%')
INSERT INTO passive_connections (id, from_id, to_id)
SELECT gen_random_uuid(), a.id, b.id
FROM n a
JOIN n b ON TRUE
WHERE (a.node_key, b.node_key) IN (
  -- Foundation chain
  ('mage.found.intellect',    'mage.found.mana_pool'),
  ('mage.found.mana_pool',    'mage.found.focus'),
  ('mage.found.focus',        'mage.found.resonance'),
  ('mage.found.resonance',    'mage.found.arcane_armor'),
  ('mage.found.arcane_armor', 'mage.found.ward'),

  -- Row-1 anchors
  ('mage.found.focus',        'mage.pyro.kindle'),
  ('mage.found.intellect',    'mage.pyro.kindle'),
  ('mage.found.mana_pool',    'mage.arc.focus_flow'),
  ('mage.found.resonance',    'mage.arc.focus_flow'),
  ('mage.found.ward',         'mage.cryo.frost'),
  ('mage.found.arcane_armor', 'mage.cryo.frost'),

  -- Weak cross-lane links
  ('mage.pyro.kindle',        'mage.arc.focus_flow'),
  ('mage.arc.focus_flow',     'mage.cryo.frost'),

  -- Row-1 → row-2 within lane
  ('mage.pyro.kindle',        'mage.pyro.conflagration'),
  ('mage.arc.focus_flow',     'mage.arc.arcane_might'),
  ('mage.cryo.frost',         'mage.cryo.freeze'),

  -- Row-2 → row-3 within lane
  ('mage.pyro.conflagration', 'mage.pyro.inferno'),
  ('mage.arc.arcane_might',   'mage.arc.chronomancy'),
  ('mage.cryo.freeze',        'mage.cryo.glacial'),

  -- Row-3 → Keystone
  ('mage.pyro.inferno',       'mage.key.ignite'),
  ('mage.arc.chronomancy',    'mage.key.manaflow'),
  ('mage.cryo.glacial',       'mage.key.frostbite'),

  -- Keystone → Ultimate (only Pyro and Arc lanes get ult per spec §6.6)
  ('mage.key.ignite',         'mage.ult.meteor'),
  ('mage.key.manaflow',       'mage.ult.timewarp')
);

COMMIT;
