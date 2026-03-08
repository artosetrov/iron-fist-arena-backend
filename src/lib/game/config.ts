import { prisma } from '@/lib/prisma'
import { cacheGet, cacheSet } from '@/lib/cache'

const CONFIG_CACHE_TTL = 5 * 60 * 1000 // 5 minutes

/**
 * Read a live game config value from the database.
 * Falls back to the provided default if the key doesn't exist.
 * Results are cached for 5 minutes to avoid repeated DB hits.
 */
export async function getGameConfig<T>(key: string, fallback: T): Promise<T> {
  const cacheKey = `gameconfig:${key}`
  const cached = cacheGet<T>(cacheKey)
  if (cached !== null) return cached

  try {
    const row = await prisma.gameConfig.findUnique({ where: { key } })
    if (!row) {
      cacheSet(cacheKey, fallback, CONFIG_CACHE_TTL)
      return fallback
    }
    cacheSet(cacheKey, row.value, CONFIG_CACHE_TTL)
    return row.value as T
  } catch {
    return fallback
  }
}

/**
 * Read multiple config values at once (batch read).
 * Returns a map of key → value, using defaults for missing keys.
 * Results are cached for 5 minutes.
 */
export async function getGameConfigs(
  keys: Record<string, unknown>
): Promise<Record<string, unknown>> {
  const batchKey = `gameconfig:batch:${Object.keys(keys).sort().join(',')}`
  const cached = cacheGet<Record<string, unknown>>(batchKey)
  if (cached !== null) return cached

  try {
    const rows = await prisma.gameConfig.findMany({
      where: { key: { in: Object.keys(keys) } },
    })
    const result: Record<string, unknown> = { ...keys }
    for (const row of rows) {
      result[row.key] = row.value
    }
    cacheSet(batchKey, result, CONFIG_CACHE_TTL)
    return result
  } catch {
    return keys
  }
}
