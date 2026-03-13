import { describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/shared-kv', () => ({
  getSharedRedis: () => null,
}))

describe('rate-limit memory fallback', () => {
  it('blocks requests after the configured limit', async () => {
    const { checkRateLimit, rateLimit } = await import('@/lib/rate-limit')
    const key = `test-rate-limit:${Date.now()}`

    const first = await checkRateLimit(key, 2, 60_000)
    const second = await checkRateLimit(key, 2, 60_000)
    const third = await checkRateLimit(key, 2, 60_000)
    const fourthAllowed = await rateLimit(`${key}:bool`, 1, 60_000)
    const fifthAllowed = await rateLimit(`${key}:bool`, 1, 60_000)

    expect(first.allowed).toBe(true)
    expect(first.remaining).toBe(1)
    expect(second.allowed).toBe(true)
    expect(second.remaining).toBe(0)
    expect(third.allowed).toBe(false)
    expect(third.remaining).toBe(0)
    expect(third.resetAt).toBeGreaterThan(Date.now())
    expect(fourthAllowed).toBe(true)
    expect(fifthAllowed).toBe(false)
  })
})
