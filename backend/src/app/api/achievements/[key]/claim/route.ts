import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ACHIEVEMENT_CATALOG } from '@/lib/game/achievement-catalog'
import { applyLevelUp } from '@/lib/game/progression'
import { awardBattlePassXp } from '@/lib/game/battle-pass'
import { BATTLE_PASS } from '@/lib/game/balance'

/**
 * POST /api/achievements/[key]/claim
 * URL param: key = achievement_key
 * Body: { character_id }
 * Claims the reward for a completed achievement.
 */
export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ key: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id } = body
    const { key: achievement_key } = await params

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const def = ACHIEVEMENT_CATALOG[achievement_key]
    if (!def) {
      return NextResponse.json({ error: 'Invalid achievement key' }, { status: 400 })
    }

    // Use interactive transaction with row-level lock to prevent double-claim
    await prisma.$transaction(async (tx) => {
      // Verify character ownership
      const character = await tx.character.findUnique({ where: { id: character_id } })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Lock the achievement row for update to prevent double-claim
      const [achievementRow] = await tx.$queryRawUnsafe<Array<{
        id: string; completed: boolean; progress: number; reward_claimed: boolean;
      }>>(
        `SELECT id, completed, progress, reward_claimed FROM achievements WHERE character_id = $1 AND achievement_key = $2 FOR UPDATE`,
        character_id,
        achievement_key
      )

      if (!achievementRow) throw new Error('ACHIEVEMENT_NOT_FOUND')

      const isCompleted = achievementRow.completed || achievementRow.progress >= def.target
      if (!isCompleted) throw new Error('NOT_COMPLETED')
      if (achievementRow.reward_claimed) throw new Error('ALREADY_CLAIMED')

      if (def.rewardType === 'gold') {
        await tx.character.update({
          where: { id: character_id },
          data: { gold: { increment: def.rewardAmount } },
        })
      } else if (def.rewardType === 'gems') {
        await tx.user.update({
          where: { id: user.id },
          data: { gems: { increment: def.rewardAmount } },
        })
      } else if (def.rewardType === 'xp') {
        await tx.character.update({
          where: { id: character_id },
          data: { currentXp: { increment: def.rewardAmount } },
        })
      }

      await tx.achievement.update({
        where: { id: achievementRow.id },
        data: { completed: true, rewardClaimed: true },
      })
    })

    // Award Battle Pass XP for achievement claim
    await awardBattlePassXp(prisma, character_id, BATTLE_PASS.BP_XP_PER_ACHIEVEMENT)

    // Check for level-up if XP was awarded
    let levelUpResult = null
    if (def.rewardType === 'xp') {
      levelUpResult = await applyLevelUp(prisma, character_id)
    }

    return NextResponse.json({
      achievement_key,
      reward: {
        type: def.rewardType,
        amount: def.rewardAmount,
      },
      leveled_up: levelUpResult?.leveledUp ?? false,
      new_level: levelUpResult?.newLevel,
      stat_points_awarded: levelUpResult?.statPointsAwarded,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'ACHIEVEMENT_NOT_FOUND') return NextResponse.json({ error: 'Achievement not found' }, { status: 404 })
      if (error.message === 'NOT_COMPLETED') return NextResponse.json({ error: 'Achievement not yet completed' }, { status: 400 })
      if (error.message === 'ALREADY_CLAIMED') return NextResponse.json({ error: 'Reward already claimed' }, { status: 400 })
    }
    console.error('claim achievement [key] error:', error)
    return NextResponse.json({ error: 'Failed to claim achievement reward' }, { status: 500 })
  }
}
