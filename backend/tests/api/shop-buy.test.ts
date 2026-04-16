import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockUpdateDailyQuestProgress,
  mockUpdateWeeklyChallengeProgress,
  mockUpdateTutorialQuestProgress,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockUpdateDailyQuestProgress: vi.fn(),
  mockUpdateWeeklyChallengeProgress: vi.fn(),
  mockUpdateTutorialQuestProgress: vi.fn(),
  prismaMock: {
    item: {
      findUnique: vi.fn(),
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
  shopRateLimit: mockRateLimit,
}))

vi.mock('@/lib/game/daily-quests', () => ({
  updateDailyQuestProgress: mockUpdateDailyQuestProgress,
}))

vi.mock('@/lib/game/weekly-challenges', () => ({
  updateWeeklyChallengeProgress: mockUpdateWeeklyChallengeProgress,
}))

vi.mock('@/lib/game/tutorial', () => ({
  updateTutorialQuestProgress: mockUpdateTutorialQuestProgress,
}))

import { POST } from '@/app/api/shop/buy/route'

/**
 * Build a fake `tx` object mirroring the current shape used by
 * `POST /api/shop/buy` (see `backend/src/app/api/shop/buy/route.ts`):
 *
 *   1. `tx.$queryRawUnsafe` → row-level lock on `users` (returns { id, gold, gems })
 *   2. `tx.character.findUnique` → ownership + inventorySlots check
 *   3. `tx.equipmentInventory.count` → inventory capacity check
 *   4. `tx.user.update` → decrement user.gold (account-level)
 *   5. `tx.equipmentInventory.create` → spawn the purchased item
 */
function makeTx(overrides: {
  userRow?: { id: string; gold: number; gems: number } | null
  character?: { userId: string; inventorySlots: number } | null
  inventoryCount?: number
  updatedUser?: { gold: number; gems: number }
  inventoryItem?: {
    id: string
    characterId: string
    itemId: string
    upgradeLevel: number
    durability: number
    maxDurability: number
    isEquipped: boolean
    item: {
      id: string
      catalogId: string
      buyPrice: number
      sellPrice: number
    }
  } | null
}) {
  const {
    userRow = null,
    character = null,
    inventoryCount = 0,
    updatedUser = { gold: 0, gems: 0 },
    inventoryItem = null,
  } = overrides

  return {
    $queryRawUnsafe: vi.fn(async () => (userRow ? [userRow] : [])),
    character: {
      findUnique: vi.fn(async () => character),
    },
    equipmentInventory: {
      count: vi.fn(async () => inventoryCount),
      create: vi.fn(async () => inventoryItem),
    },
    user: {
      update: vi.fn(async () => updatedUser),
    },
  }
}

type ShopBuyTx = ReturnType<typeof makeTx>

function mockTransaction(tx: ShopBuyTx) {
  prismaMock.$transaction.mockImplementation(
    async (callback: (innerTx: ShopBuyTx) => Promise<unknown>) => callback(tx),
  )
}

describe('POST /api/shop/buy', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    mockUpdateDailyQuestProgress.mockResolvedValue(undefined)
    mockUpdateWeeklyChallengeProgress.mockResolvedValue(undefined)
    mockUpdateTutorialQuestProgress.mockResolvedValue(undefined)
  })

  it('returns 401 when unauthorized', async () => {
    mockGetAuthUser.mockResolvedValue(null)

    const response = await POST(
      makeNextRequest('http://localhost/api/shop/buy', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', item_catalog_id: 'item-1' }),
      }),
    )

    expect(response.status).toBe(401)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Unauthorized',
    })
  })

  it('returns 404 when item not found in catalog', async () => {
    prismaMock.item.findUnique.mockResolvedValue(null)

    const response = await POST(
      makeNextRequest('http://localhost/api/shop/buy', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', item_catalog_id: 'nonexistent-item' }),
      }),
    )

    expect(response.status).toBe(404)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Item not found in catalog',
    })
  })

  it('returns 400 when not enough gold', async () => {
    prismaMock.item.findUnique.mockResolvedValue({
      id: 'item-1',
      catalogId: 'sword-1',
      buyPrice: 1000,
      sellPrice: 500,
    })

    const tx = makeTx({
      userRow: { id: 'user-1', gold: 500, gems: 0 }, // Not enough for 1000
      character: { userId: 'user-1', inventorySlots: 20 },
    })
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/shop/buy', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', item_catalog_id: 'sword-1' }),
      }),
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Not enough gold',
    })
  })

  it('returns 409 when inventory full', async () => {
    prismaMock.item.findUnique.mockResolvedValue({
      id: 'item-1',
      catalogId: 'sword-1',
      buyPrice: 500,
      sellPrice: 250,
    })

    const tx = makeTx({
      userRow: { id: 'user-1', gold: 1000, gems: 0 },
      character: { userId: 'user-1', inventorySlots: 20 },
      inventoryCount: 20, // Full
    })
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/shop/buy', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', item_catalog_id: 'sword-1' }),
      }),
    )

    expect(response.status).toBe(409)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Inventory is full',
    })
  })

  it('returns 200 and deducts gold on successful purchase', async () => {
    const item = {
      id: 'item-1',
      catalogId: 'sword-1',
      buyPrice: 500,
      sellPrice: 250,
    }

    prismaMock.item.findUnique.mockResolvedValue(item)

    const inventoryItem = {
      id: 'inv-item-1',
      characterId: 'char-1',
      itemId: 'item-1',
      upgradeLevel: 0,
      durability: 100,
      maxDurability: 100,
      isEquipped: false,
      item,
    }

    const tx = makeTx({
      userRow: { id: 'user-1', gold: 1000, gems: 100 },
      character: { userId: 'user-1', inventorySlots: 20 },
      inventoryCount: 5,
      updatedUser: { gold: 500, gems: 100 }, // 1000 - 500
      inventoryItem,
    })
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/shop/buy', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', item_catalog_id: 'sword-1' }),
      }),
    )

    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data).toMatchObject({
      character: {
        gold: 500,
        gems: 100,
      },
      inventoryItem: expect.objectContaining({
        id: 'inv-item-1',
        upgradeLevel: 0,
        isEquipped: false,
      }),
    })
    expect(tx.user.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { gold: { decrement: 500 } },
    })
    expect(mockUpdateDailyQuestProgress).toHaveBeenCalledWith(
      prismaMock,
      'char-1',
      'gold_spent',
      500,
    )
  })

  it('verifies character ownership before purchase', async () => {
    prismaMock.item.findUnique.mockResolvedValue({
      id: 'item-1',
      catalogId: 'sword-1',
      buyPrice: 500,
      sellPrice: 250,
    })

    const tx = makeTx({
      userRow: { id: 'user-1', gold: 1000, gems: 0 },
      character: { userId: 'different-user', inventorySlots: 20 }, // Not the current user
    })
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/shop/buy', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', item_catalog_id: 'sword-1' }),
      }),
    )

    expect(response.status).toBe(403)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Forbidden',
    })
  })
})
