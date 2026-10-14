import { NextRequest, NextResponse } from 'next/server'
import { Prisma } from '@prisma/client'
import { getAuthUser } from '@/lib/auth'
import { rateLimit } from '@/lib/rate-limit'
import { createSeededRng } from '@/lib/game/combat'
import { publicView, resolveRound, zoneOf, type DiceEvent, type DiceRoll } from '@/lib/game/dice'
import { loadDiceMatch, saveDiceMatch, type DiceStoredRound } from '@/lib/game/dice-match'
import { deriveCombatSeed } from '@/lib/game/combat-seed'

/**
 * POST /api/pvp/dice/resolve — clash: the opponent's hidden action lands,
 * both strikes resolve with every rune, and the next round is rolled.
 *
 * Body: { match_id, round }
 * Returns: { round, events[], dice, match_finished, winner_id }
 * Each round is also appended to interactive_choices in the shape
 * /pvp/match/complete already reads, so finalize/rewards are unchanged.
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

    if (state.finished) return NextResponse.json({ error: 'Match already resolved' }, { status: 409 })
    if (body?.round !== state.round) {
      return NextResponse.json({ error: 'Stale round', dice: publicView(state) }, { status: 409 })
    }

    const round = state.round
    const rollBefore: { p: DiceRoll; o: DiceRoll } = { p: { ...state.roll.p }, o: { ...state.roll.o } }
    const playerAction = state.acted.p
    const events = resolveRound(
      state,
      createSeededRng(deriveCombatSeed(match.id, round, 'resolve')),
      createSeededRng(deriveCombatSeed(match.id, round + 1, 'roll')),
    )

    // Final faces of this round (after both actions) for the stored record.
    const oAct = events.find((e): e is Extract<DiceEvent, { t: 'act' }> => e.t === 'act' && e.side === 'o')
    const final = {
      p: { ...rollBefore.p },
      o: { ...rollBefore.o, ...(oAct ? { [oAct.action.die]: oAct.face } : {}) },
    }
    const strikeOf = (from: 'p' | 'o') => {
      const hits = events.filter((e): e is Extract<DiceEvent, { t: 'strike' }> => e.t === 'strike' && e.from === from)
      if (hits.length === 0) return null
      const main = hits[0]
      return {
        attackerId: from === 'p' ? state.p.id : state.o.id,
        defenderId: from === 'p' ? state.o.id : state.p.id,
        damage: hits.reduce((t, h) => t + h.dmg, 0),
        isCrit: hits.some((h) => h.out === 'crit'),
        targetZone: main.zone,
        defendZone: main.guard,
        outcome: main.out,
        healAmount: hits.reduce((t, h) => t + h.heal, 0) || undefined,
      }
    }
    const stored: DiceStoredRound = {
      idx: round - 1,
      player_atk: zoneOf(final.p.a),
      player_def: zoneOf(final.p.d),
      opp_atk: zoneOf(final.o.a),
      opp_def: zoneOf(final.o.d),
      player_strike: strikeOf('p') ?? {
        attackerId: state.p.id, defenderId: state.o.id, damage: 0, isCrit: false, outcome: 'none',
      },
      opp_strike: strikeOf('o'),
      attacker_hp_after: state.p.hp,
      defender_hp_after: state.o.hp,
      dice: { round, roll: final, player_action: playerAction, events },
    }
    const choices = Array.isArray(match.interactiveChoices) ? (match.interactiveChoices as unknown[]) : []

    const saved = await saveDiceMatch(match, state, {
      interactiveChoices: [...choices, stored] as unknown as Prisma.InputJsonValue,
      interactiveStrikeIndex: round,
      turnsTaken: round,
    })
    if (!saved) return NextResponse.json({ error: 'Concurrent update, retry' }, { status: 409 })

    return NextResponse.json({
      round,
      events,
      dice: publicView(state),
      match_finished: state.finished,
      winner_id: state.finished ? (state.winner === 'p' ? state.p.id : state.o.id) : null,
    })
  } catch (error) {
    console.error('pvp dice/resolve error:', error)
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}
