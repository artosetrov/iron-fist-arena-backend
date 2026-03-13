import { Redis } from '@upstash/redis/cloudflare'

let redisClient: Redis | null | undefined
let warnedAboutMissingRedis = false

export function getSharedRedis(): Redis | null {
  if (redisClient !== undefined) {
    return redisClient
  }

  const url = process.env.UPSTASH_REDIS_REST_URL
  const token = process.env.UPSTASH_REDIS_REST_TOKEN

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
