-- =============================================================================
-- passives-tank-v2.sql — Tank talent tree, Talents v2 (2026-04-29)
-- Canonical spec: docs/06_game_systems/SKILL_TREE_DESIGN_V2.md §7
-- =============================================================================
--
-- Scope: 20 Tank-class PassiveNode rows + connections, prefixed
--   `tank.(found|prot|ward|jug|key|ult).<name>`. Non-tank classes untouched.
--
-- Active ultimates (require migration 20260429_talent_action_v2_ults applied):
--   * tank.ult.fortress     → shield_self magnitude 0.70 CD 90
--   * tank.ult.earthshatter → aoe_stun    magnitude 2    CD 120
--
-- PassiveBonusType proxies (spec effect → enum value):
--   "threat generation"     → percent_damage     (no threat stat)
--   "CC resistance"         → damage_reduction   (substitute, CC not modeled)
--   "HP regen per turn"     → lifesteal          (regen ≈ on-attack lifesteal)
--   "shield-bash damage"    → percent_damage
--   "damage reflected"      → damage_reduction   (reflect = self-mitigation proxy)
--   "heal when blocking"    → lifesteal
--   "CC duration on self"   → damage_reduction   (CC reduction ≈ mitigation)
--   "HP regen below 30%"    → lifesteal
--   "AoE taunt"             → percent_damage     (engagement proxy)
--   "active shield absorbs" → damage_reduction
--   "immune to CC"          → damage_reduction
-- =============================================================================

BEGIN;

DELETE FROM character_passives
 WHERE node_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'tank.%');

DELETE FROM passive_connections
 WHERE from_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'tank.%')
    OR to_id   IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'tank.%');

DELETE FROM character_active_slots
 WHERE node_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'tank.%');

DELETE FROM passive_nodes WHERE node_key LIKE 'tank.%';

INSERT INTO passive_nodes
  (id, node_key, name, description, bonus_type, bonus_stat, bonus_value,
   tier, position_x, position_y, cost, class_restriction, is_start_node, is_active,
   is_activatable, active_action_type, active_cooldown, active_magnitude)
VALUES
  -- Foundation (tier 1, y=520) ---------------------------------------------
  (gen_random_uuid(), 'tank.found.stoneform',   'Stoneform',   '+5%/+10%/+15% Max HP',           'percent_hp'::"PassiveBonusType",         NULL,  5, 1,  120, 520, 6, 'tank'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.found.plate',       'Plate',       '+3/+6/+9 Armor',                 'flat_armor'::"PassiveBonusType",         NULL,  3, 1,  300, 520, 6, 'tank'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.found.resilience',  'Resilience',  '+2%/+4%/+6% Damage Reduction',   'damage_reduction'::"PassiveBonusType",   NULL,  2, 1,  480, 520, 6, 'tank'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.found.rebuke',      'Rebuke',      '+5%/+10%/+15% Damage',           'percent_damage'::"PassiveBonusType",     NULL,  5, 1,  680, 520, 6, 'tank'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: threat generation
  (gen_random_uuid(), 'tank.found.stability',   'Stability',   '+5%/+10%/+15% Damage Reduction', 'damage_reduction'::"PassiveBonusType",   NULL,  5, 1,  880, 520, 6, 'tank'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: CC resistance
  (gen_random_uuid(), 'tank.found.vigor',       'Vigor',       '+3%/+6%/+9% Life Steal',         'lifesteal'::"PassiveBonusType",          NULL,  3, 1, 1080, 520, 6, 'tank'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: HP regen per turn

  -- Protector lane (offense, tier 2) ----------------------------------------
  (gen_random_uuid(), 'tank.prot.cleave',       'Cleave',         '+5%/+10%/+15% Damage',        'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  220, 400, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.prot.challenge',    'Challenge',      '+3%/+6%/+9% Critical Strike Chance', 'flat_crit_chance'::"PassiveBonusType", NULL, 3, 2,  220, 290, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: vs highest-HP enemy
  (gen_random_uuid(), 'tank.prot.retaliation',  'Retaliation',    '+5%/+10%/+15% Damage',        'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  300, 180, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: damage after being hit

  -- Warden lane (balance, tier 2) -------------------------------------------
  (gen_random_uuid(), 'tank.ward.shield',       'Shield',         '+5%/+10%/+15% Damage',        'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  430, 400, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: shield-bash damage
  (gen_random_uuid(), 'tank.ward.reflect',      'Reflect',        '+3%/+6%/+9% Damage Reduction','damage_reduction'::"PassiveBonusType",   NULL,  3, 2,  430, 290, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: reflect to attacker
  (gen_random_uuid(), 'tank.ward.absolution',   'Absolution',     '+10%/+20%/+30% Life Steal',   'lifesteal'::"PassiveBonusType",          NULL, 10, 2,  600, 180, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: heal when blocking

  -- Juggernaut lane (defense, tier 2) ---------------------------------------
  (gen_random_uuid(), 'tank.jug.fortify',       'Fortify',        '+3%/+6%/+9% Damage Reduction','damage_reduction'::"PassiveBonusType",   NULL,  3, 2,  830, 400, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.jug.immovable',     'Immovable',      '+10%/+20%/+30% Damage Reduction', 'damage_reduction'::"PassiveBonusType", NULL, 10, 2,  830, 290, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: CC duration on self
  (gen_random_uuid(), 'tank.jug.unbreakable',   'Unbreakable',    '+10%/+20%/+30% Life Steal',   'lifesteal'::"PassiveBonusType",          NULL, 10, 2,  800, 180, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: HP regen below 30%

  -- Keystones (tier 3, single-rank, cost 3) ---------------------------------
  (gen_random_uuid(), 'tank.key.taunt',         'Taunt',          '+15% Damage (AoE taunt every 10s)','percent_damage'::"PassiveBonusType",NULL, 15, 3,  300,  80, 3, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.key.aegis_wall',    'Aegis Wall',     '+15% Damage Reduction (active shield)', 'damage_reduction'::"PassiveBonusType", NULL, 15, 3, 600, 80, 3, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.key.unstoppable',   'Unstoppable',    '+15% Damage Reduction (CC immune <50% HP)', 'damage_reduction'::"PassiveBonusType", NULL, 15, 3, 800, 80, 3, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),

  -- Ultimates (tier 4, single-rank, cost 5, isActivatable) ------------------
  (gen_random_uuid(), 'tank.ult.fortress',      'Fortress',       '+25% Max HP. Active: Bastion.','percent_hp'::"PassiveBonusType",        NULL, 25, 4, 450, 20, 5, 'tank'::"CharacterClass", FALSE, TRUE, TRUE, 'shield_self'::"TalentSlotAction", 90,  0.7),
  -- Balance pass 2026-04-29: aoe_stun 2→1 rounds (2 rounds = ~25%-of-match silence + OP combo with +30% passive)
  (gen_random_uuid(), 'tank.ult.earthshatter',  'Earthshatter',   '+30% Damage. Active: Quake.', 'percent_damage'::"PassiveBonusType",     NULL, 30, 4, 750, 20, 5, 'tank'::"CharacterClass", FALSE, TRUE, TRUE, 'aoe_stun'::"TalentSlotAction",   120,  1);

WITH n AS (SELECT id, node_key FROM passive_nodes WHERE node_key LIKE 'tank.%')
INSERT INTO passive_connections (id, from_id, to_id)
SELECT gen_random_uuid(), a.id, b.id
FROM n a
JOIN n b ON TRUE
WHERE (a.node_key, b.node_key) IN (
  -- Foundation chain
  ('tank.found.stoneform',  'tank.found.plate'),
  ('tank.found.plate',      'tank.found.resilience'),
  ('tank.found.resilience', 'tank.found.rebuke'),
  ('tank.found.rebuke',     'tank.found.stability'),
  ('tank.found.stability',  'tank.found.vigor'),

  -- Row-1 anchors
  ('tank.found.rebuke',     'tank.prot.cleave'),
  ('tank.found.stability',  'tank.prot.cleave'),
  ('tank.found.plate',      'tank.ward.shield'),
  ('tank.found.stoneform',  'tank.ward.shield'),
  ('tank.found.resilience', 'tank.jug.fortify'),
  ('tank.found.vigor',      'tank.jug.fortify'),

  -- Weak cross-lane links
  ('tank.prot.cleave',      'tank.ward.shield'),
  ('tank.ward.shield',      'tank.jug.fortify'),

  -- Row-1 → row-2 within lane
  ('tank.prot.cleave',      'tank.prot.challenge'),
  ('tank.ward.shield',      'tank.ward.reflect'),
  ('tank.jug.fortify',      'tank.jug.immovable'),

  -- Row-2 → row-3 within lane
  ('tank.prot.challenge',   'tank.prot.retaliation'),
  ('tank.ward.reflect',     'tank.ward.absolution'),
  ('tank.jug.immovable',    'tank.jug.unbreakable'),

  -- Row-3 → Keystone
  ('tank.prot.retaliation', 'tank.key.taunt'),
  ('tank.ward.absolution',  'tank.key.aegis_wall'),
  ('tank.jug.unbreakable',  'tank.key.unstoppable'),

  -- Keystone → Ultimate (only Warden and Protector lanes get ult per spec §7.6)
  ('tank.key.aegis_wall',   'tank.ult.fortress'),
  ('tank.key.taunt',        'tank.ult.earthshatter')
);

COMMIT;
