import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { loadCombatCharacter } from '@/lib/game/combat-loader'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import {
  getStaminaConfig,
  getCombatConfig,
  getGoldRewardsConfig,
  getXpRewardsConfig,
} from '@/lib/game/live-config'
import { STANCE_ZONES } from '@/lib/game/balance'

const BATTLE_TICKET_TTL_MS = 5 * 60_000

/**
 * POST /api/pvp/prepare
 * Body: { character_id, opponent_id } OR { character_id, revenge_id }
 *
 * Returns everything the client needs to simulate combat locally:
 * - player_stats (full combat stats)
 * - enemy_stats (full combat stats)
 * - battle_seed (deterministic seed for client-side simulation)
 * - balance constants (for client combat engine)
 * - stamina validation (reject early if insufficient)
 *
 * Does NOT run combat or update any state — that happens in /api/pvp/resolve.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`pvp-prepare:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const [STAMINA, COMBAT] = await Promise.all([
      getStaminaConfig(),
      getCombatConfig(),
    ])

    const body = await req.json()
    const { character_id, opponent_id, revenge_id } = body

    if (!character_id || (!opponent_id && !revenge_id)) {
      return NextResponse.json(
        { error: 'character_id and opponent_id (or revenge_id) are required' },
        { status: 400 }
      )
    }

    // Resolve opponent from revenge entry if revenge_id provided
    let resolvedOpponentId = opponent_id
    let isRevenge = false

    if (revenge_id) {
      const revenge = await prisma.revengeQueue.findUnique({ where: { id: revenge_id } })
      if (!revenge) return NextResponse.json({ error: 'Revenge entry not found' }, { status: 404 })
      if (revenge.victimId !== character_id) return NextResponse.json({ error: 'This revenge does not belong to your character' }, { status: 403 })
      if (revenge.isUsed) return NextResponse.json({ error: 'Revenge has already been used' }, { status: 400 })
      if (new Date() > revenge.expiresAt) return NextResponse.json({ error: 'Revenge has expired' }, { status: 400 })
      resolvedOpponentId = revenge.attackerId
      isRevenge = true
    }

    if (character_id === resolvedOpponentId) {
      return NextResponse.json(
        { error: 'Cannot fight yourself' },
        { status: 400 }
      )
    }

    // Validate ownership + stamina in a single query
    const attacker = await prisma.character.findUnique({
      where: { id: character_id },
      select: {
        id: true,
        userId: true,
        currentStamina: true,
        maxStamina: true,
        lastStaminaUpdate: true,
        freePvpToday: true,
        freePvpDate: true,
        pvpRating: true,
        pvpCalibrationGames: true,
        firstWinToday: true,
        firstWinDate: true,
        level: true,
        cha: true,
        luk: true,
      },
    })

    if (!attacker) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (attacker.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Stamina check — revenge always costs stamina (no free PvP)
    const staminaResult = await calculateCurrentStamina(
      attacker.currentStamina,
      attacker.maxStamina,
      attacker.lastStaminaUpdate ?? new Date()
    )
    const currentStamina = staminaResult.stamina

    const isNewDay = !attacker.freePvpDate || isNewUtcDay(attacker.freePvpDate)
    const freePvpUsed = isNewDay ? 0 : attacker.freePvpToday
    const hasFreePvp = isRevenge ? false : freePvpUsed < STAMINA.FREE_PVP_PER_DAY

    if (!hasFreePvp && currentStamina < STAMINA.PVP_COST) {
      return NextResponse.json(
        { error: 'Not enough stamina', currentStamina, required: STAMINA.PVP_COST },
        { status: 400 }
      )
    }

    // Load both combat characters in parallel
    const [playerStats, enemyStats] = await Promise.all([
      loadCombatCharacter(character_id),
      loadCombatCharacter(resolvedOpponentId),
    ])

    // Generate a server-issued battle ticket so /resolve cannot be replayed or forged.
    const battleSeed = (Math.random() * 0x7FFFFFFF) | 0
    const battleTicket = await prisma.pvpBattleTicket.create({
      data: {
        characterId: character_id,
        opponentId: resolvedOpponentId,
        revengeId: revenge_id ?? null,
        battleSeed,
        expiresAt: new Date(Date.now() + BATTLE_TICKET_TTL_MS),
      },
    })

    // Serialize skills for client
    const serializeSkills = (stats: typeof playerStats) =>
      (stats.equippedSkills ?? []).map(s => ({
        id: s.id,
        skill_key: s.skillKey,
        name: s.name,
        damage_base: s.damageBase,
        damage_scaling: s.damageScaling,
        damage_type: s.damageType,
        target_type: s.targetType,
        cooldown: s.cooldown,
        effect_json: s.effectJson,
        rank: s.rank,
        rank_scaling: s.rankScaling,
      }))

    const serializePassives = (stats: typeof playerStats) => ({
      flat_damage: stats.passiveBonuses?.flatDamage ?? 0,
      percent_damage: stats.passiveBonuses?.percentDamage ?? 0,
      flat_crit_chance: stats.passiveBonuses?.flatCritChance ?? 0,
      flat_dodge_chance: stats.passiveBonuses?.flatDodgeChance ?? 0,
      lifesteal: stats.passiveBonuses?.lifesteal ?? 0,
      damage_reduction: stats.passiveBonuses?.damageReduction ?? 0,
      flat_hp: stats.passiveBonuses?.flatHp ?? 0,
      flat_armor: stats.passiveBonuses?.flatArmor ?? 0,
      flat_magic_resist: stats.passiveBonuses?.flatMagicResist ?? 0,
      percent_hp: stats.passiveBonuses?.percentHp ?? 0,
      percent_armor: stats.passiveBonuses?.percentArmor ?? 0,
      percent_magic_resist: stats.passiveBonuses?.percentMagicResist ?? 0,
    })

    return NextResponse.json({
      battle_ticket_id: battleTicket.id,
      battle_seed: battleSeed,
      player_stats: {
        id: playerStats.id,
        name: playerStats.name,
        class: playerStats.class,
        level: playerStats.level,
        avatar: playerStats.avatar,
        str: playerStats.str,
        agi: playerStats.agi,
        vit: playerStats.vit,
        end: playerStats.end,
        int: playerStats.int,
        wis: playerStats.wis,
        luk: playerStats.luk,
        cha: playerStats.cha,
        max_hp: playerStats.maxHp,
        armor: playerStats.armor,
        magic_resist: playerStats.magicResist,
        combat_stance: playerStats.combatStance,
        equipped_skills: serializeSkills(playerStats),
        passive_bonuses: serializePassives(playerStats),
      },
      enemy_stats: {
        id: enemyStats.id,
        name: enemyStats.name,
        class: enemyStats.class,
        level: enemyStats.level,
        avatar: enemyStats.avatar,
        str: enemyStats.str,
        agi: enemyStats.agi,
        vit: enemyStats.vit,
        end: enemyStats.end,
        int: enemyStats.int,
        wis: enemyStats.wis,
        luk: enemyStats.luk,
        cha: enemyStats.cha,
        max_hp: enemyStats.maxHp,
        armor: enemyStats.armor,
        magic_resist: enemyStats.magicResist,
        combat_stance: enemyStats.combatStance,
        equipped_skills: serializeSkills(enemyStats),
        passive_bonuses: serializePassives(enemyStats),
      },
      combat_config: {
        max_turns: COMBAT.MAX_TURNS,
        min_damage: COMBAT.MIN_DAMAGE,
        crit_multiplier: COMBAT.CRIT_MULTIPLIER,
        max_crit_chance: COMBAT.MAX_CRIT_CHANCE,
        max_dodge_chance: COMBAT.MAX_DODGE_CHANCE,
        rogue_dodge_bonus: COMBAT.ROGUE_DODGE_BONUS,
        tank_damage_reduction: COMBAT.TANK_DAMAGE_REDUCTION,
        damage_variance: COMBAT.DAMAGE_VARIANCE,
        poison_armor_penetration: COMBAT.POISON_ARMOR_PENETRATION,
        crit_per_luk: COMBAT.CRIT_PER_LUK,
        crit_per_agi: COMBAT.CRIT_PER_AGI,
        dodge_per_agi: COMBAT.DODGE_PER_AGI,
        dodge_per_luk: COMBAT.DODGE_PER_LUK,
        cha_intimidation_per_point: COMBAT.CHA_INTIMIDATION_PER_POINT,
        cha_intimidation_cap: COMBAT.CHA_INTIMIDATION_CAP,
        // Zone stance constants
        stance_attack_zones: STANCE_ZONES.ATTACK_ZONE,
        stance_defense_zones: STANCE_ZONES.DEFENSE_ZONE,
        stance_mismatch_offense_bonus: STANCE_ZONES.MISMATCH_OFFENSE_BONUS,
        stance_match_defense_bonus: STANCE_ZONES.MATCH_DEFENSE_BONUS,
      },
      stamina: {
        current: currentStamina,
        cost: hasFreePvp ? 0 : STAMINA.PVP_COST,
        has_free_pvp: hasFreePvp,
        free_pvp_remaining: STAMINA.FREE_PVP_PER_DAY - freePvpUsed,
      },
      is_revenge: isRevenge,
      ...(revenge_id ? { revenge_id } : {}),
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    const stack = error instanceof Error ? error.stack : undefined
    console.error('pvp prepare error:', message, stack)
    return NextResponse.json(
      { error: `Failed to prepare battle: ${message}` },
      { status: 500 }
    )
  }
}

function isNewUtcDay(date: Date | null): boolean {
  if (!date) return true
  const today = new Date()
  today.setUTCHours(0, 0, 0, 0)
  const d = new Date(date)
  d.setUTCHours(0, 0, 0, 0)
  return d.getTime() < today.getTime()
}
