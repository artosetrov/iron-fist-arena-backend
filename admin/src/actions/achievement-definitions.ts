'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

export async function getAchievementDefinitions() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.achievementDefinition.findMany({
    orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { key: 'asc' }],
  })
}

export async function createAchievementDefinition(data: {
  key: string
  title: string
  description: string
  category: string
  target: number
  rewardType: string
  rewardAmount: number
  rewardId?: string
  icon?: string
  sortOrder?: number
}) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const def = await prisma.achievementDefinition.create({
    data: { ...data, sortOrder: data.sortOrder ?? 0 },
  })

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'create_achievement_definition',
      target: def.key,
      details: data as never,
    },
  })

  return def
}

export async function updateAchievementDefinition(
  id: string,
  data: {
    title?: string
    description?: string
    category?: string
    target?: number
    rewardType?: string
    rewardAmount?: number
    rewardId?: string | null
    icon?: string | null
    active?: boolean
    sortOrder?: number
  }
) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const def = await prisma.achievementDefinition.update({ where: { id }, data })

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'update_achievement_definition',
      target: def.key,
      details: data as never,
    },
  })

  return def
}

export async function deleteAchievementDefinition(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const def = await prisma.achievementDefinition.delete({ where: { id } })

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'delete_achievement_definition',
      target: def.key,
    },
  })

  return { success: true }
}

export async function seedAchievementDefinitions() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const catalog = [
    { key: 'pvp_first_blood', target: 1, category: 'pvp', rewardType: 'gold', rewardAmount: 100 },
    { key: 'pvp_wins_10', target: 10, category: 'pvp', rewardType: 'gold', rewardAmount: 500 },
    { key: 'pvp_wins_50', target: 50, category: 'pvp', rewardType: 'gems', rewardAmount: 2 },
    { key: 'pvp_wins_100', target: 100, category: 'pvp', rewardType: 'gems', rewardAmount: 5 },
    { key: 'pvp_wins_500', target: 500, category: 'pvp', rewardType: 'gems', rewardAmount: 10 },
    { key: 'pvp_streak_5', target: 5, category: 'pvp', rewardType: 'gold', rewardAmount: 1000 },
    { key: 'pvp_streak_10', target: 10, category: 'pvp', rewardType: 'gems', rewardAmount: 3 },
    { key: 'revenge_first', target: 1, category: 'revenge', rewardType: 'gold', rewardAmount: 300 },
    { key: 'revenge_wins_10', target: 10, category: 'revenge', rewardType: 'gems', rewardAmount: 2 },
    { key: 'reach_level_10', target: 10, category: 'progression', rewardType: 'gold', rewardAmount: 500 },
    { key: 'reach_level_25', target: 25, category: 'progression', rewardType: 'gems', rewardAmount: 2 },
    { key: 'reach_level_50', target: 50, category: 'progression', rewardType: 'gems', rewardAmount: 5 },
    { key: 'first_prestige', target: 1, category: 'prestige', rewardType: 'gems', rewardAmount: 10 },
    { key: 'prestige_3', target: 3, category: 'prestige', rewardType: 'gems', rewardAmount: 20 },
    { key: 'first_legendary', target: 1, category: 'equipment', rewardType: 'gold', rewardAmount: 1000 },
    { key: 'full_set', target: 1, category: 'equipment', rewardType: 'gems', rewardAmount: 3 },
    { key: 'upgrade_10', target: 1, category: 'equipment', rewardType: 'gems', rewardAmount: 5 },
    { key: 'equip_all_slots', target: 1, category: 'equipment', rewardType: 'gold', rewardAmount: 500 },
    { key: 'dungeon_first_clear', target: 1, category: 'dungeon', rewardType: 'gold', rewardAmount: 300 },
    { key: 'dungeon_all_easy', target: 1, category: 'dungeon', rewardType: 'gems', rewardAmount: 2 },
    { key: 'dungeon_all_hard', target: 1, category: 'dungeon', rewardType: 'gems', rewardAmount: 10 },
    { key: 'boss_no_damage', target: 1, category: 'dungeon', rewardType: 'gems', rewardAmount: 5 },
    { key: 'earn_gold_10k', target: 10000, category: 'economy', rewardType: 'gold', rewardAmount: 500 },
    { key: 'earn_gold_100k', target: 100000, category: 'economy', rewardType: 'gems', rewardAmount: 3 },
    { key: 'spend_gold_50k', target: 50000, category: 'economy', rewardType: 'gems', rewardAmount: 2 },
    { key: 'shell_game_win_10', target: 10, category: 'minigame', rewardType: 'gold', rewardAmount: 1000 },
    { key: 'rank_silver', target: 1200, category: 'ranking', rewardType: 'gems', rewardAmount: 1 },
    { key: 'rank_gold', target: 1500, category: 'ranking', rewardType: 'gems', rewardAmount: 3 },
    { key: 'rank_diamond', target: 1800, category: 'ranking', rewardType: 'gems', rewardAmount: 10 },
    { key: 'rank_grandmaster', target: 2200, category: 'ranking', rewardType: 'gems', rewardAmount: 25 },
    { key: 'login_7_days', target: 7, category: 'daily', rewardType: 'gems', rewardAmount: 2 },
    { key: 'login_30_days', target: 30, category: 'daily', rewardType: 'gems', rewardAmount: 10 },
    { key: 'daily_quest_100', target: 100, category: 'daily', rewardType: 'gems', rewardAmount: 5 },
  ]

  let created = 0, skipped = 0
  for (const item of catalog) {
    const existing = await prisma.achievementDefinition.findUnique({ where: { key: item.key } })
    if (existing) { skipped++; continue }
    const label = item.key.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
    await prisma.achievementDefinition.create({
      data: {
        ...item,
        title: label,
        description: `Reach ${item.target} ${item.key.replace(/_/g, ' ')}`,
      },
    })
    created++
  }

  return { created, skipped, total: catalog.length }
}
