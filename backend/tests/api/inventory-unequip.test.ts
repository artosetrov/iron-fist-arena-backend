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
    character: {
      findUnique: vi.fn(),
    },
    equipmentInventory: {
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

import { POST } from '@/app/api/inventory/unequip/route'

function makeTx() {
  return {
    equipmentInventory: {
      update: vi.fn(async () => ({})),
    },
  }
}

type UnequipTx = ReturnType<typeof makeTx>

function mockTransaction(tx: UnequipTx) {
  prismaMock.$transaction.mockImplementation(
    async (callback: (innerTx: UnequipTx) => Promise<unknown>) => callback(tx),
  )
}

describe('POST /api/inventory/unequip', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    prismaMock.character.findUnique.mockResolvedValue({ userId: 'user-1' })
    prismaMock.equipmentInventory.findUnique.mockResolvedValue({
      id: 'inv-1',
      characterId: 'char-1',
      isEquipped: true,
    })
    mockRecalculateDerivedStats.mockResolvedValue({
      maxHp: 90,
      armor: 7,
      magicResist: 4,
    })
    mockInvalidateSkillCache.mockResolvedValue(undefined)
    mockInvalidatePassiveCache.mockResolvedValue(undefined)
    mockBuildInventoryResponse.mockResolvedValue({
      equipment: [],
      consumables: [],
      inventorySlots: 28,
    })
  })

  it('recalculates derived stats inside the unequip transaction before returning the snapshot', async () => {
    const tx = makeTx()
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/inventory/unequip', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', inventory_id: 'inv-1' }),
      }),
    )

    expect(response.status).toBe(200)
    expect(mockRecalculateDerivedStats).toHaveBeenCalledWith('char-1', tx)
    expect(tx.equipmentInventory.update).toHaveBeenCalledWith({
      where: { id: 'inv-1' },
      data: {
        isEquipped: false,
        equippedSlot: null,
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
