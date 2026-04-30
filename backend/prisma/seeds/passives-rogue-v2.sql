-- =============================================================================
-- passives-rogue-v2.sql — Rogue talent tree, Talents v2 (2026-04-29)
-- Canonical spec: docs/06_game_systems/SKILL_TREE_DESIGN_V2.md §5
-- =============================================================================
--
-- Scope:
--   20 Rogue-class PassiveNode rows + connections, prefixed
--   `rogue.(found|asn|duel|sab|key|ult).<name>`. Non-rogue classes and legacy
--   rogue rows (node_key LIKE 'rogue_%') are left untouched.
--
-- Idempotency:
--   Wipes only `character_passives` + `passive_connections` + `passive_nodes`
--   that match our `rogue.*` dotted keys. Safe to re-run on dev/staging.
--   On prod: only safe before any player has unlocked a rogue.v2 node.
--
-- Active ultimates (require migration 20260429_talent_action_v2_ults applied):
--   * rogue.ult.vanish        → stealth      magnitude 1   CD 75
--   * rogue.ult.shadow_reaper → burst_damage magnitude 0.8 CD 75
--
-- Known spec-vs-schema gaps (Phase 1.5 follow-up, mirror Warrior gap list):
--   1. Non-linear rank magnitudes are linearised (1/2/4 → 1/2/3 etc) because
--      CharacterPassive scales bonusValue × rank linearly at runtime.
--   2. PassiveBonusType enum can't express several spec effects. Proxies used:
--        • "attack speed"           → percent_damage
--        • "initiative"             → percent_damage
--        • "poison damage"          → percent_damage (no DoT type)
--        • "first-strike damage"    → percent_damage
--        • "bleed DoT"              → percent_damage
--        • "parry chance"           → flat_dodge_chance
--        • "counter damage"         → percent_damage
--        • "stun chance on crit"    → flat_crit_chance
--        • "enemy damage debuff"    → damage_reduction
--      Each such row carries `-- PROXY:` in the comment column.
--
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Scope-limited wipe (rogue.* dotted keys only)
-- ---------------------------------------------------------------------------
DELETE FROM character_passives
 WHERE node_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'rogue.%');

DELETE FROM passive_connections
 WHERE from_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'rogue.%')
    OR to_id   IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'rogue.%');

DELETE FROM character_active_slots
 WHERE node_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'rogue.%');

DELETE FROM passive_nodes WHERE node_key LIKE 'rogue.%';

-- ---------------------------------------------------------------------------
-- 2. Nodes (20 rows: 6 Foundation + 9 Specialization + 3 Keystone + 2 Ultimate)
-- ---------------------------------------------------------------------------
INSERT INTO passive_nodes
  (id, node_key, name, description, bonus_type, bonus_stat, bonus_value,
   tier, position_x, position_y, cost, class_restriction, is_start_node, is_active,
   is_activatable, active_action_type, active_cooldown, active_magnitude)
VALUES
  -- Foundation (tier 1, y=520) ---------------------------------------------
  (gen_random_uuid(), 'rogue.found.agility',    'Agility',    '+1%/+2%/+3% Dodge Chance',                  'flat_dodge_chance'::"PassiveBonusType",  NULL,  1, 1,  120, 520, 6, 'rogue'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'rogue.found.precision',  'Precision',  '+1%/+2%/+3% Critical Strike Chance',        'flat_crit_chance'::"PassiveBonusType",   NULL,  1, 1,  300, 520, 6, 'rogue'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'rogue.found.shadows',    'Shadows',    '+2%/+4%/+6% Cooldown Reduction',            'cooldown_reduction'::"PassiveBonusType", NULL,  2, 1,  480, 520, 6, 'rogue'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'rogue.found.venom',      'Venom',      '+3%/+6%/+9% Damage',                        'percent_damage'::"PassiveBonusType",     NULL,  3, 1,  680, 520, 6, 'rogue'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: poison damage
  (gen_random_uuid(), 'rogue.found.swiftness',  'Swiftness',  '+3%/+6%/+9% Damage',                        'percent_damage'::"PassiveBonusType",     NULL,  3, 1,  880, 520, 6, 'rogue'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: attack speed
  (gen_random_uuid(), 'rogue.found.cunning',    'Cunning',    '+3%/+6%/+9% Damage',                        'percent_damage'::"PassiveBonusType",     NULL,  3, 1, 1080, 520, 6, 'rogue'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: initiative

  -- Assassin lane (offense, tier 2) ----------------------------------------
  (gen_random_uuid(), 'rogue.asn.backstab',     'Backstab',   '+5%/+10%/+15% Damage',                      'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  220, 400, 6, 'rogue'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: first-strike damage
  (gen_random_uuid(), 'rogue.asn.bleed',        'Bleed',      '+4%/+8%/+12% Damage',                       'percent_damage'::"PassiveBonusType",     NULL,  4, 2,  220, 290, 6, 'rogue'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: bleed DoT chance on crit
  (gen_random_uuid(), 'rogue.asn.deep_cut',     'Deep Cut',   '+4%/+8%/+12% Critical Strike Chance',       'flat_crit_chance'::"PassiveBonusType",   NULL,  4, 2,  300, 180, 6, 'rogue'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: vs bleeding targets

  -- Duelist lane (balance, tier 2) -----------------------------------------
  (gen_random_uuid(), 'rogue.duel.parry',       'Parry',      '+3%/+6%/+9% Dodge Chance',                  'flat_dodge_chance'::"PassiveBonusType",  NULL,  3, 2,  430, 400, 6, 'rogue'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: parry chance
  (gen_random_uuid(), 'rogue.duel.riposte',     'Riposte',    '+5%/+10%/+15% Damage',                      'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  430, 290, 6, 'rogue'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: counter damage on parry
  (gen_random_uuid(), 'rogue.duel.finesse',     'Finesse',    '+5%/+10%/+15% Damage',                      'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  600, 180, 6, 'rogue'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: crit damage vs single target

  -- Saboteur lane (defense grid / theme=attrition, tier 2) ------------------
  (gen_random_uuid(), 'rogue.sab.toxin',        'Toxin',      '+5%/+10%/+15% Damage',                      'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  830, 400, 6, 'rogue'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: poison damage
  (gen_random_uuid(), 'rogue.sab.paralyze',     'Paralyze',   '+3%/+6%/+9% Critical Strike Chance',        'flat_crit_chance'::"PassiveBonusType",   NULL,  3, 2,  830, 290, 6, 'rogue'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: stun chance on crit
  (gen_random_uuid(), 'rogue.sab.weaken',       'Weaken',     '+5%/+10%/+15% Damage Reduction',            'damage_reduction'::"PassiveBonusType",   NULL,  5, 2,  800, 180, 6, 'rogue'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: enemy damage debuff

  -- Keystones (tier 3, single-rank, cost 3) --------------------------------
  (gen_random_uuid(), 'rogue.key.shadowstrike',  'Shadowstrike',   '+15% Damage (every 5th attack ×2)',  'percent_damage'::"PassiveBonusType",     NULL, 15, 3,  300,  80, 3, 'rogue'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'rogue.key.riposte_master','Riposte Master', '+20% Damage (counter melee 20%)',    'percent_damage'::"PassiveBonusType",     NULL, 20, 3,  600,  80, 3, 'rogue'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: 20% counter melee
  (gen_random_uuid(), 'rogue.key.envenom',       'Envenom',        '+10% Damage Reduction (poison stun)','damage_reduction'::"PassiveBonusType",   NULL, 10, 3,  800,  80, 3, 'rogue'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: poisons apply 1s stun on tick

  -- Ultimates (tier 4, single-rank, cost 5, isActivatable) ------------------
  -- Balance pass 2026-04-29: CD 60→75 (was shortest in game while passive only +15%; aligned with Champion/Shadow Reaper)
  (gen_random_uuid(), 'rogue.ult.vanish',         'Vanish',         '+15% Damage. Active: Fade.',         'percent_damage'::"PassiveBonusType",     NULL, 15, 4, 450, 20, 5, 'rogue'::"CharacterClass", FALSE, TRUE, TRUE, 'stealth'::"TalentSlotAction",     75,    1),
  (gen_random_uuid(), 'rogue.ult.shadow_reaper',  'Shadow Reaper',  '+30% Damage. Active: Reap.',         'percent_damage'::"PassiveBonusType",     NULL, 30, 4, 750, 20, 5, 'rogue'::"CharacterClass", FALSE, TRUE, TRUE, 'burst_damage'::"TalentSlotAction",75, 0.8);

-- ---------------------------------------------------------------------------
-- 3. Connections (20 edges)
-- ---------------------------------------------------------------------------
WITH n AS (SELECT id, node_key FROM passive_nodes WHERE node_key LIKE 'rogue.%')
INSERT INTO passive_connections (id, from_id, to_id)
SELECT gen_random_uuid(), a.id, b.id
FROM n a
JOIN n b ON TRUE
WHERE (a.node_key, b.node_key) IN (
  -- Foundation horizontal chain F1..F6
  ('rogue.found.agility',   'rogue.found.precision'),
  ('rogue.found.precision', 'rogue.found.shadows'),
  ('rogue.found.shadows',   'rogue.found.venom'),
  ('rogue.found.venom',     'rogue.found.swiftness'),
  ('rogue.found.swiftness', 'rogue.found.cunning'),

  -- Row-1 specialization anchors to nearest Foundation
  ('rogue.found.precision', 'rogue.asn.backstab'),    -- offense anchor
  ('rogue.found.cunning',   'rogue.asn.backstab'),    -- alt anchor (offense theme)
  ('rogue.found.agility',   'rogue.duel.parry'),      -- balance anchor
  ('rogue.found.swiftness', 'rogue.duel.parry'),      -- alt anchor
  ('rogue.found.venom',     'rogue.sab.toxin'),       -- defense anchor
  ('rogue.found.shadows',   'rogue.sab.toxin'),       -- alt anchor

  -- Weak cross-lane links (§5.3/§5.4)
  ('rogue.asn.backstab',    'rogue.duel.parry'),      -- offense ↔ balance weak
  ('rogue.duel.parry',      'rogue.sab.toxin'),       -- balance ↔ defense weak

  -- Row-1 → row-2 within lane
  ('rogue.asn.backstab',    'rogue.asn.bleed'),
  ('rogue.duel.parry',      'rogue.duel.riposte'),
  ('rogue.sab.toxin',       'rogue.sab.paralyze'),

  -- Row-2 → row-3 within lane
  ('rogue.asn.bleed',       'rogue.asn.deep_cut'),
  ('rogue.duel.riposte',    'rogue.duel.finesse'),
  ('rogue.sab.paralyze',    'rogue.sab.weaken'),

  -- Row-3 → Keystone
  ('rogue.asn.deep_cut',    'rogue.key.shadowstrike'),
  ('rogue.duel.finesse',    'rogue.key.riposte_master'),
  ('rogue.sab.weaken',      'rogue.key.envenom'),

  -- Keystone → Ultimate (only 2 of 3 keystones grant ult per spec §5.6)
  ('rogue.key.shadowstrike','rogue.ult.vanish'),
  ('rogue.key.envenom',     'rogue.ult.shadow_reaper')
);

COMMIT;

-- ---------------------------------------------------------------------------
-- 4. Sanity check (run after seed, expect 20 / 24)
-- ---------------------------------------------------------------------------
-- SELECT COUNT(*) AS nodes        FROM passive_nodes WHERE node_key LIKE 'rogue.%';
-- SELECT COUNT(*) AS connections  FROM passive_connections
--   WHERE from_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'rogue.%')
--      OR to_id   IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'rogue.%');
