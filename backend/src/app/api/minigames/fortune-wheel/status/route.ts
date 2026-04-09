import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const DAILY_SPIN_LIMIT = 10

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    // Verify character ownership
    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    // Count today's spins + fetch user wallet in parallel
    const today = new Date().toISOString().split('T')[0]
    const [spinsToday, dbUser] = await Promise.all([
      prisma.minigameSession.count({
        where: {
          characterId,
          gameType: 'fortune_wheel',
          createdAt: { gte: new Date(today) },
        },
      }),
      prisma.user.findUnique({ where: { id: user.id }, select: { gold: true } }),
    ])

    return NextResponse.json({
      spins_today: spinsToday,
      spins_limit: DAILY_SPIN_LIMIT,
      spins_remaining: Math.max(0, DAILY_SPIN_LIMIT - spinsToday),
      gold: dbUser?.gold ?? 0,
    })
  } catch (error) {
    console.error('fortune-wheel status error:', error)
    return NextResponse.json({ error: 'Failed to get status' }, { status: 500 })
  }
}
