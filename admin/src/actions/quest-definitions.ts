'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

export async function getQuestDefinitions() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.questDefinition.findMany({
    orderBy: [{ questType: 'asc' }],
  })
}

export async function createQuestDefinition(data: {
  questType: string
  title: string
  description: string
  icon?: string
  minTarget: number
  maxTarget: number
  rewardGold: number
  rewardXp: number
  rewardGems: number
}) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const def = await prisma.questDefinition.create({
    data,
  })

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'create_quest_definition',
      target: def.questType,
      details: data as never,
    },
  })

  return def
}

export async function updateQuestDefinition(
  id: string,
  data: {
    title?: string
    description?: string
    icon?: string
    minTarget?: number
    maxTarget?: number
    rewardGold?: number
    rewardXp?: number
    rewardGems?: number
    active?: boolean
  }
) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const def = await prisma.questDefinition.update({ where: { id }, data })

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'update_quest_definition',
      target: def.questType,
      details: data as never,
    },
  })

  return def
}

export async function deleteQuestDefinition(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const def = await prisma.questDefinition.delete({ where: { id } })

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'delete_quest_definition',
      target: def.questType,
    },
  })

  return { success: true }
}

export async function seedQuestDefinitions() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const catalog = [
    {
      questType: 'pvp_wins',
      title: 'Win PvP Battles',
      description: 'Win a certain number of PvP battles',
      icon: '⚔️',
      minTarget: 1,
      maxTarget: 100,
      rewardGold: 100,
      rewardXp: 50,
      rewardGems: 1,
    },
    {
      questType: 'dungeon_clears',
      title: 'Clear Dungeons',
      description: 'Complete a certain number of dungeon runs',
      icon: '🏰',
      minTarget: 1,
      maxTarget: 50,
      rewardGold: 150,
      rewardXp: 75,
      rewardGems: 1,
    },
    {
      questType: 'reach_level',
      title: 'Reach Level',
      description: 'Advance to a specific character level',
      icon: '📈',
      minTarget: 1,
      maxTarget: 100,
      rewardGold: 500,
      rewardXp: 0,
      rewardGems: 2,
    },
    {
      questType: 'gold_earned',
      title: 'Earn Gold',
      description: 'Accumulate a certain amount of gold',
      icon: '💰',
      minTarget: 1000,
      maxTarget: 1000000,
      rewardGold: 0,
      rewardXp: 100,
      rewardGems: 1,
    },
    {
      questType: 'items_equipped',
      title: 'Equip Items',
      description: 'Equip a certain number of items',
      icon: '🛡️',
      minTarget: 1,
      maxTarget: 100,
      rewardGold: 200,
      rewardXp: 50,
      rewardGems: 0,
    },
    {
      questType: 'bosses_defeated',
      title: 'Defeat Bosses',
      description: 'Defeat a certain number of boss enemies',
      icon: '👹',
      minTarget: 1,
      maxTarget: 50,
      rewardGold: 300,
      rewardXp: 150,
      rewardGems: 2,
    },
  ]

  let created = 0,
    skipped = 0
  for (const item of catalog) {
    const existing = await prisma.questDefinition.findUnique({
      where: { questType: item.questType },
    })
    if (existing) {
      skipped++
      continue
    }
    await prisma.questDefinition.create({
      data: item,
    })
    created++
  }

  return { created, skipped, total: catalog.length }
}
