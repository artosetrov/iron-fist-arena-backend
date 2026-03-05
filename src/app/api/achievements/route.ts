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

    // Enrich with catalog metadata
    const enriched = achievements.map((a) => {
      const def = ACHIEVEMENT_CATALOG[a.achievementKey]
      return {
        ...a,
        category: def?.category ?? 'unknown',
        rewardType: def?.rewardType ?? 'gold',
        rewardAmount: def?.rewardAmount ?? 0,
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
