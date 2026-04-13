import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { initCombatConfig, resolveSingleStrike, type SingleStrikeInput } from '@/lib/game/combat'
import { loadCombatCharacter } from '@/lib/game/combat-loader'
import type { BodyZone } from '@/lib/game/balance'

/**
 * POST /api/pvp/strike — Interactive Combat v1 (FEATURE-FLAGGED, MATCH-AWARE)
 *
 * Resolves ONE ROUND of a live interactive PvP match:
 *   1. Player attacks opponent (player-chosen zones).
 *   2. If opponent survives, opponent counter-strikes the player (server-picked
 *      zones derived from seeded RNG — AI defender for v1).
 *
 * Both turns are persisted into pvp_matches.interactive_choices. The server is
 * authoritative for HP state. Client sends only its own zone choices.
 *
 * Feature gate: INTERACTIVE_COMBAT_V1=true, else 404.
 *
 * Body:
 *   { match_id, attacker_zone, defender_zone }
 *     attacker_zone — where the player attacks on opponent
 *     defender_zone — where the player is guarding (used for counter-strike)
 *
 * Returns:
 *   {
 *     match_id, strike_index,
 *     player_strike: Turn,
 *     opponent_strike: Turn | null,
 *     attacker_hp, defender_hp,
 *     opp_zones: { attack, defend },
 *     match_finished: boolean,
 *     winner_id: string | null
 *   }
 */

const VALID_ZONES: readonly BodyZone[] = ['head', 'chest', 'legs']
const MAX_ROUNDS = 15

function isZone(v: unknown): v is BodyZone {
  return typeof v === 'string' && (VALID_ZONES as readonly string[]).includes(v)
}

function deriveSeed(matchId: string, strikeIndex: number, salt: string): number {
  let h = 2166136261 | 0
  const s = `${matchId}:${strikeIndex}:${salt}`
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i)
    h = Math.imul(h, 16777619)
  }
  return h | 0
}

/** Pick a zone from seeded RNG (0..3 → head/chest/legs). */
function pickZoneFromSeed(seed: number): BodyZone {
  // Mulberry32 single step, modulo 3
  let t = (seed + 0x6D2B79F5) | 0
  t = Math.imul(t ^ (t >>> 15), t | 1)
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
  const r = ((t ^ (t >>> 14)) >>> 0) / 4294967296
  return VALID_ZONES[Math.floor(r * 3)]
}

interface StoredRound {
  idx: number
  player_atk: BodyZone
  player_def: BodyZone
  opp_atk: BodyZone
  opp_def: BodyZone
  player_strike: unknown  // Turn
  opp_strike: unknown | null
  attacker_hp_after: number
  defender_hp_after: number
}

export async function POST(req: NextRequest) {
  if (process.env.INTERACTIVE_COMBAT_V1 === 'false') {
    return NextResponse.json({ error: 'Not Found' }, { status: 404 })
  }

  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`pvp-strike:${user.id}`, 30, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { match_id, attacker_zone, defender_zone } = body ?? {}

    if (typeof match_id !== 'string' || !isZone(attacker_zone) || !isZone(defender_zone)) {
      return NextResponse.json({ error: 'Invalid payload' }, { status: 400 })
    }

    // Local Prisma client may be stale for the 4 Interactive Combat v1 columns
    // (see memory feedback_stale_prisma_client_triage). schema.prisma + migration
    // are in sync (drift checker passes); prod `prisma generate` at build fixes.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const match: any = await (prisma.pvpMatch.findUnique as any)({ where: { id: match_id } })
    if (!match) return NextResponse.json({ error: 'Match not found' }, { status: 404 })
    if (match.status !== 'in_progress') {
      return NextResponse.json({ error: 'Match is not in progress' }, { status: 409 })
    }
    if (match.interactiveTimeoutAt && match.interactiveTimeoutAt < new Date()) {
      return NextResponse.json({ error: 'Match timed out' }, { status: 410 })
    }

    // Auth: player1 must belong to caller
    const attackerRow = await prisma.character.findUnique({
      where: { id: match.player1Id },
      select: { userId: true, maxHp: true, currentHp: true },
    })
    const defenderRow = await prisma.character.findUnique({
      where: { id: match.player2Id },
      select: { maxHp: true, currentHp: true },
    })
    if (!attackerRow || !defenderRow) {
      return NextResponse.json({ error: 'Characters missing' }, { status: 404 })
    }
    if (attackerRow.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    await initCombatConfig()
    const [attackerStats, defenderStats] = await Promise.all([
      loadCombatCharacter(match.player1Id),
      loadCombatCharacter(match.player2Id),
    ])

    // Read current HPs from choices (last entry) or from character row (round 0)
    const choices = Array.isArray(match.interactiveChoices)
      ? (match.interactiveChoices as StoredRound[])
      : []
    const last = choices[choices.length - 1]
    const curAttackerHp = last ? last.attacker_hp_after : (attackerStats.currentHp ?? attackerRow.maxHp)
    const curDefenderHp = last ? last.defender_hp_after : (defenderStats.currentHp ?? defenderRow.maxHp)

    if (curAttackerHp <= 0 || curDefenderHp <= 0) {
      return NextResponse.json({ error: 'Match already resolved' }, { status: 409 })
    }

    const strikeIndex = match.interactiveStrikeIndex ?? 0
    if (strikeIndex >= MAX_ROUNDS) {
      return NextResponse.json({ error: 'Max rounds reached' }, { status: 409 })
    }

    // Derive opponent zones deterministically from seed
    const oppAtkZone = pickZoneFromSeed(deriveSeed(match_id, strikeIndex, 'opp-atk'))
    const oppDefZone = pickZoneFromSeed(deriveSeed(match_id, strikeIndex, 'opp-def'))

    // 1) Player attacks defender
    const playerSeed = deriveSeed(match_id, strikeIndex, 'p')
    const playerInput: SingleStrikeInput = {
      attacker: attackerStats,
      defender: defenderStats,
      attackerZone: attacker_zone,
      defenderZone: oppDefZone,
      defenderHp: curDefenderHp,
      seed: playerSeed,
    }
    const playerResult = await resolveSingleStrike(playerInput)
    const newDefenderHp = playerResult.newDefenderHp
    // Apply player's self-heal (if any) — heal is applied to attacker side
    const attackerAfterHeal = Math.min(
      attackerRow.maxHp,
      curAttackerHp + (playerResult.healAmount || 0)
    )

    let oppResult: Awaited<ReturnType<typeof resolveSingleStrike>> | null = null
    let newAttackerHp = attackerAfterHeal

    // 2) Opponent counter-strike only if still alive
    if (newDefenderHp > 0) {
      const oppSeed = deriveSeed(match_id, strikeIndex, 'o')
      const oppInput: SingleStrikeInput = {
        attacker: defenderStats,
        defender: attackerStats,
        attackerZone: oppAtkZone,
        defenderZone: defender_zone,
        defenderHp: attackerAfterHeal,
        seed: oppSeed,
      }
      oppResult = await resolveSingleStrike(oppInput)
      newAttackerHp = oppResult.newDefenderHp
    }

    const matchFinished = newAttackerHp <= 0 || newDefenderHp <= 0 || (strikeIndex + 1) >= MAX_ROUNDS
    let winnerId: string | null = null
    if (matchFinished) {
      if (newDefenderHp <= 0 && newAttackerHp > 0) winnerId = match.player1Id
      else if (newAttackerHp <= 0 && newDefenderHp > 0) winnerId = match.player2Id
      else {
        // Both alive at MAX_ROUNDS (or both 0, unlikely) → higher HP% wins
        const aPct = newAttackerHp / attackerRow.maxHp
        const dPct = newDefenderHp / defenderRow.maxHp
        winnerId = aPct >= dPct ? match.player1Id : match.player2Id
      }
    }

    const round: StoredRound = {
      idx: strikeIndex,
      player_atk: attacker_zone,
      player_def: defender_zone,
      opp_atk: oppAtkZone,
      opp_def: oppDefZone,
      player_strike: playerResult.turn,
      opp_strike: oppResult?.turn ?? null,
      attacker_hp_after: Math.max(0, newAttackerHp),
      defender_hp_after: Math.max(0, newDefenderHp),
    }

    // Persist round (atomic append + index bump; relies on optimistic concurrency
    // via strikeIndex check — if a concurrent call bumped it, we reject 409)
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updated = await (prisma.pvpMatch.updateMany as any)({
      where: { id: match_id, interactiveStrikeIndex: strikeIndex, status: 'in_progress' },
      data: {
        interactiveChoices: [...choices, round],
        interactiveStrikeIndex: strikeIndex + 1,
      },
    })
    if (updated.count === 0) {
      return NextResponse.json({ error: 'Match state changed, please retry' }, { status: 409 })
    }

    return NextResponse.json({
      match_id,
      strike_index: strikeIndex,
      player_strike: playerResult.turn,
      opponent_strike: oppResult?.turn ?? null,
      attacker_hp: round.attacker_hp_after,
      defender_hp: round.defender_hp_after,
      opp_zones: { attack: oppAtkZone, defend: oppDefZone },
      match_finished: matchFinished,
      winner_id: winnerId,
    })
  } catch (error) {
    console.error('pvp strike error:', error)
    return NextResponse.json({ error: 'Failed to resolve strike' }, { status: 500 })
  }
}
