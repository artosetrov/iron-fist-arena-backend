import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { rateLimit } from '@/lib/rate-limit'
import { createSeededRng } from '@/lib/game/combat'
import { applyAction, publicView, validateAction, type DiceAction } from '@/lib/game/dice'
import { loadDiceMatch, saveDiceMatch } from '@/lib/game/dice-match'
import { deriveCombatSeed } from '@/lib/game/combat-seed'

/**
 * POST /api/pvp/dice/act — spend Focus on one die this round (dice combat).
 *
 * Body: { match_id, round, action: { type: 'reroll' | 'set', die: 'a' | 'd', face?: 0..5 } }
 * One action per round. The reroll is seeded server-side; the opponent's own
 * (simultaneous) decision stays hidden until /pvp/dice/resolve.
 * Returns: { face, dice } — `dice` is the public round view.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  if (!(await rateLimit(`pvp-dice:${user.id}`, 90, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json().catch(() => null)
    const loaded = await loadDiceMatch(user.id, body?.match_id)
    if (!loaded.ok) return loaded.res
    const { match, state } = loaded

    if (body?.round !== state.round) {
      return NextResponse.json({ error: 'Stale round', dice: publicView(state) }, { status: 409 })
    }
    const raw = body?.action ?? {}
    const die = raw.die === 'a' || raw.die === 'd' ? raw.die : null
    const action: DiceAction | null =
      die && raw.type === 'reroll' ? { type: 'reroll', die }
        : die && raw.type === 'set' && Number.isInteger(raw.face) ? { type: 'set', die, face: raw.face }
          : null
    if (!action) return NextResponse.json({ error: 'Invalid action' }, { status: 400 })

    const invalid = validateAction(state, 'p', action)
    if (invalid) {
      return NextResponse.json({ error: invalid, dice: publicView(state) }, { status: 409 })
    }

    const face = applyAction(state, 'p', action, createSeededRng(deriveCombatSeed(match.id, state.round, 'p-act')))
    if (!(await saveDiceMatch(match, state))) {
      return NextResponse.json({ error: 'Concurrent update, retry' }, { status: 409 })
    }
    return NextResponse.json({ face, dice: publicView(state) })
  } catch (error) {
    console.error('pvp dice/act error:', error)
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}
