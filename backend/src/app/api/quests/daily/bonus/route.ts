import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { invalidatePassiveCache, invalidateSkillCache } from '@/lib/game/combat-loader'
import { grantRewardEntries } from '@/lib/game/reward-grants'

const BONUS_GOLD = 500
const BONUS_XP = 300
const BONUS_GEMS = 10

function getToday(): string {
  return new Date().toISOString().slice(0, 10)
}

/**
 * POST /api/quests/daily/bonus
 * Claim the daily completion bonus (all 3 quests done + rewards claimed).
 * Body: { character_id }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({ where: { id: character_id } })
    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const today = getToday()
    const result = await prisma.$transaction(async (tx) => {
      const [lockedCharacter] = await tx.$queryRawUnsafe<Array<{
        id: string
        user_id: string
        daily_bonus_date: Date | null
      }>>(
        `SELECT id, user_id, daily_bonus_date
           FROM characters
          WHERE id = $1
          FOR UPDATE`,
        character_id,
      )

      if (!lockedCharacter) throw new Error('CHARACTER_NOT_FOUND')
      if (lockedCharacter.user_id !== user.id) throw new Error('FORBIDDEN')

      if (
        lockedCharacter.daily_bonus_date
        && lockedCharacter.daily_bonus_date.toISOString().slice(0, 10) === today
      ) {
        throw new Error('ALREADY_CLAIMED')
      }

      const quests = await tx.dailyQuest.findMany({
        where: { characterId: character_id, day: today },
        select: { completed: true },
      })

      if (quests.length < 3) throw new Error('QUESTS_NOT_READY')
      if (!quests.every((q) => q.completed)) throw new Error('QUESTS_NOT_CLAIMED')

      const rewardResult = await grantRewardEntries(tx, {
        userId: user.id,
        characterId: character_id,
        rewards: [
          { type: 'gold', quantity: BONUS_GOLD },
          { type: 'gems', quantity: BONUS_GEMS },
          { type: 'xp', quantity: BONUS_XP },
        ],
      })

      await tx.character.update({
        where: { id: character_id },
        data: { dailyBonusDate: new Date() },
      })

      return rewardResult
    })

    if (result.levelUpResult?.leveledUp) {
      await Promise.all([
        invalidateSkillCache(character_id),
        invalidatePassiveCache(character_id),
      ])
    }

    return NextResponse.json({
      success: true,
      reward_gold: BONUS_GOLD,
      reward_xp: BONUS_XP,
      reward_gems: BONUS_GEMS,
      gold: result.gold,
      gems: result.gems,
      xp: result.xp,
      leveled_up: result.levelUpResult?.leveledUp ?? false,
      new_level: result.levelUpResult?.newLevel,
      stat_points_awarded: result.levelUpResult?.statPointsAwarded,
      passive_points_awarded: result.levelUpResult?.passivePointsAwarded,
    })
  } catch (error: unknown) {
    if (error instanceof Error) {
      if (error.message === 'CHARACTER_NOT_FOUND') {
        return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      }
      if (error.message === 'FORBIDDEN') {
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      }
      if (error.message === 'ALREADY_CLAIMED') {
        return NextResponse.json({ error: 'Daily bonus already claimed today' }, { status: 400 })
      }
      if (error.message === 'QUESTS_NOT_READY') {
        return NextResponse.json({ error: 'Not all quests generated yet' }, { status: 400 })
      }
      if (error.message === 'QUESTS_NOT_CLAIMED') {
        return NextResponse.json({ error: 'Claim all quest rewards first' }, { status: 400 })
      }
    }
    console.error('daily bonus error:', error)
    return NextResponse.json({ error: 'Failed to claim daily bonus' }, { status: 500 })
  }
}
