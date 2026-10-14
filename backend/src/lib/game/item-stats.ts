const CORE_STAT_KEYS = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha'] as const

type StatsMap = Record<string, number>
type CoreStatKey = (typeof CORE_STAT_KEYS)[number]

function normalizeStats(raw: unknown): StatsMap {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return {}

  const stats: StatsMap = {}
  for (const [key, value] of Object.entries(raw)) {
    if (typeof value === 'number' && Number.isFinite(value)) {
      stats[key] = value
    }
  }
  return stats
}

/**
 * Per-copy stat rolls (2026-10-14 balance batch).
 *
 * Every dropped copy of a catalog item gets its own `rolledStats`: a bonus of
 * 0..STAT_ROLL_MAX[rarity] on each of its base stats, rounded to whole points.
 * Shop copies roll nothing, so a drop is never worse than the shop baseline
 * and is usually a little better — fighting beats buying. The roll is stored
 * once at drop time and never re-rolled; `combineItemStats` adds it to the
 * base, and the flat per-level upgrade bonus stacks on top of both.
 *
 * `rng` is injectable so tests and simulators can pin the roll.
 */
export const STAT_ROLL_MAX: Record<string, number> = {
  common: 0.10,
  uncommon: 0.12,
  rare: 0.15,
  epic: 0.20,
  legendary: 0.25,
}

export function rollItemStats(
  baseStats: unknown,
  rarity: string,
  rng: () => number = Math.random,
): StatsMap {
  const maxShare = STAT_ROLL_MAX[rarity] ?? STAT_ROLL_MAX.common
  const rolled: StatsMap = {}
  for (const [key, value] of Object.entries(normalizeStats(baseStats))) {
    if (value <= 0) continue
    const share = Math.min(1, Math.max(0, rng())) * maxShare
    const bonus = Math.round(value * share)
    if (bonus > 0) rolled[key] = bonus
  }
  return rolled
}

export function combineItemStats(baseStats: unknown, rolledStats: unknown): StatsMap {
  const combined: StatsMap = {}

  for (const source of [normalizeStats(baseStats), normalizeStats(rolledStats)]) {
    for (const [key, value] of Object.entries(source)) {
      combined[key] = (combined[key] ?? 0) + value
    }
  }

  return combined
}

export function buildEffectiveItemStats(
  baseStats: unknown,
  rolledStats: unknown,
  upgradeLevel: number,
  upgradeStatBonus: number,
): StatsMap {
  const combinedStats = combineItemStats(baseStats, rolledStats)
  const effectiveStats: StatsMap = {}

  for (const [key, value] of Object.entries(combinedStats)) {
    effectiveStats[key] = value + upgradeLevel * upgradeStatBonus
  }

  return effectiveStats
}

export function sumCoreEquipmentStats(
  baseStats: unknown,
  rolledStats: unknown,
  upgradeLevel: number,
  upgradeStatBonus: number,
): Record<CoreStatKey, number> {
  const effectiveStats = buildEffectiveItemStats(baseStats, rolledStats, upgradeLevel, upgradeStatBonus)
  const totals = { str: 0, agi: 0, vit: 0, end: 0, int: 0, wis: 0, luk: 0, cha: 0 }

  for (const key of CORE_STAT_KEYS) {
    totals[key] += effectiveStats[key] ?? 0
  }

  return totals
}

export function calculateEffectiveItemPower(
  baseStats: unknown,
  rolledStats: unknown,
  upgradeLevel: number,
  upgradeStatBonus: number,
): number {
  return Object.values(
    buildEffectiveItemStats(baseStats, rolledStats, upgradeLevel, upgradeStatBonus),
  ).reduce((sum, value) => sum + value, 0)
}
