import { Redis } from '@upstash/redis/cloudflare'

let redisClient: Redis | null | undefined
let warnedAboutMissingRedis = false

export function getSharedRedis(): Redis | null {
  if (redisClient !== undefined) {
    return redisClient
  }

  // UPSTASH_* when the store is wired by hand; KV_REST_API_* is what the
  // Upstash integration from the Vercel Marketplace injects.
  const url = process.env.UPSTASH_REDIS_REST_URL ?? process.env.KV_REST_API_URL
  const token = process.env.UPSTASH_REDIS_REST_TOKEN ?? process.env.KV_REST_API_TOKEN

  if (!url || !token) {
    if (process.env.NODE_ENV === 'production' && !warnedAboutMissingRedis) {
      warnedAboutMissingRedis = true
      console.warn(
        'Shared Redis is not configured. Falling back to per-instance memory store for cache and rate limits.',
      )
    }
    redisClient = null
    return redisClient
  }

  redisClient = new Redis({ url, token })
  return redisClient
}

export function hasSharedRedis(): boolean {
  return getSharedRedis() !== null
}
