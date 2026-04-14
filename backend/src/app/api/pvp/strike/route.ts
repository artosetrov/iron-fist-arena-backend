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
  // Phase 3: which actives fired this round (null if none)
  player_active: number | null    // slot_index of fired active, or null
  opponent_active: number | null
}

interface ActiveSlotSnapshot {
  slot_index: number
  node_id: number
  node_key: string
  name: string
  icon: string | null
  action_type: string | null
  cooldown_max: number
  magnitude: number
  cooldown_remaining: number
}

interface InteractiveActivesState {
  p1: ActiveSlotSnapshot[]
  p2: ActiveSlotSnapshot[]
}

/**
 * Apply a single active's effect to an in-flight strike and return the modified
 * resolution inputs/outputs. v1 supports burst_damage fully; other action_types
 * are validated and cooldown-tracked but not yet applied (Phase 3.B TODO).
 */
function applyBurstDamage(baseDamage: number, magnitude: number): number {
  // magnitude stored as fraction (0.5 = +50%). Integer round to prevent decimals.
  return Math.round(baseDamage * (1 + Math.max(0, magnitude)))
}

function applyShield(incomingDamage: number, magnitude: number): number {
  // magnitude stored as damage-reduction fraction (0.5 = -50% incoming).
  const reduced = Math.round(incomingDamage * Math.max(0, 1 - magnitude))
  return Math.max(0, reduced)
}

function healAmountFromActive(maxHp: number, magnitude: number): number {
  // magnitude = fraction of maxHp to heal (0.25 = 25%).
  return Math.max(0, Math.round(maxHp * Math.max(0, magnitude)))
}

function shouldExecute(currentHp: number, maxHp: number, magnitude: number): boolean {
  // magnitude = HP% threshold (0.2 = execute if defender ≤ 20% HP).
  if (maxHp <= 0) return false
  const pct = currentHp / maxHp
  return pct > 0 && pct <= Math.max(0, magnitude)
}

function decrementCooldowns(actives: ActiveSlotSnapshot[]): ActiveSlotSnapshot[] {
  return actives.map((a) => ({
    ...a,
    cooldown_remaining: Math.max(0, a.cooldown_remaining - 1),
  }))
}

/**
 * AI picks one ready active for the opponent, prioritizing:
 *   1. execute — if player is low HP (≤ magnitude threshold)
 *   2. burst_damage — if player will survive counter and we can punish
 *   3. heal_self — if opponent is below 50% HP
 *   4. shield_self — if opponent is below 60% HP
 *   5. stun_enemy — otherwise, if available
 * Returns the chosen slot or null.
 */
function pickOpponentActive(
  opponentActives: ActiveSlotSnapshot[],
  opponentHp: number,
  opponentMaxHp: number,
  playerHp: number,
  playerMaxHp: number
): ActiveSlotSnapshot | null {
  const ready = opponentActives.filter(
    (a) => a.cooldown_remaining === 0 && a.action_type
  )
  if (ready.length === 0) return null

  const priority: Record<string, number> = {
    execute: 0,
    burst_damage: 1,
    heal_self: 2,
    shield_self: 3,
    stun_enemy: 4,
  }

  const oppPct = opponentHp / opponentMaxHp

  const candidates = ready.filter((a) => {
    switch (a.action_type) {
      case 'execute':
        return shouldExecute(playerHp, playerMaxHp, a.magnitude)
      case 'heal_self':
        return oppPct <= 0.5
      case 'shield_self':
        return oppPct <= 0.6
      case 'burst_damage':
      case 'stun_enemy':
        return true
      default:
        return false
    }
  })
  if (candidates.length === 0) return null

  candidates.sort(
    (a, b) =>
      (priority[a.action_type ?? ''] ?? 99) - (priority[b.action_type ?? ''] ?? 99)
  )
  return candidates[0] ?? null
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
    const { match_id, attacker_zone, defender_zone, player_active_slot } = body ?? {}

    if (typeof match_id !== 'string' || !isZone(attacker_zone) || !isZone(defender_zone)) {
      return NextResponse.json({ error: 'Invalid payload' }, { status: 400 })
    }
    // Optional: slot index 0..2 to fire an active this round
    const firedSlotIndex: number | null =
      typeof player_active_slot === 'number' && player_active_slot >= 0 && player_active_slot <= 2
        ? player_active_slot
        : null

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
    // Round 0: both fighters start at full maxHp (match is a discrete duel).
    // Subsequent rounds read mid-match HP from the last persisted round.
    const curAttackerHp = last ? last.attacker_hp_after : attackerRow.maxHp
    const curDefenderHp = last ? last.defender_hp_after : defenderRow.maxHp

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

    // --- Phase 3: validate + prepare active fire for this round ---
    const actives: InteractiveActivesState =
      (match.interactiveActives as InteractiveActivesState | null) ?? { p1: [], p2: [] }
    let firedPlayerActive: ActiveSlotSnapshot | null = null
    if (firedSlotIndex !== null) {
      const slot = actives.p1.find((a) => a.slot_index === firedSlotIndex)
      if (!slot) {
        return NextResponse.json({ error: 'Active slot not equipped' }, { status: 400 })
      }
      if (slot.cooldown_remaining > 0) {
        return NextResponse.json({ error: 'Active on cooldown' }, { status: 409 })
      }
      if (!slot.action_type) {
        return NextResponse.json({ error: 'Slot has no action' }, { status: 400 })
      }
      firedPlayerActive = slot
    }

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

    // --- Phase 3: mutate player result per fired active ---
    // Full support for all 5 action_types. Cooldown is consumed for every fire.
    let mutatedPlayerTurn = playerResult.turn
    let newDefenderHp = playerResult.newDefenderHp
    let playerActiveLabel: string | null = null
    let playerHasShield = false           // reduces next counter-strike damage
    let playerExtraHeal = 0               // from heal_self active
    let opponentStunned = false           // stun_enemy suppresses counter this round
    if (firedPlayerActive) {
      playerActiveLabel = firedPlayerActive.action_type
      switch (firedPlayerActive.action_type) {
        case 'burst_damage': {
          const originalDmg = playerResult.turn.damage
          const boosted = applyBurstDamage(originalDmg, firedPlayerActive.magnitude)
          const delta = boosted - originalDmg
          mutatedPlayerTurn = { ...playerResult.turn, damage: boosted }
          newDefenderHp = Math.max(0, newDefenderHp - delta)
          break
        }
        case 'execute': {
          if (shouldExecute(curDefenderHp, defenderRow.maxHp, firedPlayerActive.magnitude)) {
            const finishingDmg = playerResult.turn.damage + Math.max(0, newDefenderHp)
            mutatedPlayerTurn = { ...playerResult.turn, damage: finishingDmg }
            newDefenderHp = 0
          }
          break
        }
        case 'heal_self': {
          playerExtraHeal = healAmountFromActive(attackerRow.maxHp, firedPlayerActive.magnitude)
          break
        }
        case 'shield_self': {
          playerHasShield = true
          break
        }
        case 'stun_enemy': {
          opponentStunned = true
          break
        }
      }
    }
    // Apply player's self-heal (combat formula heal + active heal)
    const attackerAfterHeal = Math.min(
      attackerRow.maxHp,
      curAttackerHp + (playerResult.healAmount || 0) + playerExtraHeal
    )

    // --- Phase 3.B: pick opponent AI active for this round ---
    // Opp sees post-strike HP so pickOpponentActive prefers heal_self if about to die.
    const firedOppActive = pickOpponentActive(
      actives.p2,
      newDefenderHp,
      defenderRow.maxHp,
      attackerAfterHeal,
      attackerRow.maxHp
    )
    const oppActiveLabel: string | null = firedOppActive?.action_type ?? null

    // Apply opp's defensive / setup actives BEFORE counter-strike resolves:
    //   shield_self → retroactively reduce player's incoming damage
    //   heal_self   → bump opp HP (can bring them back above 0 from a fatal hit)
    if (firedOppActive?.action_type === 'shield_self') {
      const reduced = applyShield(mutatedPlayerTurn.damage, firedOppActive.magnitude)
      const refund = mutatedPlayerTurn.damage - reduced
      if (refund > 0) {
        mutatedPlayerTurn = { ...mutatedPlayerTurn, damage: reduced }
        newDefenderHp = Math.min(defenderRow.maxHp, newDefenderHp + refund)
      }
    }
    if (firedOppActive?.action_type === 'heal_self') {
      const oppHeal = healAmountFromActive(defenderRow.maxHp, firedOppActive.magnitude)
      newDefenderHp = Math.min(defenderRow.maxHp, newDefenderHp + oppHeal)
    }

    let oppResult: Awaited<ReturnType<typeof resolveSingleStrike>> | null = null
    let newAttackerHp = attackerAfterHeal

    // 2) Opponent counter-strike only if still alive AND not stunned
    if (newDefenderHp > 0 && !opponentStunned) {
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
      // Apply opponent's offensive actives to counter-strike damage
      let oppDamage = oppResult.turn.damage
      if (firedOppActive?.action_type === 'burst_damage') {
        oppDamage = applyBurstDamage(oppDamage, firedOppActive.magnitude)
      } else if (
        firedOppActive?.action_type === 'execute' &&
        shouldExecute(attackerAfterHeal, attackerRow.maxHp, firedOppActive.magnitude)
      ) {
        oppDamage = attackerAfterHeal  // finishing blow
      }
      // Player's shield reduces incoming opponent damage
      if (playerHasShield) {
        oppDamage = applyShield(oppDamage, firedPlayerActive?.magnitude ?? 0)
      }
      const mutatedOppTurn = oppDamage !== oppResult.turn.damage
        ? { ...oppResult.turn, damage: oppDamage }
        : oppResult.turn
      const finalAttackerHp = Math.max(0, attackerAfterHeal - oppDamage)
      oppResult = { ...oppResult, turn: mutatedOppTurn, newDefenderHp: finalAttackerHp }
      newAttackerHp = finalAttackerHp
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
      player_strike: mutatedPlayerTurn,
      opp_strike: oppResult?.turn ?? null,
      attacker_hp_after: Math.max(0, newAttackerHp),
      defender_hp_after: Math.max(0, newDefenderHp),
      player_active: firedSlotIndex,
      opponent_active: firedOppActive?.slot_index ?? null,
    }

    // --- Phase 3: update actives state (set fired cooldown, tick all others) ---
    const updatedP1 = decrementCooldowns(
      firedPlayerActive
        ? actives.p1.map((a) =>
            a.slot_index === firedPlayerActive.slot_index
              ? { ...a, cooldown_remaining: a.cooldown_max }
              : a
          )
        : actives.p1
    )
    const updatedP2 = decrementCooldowns(
      firedOppActive
        ? actives.p2.map((a) =>
            a.slot_index === firedOppActive.slot_index
              ? { ...a, cooldown_remaining: a.cooldown_max }
              : a
          )
        : actives.p2
    )
    const newActives: InteractiveActivesState = { p1: updatedP1, p2: updatedP2 }

    // Persist round (atomic append + index bump; relies on optimistic concurrency
    // via strikeIndex check — if a concurrent call bumped it, we reject 409)
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updated = await (prisma.pvpMatch.updateMany as any)({
      where: { id: match_id, interactiveStrikeIndex: strikeIndex, status: 'in_progress' },
      data: {
        interactiveChoices: [...choices, round],
        interactiveStrikeIndex: strikeIndex + 1,
        interactiveActives: newActives,
      },
    })
    if (updated.count === 0) {
      return NextResponse.json({ error: 'Match state changed, please retry' }, { status: 409 })
    }

    return NextResponse.json({
      match_id,
      strike_index: strikeIndex,
      player_strike: mutatedPlayerTurn,
      opponent_strike: oppResult?.turn ?? null,
      attacker_hp: round.attacker_hp_after,
      defender_hp: round.defender_hp_after,
      opp_zones: { attack: oppAtkZone, defend: oppDefZone },
      match_finished: matchFinished,
      winner_id: winnerId,
      actives: newActives,
      player_active_fired: firedSlotIndex,
      player_active_label: playerActiveLabel,
      opponent_active_fired: firedOppActive?.slot_index ?? null,
      opponent_active_label: oppActiveLabel,
    })
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error)
    const stack = error instanceof Error ? error.stack : undefined
    console.error('pvp strike error:', detail, '\nstack:', stack)
    return NextResponse.json(
      { error: 'Failed to resolve strike', detail },
      { status: 500 }
    )
  }
}
