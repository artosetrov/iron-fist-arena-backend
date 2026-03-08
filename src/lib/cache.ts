const MAX_CACHE_SIZE = 10_000

const store = new Map<string, { data: unknown; expiresAt: number }>()

export function cacheGet<T>(key: string): T | null {
  const entry = store.get(key)
  if (!entry || Date.now() > entry.expiresAt) {
    store.delete(key)
    return null
  }
  return entry.data as T
}

export function cacheSet(key: string, data: unknown, ttlMs: number): void {
  // Evict oldest entry (first key in insertion order) if at capacity
  if (store.size >= MAX_CACHE_SIZE && !store.has(key)) {
    const oldest = store.keys().next().value
    if (oldest !== undefined) store.delete(oldest)
  }
  store.set(key, { data, expiresAt: Date.now() + ttlMs })
}

export function cacheDelete(key: string): void {
  store.delete(key)
}

export function cacheDeletePrefix(prefix: string): void {
  for (const key of store.keys()) {
    if (key.startsWith(prefix)) store.delete(key)
  }
}

// Clean up expired entries every 60s (same pattern as rate-limit.ts)
setInterval(() => {
  const now = Date.now()
  for (const [key, entry] of store) {
    if (now > entry.expiresAt) store.delete(key)
  }
}, 60_000)
