'use server'

import { Prisma } from '@prisma/client'
import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import { auditLog } from '@/lib/audit-log'
import { sanitizeBattlePassRewardInput } from '@/lib/battle-pass-rewards'

export async function getBattlePassRewards(seasonId?: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const where = seasonId ? { seasonId } : {}
  return prisma.battlePassReward.findMany({
    where,
    orderBy: [{ bpLevel: 'asc' }, { isPremium: 'asc' }],
    include: { season: { select: { id: true, number: true, theme: true } } },
  })
}

export async function getSeasons() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.season.findMany({ orderBy: { startAt: 'desc' } })
}

export async function createBattlePassReward(data: {
  seasonId: string
  bpLevel: number
  isPremium: boolean
  rewardType: string
  rewardId?: string
  rewardAmount: number
}) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const payload = sanitizeBattlePassRewardInput(data)
  const reward = await prisma.battlePassReward.create({ data: payload })

  auditLog(admin, 'create_bp_reward', `bp-reward/${reward.id}`, {
    seasonId: payload.seasonId,
    bpLevel: payload.bpLevel,
    isPremium: payload.isPremium,
    rewardType: payload.rewardType,
    rewardId: payload.rewardId,
  })

  return reward
}

export async function updateBattlePassReward(
  id: string,
  data: {
    rewardType?: string
    rewardId?: string | null
    rewardAmount?: number
  }
) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const existing = await prisma.battlePassReward.findUnique({
    where: { id },
  })

  if (!existing) {
    throw new Error('Battle Pass reward not found')
  }

  const payload = sanitizeBattlePassRewardInput(data, existing)
  const reward = await prisma.battlePassReward.update({
    where: { id },
    data: {
      rewardType: payload.rewardType,
      rewardId: payload.rewardId,
      rewardAmount: payload.rewardAmount,
    },
  })

  auditLog(admin, 'update_bp_reward', `bp-reward/${id}`, {
    updatedFields: Object.keys(data),
    rewardType: payload.rewardType,
    rewardId: payload.rewardId,
    rewardAmount: payload.rewardAmount,
  })

  return reward
}

export async function deleteBattlePassReward(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const reward = await prisma.battlePassReward.findUnique({
    where: { id },
    select: { bpLevel: true, isPremium: true, seasonId: true },
  })

  await prisma.battlePassReward.delete({ where: { id } })

  auditLog(admin, 'delete_bp_reward', `bp-reward/${id}`, {
    bpLevel: reward?.bpLevel,
    isPremium: reward?.isPremium,
    seasonId: reward?.seasonId,
  })

  return { success: true }
}

export async function bulkCreateBattlePassRewards(
  seasonId: string,
  maxLevel: number
) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  if (!seasonId.trim()) throw new Error('Season is required')
  if (!Number.isInteger(maxLevel) || maxLevel < 1) {
    throw new Error('Max level must be a positive integer')
  }

  // Generate default rewards for all levels
  const rewards: Array<ReturnType<typeof sanitizeBattlePassRewardInput>> = []
  for (let level = 1; level <= maxLevel; level++) {
    // Free track
    rewards.push(
      sanitizeBattlePassRewardInput({
        seasonId,
        bpLevel: level,
        isPremium: false,
        rewardType: level % 5 === 0 ? 'gems' : 'gold',
        rewardAmount: level % 5 === 0 ? 1 : 100 * level,
      })
    )
    // Premium track
    rewards.push(
      sanitizeBattlePassRewardInput({
        seasonId,
        bpLevel: level,
        isPremium: true,
        rewardType: level % 5 === 0 ? 'gems' : 'gold',
        rewardAmount: level % 5 === 0 ? 3 : 200 * level,
      })
    )
  }

  // Only create rewards that don't already exist
  let created = 0
  for (const r of rewards) {
    try {
      await prisma.battlePassReward.create({ data: r })
      created++
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        continue
      }

      throw error
    }
  }

  auditLog(admin, 'bulk_create_bp_rewards', `season/${seasonId}`, {
    maxLevel,
    created,
  })

  return { created, total: rewards.length }
}
