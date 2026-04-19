import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  prismaMock,
  mockCalculateCurrentHp,
  mockCalculateCurrentStamina,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  prismaMock: {
    character: {
      findMany: vi.fn(),
      update: vi.fn(),
    },
    user: {
      findUnique: vi.fn(),
    },
  },
  mockCalculateCurrentHp: vi.fn(),
  mockCalculateCurrentStamina: vi.fn(),
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/game/hp-regen', () => ({
  calculateCurrentHp: mockCalculateCurrentHp,
}))

vi.mock('@/lib/game/stamina', () => ({
  calculateCurrentStamina: mockCalculateCurrentStamina,
}))

import { GET } from '@/app/api/characters/route'

describe('GET /api/characters', () => {
  const baseCharacter = {
    id: 'char-1',
    userId: 'user-1',
    characterName: 'Hero',
    level: 12,
    currentHp: 30,
    maxHp: 100,
    lastHpUpdate: new Date('2026-04-18T10:00:00.000Z'),
    currentStamina: 4,
    maxStamina: 12,
    lastStaminaUpdate: new Date('2026-04-18T10:00:00.000Z'),
    createdAt: new Date('2026-04-18T09:00:00.000Z'),
  }

  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    prismaMock.character.findMany.mockResolvedValue([baseCharacter])
    prismaMock.character.update.mockResolvedValue({})
    prismaMock.user.findUnique.mockResolvedValue({ gold: 123, gems: 7 })
    mockCalculateCurrentHp.mockResolvedValue({ hp: 45, updated: true })
    mockCalculateCurrentStamina.mockResolvedValue({ stamina: 8, updated: true })
  })

  it('still returns the hero list when regen persistence fails for a character', async () => {
    prismaMock.character.update.mockRejectedValueOnce(new Error('write failed'))

    const response = await GET(makeNextRequest('http://localhost/api/characters'))

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      characters: [
        expect.objectContaining({
          id: 'char-1',
          currentHp: 45,
          currentStamina: 8,
          gold: 123,
          gems: 7,
        }),
      ],
    })
  })

  it('falls back to zero wallet values when the account row lookup fails', async () => {
    prismaMock.user.findUnique.mockRejectedValueOnce(new Error('wallet lookup failed'))

    const response = await GET(makeNextRequest('http://localhost/api/characters'))

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      characters: [
        expect.objectContaining({
          id: 'char-1',
          gold: 0,
          gems: 0,
        }),
      ],
    })
  })
})
