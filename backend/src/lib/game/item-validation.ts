// =============================================================================
// item-validation.ts — Item Balance Validation Engine
// Detects broken/overpowered/underpowered items and suggests fixes.
// =============================================================================

import { prisma } from '@/lib/prisma'
import { getGameConfig } from './config'
import {
  calculateItemPowerScore,
  getExpectedPower,
  getStatRangeForLevel,
} from './item-balance'

// --- Types ---

type Rarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary'
type ItemType =
  | 'weapon' | 'helmet' | 'chest' | 'gloves' | 'legs' | 'boots'
  | 'accessory' | 'amulet' | 'belt' | 'relic' | 'necklace' | 'ring'

export interface ValidationResult {
  isValid: boolean
  powerScore: number
  expectedPower: number
  deviation: number
  deviationPercent: number
  status: 'ok' | 'overpowered' | 'underpowered'
  warnings: string[]
}

export interface BulkValidationResult {
  totalItems: number
  validItems: number
  flaggedItems: Array<{
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
  }>
  stats: {
    avgDeviation: number
    maxDeviation: number
    worstItem: string | null
    overpoweredCount: number
    underpoweredCount: number
  }
}

export interface StatSuggestion {
  suggestedStats: Record<string, number>
  suggestedSellPrice: number
  reasoning: string[]
  currentPower: number
  targetPower: number
  adjustmentPercent: number
}

// --- Single Item Validation ---

/**
 * Validate a single item's balance.
 */
export async function validateItemBalance(
  item: {
    baseStats: Record<string, number>
    rarity: string
    itemLevel: number
    itemType: string
  },
  upgradeLevel: number = 0,
): Promise<ValidationResult> {
  const threshold = await getGameConfig<number>('item_balance.validation_power_deviation_threshold', 0.3)
  const statCapMult = await getGameConfig<number>('item_balance.validation_stat_cap_multiplier', 3.0)

  const warnings: string[] = []

  // Calculate power scores
  const powerScore = await calculateItemPowerScore(
    item.baseStats,
    item.rarity as Rarity,
    upgradeLevel,
    item.itemType as ItemType,
  )

  const expectedPower = await getExpectedPower(
    item.itemLevel,
    item.rarity as Rarity,
    item.itemType as ItemType,
  )

  const deviation = expectedPower > 0 ? (powerScore - expectedPower) / expectedPower : 0
  const deviationPercent = Math.round(deviation * 100)

  // Check stat ranges
  const range = await getStatRangeForLevel(item.itemLevel)
  for (const [stat, value] of Object.entries(item.baseStats)) {
    if (value > range.maxStat * statCapMult) {
      warnings.push(`${stat} (${value}) exceeds ${statCapMult}x bracket max (${range.maxStat})`)
    }
    if (value < 0) {
      warnings.push(`${stat} has negative value (${value})`)
    }
  }

  // Check power deviation
  let status: 'ok' | 'overpowered' | 'underpowered' = 'ok'
  if (deviation > threshold) {
    status = 'overpowered'
    warnings.push(`Power score ${powerScore} exceeds expected ${expectedPower} by ${deviationPercent}%`)
  } else if (deviation < -threshold) {
    status = 'underpowered'
    warnings.push(`Power score ${powerScore} is below expected ${expectedPower} by ${Math.abs(deviationPercent)}%`)
  }

  // Check for zero stats
  if (Object.keys(item.baseStats).length === 0) {
    warnings.push('Item has no base stats')
  }

  const isValid = status === 'ok' && warnings.length === 0

  return {
    isValid,
    powerScore,
    expectedPower,
    deviation: Math.round(deviation * 1000) / 1000,
    deviationPercent,
    status,
    warnings,
  }
}

// --- Bulk Validation ---

/**
 * Validate all items in the catalog.
 */
export async function validateAllItems(): Promise<BulkValidationResult> {
  const items = await prisma.item.findMany({
    where: {
      itemType: { not: 'consumable' },
    },
  })

  const flaggedItems: BulkValidationResult['flaggedItems'] = []
  let totalDeviation = 0
  let maxDeviation = 0
  let worstItem: string | null = null
  let overpoweredCount = 0
  let underpoweredCount = 0

  for (const item of items) {
    const baseStats = (item.baseStats as Record<string, number>) ?? {}
    const result = await validateItemBalance({
      baseStats,
      rarity: item.rarity,
      itemLevel: item.itemLevel,
      itemType: item.itemType,
    })

    totalDeviation += Math.abs(result.deviation)

    if (Math.abs(result.deviation) > maxDeviation) {
      maxDeviation = Math.abs(result.deviation)
      worstItem = item.itemName
    }

    if (result.status !== 'ok') {
      if (result.status === 'overpowered') overpoweredCount++
      else underpoweredCount++

      flaggedItems.push({
        id: item.id,
        catalogId: item.catalogId,
        itemName: item.itemName,
        itemType: item.itemType,
        rarity: item.rarity,
        itemLevel: item.itemLevel,
        baseStats,
        powerScore: result.powerScore,
        expectedPower: result.expectedPower,
        deviation: result.deviation,
        deviationPercent: result.deviationPercent,
        status: result.status,
        warnings: result.warnings,
      })
    }
  }

  // Sort flagged items by absolute deviation (worst first)
  flaggedItems.sort((a, b) => Math.abs(b.deviation) - Math.abs(a.deviation))

  return {
    totalItems: items.length,
    validItems: items.length - flaggedItems.length,
    flaggedItems,
    stats: {
      avgDeviation: items.length > 0 ? Math.round((totalDeviation / items.length) * 1000) / 1000 : 0,
      maxDeviation: Math.round(maxDeviation * 1000) / 1000,
      worstItem,
      overpoweredCount,
      underpoweredCount,
    },
  }
}

// --- Suggest Stat Adjustments ---

/**
 * Suggest stat changes to bring an item within expected balance range.
 */
export async function suggestStatAdjustments(
  item: {
    id: string
    baseStats: Record<string, number>
    rarity: string
    itemLevel: number
    itemType: string
    sellPrice: number
  },
): Promise<StatSuggestion> {
  const currentPower = await calculateItemPowerScore(
    item.baseStats,
    item.rarity as Rarity,
    0,
    item.itemType as ItemType,
  )

  const targetPower = await getExpectedPower(
    item.itemLevel,
    item.rarity as Rarity,
    item.itemType as ItemType,
  )

  const reasoning: string[] = []
  const suggestedStats = { ...item.baseStats }

  if (targetPower === 0 || currentPower === 0) {
    return {
      suggestedStats,
      suggestedSellPrice: item.sellPrice,
      reasoning: ['Unable to calculate power scores'],
      currentPower,
      targetPower,
      adjustmentPercent: 0,
    }
  }

  // Calculate the scaling factor to bring current power to target
  const scaleFactor = targetPower / currentPower
  const adjustmentPercent = Math.round((scaleFactor - 1) * 100)

  if (Math.abs(adjustmentPercent) < 5) {
    reasoning.push('Item is within acceptable balance range (< 5% deviation)')
    return {
      suggestedStats,
      suggestedSellPrice: item.sellPrice,
      reasoning,
      currentPower,
      targetPower,
      adjustmentPercent: 0,
    }
  }

  // Scale each stat proportionally
  for (const [stat, value] of Object.entries(suggestedStats)) {
    const newValue = Math.max(1, Math.round(value * scaleFactor))
    if (newValue !== value) {
      const change = newValue - value
      const dir = change > 0 ? 'Increase' : 'Reduce'
      reasoning.push(`${dir} ${stat} from ${value} to ${newValue} (${change > 0 ? '+' : ''}${change})`)
      suggestedStats[stat] = newValue
    }
  }

  // Calculate suggested sell price from the rarity-based formula
  const DEFAULT_SELL_PRICES: Record<string, number> = {
    common: 10, uncommon: 25, rare: 60, epic: 150, legendary: 400,
  }
  const sellPriceByRarity = await getGameConfig<Record<string, number>>(
    'item_balance.sell_price_by_rarity',
    DEFAULT_SELL_PRICES,
  )
  const suggestedSellPrice = (sellPriceByRarity[item.rarity] ?? 10) * item.itemLevel

  if (suggestedSellPrice !== item.sellPrice) {
    reasoning.push(`Adjust sell price from ${item.sellPrice} to ${suggestedSellPrice}`)
  }

  return {
    suggestedStats,
    suggestedSellPrice,
    reasoning,
    currentPower,
    targetPower,
    adjustmentPercent,
  }
}
