import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { DESCENT, DESCENT_DUNGEON_ID } from '@/lib/game/descent/content'
import { isDescentState, type DescentState } from '@/lib/game/descent/engine'
import { buildDescentView } from '@/lib/game/descent/view'

/** GET /api/dungeon-rush/v2/state?character_id= — the active Descent run, if any. */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`rush2-state:${user.id}`, 60, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const [character, run] = await Promise.all([
      prisma.character.findFirst({ where: { id: characterId, userId: user.id }, select: { id: true } }),
      prisma.dungeonRun.findFirst({
        where: { characterId, difficulty: 'rush', dungeonId: DESCENT_DUNGEON_ID },
        orderBy: { createdAt: 'desc' },
      }),
    ])
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })

    if (!run || !isDescentState(run.state)) {
      return NextResponse.json({ active: false, stamina_cost: DESCENT.STAMINA_COST, view: null })
    }
    return NextResponse.json({
      active: true,
      stamina_cost: DESCENT.STAMINA_COST,
      view: buildDescentView(run.id, run.state as unknown as DescentState),
    })
  } catch (error) {
    console.error('dungeon rush v2 state error:', error)
    return NextResponse.json({ error: 'Failed to load the descent' }, { status: 500 })
  }
}
