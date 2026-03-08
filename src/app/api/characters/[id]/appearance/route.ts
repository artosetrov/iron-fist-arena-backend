import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { CharacterOrigin, CharacterGender } from '@prisma/client'

const APPEARANCE_CHANGE_COST = 100 // gold

const VALID_AVATARS_MALE = ['warlord', 'knight', 'barbarian', 'shadow']
const VALID_AVATARS_FEMALE = ['valkyrie', 'sorceress', 'enchantress', 'huntress']

const ORIGIN_BONUSES: Record<string, Partial<Record<string, number>>> = {
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

export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { id } = await params
    const { origin, gender, avatar } = await req.json()

    if (!origin && !gender && !avatar) {
      return NextResponse.json(
        { error: 'At least one of origin, gender, or avatar is required' },
        { status: 400 }
      )
    }

    if (origin && !Object.values(CharacterOrigin).includes(origin)) {
      return NextResponse.json(
        { error: `Invalid origin. Must be one of: ${Object.values(CharacterOrigin).join(', ')}` },
        { status: 400 }
      )
    }

    if (gender && !Object.values(CharacterGender).includes(gender)) {
      return NextResponse.json(
        { error: `Invalid gender. Must be one of: ${Object.values(CharacterGender).join(', ')}` },
        { status: 400 }
      )
    }

    const updated = await prisma.$transaction(async (tx) => {
      const [charRow] = await tx.$queryRawUnsafe<Array<{
        id: string; user_id: string; gold: number; origin: string; gender: string; avatar: string;
        str: number; agi: number; vit: number; end: number; int: number; wis: number; luk: number; cha: number;
        current_hp: number;
      }>>(
        `SELECT id, user_id, gold, origin, gender, avatar, str, agi, vit, "end", "int", wis, luk, cha, current_hp FROM characters WHERE id = $1 FOR UPDATE`,
        id
      )

      if (!charRow) throw new Error('NOT_FOUND')
      if (charRow.user_id !== user.id) throw new Error('FORBIDDEN')

      const newOrigin = origin || charRow.origin
      const newGender = gender || charRow.gender
      const newAvatar = avatar || charRow.avatar

      // Validate avatar matches gender
      const validAvatars = newGender === 'female' ? VALID_AVATARS_FEMALE : VALID_AVATARS_MALE
      if (avatar && !validAvatars.includes(newAvatar)) {
        throw new Error('INVALID_AVATAR')
      }
      // If gender changed but avatar didn't, auto-pick first valid avatar for new gender
      const finalAvatar = validAvatars.includes(newAvatar) ? newAvatar : validAvatars[0]

      const originChanged = newOrigin !== charRow.origin
      if (originChanged && charRow.gold < APPEARANCE_CHANGE_COST) {
        throw new Error('NOT_ENOUGH_GOLD')
      }

      // Recalculate stats only if origin changed
      const data: Record<string, unknown> = {
        origin: newOrigin as CharacterOrigin,
        gender: newGender as CharacterGender,
        avatar: finalAvatar,
      }

      if (originChanged) {
        const oldBonuses = ORIGIN_BONUSES[charRow.origin] || {}
        const newBonuses = ORIGIN_BONUSES[newOrigin] || {}

        const newStats: Record<string, number> = {}
        for (const key of STAT_KEYS) {
          newStats[key] = charRow[key] - (oldBonuses[key] ?? 0) + (newBonuses[key] ?? 0)
        }

        const maxHp = calculateMaxHp(newStats.vit, newStats.end)

        Object.assign(data, {
          str: newStats.str,
          agi: newStats.agi,
          vit: newStats.vit,
          end: newStats.end,
          int: newStats.int,
          wis: newStats.wis,
          luk: newStats.luk,
          cha: newStats.cha,
          maxHp,
          currentHp: Math.min(charRow.current_hp, maxHp),
          gold: { decrement: APPEARANCE_CHANGE_COST },
        })
      }

      return tx.character.update({ where: { id }, data })
    })

    return NextResponse.json({ character: updated })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold (100 required to change race)' }, { status: 400 })
      if (error.message === 'INVALID_AVATAR') return NextResponse.json({ error: 'Avatar does not match selected gender' }, { status: 400 })
    }
    console.error('appearance change error:', error)
    return NextResponse.json({ error: 'Failed to change appearance' }, { status: 500 })
  }
}
