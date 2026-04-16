import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const prismaMock = vi.hoisted(() => ({
  featureFlag: {
    findMany: vi.fn(),
  },
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

import {
  getRuntimeFlagEnvironment,
  invalidateFlagCache,
  resolveAllFlags,
} from '../../src/lib/game/feature-flags'

const originalNodeEnv = process.env.NODE_ENV
const originalVercelEnv = process.env.VERCEL_ENV
const originalAppEnv = process.env.APP_ENV

describe('feature-flags.ts', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    invalidateFlagCache()
    delete process.env.VERCEL_ENV
    delete process.env.APP_ENV
    process.env.NODE_ENV = 'development'
  })

  afterEach(() => {
    invalidateFlagCache()
    process.env.NODE_ENV = originalNodeEnv
    process.env.VERCEL_ENV = originalVercelEnv
    process.env.APP_ENV = originalAppEnv
  })

  it('maps Vercel preview environment to staging flag resolution', async () => {
    process.env.VERCEL_ENV = 'preview'

    prismaMock.featureFlag.findMany.mockResolvedValue([
      {
        key: 'all_flag',
        flagType: 'boolean',
        value: true,
        targeting: null,
        environment: 'all',
      },
      {
        key: 'staging_flag',
        flagType: 'boolean',
        value: true,
        targeting: null,
        environment: 'staging',
      },
      {
        key: 'production_flag',
        flagType: 'boolean',
        value: true,
        targeting: null,
        environment: 'production',
      },
    ])

    const flags = await resolveAllFlags('user-1', { id: 'char-1', level: 10, class: 'rogue' })

    expect(getRuntimeFlagEnvironment()).toBe('staging')
    expect(flags).toEqual({
      all_flag: true,
      staging_flag: true,
      production_flag: false,
    })
  })

  it('applies targeting and defaults safely for mismatched users and levels', async () => {
    prismaMock.featureFlag.findMany.mockResolvedValue([
      {
        key: 'gated_flag',
        flagType: 'json',
        value: { enabled: true },
        targeting: { minLevel: 20, userIds: ['user-2'] },
        environment: 'development',
      },
      {
        key: 'rollout_flag',
        flagType: 'percentage',
        value: 100,
        targeting: { minLevel: 1, class: 'rogue' },
        environment: 'development',
      },
    ])

    const flags = await resolveAllFlags('user-1', { id: 'char-1', level: 10, class: 'rogue' })

    expect(flags).toEqual({
      gated_flag: null,
      rollout_flag: true,
    })
  })
})
