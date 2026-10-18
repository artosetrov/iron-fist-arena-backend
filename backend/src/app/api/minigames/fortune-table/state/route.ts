import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { FORTUNE_TABLE } from '@/lib/game/fortune-table'
import { FORTUNE_TABLE_GAME, roundView, settleRound } from '@/lib/game/fortune-table-server'

/**
 * Poll a round: who has sat down so far. Once the lobby is over the first
 * call draws and pays it (idempotent — the round row is locked) and the view
 * carries the result and the revealed seed.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    if (!(await rateLimit('fortune-table-state:' + user.id, 120, 60_000))) {
      return NextResponse.json({ error: 'Too many requests. Please try again later.' }, { status: 429 })
    }
    const characterId = req.nextUrl.searchParams.get('character_id')
    const roundId = req.nextUrl.searchParams.get('round_id')
    if (!characterId || !roundId) {
      return NextResponse.json({ error: 'character_id and round_id are required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true, level: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    let row = await prisma.minigameSession.findUnique({ where: { id: roundId } })
    if (!row || row.characterId !== characterId || row.gameType !== FORTUNE_TABLE_GAME) {
      return NextResponse.json({ error: 'Round not found', code: 'NOT_FOUND' }, { status: 404 })
    }

    const now = Date.now()
    if (row.status === 'active' && now - row.createdAt.getTime() >= FORTUNE_TABLE.lobbyMs) {
      // Row lock inside settleRound makes this idempotent under concurrent polls.
      await prisma.$transaction(
        (tx) => settleRound(tx, { roundId, characterId, userId: user.id, level: character.level, nowMs: now }),
      )
      row = await prisma.minigameSession.findUnique({ where: { id: roundId } })
      if (!row) return NextResponse.json({ error: 'Round not found', code: 'NOT_FOUND' }, { status: 404 })
    }

    const dbUser = await prisma.user.findUnique({ where: { id: user.id }, select: { gold: true } })
    return NextResponse.json({ round: roundView(row, now), gold: dbUser?.gold ?? 0 })
  } catch (error) {
    console.error('fortune-table state error:', error)
    return NextResponse.json({ error: 'Failed to get the round' }, { status: 500 })
  }
}
