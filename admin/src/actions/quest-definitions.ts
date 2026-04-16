'use server'

import { Prisma } from '@prisma/client'
import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import {
  sanitizeQuestDefinitionInput,
  type QuestDefinitionInput,
} from '@/lib/quest-definitions'

export async function getQuestDefinitions() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.questDefinition.findMany({
    orderBy: [{ questType: 'asc' }],
  })
}

export async function createQuestDefinition(data: QuestDefinitionInput) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const payload = sanitizeQuestDefinitionInput(data)
  const existing = await prisma.questDefinition.findUnique({
    where: { questType: payload.questType },
    select: { id: true },
  })

  if (existing) {
    throw new Error('Quest type already exists')
  }

  const def = await prisma.questDefinition.create({
    data: payload,
  })

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'create_quest_definition',
      target: def.questType,
      details: payload as Prisma.InputJsonValue,
    },
  })

  return def
}

export async function updateQuestDefinition(
  id: string,
  data: QuestDefinitionInput
) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const existing = await prisma.questDefinition.findUnique({
    where: { id },
  })

  if (!existing) {
    throw new Error('Quest definition not found')
  }

  const payload = sanitizeQuestDefinitionInput(data, existing)

  const def = await prisma.questDefinition.update({
    where: { id },
    data: {
      title: payload.title,
      description: payload.description,
      icon: payload.icon,
      minTarget: payload.minTarget,
      maxTarget: payload.maxTarget,
      rewardGold: payload.rewardGold,
      rewardXp: payload.rewardXp,
      rewardGems: payload.rewardGems,
      active: payload.active,
    },
  })

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'update_quest_definition',
      target: def.questType,
      details: {
        id,
        ...payload,
      } as Prisma.InputJsonValue,
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
      icon: 'building-arena',
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
      icon: 'building-dungeon',
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
      icon: 'reward-level-up',
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
      icon: 'building-shop',
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
      icon: 'item-upgrade',
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
      icon: 'boss-straw-dummy',
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
    const payload = sanitizeQuestDefinitionInput(item)
    const existing = await prisma.questDefinition.findUnique({
      where: { questType: payload.questType },
    })
    if (existing) {
      skipped++
      continue
    }
    await prisma.questDefinition.create({
      data: payload,
    })
    created++
  }

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'seed_quest_definitions',
      target: 'quest-definitions',
      details: {
        created,
        skipped,
        total: catalog.length,
      } as Prisma.InputJsonValue,
    },
  })

  return { created, skipped, total: catalog.length }
}
