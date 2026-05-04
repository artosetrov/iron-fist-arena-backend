-- =============================================================================
-- passives-tank-v2.sql — Tank talent tree, Talents v2 (2026-04-29)
-- Canonical spec: docs/06_game_systems/SKILL_TREE_DESIGN_V2.md §7
-- Updated 2026-05-01: added narrative `flavor` column for each node.
-- =============================================================================
--
-- Scope: 20 Tank-class PassiveNode rows + connections, prefixed
--   `tank.(found|prot|ward|jug|key|ult).<name>`. Non-tank classes untouched.
--
-- Active ultimates (require migration 20260429_talent_action_v2_ults applied):
--   * tank.ult.fortress     → shield_self magnitude 0.70 CD 90
--   * tank.ult.earthshatter → aoe_stun    magnitude 1    CD 120
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
  (id, node_key, name, description, flavor, bonus_type, bonus_stat, bonus_value,
   tier, position_x, position_y, cost, class_restriction, is_start_node, is_active,
   is_activatable, active_action_type, active_cooldown, active_magnitude)
VALUES
  -- Foundation (tier 1, y=520) ---------------------------------------------
  (gen_random_uuid(), 'tank.found.stoneform',   'Stoneform',   '+5%/+10%/+15% Max HP',           'Stand like the mountain. Each rank thickens flesh into bedrock — harder to chip, harder to break.', 'percent_hp'::"PassiveBonusType",         NULL,  5, 1,  0, 0, 6, 'tank'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.found.plate',       'Plate',       '+3/+6/+9 Armor',                 'Forged steel between your skin and the world. Reduces incoming physical bite.', 'flat_armor'::"PassiveBonusType",         NULL,  3, 1,  80, 0, 6, 'tank'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.found.resilience',  'Resilience',  '+2%/+4%/+6% Damage Reduction',   'You learn where blades land. Every wound teaches; every scar shaves a little off the next one.', 'damage_reduction'::"PassiveBonusType",   NULL,  2, 1,  160, 0, 6, 'tank'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.found.rebuke',      'Rebuke',      '+5%/+10%/+15% Damage',           'A challenge in every swing. Your strikes pull the enemy''s eyes — and their wrath — away from your allies.', 'percent_damage'::"PassiveBonusType",     NULL,  5, 1,  240, 0, 6, 'tank'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: threat generation
  (gen_random_uuid(), 'tank.found.stability',   'Stability',   '+5%/+10%/+15% Damage Reduction', 'Roots run deep. Hexes, stuns, and shoves slip off you like rain off a battlement.', 'damage_reduction'::"PassiveBonusType",   NULL,  5, 1,  320, 0, 6, 'tank'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: CC resistance
  (gen_random_uuid(), 'tank.found.vigor',       'Vigor',       '+3%/+6%/+9% Life Steal',         'The body that endures, mends. A slow tide of strength returns with every passing breath.', 'lifesteal'::"PassiveBonusType",          NULL,  3, 1, 400, 0, 6, 'tank'::"CharacterClass", TRUE, FALSE, FALSE, NULL, NULL, NULL), -- PROXY: HP regen per turn

  -- Protector lane (offense, tier 2) ----------------------------------------
  (gen_random_uuid(), 'tank.prot.cleave',       'Cleave',         '+5%/+10%/+15% Damage',        'One swing carves through more than one foe. The blade keeps moving until the line breaks.', 'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  120, 80, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.prot.challenge',    'Challenge',      '+3%/+6%/+9% Critical Strike Chance', 'Mark the strongest, then strike for the seam. The bigger they are, the better you read them.', 'flat_crit_chance'::"PassiveBonusType", NULL, 3, 2,  120, 160, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: vs highest-HP enemy
  (gen_random_uuid(), 'tank.prot.retaliation',  'Retaliation',    '+5%/+10%/+15% Damage',        'Every blow you take is loaned. The next swing of yours lands with the weight of every wound.', 'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  120, 240, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: damage after being hit

  -- Warden lane (balance, tier 2) -------------------------------------------
  (gen_random_uuid(), 'tank.ward.shield',       'Shield',         '+5%/+10%/+15% Damage',        'The shield is not just a wall. Slammed forward, its rim is a hammer; its boss, a club.', 'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  200, 80, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: shield-bash damage
  (gen_random_uuid(), 'tank.ward.reflect',      'Reflect',        '+3%/+6%/+9% Damage Reduction','Hatred is contagious. A measure of every blade brought against you finds its way back to its master.', 'damage_reduction'::"PassiveBonusType",   NULL,  3, 2,  200, 160, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: reflect to attacker
  (gen_random_uuid(), 'tank.ward.absolution',   'Absolution',     '+10%/+20%/+30% Life Steal',   'Hold the line, and the line holds you. Each blow you turn aside knits the flesh beneath the steel.', 'lifesteal'::"PassiveBonusType",          NULL, 10, 2,  200, 240, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: heal when blocking

  -- Juggernaut lane (defense, tier 2) ---------------------------------------
  (gen_random_uuid(), 'tank.jug.fortify',       'Fortify',        '+3%/+6%/+9% Damage Reduction','Brace, breathe, refuse to fall. Your stance grows wider, your guard heavier.', 'damage_reduction'::"PassiveBonusType",   NULL,  3, 2,  280, 80, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.jug.immovable',     'Immovable',      '+10%/+20%/+30% Damage Reduction', 'The earth does not flinch. Stuns, fears, and chains slip their hold on you sooner.', 'damage_reduction'::"PassiveBonusType", NULL, 10, 2,  280, 160, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: CC duration on self
  (gen_random_uuid(), 'tank.jug.unbreakable',   'Unbreakable',    '+10%/+20%/+30% Life Steal',   'Wounded beasts are the most dangerous. The closer to the edge, the harder you claw your way back.', 'lifesteal'::"PassiveBonusType",          NULL, 10, 2,  280, 240, 6, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: HP regen below 30%

  -- Keystones (tier 3, single-rank, cost 3) ---------------------------------
  (gen_random_uuid(), 'tank.key.taunt',         'Taunt',          '+15% Damage (AoE taunt every 10s)', 'You scream the warband''s name and a dozen heads turn. None will turn away while you still stand.', 'percent_damage'::"PassiveBonusType",NULL, 15, 3,  120, 320, 3, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.key.aegis_wall',    'Aegis Wall',     '+15% Damage Reduction (active shield)', 'Plant the shield, raise the wall. For a moment, nothing passes through you that you do not allow.', 'damage_reduction'::"PassiveBonusType", NULL, 15, 3, 200, 320, 3, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'tank.key.unstoppable',   'Unstoppable',    '+15% Damage Reduction (CC immune <50% HP)', 'Past a certain point, pain stops mattering. Below half-blood, no chain holds, no spell binds.', 'damage_reduction'::"PassiveBonusType", NULL, 15, 3, 280, 320, 3, 'tank'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),

  -- Ultimates (tier 4, single-rank, cost 5, isActivatable) ------------------
  (gen_random_uuid(), 'tank.ult.fortress',      'Fortress',       '+25% Max HP. Active: Bastion.', 'You are not a soldier. You are the wall the enemy breaks against. Bastion layers your hide in absorbing stone.', 'percent_hp'::"PassiveBonusType",        NULL, 25, 4, 160, 400, 5, 'tank'::"CharacterClass", FALSE, TRUE, TRUE, 'shield_self'::"TalentSlotAction", 90,  0.7),
  -- Balance pass 2026-04-29: aoe_stun 2→1 rounds (2 rounds = ~25%-of-match silence + OP combo with +30% passive)
  (gen_random_uuid(), 'tank.ult.earthshatter',  'Earthshatter',   '+30% Damage. Active: Quake.', 'Strike the ground hard enough and the world remembers it. Quake sunders the field beneath every foe.', 'percent_damage'::"PassiveBonusType",     NULL, 30, 4, 240, 400, 5, 'tank'::"CharacterClass", FALSE, TRUE, TRUE, 'aoe_stun'::"TalentSlotAction",   120,  1);

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
