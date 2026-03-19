import { beforeEach, describe, expect, it, vi } from 'vitest'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockCalculateCurrentStamina,
  mockGetStaminaConfig,
  mockGetGemCostsConfig,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockCalculateCurrentStamina: vi.fn(),
  mockGetStaminaConfig: vi.fn(),
  mockGetGemCostsConfig: vi.fn(),
  prismaMock: {
    user: {
      update: vi.fn(),
    },
    character: {
      update: vi.fn(),
    },
    $transaction: vi.fn(),
  },
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/rate-limit', () => ({
  rateLimit: mockRateLimit,
}))

vi.mock('@/lib/game/stamina', () => ({
  calculateCurrentStamina: mockCalculateCurrentStamina,
}))

vi.mock('@/lib/game/live-config', () => ({
  getStaminaConfig: mockGetStaminaConfig,
  getGemCostsConfig: mockGetGemCostsConfig,
}))

import { POST } from '@/app/api/stamina/refill/route'

describe('POST /api/stamina/refill', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    mockGetStaminaConfig.mockResolvedValue({
      REGEN_RATE: 1,
      REGEN_INTERVAL_MINUTES: 8,
      MAX: 120,
    })
    mockGetGemCostsConfig.mockResolvedValue({
      STAMINA_REFILL: 50,
    })
  })

  it('returns 401 when unauthorized', async () => {
    mockGetAuthUser.mockResolvedValue(null)

    const response = await POST(
      new Request('http://localhost/api/stamina/refill', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1' }),
      }) as any,
    )

    expect(response.status).toBe(401)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Unauthorized',
    })
  })

  it('returns 400 when stamina is already full', async () => {
    mockCalculateCurrentStamina.mockResolvedValue({
      stamina: 120,
      updated: false,
    })

    const tx = {
      $queryRawUnsafe: vi.fn()
        .mockResolvedValueOnce([{ id: 'user-1', gems: 100 }])
        .mockResolvedValueOnce([
          {
            id: 'char-1',
            user_id: 'user-1',
            current_stamina: 120,
            max_stamina: 120,
            last_stamina_update: new Date(),
          },
        ]),
    }

    prismaMock.$transaction.mockImplementation(async (callback) => callback(tx))

    const response = await POST(
      new Request('http://localhost/api/stamina/refill', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1' }),
      }) as any,
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Stamina is already full',
    })
  })

  it('returns 400 when not enough gems', async () => {
    mockCalculateCurrentStamina.mockResolvedValue({
      stamina: 60,
      updated: true,
    })

    const tx = {
      $queryRawUnsafe: vi.fn()
        .mockResolvedValueOnce([{ id: 'user-1', gems: 20 }]) // Not enough
        .mockResolvedValueOnce([
          {
            id: 'char-1',
            user_id: 'user-1',
            current_stamina: 60,
            max_stamina: 120,
            last_stamina_update: new Date(),
          },
        ]),
    }

    prismaMock.$transaction.mockImplementation(async (callback) => callback(tx))

    const response = await POST(
      new Request('http://localhost/api/stamina/refill', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1' }),
      }) as any,
    )

    expect(response.status).toBe(400)
    const data = await response.json()
    expect(data).toMatchObject({
      error: 'Not enough gems',
      required: 50,
    })
  })

  it('returns 200 and deducts gems on successful refill', async () => {
    mockCalculateCurrentStamina.mockResolvedValue({
      stamina: 60,
      updated: true,
    })

    const tx = {
      $queryRawUnsafe: vi.fn()
        .mockResolvedValueOnce([{ id: 'user-1', gems: 100 }])
        .mockResolvedValueOnce([
          {
            id: 'char-1',
            user_id: 'user-1',
            current_stamina: 60,
            max_stamina: 120,
            last_stamina_update: new Date(),
          },
        ]),
      user: {
        update: vi.fn(async () => ({ id: 'user-1', gems: 50 })),
      },
      character: {
        update: vi.fn(async () => ({
          id: 'char-1',
          currentStamina: 120,
          lastStaminaUpdate: new Date(),
        })),
      },
    }

    prismaMock.$transaction.mockImplementation(async (callback) => callback(tx))

    const response = await POST(
      new Request('http://localhost/api/stamina/refill', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1' }),
      }) as any,
    )

    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data).toMatchObject({
      stamina: {
        before: 60,
        after: 120,
        max: 120,
      },
      gems_spent: 50,
      gems_remaining: 50,
    })
    expect(tx.user.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { gems: { decrement: 50 } },
    })
    expect(tx.character.update).toHaveBeenCalledWith({
      where: { id: 'char-1' },
      data: { currentStamina: 120, lastStaminaUpdate: expect.any(Date) },
    })
  })

  it('verifies character ownership before refill', async () => {
    mockCalculateCurrentStamina.mockResolvedValue({
      stamina: 60,
      updated: true,
    })

    const tx = {
      $queryRawUnsafe: vi.fn()
        .mockResolvedValueOnce([{ id: 'user-1', gems: 100 }])
        .mockResolvedValueOnce([
          {
            id: 'char-1',
            user_id: 'different-user', // Not the current user
            current_stamina: 60,
            max_stamina: 120,
            last_stamina_update: new Date(),
          },
        ]),
    }

    prismaMock.$transaction.mockImplementation(async (callback) => callback(tx))

    const response = await POST(
      new Request('http://localhost/api/stamina/refill', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1' }),
      }) as any,
    )

    expect(response.status).toBe(403)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Forbidden',
    })
  })

  it('returns 404 when character not found', async () => {
    const tx = {
      $queryRawUnsafe: vi.fn()
        .mockResolvedValueOnce([{ id: 'user-1', gems: 100 }])
        .mockResolvedValueOnce([]), // Character not found
    }

    prismaMock.$transaction.mockImplementation(async (callback) => callback(tx))

    const response = await POST(
      new Request('http://localhost/api/stamina/refill', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'nonexistent-char' }),
      }) as any,
    )

    expect(response.status).toBe(404)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Character not found',
    })
  })
})
