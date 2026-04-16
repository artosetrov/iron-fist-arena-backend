import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockBuildInventoryResponse,
  mockRecalculateDerivedStats,
  mockInvalidateSkillCache,
  mockInvalidatePassiveCache,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockBuildInventoryResponse: vi.fn(),
  mockRecalculateDerivedStats: vi.fn(),
  mockInvalidateSkillCache: vi.fn(),
  mockInvalidatePassiveCache: vi.fn(),
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

vi.mock('@/lib/game/inventory-response', () => ({
  buildInventoryResponse: mockBuildInventoryResponse,
}))

vi.mock('@/lib/game/equipment-stats', () => ({
  recalculateDerivedStats: mockRecalculateDerivedStats,
}))

vi.mock('@/lib/game/combat-loader', () => ({
  invalidateSkillCache: mockInvalidateSkillCache,
  invalidatePassiveCache: mockInvalidatePassiveCache,
}))

import { POST } from '@/app/api/inventory/equip/route'

function makeTx() {
  return {
    character: {
      findUnique: vi.fn(async () => ({ userId: 'user-1', level: 10, class: 'warrior' })),
    },
    $queryRawUnsafe: vi
      .fn()
      .mockResolvedValueOnce([
        {
          id: 'inv-1',
          characterId: 'char-1',
          isEquipped: false,
          equippedSlot: null,
          durability: 100,
          itemType: 'helmet',
          itemLevel: 1,
          classRestriction: null,
          catalogId: 'helmet-basic',
        },
      ])
      .mockResolvedValueOnce([]),
    equipmentInventory: {
      updateMany: vi.fn(async () => ({ count: 0 })),
      update: vi.fn(async () => ({})),
      findUnique: vi.fn(async () => null),
    },
  }
}

type EquipTx = ReturnType<typeof makeTx>

function mockTransaction(tx: EquipTx) {
  prismaMock.$transaction.mockImplementation(
    async (callback: (innerTx: EquipTx) => Promise<unknown>) => callback(tx),
  )
}

describe('POST /api/inventory/equip', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    mockRecalculateDerivedStats.mockResolvedValue({
      maxHp: 100,
      armor: 10,
      magicResist: 5,
    })
    mockInvalidateSkillCache.mockResolvedValue(undefined)
    mockInvalidatePassiveCache.mockResolvedValue(undefined)
    mockBuildInventoryResponse.mockResolvedValue({
      equipment: [],
      consumables: [],
      inventorySlots: 28,
    })
  })

  it('recalculates derived stats inside the equip transaction before returning the snapshot', async () => {
    const tx = makeTx()
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/inventory/equip', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', inventory_id: 'inv-1' }),
      }),
    )

    expect(response.status).toBe(200)
    expect(mockRecalculateDerivedStats).toHaveBeenCalledWith('char-1', tx)
    expect(tx.equipmentInventory.update).toHaveBeenCalledWith({
      where: { id: 'inv-1' },
      data: {
        isEquipped: true,
        equippedSlot: 'helmet',
      },
    })
    expect(mockInvalidateSkillCache).toHaveBeenCalledWith('char-1')
    expect(mockInvalidatePassiveCache).toHaveBeenCalledWith('char-1')
    await expect(response.json()).resolves.toMatchObject({
      equipment: [],
      consumables: [],
      inventorySlots: 28,
    })
  })
})
