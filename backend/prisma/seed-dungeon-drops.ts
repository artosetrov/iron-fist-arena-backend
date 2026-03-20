// =============================================================================
// seed-dungeon-drops.ts — Populate drop tables for all dungeons
// Run: npx tsx prisma/seed-dungeon-drops.ts
// =============================================================================

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ---------------------------------------------------------------------------
// Drop table definitions per dungeon slug
// Each entry: [catalogId, dropChance%, minQty, maxQty]
// Items are from the existing catalog — nothing is generated.
// ---------------------------------------------------------------------------

type DropDef = [string, number, number, number];

const DUNGEON_DROPS: Record<string, DropDef[]> = {
  // ── Training Camp (lvl 1) — mostly common, easy drops ──────────
  training_camp: [
    ['wpn_rusty_sword', 15, 1, 1],
    ['wpn_wooden_staff', 15, 1, 1],
    ['wpn_iron_dagger', 12, 1, 1],
    ['wpn_training_mace', 12, 1, 1],
    ['helm_leather_cap', 12, 1, 1],
    ['chest_cloth_robe', 12, 1, 1],
    ['glove_cloth_wraps', 10, 1, 1],
    ['legs_cloth_pants', 10, 1, 1],
    ['boot_sandals', 10, 1, 1],
    ['ring_copper', 8, 1, 1],
    ['amu_copper_chain', 8, 1, 1],
    ['belt_rope', 10, 1, 1],
    ['neck_bone_charm', 8, 1, 1],
    ['health_potion_small', 20, 1, 2],
    ['stamina_potion_small', 18, 1, 2],
  ],

  // ── Desecrated Catacombs (lvl ~5) — common + uncommon ──────────
  desecrated_catacombs: [
    ['wpn_steel_longsword', 10, 1, 1],
    ['wpn_arcane_wand', 10, 1, 1],
    ['wpn_shadow_knife', 8, 1, 1],
    ['helm_iron_helm', 10, 1, 1],
    ['helm_mystic_hood', 8, 1, 1],
    ['chest_chain_mail', 10, 1, 1],
    ['chest_mage_robe', 8, 1, 1],
    ['glove_iron_gauntlets', 8, 1, 1],
    ['legs_chain_leggings', 8, 1, 1],
    ['boot_iron_treads', 8, 1, 1],
    ['acc_iron_shield', 7, 1, 1],
    ['amu_silver_pendant', 6, 1, 1],
    ['belt_leather', 8, 1, 1],
    ['ring_silver', 6, 1, 1],
    ['neck_emerald', 6, 1, 1],
    ['relic_old_coin', 5, 1, 1],
    ['health_potion_small', 15, 1, 2],
    ['health_potion_medium', 8, 1, 1],
    ['stamina_potion_small', 12, 1, 2],
  ],

  // ── Volcanic Forge (lvl ~10) — uncommon + rare ─────────────────
  volcanic_forge: [
    ['wpn_flamebrand', 6, 1, 1],
    ['wpn_war_hammer', 8, 1, 1],
    ['wpn_steel_longsword', 7, 1, 1],
    ['helm_dragon_visage', 5, 1, 1],
    ['helm_iron_helm', 8, 1, 1],
    ['chest_plate_armor', 5, 1, 1],
    ['chest_chain_mail', 7, 1, 1],
    ['glove_assassin', 5, 1, 1],
    ['glove_iron_gauntlets', 7, 1, 1],
    ['legs_shadow_pants', 5, 1, 1],
    ['legs_chain_leggings', 7, 1, 1],
    ['boot_windwalkers', 5, 1, 1],
    ['boot_iron_treads', 7, 1, 1],
    ['acc_magic_orb', 4, 1, 1],
    ['belt_titan', 4, 1, 1],
    ['ring_blood_ruby', 4, 1, 1],
    ['neck_dragon_tooth', 4, 1, 1],
    ['relic_skull', 3, 1, 1],
    ['health_potion_medium', 12, 1, 2],
    ['stamina_potion_medium', 10, 1, 1],
  ],

  // ── Fungal Grotto (lvl 30) — uncommon + rare ───────────────────
  fungal_grotto: [
    ['wpn_frostbite_staff', 6, 1, 1],
    ['wpn_venom_fang', 6, 1, 1],
    ['wpn_arcane_wand', 8, 1, 1],
    ['helm_dragon_visage', 5, 1, 1],
    ['helm_mystic_hood', 7, 1, 1],
    ['chest_shadow_vest', 5, 1, 1],
    ['chest_mage_robe', 7, 1, 1],
    ['glove_assassin', 5, 1, 1],
    ['legs_shadow_pants', 5, 1, 1],
    ['boot_windwalkers', 5, 1, 1],
    ['acc_magic_orb', 4, 1, 1],
    ['amu_silver_pendant', 6, 1, 1],
    ['belt_titan', 4, 1, 1],
    ['ring_blood_ruby', 4, 1, 1],
    ['relic_skull', 3, 1, 1],
    ['health_potion_medium', 12, 1, 2],
    ['stamina_potion_medium', 10, 1, 1],
  ],

  // ── Scorched Mines (lvl 35) — rare focused ─────────────────────
  scorched_mines: [
    ['wpn_flamebrand', 7, 1, 1],
    ['wpn_venom_fang', 6, 1, 1],
    ['wpn_war_hammer', 7, 1, 1],
    ['helm_dragon_visage', 6, 1, 1],
    ['chest_plate_armor', 6, 1, 1],
    ['chest_shadow_vest', 5, 1, 1],
    ['glove_assassin', 6, 1, 1],
    ['legs_shadow_pants', 6, 1, 1],
    ['legs_chain_leggings', 5, 1, 1],
    ['boot_windwalkers', 6, 1, 1],
    ['acc_magic_orb', 5, 1, 1],
    ['belt_titan', 5, 1, 1],
    ['ring_blood_ruby', 5, 1, 1],
    ['neck_dragon_tooth', 5, 1, 1],
    ['relic_skull', 4, 1, 1],
    ['health_potion_medium', 10, 1, 2],
    ['stamina_potion_medium', 8, 1, 1],
  ],

  // ── Frozen Abyss (lvl 40) — rare + epic teasers ────────────────
  frozen_abyss: [
    ['wpn_frostbite_staff', 8, 1, 1],
    ['wpn_flamebrand', 5, 1, 1],
    ['wpn_stormbringer', 2, 1, 1],
    ['helm_dragon_visage', 6, 1, 1],
    ['helm_crown_of_thorns', 2, 1, 1],
    ['chest_plate_armor', 6, 1, 1],
    ['chest_titan_cuirass', 2, 1, 1],
    ['glove_assassin', 6, 1, 1],
    ['glove_berserker', 2, 1, 1],
    ['legs_shadow_pants', 6, 1, 1],
    ['boot_windwalkers', 6, 1, 1],
    ['acc_magic_orb', 5, 1, 1],
    ['belt_titan', 5, 1, 1],
    ['ring_blood_ruby', 5, 1, 1],
    ['neck_dragon_tooth', 5, 1, 1],
    ['relic_skull', 4, 1, 1],
    ['health_potion_medium', 10, 1, 2],
    ['health_potion_large', 4, 1, 1],
  ],

  // ── Realm of Light (lvl 45) — rare + epic ──────────────────────
  realm_of_light: [
    ['wpn_stormbringer', 3, 1, 1],
    ['wpn_void_scepter', 3, 1, 1],
    ['wpn_flamebrand', 5, 1, 1],
    ['wpn_frostbite_staff', 5, 1, 1],
    ['helm_crown_of_thorns', 3, 1, 1],
    ['helm_dragon_visage', 5, 1, 1],
    ['chest_titan_cuirass', 3, 1, 1],
    ['chest_plate_armor', 5, 1, 1],
    ['glove_berserker', 3, 1, 1],
    ['glove_assassin', 5, 1, 1],
    ['legs_titan_greaves', 3, 1, 1],
    ['boot_titan_stompers', 3, 1, 1],
    ['amu_phoenix_heart', 2, 1, 1],
    ['ring_void', 3, 1, 1],
    ['belt_titan', 5, 1, 1],
    ['relic_skull', 4, 1, 1],
    ['health_potion_large', 6, 1, 1],
    ['stamina_potion_large', 4, 1, 1],
  ],

  // ── Shadow Realm (lvl 50) — epic focused ───────────────────────
  shadow_realm: [
    ['wpn_stormbringer', 4, 1, 1],
    ['wpn_void_scepter', 4, 1, 1],
    ['wpn_venom_fang', 5, 1, 1],
    ['helm_crown_of_thorns', 4, 1, 1],
    ['chest_titan_cuirass', 4, 1, 1],
    ['chest_shadow_vest', 5, 1, 1],
    ['glove_berserker', 4, 1, 1],
    ['legs_titan_greaves', 4, 1, 1],
    ['legs_shadow_pants', 5, 1, 1],
    ['boot_titan_stompers', 4, 1, 1],
    ['boot_windwalkers', 5, 1, 1],
    ['amu_phoenix_heart', 3, 1, 1],
    ['ring_void', 4, 1, 1],
    ['ring_blood_ruby', 5, 1, 1],
    ['neck_dragon_tooth', 5, 1, 1],
    ['relic_skull', 5, 1, 1],
    ['health_potion_large', 8, 1, 1],
    ['stamina_potion_large', 5, 1, 1],
  ],

  // ── Clockwork Citadel (lvl 55) — epic focused ─────────────────
  clockwork_citadel: [
    ['wpn_stormbringer', 5, 1, 1],
    ['wpn_void_scepter', 5, 1, 1],
    ['wpn_excalibur', 1, 1, 1],
    ['helm_crown_of_thorns', 5, 1, 1],
    ['chest_titan_cuirass', 5, 1, 1],
    ['glove_berserker', 5, 1, 1],
    ['legs_titan_greaves', 5, 1, 1],
    ['boot_titan_stompers', 5, 1, 1],
    ['amu_phoenix_heart', 3, 1, 1],
    ['ring_void', 5, 1, 1],
    ['belt_titan', 6, 1, 1],
    ['neck_dragon_tooth', 5, 1, 1],
    ['relic_skull', 5, 1, 1],
    ['relic_orb_of_ages', 1, 1, 1],
    ['health_potion_large', 8, 1, 1],
    ['stamina_potion_large', 6, 1, 1],
  ],

  // ── Abyssal Depths (lvl 60) — epic + legendary teasers ─────────
  abyssal_depths: [
    ['wpn_stormbringer', 5, 1, 1],
    ['wpn_void_scepter', 5, 1, 1],
    ['wpn_excalibur', 2, 1, 1],
    ['helm_crown_of_thorns', 5, 1, 1],
    ['chest_titan_cuirass', 5, 1, 1],
    ['glove_berserker', 5, 1, 1],
    ['legs_titan_greaves', 5, 1, 1],
    ['boot_titan_stompers', 5, 1, 1],
    ['amu_phoenix_heart', 4, 1, 1],
    ['ring_void', 5, 1, 1],
    ['belt_titan', 6, 1, 1],
    ['neck_dragon_tooth', 6, 1, 1],
    ['relic_orb_of_ages', 2, 1, 1],
    ['relic_skull', 5, 1, 1],
    ['health_potion_large', 10, 1, 2],
    ['stamina_potion_large', 6, 1, 1],
  ],

  // ── Infernal Throne (lvl 65) — best loot in the game ──────────
  infernal_throne: [
    ['wpn_excalibur', 3, 1, 1],
    ['wpn_stormbringer', 6, 1, 1],
    ['wpn_void_scepter', 6, 1, 1],
    ['helm_crown_of_thorns', 6, 1, 1],
    ['chest_titan_cuirass', 6, 1, 1],
    ['glove_berserker', 6, 1, 1],
    ['legs_titan_greaves', 6, 1, 1],
    ['boot_titan_stompers', 6, 1, 1],
    ['amu_phoenix_heart', 5, 1, 1],
    ['ring_void', 6, 1, 1],
    ['belt_titan', 6, 1, 1],
    ['neck_dragon_tooth', 6, 1, 1],
    ['relic_orb_of_ages', 3, 1, 1],
    ['relic_skull', 6, 1, 1],
    ['health_potion_large', 12, 1, 2],
    ['stamina_potion_large', 8, 1, 1],
  ],
};

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  console.log('🎲 Seeding dungeon drop tables...\n');

  // 1. Load all items keyed by catalogId
  const allItems = await prisma.item.findMany({ select: { id: true, catalogId: true, itemName: true } });
  const itemByCatalog = new Map(allItems.map((i) => [i.catalogId, i]));
  console.log(`  📦 Found ${allItems.length} items in catalog\n`);

  // 2. Load all dungeons keyed by slug
  const allDungeons = await prisma.dungeon.findMany({ select: { id: true, slug: true, name: true } });
  const dungeonBySlug = new Map(allDungeons.map((d) => [d.slug, d]));
  console.log(`  🏰 Found ${allDungeons.length} dungeons\n`);

  let totalDrops = 0;
  let skippedSlugs: string[] = [];

  for (const [slug, drops] of Object.entries(DUNGEON_DROPS)) {
    const dungeon = dungeonBySlug.get(slug);
    if (!dungeon) {
      skippedSlugs.push(slug);
      continue;
    }

    // Delete existing drops for this dungeon (idempotent)
    const deleted = await prisma.dungeonDrop.deleteMany({ where: { dungeonId: dungeon.id } });
    if (deleted.count > 0) {
      console.log(`  🗑️  Cleared ${deleted.count} existing drops from ${dungeon.name}`);
    }

    // Create new drops
    const dropData = drops
      .map(([catalogId, dropChance, minQty, maxQty]) => {
        const item = itemByCatalog.get(catalogId);
        if (!item) {
          console.warn(`    ⚠️  Item ${catalogId} not found — skipping`);
          return null;
        }
        return {
          dungeonId: dungeon.id,
          itemId: item.id,
          dropChance,
          minQuantity: minQty,
          maxQuantity: maxQty,
        };
      })
      .filter(Boolean) as {
      dungeonId: string;
      itemId: string;
      dropChance: number;
      minQuantity: number;
      maxQuantity: number;
    }[];

    if (dropData.length > 0) {
      await prisma.dungeonDrop.createMany({ data: dropData });
      totalDrops += dropData.length;
      console.log(`  ✅ ${dungeon.name}: ${dropData.length} drops added`);
    }
  }

  if (skippedSlugs.length > 0) {
    console.log(`\n  ⚠️  Skipped slugs (not found): ${skippedSlugs.join(', ')}`);
  }

  console.log(`\n🎲 Done! ${totalDrops} drops across ${Object.keys(DUNGEON_DROPS).length - skippedSlugs.length} dungeons.\n`);
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
