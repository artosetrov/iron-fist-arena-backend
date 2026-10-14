-- =============================================================================
-- 20261014_items_tier6_class_loot
--
-- Two content gaps from the 2026-10-14 balance audit:
--
-- 1. The item catalog stopped at itemLevel 40 against a level cap of 50, so
--    the last ten levels (a third of the ×3 XP curve in wall-clock) had no
--    gear to chase. Adds Tier 6 "Ascendant" (19 legendary items, L42–50):
--    one L44 and one L50 weapon per class, a universal armor set, accessories.
--    Art borrows a legendary sibling's PNG on purpose (image_key/image_url),
--    so the client renders real art rather than a placeholder.
--
-- 2. class_restriction was NULL on all 106 items, so the loot relevance
--    filter (loot.ts CLASS_COMPAT) and the shop's class filter never did
--    anything — a mage dropped greatswords. Sets class_restriction on every
--    weapon by its stat profile: str/agi blades → warrior, maces/hammers →
--    tank, agi/luk blades and bows → rogue, int staves → mage. Armor and
--    accessories stay universal. warrior ↔ tank share weapons through
--    CLASS_COMPAT (equip + shop now honour the same matrix as loot).
--    The tutorial sword (wpn_iron_sword_tutorial) stays universal.
--
-- Idempotent: inserts skip existing catalog_ids; the UPDATE only touches
-- rows whose class_restriction is still NULL. Run against prod via
-- Supabase MCP BEFORE deploying the backend (the seed mirrors this list).
-- =============================================================================

INSERT INTO "items"
  ("id", "catalog_id", "item_name", "item_type", "rarity", "item_level", "base_stats", "special_effect",
   "class_restriction", "set_name", "buy_price", "sell_price", "description", "drop_chance", "image_key", "image_url", "updated_at")
VALUES
  (gen_random_uuid(), 'wpn_dawnbreaker', 'Dawnbreaker', 'weapon', 'legendary', 44, '{"str":54,"agi":24,"vit":14,"luk":10}'::jsonb, '+25% all damage, +15% crit, +10% armor pen', 'warrior', NULL, 25000, 6250, 'Forged in the first light after the long night. It does not dull.', 0.1, 'wpn_soulreaver', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/wpn_soulreaver.png', NOW()),
  (gen_random_uuid(), 'wpn_colossus_maul', 'Colossus Maul', 'weapon', 'legendary', 44, '{"str":46,"vit":28,"end":18,"luk":6}'::jsonb, '+20% all damage, +15% max HP', 'tank', NULL, 25000, 6250, 'Too heavy for anyone who has not spent a lifetime holding a line.', 0.1, 'wpn_worldbreaker', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/wpn_worldbreaker.png', NOW()),
  (gen_random_uuid(), 'wpn_eclipse_fangs', 'Eclipse Fangs', 'weapon', 'legendary', 44, '{"agi":52,"luk":26,"str":12,"vit":8}'::jsonb, '+25% crit, +15% crit damage, +10% dodge', 'rogue', NULL, 25000, 6250, 'Twin blades that bite between heartbeats.', 0.1, 'wpn_soulreaver', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/wpn_soulreaver.png', NOW()),
  (gen_random_uuid(), 'wpn_starfall_codex', 'Starfall Codex', 'weapon', 'legendary', 44, '{"int":54,"wis":28,"luk":14,"cha":8}'::jsonb, '+30% spell power, +15% crit', 'mage', NULL, 25000, 6250, 'Every page is a sky that has already fallen.', 0.1, 'wpn_astral_codex', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/wpn_astral_codex.png', NOW()),
  (gen_random_uuid(), 'wpn_ascendant_blade', 'Ascendant Blade', 'weapon', 'legendary', 50, '{"str":62,"agi":26,"vit":16,"luk":12}'::jsonb, '+30% all damage, +20% crit, +15% armor pen', 'warrior', NULL, 32000, 8000, 'Carried by the last fighter to leave the arena standing.', 0.08, 'wpn_soulreaver', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/wpn_soulreaver.png', NOW()),
  (gen_random_uuid(), 'wpn_ascendant_bulwark', 'Ascendant Bulwark', 'weapon', 'legendary', 50, '{"str":52,"vit":32,"end":22,"luk":8}'::jsonb, '+25% all damage, +20% max HP, +10% all resist', 'tank', NULL, 32000, 8000, 'Half hammer, half wall. Both halves win.', 0.08, 'wpn_worldbreaker', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/wpn_worldbreaker.png', NOW()),
  (gen_random_uuid(), 'wpn_ascendant_edge', 'Ascendant Edge', 'weapon', 'legendary', 50, '{"agi":60,"luk":28,"str":14,"vit":10}'::jsonb, '+30% crit, +20% crit damage, +10% lifesteal', 'rogue', NULL, 32000, 8000, 'You will not see it. That is the point.', 0.08, 'wpn_soulreaver', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/wpn_soulreaver.png', NOW()),
  (gen_random_uuid(), 'wpn_ascendant_staff', 'Ascendant Staff', 'weapon', 'legendary', 50, '{"int":62,"wis":30,"luk":16,"cha":10}'::jsonb, '+35% spell power, +20% crit, +15% mana regen', 'mage', NULL, 32000, 8000, 'The staff remembers every spell ever cast through it.', 0.08, 'wpn_astral_codex', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/wpn_astral_codex.png', NOW()),
  (gen_random_uuid(), 'helm_ascendant_crown', 'Ascendant Crown', 'helmet', 'legendary', 42, '{"vit":32,"str":16,"end":14,"int":10}'::jsonb, '+15% all resist, +12% max HP', NULL, NULL, 20000, 5000, 'Worn by those who stopped asking permission.', 0.1, 'helm_abyssal_crown', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/helm_abyssal_crown.png', NOW()),
  (gen_random_uuid(), 'glove_ascendant_grips', 'Ascendant Grips', 'gloves', 'legendary', 42, '{"str":24,"agi":18,"luk":12,"vit":10}'::jsonb, '+15% crit damage, +10% attack speed', NULL, NULL, 20000, 5000, 'They do not let go.', 0.1, 'glove_demongrasps', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/glove_demongrasps.png', NOW()),
  (gen_random_uuid(), 'boot_ascendant_treads', 'Ascendant Treads', 'boots', 'legendary', 43, '{"agi":26,"vit":14,"luk":12,"end":10}'::jsonb, '+15% dodge, +10% movement', NULL, NULL, 21000, 5250, 'Every step lands where the ground is strongest.', 0.1, 'boot_eternaltread', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/boot_eternaltread.png', NOW()),
  (gen_random_uuid(), 'legs_ascendant_greaves', 'Ascendant Greaves', 'legs', 'legendary', 45, '{"vit":30,"agi":18,"end":14,"luk":10}'::jsonb, '+15% dodge, +10% max HP', NULL, NULL, 24000, 6000, 'Plated for the climb, not the parade.', 0.1, 'legs_voidwalker', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/legs_voidwalker.png', NOW()),
  (gen_random_uuid(), 'chest_ascendant_plate', 'Ascendant Plate', 'chest', 'legendary', 46, '{"vit":42,"end":24,"str":14,"agi":10}'::jsonb, '+20% max HP, +15% all resist', NULL, NULL, 26000, 6500, 'Dented in a hundred places. Pierced in none.', 0.1, 'chest_godplate', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/chest_godplate.png', NOW()),
  (gen_random_uuid(), 'belt_titanbind', 'Titanbind', 'belt', 'legendary', 44, '{"end":24,"vit":18,"str":12,"agi":10}'::jsonb, '+15% max stamina, +12% all resist', NULL, NULL, 22000, 5500, 'Cut from a chain that once held something much larger.', 0.1, 'belt_worldserpent', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/belt_worldserpent.png', NOW()),
  (gen_random_uuid(), 'neck_starbound_chain', 'Starbound Chain', 'necklace', 'legendary', 46, '{"wis":22,"int":14,"vit":12,"cha":10}'::jsonb, '+15% magic resist, +12% HP regen', NULL, NULL, 25000, 6250, 'Each link is a night you did not give up.', 0.1, 'neck_soulbinder', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/neck_soulbinder.png', NOW()),
  (gen_random_uuid(), 'acc_aegis_of_dawn', 'Aegis of Dawn', 'accessory', 'legendary', 48, '{"vit":24,"end":22,"wis":12,"str":10}'::jsonb, '25% reflect physical damage', NULL, NULL, 28000, 7000, 'It has never been raised in vain.', 0.08, 'acc_mirror_shield', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/acc_mirror_shield.png', NOW()),
  (gen_random_uuid(), 'amu_eye_of_the_ascendant', 'Eye of the Ascendant', 'amulet', 'legendary', 48, '{"vit":22,"wis":18,"cha":14,"luk":12}'::jsonb, 'Revive with 60% HP once per battle', NULL, NULL, 28000, 7000, 'It has seen the end of the climb. It is not impressed.', 0.08, 'amu_heart_of_eternity', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/amu_heart_of_eternity.png', NOW()),
  (gen_random_uuid(), 'ring_singularity', 'Ring of Singularity', 'ring', 'legendary', 48, '{"int":22,"luk":18,"agi":12,"wis":10}'::jsonb, '+25% magic pen, +15% crit', NULL, NULL, 27000, 6750, 'Everything bends toward it, eventually.', 0.08, 'ring_oblivion', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/ring_oblivion.png', NOW()),
  (gen_random_uuid(), 'relic_heart_of_the_void', 'Heart of the Void', 'relic', 'legendary', 50, '{"int":24,"wis":22,"luk":15,"cha":12}'::jsonb, '+25% all magic, +15% XP, +12% crit', NULL, NULL, 32000, 8000, 'Still beating. Nobody knows for whom.', 0.08, 'relic_crown_of_ashes', 'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/items/relic_crown_of_ashes.png', NOW())
ON CONFLICT ("catalog_id") DO NOTHING;

UPDATE "items" SET "class_restriction" = v.cls, "updated_at" = NOW()
FROM (VALUES
  ('wpn_rusty_sword', 'warrior'), ('wpn_steel_longsword', 'warrior'), ('wpn_flamebrand', 'warrior'),
  ('wpn_stormbringer', 'warrior'), ('wpn_hellfire_blade', 'warrior'), ('wpn_serrated_cleaver', 'warrior'),
  ('wpn_excalibur', 'warrior'), ('wpn_worldbreaker', 'warrior'), ('wpn_soulreaver', 'warrior'),
  ('wpn_training_mace', 'tank'), ('wpn_war_hammer', 'tank'), ('wpn_bonecleaver', 'tank'),
  ('wpn_iron_dagger', 'rogue'), ('wpn_shadow_knife', 'rogue'), ('wpn_venom_fang', 'rogue'), ('wpn_fey_bow', 'rogue'),
  ('wpn_wooden_staff', 'mage'), ('wpn_arcane_wand', 'mage'), ('wpn_frostbite_staff', 'mage'), ('wpn_void_scepter', 'mage'),
  ('wpn_nightmare_staff', 'mage'), ('wpn_crystalcore_staff', 'mage'), ('wpn_astral_codex', 'mage')
) AS v(catalog_id, cls)
WHERE "items"."catalog_id" = v.catalog_id
  AND "items"."class_restriction" IS NULL;
