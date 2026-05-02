-- =============================================================================
-- passives-warrior-v2.sql — Warrior talent tree, Talents v2 (2026-04-19)
-- Canonical spec: docs/06_game_systems/SKILL_TREE_DESIGN_V2.md §4
-- =============================================================================
--
-- Scope:
--   23 Warrior-class PassiveNode rows + their connections, all prefixed
--   `warrior.(found|berserk|crus|exec|key|ult).<name>`. Non-warrior classes
--   and legacy warrior rows (node_key LIKE 'warrior_%') are left untouched so
--   this seed can be re-run before the Rogue/Mage/Tank v2 seeds land.
--
-- Idempotency:
--   Wipes only `character_passives` + `passive_connections` + `passive_nodes`
--   that match our `warrior.*` dotted keys. Safe to re-run in dev/staging.
--   NOT safe on prod if any player has unlocked a warrior.v2 node — treat it
--   as a bootstrap-only seed until the data fully stabilizes.
--
-- Known spec-vs-schema gaps (flagged for Phase 1.5 follow-up):
--   1. Non-linear rank magnitudes (e.g. Vitality 3%/6%/10%) are approximated
--      as linear (3/6/9) because CharacterPassive scales bonusValue × rank at
--      runtime. See build-stats.ts / combat-loader.ts Talents v2 comments.
--      Fixing this properly requires either a `rank_magnitudes JSON` column
--      on PassiveNode or a non-linear rank multiplier in aggregatePassiveBonuses.
--   2. PassiveBonusType enum can't express several spec effects. Proxies used:
--        • "attack speed"           → percent_damage
--        • "crit chance after kill" → flat_crit_chance (no conditional)
--        • "reflect melee"          → damage_reduction
--        • "heal on block"          → lifesteal
--        • "crit damage"            → percent_damage
--        • "damage vs low HP"       → percent_damage
--        • "skip turn on kill"      → cooldown_reduction
--        • "HP restore threshold"   → percent_hp
--        • "damage reduction below 30% HP" → damage_reduction (no conditional)
--      Each such row is marked with `-- PROXY:` in the comment column. Real
--      mechanics land when the relevant effect systems ship.
--   3. Spec §4.3 defines Crusader "mirror" lane (M′) with its own row-3 node,
--      but topology §3 only reserves one S-M3 slot. Seed places Sanctified at
--      (520, 180) and Aegis at (680, 180), sharing the row visually but kept
--      as independent nodes per §4 table.
--   4. Ultimate §4.6 `champion` grants both +20% armor AND +20% magic resist.
--      Schema allows only one bonusType per node; seed uses percent_armor +
--      the active skill magnitude. Magic-resist half will become a second
--      node or a compound-bonus column in a later pass.
--
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Scope-limited wipe (warrior.* dotted keys only)
-- ---------------------------------------------------------------------------
DELETE FROM character_passives
 WHERE node_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'warrior.%');

DELETE FROM passive_connections
 WHERE from_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'warrior.%')
    OR to_id   IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'warrior.%');

DELETE FROM character_active_slots
 WHERE node_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'warrior.%');

DELETE FROM passive_nodes WHERE node_key LIKE 'warrior.%';

-- ---------------------------------------------------------------------------
-- 2. Nodes (23 rows)
--    cost=6 ⇒ 3-rank (rankCosts 1/2/3) — Foundation + Specialization.
--    cost=3 ⇒ single-rank Keystone.
--    cost=5 ⇒ single-rank Ultimate (+ activatable fields).
--    position_x/y per topology grid §3 (world canvas 1400×600).
-- ---------------------------------------------------------------------------
INSERT INTO passive_nodes
  (id, node_key, name, description, bonus_type, bonus_stat, bonus_value,
   tier, position_x, position_y, cost, class_restriction, is_start_node, is_active,
   is_activatable, active_action_type, active_cooldown, active_magnitude)
VALUES
  -- Foundation (tier 1, y=520) ---------------------------------------------
  (gen_random_uuid(), 'warrior.found.vitality',     'Vitality',     '+3%/+6%/+9% Max HP',                      'percent_hp'::"PassiveBonusType",         NULL,  3, 1,  0, 0, 6, 'warrior'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'warrior.found.iron_skin',    'Iron Skin',    '+2/+4/+6 Armor',                          'flat_armor'::"PassiveBonusType",         NULL,  2, 1,  80, 0, 6, 'warrior'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'warrior.found.wards',        'Wards',        '+2/+4/+6 Magic Resist',                   'flat_magic_resist'::"PassiveBonusType",  NULL,  2, 1,  160, 0, 6, 'warrior'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'warrior.found.critical_eye', 'Critical Eye', '+1%/+2%/+3% Critical Strike Chance',      'flat_crit_chance'::"PassiveBonusType",   NULL,  1, 1,  240, 0, 6, 'warrior'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'warrior.found.swift_resolve','Swift Resolve','+3%/+6%/+9% Damage',                      'percent_damage'::"PassiveBonusType",     NULL,  3, 1,  320, 0, 6, 'warrior'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: attack speed
  (gen_random_uuid(), 'warrior.found.lifesteal',    'Lifesteal',    '+2%/+4%/+6% Life Steal',                  'lifesteal'::"PassiveBonusType",          NULL,  2, 1, 400, 0, 6, 'warrior'::"CharacterClass", TRUE, TRUE, FALSE, NULL, NULL, NULL),

  -- Berserker lane (offense, tier 2, x~220→300) ----------------------------
  (gen_random_uuid(), 'warrior.berserk.rage',       'Rage',         '+4%/+8%/+12% Damage',                     'percent_damage'::"PassiveBonusType",     NULL,  4, 2,  80, 80, 6, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'warrior.berserk.momentum',   'Momentum',     '+3%/+6%/+9% Critical Strike Chance',      'flat_crit_chance'::"PassiveBonusType",   NULL,  3, 2,  80, 160, 6, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: crit-after-kill (30s)
  (gen_random_uuid(), 'warrior.berserk.bloodlust',  'Bloodlust',    '+4%/+8%/+12% Life Steal',                 'lifesteal'::"PassiveBonusType",          NULL,  4, 2,  80, 240, 6, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: only below 50% HP

  -- Crusader lane — primary (balance, tier 2, x=430) -----------------------
  (gen_random_uuid(), 'warrior.crus.iron_will',     'Iron Will',    '+3%/+6%/+9% Magic Resist',                'percent_magic_resist'::"PassiveBonusType", NULL,  3, 2,  160, 80, 6, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: "all resists" → magic resist only
  (gen_random_uuid(), 'warrior.crus.retribution',   'Retribution',  '+3%/+6%/+9% Damage Reduction',            'damage_reduction'::"PassiveBonusType",   NULL,  3, 2,  160, 160, 6, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: reflect melee
  (gen_random_uuid(), 'warrior.crus.sanctified',    'Sanctified',   '+10%/+20%/+30% Life Steal',               'lifesteal'::"PassiveBonusType",          NULL, 10, 2,  160, 240, 6, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: heal on block

  -- Crusader lane — mirror (balance, tier 2, x=600) ------------------------
  (gen_random_uuid(), 'warrior.crus.fortitude',     'Fortitude',    '+5%/+10%/+15% Max HP',                    'percent_hp'::"PassiveBonusType",         NULL,  5, 2,  240, 80, 6, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'warrior.crus.second_wind',   'Second Wind',  '+10%/+20%/+30% Max HP (threshold heal)',  'percent_hp'::"PassiveBonusType",         NULL, 10, 2,  240, 160, 6, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: threshold heal at 25% HP
  (gen_random_uuid(), 'warrior.crus.aegis',         'Aegis',        '+5%/+10%/+15% Damage Reduction',          'damage_reduction'::"PassiveBonusType",   NULL,  5, 2,  240, 240, 6, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: only below 30% HP

  -- Executioner lane (defense grid / theme=finishers, tier 2, x~830→800) ---
  (gen_random_uuid(), 'warrior.exec.ruthless',      'Ruthless',     '+5%/+10%/+15% Damage',                    'percent_damage'::"PassiveBonusType",     NULL,  5, 2,  320, 80, 6, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: crit damage
  (gen_random_uuid(), 'warrior.exec.execute',       'Execute',      '+10%/+20%/+30% Damage',                   'percent_damage'::"PassiveBonusType",     NULL, 10, 2,  320, 160, 6, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: vs enemies < 30% HP
  (gen_random_uuid(), 'warrior.exec.decapitate',    'Decapitate',   '+5%/+10%/+15% Cooldown Reduction',        'cooldown_reduction'::"PassiveBonusType", NULL,  5, 2,  320, 240, 6, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: skip enemy turn on kill

  -- Keystones (tier 3, single-rank, cost 3) --------------------------------
  (gen_random_uuid(), 'warrior.key.frenzy',         'Frenzy',       '+7% Damage (Chance of extra strike)',     'percent_damage'::"PassiveBonusType",     NULL,  7, 3,  80, 320, 3, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: 15% extra-strike @ 50% dmg
  (gen_random_uuid(), 'warrior.key.bulwark',        'Bulwark',      '+10% Damage Reduction (while >80% HP)',   'damage_reduction'::"PassiveBonusType",   NULL, 10, 3,  200, 320, 3, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL),
  (gen_random_uuid(), 'warrior.key.headsman',       'Headsman',     '+15% Damage (crits on <40% HP)',          'percent_damage'::"PassiveBonusType",     NULL, 15, 3,  320, 320, 3, 'warrior'::"CharacterClass", FALSE, TRUE, FALSE, NULL, NULL, NULL), -- PROXY: 1.8× crit vs low HP

  -- Ultimates (tier 4, single-rank, cost 5, isActivatable) ------------------
  (gen_random_uuid(), 'warrior.ult.unleash',        'Unleash the Beast', '+25% Damage (also +10% damage taken). Active: Rampage.', 'percent_damage'::"PassiveBonusType", NULL, 25, 4, 80, 400, 5, 'warrior'::"CharacterClass", FALSE, TRUE, TRUE,  'burst_damage'::"TalentSlotAction",     90, 60),
  (gen_random_uuid(), 'warrior.ult.champion',       'Champion''s Resolve','+20% Armor. Active: Guardian Oath.',               'percent_armor'::"PassiveBonusType",  NULL, 20, 4, 200, 400, 5, 'warrior'::"CharacterClass", FALSE, TRUE, TRUE,  'shield_self'::"TalentSlotAction",      75, 50);
  -- NOTE: Unleash's "+10% damage taken" drawback + Champion's "+20% magic resist"
  -- second bonus are NOT applied here (single-bonus-per-node schema). Track as
  -- Phase 1.5 follow-up; see seed header §4.

-- ---------------------------------------------------------------------------
-- 3. Connections
--    Foundation chain (left ↔ right) + row prereqs per spec §4.
--    Directed edges; unlock logic treats edges as undirected so one row is
--    enough per adjacency pair. Weak cross-lane links included per spec.
-- ---------------------------------------------------------------------------
WITH n AS (SELECT id, node_key FROM passive_nodes WHERE node_key LIKE 'warrior.%')
INSERT INTO passive_connections (id, from_id, to_id)
SELECT gen_random_uuid(), a.id, b.id
FROM n a
JOIN n b ON TRUE
WHERE (a.node_key, b.node_key) IN (
  -- Foundation horizontal chain F1..F6
  ('warrior.found.vitality',     'warrior.found.iron_skin'),
  ('warrior.found.iron_skin',    'warrior.found.wards'),
  ('warrior.found.wards',        'warrior.found.critical_eye'),
  ('warrior.found.critical_eye', 'warrior.found.swift_resolve'),
  ('warrior.found.swift_resolve','warrior.found.lifesteal'),

  -- Row-1 specialization anchors to nearest Foundation
  ('warrior.found.critical_eye', 'warrior.berserk.rage'),       -- offense anchor
  ('warrior.found.swift_resolve','warrior.berserk.rage'),       -- alt anchor (offense theme)
  ('warrior.found.iron_skin',    'warrior.crus.iron_will'),     -- primary balance anchor
  ('warrior.found.wards',        'warrior.crus.iron_will'),     -- alt anchor
  ('warrior.found.vitality',     'warrior.crus.fortitude'),     -- mirror balance anchor
  ('warrior.found.lifesteal',    'warrior.exec.ruthless'),      -- defense/finisher anchor
  ('warrior.found.critical_eye', 'warrior.exec.ruthless'),      -- alt anchor

  -- Weak cross-lane links (§4.3/§4.4)
  ('warrior.berserk.rage',       'warrior.crus.iron_will'),     -- offense ↔ balance weak
  ('warrior.crus.iron_will',     'warrior.exec.ruthless'),      -- balance ↔ defense weak

  -- Row-1 → row-2 within lane
  ('warrior.berserk.rage',       'warrior.berserk.momentum'),
  ('warrior.crus.iron_will',     'warrior.crus.retribution'),
  ('warrior.crus.fortitude',     'warrior.crus.second_wind'),
  ('warrior.exec.ruthless',      'warrior.exec.execute'),

  -- Row-2 → row-3 within lane
  ('warrior.berserk.momentum',   'warrior.berserk.bloodlust'),
  ('warrior.crus.retribution',   'warrior.crus.sanctified'),
  ('warrior.crus.second_wind',   'warrior.crus.aegis'),
  ('warrior.exec.execute',       'warrior.exec.decapitate'),

  -- Row-3 → Keystone
  ('warrior.berserk.bloodlust',  'warrior.key.frenzy'),
  ('warrior.crus.sanctified',    'warrior.key.bulwark'),
  ('warrior.crus.aegis',         'warrior.key.bulwark'),          -- §4.5: needs BOTH Crusader r3
  ('warrior.exec.decapitate',    'warrior.key.headsman'),

  -- Keystone → Ultimate
  ('warrior.key.frenzy',         'warrior.ult.unleash'),
  ('warrior.key.bulwark',        'warrior.ult.champion')
);

COMMIT;

-- ---------------------------------------------------------------------------
-- 4. Sanity check (run after seed, expect 23 / 25)
-- ---------------------------------------------------------------------------
-- SELECT COUNT(*) AS nodes        FROM passive_nodes       WHERE node_key LIKE 'warrior.%';
-- SELECT COUNT(*) AS connections  FROM passive_connections
--   WHERE from_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'warrior.%')
--      OR to_id   IN (SELECT id FROM passive_nodes WHERE node_key LIKE 'warrior.%');
