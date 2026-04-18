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
