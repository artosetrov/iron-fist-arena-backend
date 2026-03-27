import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getMilestoneStatus, checkAndAwardMilestones } from '@/lib/game/milestones'

/**
 * GET /api/milestones?character_id=xxx
 * Returns all milestones with claim status.
 */
export async function GET(req: NextRequest) {
  try {
    const user = await getAuthUser(req)
    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id required' }, { status: 400 })
    }

    const character = await prisma.character.findFirst({
      where: { id: characterId, userId: user.id },
      select: { id: true, level: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    const status = await getMilestoneStatus(prisma, characterId, character.level)

    return NextResponse.json(status)
  } catch (error) {
    console.error('milestones GET error:', error)
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}

/**
 * POST /api/milestones
 * Body: { character_id }
 * Claims all available milestone rewards.
 */
export async function POST(req: NextRequest) {
  try {
    const user = await getAuthUser(req)
    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id required' }, { status: 400 })
    }

    const character = await prisma.character.findFirst({
      where: { id: character_id, userId: user.id },
      select: { id: true, level: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    const awarded = await checkAndAwardMilestones(prisma, character_id, character.level)

    if (awarded.length === 0) {
      return NextResponse.json({ message: 'No milestones to claim', awarded: [] })
    }

    return NextResponse.json({
      success: true,
      awarded: awarded.map(m => ({
        level: m.level,
        gold: m.reward.gold,
        gems: m.reward.gems,
        title: m.reward.title ?? null,
        description: m.reward.description,
      })),
    })
  } catch (error) {
    console.error('milestones POST error:', error)
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}
