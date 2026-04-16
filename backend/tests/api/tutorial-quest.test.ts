import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockLogTutorialEvent,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(),
  mockLogTutorialEvent: vi.fn(),
  prismaMock: {
    $transaction: vi.fn(),
  },
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/rate-limit', () => ({
  rateLimit: mockRateLimit,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/game/tutorial-analytics', () => ({
  logTutorialEvent: mockLogTutorialEvent,
}))

import { POST } from '@/app/api/tutorial/quest/route'

describe('POST /api/tutorial/quest', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
  })

  it('returns 409 when progressing a quest that is not unlocked yet', async () => {
    prismaMock.$transaction.mockImplementation(
      async (callback: (tx: {
        character: { findUnique: ReturnType<typeof vi.fn> }
        tutorialQuest: {
          findUnique: ReturnType<typeof vi.fn>
          create: ReturnType<typeof vi.fn>
        }
      }) => Promise<unknown>) => callback({
        character: {
          findUnique: vi.fn(async () => ({ userId: 'user-1', level: 1 })),
        },
        tutorialQuest: {
          findUnique: vi.fn(async () => null),
          create: vi.fn(async () => ({})),
        },
      }),
    )

    const response = await POST(
      makeNextRequest('http://localhost/api/tutorial/quest', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          quest_id: 'first_dungeon',
          action: 'progress',
          amount: 1,
        }),
      }),
    )

    expect(response.status).toBe(409)
    await expect(response.json()).resolves.toEqual({
      error: 'Quest not unlocked yet',
    })
  })

  it('rejects non-positive progress amounts before entering the transaction', async () => {
    const response = await POST(
      makeNextRequest('http://localhost/api/tutorial/quest', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          quest_id: 'equip_gear',
          action: 'progress',
          amount: 0,
        }),
      }),
    )

    expect(response.status).toBe(400)
    expect(prismaMock.$transaction).not.toHaveBeenCalled()
    await expect(response.json()).resolves.toEqual({
      error: 'amount must be a positive integer',
    })
  })

  it('claims gold and consumable rewards using the canonical consumable type', async () => {
    const tx = {
      character: {
        findUnique: vi.fn(async () => ({ userId: 'user-1' })),
      },
      $queryRawUnsafe: vi.fn(async () => [{ id: 'user-1', gold: 1000 }]),
      tutorialQuest: {
        findUnique: vi.fn(async () => ({
          id: 'quest-row',
          isCompleted: true,
          rewardClaimed: false,
        })),
        update: vi.fn(async () => ({})),
      },
      user: {
        update: vi.fn(async () => ({})),
      },
      consumableInventory: {
        upsert: vi.fn(async () => ({})),
      },
      item: {
        findUnique: vi.fn(async () => null),
      },
      equipmentInventory: {
        create: vi.fn(async () => ({})),
      },
    }

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: typeof tx) => Promise<unknown>) => callback(tx),
    )

    const response = await POST(
      makeNextRequest('http://localhost/api/tutorial/quest', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          quest_id: 'win_3_pvp',
          action: 'claim',
        }),
      }),
    )

    expect(response.status).toBe(200)
    expect(tx.user.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { gold: { increment: 300 } },
    })
    expect(tx.consumableInventory.upsert).toHaveBeenCalledWith({
      where: {
        characterId_consumableType: {
          characterId: 'char-1',
          consumableType: 'health_potion_medium',
        },
      },
      update: { quantity: { increment: 1 } },
      create: {
        characterId: 'char-1',
        consumableType: 'health_potion_medium',
        quantity: 1,
      },
    })
    await expect(response.json()).resolves.toMatchObject({
      claimed: true,
      goldDelta: 300,
      rewards: {
        gold: 300,
        consumable_type: 'health_potion_medium',
        consumable_amount: 1,
      },
    })
  })
})
