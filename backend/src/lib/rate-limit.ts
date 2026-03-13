import { Ratelimit } from '@upstash/ratelimit'
import { getSharedRedis } from './shared-kv'

const memoryStore = new Map<string, { count: number; resetAt: number }>()
const limiterCache = new Map<string, Ratelimit>()
const RATE_LIMIT_PREFIX = 'ifa:ratelimit'

export interface RateLimitResult {
  allowed: boolean
  limit: number
  remaining: number
  resetAt: number
}

function getLimiter(limit: number, windowMs: number): Ratelimit | null {
  const redis = getSharedRedis()
  if (!redis) return null

  const limiterKey = `${limit}:${windowMs}`
  const existing = limiterCache.get(limiterKey)
  if (existing) return existing

  const limiter = new Ratelimit({
    redis,
    limiter: Ratelimit.fixedWindow(limit, `${Math.ceil(windowMs / 1000)} s`),
    analytics: false,
    prefix: RATE_LIMIT_PREFIX,
  })
  limiterCache.set(limiterKey, limiter)
  return limiter
}

function checkMemoryRateLimit(key: string, limit: number, windowMs: number): RateLimitResult {
  const now = Date.now()
  const entry = memoryStore.get(key)

  if (!entry || now > entry.resetAt) {
    const resetAt = now + windowMs
    memoryStore.set(key, { count: 1, resetAt })
    return {
      allowed: true,
      limit,
      remaining: Math.max(0, limit - 1),
      resetAt,
    }
  }

  entry.count += 1

  return {
    allowed: entry.count <= limit,
    limit,
    remaining: Math.max(0, limit - entry.count),
    resetAt: entry.resetAt,
  }
}

export async function checkRateLimit(
  key: string,
  limit: number,
  windowMs: number
): Promise<RateLimitResult> {
  const limiter = getLimiter(limit, windowMs)
  if (!limiter) {
    return checkMemoryRateLimit(key, limit, windowMs)
  }

  const result = await limiter.limit(key)
  return {
    allowed: result.success,
    limit: result.limit,
    remaining: Math.max(0, result.remaining),
    resetAt: result.reset,
  }
}

export async function rateLimit(key: string, limit: number, windowMs: number): Promise<boolean> {
  const result = await checkRateLimit(key, limit, windowMs)
  return result.allowed
}

// Clean up old entries periodically when running without shared Redis.
const cleanupInterval = setInterval(() => {
  const now = Date.now()
  for (const [key, entry] of memoryStore) {
    if (now > entry.resetAt) memoryStore.delete(key)
  }
}, 60_000)

cleanupInterval.unref?.()
