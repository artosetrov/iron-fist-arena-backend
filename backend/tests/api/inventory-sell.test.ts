import { beforeEach, describe, expect, it, vi } from 'vitest'

const {
  mockGetAuthUser,
  mockRateLimit,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  prismaMock: {
    character: {
      findUnique: vi.fn(),
      update: vi.fn(),
    },
    equipmentInventory: {
      findUnique: vi.fn(),
      delete: vi.fn(),
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

import { POST } from '@/app/api/inventory/sell/route'

describe('POST /api/inventory/sell', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
  })

  it('returns 401 when unauthorized', async () => {
    mockGetAuthUser.mockResolvedValue(null)

    const response = await POST(
      new Request('http://localhost/api/inventory/sell', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', inventory_id: 'inv-1' }),
      }) as any,
    )

    expect(response.status).toBe(401)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Unauthorized',
    })
  })

  it('returns 400 when item is equipped', async () => {
    prismaMock.character.findUnique.mockResolvedValue({
      id: 'char-1',
      userId: 'user-1',
    })

    prismaMock.equipmentInventory.findUnique.mockResolvedValue({
      id: 'inv-1',
      characterId: 'char-1',
      itemId: 'item-1',
      isEquipped: true,
      upgradeLevel: 0,
      item: {
        id: 'item-1',
        sellPrice: 500,
      },
    })

    const response = await POST(
      new Request('http://localhost/api/inventory/sell', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', inventory_id: 'inv-1' }),
      }) as any,
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Cannot sell an equipped item. Unequip it first.',
    })
  })

  it('returns 404 when item not found', async () => {
    prismaMock.character.findUnique.mockResolvedValue({
      id: 'char-1',
      userId: 'user-1',
    })

    prismaMock.equipmentInventory.findUnique.mockResolvedValue(null)

    const response = await POST(
      new Request('http://localhost/api/inventory/sell', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', inventory_id: 'nonexistent' }),
      }) as any,
    )

    expect(response.status).toBe(404)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Inventory item not found',
    })
  })

  it('returns 200 and adds gold on successful sell', async () => {
    prismaMock.character.findUnique.mockResolvedValue({
      id: 'char-1',
      userId: 'user-1',
    })

    const inventoryItem = {
      id: 'inv-1',
      characterId: 'char-1',
      itemId: 'item-1',
      isEquipped: false,
      upgradeLevel: 2,
      item: {
        id: 'item-1',
        sellPrice: 500,
      },
    }

    prismaMock.equipmentInventory.findUnique.mockResolvedValue(inventoryItem)

    const updatedCharacter = {
      id: 'char-1',
      userId: 'user-1',
      gold: 1600, // 1000 + 600
    }

    const tx = {
      equipmentInventory: {
        delete: vi.fn(async () => inventoryItem),
      },
      character: {
        update: vi.fn(async () => updatedCharacter),
      },
    }

    prismaMock.$transaction.mockImplementation(async (callback) => callback(tx))

    const response = await POST(
      new Request('http://localhost/api/inventory/sell', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', inventory_id: 'inv-1' }),
      }) as any,
    )

    expect(response.status).toBe(200)
    const data = await response.json()
    // baseSellPrice * (1 + upgradeLevel * 0.1) = 500 * (1 + 2 * 0.1) = 500 * 1.2 = 600
    expect(data).toMatchObject({
      gold: 1600,
      soldFor: 600,
    })
  })

  it('applies correct sell price formula with upgrade level', async () => {
    prismaMock.character.findUnique.mockResolvedValue({
      id: 'char-1',
      userId: 'user-1',
    })

    const testCases = [
      { upgradeLevel: 0, baseSellPrice: 100, expected: 100 }, // 100 * (1 + 0 * 0.1) = 100
      { upgradeLevel: 1, baseSellPrice: 100, expected: 110 }, // 100 * (1 + 1 * 0.1) = 110
      { upgradeLevel: 5, baseSellPrice: 100, expected: 150 }, // 100 * (1 + 5 * 0.1) = 150
      { upgradeLevel: 10, baseSellPrice: 100, expected: 200 }, // 100 * (1 + 10 * 0.1) = 200
    ]

    for (const testCase of testCases) {
      vi.clearAllMocks()

      mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
      mockRateLimit.mockResolvedValue(true)

      prismaMock.character.findUnique.mockResolvedValue({
        id: 'char-1',
        userId: 'user-1',
      })

      const inventoryItem = {
        id: 'inv-1',
        characterId: 'char-1',
        itemId: 'item-1',
        isEquipped: false,
        upgradeLevel: testCase.upgradeLevel,
        item: {
          id: 'item-1',
          sellPrice: testCase.baseSellPrice,
        },
      }

      prismaMock.equipmentInventory.findUnique.mockResolvedValue(inventoryItem)

      const updatedCharacter = {
        id: 'char-1',
        userId: 'user-1',
        gold: 1000 + testCase.expected,
      }

      const tx = {
        equipmentInventory: {
          delete: vi.fn(async () => inventoryItem),
        },
        character: {
          update: vi.fn(async () => updatedCharacter),
        },
      }

      prismaMock.$transaction.mockImplementation(async (callback) => callback(tx))

      const response = await POST(
        new Request('http://localhost/api/inventory/sell', {
          method: 'POST',
          body: JSON.stringify({ character_id: 'char-1', inventory_id: 'inv-1' }),
        }) as any,
      )

      expect(response.status).toBe(200)
      const data = await response.json()
      expect(data.soldFor).toBe(testCase.expected)
    }
  })

  it('verifies character ownership before selling', async () => {
    prismaMock.character.findUnique.mockResolvedValue({
      id: 'char-1',
      userId: 'different-user', // Not the current user
    })

    const response = await POST(
      new Request('http://localhost/api/inventory/sell', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', inventory_id: 'inv-1' }),
      }) as any,
    )

    expect(response.status).toBe(403)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Forbidden',
    })
  })

  it('verifies item belongs to character before selling', async () => {
    prismaMock.character.findUnique.mockResolvedValue({
      id: 'char-1',
      userId: 'user-1',
    })

    prismaMock.equipmentInventory.findUnique.mockResolvedValue({
      id: 'inv-1',
      characterId: 'char-2', // Not this character
      itemId: 'item-1',
      isEquipped: false,
      upgradeLevel: 0,
      item: {
        id: 'item-1',
        sellPrice: 500,
      },
    })

    const response = await POST(
      new Request('http://localhost/api/inventory/sell', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', inventory_id: 'inv-1' }),
      }) as any,
    )

    expect(response.status).toBe(403)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Item does not belong to this character',
    })
  })
})
