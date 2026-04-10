-- Bug #12: stale `special_effect` values on consumable rows contradicted the
-- newer `description` copy (e.g. "+50 stamina" vs "Restores 60 stamina.").
-- Rebalance happened in seed.ts/20260320_seed_consumable_items but neither
-- touched `special_effect`, so it kept the pre-rebalance numbers.
--
-- Reconcile by scrubbing `special_effect` to match the current numbers and
-- description text. The iOS client also hides this field for consumables
-- now, but we fix the data so admin panel and any future consumers are
-- consistent.

UPDATE items
   SET special_effect = '+30 stamina'
 WHERE catalog_id = 'stamina_potion_small';

UPDATE items
   SET special_effect = '+60 stamina'
 WHERE catalog_id = 'stamina_potion_medium';

UPDATE items
   SET special_effect = 'Full stamina restore'
 WHERE catalog_id = 'stamina_potion_large';

UPDATE items
   SET special_effect = '+25% HP'
 WHERE catalog_id = 'health_potion_small';

UPDATE items
   SET special_effect = '+50% HP'
 WHERE catalog_id = 'health_potion_medium';

UPDATE items
   SET special_effect = 'Full HP restore'
 WHERE catalog_id = 'health_potion_large';
