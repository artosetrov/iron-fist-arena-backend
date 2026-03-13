import type { PrismaClient } from '@prisma/client'
import { BATTLE_PASS_MILESTONE_CATALOG_IDS } from './battle-pass-milestones'

type BattlePassRepairClient = Pick<PrismaClient, 'item' | 'battlePassReward' | '$transaction'>

export async function repairBattlePassRewards(prisma: BattlePassRepairClient): Promise<number> {
  const milestoneLevels = Object.keys(BATTLE_PASS_MILESTONE_CATALOG_IDS).map((level) => Number(level))

  const milestoneItems = await prisma.item.findMany({
    where: {
      catalogId: { in: Object.values(BATTLE_PASS_MILESTONE_CATALOG_IDS) },
    },
    select: {
      id: true,
      catalogId: true,
      itemName: true,
    },
  })

  const itemIdByCatalogId = new Map(
    milestoneItems.map((item) => [item.catalogId, item.id]),
  )

  for (const catalogId of Object.values(BATTLE_PASS_MILESTONE_CATALOG_IDS)) {
    if (!itemIdByCatalogId.has(catalogId)) {
      throw new Error(
        `Battle pass repair requires item catalog "${catalogId}". Run the main item seed first.`,
      )
    }
  }

  const rewards = await prisma.battlePassReward.findMany({
    where: {
      isPremium: true,
      bpLevel: { in: milestoneLevels },
    },
    select: {
      id: true,
      seasonId: true,
      bpLevel: true,
      rewardType: true,
      rewardId: true,
      rewardAmount: true,
    },
    orderBy: [{ seasonId: 'asc' }, { bpLevel: 'asc' }],
  })

  let updatedCount = 0

  await prisma.$transaction(async (tx) => {
    for (const reward of rewards) {
      const expectedCatalogId = BATTLE_PASS_MILESTONE_CATALOG_IDS[reward.bpLevel]
      const expectedRewardId = itemIdByCatalogId.get(expectedCatalogId)

      if (!expectedRewardId) {
        throw new Error(`Missing item id for battle pass level ${reward.bpLevel}`)
      }

      if (
        reward.rewardType === 'item' &&
        reward.rewardId === expectedRewardId &&
        reward.rewardAmount === 1
      ) {
        continue
      }

      await tx.battlePassReward.update({
        where: { id: reward.id },
        data: {
          rewardType: 'item',
          rewardId: expectedRewardId,
          rewardAmount: 1,
        },
      })
      updatedCount += 1
    }
  })

  return updatedCount
}
