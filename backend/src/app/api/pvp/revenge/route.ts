import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/pvp/revenge?character_id=xxx
 * Returns available revenge entries for the character.
 *
 * The POST handler for executing a revenge fight lives at
 * /api/pvp/revenge/[id] (dynamic route).
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const now = new Date()

    // Parallel: verify ownership + fetch revenge entries
    const [character, revengeEntries] = await Promise.all([
      prisma.character.findUnique({
        where: { id: characterId },
        select: { id: true, userId: true },
      }),
      prisma.revengeQueue.findMany({
        where: {
          victimId: characterId,
          isUsed: false,
          expiresAt: { gt: now },
        },
        include: {
          attacker: {
            select: { id: true, characterName: true, class: true, level: true, pvpRating: true, avatar: true },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: 20,
      }),
    ])

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const entries = revengeEntries.map((r) => ({
      id: r.id,
      attacker_id: r.attacker.id,
      attacker_name: r.attacker.characterName,
      attacker_class: r.attacker.class,
      attacker_level: r.attacker.level,
      attacker_rating: r.attacker.pvpRating,
      rating_lost: 0,
      created_at: r.createdAt.toISOString(),
    }))

    return NextResponse.json({ revenge_list: entries })
  } catch (error) {
    console.error('get revenge list error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch revenge list' },
      { status: 500 }
    )
  }
}
