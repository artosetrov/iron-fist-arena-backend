import { beforeEach, describe, expect, it, vi } from 'vitest'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockUpdateDailyQuestProgress,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockUpdateDailyQuestProgress: vi.fn(),
  prismaMock: {
    item: {
      findUnique: vi.fn(),
    },
    character: {
      findUnique: vi.fn(),
      update: vi.fn(),
    },
    equipmentInventory: {
      count: vi.fn(),
      create: vi.fn(),
    },
    user: {
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
}))

vi.mock('@/lib/game/daily-quests', () => ({
  updateDailyQuestProgress: mockUpdateDailyQuestProgress,
}))

import { POST } from '@/app/api/shop/buy/route'

describe('POST /api/shop/buy', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
  })

  it('returns 401 when unauthorized', async () => {
    mockGetAuthUser.mockResolvedValue(null)

    const response = await POST(
      new Request('http://localhost/api/shop/buy', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', item_catalog_id: 'item-1' }),
      }) as any,
    )

    expect(response.status).toBe(401)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Unauthorized',
    })
  })

  it('returns 404 when item not found in catalog', async () => {
    prismaMock.item.findUnique.mockResolvedValue(null)

    const response = await POST(
      new Request('http://localhost/api/shop/buy', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', item_catalog_id: 'nonexistent-item' }),
      }) as any,
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

    const tx = {
      $queryRawUnsafe: vi.fn(async () => [
        {
          id: 'char-1',
          user_id: 'user-1',
          gold: 500, // Not enough for 1000
          inventory_slots: 20,
        },
      ]),
    }

    prismaMock.$transaction.mockImplementation(async (callback) => callback(tx))

    const response = await POST(
      new Request('http://localhost/api/shop/buy', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', item_catalog_id: 'sword-1' }),
      }) as any,
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

    const tx = {
      $queryRawUnsafe: vi.fn(async () => [
        {
          id: 'char-1',
          user_id: 'user-1',
          gold: 1000,
          inventory_slots: 20,
        },
      ]),
      equipmentInventory: {
        count: vi.fn(async () => 20), // Full
      },
    }

    prismaMock.$transaction.mockImplementation(async (callback) => callback(tx))

    const response = await POST(
      new Request('http://localhost/api/shop/buy', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', item_catalog_id: 'sword-1' }),
      }) as any,
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

    const updatedCharacter = {
      id: 'char-1',
      gold: 500, // 1000 - 500
      maxStamina: 120,
    }

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

    const tx = {
      $queryRawUnsafe: vi.fn(async () => [
        {
          id: 'char-1',
          user_id: 'user-1',
          gold: 1000,
          inventory_slots: 20,
        },
      ]),
      equipmentInventory: {
        count: vi.fn(async () => 5),
        create: vi.fn(async () => inventoryItem),
      },
      character: {
        update: vi.fn(async () => updatedCharacter),
      },
    }

    prismaMock.$transaction.mockImplementation(async (callback) => callback(tx))

    prismaMock.user.findUnique.mockResolvedValue({
      id: 'user-1',
      gems: 100,
    })

    const response = await POST(
      new Request('http://localhost/api/shop/buy', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', item_catalog_id: 'sword-1' }),
      }) as any,
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

    const tx = {
      $queryRawUnsafe: vi.fn(async () => [
        {
          id: 'char-1',
          user_id: 'different-user', // Not the current user
          gold: 1000,
          inventory_slots: 20,
        },
      ]),
    }

    prismaMock.$transaction.mockImplementation(async (callback) => callback(tx))

    const response = await POST(
      new Request('http://localhost/api/shop/buy', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', item_catalog_id: 'sword-1' }),
      }) as any,
    )

    expect(response.status).toBe(403)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Forbidden',
    })
  })
})
