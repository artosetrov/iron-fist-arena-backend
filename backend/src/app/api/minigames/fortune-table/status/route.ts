import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { FORTUNE_TABLE } from '@/lib/game/fortune-table'
import {
  FORTUNE_TABLE_GAME, activeRound, recentHistory, roundView, settleDueRounds, todayStart,
} from '@/lib/game/fortune-table-server'

/** Fortune's Table lobby info: tiers, limits, the open round (if any), history. */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    if (!(await rateLimit('fortune-table-status:' + user.id, 60, 60_000))) {
      return NextResponse.json({ error: 'Too many requests. Please try again later.' }, { status: 429 })
    }
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) return NextResponse.json({ error: 'character_id is required' }, { status: 400 })

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true, level: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    const now = Date.now()
    // A round the player walked away from is drawn and paid now.
    await settleDueRounds(prisma, { characterId, userId: user.id, level: character.level, nowMs: now })

    const [roundsToday, dbUser, open, history] = await Promise.all([
      prisma.minigameSession.count({
        where: { characterId, gameType: FORTUNE_TABLE_GAME, createdAt: { gte: todayStart(now) } },
      }),
      prisma.user.findUnique({ where: { id: user.id }, select: { gold: true } }),
      activeRound(prisma, characterId, now),
      recentHistory(prisma, characterId),
    ])

    return NextResponse.json({
      tiers: FORTUNE_TABLE.tiers.map((t) => ({
        key: t.key,
        min_stake: t.minStake,
        max_stake: t.maxStake,
        min_level: t.minLevel,
        unlocked: character.level >= t.minLevel,
      })),
      rake: FORTUNE_TABLE.rake,
      lobby_ms: FORTUNE_TABLE.lobbyMs,
      rounds_today: roundsToday,
      rounds_limit: FORTUNE_TABLE.dailyRounds,
      gold: dbUser?.gold ?? 0,
      active_round: open ? roundView(open, now) : null,
      history,
    })
  } catch (error) {
    console.error('fortune-table status error:', error)
    return NextResponse.json({ error: 'Failed to get status' }, { status: 500 })
  }
}
