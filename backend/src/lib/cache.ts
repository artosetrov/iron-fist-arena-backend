import { getSharedRedis } from './shared-kv'

const MAX_CACHE_SIZE = 10_000
const CACHE_PREFIX = 'ifa:cache:'

const store = new Map<string, { data: unknown; expiresAt: number }>()

function getRedisKey(key: string): string {
  return `${CACHE_PREFIX}${key}`
}

export async function cacheGet<T>(key: string): Promise<T | null> {
  const redis = getSharedRedis()
  if (redis) {
    const cached = await redis.get<string | null>(getRedisKey(key))
    if (cached === null) return null

    if (typeof cached === 'string') {
      return JSON.parse(cached) as T
    }

    return cached as T
  }

  const entry = store.get(key)
  if (!entry || Date.now() > entry.expiresAt) {
    store.delete(key)
    return null
  }
  return entry.data as T
}

export async function cacheSet(key: string, data: unknown, ttlMs: number): Promise<void> {
  const redis = getSharedRedis()
  if (redis) {
    await redis.set(getRedisKey(key), JSON.stringify(data), { px: ttlMs })
    return
  }

  // Evict oldest entry (first key in insertion order) if at capacity
  if (store.size >= MAX_CACHE_SIZE && !store.has(key)) {
    const oldest = store.keys().next().value
    if (oldest !== undefined) store.delete(oldest)
  }
  store.set(key, { data, expiresAt: Date.now() + ttlMs })
}

export async function cacheDelete(key: string): Promise<void> {
  const redis = getSharedRedis()
  if (redis) {
    await redis.del(getRedisKey(key))
    return
  }

  store.delete(key)
}

export async function cacheDeletePrefix(prefix: string): Promise<void> {
  const redis = getSharedRedis()
  if (redis) {
    let cursor = 0
    const pattern = `${getRedisKey(prefix)}*`

    do {
      const [nextCursor, keys] = await redis.scan(cursor, {
        match: pattern,
        count: 200,
      })

      if (keys.length > 0) {
        await redis.del(...keys)
      }

      cursor = Number(nextCursor)
    } while (cursor !== 0)
    return
  }

  for (const key of store.keys()) {
    if (key.startsWith(prefix)) store.delete(key)
  }
}

// Clean up expired entries every 60s when running without shared Redis.
const cleanupInterval = setInterval(() => {
  const now = Date.now()
  for (const [key, entry] of store) {
    if (now > entry.expiresAt) store.delete(key)
  }
}, 60_000)

cleanupInterval.unref?.()
