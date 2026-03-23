-- =============================================================================
-- Migration: Catalog-based drop system
-- 1. Set dropChance on existing catalog items (enables them as loot drops)
-- 2. Insert new mid/high-level items for levels 15-50
-- 3. Index for efficient catalog lookups
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Update dropChance on existing catalog items
-- ─────────────────────────────────────────────────────────────────────────────

-- Common items: weight 1.0
UPDATE items SET drop_chance = 1.0
WHERE catalog_id IN (
  'wpn_rusty_sword', 'wpn_wooden_staff', 'wpn_iron_dagger', 'wpn_training_mace',
  'helm_leather_cap', 'chest_cloth_robe', 'glove_cloth_wraps', 'legs_cloth_pants',
  'boot_sandals', 'acc_wooden_shield', 'amu_copper_chain', 'belt_rope',
  'ring_copper', 'neck_bone_charm'
);

-- Uncommon items: weight 1.0
UPDATE items SET drop_chance = 1.0
WHERE catalog_id IN (
  'wpn_steel_longsword', 'wpn_arcane_wand', 'wpn_shadow_knife', 'wpn_war_hammer',
  'helm_iron_helm', 'helm_mystic_hood', 'chest_chain_mail', 'chest_mage_robe',
  'glove_iron_gauntlets', 'legs_chain_leggings', 'boot_iron_treads',
  'acc_iron_shield', 'amu_silver_pendant', 'belt_leather', 'ring_silver',
  'neck_emerald', 'relic_old_coin'
);

-- Rare items: weight 1.0
UPDATE items SET drop_chance = 1.0
WHERE catalog_id IN (
  'wpn_flamebrand', 'wpn_frostbite_staff', 'wpn_venom_fang',
  'helm_dragon_visage', 'chest_plate_armor', 'chest_shadow_vest',
  'glove_assassin', 'legs_shadow_pants', 'boot_windwalkers',
  'acc_magic_orb', 'belt_titan', 'ring_blood_ruby', 'neck_dragon_tooth',
  'relic_skull'
);

-- Epic items: weight 0.8
UPDATE items SET drop_chance = 0.8
WHERE catalog_id IN (
  'wpn_stormbringer', 'wpn_void_scepter',
  'helm_crown_of_thorns', 'chest_titan_cuirass',
  'glove_berserker', 'legs_titan_greaves', 'boot_titan_stompers',
  'ring_void'
);

-- Phoenix Heart: lower weight (revive is very strong)
UPDATE items SET drop_chance = 0.5 WHERE catalog_id = 'amu_phoenix_heart';

-- Legendary items: weight 0.3
UPDATE items SET drop_chance = 0.3
WHERE catalog_id IN ('wpn_excalibur', 'relic_orb_of_ages');

-- Consumables stay at 0 (shop-only)

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Insert new Tier 3+ items (levels 15-50)
-- ─────────────────────────────────────────────────────────────────────────────

-- Epic Tier 3 (lvl 15-18)
INSERT INTO items (id, catalog_id, item_name, item_type, rarity, item_level, buy_price, sell_price, base_stats, description, special_effect, drop_chance)
VALUES
  (gen_random_uuid(), 'wpn_bonecleaver', 'Bonecleaver', 'weapon', 'epic', 15, 3200, 800, '{"str":20,"agi":10,"vit":5}', 'Cleaves through bone and steel alike.', '+12% armor penetration', 0.7),
  (gen_random_uuid(), 'wpn_nightmare_staff', 'Nightmare Staff', 'weapon', 'epic', 18, 3800, 950, '{"int":22,"wis":12,"luk":6}', 'Channels the terrors of the dreaming.', '+12% fear chance', 0.6),
  (gen_random_uuid(), 'helm_dread_visor', 'Dread Visor', 'helmet', 'epic', 16, 3000, 750, '{"vit":16,"end":8,"str":6}', 'Inspires fear in all who see it.', '+8% intimidation', 0.7),
  (gen_random_uuid(), 'chest_bloodweave', 'Bloodweave Armor', 'chest', 'epic', 16, 3400, 850, '{"vit":18,"str":8,"agi":6}', 'Woven from the sinew of fell beasts.', '+5% lifesteal', 0.7),
  (gen_random_uuid(), 'glove_plaguegrip', 'Plaguegrip Gloves', 'gloves', 'epic', 15, 2800, 700, '{"agi":12,"luk":6,"int":4}', 'Drip with venomous ichor.', '+8% poison damage', 0.7),
  (gen_random_uuid(), 'legs_nightstalker', 'Nightstalker Leggings', 'legs', 'epic', 15, 2800, 700, '{"agi":14,"luk":6,"vit":5}', 'Bend light around the wearer.', '+8% dodge', 0.7),
  (gen_random_uuid(), 'boot_wraithstep', 'Wraithstep Boots', 'boots', 'epic', 16, 2900, 725, '{"agi":14,"luk":5,"vit":4}', 'Leave no footprints.', '+10% evasion', 0.7),
  (gen_random_uuid(), 'acc_aegis', 'Aegis Shield', 'accessory', 'epic', 12, 2400, 600, '{"vit":10,"end":8,"str":4}', 'Legendary shield of protection.', '+10% block chance', 0.8),
  (gen_random_uuid(), 'amu_soulchain', 'Soulchain Pendant', 'amulet', 'epic', 15, 3000, 750, '{"int":10,"wis":8,"cha":5}', 'Binds wandering spirits.', '+10% magic resist', 0.7),
  (gen_random_uuid(), 'belt_warbrand', 'Warbrand Belt', 'belt', 'epic', 12, 2200, 550, '{"end":10,"str":6,"vit":4}', 'Forged in the fires of war.', '+8% max stamina', 0.8),
  (gen_random_uuid(), 'ring_shadowfang', 'Shadowfang Ring', 'ring', 'epic', 15, 2800, 700, '{"agi":10,"luk":8,"str":4}', 'Cut from the fang of a shadow wolf.', '+8% crit damage', 0.7),
  (gen_random_uuid(), 'neck_dreadstone', 'Dreadstone Collar', 'necklace', 'epic', 12, 2500, 625, '{"vit":8,"wis":6,"end":5}', 'Cold to the touch.', '+8% frost resist', 0.8),
  (gen_random_uuid(), 'relic_warhorn', 'Warhorn of the Fallen', 'relic', 'epic', 12, 2600, 650, '{"str":8,"cha":6,"end":5}', 'Echoes with battle cries of the dead.', '+10% team morale', 0.8)
ON CONFLICT (catalog_id) DO NOTHING;

-- Tier 4: High epic (lvl 20-22)
INSERT INTO items (id, catalog_id, item_name, item_type, rarity, item_level, buy_price, sell_price, base_stats, description, special_effect, drop_chance)
VALUES
  (gen_random_uuid(), 'wpn_hellfire_blade', 'Hellfire Blade', 'weapon', 'epic', 22, 4500, 1125, '{"str":28,"agi":12,"luk":6}', 'Forged in abyssal flames.', '+15% fire damage', 0.6),
  (gen_random_uuid(), 'wpn_crystalcore_staff', 'Crystalcore Staff', 'weapon', 'epic', 22, 4500, 1125, '{"int":28,"wis":14,"luk":5}', 'A shard of pure mana crystallised.', '+15% spell power', 0.6),
  (gen_random_uuid(), 'wpn_serrated_cleaver', 'Serrated Cleaver', 'weapon', 'rare', 20, 2200, 550, '{"str":16,"agi":8}', 'Its teeth never dull.', '+8% bleed chance', 1.0),
  (gen_random_uuid(), 'wpn_fey_bow', 'Feywisp Bow', 'weapon', 'rare', 20, 2200, 550, '{"agi":14,"luk":8,"int":4}', 'Guided by woodland spirits.', '+8% accuracy', 1.0),
  (gen_random_uuid(), 'helm_warskull', 'Warskull Helm', 'helmet', 'epic', 22, 4000, 1000, '{"vit":20,"str":10,"end":8}', 'Skull of a defeated champion.', '+12% damage when HP < 50%', 0.6),
  (gen_random_uuid(), 'helm_moonveil', 'Moonveil Hood', 'helmet', 'rare', 20, 2000, 500, '{"int":10,"wis":8,"vit":4}', 'Woven from moonlight.', '+6% magic resist', 1.0),
  (gen_random_uuid(), 'chest_dragonhide', 'Dragonhide Cuirass', 'chest', 'epic', 22, 4800, 1200, '{"vit":22,"end":12,"str":8}', 'Scales of an elder dragon.', '+12% all resist', 0.6),
  (gen_random_uuid(), 'chest_spiritweave', 'Spiritweave Robe', 'chest', 'rare', 20, 2400, 600, '{"int":12,"wis":10,"vit":5}', 'Ghosts woven into silk.', '+8% spell crit', 1.0),
  (gen_random_uuid(), 'glove_irongrip', 'Irongrip Gauntlets', 'gloves', 'epic', 22, 3600, 900, '{"str":16,"agi":8,"end":6}', 'Grip that never fails.', '+10% disarm resist', 0.6),
  (gen_random_uuid(), 'legs_boneguard', 'Boneguard Greaves', 'legs', 'epic', 22, 3800, 950, '{"vit":18,"end":10,"str":6}', 'Reinforced with monster bone.', '+10% stun resist', 0.6),
  (gen_random_uuid(), 'boot_stormstriders', 'Stormstrider Boots', 'boots', 'epic', 22, 3600, 900, '{"agi":18,"luk":8,"vit":5}', 'Ride the lightning.', '+12% movement speed', 0.6),
  (gen_random_uuid(), 'belt_wyrmskin', 'Wyrmskin Belt', 'belt', 'epic', 22, 3400, 850, '{"end":14,"vit":8,"str":5}', 'Scaled girdle of protection.', '+10% max stamina', 0.6),
  (gen_random_uuid(), 'ring_eclipse', 'Eclipse Band', 'ring', 'epic', 22, 3600, 900, '{"int":12,"luk":10,"wis":6}', 'Darkens the light around it.', '+12% shadow damage', 0.6),
  (gen_random_uuid(), 'neck_bloodstone', 'Bloodstone Pendant', 'necklace', 'epic', 22, 3600, 900, '{"str":10,"vit":8,"luk":6}', 'Pulses with stolen vitality.', '+5% lifesteal', 0.6),
  (gen_random_uuid(), 'amu_doomward', 'Doomward Amulet', 'amulet', 'epic', 22, 3600, 900, '{"vit":10,"wis":8,"cha":6}', 'Wards against instant death.', 'Survive lethal hit once (1 HP)', 0.5),
  (gen_random_uuid(), 'relic_demon_eye', 'Demon Eye', 'relic', 'epic', 22, 3800, 950, '{"int":12,"luk":8,"wis":5}', 'Sees through all deception.', '+10% crit chance', 0.6),
  (gen_random_uuid(), 'acc_tower_shield', 'Obsidian Tower Shield', 'accessory', 'epic', 22, 4000, 1000, '{"vit":14,"end":12,"str":6}', 'An immovable wall of volcanic glass.', '+15% block chance', 0.6)
ON CONFLICT (catalog_id) DO NOTHING;

-- Tier 5: Legendary (lvl 30-40)
INSERT INTO items (id, catalog_id, item_name, item_type, rarity, item_level, buy_price, sell_price, base_stats, description, special_effect, drop_chance)
VALUES
  (gen_random_uuid(), 'wpn_worldbreaker', 'Worldbreaker', 'weapon', 'legendary', 30, 15000, 3750, '{"str":40,"agi":18,"vit":12,"luk":8}', 'Shatters the fabric of reality.', '+25% all damage, +15% armor pen', 0.2),
  (gen_random_uuid(), 'wpn_soulreaver', 'Soulreaver', 'weapon', 'legendary', 40, 22000, 5500, '{"str":50,"agi":22,"luk":15,"vit":10}', 'Consumes the essence of the fallen.', '+8% lifesteal, +20% crit', 0.1),
  (gen_random_uuid(), 'wpn_astral_codex', 'Astral Codex', 'weapon', 'legendary', 35, 18000, 4500, '{"int":45,"wis":25,"luk":12,"cha":8}', 'Written by the gods themselves.', '+25% spell power, +15% mana regen', 0.15),
  (gen_random_uuid(), 'helm_abyssal_crown', 'Abyssal Crown', 'helmet', 'legendary', 30, 12000, 3000, '{"vit":28,"str":14,"end":12,"int":8}', 'Crown of the abyss lords.', '+15% all resist, +10% max HP', 0.2),
  (gen_random_uuid(), 'chest_godplate', 'Godplate Armor', 'chest', 'legendary', 35, 18000, 4500, '{"vit":35,"end":20,"str":12,"agi":8}', 'Worn by the divine sentinels.', '+20% max HP, +15% all resist', 0.15),
  (gen_random_uuid(), 'glove_demongrasps', 'Demongrasps', 'gloves', 'legendary', 30, 12000, 3000, '{"str":20,"agi":15,"luk":10,"vit":8}', 'Hands of a demon lord.', '+15% crit damage, +10% attack speed', 0.2),
  (gen_random_uuid(), 'legs_voidwalker', 'Voidwalker Greaves', 'legs', 'legendary', 32, 14000, 3500, '{"vit":25,"agi":15,"end":12,"luk":8}', 'Walk between dimensions.', '+15% dodge, +10% movement speed', 0.2),
  (gen_random_uuid(), 'boot_eternaltread', 'Eternal Treads', 'boots', 'legendary', 30, 12000, 3000, '{"agi":22,"vit":12,"luk":10,"end":8}', 'Have walked since the dawn of time.', '+15% movement, +10% dodge', 0.2),
  (gen_random_uuid(), 'acc_mirror_shield', 'Mirror Shield', 'accessory', 'legendary', 35, 16000, 4000, '{"vit":20,"end":18,"wis":10,"str":8}', 'Reflects spells back at casters.', '25% reflect magic damage', 0.15),
  (gen_random_uuid(), 'amu_heart_of_eternity', 'Heart of Eternity', 'amulet', 'legendary', 35, 16000, 4000, '{"vit":18,"wis":15,"cha":12,"luk":10}', 'Beats with the pulse of forever.', 'Revive with 50% HP once per battle', 0.15),
  (gen_random_uuid(), 'belt_worldserpent', 'Worldserpent Belt', 'belt', 'legendary', 30, 12000, 3000, '{"end":20,"vit":15,"str":10,"agi":8}', 'Coiled from the world serpent''s scale.', '+15% max stamina, +10% all resist', 0.2),
  (gen_random_uuid(), 'ring_oblivion', 'Ring of Oblivion', 'ring', 'legendary', 35, 15000, 3750, '{"int":18,"luk":15,"agi":10,"wis":8}', 'Erases existence itself.', '+20% magic pen, +15% crit', 0.15),
  (gen_random_uuid(), 'neck_soulbinder', 'Soulbinder Chain', 'necklace', 'legendary', 32, 14000, 3500, '{"wis":18,"int":12,"vit":10,"cha":8}', 'Chains that bind the spirit world.', '+15% magic resist, +10% HP regen', 0.2),
  (gen_random_uuid(), 'relic_crown_of_ashes', 'Crown of Ashes', 'relic', 'legendary', 40, 20000, 5000, '{"int":20,"wis":18,"luk":12,"cha":10}', 'Remains of a burnt god.', '+20% all magic, +15% XP, +10% crit', 0.1)
ON CONFLICT (catalog_id) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Add index for catalog item lookups by drop system
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_items_drop_lookup
  ON items (rarity, item_type, item_level, drop_chance)
  WHERE drop_chance > 0;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Clean up orphaned procedural loot items
--    Only deletes loot_* Items that have NO linked EquipmentInventory.
--    Items still in someone's inventory are preserved (they just won't be
--    generated again going forward).
-- ─────────────────────────────────────────────────────────────────────────────
DELETE FROM items
WHERE catalog_id LIKE 'loot_%'
  AND id NOT IN (SELECT DISTINCT item_id FROM equipment_inventory);
