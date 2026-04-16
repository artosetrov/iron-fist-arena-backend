/**
 * Combat Simulation Engine
 *
 * Runs simplified 1v1 combat simulations using the game's balance parameters.
 * Used by admin panel for balance validation and "what-if" scenarios.
 */

import { prisma } from './prisma'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface CharacterBuild {
  class: string
  level: number
  gearPowerScore: number
}

interface CombatStats {
  hp: number
  attack: number
  defense: number
  speed: number
  critChance: number
  dodgeChance: number
  damageReduction: number
}

interface SimulationResult {
  winRateA: number
  winRateB: number
  draws: number
  avgTurns: number
  avgDamagePerHitA: number
  avgDamagePerHitB: number
  critRateA: number
  critRateB: number
  dodgeRateA: number
  dodgeRateB: number
}

// ---------------------------------------------------------------------------
// Class base stats per level (simplified scaling)
// ---------------------------------------------------------------------------

const CLASS_BASE_STATS: Record<string, {
  str: number; agi: number; vit: number; int: number; luk: number; cha: number
}> = {
  warrior: { str: 8, agi: 4, vit: 7, int: 2, luk: 3, cha: 3 },
  rogue:   { str: 4, agi: 8, vit: 4, int: 3, luk: 6, cha: 3 },
  mage:    { str: 2, agi: 4, vit: 3, int: 8, luk: 4, cha: 5 },
  tank:    { str: 5, agi: 2, vit: 9, int: 2, luk: 2, cha: 4 },
}

// ---------------------------------------------------------------------------
// Load balance config from DB (with cache)
// ---------------------------------------------------------------------------

let configCache: Record<string, Record<string, unknown>> | null = null

async function getBalanceConfig(): Promise<Record<string, Record<string, unknown>>> {
  if (configCache) return configCache

  const configs = await prisma.gameConfig.findMany()
  const map: Record<string, Record<string, unknown>> = {}
  for (const c of configs) {
    map[c.key] = (c.value as Record<string, unknown>) ?? {}
  }
  configCache = map

  // Auto-expire cache after 30s
  setTimeout(() => { configCache = null }, 30_000)

  return map
}

function getNum(obj: Record<string, unknown> | undefined, key: string, fallback: number): number {
  if (!obj) return fallback
  const v = obj[key]
  return typeof v === 'number' ? v : fallback
}

// ---------------------------------------------------------------------------
// Build combat stats from character build + balance config
// ---------------------------------------------------------------------------

function buildCombatStats(build: CharacterBuild, config: Record<string, Record<string, unknown>>): CombatStats {
  const base = CLASS_BASE_STATS[build.class] ?? CLASS_BASE_STATS.warrior
  const lvl = build.level

  // Scale base stats by level
  const str = base.str + Math.floor(base.str * (lvl - 1) * 0.15)
  const agi = base.agi + Math.floor(base.agi * (lvl - 1) * 0.15)
  const vit = base.vit + Math.floor(base.vit * (lvl - 1) * 0.15)
  const int_ = base.int + Math.floor(base.int * (lvl - 1) * 0.15)
  const luk = base.luk + Math.floor(base.luk * (lvl - 1) * 0.15)

  const combat = config['combat'] ?? {}

  // HP calculation
  const hpBase = getNum(combat, 'hpBase', 100)
  const hpPerVit = getNum(combat, 'hpPerVit', 10)
  const hp = hpBase + vit * hpPerVit + lvl * 5

  // Attack — class-dependent
  const isPhy = build.class === 'warrior' || build.class === 'rogue' || build.class === 'tank'
  const baseAttack = isPhy ? str * 2.5 + build.gearPowerScore * 0.5 : int_ * 2.5 + build.gearPowerScore * 0.5

  // Defense from VIT/gear
  const defense = vit * 1.5 + build.gearPowerScore * 0.3

  // Speed from AGI
  const speed = agi

  // Crit chance
  const critPerLuk = getNum(combat, 'critPerLuk', 0.7)
  const critPerAgi = getNum(combat, 'critPerAgi', 0.15)
  const critChance = Math.min(luk * critPerLuk + agi * critPerAgi, 50) / 100

  // Dodge chance
  const dodgePerAgi = getNum(combat, 'dodgePerAgi', 0.2)
  const dodgePerLuk = getNum(combat, 'dodgePerLuk', 0.1)
  const dodgeChance = Math.min(agi * dodgePerAgi + luk * dodgePerLuk, 30) / 100

  // Tank DR
  const tankDr = build.class === 'tank' ? getNum(combat, 'tankDamageReduction', 0.85) : 1

  return {
    hp,
    attack: Math.round(baseAttack),
    defense: Math.round(defense),
    speed,
    critChance,
    dodgeChance,
    damageReduction: tankDr,
  }
}

// ---------------------------------------------------------------------------
// Run a single combat between two stat blocks
// ---------------------------------------------------------------------------

function runSingleCombat(
  a: CombatStats,
  b: CombatStats,
  maxTurns: number,
  config: Record<string, Record<string, unknown>>
): { winner: 'a' | 'b' | 'draw'; turns: number; stats: {
  damageDealtA: number; damageDealtB: number
  critsA: number; critsB: number
  dodgesA: number; dodgesB: number
  hitsA: number; hitsB: number
}} {
  let hpA = a.hp
  let hpB = b.hp
  let turns = 0

  const combat = config['combat'] ?? {}
  const critMul = getNum(combat, 'critMultiplier', 1.5)
  const minDmg = getNum(combat, 'minDamage', 1)
  const dmgVariance = getNum(combat, 'damageVariance', 0.15)

  const stats = {
    damageDealtA: 0, damageDealtB: 0,
    critsA: 0, critsB: 0,
    dodgesA: 0, dodgesB: 0,
    hitsA: 0, hitsB: 0,
  }

  // Determine who goes first by speed
  const aFirst = a.speed >= b.speed

  while (hpA > 0 && hpB > 0 && turns < maxTurns) {
    turns++

    // Attacker and defender for this turn
    const [atk, def, isA] = aFirst
      ? (turns % 2 === 1 ? [a, b, true] : [b, a, false])
      : (turns % 2 === 1 ? [b, a, false] : [a, b, true])

    // Dodge check
    if (Math.random() < def.dodgeChance) {
      if (isA) stats.dodgesB++; else stats.dodgesA++
      continue
    }

    // Calculate damage
    const variance = 1 + (Math.random() * 2 - 1) * dmgVariance
    let dmg = Math.max(minDmg, (atk.attack - def.defense * 0.4) * variance)

    // Crit check
    const isCrit = Math.random() < atk.critChance
    if (isCrit) {
      dmg *= critMul
      if (isA) stats.critsA++; else stats.critsB++
    }

    // Tank DR
    dmg *= def.damageReduction

    dmg = Math.round(dmg)

    if (isA) {
      hpB -= dmg
      stats.damageDealtA += dmg
      stats.hitsA++
    } else {
      hpA -= dmg
      stats.damageDealtB += dmg
      stats.hitsB++
    }
  }

  const winner = hpA <= 0 && hpB <= 0 ? 'draw' : hpA <= 0 ? 'b' : hpB <= 0 ? 'a' : 'draw'
  return { winner, turns, stats }
}

// ---------------------------------------------------------------------------
// Public API: 1v1 Combat Simulation
// ---------------------------------------------------------------------------

export async function simulateCombat(
  charA: CharacterBuild,
  charB: CharacterBuild,
  iterations: number
): Promise<SimulationResult & { saved: boolean }> {
  const config = await getBalanceConfig()
  const maxTurns = getNum(config['combat'] ?? {}, 'maxTurns', 50)

  const statsA = buildCombatStats(charA, config)
  const statsB = buildCombatStats(charB, config)

  let winsA = 0, winsB = 0, draws = 0
  let totalTurns = 0
  let totalDmgA = 0, totalDmgB = 0
  let totalCritsA = 0, totalCritsB = 0
  let totalDodgesA = 0, totalDodgesB = 0
  let totalHitsA = 0, totalHitsB = 0

  for (let i = 0; i < iterations; i++) {
    const result = runSingleCombat(statsA, statsB, maxTurns, config)
    if (result.winner === 'a') winsA++
    else if (result.winner === 'b') winsB++
    else draws++

    totalTurns += result.turns
    totalDmgA += result.stats.damageDealtA
    totalDmgB += result.stats.damageDealtB
    totalCritsA += result.stats.critsA
    totalCritsB += result.stats.critsB
    totalDodgesA += result.stats.dodgesA
    totalDodgesB += result.stats.dodgesB
    totalHitsA += result.stats.hitsA
    totalHitsB += result.stats.hitsB
  }

  const simResult = {
    winRateA: Math.round((winsA / iterations) * 1000) / 10,
    winRateB: Math.round((winsB / iterations) * 1000) / 10,
    draws: Math.round((draws / iterations) * 1000) / 10,
    avgTurns: Math.round((totalTurns / iterations) * 10) / 10,
    avgDamagePerHitA: totalHitsA > 0 ? Math.round(totalDmgA / totalHitsA) : 0,
    avgDamagePerHitB: totalHitsB > 0 ? Math.round(totalDmgB / totalHitsB) : 0,
    critRateA: totalHitsA > 0 ? Math.round((totalCritsA / (totalHitsA + totalCritsA)) * 1000) / 10 : 0,
    critRateB: totalHitsB > 0 ? Math.round((totalCritsB / (totalHitsB + totalCritsB)) * 1000) / 10 : 0,
    dodgeRateA: iterations > 0 ? Math.round((totalDodgesA / iterations) * 100) / 100 : 0,
    dodgeRateB: iterations > 0 ? Math.round((totalDodgesB / iterations) * 100) / 100 : 0,
  }

  // Save simulation run
  let saved = false
  try {
    await prisma.balanceSimulationRun.create({
      data: {
        runType: 'combat_sim',
        config: { charA, charB, iterations } as object,
        results: simResult as object,
        summary: `${charA.class} L${charA.level} vs ${charB.class} L${charB.level}: ${simResult.winRateA}%/${simResult.winRateB}%`,
      },
    })
    saved = true
  } catch { /* non-critical */ }

  return { ...simResult, saved }
}

// ---------------------------------------------------------------------------
// Public API: Class Matchup Matrix
// ---------------------------------------------------------------------------

export async function simulateMatchups(
  level: number,
  gearPowerScore: number,
  iterations: number
): Promise<{ matrix: Record<string, Record<string, number>>; classes: string[]; saved: boolean }> {
  const classes = ['warrior', 'rogue', 'mage', 'tank']
  const matrix: Record<string, Record<string, number>> = {}

  for (const c1 of classes) {
    matrix[c1] = {}
    for (const c2 of classes) {
      if (c1 === c2) {
        matrix[c1][c2] = 50
        continue
      }
      // Check if we already computed the inverse
      if (matrix[c2]?.[c1] !== undefined) {
        matrix[c1][c2] = Math.round((100 - matrix[c2][c1]) * 10) / 10
        continue
      }
      const result = await simulateCombat(
        { class: c1, level, gearPowerScore },
        { class: c2, level, gearPowerScore },
        iterations
      )
      matrix[c1][c2] = result.winRateA
    }
  }

  // Save
  let saved = false
  try {
    await prisma.balanceSimulationRun.create({
      data: {
        runType: 'class_matchups',
        config: { level, gearPowerScore, iterations } as object,
        results: { matrix, classes } as object,
        summary: `L${level} GP${gearPowerScore} matchup matrix (${iterations} iters)`,
      },
    })
    saved = true
  } catch { /* non-critical */ }

  return { matrix, classes, saved }
}

// ---------------------------------------------------------------------------
// Public API: Item Impact Analysis
// ---------------------------------------------------------------------------

export async function simulateItemImpact(
  itemStats: Record<string, number>,
  characterClass: string,
  characterLevel: number
): Promise<{
  dpsChange: number
  winRateChange: number
  ttkChange: number
  beforeStats: CombatStats
  afterStats: CombatStats
  saved: boolean
}> {
  const config = await getBalanceConfig()
  const iterations = 500

  // Baseline: no item gear
  const baseResult = await simulateCombat(
    { class: characterClass, level: characterLevel, gearPowerScore: 0 },
    { class: 'warrior', level: characterLevel, gearPowerScore: 0 },
    iterations
  )

  // With item: sum stats as approximate gear power score
  const totalStats = Object.values(itemStats).reduce((a, b) => a + b, 0)
  const gearPower = totalStats * 2 // rough mapping

  const withItemResult = await simulateCombat(
    { class: characterClass, level: characterLevel, gearPowerScore: gearPower },
    { class: 'warrior', level: characterLevel, gearPowerScore: 0 },
    iterations
  )

  const beforeStats = buildCombatStats(
    { class: characterClass, level: characterLevel, gearPowerScore: 0 }, config
  )
  const afterStats = buildCombatStats(
    { class: characterClass, level: characterLevel, gearPowerScore: gearPower }, config
  )

  const dpsChange = baseResult.avgDamagePerHitA > 0
    ? Math.round(((withItemResult.avgDamagePerHitA - baseResult.avgDamagePerHitA) / baseResult.avgDamagePerHitA) * 1000) / 10
    : 0

  const winRateChange = Math.round((withItemResult.winRateA - baseResult.winRateA) * 10) / 10

  const ttkBefore = baseResult.avgTurns
  const ttkAfter = withItemResult.avgTurns
  const ttkChange = ttkBefore > 0
    ? Math.round(((ttkAfter - ttkBefore) / ttkBefore) * 1000) / 10
    : 0

  // Save
  let saved = false
  try {
    await prisma.balanceSimulationRun.create({
      data: {
        runType: 'item_impact',
        config: { itemStats, characterClass, characterLevel } as object,
        results: { dpsChange, winRateChange, ttkChange } as object,
        summary: `${characterClass} L${characterLevel}: DPS ${dpsChange > 0 ? '+' : ''}${dpsChange}%, WR ${winRateChange > 0 ? '+' : ''}${winRateChange}%`,
      },
    })
    saved = true
  } catch { /* non-critical */ }

  return { dpsChange, winRateChange, ttkChange, beforeStats, afterStats, saved }
}
