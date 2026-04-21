-- Seed 2026-04-21: idempotently repopulate dungeon drop tables.
--
-- Source of truth: `backend/prisma/seed-dungeon-drops.ts` (DUNGEON_DROPS).
-- This .sql mirrors that TS seed so a prod / staging snapshot-restore can
-- rehydrate drop tables without Node tooling.
--
-- Idempotency note: `dungeon_drops` has NO natural unique key — the Prisma
-- model only has PK `id`. We use `WHERE NOT EXISTS` keyed on (dungeon_id,
-- item_id) to guarantee re-runs don't duplicate drops. The TS seed takes the
-- opposite approach (`deleteMany` before insert) which is safe only for
-- bootstrap / controlled repair. This SQL mirror preserves any operator
-- tuning already in place.
--
-- FK lookups: dungeons by slug, items by catalog_id. If either side is
-- missing for a given drop row, that row is silently skipped (the JOIN
-- filters it out) — admins must seed dungeons + items catalogs first.
--
-- When editing drops: update BOTH `seed-dungeon-drops.ts` AND this file in
-- the same commit. See gatekeeper/SKILL.md §6c.
--
-- Related incidents: dungeon drop tables are static catalog and were
-- previously lost on snapshot-restore alongside dungeons/bosses/abilities.

INSERT INTO "dungeon_drops" ("id", "dungeon_id", "item_id", "drop_chance", "min_quantity", "max_quantity", "created_at")
SELECT gen_random_uuid(), d."id", i."id", v.drop_chance, v.min_qty, v.max_qty, NOW()
FROM "dungeons" d
CROSS JOIN (VALUES
  -- ── Training Camp (lvl 1) — mostly common, easy drops ──────────
  ('training_camp',        'wpn_rusty_sword',       15.0, 1, 1),
  ('training_camp',        'wpn_wooden_staff',      15.0, 1, 1),
  ('training_camp',        'wpn_iron_dagger',       12.0, 1, 1),
  ('training_camp',        'wpn_training_mace',     12.0, 1, 1),
  ('training_camp',        'helm_leather_cap',      12.0, 1, 1),
  ('training_camp',        'chest_cloth_robe',      12.0, 1, 1),
  ('training_camp',        'glove_cloth_wraps',     10.0, 1, 1),
  ('training_camp',        'legs_cloth_pants',      10.0, 1, 1),
  ('training_camp',        'boot_sandals',          10.0, 1, 1),
  ('training_camp',        'ring_copper',            8.0, 1, 1),
  ('training_camp',        'amu_copper_chain',       8.0, 1, 1),
  ('training_camp',        'belt_rope',             10.0, 1, 1),
  ('training_camp',        'neck_bone_charm',        8.0, 1, 1),
  ('training_camp',        'health_potion_small',   20.0, 1, 2),
  ('training_camp',        'stamina_potion_small',  18.0, 1, 2),

  -- ── Desecrated Catacombs (lvl ~5) — common + uncommon ──────────
  ('desecrated_catacombs', 'wpn_steel_longsword',   10.0, 1, 1),
  ('desecrated_catacombs', 'wpn_arcane_wand',       10.0, 1, 1),
  ('desecrated_catacombs', 'wpn_shadow_knife',       8.0, 1, 1),
  ('desecrated_catacombs', 'helm_iron_helm',        10.0, 1, 1),
  ('desecrated_catacombs', 'helm_mystic_hood',       8.0, 1, 1),
  ('desecrated_catacombs', 'chest_chain_mail',      10.0, 1, 1),
  ('desecrated_catacombs', 'chest_mage_robe',        8.0, 1, 1),
  ('desecrated_catacombs', 'glove_iron_gauntlets',   8.0, 1, 1),
  ('desecrated_catacombs', 'legs_chain_leggings',    8.0, 1, 1),
  ('desecrated_catacombs', 'boot_iron_treads',       8.0, 1, 1),
  ('desecrated_catacombs', 'acc_iron_shield',        7.0, 1, 1),
  ('desecrated_catacombs', 'amu_silver_pendant',     6.0, 1, 1),
  ('desecrated_catacombs', 'belt_leather',           8.0, 1, 1),
  ('desecrated_catacombs', 'ring_silver',            6.0, 1, 1),
  ('desecrated_catacombs', 'neck_emerald',           6.0, 1, 1),
  ('desecrated_catacombs', 'relic_old_coin',         5.0, 1, 1),
  ('desecrated_catacombs', 'health_potion_small',   15.0, 1, 2),
  ('desecrated_catacombs', 'health_potion_medium',   8.0, 1, 1),
  ('desecrated_catacombs', 'stamina_potion_small',  12.0, 1, 2),

  -- ── Volcanic Forge (lvl ~10) — uncommon + rare ─────────────────
  ('volcanic_forge',       'wpn_flamebrand',         6.0, 1, 1),
  ('volcanic_forge',       'wpn_war_hammer',         8.0, 1, 1),
  ('volcanic_forge',       'wpn_steel_longsword',    7.0, 1, 1),
  ('volcanic_forge',       'helm_dragon_visage',     5.0, 1, 1),
  ('volcanic_forge',       'helm_iron_helm',         8.0, 1, 1),
  ('volcanic_forge',       'chest_plate_armor',      5.0, 1, 1),
  ('volcanic_forge',       'chest_chain_mail',       7.0, 1, 1),
  ('volcanic_forge',       'glove_assassin',         5.0, 1, 1),
  ('volcanic_forge',       'glove_iron_gauntlets',   7.0, 1, 1),
  ('volcanic_forge',       'legs_shadow_pants',      5.0, 1, 1),
  ('volcanic_forge',       'legs_chain_leggings',    7.0, 1, 1),
  ('volcanic_forge',       'boot_windwalkers',       5.0, 1, 1),
  ('volcanic_forge',       'boot_iron_treads',       7.0, 1, 1),
  ('volcanic_forge',       'acc_magic_orb',          4.0, 1, 1),
  ('volcanic_forge',       'belt_titan',             4.0, 1, 1),
  ('volcanic_forge',       'ring_blood_ruby',        4.0, 1, 1),
  ('volcanic_forge',       'neck_dragon_tooth',      4.0, 1, 1),
  ('volcanic_forge',       'relic_skull',            3.0, 1, 1),
  ('volcanic_forge',       'health_potion_medium',  12.0, 1, 2),
  ('volcanic_forge',       'stamina_potion_medium', 10.0, 1, 1),

  -- ── Fungal Grotto (lvl 30) — uncommon + rare ───────────────────
  ('fungal_grotto',        'wpn_frostbite_staff',    6.0, 1, 1),
  ('fungal_grotto',        'wpn_venom_fang',         6.0, 1, 1),
  ('fungal_grotto',        'wpn_arcane_wand',        8.0, 1, 1),
  ('fungal_grotto',        'helm_dragon_visage',     5.0, 1, 1),
  ('fungal_grotto',        'helm_mystic_hood',       7.0, 1, 1),
  ('fungal_grotto',        'chest_shadow_vest',      5.0, 1, 1),
  ('fungal_grotto',        'chest_mage_robe',        7.0, 1, 1),
  ('fungal_grotto',        'glove_assassin',         5.0, 1, 1),
  ('fungal_grotto',        'legs_shadow_pants',      5.0, 1, 1),
  ('fungal_grotto',        'boot_windwalkers',       5.0, 1, 1),
  ('fungal_grotto',        'acc_magic_orb',          4.0, 1, 1),
  ('fungal_grotto',        'amu_silver_pendant',     6.0, 1, 1),
  ('fungal_grotto',        'belt_titan',             4.0, 1, 1),
  ('fungal_grotto',        'ring_blood_ruby',        4.0, 1, 1),
  ('fungal_grotto',        'relic_skull',            3.0, 1, 1),
  ('fungal_grotto',        'health_potion_medium',  12.0, 1, 2),
  ('fungal_grotto',        'stamina_potion_medium', 10.0, 1, 1),

  -- ── Scorched Mines (lvl 35) — rare focused ─────────────────────
  ('scorched_mines',       'wpn_flamebrand',         7.0, 1, 1),
  ('scorched_mines',       'wpn_venom_fang',         6.0, 1, 1),
  ('scorched_mines',       'wpn_war_hammer',         7.0, 1, 1),
  ('scorched_mines',       'helm_dragon_visage',     6.0, 1, 1),
  ('scorched_mines',       'chest_plate_armor',      6.0, 1, 1),
  ('scorched_mines',       'chest_shadow_vest',      5.0, 1, 1),
  ('scorched_mines',       'glove_assassin',         6.0, 1, 1),
  ('scorched_mines',       'legs_shadow_pants',      6.0, 1, 1),
  ('scorched_mines',       'legs_chain_leggings',    5.0, 1, 1),
  ('scorched_mines',       'boot_windwalkers',       6.0, 1, 1),
  ('scorched_mines',       'acc_magic_orb',          5.0, 1, 1),
  ('scorched_mines',       'belt_titan',             5.0, 1, 1),
  ('scorched_mines',       'ring_blood_ruby',        5.0, 1, 1),
  ('scorched_mines',       'neck_dragon_tooth',      5.0, 1, 1),
  ('scorched_mines',       'relic_skull',            4.0, 1, 1),
  ('scorched_mines',       'health_potion_medium',  10.0, 1, 2),
  ('scorched_mines',       'stamina_potion_medium',  8.0, 1, 1),

  -- ── Frozen Abyss (lvl 40) — rare + epic teasers ────────────────
  ('frozen_abyss',         'wpn_frostbite_staff',    8.0, 1, 1),
  ('frozen_abyss',         'wpn_flamebrand',         5.0, 1, 1),
  ('frozen_abyss',         'wpn_stormbringer',       2.0, 1, 1),
  ('frozen_abyss',         'helm_dragon_visage',     6.0, 1, 1),
  ('frozen_abyss',         'helm_crown_of_thorns',   2.0, 1, 1),
  ('frozen_abyss',         'chest_plate_armor',      6.0, 1, 1),
  ('frozen_abyss',         'chest_titan_cuirass',    2.0, 1, 1),
  ('frozen_abyss',         'glove_assassin',         6.0, 1, 1),
  ('frozen_abyss',         'glove_berserker',        2.0, 1, 1),
  ('frozen_abyss',         'legs_shadow_pants',      6.0, 1, 1),
  ('frozen_abyss',         'boot_windwalkers',       6.0, 1, 1),
  ('frozen_abyss',         'acc_magic_orb',          5.0, 1, 1),
  ('frozen_abyss',         'belt_titan',             5.0, 1, 1),
  ('frozen_abyss',         'ring_blood_ruby',        5.0, 1, 1),
  ('frozen_abyss',         'neck_dragon_tooth',      5.0, 1, 1),
  ('frozen_abyss',         'relic_skull',            4.0, 1, 1),
  ('frozen_abyss',         'health_potion_medium',  10.0, 1, 2),
  ('frozen_abyss',         'health_potion_large',    4.0, 1, 1),

  -- ── Realm of Light (lvl 45) — rare + epic ──────────────────────
  ('realm_of_light',       'wpn_stormbringer',       3.0, 1, 1),
  ('realm_of_light',       'wpn_void_scepter',       3.0, 1, 1),
  ('realm_of_light',       'wpn_flamebrand',         5.0, 1, 1),
  ('realm_of_light',       'wpn_frostbite_staff',    5.0, 1, 1),
  ('realm_of_light',       'helm_crown_of_thorns',   3.0, 1, 1),
  ('realm_of_light',       'helm_dragon_visage',     5.0, 1, 1),
  ('realm_of_light',       'chest_titan_cuirass',    3.0, 1, 1),
  ('realm_of_light',       'chest_plate_armor',      5.0, 1, 1),
  ('realm_of_light',       'glove_berserker',        3.0, 1, 1),
  ('realm_of_light',       'glove_assassin',         5.0, 1, 1),
  ('realm_of_light',       'legs_titan_greaves',     3.0, 1, 1),
  ('realm_of_light',       'boot_titan_stompers',    3.0, 1, 1),
  ('realm_of_light',       'amu_phoenix_heart',      2.0, 1, 1),
  ('realm_of_light',       'ring_void',              3.0, 1, 1),
  ('realm_of_light',       'belt_titan',             5.0, 1, 1),
  ('realm_of_light',       'relic_skull',            4.0, 1, 1),
  ('realm_of_light',       'health_potion_large',    6.0, 1, 1),
  ('realm_of_light',       'stamina_potion_large',   4.0, 1, 1),

  -- ── Shadow Realm (lvl 50) — epic focused ───────────────────────
  ('shadow_realm',         'wpn_stormbringer',       4.0, 1, 1),
  ('shadow_realm',         'wpn_void_scepter',       4.0, 1, 1),
  ('shadow_realm',         'wpn_venom_fang',         5.0, 1, 1),
  ('shadow_realm',         'helm_crown_of_thorns',   4.0, 1, 1),
  ('shadow_realm',         'chest_titan_cuirass',    4.0, 1, 1),
  ('shadow_realm',         'chest_shadow_vest',      5.0, 1, 1),
  ('shadow_realm',         'glove_berserker',        4.0, 1, 1),
  ('shadow_realm',         'legs_titan_greaves',     4.0, 1, 1),
  ('shadow_realm',         'legs_shadow_pants',      5.0, 1, 1),
  ('shadow_realm',         'boot_titan_stompers',    4.0, 1, 1),
  ('shadow_realm',         'boot_windwalkers',       5.0, 1, 1),
  ('shadow_realm',         'amu_phoenix_heart',      3.0, 1, 1),
  ('shadow_realm',         'ring_void',              4.0, 1, 1),
  ('shadow_realm',         'ring_blood_ruby',        5.0, 1, 1),
  ('shadow_realm',         'neck_dragon_tooth',      5.0, 1, 1),
  ('shadow_realm',         'relic_skull',            5.0, 1, 1),
  ('shadow_realm',         'health_potion_large',    8.0, 1, 1),
  ('shadow_realm',         'stamina_potion_large',   5.0, 1, 1),

  -- ── Clockwork Citadel (lvl 55) — epic focused ─────────────────
  ('clockwork_citadel',    'wpn_stormbringer',       5.0, 1, 1),
  ('clockwork_citadel',    'wpn_void_scepter',       5.0, 1, 1),
  ('clockwork_citadel',    'wpn_excalibur',          1.0, 1, 1),
  ('clockwork_citadel',    'helm_crown_of_thorns',   5.0, 1, 1),
  ('clockwork_citadel',    'chest_titan_cuirass',    5.0, 1, 1),
  ('clockwork_citadel',    'glove_berserker',        5.0, 1, 1),
  ('clockwork_citadel',    'legs_titan_greaves',     5.0, 1, 1),
  ('clockwork_citadel',    'boot_titan_stompers',    5.0, 1, 1),
  ('clockwork_citadel',    'amu_phoenix_heart',      3.0, 1, 1),
  ('clockwork_citadel',    'ring_void',              5.0, 1, 1),
  ('clockwork_citadel',    'belt_titan',             6.0, 1, 1),
  ('clockwork_citadel',    'neck_dragon_tooth',      5.0, 1, 1),
  ('clockwork_citadel',    'relic_skull',            5.0, 1, 1),
  ('clockwork_citadel',    'relic_orb_of_ages',      1.0, 1, 1),
  ('clockwork_citadel',    'health_potion_large',    8.0, 1, 1),
  ('clockwork_citadel',    'stamina_potion_large',   6.0, 1, 1),

  -- ── Abyssal Depths (lvl 60) — epic + legendary teasers ─────────
  ('abyssal_depths',       'wpn_stormbringer',       5.0, 1, 1),
  ('abyssal_depths',       'wpn_void_scepter',       5.0, 1, 1),
  ('abyssal_depths',       'wpn_excalibur',          2.0, 1, 1),
  ('abyssal_depths',       'helm_crown_of_thorns',   5.0, 1, 1),
  ('abyssal_depths',       'chest_titan_cuirass',    5.0, 1, 1),
  ('abyssal_depths',       'glove_berserker',        5.0, 1, 1),
  ('abyssal_depths',       'legs_titan_greaves',     5.0, 1, 1),
  ('abyssal_depths',       'boot_titan_stompers',    5.0, 1, 1),
  ('abyssal_depths',       'amu_phoenix_heart',      4.0, 1, 1),
  ('abyssal_depths',       'ring_void',              5.0, 1, 1),
  ('abyssal_depths',       'belt_titan',             6.0, 1, 1),
  ('abyssal_depths',       'neck_dragon_tooth',      6.0, 1, 1),
  ('abyssal_depths',       'relic_orb_of_ages',      2.0, 1, 1),
  ('abyssal_depths',       'relic_skull',            5.0, 1, 1),
  ('abyssal_depths',       'health_potion_large',   10.0, 1, 2),
  ('abyssal_depths',       'stamina_potion_large',   6.0, 1, 1),

  -- ── Infernal Throne (lvl 65) — best loot in the game ──────────
  ('infernal_throne',      'wpn_excalibur',          3.0, 1, 1),
  ('infernal_throne',      'wpn_stormbringer',       6.0, 1, 1),
  ('infernal_throne',      'wpn_void_scepter',       6.0, 1, 1),
  ('infernal_throne',      'helm_crown_of_thorns',   6.0, 1, 1),
  ('infernal_throne',      'chest_titan_cuirass',    6.0, 1, 1),
  ('infernal_throne',      'glove_berserker',        6.0, 1, 1),
  ('infernal_throne',      'legs_titan_greaves',     6.0, 1, 1),
  ('infernal_throne',      'boot_titan_stompers',    6.0, 1, 1),
  ('infernal_throne',      'amu_phoenix_heart',      5.0, 1, 1),
  ('infernal_throne',      'ring_void',              6.0, 1, 1),
  ('infernal_throne',      'belt_titan',             6.0, 1, 1),
  ('infernal_throne',      'neck_dragon_tooth',      6.0, 1, 1),
  ('infernal_throne',      'relic_orb_of_ages',      3.0, 1, 1),
  ('infernal_throne',      'relic_skull',            6.0, 1, 1),
  ('infernal_throne',      'health_potion_large',   12.0, 1, 2),
  ('infernal_throne',      'stamina_potion_large',   8.0, 1, 1)
) AS v(dungeon_slug, catalog_id, drop_chance, min_qty, max_qty)
JOIN "items" i ON i."catalog_id" = v.catalog_id
WHERE d."slug" = v.dungeon_slug
  AND NOT EXISTS (
    SELECT 1 FROM "dungeon_drops" dd
    WHERE dd."dungeon_id" = d."id"
      AND dd."item_id"    = i."id"
  );
