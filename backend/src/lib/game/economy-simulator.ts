// =============================================================================
// economy-simulator.ts — Pure Monte-Carlo gold income/sink simulator
// =============================================================================
//
// Purpose: produce a defensible "sink ratio" number for W3.D3 balance changes
// without needing a live DB or full combat engine. The simulator is
// deliberately cheap and conservative — we are NOT trying to match real player
// behavior perfectly, we are trying to answer: "given the tuning numbers in
// balance.ts, does a plausible day of play drain 55-80% of the gold earned?"
//
// Why pure (no Prisma, no HTTP, no RNG that touches global state)?
//   1. Must run inside vitest without hitting a DB.
//   2. Must be deterministic when a seed is passed — CI needs reproducibility.
//   3. Must use the EXACT balance formulas from balance.ts, so that a future
//      balance change is reflected in the simulator automatically.
//
// Archetypes — derived from the ECONOMY.md monetization tiers:
//   - casual:  ~2 PvP + light farm per day, no refill
//   - active:  ~8 PvP + daily quests + dungeon runs, occasional refill
//   - whale:   ~18 PvP + dungeon grind + 2 stamina refills/day + upgrades
//
// The simulator is intentionally optimistic on INCOME (so sink_ratio is a
// LOWER bound: if even the whale drains 70% with inflated income, the real
// economy is fine). Sinks are modeled at expected value — no RNG on repair
// frequency or upgrade failures; we use the exponential upgrade curve.
//
// All numbers feed from balance.ts. Do NOT hardcode values here.

import {
  GOLD_REWARDS,
  DAILY_LOGIN_REWARDS,
  FIRST_WIN_BONUS,
  REPAIR_COSTS,
  UPGRADE_COSTS,
  CHA_GOLD_BONUS_CAP,
  chaGoldBonus,
  streakGoldMultiplier,
  lossStreakGoldMultiplier,
  levelScaledReward,
  repairCost,
  upgradeCost,
  UPGRADE_CHANCES,
} from './balance'

// -----------------------------------------------------------------------------
// Types
// -----------------------------------------------------------------------------

export interface Archetype {
  /** Short key: 'casual' | 'active' | 'whale' — used for reporting. */
  name: string
  /** Expected character level (drives levelScaledReward). */
  level: number
  /** CHA stat value — drives gold bonus. */
  cha: number
  /** PvP matches per day (wins + losses combined). */
  pvpMatchesPerDay: number
  /** Win rate over PvP matches — 0.5 = average. */
  pvpWinRate: number
  /** Dungeon clears per day (used for gold via floor rewards and for repair wear). */
  dungeonClearsPerDay: number
  /** Average gold per dungeon clear (floor-scaled, external input to keep this module pure). */
  avgDungeonGold: number
  /** Daily quest completions — each gives ~quest_reward gold. */
  dailyQuestCompletions: number
  /** Average gold per daily quest reward. */
  avgQuestGold: number
  /** Fraction of days the player claims daily login reward. */
  dailyLoginProbability: number
  /** Stamina potions (small) consumed per day. */
  staminaPotionsSmallPerDay: number
  /** HP potions (small) consumed per day. */
  healthPotionsSmallPerDay: number
  /** Stamina refills via gems — NOT a gold sink, excluded from model. */
  /** Upgrade attempts per day (gold sink). */
  upgradeAttemptsPerDay: number
  /** Current upgrade level the player is trying to push from (drives exponential cost). */
  avgUpgradePlusLevel: number
  /** Repairs per day (full-gear repair — 7 item slots). */
  repairCyclesPerDay: number
  /** Average item level of equipped gear (repair cost scales with item level). */
  avgItemLevel: number
  /** Average item rarity for repair cost (string keys matching REPAIR_COSTS.RARITY_MULTIPLIERS). */
  avgItemRarity: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary'
}

export interface DayResult {
  gold_in: number
  gold_out: number
  sink_ratio: number
}

export interface ArchetypeReport {
  name: string
  days: number
  avg_gold_in_per_day: number
  avg_gold_out_per_day: number
  sink_ratio: number
  cumulative_net: number
}

// -----------------------------------------------------------------------------
// Archetypes (defaults — exported so tests and scripts share the same baseline)
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Default archetypes — calibrated against ECONOMY.md expected income/sink bands.
// Numbers are a mean over ~30 days of play; day-to-day variance is handled by
// the 1000-player Monte-Carlo loop, not by fuzzing individual fields.
//
// Key realism constraints applied (vs the naive "everyone always streaks" model):
//   - effectiveStreakWinIndex = 2 (50th-percentile streak length for a p=0.5..0.6
//     Bernoulli sequence) — most fights are NOT in a streak of 3+.
//   - repairCyclesPerDay reflects item durability (~100 → full-set repair every
//     ~12-14 fights for an active player, so 0.15-0.25 full cycles per day).
//   - upgradeAttemptsPerDay counts ALL attempts, not just successes. Whales push
//     +8 with ~15-25% success, so 1.5 attempts/day is realistic.
// -----------------------------------------------------------------------------

export const CASUAL_ARCHETYPE: Archetype = {
  name: 'casual',
  level: 15,
  cha: 12,                          // starter CHA allocation
  pvpMatchesPerDay: 2,
  pvpWinRate: 0.5,
  dungeonClearsPerDay: 0.7,         // not every day
  avgDungeonGold: 90,
  dailyQuestCompletions: 1,
  avgQuestGold: 120,
  dailyLoginProbability: 0.7,
  staminaPotionsSmallPerDay: 0.15,
  healthPotionsSmallPerDay: 0.2,
  upgradeAttemptsPerDay: 0.3,
  avgUpgradePlusLevel: 3,
  repairCyclesPerDay: 0.10,         // full-set repair ~once every 10 days
  avgItemLevel: 10,
  avgItemRarity: 'uncommon',
}

export const ACTIVE_ARCHETYPE: Archetype = {
  name: 'active',
  level: 30,
  cha: 25,
  pvpMatchesPerDay: 7,
  pvpWinRate: 0.55,
  dungeonClearsPerDay: 3,
  avgDungeonGold: 180,
  dailyQuestCompletions: 3,
  avgQuestGold: 140,
  dailyLoginProbability: 0.95,
  staminaPotionsSmallPerDay: 0.6,
  healthPotionsSmallPerDay: 0.8,
  upgradeAttemptsPerDay: 1.0,
  avgUpgradePlusLevel: 5,
  repairCyclesPerDay: 0.15,         // full set every ~7 days
  avgItemLevel: 25,
  avgItemRarity: 'rare',
}

export const WHALE_ARCHETYPE: Archetype = {
  name: 'whale',
  level: 45,
  cha: 45,                          // still high but under 60 DR threshold
  pvpMatchesPerDay: 15,
  pvpWinRate: 0.6,
  dungeonClearsPerDay: 7,
  avgDungeonGold: 260,
  dailyQuestCompletions: 4,
  avgQuestGold: 180,
  dailyLoginProbability: 1.0,
  staminaPotionsSmallPerDay: 1.2,
  healthPotionsSmallPerDay: 1.8,
  upgradeAttemptsPerDay: 1.4,
  avgUpgradePlusLevel: 8,           // pushes +9, 25% success → 4x attempts per success
  repairCyclesPerDay: 0.22,         // full set every ~4-5 days — heavy PvP wear
  avgItemLevel: 40,
  avgItemRarity: 'epic',
}

export const DEFAULT_ARCHETYPES: readonly Archetype[] = [
  CASUAL_ARCHETYPE,
  ACTIVE_ARCHETYPE,
  WHALE_ARCHETYPE,
] as const

// -----------------------------------------------------------------------------
// Consumable prices — must match admin seed config.ts W3.D3 values.
// Kept as a local constant because the canonical runtime values live in the
// GameConfig table; pulling them from DB would break test purity.
// -----------------------------------------------------------------------------

export const SIM_CONSUMABLE_PRICES = {
  stamina_potion_small: 125,
  health_potion_small: 190,
} as const

// -----------------------------------------------------------------------------
// Pure deterministic RNG (mulberry32) — same input → same output.
// -----------------------------------------------------------------------------

function mulberry32(seed: number): () => number {
  let a = seed >>> 0
  return function () {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

// -----------------------------------------------------------------------------
// Per-day income model
// -----------------------------------------------------------------------------

/**
 * Simulate one day of income for one archetype.
 * Optimistic assumptions (intentional — we want sink_ratio to be a lower bound):
 *   - Every PvP fight benefits from average streak bonus (mid-tier).
 *   - CHA bonus is applied at full curve value.
 *   - Level scaling is full.
 *   - First-win-of-day bonus always fires.
 */
export function simulateDayIncome(a: Archetype, rng: () => number): number {
  let gold = 0

  // Daily login — gold entries only; other rewards (potions, gems) are not gold.
  if (rng() < a.dailyLoginProbability) {
    for (const r of DAILY_LOGIN_REWARDS) {
      if (r.type === 'gold') {
        // Over 7 days you see each entry once; flatten to per-day expected value.
        gold += r.amount / DAILY_LOGIN_REWARDS.length
      }
    }
  }

  // PvP — wins and losses split by winRate
  const wins = a.pvpMatchesPerDay * a.pvpWinRate
  const losses = a.pvpMatchesPerDay - wins

  // Effective streak bonus — NOT streak(5). Expected streak length for a
  // p≈0.5 Bernoulli process is ~2, so most fights are at streak index 0-2
  // (no bonus) and only ~20-30% of fights are in a 3+ run. Use streak(3)
  // weighted at 25% as an honest expected-value average.
  const avgWinStreakBonus = streakGoldMultiplier(3) * 0.25
  const avgLossRecoveryBonus = lossStreakGoldMultiplier(3) * 0.25

  const pvpWinBase = levelScaledReward(GOLD_REWARDS.PVP_WIN_BASE, a.level)
  const pvpLossBase = levelScaledReward(GOLD_REWARDS.PVP_LOSS_BASE, a.level)

  // Apply streak bonus to wins, loss-streak recovery to the first win after losses
  let pvpGold = 0
  pvpGold += wins * pvpWinBase * (1 + avgWinStreakBonus)
  pvpGold += losses * pvpLossBase
  // Recovery: model ONE recovered win per simulated day with a loss streak.
  pvpGold += pvpWinBase * avgLossRecoveryBonus * Math.min(1, losses / 3)

  // First win of the day — doubles the first PvP win of the day.
  if (wins >= 1) {
    pvpGold += pvpWinBase * (FIRST_WIN_BONUS.GOLD_MULT - 1)
  }

  // CHA bonus — applied to all PvP gold. Use the pure function to stay in sync.
  pvpGold = chaGoldBonus(Math.floor(pvpGold), a.cha)

  gold += pvpGold

  // Dungeon clears — flat average, level-scaled
  gold += a.dungeonClearsPerDay * levelScaledReward(a.avgDungeonGold, a.level)

  // Daily quests — flat
  gold += a.dailyQuestCompletions * a.avgQuestGold

  return Math.floor(gold)
}

// -----------------------------------------------------------------------------
// Per-day sink model
// -----------------------------------------------------------------------------

/**
 * Simulate one day of gold sinks for one archetype.
 * Sinks modeled:
 *   - Repair: cost per full-gear repair × repairCyclesPerDay × 7 equipment slots
 *   - Upgrade: cost per attempt via UPGRADE_COSTS exponential (gold burned even
 *     on failure — we use the attempt count, not successes)
 *   - Consumables: stamina and health potions at the W3.D3 price points
 */
export function simulateDaySinks(a: Archetype): number {
  let gold = 0

  // Repair — model a "full gear repair" at repairCyclesPerDay, ~7 slots per full set.
  const equipmentSlots = 7
  const costPerItem = repairCost(a.avgItemLevel, a.avgItemRarity)
  gold += a.repairCyclesPerDay * equipmentSlots * costPerItem

  // Upgrade attempts at avgUpgradePlusLevel — exponential cost, attempts > successes.
  // We count ALL attempted upgrades (failed attempts still burn gold).
  gold += a.upgradeAttemptsPerDay * upgradeCost(a.avgUpgradePlusLevel)

  // Consumables
  gold += a.staminaPotionsSmallPerDay * SIM_CONSUMABLE_PRICES.stamina_potion_small
  gold += a.healthPotionsSmallPerDay * SIM_CONSUMABLE_PRICES.health_potion_small

  return Math.floor(gold)
}

// -----------------------------------------------------------------------------
// Multi-day / multi-player run
// -----------------------------------------------------------------------------

export interface SimulatorOptions {
  /** Number of simulated players per archetype. */
  playersPerArchetype: number
  /** Number of days per player. */
  days: number
  /** Deterministic seed for reproducibility. */
  seed: number
}

export interface SimulatorResult {
  archetypes: ArchetypeReport[]
  total_gold_in: number
  total_gold_out: number
  overall_sink_ratio: number
}

export function runEconomySimulation(
  archetypes: readonly Archetype[],
  options: SimulatorOptions,
): SimulatorResult {
  const rng = mulberry32(options.seed)

  const reports: ArchetypeReport[] = []
  let totalIn = 0
  let totalOut = 0

  for (const archetype of archetypes) {
    let archIn = 0
    let archOut = 0
    const playerDays = options.playersPerArchetype * options.days

    for (let p = 0; p < options.playersPerArchetype; p++) {
      for (let d = 0; d < options.days; d++) {
        archIn += simulateDayIncome(archetype, rng)
        archOut += simulateDaySinks(archetype)
      }
    }

    reports.push({
      name: archetype.name,
      days: options.days,
      avg_gold_in_per_day: archIn / playerDays,
      avg_gold_out_per_day: archOut / playerDays,
      sink_ratio: archIn > 0 ? archOut / archIn : 0,
      cumulative_net: archIn - archOut,
    })

    totalIn += archIn
    totalOut += archOut
  }

  return {
    archetypes: reports,
    total_gold_in: totalIn,
    total_gold_out: totalOut,
    overall_sink_ratio: totalIn > 0 ? totalOut / totalIn : 0,
  }
}

// Re-export a few constants so callers never need to reach into balance.ts.
export { CHA_GOLD_BONUS_CAP, REPAIR_COSTS, UPGRADE_COSTS, UPGRADE_CHANCES }
