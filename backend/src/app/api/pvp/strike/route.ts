import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import {
  initCombatConfig,
  resolveSingleStrike,
  createSeededRng,
  isZoneMatrixV2,
  type SingleStrikeInput,
  type CharacterStats,
  type Turn,
} from '@/lib/game/combat'
import { getCombatConfig } from '@/lib/game/live-config'
import { loadCombatCharacter } from '@/lib/game/combat-loader'
import { tickCooldowns, type SkillCooldownState } from '@/lib/game/skills'
import {
  pickZones,
  policyForCharacter,
  personalityForKey,
  type ZonePolicy,
  type ZoneRoundContext,
} from '@/lib/game/zone-policy'
import {
  applyBurstDamage,
  applyShield,
  healAmountFromActive,
  shouldExecute,
} from '@/lib/game/active-handlers'
import type { BodyZone } from '@/lib/game/balance'
import { ConsumableType, Prisma } from '@prisma/client'
import { invalidateActiveSlotsCache } from '@/lib/game/active-slots'

// Snapshot shape written by /pvp/match/start for non-PvP opponents.
// Bots/dungeon bosses have no DB row, so their combat stats travel with the match.
interface OpponentSnapshot {
  kind: 'bot'
  id: string
  character_name: string
  class: string
  level: number
  avatar: string | null
  max_hp: number
  combat_stats: CharacterStats
}

/**
 * POST /api/pvp/strike — Interactive Combat v1 (FEATURE-FLAGGED, MATCH-AWARE)
 *
 * Resolves ONE ROUND of a live interactive PvP match:
 *   1. Player attacks opponent (player-chosen zones).
 *   2. If opponent survives, opponent counter-strikes the player. Opponent
 *      zones come from a ZONE POLICY (ghost of the real defender / bot
 *      personality — see lib/game/zone-policy.ts), sampled with a secret-seeded
 *      rng. Combat v2 (`combat.zone_matrix_v2`): higher AGI swings first.
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

/**
 * Server-side secret folded into every per-strike seed.
 *
 * Without it the opponent's zone picks were a pure hash of `match_id`,
 * `strikeIndex` and a constant salt — three values the client already holds
 * (the first two come back in every strike response). A modified client
 * could reproduce `pickZoneFromSeed` exactly and play every round knowing the
 * opponent's attack and defence zones, which the 2026-10-14 audit measured at
 * an 81% win rate against 57% for honest play.
 *
 * `BOT_TICKET_SECRET` is reused as the fallback because it is already a
 * required production secret; a dedicated `COMBAT_SEED_SECRET` wins when set.
 */
const SEED_SECRET = process.env.COMBAT_SEED_SECRET ?? process.env.BOT_TICKET_SECRET ?? ''
if (!SEED_SECRET && process.env.NODE_ENV === 'production') {
  console.warn('[pvp/strike] COMBAT_SEED_SECRET / BOT_TICKET_SECRET unset — opponent zones are client-predictable')
}

function deriveSeed(matchId: string, strikeIndex: number, salt: string): number {
  let h = 2166136261 | 0
  const s = `${SEED_SECRET}:${matchId}:${strikeIndex}:${salt}`
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i)
    h = Math.imul(h, 16777619)
  }
  return h | 0
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
  // Combat v2 (optional — absent on pre-v2 rounds)
  /** Whose block is ignored NEXT round (legs landed this round). */
  opened_next?: { player: boolean; opponent: boolean }
  /** Who swung first this round. */
  initiative?: 'player' | 'opponent'
}

interface ActiveSlotSnapshot {
  slot_index: number
  // Phase 4.B: snapshots may be talent OR consumable. Field is absent in
  // pre-4.B matches — treat missing `kind` as 'talent' for backward compat.
  kind?: 'talent' | 'consumable'
  // UUID string — passive_nodes.id is `String @id @default(uuid())` in Prisma.
  // Typing as `number` caused iOS decode crash (incident 2026-04-14).
  node_id: string | null
  node_key: string | null
  // Consumable-only (null for talent).
  consumable_type?: string | null
  name: string
  icon: string | null
  action_type: string | null
  cooldown_max: number
  magnitude: number
  cooldown_remaining: number
  // Consumable-only: true once fired this battle. Enforces 1-per-battle at
  // the snapshot level (cooldowns are 0 for consumables, so we can't use them).
  consumed?: boolean
}

function isConsumableSlot(slot: ActiveSlotSnapshot): boolean {
  return slot.kind === 'consumable' || (!!slot.consumable_type && slot.node_id == null)
}

/**
 * Cross-round buff state per side. Talents v2 (2026-04-29) introduced effects
 * that persist beyond the round of their fire — currently only `aoe_stun` (Tank
 * Quake ult) needs this. Optional everywhere; missing/old matches read as no
 * active buffs. Decrement once per round in the advance step.
 *
 * Spec: docs/06_game_systems/SKILL_TREE_DESIGN_V2.md §8
 */
interface ActiveBuffsState {
  /** How many upcoming counter-strikes this side must skip (aoe_stun received). */
  stunRoundsRemaining?: number
}

interface InteractiveActivesState {
  p1: ActiveSlotSnapshot[]
  p2: ActiveSlotSnapshot[]
  /** D4 — equipped-skill cooldowns per side, persisted across rounds (skill id → rounds left). */
  p1_skill_cd?: SkillCooldownState
  p2_skill_cd?: SkillCooldownState
  /** Buffs OWNED by p1 (negative effects applied TO p1 by an opposing aoe_stun). */
  p1_buffs?: ActiveBuffsState
  /** Buffs OWNED by p2 (negative effects applied TO p2 by p1's aoe_stun). */
  p2_buffs?: ActiveBuffsState
}

function removePlayerActiveSlot(
  actives: InteractiveActivesState,
  slotIndex: number,
): InteractiveActivesState {
  return {
    p1: actives.p1.filter((slot) => slot.slot_index !== slotIndex),
    p2: actives.p2,
    // Preserve buffs — losing them on a consumable-reconcile would mid-stun
    // grant the opponent free counters, which is gameplay-incorrect.
    p1_buffs: actives.p1_buffs,
    p2_buffs: actives.p2_buffs,
    p1_skill_cd: actives.p1_skill_cd,
    p2_skill_cd: actives.p2_skill_cd,
  }
}

// Pure handler math (`applyBurstDamage`, `applyShield`, `healAmountFromActive`,
// `shouldExecute`) lives in `@/lib/game/active-handlers` so it can be unit-tested
// in isolation. See `backend/tests/lib/active-handlers.test.ts`.

function advanceActivesAfterRound(
  actives: ActiveSlotSnapshot[],
  firedSlotIndex: number | null,
): ActiveSlotSnapshot[] {
  return actives.map((slot) => {
    if (firedSlotIndex !== null && slot.slot_index === firedSlotIndex) {
      if (isConsumableSlot(slot)) {
        return { ...slot, consumed: true }
      }
      return { ...slot, cooldown_remaining: slot.cooldown_max }
    }

    return {
      ...slot,
      cooldown_remaining: Math.max(0, slot.cooldown_remaining - 1),
    }
  })
}

/**
 * AI picks one ready active for the opponent, prioritizing:
 *   1. execute — if player is in execute range (guaranteed kill)
 *   2. stealth — if player is below 0.5 HP (force-crit finisher)
 *   3. heal_self — if opponent is CRITICALLY low (≤ 0.35 HP) and not already
 *      in execute range from the player
 *   4. burst_damage / aoe_damage — if player is vulnerable (< 0.7 HP) OR
 *      opponent is healthy (> 0.7 HP) — i.e. good kill window or low-risk
 *      aggression. aoe_damage is mathematically identical in 1v1.
 *   5. shield_self — if opponent is below 0.5 HP AND player has a ready
 *      active that isn't already on cooldown (incoming heavy hit likely)
 *   6. burst_damage / aoe_damage — fallback when nothing else fits but burst
 *      is ready
 * Returns the chosen slot or null.
 *
 * Excluded from AI v1:
 *   - stun_enemy / aoe_stun: AI moves SECOND, so stunning the player after
 *     they already attacked has no in-round effect; carry-over value exists
 *     but a 1-CD cost for low payoff is currently a worse pick than burst.
 *   - cooldown_reset: opp acts after player. Resetting opp cooldowns matters
 *     only if opp had multiple actives ready — at which point firing one of
 *     them directly is strictly better. Skip for now; reconsider when AI gets
 *     multi-round planning (Phase 5+).
 */
function pickOpponentActive(
  opponentActives: ActiveSlotSnapshot[],
  opponentHp: number,
  opponentMaxHp: number,
  playerHp: number,
  playerMaxHp: number,
  playerActives?: ActiveSlotSnapshot[]
): ActiveSlotSnapshot | null {
  // Phase 4.B: exclude consumable slots from AI. Consumables belong to a
  // specific player's inventory — the opponent-AI must not decrement the
  // user's real potions. Also exclude stun-family + cooldown_reset for
  // reasons spelled out in the function header.
  const ready = opponentActives.filter(
    (a) =>
      a.cooldown_remaining === 0 &&
      a.action_type &&
      a.action_type !== 'stun_enemy' &&
      a.action_type !== 'aoe_stun' &&
      a.action_type !== 'cooldown_reset' &&
      !isConsumableSlot(a)
  )
  if (ready.length === 0) return null

  const oppPct = opponentMaxHp > 0 ? opponentHp / opponentMaxHp : 0
  const playerPct = playerMaxHp > 0 ? playerHp / playerMaxHp : 0
  const playerHasReadyActive = (playerActives ?? []).some(
    (a) => a.cooldown_remaining === 0 && !!a.action_type
  )

  const isBurstLike = (a: ActiveSlotSnapshot): boolean =>
    a.action_type === 'burst_damage' || a.action_type === 'aoe_damage'

  // Tier 1 — execute (guaranteed kill)
  const execSlot = ready.find(
    (a) =>
      a.action_type === 'execute' &&
      shouldExecute(playerHp, playerMaxHp, a.magnitude)
  )
  if (execSlot) return execSlot

  // Tier 2 — stealth as opportunistic finisher (force-crit ≥ ×CRIT_MULTIPLIER damage)
  if (playerPct < 0.5) {
    const stealth = ready.find((a) => a.action_type === 'stealth')
    if (stealth) return stealth
  }

  // Tier 3 — emergency heal (save from certain death next round)
  if (oppPct <= 0.35) {
    const heal = ready.find((a) => a.action_type === 'heal_self')
    if (heal) return heal
  }

  // Tier 4 — burst / aoe_damage in kill window OR safe-aggressive window
  if (playerPct < 0.7 || oppPct > 0.7) {
    const burst = ready.find(isBurstLike)
    if (burst) return burst
  }

  // Tier 5 — preemptive shield when opp is low AND player has a loaded active
  if (oppPct <= 0.5 && playerHasReadyActive) {
    const shield = ready.find((a) => a.action_type === 'shield_self')
    if (shield) return shield
  }

  // Tier 6 — fallback burst/aoe when all else fails but it is ready
  const burstFallback = ready.find(isBurstLike)
  if (burstFallback) return burstFallback

  // Final fallback — take any remaining non-stun talent to at least use the cooldown
  return ready[0] ?? null
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

    const match = await prisma.pvpMatch.findUnique({ where: { id: match_id } })
    if (!match) return NextResponse.json({ error: 'Match not found' }, { status: 404 })
    if (match.status !== 'in_progress') {
      return NextResponse.json({ error: 'Match is not in progress' }, { status: 409 })
    }
    if (match.interactiveTimeoutAt && match.interactiveTimeoutAt < new Date()) {
      return NextResponse.json({ error: 'Match timed out' }, { status: 410 })
    }

    // Dice combat matches resolve via /pvp/dice/act + /pvp/dice/resolve.
    if ((match.interactiveActives as unknown as { dice?: unknown } | null)?.dice) {
      return NextResponse.json({ error: 'Dice match — use /api/pvp/dice/resolve', code: 'DICE_MATCH' }, { status: 409 })
    }

    const opponentType = match.opponentType ?? 'pvp'

    // For PvP, defender is a real character. For bot/dungeon, defender stats live
    // in match.opponentSnapshot (no DB row exists).
    if (opponentType === 'pvp' && !match.player2Id) {
      return NextResponse.json(
        { error: 'Player-vs-player opponent missing' },
        { status: 409 },
      )
    }
    const opponentSnapshot =
      opponentType !== 'pvp'
        ? (match.opponentSnapshot as unknown as OpponentSnapshot | null)
        : null
    if (opponentType !== 'pvp' && !opponentSnapshot) {
      return NextResponse.json(
        { error: 'Opponent snapshot missing on non-PvP match' },
        { status: 500 },
      )
    }

    // Auth: player1 must belong to caller
    const attackerRow = await prisma.character.findUnique({
      where: { id: match.player1Id },
      select: { userId: true, maxHp: true, currentHp: true },
    })
    if (!attackerRow) {
      return NextResponse.json({ error: 'Characters missing' }, { status: 404 })
    }
    if (attackerRow.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const defenderRow =
      opponentType === 'pvp' && match.player2Id
        ? await prisma.character.findUnique({
            where: { id: match.player2Id },
            select: { maxHp: true, currentHp: true, zoneProfile: true },
          })
        : { maxHp: opponentSnapshot!.max_hp, currentHp: opponentSnapshot!.max_hp, zoneProfile: null as unknown }
    if (!defenderRow) {
      return NextResponse.json({ error: 'Characters missing' }, { status: 404 })
    }

    await initCombatConfig()
    const attackerStats = await loadCombatCharacter(match.player1Id)
    const defenderStats =
      opponentType === 'pvp' && match.player2Id
        ? await loadCombatCharacter(match.player2Id)
        : (opponentSnapshot!.combat_stats as CharacterStats)

    // Read current HPs from choices (last entry) or from character row (round 0)
    const choices = Array.isArray(match.interactiveChoices)
      ? (match.interactiveChoices as unknown as StoredRound[])
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

    // --- Combat v2 wiring ---------------------------------------------------
    const combatCfg = await getCombatConfig()
    const v2 = isZoneMatrixV2(combatCfg)

    // Opponent zones come from a POLICY, never from a bare roll (COMBAT_V2_DESIGN §4).
    //   pvp  → the defender's ghost (recorded habits) with a personality fallback
    //   bot / dungeon_boss → a stable personality derived from the bot/boss key
    // The rng is seeded with the server secret, so the pick stays unpredictable
    // for a modified client even though the policy itself is readable.
    const oppPolicy: ZonePolicy =
      opponentType === 'pvp' && match.player2Id
        ? policyForCharacter(match.player2Id, defenderRow.zoneProfile)
        : { kind: 'personality', personality: personalityForKey(match.botKey ?? match.bossKey ?? opponentSnapshot!.id) }
    const lastPlayerTurn = (last?.player_strike ?? null) as Turn | null
    const lastOppTurn = (last?.opp_strike ?? null) as Turn | null
    const oppCtx: ZoneRoundContext = {
      roundIndex: strikeIndex,
      myHpPct: defenderRow.maxHp > 0 ? curDefenderHp / defenderRow.maxHp : 0,
      oppHpPct: attackerRow.maxHp > 0 ? curAttackerHp / attackerRow.maxHp : 0,
      ...(last
        ? {
            last: {
              myAttack: last.opp_atk,
              myBlock: last.opp_def,
              oppAttack: last.player_atk,
              oppBlock: last.player_def,
              myStrikeBlocked: lastOppTurn?.outcome === 'blocked',
              iTookCrit: lastPlayerTurn?.isCrit === true,
              iLandedCrit: lastOppTurn?.isCrit === true,
            },
          }
        : {}),
    }
    const oppPick = pickZones(oppPolicy, oppCtx, createSeededRng(deriveSeed(match_id, strikeIndex, 'policy')))
    const oppAtkZone: BodyZone = oppPick.attack
    const oppDefZone: BodyZone = oppPick.block

    // Legs landed last round → that side's block does not apply this round.
    const playerOpened = last?.opened_next?.player === true
    const opponentOpened = last?.opened_next?.opponent === true

    // Initiative (D5): v1 always let the player swing first, which alone is a
    // 62–67% edge in a mirror. v2: higher AGI first, ties alternate by round.
    const playerFirst = !v2
      || attackerStats.agi > defenderStats.agi
      || (attackerStats.agi === defenderStats.agi && strikeIndex % 2 === 0)

    // --- Phase 3: validate + prepare active fire for this round ---
    const actives: InteractiveActivesState =
      (match.interactiveActives as unknown as InteractiveActivesState | null) ?? { p1: [], p2: [] }
    // D4: skill cooldowns persist per side across rounds (was a fresh {} per strike).
    const p1SkillCd: SkillCooldownState = { ...(actives.p1_skill_cd ?? {}) }
    const p2SkillCd: SkillCooldownState = { ...(actives.p2_skill_cd ?? {}) }
    let firedPlayerActive: ActiveSlotSnapshot | null = null
    let firedIsConsumable = false
    if (firedSlotIndex !== null) {
      const slot = actives.p1.find((a) => a.slot_index === firedSlotIndex)
      if (!slot) {
        return NextResponse.json({ error: 'Active slot not equipped' }, { status: 400 })
      }
      if (!slot.action_type) {
        return NextResponse.json({ error: 'Slot has no action' }, { status: 400 })
      }
      if (isConsumableSlot(slot)) {
        // Consumables: gated by `consumed` (1/battle), not cooldowns.
        if (slot.consumed) {
          return NextResponse.json({ error: 'Consumable already used this battle' }, { status: 409 })
        }
        firedIsConsumable = true
      } else {
        if (slot.cooldown_remaining > 0) {
          return NextResponse.json({ error: 'Active on cooldown' }, { status: 409 })
        }
      }
      firedPlayerActive = slot
    }

    // Carry-over state read from interactiveActives.{p1,p2}_buffs:
    //   * p2.stunRoundsRemaining > 0 ⇒ opp must skip its strike THIS round
    //   * p1.stunRoundsRemaining is read for symmetry but currently never set
    //     by the AI (see pickOpponentActive header). Reserved for human-vs-human PvP.
    const incomingP2Stun = actives.p2_buffs?.stunRoundsRemaining ?? 0
    const incomingP1Stun = actives.p1_buffs?.stunRoundsRemaining ?? 0
    let opponentStunned = incomingP2Stun > 0
    let newP2StunRoundsRemaining = incomingP2Stun
    const newP1StunRoundsRemaining = incomingP1Stun

    // Pre-fetch crit multiplier only when stealth is firing.
    let stealthCritMultiplier = 2.0
    if (firedPlayerActive?.action_type === 'stealth') {
      stealthCritMultiplier = Math.max(1, combatCfg.CRIT_MULTIPLIER ?? 2.0)
    }

    // Player's declared actives resolve at round start, whatever the strike
    // order: a heal/shield/stun is a decision made before anyone swings.
    let playerActiveLabel: string | null = null
    let playerHasShield = false
    let playerExtraHeal = 0
    if (firedPlayerActive) {
      playerActiveLabel = firedPlayerActive.action_type
      switch (firedPlayerActive.action_type) {
        case 'heal_self':
          playerExtraHeal = healAmountFromActive(attackerRow.maxHp, firedPlayerActive.magnitude)
          break
        case 'shield_self':
          playerHasShield = true
          break
        case 'stun_enemy':
          // Single-round stun. Does NOT touch newP2StunRoundsRemaining — that
          // counter is for aoe_stun's multi-round persistence.
          opponentStunned = true
          break
        case 'aoe_stun': {
          // Multi-round opponent stun. magnitude = number of rounds opp skips
          // (default 2). End-of-round decrement removes one round.
          // Spec: docs/06_game_systems/SKILL_TREE_DESIGN_V2.md §8 (Tank Quake).
          const rounds = Math.max(1, Math.floor(firedPlayerActive.magnitude || 2))
          opponentStunned = true
          newP2StunRoundsRemaining = rounds
          break
        }
        default:
          break // offensive actives mutate the player's own strike below
      }
    }

    // Round state. One object (not closed-over `let`s) so TS keeps the declared
    // union types after the strike helpers mutate it.
    const R = {
      hpPlayer: Math.min(attackerRow.maxHp, curAttackerHp + playerExtraHeal), // player heal lands first
      hpOpp: curDefenderHp,
      playerTurn: null as Turn | null,
      oppTurn: null as Turn | null,
      firedOppActive: null as ActiveSlotSnapshot | null,
      oppHasShield: false,        // opp shield picked BEFORE the player's strike (opp-first rounds)
      playerOpensOpp: false,
      oppOpensPlayer: false,
    }

    // 1) Player strike — attacker-chosen zones vs the policy's block.
    const doPlayerStrike = async () => {
      const playerSeed = deriveSeed(match_id, strikeIndex, 'p')
      const playerInput: SingleStrikeInput = {
        attacker: attackerStats,
        defender: defenderStats,
        attackerZone: attacker_zone,
        defenderZone: oppDefZone,
        defenderHp: R.hpOpp,
        seed: playerSeed,
        turn: strikeIndex + 1,
        defenderOpened: opponentOpened,
        cooldownState: p1SkillCd,
      }
      const playerResult = await resolveSingleStrike(playerInput)
      let turn = playerResult.turn
      let newOppHp = playerResult.newDefenderHp
      R.playerOpensOpp = turn.opensDefender === true

      // Offensive actives mutate the player's strike.
      if (firedPlayerActive) {
        switch (firedPlayerActive.action_type) {
          case 'burst_damage':
          case 'aoe_damage': {
            // aoe_damage is a 1v1 alias of burst_damage (Talents v2 §8).
            const originalDmg = turn.damage
            const boosted = applyBurstDamage(originalDmg, firedPlayerActive.magnitude)
            const delta = boosted - originalDmg
            turn = { ...turn, damage: boosted }
            newOppHp = Math.max(0, newOppHp - delta)
            break
          }
          case 'execute': {
            if (shouldExecute(R.hpOpp, defenderRow.maxHp, firedPlayerActive.magnitude)) {
              const finishingDmg = turn.damage + Math.max(0, newOppHp)
              turn = { ...turn, damage: finishingDmg }
              newOppHp = 0
            }
            break
          }
          case 'stealth': {
            // Force-crit on the player's CURRENT-round attack (Talents v2 §8:
            // "next attack auto-crits" — the slot fires before the strike
            // resolves on the same round, so "next" = "this").
            if (!turn.isCrit && turn.damage > 0) {
              const baseDmg = turn.damage
              const boostedDmg = Math.round(baseDmg * stealthCritMultiplier)
              const delta = boostedDmg - baseDmg
              turn = { ...turn, damage: boostedDmg, isCrit: true, ...(turn.outcome === 'hit' ? { outcome: 'crit' as const } : {}) }
              newOppHp = Math.max(0, newOppHp - delta)
            }
            break
          }
          default:
            break
        }
      }

      // Opp shield raised earlier this round (opp-first order) soaks this hit.
      if (R.oppHasShield && R.firedOppActive) {
        const reduced = applyShield(turn.damage, R.firedOppActive.magnitude)
        const refund = turn.damage - reduced
        if (refund > 0) {
          turn = { ...turn, damage: reduced }
          newOppHp = Math.min(defenderRow.maxHp, newOppHp + refund)
        }
      }

      R.hpOpp = newOppHp
      // Lifesteal + v2 counter (head into block) land on the player now.
      if (playerResult.healAmount > 0) R.hpPlayer = Math.min(attackerRow.maxHp, R.hpPlayer + playerResult.healAmount)
      if (playerResult.counterDamage > 0) R.hpPlayer = Math.max(0, R.hpPlayer - playerResult.counterDamage)
      R.playerTurn = turn
    }

    // 2) Opponent strike — policy zones vs the player's declared block.
    const doOpponentStrike = async (playerAlreadyStruck: boolean) => {
      // AI picks its active right before it swings, seeing the current HPs.
      const picked = pickOpponentActive(
        actives.p2,
        R.hpOpp,
        defenderRow.maxHp,
        R.hpPlayer,
        attackerRow.maxHp,
        actives.p1
      )
      R.firedOppActive = picked
      if (picked?.action_type === 'shield_self') {
        if (playerAlreadyStruck && R.playerTurn) {
          // Player-first order: the shield retroactively soaks the hit it just took (legacy behaviour).
          const reduced = applyShield(R.playerTurn.damage, picked.magnitude)
          const refund = R.playerTurn.damage - reduced
          if (refund > 0) {
            R.playerTurn = { ...R.playerTurn, damage: reduced }
            R.hpOpp = Math.min(defenderRow.maxHp, R.hpOpp + refund)
          }
        } else {
          R.oppHasShield = true
        }
      }
      if (picked?.action_type === 'heal_self') {
        const oppHeal = healAmountFromActive(defenderRow.maxHp, picked.magnitude)
        R.hpOpp = Math.min(defenderRow.maxHp, R.hpOpp + oppHeal)
      }

      if (opponentStunned) return

      const oppSeed = deriveSeed(match_id, strikeIndex, 'o')
      const oppInput: SingleStrikeInput = {
        attacker: defenderStats,
        defender: attackerStats,
        attackerZone: oppAtkZone,
        defenderZone: defender_zone,
        defenderHp: R.hpPlayer,
        seed: oppSeed,
        turn: strikeIndex + 1,
        defenderOpened: playerOpened,
        cooldownState: p2SkillCd,
      }
      const oppResult = await resolveSingleStrike(oppInput)
      let oppDamage = oppResult.turn.damage
      let oppForcedCrit = false
      if (picked?.action_type === 'burst_damage' || picked?.action_type === 'aoe_damage') {
        oppDamage = applyBurstDamage(oppDamage, picked.magnitude)
      } else if (
        picked?.action_type === 'execute' &&
        shouldExecute(R.hpPlayer, attackerRow.maxHp, picked.magnitude)
      ) {
        oppDamage = R.hpPlayer  // finishing blow
      } else if (picked?.action_type === 'stealth') {
        if (!oppResult.turn.isCrit && oppDamage > 0) {
          const critMul = Math.max(1, combatCfg.CRIT_MULTIPLIER ?? 2.0)
          oppDamage = Math.round(oppDamage * critMul)
          oppForcedCrit = true
        }
      }
      // Player's shield reduces incoming opponent damage
      if (playerHasShield) {
        oppDamage = applyShield(oppDamage, firedPlayerActive?.magnitude ?? 0)
      }
      const oppDamageChanged = oppDamage !== oppResult.turn.damage
      let turn: Turn = oppDamageChanged || oppForcedCrit
        ? {
            ...oppResult.turn,
            damage: oppDamage,
            ...(oppForcedCrit ? { isCrit: true, ...(oppResult.turn.outcome === 'hit' ? { outcome: 'crit' as const } : {}) } : {}),
          }
        : oppResult.turn
      R.oppOpensPlayer = turn.opensDefender === true
      R.hpPlayer = Math.max(0, R.hpPlayer - oppDamage)
      if (oppResult.healAmount > 0) R.hpOpp = Math.min(defenderRow.maxHp, R.hpOpp + oppResult.healAmount)
      if (oppResult.counterDamage > 0) R.hpOpp = Math.max(0, R.hpOpp - oppResult.counterDamage)
      turn = { ...turn, defenderHpAfter: R.hpPlayer }
      R.oppTurn = turn
    }

    if (playerFirst) {
      await doPlayerStrike()
      if (R.hpOpp > 0 && R.hpPlayer > 0) await doOpponentStrike(true)
    } else {
      await doOpponentStrike(false)
      if (R.hpOpp > 0 && R.hpPlayer > 0) await doPlayerStrike()
    }
    if (R.playerTurn) {
      R.playerTurn = { ...R.playerTurn, defenderHpAfter: Math.max(0, R.hpOpp) }
    }

    // Skill cooldowns tick once per round for both sides (mirrors runCombat).
    tickCooldowns(p1SkillCd)
    tickCooldowns(p2SkillCd)

    const newAttackerHp = R.hpPlayer
    const newDefenderHp = R.hpOpp
    const firedOppActive = R.firedOppActive
    const oppActiveLabel: string | null = firedOppActive?.action_type ?? null
    // A round where the opponent struck first and killed the player has no
    // player strike; the client renders `player_strike: null` as "no swing".
    const mutatedPlayerTurn: Turn | null = R.playerTurn
    const oppResult = R.oppTurn ? { turn: R.oppTurn } : null

    const matchFinished = newAttackerHp <= 0 || newDefenderHp <= 0 || (strikeIndex + 1) >= MAX_ROUNDS
    const opponentId = match.player2Id ?? opponentSnapshot?.id ?? ''
    let winnerId: string | null = null
    if (matchFinished) {
      if (newDefenderHp <= 0 && newAttackerHp > 0) winnerId = match.player1Id
      else if (newAttackerHp <= 0 && newDefenderHp > 0) winnerId = opponentId
      else {
        // Both alive at MAX_ROUNDS (or both 0, unlikely) → higher HP% wins
        const aPct = newAttackerHp / attackerRow.maxHp
        const dPct = newDefenderHp / defenderRow.maxHp
        winnerId = aPct >= dPct ? match.player1Id : opponentId
      }
    }

    // The client decodes `player_strike` as non-optional. If the opponent struck
    // first and the player fell before swinging, send an inert zero turn
    // tagged `outcome: 'none'` instead of null.
    const playerStrikePayload: Turn = mutatedPlayerTurn ?? {
      turnNumber: strikeIndex + 1,
      attackerId: match.player1Id,
      damage: 0,
      isCrit: false,
      isDodge: false,
      defenderHpAfter: Math.max(0, newDefenderHp),
      targetZone: attacker_zone,
      defendZone: oppDefZone,
      outcome: 'none',
    }

    const round: StoredRound = {
      idx: strikeIndex,
      player_atk: attacker_zone,
      player_def: defender_zone,
      opp_atk: oppAtkZone,
      opp_def: oppDefZone,
      player_strike: playerStrikePayload,
      opp_strike: oppResult?.turn ?? null,
      attacker_hp_after: Math.max(0, newAttackerHp),
      defender_hp_after: Math.max(0, newDefenderHp),
      player_active: firedSlotIndex,
      opponent_active: firedOppActive?.slot_index ?? null,
      opened_next: { player: R.oppOpensPlayer, opponent: R.playerOpensOpp },
      initiative: playerFirst ? 'player' : 'opponent',
    }

    // --- Phase 3 + Talents v2: update actives state ---
    //   Talent fires → set cooldown_remaining = cooldown_max.
    //   Consumable fires → set consumed = true.
    //   All OTHER slots tick down by 1 at end of round.
    //   cooldown_reset (Mage Rewind ult) → zero-out cooldowns on the firing
    //     side's OTHER non-consumable slots (the fired slot itself stays at
    //     full cooldown so it can't chain-reset every round).
    const advancedP1 = advanceActivesAfterRound(
      actives.p1,
      firedPlayerActive?.slot_index ?? null,
    )
    const advancedP2 = advanceActivesAfterRound(
      actives.p2,
      firedOppActive?.slot_index ?? null,
    )
    const updatedP1 =
      firedPlayerActive?.action_type === 'cooldown_reset'
        ? advancedP1.map((slot) =>
            slot.slot_index === firedPlayerActive!.slot_index || isConsumableSlot(slot)
              ? slot
              : { ...slot, cooldown_remaining: 0 },
          )
        : advancedP1
    const updatedP2 =
      firedOppActive?.action_type === 'cooldown_reset'
        ? advancedP2.map((slot) =>
            slot.slot_index === firedOppActive!.slot_index || isConsumableSlot(slot)
              ? slot
              : { ...slot, cooldown_remaining: 0 },
          )
        : advancedP2

    // End-of-round stun decrement. aoe_stun fired this round set
    // newP{1,2}StunRoundsRemaining = magnitude (e.g. 2). The current round
    // already consumed one round of stun (counter was suppressed), so we
    // decrement by 1. Pre-existing stun carry-over decrements the same way.
    const newActives: InteractiveActivesState = {
      p1: updatedP1,
      p2: updatedP2,
      p1_buffs: { stunRoundsRemaining: Math.max(0, newP1StunRoundsRemaining - 1) },
      p2_buffs: { stunRoundsRemaining: Math.max(0, newP2StunRoundsRemaining - 1) },
      p1_skill_cd: p1SkillCd,
      p2_skill_cd: p2SkillCd,
    }

    // Persist round in a single transaction:
    //   1. If a consumable fired, lock + decrement its inventory row.
    //      If quantity < 1 (user consumed it out-of-combat between match-start
    //      and now) — abort with 400 so the client can strip it from the UI.
    //   2. Atomic updateMany on pvp_matches with optimistic concurrency guard
    //      (strikeIndex + status). If the guard fails, rollback the inventory
    //      decrement too.
    try {
      await prisma.$transaction(async (tx) => {
        if (firedIsConsumable && firedPlayerActive?.consumable_type) {
          const consumableType = firedPlayerActive.consumable_type
          const [inv] = await tx.$queryRawUnsafe<Array<{ id: string; quantity: number }>>(
            `SELECT id, quantity FROM consumable_inventory
               WHERE character_id = $1 AND consumable_type::text = $2
               FOR UPDATE`,
            match.player1Id,
            consumableType
          )
          if (!inv || inv.quantity < 1) {
            throw new Error('OUT_OF_CONSUMABLE')
          }
          await tx.$executeRawUnsafe(
            `UPDATE consumable_inventory
                SET quantity = quantity - 1
              WHERE id = $1`,
            inv.id
          )
        }

        const updated = await tx.pvpMatch.updateMany({
          where: { id: match_id, interactiveStrikeIndex: strikeIndex, status: 'in_progress' },
          data: {
            interactiveChoices: [...choices, round] as unknown as Prisma.InputJsonValue,
            interactiveStrikeIndex: strikeIndex + 1,
            interactiveActives: newActives as unknown as Prisma.InputJsonValue,
          },
        })
        if (updated.count === 0) {
          throw new Error('MATCH_STATE_CHANGED')
        }
      })
    } catch (txErr) {
      if (txErr instanceof Error) {
        if (txErr.message === 'OUT_OF_CONSUMABLE') {
          const reconciledActives =
            firedSlotIndex !== null
              ? removePlayerActiveSlot(actives, firedSlotIndex)
              : actives
          // Strip the impossible potion slot from the persisted match snapshot
          // so the client can recover in-place instead of getting stuck in a
          // retry loop that keeps failing the same round.
          const reconciled = await prisma.pvpMatch.updateMany({
            where: { id: match_id, interactiveStrikeIndex: strikeIndex, status: 'in_progress' },
            data: { interactiveActives: reconciledActives as unknown as Prisma.InputJsonValue },
          })
          if (reconciled.count === 0) {
            return NextResponse.json(
              { error: 'Match state changed, please retry' },
              { status: 409 }
            )
          }
          await Promise.all([
            invalidateActiveSlotsCache(match.player1Id),
            firedSlotIndex !== null && firedPlayerActive?.consumable_type
              ? prisma.characterActiveSlot.deleteMany({
                  where: {
                    characterId: match.player1Id,
                    slotIndex: firedSlotIndex,
                    consumableType: firedPlayerActive.consumable_type as ConsumableType,
                  },
                })
              : Promise.resolve(),
          ])
          return NextResponse.json(
            {
              error: 'You have no potions of this type left',
              code: 'OUT_OF_CONSUMABLE',
              recoverable: true,
              actives: reconciledActives,
              removed_slot_index: firedSlotIndex,
              removed_consumable_type: firedPlayerActive?.consumable_type ?? null,
            },
            { status: 409 }
          )
        }
        if (txErr.message === 'MATCH_STATE_CHANGED') {
          return NextResponse.json(
            { error: 'Match state changed, please retry' },
            { status: 409 }
          )
        }
      }
      throw txErr
    }

    if (firedIsConsumable && firedPlayerActive?.consumable_type) {
      await invalidateActiveSlotsCache(match.player1Id)
    }

    return NextResponse.json({
      match_id,
      strike_index: strikeIndex,
      player_strike: playerStrikePayload,
      opponent_strike: oppResult?.turn ?? null,
      attacker_hp: round.attacker_hp_after,
      defender_hp: round.defender_hp_after,
      opp_zones: { attack: oppAtkZone, defend: oppDefZone },
      match_finished: matchFinished,
      winner_id: winnerId,
      // Combat v2 (additive): who swung first, and whose block is void next round.
      initiative: round.initiative,
      opened: round.opened_next,
      zone_matrix_v2: v2,
      actives: newActives,
      player_active_fired: firedSlotIndex,
      player_active_label: playerActiveLabel,
      // Phase 4.B: surface consumable fire so iOS can refresh inventory counts
      // and show a distinct "Potion used" banner instead of the generic heal_self.
      player_consumable_fired: firedIsConsumable
        ? (firedPlayerActive?.consumable_type ?? null)
        : null,
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
