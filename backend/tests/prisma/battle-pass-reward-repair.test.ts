import { describe, expect, it, vi } from 'vitest'
import { repairBattlePassRewards } from '../../prisma/battle-pass-reward-repair'

describe('repairBattlePassRewards', () => {
  it('rewrites legacy premium milestone rewards to canonical item rewards', async () => {
    const update = vi.fn().mockResolvedValue(null)
    const prisma = {
      item: {
        findMany: vi.fn().mockResolvedValue([
          { id: 'item-10', catalogId: 'chest_chain_mail', itemName: 'Chain Mail' },
          { id: 'item-20', catalogId: 'chest_plate_armor', itemName: 'Plate Armor' },
          { id: 'item-30', catalogId: 'chest_titan_cuirass', itemName: 'Titan Cuirass' },
        ]),
      },
      battlePassReward: {
        findMany: vi.fn().mockResolvedValue([
          { id: 'reward-10', seasonId: 'season-1', bpLevel: 10, rewardType: 'chest', rewardId: null, rewardAmount: 1 },
          { id: 'reward-20', seasonId: 'season-1', bpLevel: 20, rewardType: 'item', rewardId: 'wrong-item', rewardAmount: 2 },
          { id: 'reward-30', seasonId: 'season-1', bpLevel: 30, rewardType: 'item', rewardId: 'item-30', rewardAmount: 1 },
        ]),
      },
      $transaction: vi.fn(async (fn: (tx: { battlePassReward: { update: typeof update } }) => Promise<void>) =>
        fn({ battlePassReward: { update } })),
    }

    const updatedCount = await repairBattlePassRewards(prisma as never)

    expect(updatedCount).toBe(2)
    expect(update).toHaveBeenCalledTimes(2)
    expect(update).toHaveBeenNthCalledWith(1, {
      where: { id: 'reward-10' },
      data: { rewardType: 'item', rewardId: 'item-10', rewardAmount: 1 },
    })
    expect(update).toHaveBeenNthCalledWith(2, {
      where: { id: 'reward-20' },
      data: { rewardType: 'item', rewardId: 'item-20', rewardAmount: 1 },
    })
  })

  it('fails fast when a required milestone item is missing', async () => {
    const prisma = {
      item: {
        findMany: vi.fn().mockResolvedValue([
          { id: 'item-10', catalogId: 'chest_chain_mail', itemName: 'Chain Mail' },
        ]),
      },
      battlePassReward: {
        findMany: vi.fn(),
      },
      $transaction: vi.fn(),
    }

    await expect(repairBattlePassRewards(prisma as never)).rejects.toThrow(
      'Battle pass repair requires item catalog "chest_plate_armor". Run the main item seed first.',
    )
  })
})
