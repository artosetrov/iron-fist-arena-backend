-- Interactive Combat v1 — Phase 1.3: Mark 8 MVP activatable talents.
-- Idempotent: UPDATE-based, safe to re-run.
-- Nodes chosen: 1 tier-5 ultimate + 1 tier-3 keystone per class (4 classes × 2 = 8).

-- WARRIOR
UPDATE "public"."passive_nodes"
SET "is_activatable"    = TRUE,
    "active_action_type" = 'burst_damage',
    "active_cooldown"    = 5,
    "active_magnitude"   = 0.75
WHERE "node_key" = 'warrior_5_ult';

UPDATE "public"."passive_nodes"
SET "is_activatable"    = TRUE,
    "active_action_type" = 'burst_damage',
    "active_cooldown"    = 3,
    "active_magnitude"   = 0.35
WHERE "node_key" = 'warrior_3_fury';

-- ROGUE
UPDATE "public"."passive_nodes"
SET "is_activatable"    = TRUE,
    "active_action_type" = 'execute',
    "active_cooldown"    = 5,
    "active_magnitude"   = 0.30
WHERE "node_key" = 'rogue_5_ult';

UPDATE "public"."passive_nodes"
SET "is_activatable"    = TRUE,
    "active_action_type" = 'burst_damage',
    "active_cooldown"    = 3,
    "active_magnitude"   = 0.40
WHERE "node_key" = 'rogue_3_shadow';

-- MAGE
UPDATE "public"."passive_nodes"
SET "is_activatable"    = TRUE,
    "active_action_type" = 'stun_enemy',
    "active_cooldown"    = 6,
    "active_magnitude"   = 1.0
WHERE "node_key" = 'mage_5_ult';

UPDATE "public"."passive_nodes"
SET "is_activatable"    = TRUE,
    "active_action_type" = 'burst_damage',
    "active_cooldown"    = 3,
    "active_magnitude"   = 0.45
WHERE "node_key" = 'mage_3_arcane';

-- TANK
UPDATE "public"."passive_nodes"
SET "is_activatable"    = TRUE,
    "active_action_type" = 'shield_self',
    "active_cooldown"    = 5,
    "active_magnitude"   = 0.30
WHERE "node_key" = 'tank_5_ult';

UPDATE "public"."passive_nodes"
SET "is_activatable"    = TRUE,
    "active_action_type" = 'heal_self',
    "active_cooldown"    = 4,
    "active_magnitude"   = 0.20
WHERE "node_key" = 'tank_3_fortress';
