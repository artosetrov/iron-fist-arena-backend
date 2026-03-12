import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ACHIEVEMENT_CATALOG } from '@/lib/game/achievement-catalog'

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')

    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Get existing achievements
    let achievements = await prisma.achievement.findMany({
      where: { characterId },
      orderBy: { achievementKey: 'asc' },
    })

    // If no achievements exist, initialize from catalog
    if (achievements.length === 0) {
      const catalogKeys = Object.keys(ACHIEVEMENT_CATALOG)

      const createData = catalogKeys.map((key) => ({
        characterId,
        achievementKey: key,
        target: ACHIEVEMENT_CATALOG[key].target,
        progress: 0,
        completed: false,
        rewardClaimed: false,
      }))

      await prisma.achievement.createMany({ data: createData })

      achievements = await prisma.achievement.findMany({
        where: { characterId },
        orderBy: { achievementKey: 'asc' },
      })
    }

    // Enrich with catalog metadata and transform to iOS-compatible format
    const enriched = achievements.map((a) => {
      const def = ACHIEVEMENT_CATALOG[a.achievementKey]
      const rewardType = def?.rewardType ?? 'gold'
      const rewardAmount = def?.rewardAmount ?? 0
      const reward =
        rewardType === 'gold'
          ? { gold: rewardAmount }
          : rewardType === 'gems'
          ? { gems: rewardAmount }
          : rewardType === 'title'
          ? { title: def?.rewardId ?? 'unknown' }
          : rewardType === 'frame'
          ? { frame: def?.rewardId ?? 'unknown' }
          : null

      const key = a.achievementKey
      const label = key.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())

      return {
        key,
        category: def?.category ?? 'unknown',
        title: label,
        description: `Reach ${a.target} ${key.replace(/_/g, ' ')}`,
        target: a.target,
        progress: a.progress,
        completed: a.completed || a.progress >= a.target,
        rewardClaimed: a.rewardClaimed,
        reward,
      }
    })

    return NextResponse.json({ achievements: enriched })
  } catch (error) {
    console.error('get achievements error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch achievements' },
      { status: 500 }
    )
  }
}
