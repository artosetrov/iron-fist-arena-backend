import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ACHIEVEMENT_CATALOG } from '@/lib/game/achievement-catalog'

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

    const character = await prisma.character.findUnique({ where: { id: character_id } })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const def = ACHIEVEMENT_CATALOG[achievement_key]
    if (!def) {
      return NextResponse.json({ error: 'Invalid achievement key' }, { status: 400 })
    }

    const achievement = await prisma.achievement.findUnique({
      where: {
        characterId_achievementKey: { characterId: character_id, achievementKey: achievement_key },
      },
    })

    if (!achievement) {
      return NextResponse.json({ error: 'Achievement not found' }, { status: 404 })
    }

    if (!achievement.completed) {
      return NextResponse.json({ error: 'Achievement not yet completed' }, { status: 400 })
    }

    if (achievement.rewardClaimed) {
      return NextResponse.json({ error: 'Reward already claimed' }, { status: 400 })
    }

    if (def.rewardType === 'gold') {
      await prisma.character.update({
        where: { id: character_id },
        data: { gold: { increment: def.rewardAmount } },
      })
    } else if (def.rewardType === 'gems') {
      await prisma.user.update({
        where: { id: user.id },
        data: { gems: { increment: def.rewardAmount } },
      })
    } else if (def.rewardType === 'xp') {
      await prisma.character.update({
        where: { id: character_id },
        data: { currentXp: { increment: def.rewardAmount } },
      })
    }

    await prisma.achievement.update({
      where: { id: achievement.id },
      data: { rewardClaimed: true },
    })

    return NextResponse.json({
      achievement_key,
      reward: {
        type: def.rewardType,
        amount: def.rewardAmount,
      },
    })
  } catch (error) {
    console.error('claim achievement [key] error:', error)
    return NextResponse.json({ error: 'Failed to claim achievement reward' }, { status: 500 })
  }
}
