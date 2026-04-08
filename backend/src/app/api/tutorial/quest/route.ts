import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { TUTORIAL_QUESTS } from '@/lib/game/tutorial'
import { logTutorialEvent } from '@/lib/game/tutorial-analytics'

/**
 * POST /api/tutorial/quest
 * Update quest progress or claim reward.
 * Body: { character_id, quest_id, action: "progress" | "claim", amount?: number }
 *
 * action="progress": increment quest progress by amount (default 1)
 * action="claim": claim reward for completed quest
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`tutorial-quest:${user.id}`, 30, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, quest_id, action, amount = 1 } = body

    if (!character_id || !quest_id || !action) {
      return NextResponse.json(
        { error: 'character_id, quest_id, and action are required' },
        { status: 400 }
      )
    }

    if (action !== 'progress' && action !== 'claim') {
      return NextResponse.json({ error: 'action must be "progress" or "claim"' }, { status: 400 })
    }

    const questDef = TUTORIAL_QUESTS.find((q) => q.id === quest_id)
    if (!questDef) {
      return NextResponse.json({ error: 'Unknown quest_id' }, { status: 400 })
    }

    if (action === 'progress') {
      return await handleProgress(user.id, character_id, quest_id, questDef, amount)
    } else {
      return await handleClaim(user.id, character_id, quest_id, questDef)
    }
  } catch (error) {
    console.error('tutorial quest error:', error)
    return NextResponse.json({ error: 'Failed to update quest' }, { status: 500 })
  }
}

async function handleProgress(
  userId: string,
  characterId: string,
  questId: string,
  questDef: (typeof TUTORIAL_QUESTS)[number],
  amount: number
) {
  const result = await prisma.$transaction(async (tx) => {
    // Verify ownership
    const character = await tx.character.findUnique({
      where: { id: characterId },
      select: { userId: true, level: true },
    })
    if (!character) throw new Error('NOT_FOUND')
    if (character.userId !== userId) throw new Error('FORBIDDEN')

    // Ensure quest exists (create if character reached unlock level)
    let quest = await tx.tutorialQuest.findUnique({
      where: {
        characterId_questId: { characterId, questId },
      },
    })

    if (!quest) {
      if (character.level < questDef.unlockLevel) {
        throw new Error('QUEST_LOCKED')
      }
      quest = await tx.tutorialQuest.create({
        data: {
          characterId,
          questId,
          target: questDef.target,
        },
      })
    }

    if (quest.isCompleted) {
      return { quest, justCompleted: false }
    }

    const newProgress = Math.min(quest.progress + amount, quest.target)
    const justCompleted = newProgress >= quest.target

    const updated = await tx.tutorialQuest.update({
      where: { id: quest.id },
      data: {
        progress: newProgress,
        isCompleted: justCompleted,
        completedAt: justCompleted ? new Date() : undefined,
      },
    })

    return { quest: updated, justCompleted }
  })

  if (result.justCompleted) {
    logTutorialEvent({
      event: 'tutorial_quest_done',
      characterId,
      questId,
      progress: result.quest.progress,
      target: result.quest.target,
    })
  }

  return NextResponse.json({
    quest: result.quest,
    justCompleted: result.justCompleted,
  })
}

async function handleClaim(
  userId: string,
  characterId: string,
  questId: string,
  questDef: (typeof TUTORIAL_QUESTS)[number]
) {
  const result = await prisma.$transaction(async (tx) => {
    // Lock character for gold/item updates
    const [character] = await tx.$queryRawUnsafe<
      Array<{ id: string; user_id: string; gold: number }>
    >(
      `SELECT id, user_id, gold FROM characters WHERE id = $1 FOR UPDATE`,
      characterId
    )
    if (!character) throw new Error('NOT_FOUND')
    if (character.user_id !== userId) throw new Error('FORBIDDEN')

    const quest = await tx.tutorialQuest.findUnique({
      where: {
        characterId_questId: { characterId, questId },
      },
    })

    if (!quest) throw new Error('QUEST_NOT_FOUND')
    if (!quest.isCompleted) throw new Error('QUEST_NOT_COMPLETED')
    if (quest.rewardClaimed) throw new Error('ALREADY_CLAIMED')

    // Mark as claimed
    await tx.tutorialQuest.update({
      where: { id: quest.id },
      data: { rewardClaimed: true },
    })

    // Apply rewards
    const rewards = questDef.rewards
    let goldDelta = 0

    if (rewards.gold) {
      goldDelta = rewards.gold
      await tx.character.update({
        where: { id: characterId },
        data: { gold: { increment: rewards.gold } },
      })
    }

    if (rewards.consumable_type && rewards.consumable_amount) {
      await tx.consumableInventory.upsert({
        where: {
          characterId_consumableType: {
            characterId,
            consumableType: rewards.consumable_type as any,
          },
        },
        update: { quantity: { increment: rewards.consumable_amount } },
        create: {
          characterId,
          consumableType: rewards.consumable_type as any,
          quantity: rewards.consumable_amount,
        },
      })
    }

    if (rewards.item_catalog_id) {
      const item = await tx.item.findUnique({
        where: { catalogId: rewards.item_catalog_id },
      })
      if (item) {
        await tx.equipmentInventory.create({
          data: {
            characterId,
            itemId: item.id,
            upgradeLevel: 0,
            durability: 100,
            maxDurability: 100,
            isEquipped: false,
          },
        })
      }
    }

    // BP levels handled separately if needed (future)

    return { goldDelta, rewards }
  })

  logTutorialEvent({
    event: 'tutorial_quest_claim',
    characterId,
    questId,
    goldDelta: result.goldDelta,
  })

  return NextResponse.json({
    claimed: true,
    goldDelta: result.goldDelta,
    rewards: result.rewards,
  })
}
