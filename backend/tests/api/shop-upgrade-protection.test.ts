/**
 * POST /api/shop/upgrade — Protection Scrolls are consumed before gems
 * (2026-10-14). Adventurer's Bundles had been granting scrolls that nothing
 * spent; the route only knew the 40-gem path.
 */
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const { mockGetAuthUser, mockRateLimit, prismaMock } = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  prismaMock: { $transaction: vi.fn(), equipmentInventory: { findUnique: vi.fn() } },
}))

vi.mock('@/lib/auth', () => ({ getAuthUser: mockGetAuthUser }))
vi.mock('@/lib/prisma', () => ({ prisma: prismaMock }))
vi.mock('@/lib/rate-limit', () => ({ rateLimit: mockRateLimit, shopRateLimit: mockRateLimit }))
vi.mock('@/lib/game/live-config', () => ({
  getUpgradeChancesConfig: vi.fn(async () => [100, 100, 100, 100, 100, 80, 60, 40, 30, 20]),
}))
vi.mock('@/lib/game/item-balance', () => ({
  getUpgradeCost: vi.fn(async () => 1000),
  getUpgradeSuccessChance: vi.fn(async () => 0), // every roll fails — we are testing the failure branch
  getUpgradeProtectionCost: vi.fn(async () => 40),
  getUpgradeDowngradeThreshold: vi.fn(async () => 8),
  getUpgradeStatBonus: vi.fn(async () => 0.05),
}))
vi.mock('@/lib/game/daily-quests', () => ({ updateDailyQuestProgress: vi.fn() }))
vi.mock('@/lib/game/weekly-challenges', () => ({ updateWeeklyChallengeProgress: vi.fn() }))
vi.mock('@/lib/game/equipment-stats', () => ({ recalculateDerivedStats: vi.fn() }))
vi.mock('@/lib/game/combat-loader', () => ({ invalidateSkillCache: vi.fn(), invalidatePassiveCache: vi.fn() }))
vi.mock('@/lib/game/guild-challenge', () => ({ incrementGuildChallenge: vi.fn(async () => undefined) }))
vi.mock('@/lib/analytics', () => ({ track: vi.fn() }))

import { POST } from '@/app/api/shop/upgrade/route'

const inventoryItem = {
  id: 'inv-1',
  characterId: 'char-1',
  upgradeLevel: 8, // attempting +9: failure downgrades without protection
  isEquipped: false,
  rolledStats: null,
  item: { catalogId: 'wpn_soulreaver', baseStats: { str: 50 } },
}

function makeTx(opts: { gems: number; scrolls: number | null }) {
  const tx = {
    $queryRawUnsafe: vi.fn(async (sql: string) => {
      if (sql.includes('FROM users')) return [{ id: 'user-1', gold: 50_000, gems: opts.gems }]
      if (sql.includes('consumable_inventory')) return opts.scrolls === null ? [] : [{ quantity: opts.scrolls }]
      throw new Error(`unexpected raw query: ${sql}`)
    }),
    character: { findUnique: vi.fn(async () => ({ userId: 'user-1' })) },
    user: { update: vi.fn(async ({ data }: { data: Record<string, { decrement: number }> }) => ({ gold: 49_000, gems: opts.gems - (data.gems?.decrement ?? 0) })) },
    equipmentInventory: { update: vi.fn(async () => ({ ...inventoryItem, upgradeLevel: 7 })) },
    consumableInventory: { update: vi.fn(async () => ({ quantity: (opts.scrolls ?? 1) - 1 })) },
  }
  prismaMock.$transaction.mockImplementation(async (fn: (t: typeof tx) => Promise<unknown>) => fn(tx))
  return tx
}

function upgrade(useProtection: boolean) {
  return POST(
    makeNextRequest('http://localhost/api/shop/upgrade', {
      method: 'POST',
      body: JSON.stringify({ character_id: 'char-1', inventory_id: 'inv-1', use_protection: useProtection }),
    }),
  )
}

describe('POST /api/shop/upgrade — protection source', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    prismaMock.equipmentInventory.findUnique.mockResolvedValue(inventoryItem)
  })

  it('spends a scroll, not gems, when the character owns one', async () => {
    const tx = makeTx({ gems: 0, scrolls: 2 })
    const response = await upgrade(true)
    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      success: false,
      protection_used: true,
      protection_source: 'scroll',
      protection_scrolls_remaining: 1,
      level_lost: false,
      newLevel: 8,
    })
    expect(tx.consumableInventory.update).toHaveBeenCalledWith({
      where: { characterId_consumableType: { characterId: 'char-1', consumableType: 'protection_scroll' } },
      data: { quantity: { decrement: 1 } },
    })
    // gold was charged (one update), gems were not (no second update)
    expect(tx.user.update).toHaveBeenCalledTimes(1)
    expect(tx.user.update.mock.calls[0][0]).toMatchObject({ data: { gold: { decrement: 1000 } } })
    expect(tx.equipmentInventory.update).not.toHaveBeenCalled()
    // the scroll row was locked
    expect(tx.$queryRawUnsafe.mock.calls.some(([sql]) => sql.includes('consumable_inventory') && sql.includes('FOR UPDATE'))).toBe(true)
  })

  it('falls back to gems when no scroll is owned', async () => {
    const tx = makeTx({ gems: 100, scrolls: null })
    const response = await upgrade(true)
    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      protection_used: true,
      protection_source: 'gems',
      protection_scrolls_remaining: 0,
      gems: 60,
    })
    expect(tx.consumableInventory.update).not.toHaveBeenCalled()
    expect(tx.user.update).toHaveBeenCalledTimes(2)
  })

  it('refuses up front with neither scrolls nor gems, before spending gold', async () => {
    const tx = makeTx({ gems: 10, scrolls: 0 })
    const response = await upgrade(true)
    expect(response.status).toBe(400)
    expect(tx.user.update).not.toHaveBeenCalled()
  })

  it('does not look at scrolls when protection is not requested, and downgrades at +9', async () => {
    const tx = makeTx({ gems: 0, scrolls: 5 })
    const response = await upgrade(false)
    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({ protection_used: false, protection_source: null, level_lost: true, newLevel: 7 })
    expect(tx.$queryRawUnsafe.mock.calls.some(([sql]) => sql.includes('consumable_inventory'))).toBe(false)
    expect(tx.consumableInventory.update).not.toHaveBeenCalled()
  })
})
