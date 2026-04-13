import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { rateLimit } from '@/lib/rate-limit'
import { initCombatConfig, resolveSingleStrike, type SingleStrikeInput } from '@/lib/game/combat'
import { loadCombatCharacter } from '@/lib/game/combat-loader'
import type { BodyZone } from '@/lib/game/balance'

/**
 * POST /api/pvp/strike — Interactive Combat v1 (FEATURE-FLAGGED, ADDITIVE)
 *
 * Single-strike resolution. Does NOT persist anything. Does NOT consume stamina
 * or award rewards. The existing /pvp/fight endpoint is untouched.
 *
 * Gate: `INTERACTIVE_COMBAT_V1` env flag. Default off → this route returns 404
 * so it's invisible in prod until we explicitly enable it.
 *
 * Body:
 *   {
 *     match_id:       string     // client-generated UUID for seed derivation
 *     strike_index:   number     // 0-based
 *     attacker_id:    string
 *     defender_id:    string
 *     attacker_zone:  "head"|"chest"|"legs"
 *     defender_zone:  "head"|"chest"|"legs"
 *     defender_hp:    number     // client's current belief; server clamps
 *   }
 *
 * Returns: { turn, newDefenderHp, healAmount, seed }
 */

const VALID_ZONES: readonly BodyZone[] = ['head', 'chest', 'legs']

function isZone(v: unknown): v is BodyZone {
  return typeof v === 'string' && (VALID_ZONES as readonly string[]).includes(v)
}

/**
 * Deterministic 32-bit seed from matchId + strike index.
 * Same inputs → same seed → same strike resolution on replay.
 */
function deriveSeed(matchId: string, strikeIndex: number): number {
  let h = 2166136261 | 0
  const s = `${matchId}:${strikeIndex}`
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i)
    h = Math.imul(h, 16777619)
  }
  return h | 0
}

export async function POST(req: NextRequest) {
  // Feature flag — hard gate. Invisible endpoint until we flip this.
  if (process.env.INTERACTIVE_COMBAT_V1 !== 'true') {
    return NextResponse.json({ error: 'Not Found' }, { status: 404 })
  }

  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  // Tighter rate limit than /pvp/fight — one strike ≈ 6-10s of real time.
  if (!(await rateLimit(`pvp-strike:${user.id}`, 30, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const {
      match_id,
      strike_index,
      attacker_id,
      defender_id,
      attacker_zone,
      defender_zone,
      defender_hp,
    } = body ?? {}

    if (
      typeof match_id !== 'string' ||
      typeof strike_index !== 'number' ||
      typeof attacker_id !== 'string' ||
      typeof defender_id !== 'string' ||
      !isZone(attacker_zone) ||
      !isZone(defender_zone) ||
      typeof defender_hp !== 'number'
    ) {
      return NextResponse.json({ error: 'Invalid payload' }, { status: 400 })
    }

    if (attacker_id === defender_id) {
      return NextResponse.json({ error: 'Cannot strike yourself' }, { status: 400 })
    }

    await initCombatConfig()

    const [attackerStats, defenderStats] = await Promise.all([
      loadCombatCharacter(attacker_id),
      loadCombatCharacter(defender_id),
    ])

    // Authorization: attacker must belong to the caller. We check by re-loading
    // a minimal row — loadCombatCharacter doesn't expose userId.
    // (Using dynamic import of prisma only here to keep loader lean.)
    const { prisma } = await import('@/lib/prisma')
    const ownRow = await prisma.character.findUnique({
      where: { id: attacker_id },
      select: { userId: true },
    })
    if (!ownRow) return NextResponse.json({ error: 'Attacker not found' }, { status: 404 })
    if (ownRow.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const seed = deriveSeed(match_id, strike_index)

    const input: SingleStrikeInput = {
      attacker: attackerStats,
      defender: defenderStats,
      attackerZone: attacker_zone,
      defenderZone: defender_zone,
      defenderHp: defender_hp,
      seed,
    }

    const result = await resolveSingleStrike(input)

    return NextResponse.json({
      turn: result.turn,
      new_defender_hp: result.newDefenderHp,
      heal_amount: result.healAmount,
      seed,
      match_id,
      strike_index,
    })
  } catch (error) {
    console.error('pvp strike error:', error)
    return NextResponse.json({ error: 'Failed to resolve strike' }, { status: 500 })
  }
}
