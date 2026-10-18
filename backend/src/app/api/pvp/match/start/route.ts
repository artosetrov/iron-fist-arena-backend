import { DESCENT_DUNGEON_ID } from '@/lib/game/descent/content'
import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { freePvpPerDay, PREMIUM_ENTITLEMENT_USER_SELECT } from '@/lib/game/premium'
import { prisma } from '@/lib/prisma'
import { isKillSwitchOn } from '@/lib/game/feature-flags'
import { rateLimit } from '@/lib/rate-limit'
import { createSeededRng, diceHitProfile, initCombatConfig, type CharacterStats } from '@/lib/game/combat'
import { loadCombatCharacter } from '@/lib/game/combat-loader'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { getDiceConfig, getStaminaConfig } from '@/lib/game/live-config'
import { isNpcBot, generateBotCombatStats } from '@/lib/game/npc-bots'
import { generateDungeonFloorFromDB, type Enemy } from '@/lib/game/dungeon'
import { Prisma } from '@prisma/client'
import { randomUUID } from 'crypto'
import { sameOwner, selfFarmResponse } from '@/lib/game/pvp-opponent'
import { createDiceState, publicView, rollRound } from '@/lib/game/dice'
import { botDiceLoadout, emptyLoadout, loadDiceLoadout, runeInfoFor } from '@/lib/game/dice-loadout'
import { deriveCombatSeed } from '@/lib/game/combat-seed'
import {
  applyArtifactStatBoosts, applyRushBuffs, effectiveHp, generateRushEnemy, isCombatRoom,
  RUSH_ARTIFACTS, type RushArtifact, type RushState,
} from '@/lib/game/dungeon-rush'

type OpponentType = 'pvp' | 'bot' | 'dungeon_boss' | 'dungeon_rush'
const VALID_OPPONENT_TYPES: readonly OpponentType[] = ['pvp', 'bot', 'dungeon_boss', 'dungeon_rush']
function isOpponentType(v: unknown): v is OpponentType {
  return typeof v === 'string' && (VALID_OPPONENT_TYPES as readonly string[]).includes(v)
}

interface DungeonRunFightState {
  enemies: Enemy[]
  isBoss: boolean
  floorsCleared: number
  totalGoldEarned: number
  totalXpEarned: number
}

/// Mirrors `enemyToCharacterStats` in /api/dungeons/run/[id]/fight. Kept inline
/// here to avoid a circular import from the dungeon route module; consider
/// hoisting both copies into lib/game/dungeon.ts once old combat is retired.
function dungeonEnemyToCharacterStats(enemy: Enemy): CharacterStats {
  return {
    id: enemy.id,
    name: enemy.name,
    class: 'warrior',
    level: enemy.level,
    str: enemy.str,
    agi: enemy.agi,
    vit: Math.round(enemy.maxHp / 8),
    end: Math.round(enemy.armor / 2),
    int: Math.round(enemy.magicResist),
    wis: 5,
    luk: 5,
    cha: 1,
    maxHp: enemy.maxHp,
    armor: enemy.armor,
    magicResist: enemy.magicResist,
    isPassiveTarget: enemy.isPassive === true,
  }
}

/**
 * POST /api/pvp/match/start — Interactive Combat v1 (FEATURE-FLAGGED)
 *
 * Creates an in-progress pvp_matches row. Reserves stamina / free-pvp slot
 * inside the same transaction as /pvp/fight does. Does NOT run combat —
 * dice combat (DICE_RUNES_DESIGN.md) runs round-by-round via
 * /pvp/dice/act + /pvp/dice/resolve, then is finalized via
 * /pvp/match/complete (ELO + rewards). Round 1 is rolled here.
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

  // Kill switch (admin → Feature Flags → pvp_enabled).
  if (!(await isKillSwitchOn('pvp_enabled', user.id))) {
    return NextResponse.json(
      { error: 'The Arena is closed for maintenance. Please try again soon.', code: 'PVP_DISABLED' },
      { status: 503 },
    )
  }

  try {
    const STAMINA = await getStaminaConfig()
    const body = await req.json()
    const {
      character_id,
      opponent_id,
      opponent_type: rawOpponentType,
      dungeon_run_id,
    } = body ?? {}

    if (typeof character_id !== 'string' || typeof opponent_id !== 'string') {
      return NextResponse.json({ error: 'character_id and opponent_id required' }, { status: 400 })
    }

    // Derive opponent_type: explicit field wins; otherwise infer from opponent_id prefix.
    // Old iOS clients without opponent_type will still get bot mode when firing at npc_* ids.
    const opponentType: OpponentType = isOpponentType(rawOpponentType)
      ? rawOpponentType
      : isNpcBot(opponent_id)
        ? 'bot'
        : 'pvp'

    if (opponentType === 'pvp' && character_id === opponent_id) {
      return NextResponse.json({ error: 'Cannot fight yourself' }, { status: 400 })
    }

    if ((opponentType === 'dungeon_boss' || opponentType === 'dungeon_rush') && typeof dungeon_run_id !== 'string') {
      return NextResponse.json(
        { error: `dungeon_run_id required for ${opponentType} opponent_type` },
        { status: 400 },
      )
    }

    const select = {
      id: true, userId: true, characterName: true, class: true, origin: true,
      level: true, avatar: true, maxHp: true, currentHp: true, lastHpUpdate: true,
      currentStamina: true, maxStamina: true, lastStaminaUpdate: true,
      pvpRating: true, freePvpToday: true, freePvpDate: true,
      user: { select: PREMIUM_ENTITLEMENT_USER_SELECT },
      pvpWins: true, pvpLosses: true,
    } as const

    const attacker = await prisma.character.findUnique({ where: { id: character_id }, select })
    if (!attacker) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (attacker.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    // For PvP mode, defender is a real character row. For bot / dungeon_boss,
    // defender is synthesized from a generator / dungeon state respectively.
    const defender = opponentType === 'pvp'
      ? await prisma.character.findUnique({ where: { id: opponent_id }, select })
      : null
    if (opponentType === 'pvp' && !defender) {
      return NextResponse.json({ error: 'Opponent not found' }, { status: 404 })
    }
    if (defender && sameOwner(attacker, defender)) {
      console.warn(`[pvp] self-farm blocked on match start: user ${user.id}, ${character_id} vs ${opponent_id}`)
      return selfFarmResponse()
    }
    if (opponentType === 'bot' && !isNpcBot(opponent_id)) {
      return NextResponse.json({ error: 'Invalid bot opponent id (expected npc_* prefix)' }, { status: 400 })
    }

    // For dungeon_boss, pre-load the run so we can bail early with a clean
    // error before any DB writes (stamina / match create).
    const dungeonRun =
      opponentType === 'dungeon_boss'
        ? await prisma.dungeonRun.findFirst({
            where: {
              id: dungeon_run_id as string,
              characterId: attacker.id,
              difficulty: { not: 'rush' },
            },
          })
        : null
    if (opponentType === 'dungeon_boss' && !dungeonRun) {
      return NextResponse.json({ error: 'No active dungeon run found' }, { status: 404 })
    }

    // Pull the first boss enemy from the current floor's state. Matches the
    // dungeon-run fight contract (one boss per floor).
    let dungeonBoss: Enemy | null =
      dungeonRun !== null
        ? (((dungeonRun.state as unknown as DungeonRunFightState | null)?.enemies?.[0]) ?? null)
        : null
    // Runs that landed on an old variety floor (3/5/7/9) carry `enemies: []`.
    // Every floor is a boss now — regenerate it instead of bricking the run.
    if (opponentType === 'dungeon_boss' && dungeonRun && !dungeonBoss) {
      const floor = await generateDungeonFloorFromDB(dungeonRun.currentFloor, dungeonRun.difficulty, dungeonRun.dungeonId)
      dungeonBoss = floor.enemies[0] ?? null
    }
    if (opponentType === 'dungeon_boss' && !dungeonBoss) {
      return NextResponse.json({ error: 'Dungeon floor has no boss to fight' }, { status: 409 })
    }

    // Dungeon Rush — the current combat room of the caller's rush run. The
    // fight is played on dice here and settled by /dungeon-rush/fight with
    // this match_id (rewards, HP%, next room stay in the rush route).
    const rushRun =
      opponentType === 'dungeon_rush'
        ? await prisma.dungeonRun.findFirst({
            where: { id: dungeon_run_id as string, characterId: attacker.id, difficulty: 'rush', dungeonId: { not: DESCENT_DUNGEON_ID } },
          })
        : null
    const rushState = rushRun ? (rushRun.state as unknown as RushState | null) : null
    const rushRoom = rushState?.rooms?.[rushState.currentRoomIndex] ?? null
    if (opponentType === 'dungeon_rush') {
      if (!rushRun || !rushState || !Array.isArray(rushState.rooms)) {
        return NextResponse.json({ error: 'No active dungeon rush found' }, { status: 404 })
      }
      if (!rushRoom || !isCombatRoom(rushRoom.type) || rushRoom.resolved) {
        return NextResponse.json({ error: 'Current rush room is not an open combat room' }, { status: 409 })
      }
    }
    const rushEnemy = rushRoom && opponentType === 'dungeon_rush'
      ? generateRushEnemy(rushRoom.index, rushRoom.type, rushRoom.seed)
      : null

    // Pre-check HP + stamina (authoritative re-check happens inside transaction).
    // Dungeon boss fights skip the PvP stamina gate — dungeon entry already
    // consumed its own resource (staminaless per-floor fights preserve parity
    // with the classic /dungeons/run/:id/fight endpoint).
    const preHp = attacker.currentHp
    const minHp = Math.ceil(attacker.maxHp * 0.3)
    // Rush carries its own HP% between rooms — the character HP gate doesn't apply.
    const isRush = opponentType === 'dungeon_rush'
    if (!isRush && preHp < minHp) {
      return NextResponse.json(
        { error: 'Not enough health to fight. Use a health potion first!',
          currentHp: preHp, minHealthRequired: minHp, maxHp: attacker.maxHp },
        { status: 400 }
      )
    }
    const skipStaminaGate = opponentType === 'dungeon_boss' || isRush
    const preStamina = await calculateCurrentStamina(
      attacker.currentStamina, attacker.maxStamina,
      attacker.lastStaminaUpdate ?? new Date()
    )
    const freePvpAllowance = freePvpPerDay(attacker.user, STAMINA.FREE_PVP_PER_DAY)
    const preFreeUsed = isNewUtcDay(attacker.freePvpDate) ? 0 : attacker.freePvpToday
    const preHasFree = preFreeUsed < freePvpAllowance
    if (!skipStaminaGate && !preHasFree && preStamina.stamina < STAMINA.PVP_COST) {
      return NextResponse.json(
        { error: 'Not enough stamina', currentStamina: preStamina.stamina, required: STAMINA.PVP_COST },
        { status: 400 }
      )
    }

    await initCombatConfig()
    let attackerStats = await loadCombatCharacter(attacker.id)
    // Rush: buffs + artifacts change the hero's stats, and HP% carries over.
    let attackerMaxHp = attacker.maxHp
    let attackerStartHp = attacker.maxHp
    if (isRush && rushState) {
      const artifacts: RushArtifact[] = (rushState.artifacts ?? []).map(
        (a) => RUSH_ARTIFACTS.find((r) => r.id === a.id) ?? (a as RushArtifact),
      )
      attackerStats = applyArtifactStatBoosts(applyRushBuffs(attackerStats, rushState.buffs), artifacts)
      attackerMaxHp = attackerStats.maxHp
      attackerStartHp = effectiveHp(attackerMaxHp, rushState.currentHpPercent)
    }
    const defenderStats: CharacterStats =
      opponentType === 'pvp' && defender
        ? await loadCombatCharacter(defender.id)
        : opponentType === 'dungeon_boss' && dungeonBoss
          ? dungeonEnemyToCharacterStats(dungeonBoss)
          : isRush && rushEnemy
            ? dungeonEnemyToCharacterStats(rushEnemy)
            : generateBotCombatStats(opponent_id, attackerStats, attacker.pvpWins + attacker.pvpLosses)

    const now = new Date()
    const timeoutAt = new Date(now.getTime() + MATCH_TIMEOUT_MS)

    // Dice combat (DICE_RUNES_DESIGN.md) — snapshot both fighters' dice, runes
    // and per-strike hit at match start; the whole duel then runs on this
    // state. Active slots / consumables don't exist in dice combat.
    const DICE_CFG = await getDiceConfig()
    const matchId = randomUUID()
    const [hitP, hitO, loadoutP, loadoutO] = await Promise.all([
      diceHitProfile(attackerStats, defenderStats),
      diceHitProfile(defenderStats, attackerStats),
      loadDiceLoadout(attacker.id, attacker.class, attacker.level),
      opponentType === 'pvp' && defender
        ? loadDiceLoadout(defender.id, defender.class, defender.level)
        : opponentType === 'bot'
          ? Promise.resolve(botDiceLoadout(opponent_id, defenderStats.class, defenderStats.level))
          : Promise.resolve(emptyLoadout()),
    ])
    const diceState = createDiceState(
      {
        id: attacker.id, name: attacker.characterName, maxHp: attackerMaxHp, hp: attackerStartHp,
        hit: hitP.hit, lifesteal: hitP.lifesteal, agi: attackerStats.agi,
        atk: loadoutP.atk, grd: loadoutP.grd,
      },
      {
        id: defenderStats.id, name: defenderStats.name, maxHp: defenderStats.maxHp,
        hit: hitO.hit, lifesteal: hitO.lifesteal, agi: defenderStats.agi,
        atk: loadoutO.atk, grd: loadoutO.grd,
        boss: opponentType === 'dungeon_boss' || (isRush && rushRoom?.type === 'miniboss'),
      },
      DICE_CFG,
    )
    rollRound(diceState, createSeededRng(deriveCombatSeed(matchId, 1, 'roll')))
    const interactiveActives = { dice: diceState }

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
      if (!isRush && locked.current_hp < lockedMinHp) throw new Error('NOT_ENOUGH_HP')

      const lockedSt = await calculateCurrentStamina(
        locked.current_stamina, locked.max_stamina,
        locked.last_stamina_update ?? new Date()
      )
      const lockedFreeUsed = isNewUtcDay(locked.free_pvp_date) ? 0 : locked.free_pvp_today
      const lockedHasFree = lockedFreeUsed < freePvpAllowance
      // Dungeon boss fights don't consume PvP stamina / free-fight slot.
      const cost = skipStaminaGate ? 0 : lockedHasFree ? 0 : STAMINA.PVP_COST
      if (!skipStaminaGate && !lockedHasFree && lockedSt.stamina < STAMINA.PVP_COST) {
        throw new Error('NOT_ENOUGH_STAMINA')
      }
      const staminaAfter = lockedSt.stamina - cost

      const attackerUpdate: Record<string, unknown> = {
        currentStamina: staminaAfter,
        lastStaminaUpdate: now,
      }
      if (!skipStaminaGate && lockedHasFree) {
        attackerUpdate.freePvpToday = lockedFreeUsed + 1
        attackerUpdate.freePvpDate = now
      }
      await tx.character.update({ where: { id: attacker.id }, data: attackerUpdate })

      // Non-PvP opponents don't exist as DB rows — stash their combat stats on
      // the match so /strike + /complete can reload them without touching
      // Character. For PvP, player2Id keeps the FK (legacy path).
      const opponentSnapshot =
        opponentType !== 'pvp'
          ? {
              kind: opponentType,
              id: defenderStats.id,
              character_name: defenderStats.name,
              class: defenderStats.class,
              level: defenderStats.level,
              avatar: defenderStats.avatar ?? null,
              max_hp: defenderStats.maxHp,
              combat_stats: defenderStats,
              // Rush: pins the room this match was started for, so
              // /dungeon-rush/fight can refuse a match from a stale room.
              ...(isRush && rushRoom
                ? { rush_room: { index: rushRoom.index, seed: rushRoom.seed, type: rushRoom.type } }
                : {}),
            }
          : null

      const matchTypeForDb =
        opponentType === 'bot'
          ? 'bot'
          : opponentType === 'dungeon_boss' || opponentType === 'dungeon_rush'
            ? opponentType
            : 'ranked'

      const match = await tx.pvpMatch.create({
        data: {
          id: matchId,
          player1Id: attacker.id,
          player2Id: opponentType === 'pvp' && defender ? defender.id : null,
          player1RatingBefore: attacker.pvpRating,
          player1RatingAfter: attacker.pvpRating,   // updated on /complete
          player2RatingBefore: defender?.pvpRating ?? attacker.pvpRating,
          player2RatingAfter: defender?.pvpRating ?? attacker.pvpRating,
          winnerId: null,
          loserId: null,
          combatLog: [],
          turnsTaken: 0,
          goldReward: 0,
          xpReward: 0,
          matchType: matchTypeForDb,
          isRevenge: false,
          status: 'in_progress',
          interactiveStrikeIndex: 0,
          interactiveTimeoutAt: timeoutAt,
          interactiveChoices: [] as Prisma.JsonArray,
          interactiveActives: interactiveActives as unknown as Prisma.InputJsonValue,
          opponentType,
          opponentSnapshot: opponentSnapshot as unknown as Prisma.InputJsonValue,
          botKey: opponentType === 'bot' ? opponent_id : null,
          dungeonRunId: opponentType === 'dungeon_boss' || isRush ? (dungeon_run_id as string) : null,
          bossKey: opponentType === 'dungeon_boss' ? defenderStats.id : null,
        },
      })

      return { match, newStamina: staminaAfter }
    })

    // Interactive Combat is a discrete duel — both fighters enter at full HP.
    // Classic `/fight` used persisted currentHp but the UI never rendered it;
    // Interactive Combat shows the HP bar from round 0, so persisted damage
    // looks like "enemy HP dropped before first strike". Use maxHp for both.
    // The 30% HP gate on the attacker above still prevents near-death PvP.
    const startAttackerHp = attackerStartHp
    const startDefenderHp = defenderStats.maxHp

    const defenderPayload = opponentType === 'pvp' && defender
      ? {
          id: defender.id,
          character_name: defender.characterName,
          class: defender.class,
          origin: defender.origin,
          level: defender.level,
          avatar: defender.avatar,
          max_hp: defender.maxHp,
          current_hp: startDefenderHp,
        }
      : {
          id: opponent_id,
          character_name: defenderStats.name,
          class: defenderStats.class,
          origin: null as string | null, // bots don't carry origin in stats
          level: defenderStats.level,
          avatar: defenderStats.avatar,
          max_hp: defenderStats.maxHp,
          current_hp: startDefenderHp,
        }

    return NextResponse.json({
      match_id: match.id,
      max_rounds: MAX_ROUNDS,
      timeout_at: timeoutAt.toISOString(),
      opponent_type: opponentType,
      attacker: {
        id: attacker.id,
        character_name: attacker.characterName,
        class: attacker.class,
        origin: attacker.origin,
        level: attacker.level,
        avatar: attacker.avatar,
        max_hp: attackerMaxHp,
        current_hp: startAttackerHp,
      },
      defender: defenderPayload,
      stamina: { current: newStamina, max: attacker.maxStamina },
      // Dice combat replaced active slots; kept empty for older clients' decoders.
      actives: { p1: [], p2: [] },
      dice: publicView(diceState),
      rune_info: runeInfoFor(loadoutP, loadoutO),
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
