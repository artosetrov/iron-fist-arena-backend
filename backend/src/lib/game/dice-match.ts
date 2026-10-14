// =============================================================================
// dice-match.ts — load / persist the dice state of an in-progress pvp_matches row
// =============================================================================

import { NextResponse } from 'next/server'
import { Prisma, type PvpMatch } from '@prisma/client'
import { prisma } from '@/lib/prisma'
import type { DiceState } from './dice'

export type LoadedDiceMatch =
  | { ok: true; match: PvpMatch; state: DiceState }
  | { ok: false; res: NextResponse }

const fail = (error: string, status: number): LoadedDiceMatch =>
  ({ ok: false, res: NextResponse.json({ error }, { status }) })

/** Fetch the match, check the caller owns player1 and the match is a live dice duel. */
export async function loadDiceMatch(userId: string, matchId: unknown): Promise<LoadedDiceMatch> {
  if (typeof matchId !== 'string') return fail('match_id required', 400)
  const match = await prisma.pvpMatch.findUnique({ where: { id: matchId } })
  if (!match) return fail('Match not found', 404)
  const owner = await prisma.character.findUnique({ where: { id: match.player1Id }, select: { userId: true } })
  if (!owner || owner.userId !== userId) return fail('Forbidden', 403)
  if (match.status !== 'in_progress') return fail('Match is not in progress', 409)
  if (match.interactiveTimeoutAt && match.interactiveTimeoutAt < new Date()) return fail('Match timed out', 410)
  const state = (match.interactiveActives as unknown as { dice?: DiceState } | null)?.dice
  if (!state || state.v !== 1) return fail('Not a dice match', 409)
  return { ok: true, match, state }
}

/**
 * Write the state back with optimistic concurrency on `updatedAt`: two taps
 * racing the same round can't both apply. Returns false when we lost the race.
 */
export async function saveDiceMatch(
  match: PvpMatch,
  state: DiceState,
  extra: Prisma.PvpMatchUpdateManyMutationInput = {},
): Promise<boolean> {
  const res = await prisma.pvpMatch.updateMany({
    where: { id: match.id, status: 'in_progress', updatedAt: match.updatedAt },
    data: { ...extra, interactiveActives: { dice: state } as unknown as Prisma.InputJsonValue },
  })
  return res.count === 1
}

/** Shape /pvp/match/complete already reads (StoredRound) + the dice detail. */
export interface DiceStoredRound {
  idx: number
  player_atk: string
  player_def: string
  opp_atk: string
  opp_def: string
  player_strike: {
    attackerId: string; defenderId: string; damage: number; isCrit: boolean
    targetZone?: string; defendZone?: string; outcome?: string; healAmount?: number
  }
  opp_strike: DiceStoredRound['player_strike'] | null
  attacker_hp_after: number
  defender_hp_after: number
  dice: unknown
}
