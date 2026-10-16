import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { CharacterOrigin, CharacterGender } from '@prisma/client'
import { ORIGIN_BONUSES, STAT_KEYS, calculateMaxHp } from '@/lib/game/creation-stats'

const APPEARANCE_CHANGE_COST = 100 // gold




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
      // Lock user row for update (gold balance)
      const [userRow] = await tx.$queryRawUnsafe<Array<{ id: string; gold: number; gems: number }>>(
        `SELECT id, gold, gems FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )

      if (!userRow) throw new Error('USER_NOT_FOUND')

      const [charRow] = await tx.$queryRawUnsafe<Array<{
        id: string; user_id: string; origin: string; gender: string; avatar: string;
        str: number; agi: number; vit: number; end: number; int: number; wis: number; luk: number; cha: number;
        current_hp: number;
      }>>(
        `SELECT id, user_id, origin, gender, avatar, str, agi, vit, "end", "int", wis, luk, cha, current_hp FROM characters WHERE id = $1 FOR UPDATE`,
        id
      )

      if (!charRow) throw new Error('NOT_FOUND')
      if (charRow.user_id !== user.id) throw new Error('FORBIDDEN')

      const newOrigin = origin || charRow.origin
      const newGender = gender || charRow.gender
      const newAvatar = avatar || charRow.avatar

      // Validate avatar against DB skin catalog (filtered by origin + gender)
      const availableSkins = await tx.appearanceSkin.findMany({
        where: {
          origin: newOrigin as CharacterOrigin,
          gender: newGender as CharacterGender,
        },
        select: { id: true, skinKey: true, isDefault: true, priceGold: true, priceGems: true },
        orderBy: { sortOrder: 'asc' },
      })
      const validKeys = availableSkins.map((s) => s.skinKey)

      if (avatar && validKeys.length > 0 && !validKeys.includes(newAvatar)) {
        throw new Error('INVALID_AVATAR')
      }
      // If gender changed but avatar didn't, auto-pick first valid avatar for new gender
      const finalAvatar = validKeys.includes(newAvatar)
        ? newAvatar
        : validKeys[0] ?? newAvatar

      const originChanged = newOrigin !== charRow.origin
      const avatarChanged = finalAvatar !== charRow.avatar

      // Skin pricing + ownership. The editor shows priceGold/priceGems from
      // the catalog, but the server never charged or checked them — every
      // premium skin was free (AUDIT-2026-10-13 H5). A non-default skin must
      // be owned (Cosmetic type=skin from Battle Pass / achievements, or a
      // previous purchase here) or paid for now, under the user row lock.
      let skinGoldCost = 0
      let skinGemCost = 0
      let purchasedSkinKey: string | null = null
      const targetSkin = avatarChanged ? availableSkins.find((sk) => sk.skinKey === finalAvatar) : undefined
      if (targetSkin && !targetSkin.isDefault && (targetSkin.priceGold > 0 || targetSkin.priceGems > 0)) {
        const owned = await tx.cosmetic.findFirst({
          where: { userId: user.id, type: 'skin', refId: { in: [targetSkin.skinKey, targetSkin.id] } },
          select: { id: true },
        })
        if (!owned) {
          skinGoldCost = targetSkin.priceGold
          skinGemCost = targetSkin.priceGems
          purchasedSkinKey = targetSkin.skinKey
        }
      }

      const totalGoldCost = (originChanged ? APPEARANCE_CHANGE_COST : 0) + skinGoldCost
      if (userRow.gold < totalGoldCost) throw new Error('NOT_ENOUGH_GOLD')
      if (userRow.gems < skinGemCost) throw new Error('NOT_ENOUGH_GEMS')

      // Recalculate stats only if origin changed
      const data: Record<string, unknown> = {
        origin: newOrigin as CharacterOrigin,
        gender: newGender as CharacterGender,
        avatar: finalAvatar,
      }

      if (originChanged) {
        const oldBonuses: Record<string, number> = ORIGIN_BONUSES[charRow.origin as keyof typeof ORIGIN_BONUSES] || {}
        const newBonuses: Record<string, number> = ORIGIN_BONUSES[newOrigin as keyof typeof ORIGIN_BONUSES] || {}

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
        })
      }

      // Charge once for everything (gold lives on users, not characters).
      if (totalGoldCost > 0 || skinGemCost > 0) {
        await tx.user.update({
          where: { id: user.id },
          data: {
            ...(totalGoldCost > 0 ? { gold: { decrement: totalGoldCost } } : {}),
            ...(skinGemCost > 0 ? { gems: { decrement: skinGemCost } } : {}),
          },
        })
      }
      if (purchasedSkinKey) {
        await tx.cosmetic.create({
          data: { userId: user.id, type: 'skin', refId: purchasedSkinKey },
        })
      }

      const character = await tx.character.update({ where: { id }, data })
      const gold = userRow.gold - totalGoldCost
      const gems = userRow.gems - skinGemCost
      return { character, gold, gems, purchasedSkinKey }
    })

    return NextResponse.json({
      // Compatibility alias: current clients still decode `character.gold`.
      character: { ...updated.character, gold: updated.gold, gems: updated.gems },
      // Compatibility alias for older lightweight callers.
      gold: updated.gold,
      gems: updated.gems,
      // Canonical wallet boundary for newer callers.
      wallet: { gold: updated.gold, gems: updated.gems },
      purchasedSkin: updated.purchasedSkinKey,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold for this change' }, { status: 400 })
      if (error.message === 'NOT_ENOUGH_GEMS') return NextResponse.json({ error: 'Not enough gems for this skin' }, { status: 400 })
      if (error.message === 'INVALID_AVATAR') return NextResponse.json({ error: 'Avatar does not match selected gender' }, { status: 400 })
    }
    console.error('appearance change error:', error)
    return NextResponse.json({ error: 'Failed to change appearance' }, { status: 500 })
  }
}
