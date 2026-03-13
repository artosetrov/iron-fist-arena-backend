import { describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/shared-kv', () => ({
  getSharedRedis: () => null,
}))

describe('cache memory fallback', () => {
  it('stores, reads, and deletes cache entries by prefix', async () => {
    const { cacheDeletePrefix, cacheGet, cacheSet } = await import('@/lib/cache')
    const prefix = `test-cache:${Date.now()}`

    await cacheSet(`${prefix}:one`, { value: 1 }, 60_000)
    await cacheSet(`${prefix}:two`, { value: 2 }, 60_000)

    expect(await cacheGet<{ value: number }>(`${prefix}:one`)).toEqual({ value: 1 })
    expect(await cacheGet<{ value: number }>(`${prefix}:two`)).toEqual({ value: 2 })

    await cacheDeletePrefix(prefix)

    expect(await cacheGet(`${prefix}:one`)).toBeNull()
    expect(await cacheGet(`${prefix}:two`)).toBeNull()
  })
})
