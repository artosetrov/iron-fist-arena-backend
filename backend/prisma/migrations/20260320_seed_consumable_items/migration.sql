-- Seed consumable potions and gem packs into the items table.
-- These were previously hardcoded in the shop/items API route.
-- Now they live in the DB so admin can manage images, prices, and descriptions.

INSERT INTO items (id, catalog_id, item_name, item_type, rarity, item_level, buy_price, sell_price, description, base_stats)
VALUES
  -- Stamina potions
  (gen_random_uuid(), 'stamina_potion_small',  'Small Stamina Potion',  'consumable', 'common',   1, 100,  0, 'Restores 30 stamina.',      '{}'),
  (gen_random_uuid(), 'stamina_potion_medium', 'Medium Stamina Potion', 'consumable', 'uncommon', 1, 250,  0, 'Restores 60 stamina.',      '{}'),
  (gen_random_uuid(), 'stamina_potion_large',  'Large Stamina Potion',  'consumable', 'rare',     1, 500,  0, 'Fully restores stamina.',   '{}'),
  -- Health potions
  (gen_random_uuid(), 'health_potion_small',   'Small Health Potion',   'consumable', 'common',   1, 150,  0, 'Restores 25% of max HP.',   '{}'),
  (gen_random_uuid(), 'health_potion_medium',  'Medium Health Potion',  'consumable', 'uncommon', 1, 350,  0, 'Restores 50% of max HP.',   '{}'),
  (gen_random_uuid(), 'health_potion_large',   'Large Health Potion',   'consumable', 'rare',     1, 700,  0, 'Fully restores HP.',        '{}'),
  -- Gem packs
  (gen_random_uuid(), 'gem_pack_small',        'Small Gem Pouch',       'consumable', 'uncommon', 1, 150,  0, 'Contains 10 gems.',         '{}'),
  (gen_random_uuid(), 'gem_pack_medium',       'Medium Gem Pouch',      'consumable', 'rare',     1, 750,  0, 'Contains 50 gems.',         '{}'),
  (gen_random_uuid(), 'gem_pack_large',        'Large Gem Pouch',       'consumable', 'epic',     1, 1500, 0, 'Contains 100 gems.',        '{}')
ON CONFLICT (catalog_id) DO UPDATE SET
  item_name   = EXCLUDED.item_name,
  rarity      = EXCLUDED.rarity,
  buy_price   = EXCLUDED.buy_price,
  description = EXCLUDED.description;
