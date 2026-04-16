import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { TUTORIAL_QUESTS } from '@/lib/game/tutorial'
import { logTutorialEvent } from '@/lib/game/tutorial-analytics'
import type { TutorialQuestDef, TutorialQuestRewards } from '@/lib/game/tutorial'

type TutorialQuestAction = 'progress' | 'claim'

type TutorialQuestBody = {
  character_id?: string
  quest_id?: string
  action?: TutorialQuestAction
  amount?: number
}

function isTutorialQuestError(
  error: unknown,
  code:
    | 'NOT_FOUND'
    | 'FORBIDDEN'
    | 'QUEST_LOCKED'
    | 'USER_NOT_FOUND'
    | 'QUEST_NOT_FOUND'
    | 'QUEST_NOT_COMPLETED'
    | 'ALREADY_CLAIMED'
    | 'ITEM_REWARD_NOT_FOUND'
    | 'INVALID_CONSUMABLE_REWARD',
): error is Error {
  return error instanceof Error && error.message === code
}

function hasConsumableReward(
  rewards: TutorialQuestRewards,
): rewards is TutorialQuestRewards & {
  consumable_type: NonNullable<TutorialQuestRewards['consumable_type']>
  consumable_amount: number
} {
  return Boolean(rewards.consumable_type && rewards.consumable_amount)
}

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
    const body = await req.json() as TutorialQuestBody
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

    if (action === 'progress' && (!Number.isInteger(amount) || amount <= 0)) {
      return NextResponse.json({ error: 'amount must be a positive integer' }, { status: 400 })
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
    if (isTutorialQuestError(error, 'NOT_FOUND')) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (isTutorialQuestError(error, 'FORBIDDEN')) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }
    if (isTutorialQuestError(error, 'QUEST_LOCKED')) {
      return NextResponse.json({ error: 'Quest not unlocked yet' }, { status: 409 })
    }
    if (isTutorialQuestError(error, 'USER_NOT_FOUND')) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }
    if (isTutorialQuestError(error, 'QUEST_NOT_FOUND')) {
      return NextResponse.json({ error: 'Quest not found' }, { status: 404 })
    }
    if (isTutorialQuestError(error, 'QUEST_NOT_COMPLETED')) {
      return NextResponse.json({ error: 'Quest not completed yet' }, { status: 400 })
    }
    if (isTutorialQuestError(error, 'ALREADY_CLAIMED')) {
      return NextResponse.json({ error: 'Reward already claimed' }, { status: 409 })
    }
    if (
      isTutorialQuestError(error, 'ITEM_REWARD_NOT_FOUND')
      || isTutorialQuestError(error, 'INVALID_CONSUMABLE_REWARD')
    ) {
      return NextResponse.json({ error: 'Tutorial quest reward is misconfigured' }, { status: 500 })
    }
    console.error('tutorial quest error:', error)
    return NextResponse.json({ error: 'Failed to update quest' }, { status: 500 })
  }
}

async function handleProgress(
  userId: string,
  characterId: string,
  questId: string,
  questDef: TutorialQuestDef,
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
  questDef: TutorialQuestDef
) {
  const result = await prisma.$transaction(async (tx) => {
    // Verify character exists and ownership
    const character = await tx.character.findUnique({
      where: { id: characterId },
      select: { userId: true },
    })
    if (!character) throw new Error('NOT_FOUND')
    if (character.userId !== userId) throw new Error('FORBIDDEN')

    // Lock user row for gold update
    const [userRow] = await tx.$queryRawUnsafe<
      Array<{ id: string; gold: number }>
    >(
      `SELECT id, gold FROM users WHERE id = $1 FOR UPDATE`,
      userId
    )
    if (!userRow) throw new Error('USER_NOT_FOUND')

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
      await tx.user.update({
        where: { id: userId },
        data: { gold: { increment: rewards.gold } },
      })
    }

    if (rewards.consumable_type && !rewards.consumable_amount) {
      throw new Error('INVALID_CONSUMABLE_REWARD')
    }

    if (hasConsumableReward(rewards)) {
      await tx.consumableInventory.upsert({
        where: {
          characterId_consumableType: {
            characterId,
            consumableType: rewards.consumable_type,
          },
        },
        update: { quantity: { increment: rewards.consumable_amount } },
        create: {
          characterId,
          consumableType: rewards.consumable_type,
          quantity: rewards.consumable_amount,
        },
      })
    }

    if (rewards.item_catalog_id) {
      const item = await tx.item.findUnique({
        where: { catalogId: rewards.item_catalog_id },
      })
      if (!item) {
        throw new Error('ITEM_REWARD_NOT_FOUND')
      }
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
