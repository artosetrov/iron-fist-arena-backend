import { NextRequest, NextResponse } from 'next/server'
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

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    // User record is ensured at auth/login time — no need to upsert on every GET
    const characters = await prisma.character.findMany({
      where: { userId: user.id },
      orderBy: { createdAt: 'desc' },
    })

    // Apply HP + stamina regen so the list shows accurate values
    // (prevents stale "0 HP" display on character selection after a loss)
    const now = new Date()
    const enriched = await Promise.all(
      characters.map(async (char) => {
        const [hpResult, staminaResult] = await Promise.all([
          calculateCurrentHp(char.currentHp, char.maxHp, char.lastHpUpdate ?? now),
          calculateCurrentStamina(char.currentStamina, char.maxStamina, char.lastStaminaUpdate ?? now),
        ])

        // Persist regen updates to DB if changed
        const updates: Record<string, unknown> = {}
        if (hpResult.updated) {
          updates.currentHp = hpResult.hp
          updates.lastHpUpdate = now
        }
        if (staminaResult.updated) {
          updates.currentStamina = staminaResult.stamina
          updates.lastStaminaUpdate = now
        }
        if (Object.keys(updates).length > 0) {
          await prisma.character.update({ where: { id: char.id }, data: updates })
        }

        return {
          ...char,
          currentHp: hpResult.hp,
          currentStamina: staminaResult.stamina,
        }
      })
    )

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

    return NextResponse.json({ character }, { status: 201 })
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
