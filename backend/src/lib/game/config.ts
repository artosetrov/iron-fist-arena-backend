import { prisma } from '@/lib/prisma'
import { cacheDelete, cacheDeletePrefix, cacheGet, cacheSet } from '@/lib/cache'

const CONFIG_CACHE_TTL = 5 * 60 * 1000 // 5 minutes

/**
 * In-process memo in front of the shared cache (latency pass 2026-10-15).
 *
 * With Upstash configured, every `cacheGet` is an HTTP round trip, and hot
 * paths read config many times per request (stat recompute alone read ~11
 * keys sequentially, inside a row-locked transaction). A warm serverless
 * instance now answers repeats from memory for `MEMO_TTL_MS`.
 *
 * Trade-off: an admin config change reaches OTHER warm instances up to
 * `MEMO_TTL_MS` later (this instance is cleared immediately by
 * `invalidateGameConfigCache`).
 */
const MEMO_TTL_MS = 30 * 1000
const MEMO_MAX_ENTRIES = 2_000
const memo = new Map<string, { value: unknown; expiresAt: number }>()

function memoGet<T>(key: string): { hit: true; value: T } | { hit: false } {
  const entry = memo.get(key)
  if (!entry) return { hit: false }
  if (Date.now() > entry.expiresAt) {
    memo.delete(key)
    return { hit: false }
  }
  // Callers get their own copy: a caller that sorts or patches a config
  // array/object in place must not corrupt the memo for everyone else.
  return { hit: true, value: structuredClone(entry.value) as T }
}

function memoSet(key: string, value: unknown): void {
  if (memo.size >= MEMO_MAX_ENTRIES && !memo.has(key)) {
    const oldest = memo.keys().next().value
    if (oldest !== undefined) memo.delete(oldest)
  }
  memo.set(key, { value: structuredClone(value), expiresAt: Date.now() + MEMO_TTL_MS })
}

/**
 * Read a live game config value from the database.
 * Falls back to the provided default if the key doesn't exist.
 * Results are cached for 5 minutes to avoid repeated DB hits.
 */
export async function getGameConfig<T>(key: string, fallback: T): Promise<T> {
  const cacheKey = `gameconfig:${key}`
  const memoized = memoGet<T>(cacheKey)
  if (memoized.hit) return memoized.value

  const cached = await cacheGet<T>(cacheKey)
  if (cached !== null) {
    memoSet(cacheKey, cached)
    return cached
  }

  try {
    const row = await prisma.gameConfig.findUnique({ where: { key } })
    if (!row) {
      await cacheSet(cacheKey, fallback, CONFIG_CACHE_TTL)
      memoSet(cacheKey, fallback)
      return fallback
    }
    await cacheSet(cacheKey, row.value, CONFIG_CACHE_TTL)
    memoSet(cacheKey, row.value)
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
  const memoized = memoGet<Record<string, unknown>>(batchKey)
  if (memoized.hit) return memoized.value

  const cached = await cacheGet<Record<string, unknown>>(batchKey)
  if (cached !== null) {
    memoSet(batchKey, cached)
    return cached
  }

  try {
    const rows = await prisma.gameConfig.findMany({
      where: { key: { in: Object.keys(keys) } },
    })
    const result: Record<string, unknown> = { ...keys }
    for (const row of rows) {
      result[row.key] = row.value
    }
    await cacheSet(batchKey, result, CONFIG_CACHE_TTL)
    memoSet(batchKey, result)
    return result
  } catch {
    return keys
  }
}

export async function invalidateGameConfigCache(keys: readonly string[] = []): Promise<void> {
  const uniqueKeys = [...new Set(keys.filter(Boolean))]

  // This instance forgets immediately; other warm instances within MEMO_TTL_MS.
  for (const key of uniqueKeys) memo.delete(`gameconfig:${key}`)
  for (const memoKey of [...memo.keys()]) {
    if (memoKey.startsWith('gameconfig:batch:')) memo.delete(memoKey)
  }

  await Promise.all([
    ...uniqueKeys.map((key) => cacheDelete(`gameconfig:${key}`)),
    cacheDeletePrefix('gameconfig:batch:'),
  ])
}
