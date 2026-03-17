import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getAchievementCatalog } from '@/lib/game/achievement-catalog'
import { applyLevelUp } from '@/lib/game/progression'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`achievements-claim:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, achievement_key } = body

    if (!character_id || !achievement_key) {
      return NextResponse.json(
        { error: 'character_id and achievement_key are required' },
        { status: 400 }
      )
    }

    // Validate achievement key exists in catalog (DB-driven with hardcoded fallback)
    const catalog = await getAchievementCatalog()
    const def = catalog[achievement_key]
    if (!def) {
      return NextResponse.json({ error: 'Invalid achievement key' }, { status: 400 })
    }

    // Atomic read-check-write in interactive transaction with FOR UPDATE
    const result = await prisma.$transaction(async (tx) => {
      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { id: true, userId: true },
      })

      if (!character) throw new Error('CHARACTER_NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Lock the achievement row with FOR UPDATE via raw query
      const achievements = await tx.$queryRawUnsafe<any[]>(
        `SELECT id, progress, completed, reward_claimed AS "rewardClaimed"
         FROM achievements
         WHERE character_id = $1 AND achievement_key = $2
         FOR UPDATE`,
        character_id, achievement_key
      )

      const achievement = achievements[0]
      if (!achievement) throw new Error('ACHIEVEMENT_NOT_FOUND')

      const isCompleted = achievement.completed || achievement.progress >= def.target
      if (!isCompleted) throw new Error('NOT_COMPLETED')
      if (achievement.rewardClaimed) throw new Error('ALREADY_CLAIMED')

      // Apply reward
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

      // Mark as completed and claimed
      await tx.achievement.update({
        where: { id: achievement.id },
        data: { completed: true, rewardClaimed: true },
      })

      return { rewardType: def.rewardType, rewardAmount: def.rewardAmount }
    })

    // Check for level-up if XP was awarded (outside tx is fine)
    let levelUpResult = null
    if (result.rewardType === 'xp') {
      levelUpResult = await applyLevelUp(prisma, character_id)
    }

    return NextResponse.json({
      achievement_key,
      reward: {
        type: result.rewardType,
        amount: result.rewardAmount,
      },
      leveled_up: levelUpResult?.leveledUp ?? false,
      new_level: levelUpResult?.newLevel,
      stat_points_awarded: levelUpResult?.statPointsAwarded,
    })
  } catch (error: any) {
    if (error.message === 'CHARACTER_NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    if (error.message === 'ACHIEVEMENT_NOT_FOUND') return NextResponse.json({ error: 'Achievement not found' }, { status: 404 })
    if (error.message === 'NOT_COMPLETED') return NextResponse.json({ error: 'Achievement not yet completed' }, { status: 400 })
    if (error.message === 'ALREADY_CLAIMED') return NextResponse.json({ error: 'Reward already claimed' }, { status: 400 })

    console.error('claim achievement error:', error)
    return NextResponse.json(
      { error: 'Failed to claim achievement reward' },
      { status: 500 }
    )
  }
}
