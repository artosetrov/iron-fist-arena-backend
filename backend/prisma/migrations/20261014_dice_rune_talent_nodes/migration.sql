-- 2026-10-14: Dice combat — 16 Lesser rune nodes (4 per class) in the talent tree.
-- Spec: docs/06_game_systems/DICE_RUNES_DESIGN.md §4. Keystones and ultimates
-- become Path / Great runes in code (runes.ts) — their rows are untouched.
--
-- Each Lesser rune is a 1-SP single-rank node one row above the foundation
-- strip (position_y = -80), linked to the foundation node it sits on, so it
-- unlocks once that node has a rank. bonus_value 0: the node grants the rune,
-- not a stat. Idempotent (ON CONFLICT / NOT EXISTS) — safe on prod.
--
-- Anchors avoid the rightmost foundation nodes (x=400): prod deactivated them
-- in `drop_rightmost_foundation_per_class` (applied via Supabase, 2026-05-04).

INSERT INTO passive_nodes
  (id, node_key, name, description, flavor, bonus_type, bonus_stat, bonus_value,
   tier, position_x, position_y, cost, icon, class_restriction, is_start_node, is_active, is_activatable)
SELECT gen_random_uuid(), v.node_key, v.name, v.description, v.flavor, 'flat_damage'::"PassiveBonusType", NULL, 0,
       1, v.x, -80, 1, v.icon, v.cls::"CharacterClass", FALSE, TRUE, FALSE
FROM (VALUES
  ('warrior.rune.wrath', 'Wrath Rune', 'On hit: +1 Focus', 'Socket it into your attack die in Hero → Dice.', 0, 'warrior', 'rune-warrior-wrath'),
  ('warrior.rune.blade', 'Blade Rune', 'This face hits 25% harder', 'Socket it into your attack die in Hero → Dice.', 80, 'warrior', 'rune-warrior-blade'),
  ('warrior.rune.mail', 'Mail Rune', 'Hits taken −35%', 'Socket it into your guard die in Hero → Dice.', 160, 'warrior', 'rune-warrior-mail'),
  ('warrior.rune.endurance', 'Endurance Rune', 'On block: heal 20% HP', 'Socket it into your guard die in Hero → Dice.', 320, 'warrior', 'rune-warrior-endurance'),
  ('rogue.rune.dagger', 'Dagger Rune', 'If blocked: 80% still lands', 'Socket it into your attack die in Hero → Dice.', 80, 'rogue', 'rune-rogue-dagger'),
  ('rogue.rune.bloodletting', 'Bloodletting Rune', 'On hit: bleed 25% next round', 'Socket it into your attack die in Hero → Dice.', 240, 'rogue', 'rune-rogue-bloodletting'),
  ('rogue.rune.evasion', 'Evasion Rune', 'On block: +2 Focus', 'Socket it into your guard die in Hero → Dice.', 0, 'rogue', 'rune-rogue-evasion'),
  ('rogue.rune.smoke', 'Smoke Rune', '30%: a strike at another zone misses', 'Socket it into your guard die in Hero → Dice.', 160, 'rogue', 'rune-rogue-smoke'),
  ('mage.rune.spark', 'Spark Rune', '+30% damage, ignores Wall', 'Socket it into your attack die in Hero → Dice.', 0, 'mage', 'rune-mage-spark'),
  ('mage.rune.mana', 'Mana Rune', 'On land: +1 Focus', 'Socket it into your attack die in Hero → Dice.', 80, 'mage', 'rune-mage-mana'),
  ('mage.rune.barrier', 'Barrier Rune', 'Hits taken −40%', 'Socket it into your guard die in Hero → Dice.', 320, 'mage', 'rune-mage-barrier'),
  ('mage.rune.mirror', 'Mirror Rune', 'On block: reflect 60% back', 'Socket it into your guard die in Hero → Dice.', 240, 'mage', 'rune-mage-mirror'),
  ('tank.rune.ram', 'Ram Rune', '+25% damage; on legs the sweep lasts 2 rounds', 'Socket it into your attack die in Hero → Dice.', 240, 'tank', 'rune-tank-ram'),
  ('tank.rune.stone', 'Stone Rune', 'Hits taken −40%', 'Socket it into your guard die in Hero → Dice.', 0, 'tank', 'rune-tank-stone'),
  ('tank.rune.thorns', 'Thorns Rune', 'On take: 25% goes back to the attacker', 'Socket it into your guard die in Hero → Dice.', 80, 'tank', 'rune-tank-thorns'),
  ('tank.rune.fortify', 'Fortify Rune', 'On block: heal 20% HP', 'Socket it into your guard die in Hero → Dice.', 320, 'tank', 'rune-tank-fortify')
) AS v(node_key, name, description, flavor, x, cls, icon)
ON CONFLICT (node_key) DO NOTHING;

INSERT INTO passive_connections (id, from_id, to_id)
SELECT gen_random_uuid(), f.id, t.id
FROM (VALUES
  ('warrior.found.vitality', 'warrior.rune.wrath'),
  ('warrior.found.iron_skin', 'warrior.rune.blade'),
  ('warrior.found.wards', 'warrior.rune.mail'),
  ('warrior.found.swift_resolve', 'warrior.rune.endurance'),
  ('rogue.found.precision', 'rogue.rune.dagger'),
  ('rogue.found.venom', 'rogue.rune.bloodletting'),
  ('rogue.found.agility', 'rogue.rune.evasion'),
  ('rogue.found.shadows', 'rogue.rune.smoke'),
  ('mage.found.intellect', 'mage.rune.spark'),
  ('mage.found.mana_pool', 'mage.rune.mana'),
  ('mage.found.arcane_armor', 'mage.rune.barrier'),
  ('mage.found.resonance', 'mage.rune.mirror'),
  ('tank.found.rebuke', 'tank.rune.ram'),
  ('tank.found.stoneform', 'tank.rune.stone'),
  ('tank.found.plate', 'tank.rune.thorns'),
  ('tank.found.stability', 'tank.rune.fortify')
) AS c(from_key, to_key)
JOIN passive_nodes f ON f.node_key = c.from_key
JOIN passive_nodes t ON t.node_key = c.to_key
WHERE NOT EXISTS (
  SELECT 1 FROM passive_connections pc WHERE pc.from_id = f.id AND pc.to_id = t.id
);
