import { beforeEach, describe, expect, it, vi } from 'vitest'

const {
  mockGetAuthUser,
  mockRateLimit,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  prismaMock: {
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

/**
 * Build a fake `tx` object that mirrors the current shape used by
 * `POST /api/inventory/sell` (see `backend/src/app/api/inventory/sell/route.ts`):
 *
 *   1. `tx.$queryRawUnsafe` → row-level lock on equipment_inventory
 *   2. `tx.character.findUnique` → ownership check
 *   3. `tx.item.findUnique` → sell price lookup
 *   4. `tx.equipmentInventory.delete` → remove the item
 *   5. `tx.user.update` → increment user.gold (account-level, not character-level)
 *
 * Each call-site in the test overrides only the pieces it needs.
 */
function makeTx(overrides: {
  invRow?: {
    id: string
    character_id: string
    is_equipped: boolean
    upgrade_level: number
    item_id: string
  } | null
  character?: { userId: string } | null
  item?: { sellPrice: number } | null
  updatedUserGold?: number
}) {
  const {
    invRow = null,
    character = null,
    item = null,
    updatedUserGold = 0,
  } = overrides

  return {
    $queryRawUnsafe: vi.fn(async () => (invRow ? [invRow] : [])),
    character: {
      findUnique: vi.fn(async () => character),
    },
    item: {
      findUnique: vi.fn(async () => item),
    },
    equipmentInventory: {
      delete: vi.fn(async () => ({})),
    },
    user: {
      update: vi.fn(async () => ({ id: 'user-1', gold: updatedUserGold })),
    },
  }
}

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
    const tx = makeTx({
      invRow: {
        id: 'inv-1',
        character_id: 'char-1',
        is_equipped: true,
        upgrade_level: 0,
        item_id: 'item-1',
      },
      character: { userId: 'user-1' },
      item: { sellPrice: 500 },
    })
    prismaMock.$transaction.mockImplementation(async (callback: any) => callback(tx))

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
    const tx = makeTx({ invRow: null })
    prismaMock.$transaction.mockImplementation(async (callback: any) => callback(tx))

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
    // baseSellPrice * (1 + upgradeLevel * 0.1) = 500 * (1 + 2 * 0.1) = 500 * 1.2 = 600
    // Starting user gold = 1000 → after increment = 1600
    const tx = makeTx({
      invRow: {
        id: 'inv-1',
        character_id: 'char-1',
        is_equipped: false,
        upgrade_level: 2,
        item_id: 'item-1',
      },
      character: { userId: 'user-1' },
      item: { sellPrice: 500 },
      updatedUserGold: 1600,
    })
    prismaMock.$transaction.mockImplementation(async (callback: any) => callback(tx))

    const response = await POST(
      new Request('http://localhost/api/inventory/sell', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', inventory_id: 'inv-1' }),
      }) as any,
    )

    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data).toMatchObject({
      gold: 1600,
      soldFor: 600,
    })
    expect(tx.equipmentInventory.delete).toHaveBeenCalledWith({ where: { id: 'inv-1' } })
    expect(tx.user.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { gold: { increment: 600 } },
    })
  })

  it('applies correct sell price formula with upgrade level', async () => {
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

      const tx = makeTx({
        invRow: {
          id: 'inv-1',
          character_id: 'char-1',
          is_equipped: false,
          upgrade_level: testCase.upgradeLevel,
          item_id: 'item-1',
        },
        character: { userId: 'user-1' },
        item: { sellPrice: testCase.baseSellPrice },
        updatedUserGold: 1000 + testCase.expected,
      })
      prismaMock.$transaction.mockImplementation(async (callback: any) => callback(tx))

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
    const tx = makeTx({
      invRow: {
        id: 'inv-1',
        character_id: 'char-1',
        is_equipped: false,
        upgrade_level: 0,
        item_id: 'item-1',
      },
      character: { userId: 'different-user' }, // Not the current user
      item: { sellPrice: 500 },
    })
    prismaMock.$transaction.mockImplementation(async (callback: any) => callback(tx))

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
    const tx = makeTx({
      invRow: {
        id: 'inv-1',
        character_id: 'char-2', // Not this character
        is_equipped: false,
        upgrade_level: 0,
        item_id: 'item-1',
      },
      character: { userId: 'user-1' },
      item: { sellPrice: 500 },
    })
    prismaMock.$transaction.mockImplementation(async (callback: any) => callback(tx))

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
