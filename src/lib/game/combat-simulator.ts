// =============================================================================
// combat-simulator.ts — Combat Simulation Engine
// Runs thousands of simulated fights to test balance.
// =============================================================================

import { runCombat, type CharacterStats, type CharacterClassType, type CombatResult } from './combat'
import { calculateDerivedStatsFromConfig } from './item-balance'

// --- Types ---

export interface SimulationConfig {
  iterations: number
}

export interface CombatSimResult {
  winRateA: number
  winRateB: number
  avgTurns: number
  avgDpsA: number
  avgDpsB: number
  avgTtkA: number  // avg turns to kill B
  avgTtkB: number  // avg turns to kill A
  critRateA: number
  critRateB: number
  dodgeRateA: number
  dodgeRateB: number
  avgDamagePerHitA: number
  avgDamagePerHitB: number
}

export interface ClassMatchupResult {
  matrix: Record<string, Record<string, number>>  // class -> class -> winRate
  classes: string[]
  level: number
  gearPowerScore: number
  iterations: number
}

export interface ItemImpactResult {
  baselineDps: number
  withItemDps: number
  dpsChange: number
  dpsChangePercent: number
  baselineWinRate: number
  withItemWinRate: number
  winRateChange: number
  baselineTtk: number
  withItemTtk: number
  ttkChange: number
}

// --- Helpers ---

const STAT_KEYS = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha'] as const

/**
 * Build a character with specified stats for simulation.
 */
async function buildSimCharacter(params: {
  id: string
  name: string
  class: CharacterClassType
  level: number
  stats?: Partial<Record<typeof STAT_KEYS[number], number>>
  gearPowerScore?: number
}): Promise<CharacterStats> {
  const baseStat = 10 + (params.level - 1) * 3 / 8 // roughly 3 stat points per level spread across 8 stats

  const stats = {
    str: params.stats?.str ?? Math.round(baseStat),
    agi: params.stats?.agi ?? Math.round(baseStat),
    vit: params.stats?.vit ?? Math.round(baseStat),
    end: params.stats?.end ?? Math.round(baseStat),
    int: params.stats?.int ?? Math.round(baseStat),
    wis: params.stats?.wis ?? Math.round(baseStat),
    luk: params.stats?.luk ?? Math.round(baseStat),
    cha: params.stats?.cha ?? Math.round(baseStat),
  }

  // Apply class-specific stat emphasis
  switch (params.class) {
    case 'warrior':
      stats.str = Math.round(stats.str * 1.4)
      stats.vit = Math.round(stats.vit * 1.2)
      break
    case 'tank':
      stats.vit = Math.round(stats.vit * 1.4)
      stats.end = Math.round(stats.end * 1.4)
      break
    case 'rogue':
      stats.agi = Math.round(stats.agi * 1.4)
      stats.luk = Math.round(stats.luk * 1.2)
      break
    case 'mage':
      stats.int = Math.round(stats.int * 1.4)
      stats.wis = Math.round(stats.wis * 1.2)
      break
  }

  // Add gear bonus proportionally to power score
  if (params.gearPowerScore) {
    const gearBonus = Math.round(params.gearPowerScore / 10)
    stats.str += gearBonus
    stats.agi += gearBonus
    stats.vit += gearBonus
    stats.end += gearBonus
    stats.int += gearBonus
    stats.wis += gearBonus
  }

  const derived = await calculateDerivedStatsFromConfig(stats)

  return {
    id: params.id,
    name: params.name,
    class: params.class,
    level: params.level,
    ...stats,
    maxHp: derived.maxHp,
    armor: derived.armor,
    magicResist: derived.magicResist,
    combatStance: null,
  }
}

/**
 * Extract DPS and combat metrics from a single combat result.
 */
function analyzeCombat(
  result: CombatResult,
  idA: string,
  idB: string,
  maxHpA: number,
  maxHpB: number,
): {
  winner: 'A' | 'B'
  turns: number
  totalDamageA: number
  totalDamageB: number
  critsA: number
  critsB: number
  dodgesA: number
  dodgesB: number
  hitsA: number
  hitsB: number
} {
  let totalDamageA = 0
  let totalDamageB = 0
  let critsA = 0
  let critsB = 0
  let dodgesA = 0
  let dodgesB = 0
  let hitsA = 0
  let hitsB = 0

  for (const turn of result.turns) {
    if (turn.attackerId === idA) {
      totalDamageA += turn.damage
      if (turn.isCrit) critsA++
      if (turn.isDodge) dodgesB++
      if (!turn.isDodge) hitsA++
    } else {
      totalDamageB += turn.damage
      if (turn.isCrit) critsB++
      if (turn.isDodge) dodgesA++
      if (!turn.isDodge) hitsB++
    }
  }

  return {
    winner: result.winnerId === idA ? 'A' : 'B',
    turns: result.totalTurns,
    totalDamageA,
    totalDamageB,
    critsA,
    critsB,
    dodgesA,
    dodgesB,
    hitsA,
    hitsB,
  }
}

// --- Public API ---

/**
 * Run many combat simulations between two character configurations.
 */
export async function simulateCombat(
  charAConfig: {
    class: CharacterClassType
    level: number
    stats?: Partial<Record<typeof STAT_KEYS[number], number>>
    gearPowerScore?: number
  },
  charBConfig: {
    class: CharacterClassType
    level: number
    stats?: Partial<Record<typeof STAT_KEYS[number], number>>
    gearPowerScore?: number
  },
  iterations: number = 1000,
): Promise<CombatSimResult> {
  const charA = await buildSimCharacter({
    id: 'sim_a',
    name: 'Fighter A',
    ...charAConfig,
  })

  const charB = await buildSimCharacter({
    id: 'sim_b',
    name: 'Fighter B',
    ...charBConfig,
  })

  let winsA = 0
  let totalTurns = 0
  let totalDamageA = 0
  let totalDamageB = 0
  let totalCritsA = 0
  let totalCritsB = 0
  let totalDodgesA = 0
  let totalDodgesB = 0
  let totalHitsA = 0
  let totalHitsB = 0

  for (let i = 0; i < iterations; i++) {
    const result = runCombat(charA, charB)
    const analysis = analyzeCombat(result, 'sim_a', 'sim_b', charA.maxHp, charB.maxHp)

    if (analysis.winner === 'A') winsA++
    totalTurns += analysis.turns
    totalDamageA += analysis.totalDamageA
    totalDamageB += analysis.totalDamageB
    totalCritsA += analysis.critsA
    totalCritsB += analysis.critsB
    totalDodgesA += analysis.dodgesA
    totalDodgesB += analysis.dodgesB
    totalHitsA += analysis.hitsA
    totalHitsB += analysis.hitsB
  }

  const avgTurns = totalTurns / iterations
  const winRateA = Math.round((winsA / iterations) * 1000) / 10
  const winRateB = Math.round(((iterations - winsA) / iterations) * 1000) / 10

  return {
    winRateA,
    winRateB,
    avgTurns: Math.round(avgTurns * 10) / 10,
    avgDpsA: totalHitsA > 0 ? Math.round(totalDamageA / totalHitsA) : 0,
    avgDpsB: totalHitsB > 0 ? Math.round(totalDamageB / totalHitsB) : 0,
    avgTtkA: avgTurns > 0 ? Math.round(avgTurns * 10) / 10 : 0,
    avgTtkB: avgTurns > 0 ? Math.round(avgTurns * 10) / 10 : 0,
    critRateA: totalHitsA > 0 ? Math.round((totalCritsA / (totalHitsA + totalDodgesB)) * 1000) / 10 : 0,
    critRateB: totalHitsB > 0 ? Math.round((totalCritsB / (totalHitsB + totalDodgesA)) * 1000) / 10 : 0,
    dodgeRateA: (totalHitsB + totalDodgesA) > 0
      ? Math.round((totalDodgesA / (totalHitsB + totalDodgesA)) * 1000) / 10
      : 0,
    dodgeRateB: (totalHitsA + totalDodgesB) > 0
      ? Math.round((totalDodgesB / (totalHitsA + totalDodgesB)) * 1000) / 10
      : 0,
    avgDamagePerHitA: totalHitsA > 0 ? Math.round(totalDamageA / totalHitsA) : 0,
    avgDamagePerHitB: totalHitsB > 0 ? Math.round(totalDamageB / totalHitsB) : 0,
  }
}

/**
 * Run round-robin class matchups at a given level and gear power.
 */
export async function simulateClassMatchups(
  level: number,
  gearPowerScore: number = 0,
  iterations: number = 500,
): Promise<ClassMatchupResult> {
  const classes: CharacterClassType[] = ['warrior', 'tank', 'rogue', 'mage']
  const matrix: Record<string, Record<string, number>> = {}

  for (const classA of classes) {
    matrix[classA] = {}
    for (const classB of classes) {
      if (classA === classB) {
        matrix[classA][classB] = 50.0
        continue
      }

      const result = await simulateCombat(
        { class: classA, level, gearPowerScore },
        { class: classB, level, gearPowerScore },
        iterations,
      )

      matrix[classA][classB] = result.winRateA
    }
  }

  return {
    matrix,
    classes,
    level,
    gearPowerScore,
    iterations,
  }
}

/**
 * Simulate the impact of adding stats (from an item) to a character.
 */
export async function simulateItemImpact(
  itemStats: Record<string, number>,
  characterClass: CharacterClassType,
  characterLevel: number,
  iterations: number = 500,
): Promise<ItemImpactResult> {
  // Build enhanced character (with item stats added)
  const enhancedStats: Partial<Record<typeof STAT_KEYS[number], number>> = {}
  const baseStat = 10 + (characterLevel - 1) * 3 / 8

  for (const key of STAT_KEYS) {
    enhancedStats[key] = Math.round(baseStat) + (itemStats[key] ?? 0)
  }

  // Apply class emphasis
  switch (characterClass) {
    case 'warrior':
      enhancedStats.str = Math.round((enhancedStats.str ?? baseStat) * 1.4)
      enhancedStats.vit = Math.round((enhancedStats.vit ?? baseStat) * 1.2)
      break
    case 'tank':
      enhancedStats.vit = Math.round((enhancedStats.vit ?? baseStat) * 1.4)
      enhancedStats.end = Math.round((enhancedStats.end ?? baseStat) * 1.4)
      break
    case 'rogue':
      enhancedStats.agi = Math.round((enhancedStats.agi ?? baseStat) * 1.4)
      enhancedStats.luk = Math.round((enhancedStats.luk ?? baseStat) * 1.2)
      break
    case 'mage':
      enhancedStats.int = Math.round((enhancedStats.int ?? baseStat) * 1.4)
      enhancedStats.wis = Math.round((enhancedStats.wis ?? baseStat) * 1.2)
      break
  }

  const enhancedChar = await buildSimCharacter({
    id: 'sim_enhanced',
    name: 'Enhanced',
    class: characterClass,
    level: characterLevel,
    stats: enhancedStats,
  })

  // Create a standard opponent
  const opponent = await buildSimCharacter({
    id: 'sim_opponent',
    name: 'Opponent',
    class: 'warrior', // standard opponent
    level: characterLevel,
  })

  // Run baseline simulations
  const baselineResult = await simulateCombat(
    { class: characterClass, level: characterLevel },
    { class: 'warrior', level: characterLevel },
    iterations,
  )

  // Run enhanced simulations
  let enhancedWins = 0
  let enhancedTotalDamage = 0
  let enhancedTotalTurns = 0
  let enhancedHits = 0

  for (let i = 0; i < iterations; i++) {
    const result = runCombat(enhancedChar, opponent)
    if (result.winnerId === 'sim_enhanced') enhancedWins++
    enhancedTotalTurns += result.totalTurns

    for (const turn of result.turns) {
      if (turn.attackerId === 'sim_enhanced' && !turn.isDodge) {
        enhancedTotalDamage += turn.damage
        enhancedHits++
      }
    }
  }

  const enhancedDps = enhancedHits > 0 ? Math.round(enhancedTotalDamage / enhancedHits) : 0
  const enhancedWinRate = Math.round((enhancedWins / iterations) * 1000) / 10
  const enhancedTtk = Math.round((enhancedTotalTurns / iterations) * 10) / 10

  return {
    baselineDps: baselineResult.avgDpsA,
    withItemDps: enhancedDps,
    dpsChange: enhancedDps - baselineResult.avgDpsA,
    dpsChangePercent: baselineResult.avgDpsA > 0
      ? Math.round(((enhancedDps - baselineResult.avgDpsA) / baselineResult.avgDpsA) * 1000) / 10
      : 0,
    baselineWinRate: baselineResult.winRateA,
    withItemWinRate: enhancedWinRate,
    winRateChange: Math.round((enhancedWinRate - baselineResult.winRateA) * 10) / 10,
    baselineTtk: baselineResult.avgTtkA,
    withItemTtk: enhancedTtk,
    ttkChange: Math.round((enhancedTtk - baselineResult.avgTtkA) * 10) / 10,
  }
}
