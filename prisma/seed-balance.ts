// =============================================================================
// seed-balance.ts — Seed item balance configuration into GameConfig + ItemBalanceProfile
// =============================================================================

import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

const BALANCE_CONFIGS: { key: string; value: unknown; category: string; description: string }[] = [
  // --- Power Score Weights ---
  { key: 'item_balance.power_stat_weights', value: { str: 1.0, agi: 1.0, vit: 0.8, end: 0.7, int: 1.0, wis: 0.7, luk: 0.5, cha: 0.3 }, category: 'item_balance', description: 'Weight of each stat in power score calculation' },
  { key: 'item_balance.power_upgrade_multiplier', value: 0.05, category: 'item_balance', description: 'Power bonus per upgrade level (5% each)' },
  { key: 'item_balance.power_rarity_multipliers', value: { common: 1.0, uncommon: 1.3, rare: 1.6, epic: 2.0, legendary: 2.5 }, category: 'item_balance', description: 'Rarity multiplier for power score' },

  // --- Stat Ranges by Level ---
  {
    key: 'item_balance.stat_ranges', category: 'item_balance',
    description: 'Allowed stat ranges per level bracket',
    value: [
      { minLevel: 1, maxLevel: 5, minStat: 1, maxStat: 8 },
      { minLevel: 6, maxLevel: 10, minStat: 5, maxStat: 16 },
      { minLevel: 11, maxLevel: 20, minStat: 10, maxStat: 30 },
      { minLevel: 21, maxLevel: 35, minStat: 18, maxStat: 50 },
      { minLevel: 36, maxLevel: 50, minStat: 28, maxStat: 75 },
    ],
  },

  // --- Rarity Multipliers ---
  { key: 'item_balance.rarity_multipliers', value: { common: 1.0, uncommon: 1.3, rare: 1.6, epic: 2.0, legendary: 2.5 }, category: 'item_balance', description: 'Stat generation rarity scaling factors' },

  // --- Level Scaling ---
  { key: 'item_balance.level_scaling_formula', value: 'linear', category: 'item_balance', description: 'Formula type: linear, exponential, or logarithmic' },
  { key: 'item_balance.level_scaling_base', value: 2, category: 'item_balance', description: 'Base stat multiplier per item level (itemLevel * base)' },
  { key: 'item_balance.level_scaling_exponent', value: 1.0, category: 'item_balance', description: 'Exponent for exponential scaling mode' },
  { key: 'item_balance.level_variance', value: 2, category: 'item_balance', description: 'Level variance range for dropped items (+/-)' },

  // --- Drop Tuning ---
  { key: 'item_balance.luk_drop_bonus_per_point', value: 0.003, category: 'item_balance', description: 'Drop chance bonus per LUK point (+0.3%)' },
  { key: 'item_balance.drop_chance_cap', value: 0.95, category: 'item_balance', description: 'Maximum drop chance cap (95%)' },
  { key: 'item_balance.level_rarity_bonus_per_level', value: 0.2, category: 'item_balance', description: 'Rarity bonus shift per player level above 1' },
  { key: 'item_balance.level_rarity_bonus_distribution', value: { rare: 0.4, epic: 0.35, legendary: 0.25 }, category: 'item_balance', description: 'How level rarity bonus distributes across tiers' },

  // --- Economy ---
  { key: 'item_balance.sell_price_by_rarity', value: { common: 10, uncommon: 25, rare: 60, epic: 150, legendary: 400 }, category: 'item_balance', description: 'Base sell price per rarity tier (multiplied by level)' },
  { key: 'item_balance.buy_price_multiplier', value: 4, category: 'item_balance', description: 'Buy price = sell price * this multiplier' },
  { key: 'item_balance.power_to_price_ratio', value: 5, category: 'item_balance', description: 'Gold per power score point for auto-pricing' },

  // --- Upgrade Balance ---
  { key: 'item_balance.upgrade_stat_bonus_per_level', value: 1, category: 'item_balance', description: 'Stat bonus added per upgrade level per stat' },
  { key: 'item_balance.upgrade_cost_formula', value: 'linear', category: 'item_balance', description: 'Upgrade cost formula: linear, exponential, or custom' },
  { key: 'item_balance.upgrade_cost_base', value: 100, category: 'item_balance', description: 'Base gold cost multiplier for upgrades' },
  { key: 'item_balance.upgrade_cost_exponent', value: 1.5, category: 'item_balance', description: 'Exponent for exponential cost scaling' },
  { key: 'item_balance.upgrade_failure_downgrade_threshold', value: 5, category: 'item_balance', description: 'Upgrade level at which failure causes downgrade' },
  { key: 'item_balance.upgrade_protection_gem_cost', value: 30, category: 'item_balance', description: 'Gem cost for upgrade protection scroll' },

  // --- Validation Thresholds ---
  { key: 'item_balance.validation_power_deviation_threshold', value: 0.3, category: 'item_balance', description: 'Flag items with power deviation exceeding 30%' },
  { key: 'item_balance.validation_stat_cap_multiplier', value: 3.0, category: 'item_balance', description: 'Flag stats exceeding bracket max * this multiplier' },

  // --- Derived Stat Formulas ---
  { key: 'item_balance.hp_base', value: 80, category: 'item_balance', description: 'Base HP before stat bonuses' },
  { key: 'item_balance.hp_per_vit', value: 5, category: 'item_balance', description: 'HP gained per VIT point' },
  { key: 'item_balance.hp_per_end', value: 3, category: 'item_balance', description: 'HP gained per END point' },
  { key: 'item_balance.armor_per_end', value: 2, category: 'item_balance', description: 'Armor gained per END point' },
  { key: 'item_balance.armor_per_str', value: 0.5, category: 'item_balance', description: 'Armor gained per STR point' },
  { key: 'item_balance.mr_per_wis', value: 2, category: 'item_balance', description: 'Magic Resist gained per WIS point' },
  { key: 'item_balance.mr_per_int', value: 0.5, category: 'item_balance', description: 'Magic Resist gained per INT point' },

  // --- Combat Damage Scaling ---
  {
    key: 'item_balance.class_damage_scaling', category: 'item_balance',
    description: 'Per-class damage formula: damage = stat * multiplier + level * levelBonus',
    value: {
      warrior: { stat: 'str', multiplier: 1.5, levelBonus: 2 },
      tank: { stat: 'str', multiplier: 1.2, levelBonus: 2 },
      rogue: { stat: 'agi', multiplier: 1.5, levelBonus: 2 },
      mage: { stat: 'int', multiplier: 1.5, levelBonus: 2 },
    },
  },
]

const ITEM_BALANCE_PROFILES: { itemType: string; statWeights: Record<string, number>; powerWeight: number; description: string }[] = [
  { itemType: 'weapon', statWeights: { str: 1.0, agi: 0.3 }, powerWeight: 1.2, description: 'Weapons emphasize STR with secondary AGI' },
  { itemType: 'helmet', statWeights: { vit: 0.8, wis: 0.4 }, powerWeight: 0.9, description: 'Helmets emphasize VIT with secondary WIS' },
  { itemType: 'chest', statWeights: { vit: 1.0, end: 0.5 }, powerWeight: 1.0, description: 'Chest armor emphasizes VIT with secondary END' },
  { itemType: 'gloves', statWeights: { str: 0.6, agi: 0.6 }, powerWeight: 0.85, description: 'Gloves balance STR and AGI equally' },
  { itemType: 'legs', statWeights: { vit: 0.7, end: 0.5 }, powerWeight: 0.9, description: 'Leg armor emphasizes VIT with secondary END' },
  { itemType: 'boots', statWeights: { agi: 1.0, end: 0.3 }, powerWeight: 0.85, description: 'Boots emphasize AGI with secondary END' },
  { itemType: 'accessory', statWeights: { luk: 1.0, cha: 0.5 }, powerWeight: 0.7, description: 'Accessories emphasize LUK with secondary CHA' },
  { itemType: 'amulet', statWeights: { int: 1.0, wis: 0.5 }, powerWeight: 0.8, description: 'Amulets emphasize INT with secondary WIS' },
  { itemType: 'belt', statWeights: { end: 1.0, vit: 0.3 }, powerWeight: 0.75, description: 'Belts emphasize END with secondary VIT' },
  { itemType: 'relic', statWeights: { int: 0.7, wis: 0.7 }, powerWeight: 0.9, description: 'Relics balance INT and WIS' },
  { itemType: 'necklace', statWeights: { cha: 1.0, luk: 0.4 }, powerWeight: 0.7, description: 'Necklaces emphasize CHA with secondary LUK' },
  { itemType: 'ring', statWeights: { luk: 0.5, str: 0.5 }, powerWeight: 0.75, description: 'Rings balance LUK and STR' },
]

async function main() {
  console.log('Seeding item balance configuration...')

  // Seed GameConfig values
  let created = 0
  let skipped = 0

  for (const cfg of BALANCE_CONFIGS) {
    const existing = await prisma.gameConfig.findUnique({ where: { key: cfg.key } })
    if (existing) {
      skipped++
      continue
    }
    await prisma.gameConfig.create({
      data: {
        key: cfg.key,
        value: cfg.value as never,
        category: cfg.category,
        description: cfg.description,
      },
    })
    created++
  }

  console.log(`GameConfig: ${created} created, ${skipped} skipped (already exist)`)

  // Seed ItemBalanceProfile values
  let profilesCreated = 0
  let profilesSkipped = 0

  for (const profile of ITEM_BALANCE_PROFILES) {
    const existing = await prisma.itemBalanceProfile.findFirst({
      where: { itemType: profile.itemType as never },
    })
    if (existing) {
      profilesSkipped++
      continue
    }
    await prisma.itemBalanceProfile.create({
      data: {
        itemType: profile.itemType as never,
        statWeights: profile.statWeights as never,
        powerWeight: profile.powerWeight,
        description: profile.description,
      },
    })
    profilesCreated++
  }

  console.log(`ItemBalanceProfile: ${profilesCreated} created, ${profilesSkipped} skipped`)
  console.log('Done!')
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
