import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { initCombatConfig } from '@/lib/game/combat'
import { loadCombatCharacter } from '@/lib/game/combat-loader'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { getStaminaConfig } from '@/lib/game/live-config'

/**
 * POST /api/pvp/match/start — Interactive Combat v1 (FEATURE-FLAGGED)
 *
 * Creates an in-progress pvp_matches row. Reserves stamina / free-pvp slot
 * inside the same transaction as /pvp/fight does. Does NOT run combat —
 * combat happens round-by-round via /pvp/strike, then is finalized via
 * /pvp/match/complete (ELO + rewards).
 *
 * Gate: `INTERACTIVE_COMBAT_V1` env flag. 404 when off.
 *
 * Body: { character_id, opponent_id }
 * Returns: { match_id, attacker{...}, defender{...}, stamina, max_rounds }
 */

function isNewUtcDay(date: Date | null): boolean {
  if (!date) return true
  const today = new Date()
  today.setUTCHours(0, 0, 0, 0)
  const d = new Date(date)
  d.setUTCHours(0, 0, 0, 0)
  return d.getTime() < today.getTime()
}

// Per-match round cap. If no KO by this point, /complete picks winner by HP%.
const MAX_ROUNDS = 15
// Match expires if no /complete call within this window.
const MATCH_TIMEOUT_MS = 10 * 60_000 // 10 min

export async function POST(req: NextRequest) {
  if (process.env.INTERACTIVE_COMBAT_V1 === 'false') {
    return NextResponse.json({ error: 'Not Found' }, { status: 404 })
  }

  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`pvp-match-start:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const STAMINA = await getStaminaConfig()
    const body = await req.json()
    const { character_id, opponent_id } = body ?? {}

    if (typeof character_id !== 'string' || typeof opponent_id !== 'string') {
      return NextResponse.json({ error: 'character_id and opponent_id required' }, { status: 400 })
    }
    if (character_id === opponent_id) {
      return NextResponse.json({ error: 'Cannot fight yourself' }, { status: 400 })
    }

    const select = {
      id: true, userId: true, characterName: true, class: true, origin: true,
      level: true, avatar: true, maxHp: true, currentHp: true, lastHpUpdate: true,
      currentStamina: true, maxStamina: true, lastStaminaUpdate: true,
      pvpRating: true, freePvpToday: true, freePvpDate: true,
    } as const

    const [attacker, defender] = await Promise.all([
      prisma.character.findUnique({ where: { id: character_id }, select }),
      prisma.character.findUnique({ where: { id: opponent_id }, select }),
    ])

    if (!attacker) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (attacker.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    if (!defender) return NextResponse.json({ error: 'Opponent not found' }, { status: 404 })

    // Pre-check HP + stamina (authoritative re-check happens inside transaction)
    const preHp = attacker.currentHp
    const minHp = Math.ceil(attacker.maxHp * 0.3)
    if (preHp < minHp) {
      return NextResponse.json(
        { error: 'Not enough health to fight. Use a health potion first!',
          currentHp: preHp, minHealthRequired: minHp, maxHp: attacker.maxHp },
        { status: 400 }
      )
    }
    const preStamina = await calculateCurrentStamina(
      attacker.currentStamina, attacker.maxStamina,
      attacker.lastStaminaUpdate ?? new Date()
    )
    const preFreeUsed = isNewUtcDay(attacker.freePvpDate) ? 0 : attacker.freePvpToday
    const preHasFree = preFreeUsed < STAMINA.FREE_PVP_PER_DAY
    if (!preHasFree && preStamina.stamina < STAMINA.PVP_COST) {
      return NextResponse.json(
        { error: 'Not enough stamina', currentStamina: preStamina.stamina, required: STAMINA.PVP_COST },
        { status: 400 }
      )
    }

    await initCombatConfig()
    const [attackerStats, defenderStats] = await Promise.all([
      loadCombatCharacter(attacker.id),
      loadCombatCharacter(defender.id),
    ])

    const now = new Date()
    const timeoutAt = new Date(now.getTime() + MATCH_TIMEOUT_MS)

    const { match, newStamina } = await prisma.$transaction(async (tx) => {
      // Lock attacker row
      const [locked] = await tx.$queryRawUnsafe<Array<{
        id: string; current_hp: number; max_hp: number;
        current_stamina: number; max_stamina: number; last_stamina_update: Date;
        free_pvp_today: number; free_pvp_date: Date | null
      }>>(
        `SELECT id, current_hp, max_hp, current_stamina, max_stamina, last_stamina_update, free_pvp_today, free_pvp_date
         FROM characters WHERE id = $1 FOR UPDATE`,
        attacker.id
      )
      if (!locked) throw new Error('ATTACKER_NOT_FOUND')

      const lockedMinHp = Math.ceil(locked.max_hp * 0.3)
      if (locked.current_hp < lockedMinHp) throw new Error('NOT_ENOUGH_HP')

      const lockedSt = await calculateCurrentStamina(
        locked.current_stamina, locked.max_stamina,
        locked.last_stamina_update ?? new Date()
      )
      const lockedFreeUsed = isNewUtcDay(locked.free_pvp_date) ? 0 : locked.free_pvp_today
      const lockedHasFree = lockedFreeUsed < STAMINA.FREE_PVP_PER_DAY
      const cost = lockedHasFree ? 0 : STAMINA.PVP_COST
      if (!lockedHasFree && lockedSt.stamina < STAMINA.PVP_COST) {
        throw new Error('NOT_ENOUGH_STAMINA')
      }
      const staminaAfter = lockedSt.stamina - cost

      const attackerUpdate: Record<string, unknown> = {
        currentStamina: staminaAfter,
        lastStaminaUpdate: now,
      }
      if (lockedHasFree) {
        attackerUpdate.freePvpToday = lockedFreeUsed + 1
        attackerUpdate.freePvpDate = now
      }
      await tx.character.update({ where: { id: attacker.id }, data: attackerUpdate })

      // Local Prisma client may be stale for the 4 Interactive Combat v1 columns
      // (memory: feedback_stale_prisma_client_triage). Cast to any; prod build
      // regenerates the client so types will be precise there.
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const match = await (tx.pvpMatch.create as any)({
        data: {
          player1Id: attacker.id,
          player2Id: defender.id,
          player1RatingBefore: attacker.pvpRating,
          player1RatingAfter: attacker.pvpRating,   // updated on /complete
          player2RatingBefore: defender.pvpRating,
          player2RatingAfter: defender.pvpRating,
          winnerId: null,
          loserId: null,
          combatLog: [],
          turnsTaken: 0,
          goldReward: 0,
          xpReward: 0,
          matchType: 'ranked',
          isRevenge: false,
          status: 'in_progress',
          interactiveStrikeIndex: 0,
          interactiveTimeoutAt: timeoutAt,
          interactiveChoices: [],
        },
      })

      return { match, newStamina: staminaAfter }
    })

    // Initial HPs as combat starts (current_hp from characters, snapshotted)
    const startAttackerHp = attackerStats.currentHp ?? attacker.maxHp
    const startDefenderHp = defenderStats.currentHp ?? defender.maxHp

    return NextResponse.json({
      match_id: match.id,
      max_rounds: MAX_ROUNDS,
      timeout_at: timeoutAt.toISOString(),
      attacker: {
        id: attacker.id,
        character_name: attacker.characterName,
        class: attacker.class,
        origin: attacker.origin,
        level: attacker.level,
        avatar: attacker.avatar,
        max_hp: attacker.maxHp,
        current_hp: startAttackerHp,
      },
      defender: {
        id: defender.id,
        character_name: defender.characterName,
        class: defender.class,
        origin: defender.origin,
        level: defender.level,
        avatar: defender.avatar,
        max_hp: defender.maxHp,
        current_hp: startDefenderHp,
      },
      stamina: { current: newStamina, max: attacker.maxStamina },
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_ENOUGH_STAMINA') {
        return NextResponse.json({ error: 'Not enough stamina' }, { status: 400 })
      }
      if (error.message === 'NOT_ENOUGH_HP') {
        return NextResponse.json({ error: 'Not enough health to fight. Use a health potion first!' }, { status: 400 })
      }
    }
    const detail = error instanceof Error ? error.message : String(error)
    const stack = error instanceof Error ? error.stack : undefined
    console.error('pvp match/start error:', detail, '\nstack:', stack)
    return NextResponse.json(
      { error: 'Failed to start match', detail },
      { status: 500 }
    )
  }
}
