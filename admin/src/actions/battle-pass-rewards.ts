'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import { auditLog } from '@/lib/audit-log'

export async function getBattlePassRewards(seasonId?: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const where = seasonId ? { seasonId } : {}
  return prisma.battlePassReward.findMany({
    where,
    orderBy: [{ bpLevel: 'asc' }, { isPremium: 'asc' }],
    include: { season: { select: { id: true, name: true } } },
  })
}

export async function getSeasons() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.season.findMany({ orderBy: { startDate: 'desc' } })
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

  const reward = await prisma.battlePassReward.create({ data })

  auditLog(admin, 'create_bp_reward', `bp-reward/${reward.id}`, {
    seasonId: data.seasonId,
    bpLevel: data.bpLevel,
    isPremium: data.isPremium,
    rewardType: data.rewardType,
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

  const reward = await prisma.battlePassReward.update({
    where: { id },
    data: {
      ...(data.rewardType !== undefined && { rewardType: data.rewardType }),
      ...(data.rewardId !== undefined && { rewardId: data.rewardId }),
      ...(data.rewardAmount !== undefined && { rewardAmount: data.rewardAmount }),
    },
  })

  auditLog(admin, 'update_bp_reward', `bp-reward/${id}`, {
    updatedFields: Object.keys(data),
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

  // Generate default rewards for all levels
  const rewards = []
  for (let level = 1; level <= maxLevel; level++) {
    // Free track
    rewards.push({
      seasonId,
      bpLevel: level,
      isPremium: false,
      rewardType: level % 5 === 0 ? 'gems' : 'gold',
      rewardAmount: level % 5 === 0 ? 1 : 100 * level,
    })
    // Premium track
    rewards.push({
      seasonId,
      bpLevel: level,
      isPremium: true,
      rewardType: level % 5 === 0 ? 'gems' : 'gold',
      rewardAmount: level % 5 === 0 ? 3 : 200 * level,
    })
  }

  // Only create rewards that don't already exist
  let created = 0
  for (const r of rewards) {
    try {
      await prisma.battlePassReward.create({ data: r })
      created++
    } catch {
      // Unique constraint violation = already exists, skip
    }
  }

  auditLog(admin, 'bulk_create_bp_rewards', `season/${seasonId}`, {
    maxLevel,
    created,
  })

  return { created, total: rewards.length }
}
