import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

const MIN_BET = 50
const MAX_BET = 1000

/**
 * POST /api/minigames/shell-game/play
 * Single-step shell game: bet + guess in one call.
 * Body: { character_id, bet_amount, chosen_cup }
 * Response: { winning_cup, won, win_amount, gold }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`shellgame:${user.id}`, 30, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, bet_amount, chosen_cup } = body

    if (!character_id || bet_amount == null || chosen_cup == null) {
      return NextResponse.json(
        { error: 'character_id, bet_amount, and chosen_cup are required' },
        { status: 400 }
      )
    }

    if (bet_amount < MIN_BET || bet_amount > MAX_BET) {
      return NextResponse.json(
        { error: `Bet must be between ${MIN_BET} and ${MAX_BET} gold` },
        { status: 400 }
      )
    }

    if (![0, 1, 2].includes(chosen_cup)) {
      return NextResponse.json(
        { error: 'chosen_cup must be 0, 1, or 2' },
        { status: 400 }
      )
    }

    const character = await prisma.character.findUnique({
      where: { id: character_id },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }
    if (character.gold < bet_amount) {
      return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
    }

    // Pick winning cup
    const winning_cup = Math.floor(Math.random() * 3)
    const won = chosen_cup === winning_cup
    const win_amount = won ? bet_amount * 2 : 0
    const goldDelta = won ? bet_amount : -bet_amount // win returns bet + profit; lose deducts bet

    const updated = await prisma.character.update({
      where: { id: character_id },
      data: { gold: { increment: goldDelta } },
      select: { gold: true },
    })

    return NextResponse.json({
      winning_cup,
      won,
      win_amount,
      gold: updated.gold,
    })
  } catch (error) {
    console.error('shell-game play error:', error)
    return NextResponse.json(
      { error: 'Failed to process shell game' },
      { status: 500 }
    )
  }
}
