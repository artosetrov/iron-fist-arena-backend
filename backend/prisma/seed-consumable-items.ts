/**
 * Seed `items` rows for shop-purchasable consumables (potions + gem packs).
 *
 * Mirrors `prisma/migrations/20260320_seed_consumable_items/migration.sql` —
 * keep them in sync. The migration is what runs in prod / staging via
 * `prisma migrate deploy`; this script is for local dev DBs and CI fixtures
 * that may be re-bootstrapped without replaying the full migration history.
 *
 * Source of truth: this TS file. The 2026-03-20 migration carries the same
 * 9 catalog rows verbatim — when a price / description / rarity changes,
 * update both this file AND a NEW migration (do not edit the old migration
 * in place; migration history is append-only).
 *
 * Idempotent: uses `upsert` keyed on `catalogId`. Re-running will not
 * duplicate rows. On conflict only the catalog metadata is refreshed
 * (item_name / rarity / buy_price / description); admin-managed fields
 * (image_url, image_key, drop_chance) are left untouched.
 *
 * Closes the gatekeeper §6c gap flagged in `docs/retro/RETRO_2026-04-21.md`
 * pending-list item: "Достроить seed-consumable-items.ts для парности с
 * 20260320_seed_consumable_items миграцией (P2)."
 *
 * Usage:
 *   npm run db:seed:consumables
 */

import { PrismaClient, ItemType, Rarity } from '@prisma/client'

const prisma = new PrismaClient()

interface ConsumableDef {
  catalogId: string
  itemName: string
  rarity: Rarity
  buyPrice: number
  description: string
}

// Keep order identical to the SQL migration so a side-by-side diff stays
// trivial. Comments mirror the section headers in `migration.sql`.
const CONSUMABLE_DEFS: ConsumableDef[] = [
  // Stamina potions
  { catalogId: 'stamina_potion_small',  itemName: 'Small Stamina Potion',  rarity: 'common',   buyPrice: 100,  description: 'Restores 30 stamina.' },
  { catalogId: 'stamina_potion_medium', itemName: 'Medium Stamina Potion', rarity: 'uncommon', buyPrice: 250,  description: 'Restores 60 stamina.' },
  { catalogId: 'stamina_potion_large',  itemName: 'Large Stamina Potion',  rarity: 'rare',     buyPrice: 500,  description: 'Fully restores stamina.' },
  // Health potions
  { catalogId: 'health_potion_small',   itemName: 'Small Health Potion',   rarity: 'common',   buyPrice: 150,  description: 'Restores 25% of max HP.' },
  { catalogId: 'health_potion_medium',  itemName: 'Medium Health Potion',  rarity: 'uncommon', buyPrice: 350,  description: 'Restores 50% of max HP.' },
  { catalogId: 'health_potion_large',   itemName: 'Large Health Potion',   rarity: 'rare',     buyPrice: 700,  description: 'Fully restores HP.' },
  // Gem packs
  { catalogId: 'gem_pack_small',        itemName: 'Small Gem Pouch',       rarity: 'uncommon', buyPrice: 150,  description: 'Contains 10 gems.' },
  { catalogId: 'gem_pack_medium',       itemName: 'Medium Gem Pouch',      rarity: 'rare',     buyPrice: 750,  description: 'Contains 50 gems.' },
  { catalogId: 'gem_pack_large',        itemName: 'Large Gem Pouch',       rarity: 'epic',     buyPrice: 1500, description: 'Contains 100 gems.' },
]

async function main() {
  let created = 0
  let updated = 0

  for (const def of CONSUMABLE_DEFS) {
    const result = await prisma.item.upsert({
      where: { catalogId: def.catalogId },
      // Update only catalog metadata — leave image_url / image_key /
      // drop_chance untouched so admin edits and asset uploads don't get
      // wiped on a re-seed.
      update: {
        itemName: def.itemName,
        rarity: def.rarity,
        buyPrice: def.buyPrice,
        description: def.description,
      },
      create: {
        catalogId: def.catalogId,
        itemName: def.itemName,
        itemType: 'consumable' as ItemType,
        rarity: def.rarity,
        itemLevel: 1,
        buyPrice: def.buyPrice,
        sellPrice: 0,
        description: def.description,
        baseStats: {},
      },
    })

    if (result.createdAt.getTime() === result.updatedAt.getTime()) {
      created++
    } else {
      updated++
    }
  }

  console.log(`✓ consumable_items seed complete — ${created} created, ${updated} updated`)
}

main()
  .catch((err) => {
    console.error('✗ consumable_items seed failed:', err)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
