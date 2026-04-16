/**
 * Item Balance Validator
 *
 * Validates items against balance configs, computes power scores,
 * flags outliers, and generates fix suggestions.
 */

import { prisma } from './prisma'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface FlaggedItem {
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
  status: 'overpowered' | 'underpowered'
  warnings: string[]
}

interface ValidationResult {
  totalItems: number
  validItems: number
  flaggedItems: FlaggedItem[]
  stats: {
    avgDeviation: number
    maxDeviation: number
    worstItem: string | null
    overpoweredCount: number
    underpoweredCount: number
  }
}

interface Suggestion {
  suggestedStats: Record<string, number>
  suggestedSellPrice: number
  reasoning: string[]
  currentPower: number
  targetPower: number
  adjustmentPercent: number
}

// ---------------------------------------------------------------------------
// Default stat weights and rarity multipliers
// ---------------------------------------------------------------------------

const DEFAULT_STAT_WEIGHTS: Record<string, number> = {
  str: 1.0, agi: 1.0, vit: 1.2, end: 0.8,
  int: 1.0, wis: 0.9, luk: 0.7, cha: 0.5,
}

const DEFAULT_RARITY_MULTIPLIERS: Record<string, number> = {
  common: 1.0,
  uncommon: 1.5,
  rare: 2.2,
  epic: 3.5,
  legendary: 5.5,
}

const STAT_NAMES = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha']

// ---------------------------------------------------------------------------
// Load config
// ---------------------------------------------------------------------------

async function loadBalanceConfigs(): Promise<{
  statWeights: Record<string, number>
  rarityMultipliers: Record<string, number>
  deviationThreshold: number
  levelScalingBase: number
  levelScalingExponent: number
  sellPriceByRarity: Record<string, number>
  buyPriceMultiplier: number
  powerToPriceRatio: number
}> {
  const configs = await prisma.gameConfig.findMany({
    where: {
      key: {
        in: [
          'power_stat_weights', 'rarity_multipliers', 'validation_power_deviation_threshold',
          'level_scaling_base', 'level_scaling_exponent',
          'sell_price_by_rarity', 'buy_price_multiplier', 'power_to_price_ratio',
        ],
      },
    },
  })

  const map: Record<string, unknown> = {}
  for (const c of configs) {
    map[c.key] = c.value
  }

  return {
    statWeights: (map['power_stat_weights'] as Record<string, number>) ?? DEFAULT_STAT_WEIGHTS,
    rarityMultipliers: (map['rarity_multipliers'] as Record<string, number>) ?? DEFAULT_RARITY_MULTIPLIERS,
    deviationThreshold: ((map['validation_power_deviation_threshold'] as { value?: number })?.value) ?? 20,
    levelScalingBase: ((map['level_scaling_base'] as { value?: number })?.value) ?? 1.0,
    levelScalingExponent: ((map['level_scaling_exponent'] as { value?: number })?.value) ?? 1.15,
    sellPriceByRarity: (map['sell_price_by_rarity'] as Record<string, number>) ?? { common: 10, uncommon: 25, rare: 75, epic: 200, legendary: 500 },
    buyPriceMultiplier: ((map['buy_price_multiplier'] as { value?: number })?.value) ?? 3,
    powerToPriceRatio: ((map['power_to_price_ratio'] as { value?: number })?.value) ?? 2.5,
  }
}

// ---------------------------------------------------------------------------
// Power score calculation
// ---------------------------------------------------------------------------

function calculatePowerScore(
  baseStats: Record<string, number>,
  rarity: string,
  itemLevel: number,
  statWeights: Record<string, number>,
  rarityMultipliers: Record<string, number>,
  levelScalingBase: number,
  levelScalingExponent: number
): number {
  // Weighted stat sum
  let weightedSum = 0
  for (const stat of STAT_NAMES) {
    const val = baseStats[stat] ?? 0
    const weight = statWeights[stat] ?? 1.0
    weightedSum += val * weight
  }

  // Rarity multiplier
  const rarityMul = rarityMultipliers[rarity.toLowerCase()] ?? 1.0

  // Level scaling
  const levelMul = levelScalingBase * Math.pow(itemLevel, levelScalingExponent - 1)

  return Math.round(weightedSum * rarityMul * levelMul * 10) / 10
}

function calculateExpectedPower(
  rarity: string,
  itemLevel: number,
  rarityMultipliers: Record<string, number>,
  levelScalingBase: number,
  levelScalingExponent: number
): number {
  // Expected power for a "balanced" item at this rarity/level
  // Assumes ~20 total weighted stats for a balanced item
  const baseExpected = 20
  const rarityMul = rarityMultipliers[rarity.toLowerCase()] ?? 1.0
  const levelMul = levelScalingBase * Math.pow(itemLevel, levelScalingExponent - 1)
  return Math.round(baseExpected * rarityMul * levelMul * 10) / 10
}

// ---------------------------------------------------------------------------
// Public: Validate all items
// ---------------------------------------------------------------------------

export async function validateItems(): Promise<ValidationResult> {
  const config = await loadBalanceConfigs()
  const items = await prisma.item.findMany({
    select: {
      id: true, catalogId: true, itemName: true, itemType: true,
      rarity: true, itemLevel: true, baseStats: true, sellPrice: true,
    },
  })

  const flagged: FlaggedItem[] = []
  let totalDeviation = 0
  let maxDeviation = 0
  let worstItem: string | null = null

  for (const item of items) {
    const stats = (item.baseStats as Record<string, number>) ?? {}
    const powerScore = calculatePowerScore(
      stats, item.rarity, item.itemLevel,
      config.statWeights, config.rarityMultipliers,
      config.levelScalingBase, config.levelScalingExponent
    )
    const expectedPower = calculateExpectedPower(
      item.rarity, item.itemLevel,
      config.rarityMultipliers, config.levelScalingBase, config.levelScalingExponent
    )

    const deviation = powerScore - expectedPower
    const deviationPct = expectedPower > 0 ? Math.round((Math.abs(deviation) / expectedPower) * 1000) / 10 : 0

    totalDeviation += Math.abs(deviationPct)
    if (Math.abs(deviationPct) > maxDeviation) {
      maxDeviation = Math.abs(deviationPct)
      worstItem = item.itemName
    }

    if (deviationPct > config.deviationThreshold) {
      const warnings: string[] = []
      if (deviationPct > 50) warnings.push('Extreme deviation — likely a data error')
      if (deviationPct > 30) warnings.push('Large power deviation from expected')

      // Check stat cap issues
      for (const stat of STAT_NAMES) {
        if ((stats[stat] ?? 0) > item.itemLevel * 5) {
          warnings.push(`${stat.toUpperCase()} exceeds level cap (${stats[stat]} > ${item.itemLevel * 5})`)
        }
      }

      flagged.push({
        id: item.id,
        catalogId: item.catalogId,
        itemName: item.itemName,
        itemType: item.itemType,
        rarity: item.rarity,
        itemLevel: item.itemLevel,
        baseStats: stats,
        powerScore,
        expectedPower,
        deviation,
        deviationPercent: deviationPct,
        status: deviation > 0 ? 'overpowered' : 'underpowered',
        warnings,
      })
    }
  }

  // Sort flagged by deviation (worst first)
  flagged.sort((a, b) => b.deviationPercent - a.deviationPercent)

  const overCount = flagged.filter(f => f.status === 'overpowered').length
  const underCount = flagged.filter(f => f.status === 'underpowered').length

  // Save validation run
  try {
    await prisma.balanceSimulationRun.create({
      data: {
        runType: 'item_audit',
        config: { threshold: config.deviationThreshold } as object,
        results: {
          totalItems: items.length,
          flaggedCount: flagged.length,
          overpowered: overCount,
          underpowered: underCount,
        } as object,
        summary: `${flagged.length}/${items.length} flagged (${overCount} OP, ${underCount} UP)`,
      },
    })
  } catch { /* non-critical */ }

  return {
    totalItems: items.length,
    validItems: items.length - flagged.length,
    flaggedItems: flagged,
    stats: {
      avgDeviation: items.length > 0 ? Math.round(totalDeviation / items.length * 10) / 10 : 0,
      maxDeviation: Math.round(maxDeviation * 10) / 10,
      worstItem,
      overpoweredCount: overCount,
      underpoweredCount: underCount,
    },
  }
}

// ---------------------------------------------------------------------------
// Public: Generate suggestion for a flagged item
// ---------------------------------------------------------------------------

export async function suggestFix(itemId: string): Promise<{ suggestion: Suggestion } | { error: string }> {
  const config = await loadBalanceConfigs()
  const item = await prisma.item.findUnique({
    where: { id: itemId },
    select: {
      id: true, itemName: true, itemType: true, rarity: true,
      itemLevel: true, baseStats: true, sellPrice: true,
    },
  })

  if (!item) return { error: 'Item not found' }

  const stats = (item.baseStats as Record<string, number>) ?? {}
  const currentPower = calculatePowerScore(
    stats, item.rarity, item.itemLevel,
    config.statWeights, config.rarityMultipliers,
    config.levelScalingBase, config.levelScalingExponent
  )
  const targetPower = calculateExpectedPower(
    item.rarity, item.itemLevel,
    config.rarityMultipliers, config.levelScalingBase, config.levelScalingExponent
  )

  const adjustmentPercent = Math.round(((targetPower - currentPower) / currentPower) * 1000) / 10
  const scaleFactor = targetPower / (currentPower || 1)

  // Scale stats proportionally toward target power
  const suggestedStats: Record<string, number> = {}
  const reasoning: string[] = []

  for (const stat of STAT_NAMES) {
    const original = stats[stat] ?? 0
    if (original === 0) continue
    const adjusted = Math.round(original * scaleFactor)
    const levelCap = item.itemLevel * 5
    suggestedStats[stat] = Math.min(adjusted, levelCap)

    if (suggestedStats[stat] !== original) {
      reasoning.push(`${stat.toUpperCase()}: ${original} → ${suggestedStats[stat]} (${adjusted > levelCap ? 'capped at level limit' : 'scaled proportionally'})`)
    }
  }

  // Suggested sell price
  const baseSellPrice = config.sellPriceByRarity[item.rarity.toLowerCase()] ?? 10
  const suggestedSellPrice = Math.round(baseSellPrice + targetPower * config.powerToPriceRatio)

  if (suggestedSellPrice !== item.sellPrice) {
    reasoning.push(`Sell price: ${item.sellPrice} → ${suggestedSellPrice} (based on power-to-price ratio)`)
  }

  if (reasoning.length === 0) {
    reasoning.push('Item is already at target power — no adjustments needed')
  }

  return {
    suggestion: {
      suggestedStats,
      suggestedSellPrice,
      reasoning,
      currentPower,
      targetPower,
      adjustmentPercent,
    },
  }
}

// ---------------------------------------------------------------------------
// Public: Apply suggestion to an item
// ---------------------------------------------------------------------------

export async function applySuggestion(
  itemId: string,
  suggestedStats: Record<string, number>,
  suggestedSellPrice: number,
  adminId: string
): Promise<{ success: boolean }> {
  await prisma.item.update({
    where: { id: itemId },
    data: {
      baseStats: suggestedStats,
      sellPrice: suggestedSellPrice,
    },
  })

  // Log the change
  try {
    await prisma.adminLog.create({
      data: {
        action: 'apply_balance_suggestion',
        target: itemId,
        details: { suggestedStats, suggestedSellPrice } as object,
        adminId,
      },
    })
  } catch { /* non-critical */ }

  return { success: true }
}
