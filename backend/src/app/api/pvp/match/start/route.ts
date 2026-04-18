import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { initCombatConfig } from '@/lib/game/combat'
import { loadCombatCharacter } from '@/lib/game/combat-loader'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { getStaminaConfig } from '@/lib/game/live-config'
import { getHpRestoreFraction, isHealthPotion } from '@/lib/game/consumable-effects'
import { ConsumableType, Prisma } from '@prisma/client'

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

    // Load equipped active-slot snapshot for both players. Snapshotted at
    // match-start so mid-match equip changes (from another device) don't
    // influence the current duel. All cooldowns start at 0 (ready).
    //
    // Phase 4.B: slots can be EITHER a talent (node_id set) OR a consumable
    // (consumable_type set). Both kinds unify into the same ActiveSlotSnapshot
    // shape downstream so the strike-resolver + client only see one list.
    type TalentRow = {
      slot_index: number
      // passive_nodes.id is a UUID string (Prisma `String @id @default(uuid())`),
      // NOT an integer. Typing it as `number` caused iOS /match/start to crash
      // with "type mismatch Int at actives.p1.[0].nodeId" once any talent was
      // equipped (incident 2026-04-14).
      node_id: string
      node_key: string
      name: string
      icon: string | null
      active_action_type: string | null
      active_cooldown: number | null
      active_magnitude: number | null
    }
    type ConsumableRow = {
      slot_index: number
      consumable_type: string
      name: string | null
      icon: string | null
    }
    async function loadActives(charId: string) {
      const [talentRows, consumableRows] = await Promise.all([
        prisma.$queryRawUnsafe<TalentRow[]>(
          `SELECT s.slot_index, n.id AS node_id, n.node_key, n.name, n.icon,
                  n.active_action_type, n.active_cooldown, n.active_magnitude
             FROM character_active_slots s
             JOIN passive_nodes n ON n.id = s.node_id
             WHERE s.character_id = $1 AND n.is_activatable = true
             ORDER BY s.slot_index`,
          charId
        ),
        prisma.$queryRawUnsafe<ConsumableRow[]>(
          `SELECT s.slot_index, s.consumable_type::text AS consumable_type,
                  COALESCE(i.item_name, s.consumable_type::text) AS name,
                  i.image_key AS icon
             FROM character_active_slots s
             JOIN consumable_inventory ci
               ON ci.character_id = s.character_id
              AND ci.consumable_type = s.consumable_type
             LEFT JOIN items i ON i.catalog_id = s.consumable_type::text
             WHERE s.character_id = $1
               AND s.consumable_type IS NOT NULL
               AND ci.quantity > 0
             ORDER BY s.slot_index`,
          charId
        ),
      ])
      return { talentRows, consumableRows }
    }
    const [p1Slots, p2Slots] = await Promise.all([
      loadActives(attacker.id),
      loadActives(defender.id),
    ])

    // Pre-resolve heal fractions for consumables (magnitude snapshot: frozen for this duel).
    const allConsumableTypes = [
      ...p1Slots.consumableRows.map((r) => r.consumable_type),
      ...p2Slots.consumableRows.map((r) => r.consumable_type),
    ]
    const uniqueConsumableTypes = [...new Set(allConsumableTypes)] as ConsumableType[]
    const healFractionEntries = await Promise.all(
      uniqueConsumableTypes.map(async (t) => [t, await getHpRestoreFraction(t)] as const)
    )
    const healFractionByType = new Map(healFractionEntries)

    const actorActivesSnapshot = (slots: { talentRows: TalentRow[]; consumableRows: ConsumableRow[] }) => {
      const talentSnaps = slots.talentRows.map((r) => ({
        slot_index: r.slot_index,
        kind: 'talent' as const,
        node_id: r.node_id as string | null,
        node_key: r.node_key as string | null,
        consumable_type: null as string | null,
        name: r.name,
        icon: r.icon,
        action_type: r.active_action_type,
        cooldown_max: r.active_cooldown ?? 0,
        magnitude: r.active_magnitude ?? 0,
        cooldown_remaining: 0,
        consumed: false,
      }))
      const consumableSnaps = slots.consumableRows.map((r) => {
        const ct = r.consumable_type as ConsumableType
        const magnitude = isHealthPotion(ct) ? (healFractionByType.get(ct) ?? 0) : 0
        return {
          slot_index: r.slot_index,
          kind: 'consumable' as const,
          node_id: null as string | null,
          node_key: null as string | null,
          consumable_type: r.consumable_type,
          name: r.name ?? r.consumable_type,
          icon: r.icon,
          // Reuse existing heal_self handler in strike-resolver — consumables
          // behave identically to a heal_self talent in terms of HP math.
          action_type: 'heal_self' as string | null,
          cooldown_max: 0,          // no cooldown — gated by `consumed` instead
          magnitude,
          cooldown_remaining: 0,
          consumed: false,
        }
      })
      return [...talentSnaps, ...consumableSnaps].sort((a, b) => a.slot_index - b.slot_index)
    }
    const interactiveActives = {
      p1: actorActivesSnapshot(p1Slots),
      p2: actorActivesSnapshot(p2Slots),
    }

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

      const match = await tx.pvpMatch.create({
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
          interactiveChoices: [] as Prisma.JsonArray,
          interactiveActives: interactiveActives as Prisma.InputJsonValue,
        },
      })

      return { match, newStamina: staminaAfter }
    })

    // Interactive Combat is a discrete duel — both fighters enter at full HP.
    // Classic `/fight` used persisted currentHp but the UI never rendered it;
    // Interactive Combat shows the HP bar from round 0, so persisted damage
    // looks like "enemy HP dropped before first strike". Use maxHp for both.
    // The 30% HP gate on the attacker above still prevents near-death PvP.
    const startAttackerHp = attacker.maxHp
    const startDefenderHp = defender.maxHp
    // loadCombatCharacter calls above keep the combat config warm; stat bodies
    // themselves aren't needed here because /match/start doesn't resolve combat.
    void attackerStats; void defenderStats;

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
      actives: interactiveActives,
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
