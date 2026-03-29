// =============================================================================
// item-balance.ts — Core Item Balance Engine
// All formulas read from GameConfig with hardcoded fallbacks for safety.
// =============================================================================

import { getGameConfig, getGameConfigs } from './config'
import { prisma } from '@/lib/prisma'

// --- Types ---

type Rarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary'
type ItemType =
  | 'weapon' | 'helmet' | 'chest' | 'gloves' | 'legs' | 'boots'
  | 'accessory' | 'amulet' | 'belt' | 'relic' | 'necklace' | 'ring'

type StatKey = 'str' | 'agi' | 'vit' | 'end' | 'int' | 'wis' | 'luk' | 'cha'

interface StatBlock {
  str: number
  agi: number
  vit: number
  end: number
  int: number
  wis: number
  luk: number
  cha: number
}

interface StatRange {
  minLevel: number
  maxLevel: number
  minStat: number
  maxStat: number
}

interface ClassDamageScaling {
  stat: string
  multiplier: number
  levelBonus: number
}

// --- Fallback defaults (match current hardcoded values) ---

const DEFAULT_POWER_STAT_WEIGHTS: Record<string, number> = {
  str: 1.0, agi: 1.0, vit: 0.8, end: 0.7, int: 1.0, wis: 0.7, luk: 0.5, cha: 0.3,
}

const DEFAULT_RARITY_MULTIPLIERS: Record<string, number> = {
  common: 1.0, uncommon: 1.3, rare: 1.6, epic: 2.0, legendary: 2.5,
}

const DEFAULT_STAT_RANGES: StatRange[] = [
  { minLevel: 1, maxLevel: 5, minStat: 1, maxStat: 8 },
  { minLevel: 6, maxLevel: 10, minStat: 5, maxStat: 16 },
  { minLevel: 11, maxLevel: 20, minStat: 10, maxStat: 30 },
  { minLevel: 21, maxLevel: 35, minStat: 18, maxStat: 50 },
  { minLevel: 36, maxLevel: 50, minStat: 28, maxStat: 75 },
]

const DEFAULT_SELL_PRICE_BY_RARITY: Record<string, number> = {
  common: 10, uncommon: 25, rare: 60, epic: 150, legendary: 400,
}

const DEFAULT_CLASS_DAMAGE_SCALING: Record<string, ClassDamageScaling> = {
  warrior: { stat: 'str', multiplier: 1.5, levelBonus: 2 },
  tank: { stat: 'str', multiplier: 1.3, levelBonus: 2 },
  rogue: { stat: 'agi', multiplier: 1.5, levelBonus: 2 },
  mage: { stat: 'int', multiplier: 1.4, levelBonus: 2 },
}

const DEFAULT_ITEM_TYPE_WEIGHTS: Record<string, Record<string, number>> = {
  weapon: { str: 1.0, agi: 0.3 },
  helmet: { vit: 0.8, wis: 0.4 },
  chest: { vit: 1.0, end: 0.5 },
  gloves: { str: 0.6, agi: 0.6 },
  legs: { vit: 0.7, end: 0.5 },
  boots: { agi: 1.0, end: 0.3 },
  accessory: { luk: 1.0, cha: 0.5 },
  amulet: { int: 1.0, wis: 0.5 },
  belt: { end: 1.0, vit: 0.3 },
  relic: { int: 0.7, wis: 0.7 },
  necklace: { cha: 1.0, luk: 0.4 },
  ring: { luk: 0.5, str: 0.5 },
}

// --- ItemBalanceProfile cache (module-level, avoids repeated DB hits per item type) ---

interface CachedProfile {
  powerWeight: number
  statWeights: Record<string, number>
}
const _itemBalanceProfileCache = new Map<string, CachedProfile>()

async function getItemBalanceProfile(itemType: string): Promise<CachedProfile | null> {
  if (_itemBalanceProfileCache.has(itemType)) {
    return _itemBalanceProfileCache.get(itemType)!
  }
  try {
    const profile = await prisma.itemBalanceProfile.findFirst({
      where: { itemType: itemType as never },
      select: { powerWeight: true, statWeights: true },
    })
    if (profile) {
      const cached: CachedProfile = {
        powerWeight: profile.powerWeight,
        statWeights: profile.statWeights as Record<string, number>,
      }
      _itemBalanceProfileCache.set(itemType, cached)
      return cached
    }
  } catch {
    // fallback — don't cache misses so we retry on next call
  }
  return null
}

// --- Power Score ---

/**
 * Calculate the Item Power Score.
 * Power = sum(stat * weight) * rarityMult * (1 + upgradeLevel * upgradeMult) * itemTypePowerWeight
 */
export async function calculateItemPowerScore(
  baseStats: Record<string, number>,
  rarity: Rarity,
  upgradeLevel: number = 0,
  itemType?: ItemType,
): Promise<number> {
  const [powerWeights, rarityMults, upgradeMult] = await Promise.all([
    getGameConfig<Record<string, number>>('item_balance.power_stat_weights', DEFAULT_POWER_STAT_WEIGHTS),
    getGameConfig<Record<string, number>>('item_balance.power_rarity_multipliers', DEFAULT_RARITY_MULTIPLIERS),
    getGameConfig<number>('item_balance.power_upgrade_multiplier', 0.05),
  ])

  // Weighted stat sum
  let statSum = 0
  for (const [stat, value] of Object.entries(baseStats)) {
    const weight = powerWeights[stat] ?? 0.5
    statSum += value * weight
  }

  // Rarity multiplier
  const rarityMult = rarityMults[rarity] ?? 1.0

  // Upgrade bonus
  const upgradeBonus = 1 + upgradeLevel * upgradeMult

  // Item type power weight — use module-level cache (no DB hit on repeated calls)
  let typePowerWeight = 1.0
  if (itemType) {
    const profile = await getItemBalanceProfile(itemType)
    if (profile) typePowerWeight = profile.powerWeight
  }

  return Math.round(statSum * rarityMult * upgradeBonus * typePowerWeight)
}

// --- Stat Ranges ---

/**
 * Get the allowed stat range for a given item level.
 */
export async function getStatRangeForLevel(itemLevel: number): Promise<StatRange> {
  const ranges = await getGameConfig<StatRange[]>('item_balance.stat_ranges', DEFAULT_STAT_RANGES)

  for (const range of ranges) {
    if (itemLevel >= range.minLevel && itemLevel <= range.maxLevel) {
      return range
    }
  }

  // If level exceeds all ranges, extrapolate from last range
  const last = ranges[ranges.length - 1]
  if (last && itemLevel > last.maxLevel) {
    const scaleFactor = itemLevel / last.maxLevel
    return {
      minLevel: last.maxLevel + 1,
      maxLevel: itemLevel,
      minStat: Math.round(last.minStat * scaleFactor),
      maxStat: Math.round(last.maxStat * scaleFactor),
    }
  }

  return { minLevel: 1, maxLevel: 5, minStat: 1, maxStat: 8 }
}

// --- Expected Power for a level + rarity ---

/**
 * Calculate the expected power score for an item at a given level and rarity.
 * Used by validation to detect OP or weak items.
 */
export async function getExpectedPower(itemLevel: number, rarity: Rarity, itemType?: ItemType): Promise<number> {
  const range = await getStatRangeForLevel(itemLevel)
  const rarityMults = await getGameConfig<Record<string, number>>('item_balance.rarity_multipliers', DEFAULT_RARITY_MULTIPLIERS)
  const rarityMult = rarityMults[rarity] ?? 1.0

  // Expected average stat = midpoint of range * rarityMult
  const avgStat = ((range.minStat + range.maxStat) / 2) * rarityMult

  // Get item type weights to estimate number of stats — use module-level cache
  let weights: Record<string, number> = { str: 1.0 }
  if (itemType) {
    const profile = await getItemBalanceProfile(itemType)
    if (profile) {
      weights = profile.statWeights
    } else {
      weights = DEFAULT_ITEM_TYPE_WEIGHTS[itemType] ?? { str: 1.0 }
    }
  }

  // Build expected stats
  const expectedStats: Record<string, number> = {}
  for (const [stat, weight] of Object.entries(weights)) {
    expectedStats[stat] = Math.round(avgStat * weight)
  }

  return calculateItemPowerScore(expectedStats, rarity, 0, itemType)
}

// --- Base Stat Generation ---

/**
 * Generate base stats for a new item, reading all config from DB.
 * Replaces the hardcoded generateBaseStats in loot.ts.
 */
export async function generateBalancedBaseStats(
  itemType: ItemType,
  rarity: Rarity,
  itemLevel: number,
): Promise<Record<string, number>> {
  const [rarityMults, formula, scalingBase, exponent] = await Promise.all([
    getGameConfig<Record<string, number>>('item_balance.rarity_multipliers', DEFAULT_RARITY_MULTIPLIERS),
    getGameConfig<string>('item_balance.level_scaling_formula', 'linear'),
    getGameConfig<number>('item_balance.level_scaling_base', 2),
    getGameConfig<number>('item_balance.level_scaling_exponent', 1.0),
  ])

  const mult = rarityMults[rarity] ?? 1.0

  // Calculate base value from level scaling formula
  let baseValue: number
  switch (formula) {
    case 'exponential':
      baseValue = Math.max(1, Math.round(Math.pow(itemLevel, exponent) * scalingBase * mult))
      break
    case 'logarithmic':
      baseValue = Math.max(1, Math.round(Math.log2(itemLevel + 1) * scalingBase * mult * 3))
      break
    case 'linear':
    default:
      baseValue = Math.max(1, Math.round(itemLevel * scalingBase * mult))
      break
  }

  // Get item type stat weights from ItemBalanceProfile
  let statWeights: Record<string, number>
  try {
    const profile = await prisma.itemBalanceProfile.findFirst({
      where: { itemType: itemType as never },
    })
    statWeights = profile
      ? (profile.statWeights as Record<string, number>)
      : (DEFAULT_ITEM_TYPE_WEIGHTS[itemType] ?? { str: 1.0 })
  } catch {
    statWeights = DEFAULT_ITEM_TYPE_WEIGHTS[itemType] ?? { str: 1.0 }
  }

  // Generate stats based on weights
  const stats: Record<string, number> = {}
  for (const [stat, weight] of Object.entries(statWeights)) {
    stats[stat] = Math.max(1, Math.round(baseValue * weight))
  }

  return stats
}

// --- Economy ---

/**
 * Calculate sell price based on rarity and item level.
 */
export async function calculateSellPrice(
  rarity: Rarity,
  itemLevel: number,
): Promise<number> {
  const sellPriceByRarity = await getGameConfig<Record<string, number>>(
    'item_balance.sell_price_by_rarity',
    DEFAULT_SELL_PRICE_BY_RARITY,
  )
  const basePrice = sellPriceByRarity[rarity] ?? 10
  return basePrice * itemLevel
}

/**
 * Calculate buy price from sell price.
 */
export async function calculateBuyPrice(sellPrice: number): Promise<number> {
  const multiplier = await getGameConfig<number>('item_balance.buy_price_multiplier', 4)
  return Math.round(sellPrice * multiplier)
}

/**
 * Calculate sell price from power score (alternative formula).
 */
export async function calculatePricefromPower(powerScore: number): Promise<{ sellPrice: number; buyPrice: number }> {
  const [ratio, buyMult] = await Promise.all([
    getGameConfig<number>('item_balance.power_to_price_ratio', 5),
    getGameConfig<number>('item_balance.buy_price_multiplier', 4),
  ])
  const sellPrice = Math.round(powerScore * ratio)
  return { sellPrice, buyPrice: Math.round(sellPrice * buyMult) }
}

// --- Upgrades ---

/**
 * Get the gold cost for an upgrade attempt.
 */
export async function getUpgradeCost(currentUpgradeLevel: number): Promise<number> {
  const [formula, base, exponent] = await Promise.all([
    getGameConfig<string>('item_balance.upgrade_cost_formula', 'linear'),
    getGameConfig<number>('item_balance.upgrade_cost_base', 100),
    getGameConfig<number>('item_balance.upgrade_cost_exponent', 1.5),
  ])

  const level = currentUpgradeLevel + 1

  switch (formula) {
    case 'exponential':
      return Math.round(base * Math.pow(level, exponent))
    case 'linear':
    default:
      return level * base
  }
}

/**
 * Get the success chance for an upgrade attempt (0-100).
 */
export async function getUpgradeSuccessChance(currentUpgradeLevel: number): Promise<number> {
  const chances = await getGameConfig<number[]>(
    'upgrade_chances',
    [100, 100, 100, 100, 100, 80, 60, 40, 25, 15],
  )
  if (currentUpgradeLevel >= chances.length) return 0
  return chances[currentUpgradeLevel]
}

/**
 * Get the upgrade protection scroll gem cost.
 */
export async function getUpgradeProtectionCost(): Promise<number> {
  return getGameConfig<number>('item_balance.upgrade_protection_gem_cost', 30)
}

/**
 * Get the upgrade level threshold at which failure causes downgrade.
 */
export async function getUpgradeDowngradeThreshold(): Promise<number> {
  return getGameConfig<number>('item_balance.upgrade_failure_downgrade_threshold', 5)
}

/**
 * Get the stat bonus added per upgrade level per stat.
 */
export async function getUpgradeStatBonus(): Promise<number> {
  return getGameConfig<number>('item_balance.upgrade_stat_bonus_per_level', 1)
}

// --- Derived Stats ---

/**
 * Calculate derived stats (maxHp, armor, magicResist) from total stats.
 * Reads formula coefficients from GameConfig.
 */
export async function calculateDerivedStatsFromConfig(
  stats: StatBlock,
): Promise<{ maxHp: number; armor: number; magicResist: number }> {
  const cfg = await getGameConfigs({
    'item_balance.hp_base': 80,
    'item_balance.hp_per_vit': 5,
    'item_balance.hp_per_end': 3,
    'item_balance.armor_per_end': 2,
    'item_balance.armor_per_str': 0.5,
    'item_balance.mr_per_wis': 2,
    'item_balance.mr_per_int': 0.5,
  })

  const hpBase = cfg['item_balance.hp_base'] as number
  const hpPerVit = cfg['item_balance.hp_per_vit'] as number
  const hpPerEnd = cfg['item_balance.hp_per_end'] as number
  const armorPerEnd = cfg['item_balance.armor_per_end'] as number
  const armorPerStr = cfg['item_balance.armor_per_str'] as number
  const mrPerWis = cfg['item_balance.mr_per_wis'] as number
  const mrPerInt = cfg['item_balance.mr_per_int'] as number

  return {
    maxHp: Math.round(hpBase + stats.vit * hpPerVit + stats.end * hpPerEnd),
    armor: Math.floor(stats.end * armorPerEnd + stats.str * armorPerStr),
    magicResist: Math.floor(stats.wis * mrPerWis + stats.int * mrPerInt),
  }
}

// --- Combat ---

/**
 * Get the damage formula for a character class from config.
 */
export async function getClassDamageFormula(
  characterClass: string,
): Promise<ClassDamageScaling> {
  const scaling = await getGameConfig<Record<string, ClassDamageScaling>>(
    'item_balance.class_damage_scaling',
    DEFAULT_CLASS_DAMAGE_SCALING,
  )
  return scaling[characterClass] ?? DEFAULT_CLASS_DAMAGE_SCALING.warrior
}

// --- Drop Tuning ---

/**
 * Get drop tuning configuration values.
 */
export async function getDropTuningConfig(): Promise<{
  lukBonusPerPoint: number
  dropChanceCap: number
  levelRarityBonusPerLevel: number
  levelRarityBonusDistribution: Record<string, number>
  levelVariance: number
}> {
  const cfg = await getGameConfigs({
    'item_balance.luk_drop_bonus_per_point': 0.003,
    'item_balance.drop_chance_cap': 0.95,
    'item_balance.level_rarity_bonus_per_level': 0.2,
    'item_balance.level_rarity_bonus_distribution': { rare: 0.4, epic: 0.35, legendary: 0.25 },
    'item_balance.level_variance': 2,
  })

  return {
    lukBonusPerPoint: cfg['item_balance.luk_drop_bonus_per_point'] as number,
    dropChanceCap: cfg['item_balance.drop_chance_cap'] as number,
    levelRarityBonusPerLevel: cfg['item_balance.level_rarity_bonus_per_level'] as number,
    levelRarityBonusDistribution: cfg['item_balance.level_rarity_bonus_distribution'] as Record<string, number>,
    levelVariance: cfg['item_balance.level_variance'] as number,
  }
}

/**
 * Get rarity multipliers for stat generation.
 */
export async function getRarityMultipliers(): Promise<Record<string, number>> {
  return getGameConfig<Record<string, number>>('item_balance.rarity_multipliers', DEFAULT_RARITY_MULTIPLIERS)
}

// --- Bulk Power Score Calculation ---

/**
 * Calculate power scores for all items in the catalog.
 * Returns array of items with their actual and expected power scores.
 */
export async function calculateAllItemPowerScores(filters?: {
  itemType?: string
  rarity?: string
  minLevel?: number
  maxLevel?: number
  sortBy?: 'deviation' | 'power' | 'level'
  limit?: number
  offset?: number
}): Promise<{
  items: Array<{
    id: string
    catalogId: string
    itemName: string
    itemType: string
    rarity: string
    itemLevel: number
    baseStats: Record<string, number>
    powerScore: number
    expectedPower: number
    deviation: number
    deviationPercent: number
    status: 'ok' | 'overpowered' | 'underpowered'
  }>
  total: number
}> {
  const where: Record<string, unknown> = {}
  if (filters?.itemType) where.itemType = filters.itemType
  if (filters?.rarity) where.rarity = filters.rarity
  if (filters?.minLevel || filters?.maxLevel) {
    where.itemLevel = {
      ...(filters?.minLevel ? { gte: filters.minLevel } : {}),
      ...(filters?.maxLevel ? { lte: filters.maxLevel } : {}),
    }
  }

  const [items, total] = await Promise.all([
    prisma.item.findMany({
      where: where as never,
      orderBy: { itemLevel: 'asc' },
      take: filters?.limit ?? 100,
      skip: filters?.offset ?? 0,
    }),
    prisma.item.count({ where: where as never }),
  ])

  const threshold = await getGameConfig<number>('item_balance.validation_power_deviation_threshold', 0.3)

  const results = await Promise.all(
    items.map(async (item) => {
      const baseStats = (item.baseStats as Record<string, number>) ?? {}
      const powerScore = await calculateItemPowerScore(
        baseStats,
        item.rarity as Rarity,
        0,
        item.itemType as ItemType,
      )
      const expectedPower = await getExpectedPower(
        item.itemLevel,
        item.rarity as Rarity,
        item.itemType as ItemType,
      )
      const deviation = expectedPower > 0 ? (powerScore - expectedPower) / expectedPower : 0
      const deviationPercent = Math.round(deviation * 100)

      let status: 'ok' | 'overpowered' | 'underpowered' = 'ok'
      if (deviation > threshold) status = 'overpowered'
      else if (deviation < -threshold) status = 'underpowered'

      return {
        id: item.id,
        catalogId: item.catalogId,
        itemName: item.itemName,
        itemType: item.itemType,
        rarity: item.rarity,
        itemLevel: item.itemLevel,
        baseStats,
        powerScore,
        expectedPower,
        deviation: Math.round(deviation * 1000) / 1000,
        deviationPercent,
        status,
      }
    }),
  )

  // Sort
  if (filters?.sortBy === 'deviation') {
    results.sort((a, b) => Math.abs(b.deviation) - Math.abs(a.deviation))
  } else if (filters?.sortBy === 'power') {
    results.sort((a, b) => b.powerScore - a.powerScore)
  }

  return { items: results, total }
}
