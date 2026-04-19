import { NextRequest, NextResponse } from 'next/server'
import { Prisma } from '@prisma/client'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { CharacterClass, CharacterOrigin, CharacterGender } from '@prisma/client'
import { calculateCurrentHp } from '@/lib/game/hp-regen'
import { calculateCurrentStamina } from '@/lib/game/stamina'

// Avatar validation is done against the appearance_skins DB table at runtime

const ORIGIN_BONUSES: Record<CharacterOrigin, Partial<Record<string, number>>> = {
  human:    { cha: 2, wis: 1 },
  orc:      { str: 3, int: -1 },
  skeleton: { end: 2, agi: 1 },
  demon:    { int: 2, wis: 2, cha: -1 },
  dogfolk:  { agi: 2, luk: 1 },
}

const STAT_KEYS = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha'] as const

function calculateMaxHp(vit: number, end: number): number {
  return 80 + vit * 5 + end * 3
}

type CharacterListRow = {
  id: string
  userId: string
  characterName: string
  class: string
  origin: string
  gender: string | null
  avatar: string | null
  level: number
  currentXp: number
  prestigeLevel: number
  statPointsAvailable: number
  passivePointsAvailable: number
  str: number
  agi: number
  vit: number
  end: number
  int: number
  wis: number
  luk: number
  cha: number
  maxHp: number
  currentHp: number
  armor: number
  magicResist: number
  combatStance: Prisma.JsonValue | null
  currentStamina: number
  maxStamina: number
  lastStaminaUpdate: Date | null
  lastHpUpdate: Date | null
  pvpRating: number
  pvpWins: number
  pvpLosses: number
  pvpWinStreak: number
  pvpLossStreak: number
  firstWinToday: boolean
  freePvpToday: number
  inventorySlots: number
  createdAt: Date
  gearScore: number
}

async function fetchCharacterRows(userId: string): Promise<CharacterListRow[]> {
  try {
    return await prisma.character.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        userId: true,
        characterName: true,
        class: true,
        origin: true,
        gender: true,
        avatar: true,
        level: true,
        currentXp: true,
        prestigeLevel: true,
        statPointsAvailable: true,
        passivePointsAvailable: true,
        str: true,
        agi: true,
        vit: true,
        end: true,
        int: true,
        wis: true,
        luk: true,
        cha: true,
        maxHp: true,
        currentHp: true,
        armor: true,
        magicResist: true,
        combatStance: true,
        currentStamina: true,
        maxStamina: true,
        lastStaminaUpdate: true,
        lastHpUpdate: true,
        pvpRating: true,
        pvpWins: true,
        pvpLosses: true,
        pvpWinStreak: true,
        pvpLossStreak: true,
        firstWinToday: true,
        freePvpToday: true,
        inventorySlots: true,
        createdAt: true,
        gearScore: true,
      },
    }) as CharacterListRow[]
  } catch (error) {
    console.warn('list characters prisma read warning, retrying with raw SQL:', error)
  }

  return prisma.$queryRaw<CharacterListRow[]>`
    SELECT
      c.id,
      c.user_id AS "userId",
      c.character_name AS "characterName",
      c.class::text AS "class",
      c.origin::text AS "origin",
      c.gender::text AS "gender",
      c.avatar,
      c.level,
      c.current_xp AS "currentXp",
      c.prestige_level AS "prestigeLevel",
      c.stat_points_available AS "statPointsAvailable",
      c.passive_points_available AS "passivePointsAvailable",
      c.str,
      c.agi,
      c.vit,
      c."end" AS "end",
      c."int" AS "int",
      c.wis,
      c.luk,
      c.cha,
      c.max_hp AS "maxHp",
      c.current_hp AS "currentHp",
      c.armor,
      c.magic_resist AS "magicResist",
      c.combat_stance AS "combatStance",
      c.current_stamina AS "currentStamina",
      c.max_stamina AS "maxStamina",
      c.last_stamina_update AS "lastStaminaUpdate",
      c.last_hp_update AS "lastHpUpdate",
      c.pvp_rating AS "pvpRating",
      c.pvp_wins AS "pvpWins",
      c.pvp_losses AS "pvpLosses",
      c.pvp_win_streak AS "pvpWinStreak",
      c.pvp_loss_streak AS "pvpLossStreak",
      c.first_win_today AS "firstWinToday",
      c.free_pvp_today AS "freePvpToday",
      c.inventory_slots AS "inventorySlots",
      c.created_at AS "createdAt",
      c.gear_score AS "gearScore"
    FROM characters c
    WHERE c.user_id = ${userId}
    ORDER BY c.created_at DESC
  `
}

function normalizeCharacterRow(row: CharacterListRow): CharacterListRow {
  return {
    ...row,
    class: Object.values(CharacterClass).includes(row.class as CharacterClass) ? row.class : CharacterClass.warrior,
    origin: Object.values(CharacterOrigin).includes(row.origin as CharacterOrigin) ? row.origin : CharacterOrigin.human,
    gender: row.gender && Object.values(CharacterGender).includes(row.gender as CharacterGender)
      ? row.gender
      : CharacterGender.male,
  }
}

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    // Character list is required. Account wallet is only compatibility sugar
    // for older iOS DTOs, so do not fail the whole screen if it cannot load.
    const characters = (await fetchCharacterRows(user.id)).map(normalizeCharacterRow)

    let accountGold = 0
    let accountGems = 0
    try {
      const userAccount = await prisma.user.findUnique({
        where: { id: user.id },
        select: { gold: true, gems: true },
      })
      accountGold = userAccount?.gold ?? 0
      accountGems = userAccount?.gems ?? 0
    } catch (error) {
      console.warn('list characters wallet warning:', error)
    }

    // Apply HP + stamina regen so the list shows accurate values
    // (prevents stale "0 HP" display on character selection after a loss)
    const now = new Date()
    const enrichedResults = await Promise.allSettled(
      characters.map(async (char) => {
        let currentHp = char.currentHp
        let currentStamina = char.currentStamina
        const updates: Record<string, unknown> = {}

        try {
          const [hpResult, staminaResult] = await Promise.all([
            calculateCurrentHp(char.currentHp, char.maxHp, char.lastHpUpdate ?? now),
            calculateCurrentStamina(char.currentStamina, char.maxStamina, char.lastStaminaUpdate ?? now),
          ])

          currentHp = hpResult.hp
          currentStamina = staminaResult.stamina

          if (hpResult.updated) {
            updates.currentHp = hpResult.hp
            updates.lastHpUpdate = now
          }
          if (staminaResult.updated) {
            updates.currentStamina = staminaResult.stamina
            updates.lastStaminaUpdate = now
          }
        } catch (error) {
          console.warn(`list characters regen warning for ${char.id}:`, error)
        }

        if (Object.keys(updates).length > 0) {
          try {
            await prisma.character.update({ where: { id: char.id }, data: updates })
          } catch (error) {
            console.warn(`list characters regen persist warning for ${char.id}:`, error)
          }
        }

        return {
          ...char,
          currentHp,
          currentStamina,
          gold: accountGold,
          gems: accountGems,
        }
      }),
    )

    const enriched = enrichedResults.map((result, index) => {
      if (result.status === 'fulfilled') return result.value

      const char = characters[index]
      console.warn(`list characters enrich fallback for ${char.id}:`, result.reason)
      return {
        ...char,
        gold: accountGold,
        gems: accountGems,
      }
    })

    return NextResponse.json({ characters: enriched })
  } catch (error) {
    console.error('list characters error:', error)
    return NextResponse.json(
      { error: 'Failed to list characters' },
      { status: 500 }
    )
  }
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_name, class: charClass, origin, gender, avatar } = body

    if (!character_name || !charClass || !origin) {
      return NextResponse.json(
        { error: 'character_name, class, and origin are required' },
        { status: 400 }
      )
    }

    if (typeof character_name !== 'string' || character_name.length < 3 || character_name.length > 16) {
      return NextResponse.json(
        { error: 'Character name must be between 3 and 16 characters' },
        { status: 400 }
      )
    }

    if (!/^[a-zA-Z0-9]+$/.test(character_name)) {
      return NextResponse.json(
        { error: 'Character name must contain only letters and numbers' },
        { status: 400 }
      )
    }

    if (!Object.values(CharacterClass).includes(charClass)) {
      return NextResponse.json(
        { error: `Invalid class. Must be one of: ${Object.values(CharacterClass).join(', ')}` },
        { status: 400 }
      )
    }

    if (!Object.values(CharacterOrigin).includes(origin)) {
      return NextResponse.json(
        { error: `Invalid origin. Must be one of: ${Object.values(CharacterOrigin).join(', ')}` },
        { status: 400 }
      )
    }

    // Gender validation (optional for backwards compatibility, defaults to male)
    const charGender: CharacterGender = gender && Object.values(CharacterGender).includes(gender)
      ? gender as CharacterGender
      : CharacterGender.male

    // Avatar validation — check against appearance_skins table
    let charAvatar: string | null = null
    if (avatar) {
      const skin = await prisma.appearanceSkin.findUnique({
        where: { skinKey: avatar },
        select: { skinKey: true, origin: true, gender: true },
      })
      if (skin && skin.origin === origin && skin.gender === charGender) {
        charAvatar = skin.skinKey
      }
    }
    // Fallback: pick the first default skin for this origin + gender
    if (!charAvatar) {
      const fallback = await prisma.appearanceSkin.findFirst({
        where: { origin: origin as CharacterOrigin, gender: charGender, isDefault: true },
        select: { skinKey: true },
        orderBy: { sortOrder: 'asc' },
      })
      charAvatar = fallback?.skinKey ?? avatar ?? null
    }

    // Ensure user record exists in our database (handles users created
    // via Supabase Auth before we had prisma.user.create in auth routes)
    await prisma.user.upsert({
      where: { id: user.id },
      update: { lastLogin: new Date() },
      create: {
        id: user.id,
        email: user.email ?? null,
        username: user.email?.split('@')[0] ?? 'player',
        authProvider: 'email',
      },
    })

    // Enforce maximum character limit per user
    const existingCount = await prisma.character.count({
      where: { userId: user.id },
    })
    if (existingCount >= 5) {
      return NextResponse.json(
        { error: 'Maximum characters reached (5)' },
        { status: 400 }
      )
    }

    const bonuses = ORIGIN_BONUSES[origin as CharacterOrigin]
    const baseStatValue = 10

    const stats: Record<string, number> = {}
    for (const key of STAT_KEYS) {
      stats[key] = baseStatValue + (bonuses[key] ?? 0)
    }

    const maxHp = calculateMaxHp(stats.vit, stats.end)

    const character = await prisma.character.create({
      data: {
        userId: user.id,
        characterName: character_name,
        class: charClass as CharacterClass,
        origin: origin as CharacterOrigin,
        gender: charGender,
        avatar: charAvatar ?? undefined,
        str: stats.str,
        agi: stats.agi,
        vit: stats.vit,
        end: stats.end,
        int: stats.int,
        wis: stats.wis,
        luk: stats.luk,
        cha: stats.cha,
        maxHp,
        currentHp: maxHp,
        statPointsAvailable: 5,
      },
    })

    // Attach account-level gold/gems for iOS compatibility
    const userWallet = await prisma.user.findUnique({
      where: { id: user.id },
      select: { gold: true, gems: true },
    })

    return NextResponse.json({
      character: { ...character, gold: userWallet?.gold ?? 0, gems: userWallet?.gems ?? 0 },
    }, { status: 201 })
  } catch (error: unknown) {
    console.error('create character error:', error)

    if (
      error instanceof Error &&
      'code' in error &&
      (error as { code: string }).code === 'P2002'
    ) {
      return NextResponse.json(
        { error: 'Character name already taken' },
        { status: 409 }
      )
    }

    return NextResponse.json(
      { error: 'Failed to create character' },
      { status: 500 }
    )
  }
}
