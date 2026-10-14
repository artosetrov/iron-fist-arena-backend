import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { buildDicePayload } from '@/lib/game/dice-loadout'

/**
 * GET /api/dice?character_id=… — Hero → Dice tab (DICE_RUNES_DESIGN.md §5).
 * Both dice with socketed runes, open sockets by level, and the class's nine
 * runes (owned or not, with the talent node that unlocks each).
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  if (!(await rateLimit(`dice-get:${user.id}`, 60, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }
  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) return NextResponse.json({ error: 'character_id required' }, { status: 400 })
    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { id: true, userId: true, class: true, level: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    return NextResponse.json(await buildDicePayload(character))
  } catch (error) {
    console.error('dice get error:', error)
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}
