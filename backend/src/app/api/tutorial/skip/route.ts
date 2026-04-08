import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import {
  STARTER_WEAPON_BY_CLASS,
  WELCOME_GIFT,
  REFERRAL_BONUS,
  generateReferralCode,
} from '@/lib/game/tutorial'
import { logTutorialEvent } from '@/lib/game/tutorial-analytics'

/**
 * POST /api/tutorial/skip
 * Skip tutorial — gives welcome gift but marks tutorial as skipped.
 * Weapon is NOT auto-equipped (experienced player does it themselves).
 * Body: { character_id, referral_code? }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`tutorial-skip:${user.id}`, 5, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, referral_code } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      const [character] = await tx.$queryRawUnsafe<
        Array<{
          id: string
          user_id: string
          tutorial_step: number
          class: string
          current_stamina: number
          max_stamina: number
          prestige_level: number
        }>
      >(
        `SELECT id, user_id, tutorial_step, class, current_stamina, max_stamina, prestige_level
         FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')
      if (character.tutorial_step >= 3) throw new Error('ALREADY_COMPLETED')

      // Determine starter weapon
      const weaponCatalogId = STARTER_WEAPON_BY_CLASS[character.class] || 'wpn_rusty_sword'
      const item = await tx.item.findUnique({ where: { catalogId: weaponCatalogId } })
      if (!item) throw new Error('STARTER_ITEM_NOT_FOUND')

      // Handle referral
      let isReferred = false
      if (referral_code) {
        const referralRecord = await tx.character.findUnique({
          where: { referralCode: referral_code },
          select: { id: true },
        })
        if (referralRecord && referralRecord.id !== character_id) {
          await tx.character.update({
            where: { id: character_id },
            data: { referredBy: referralRecord.id },
          })
          isReferred = true
        }
      }

      const extraGold = isReferred ? REFERRAL_BONUS.extraGold : 0

      // Skip tutorial: step=3, skipped=true, give all gifts
      const updatedCharacter = await tx.character.update({
        where: { id: character_id },
        data: {
          tutorialStep: 3,
          tutorialSkipped: true,
          gold: { increment: extraGold },
          currentStamina: Math.min(
            character.current_stamina + WELCOME_GIFT.staminaBonus,
            character.max_stamina + WELCOME_GIFT.staminaBonus
          ),
          referralCode: generateReferralCode(),
        },
      })

      // Give weapon (NOT equipped)
      await tx.equipmentInventory.create({
        data: {
          characterId: character_id,
          itemId: item.id,
          upgradeLevel: 0,
          durability: 100,
          maxDurability: 100,
          isEquipped: false,
        },
      })

      // Give health potions
      await tx.consumableInventory.upsert({
        where: {
          characterId_consumableType: {
            characterId: character_id,
            consumableType: WELCOME_GIFT.healthPotionType,
          },
        },
        update: { quantity: { increment: WELCOME_GIFT.healthPotionCount } },
        create: {
          characterId: character_id,
          consumableType: WELCOME_GIFT.healthPotionType,
          quantity: WELCOME_GIFT.healthPotionCount,
        },
      })

      return { character: updatedCharacter, isReferred }
    })

    logTutorialEvent({
      event: 'tutorial_skipped',
      characterId: character_id,
      isReferred: result.isReferred,
    })

    return NextResponse.json({
      tutorialStep: 3,
      tutorialSkipped: true,
      isReferred: result.isReferred,
      gold: result.character.gold,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'ALREADY_COMPLETED') return NextResponse.json({ error: 'Tutorial already completed' }, { status: 409 })
    }
    console.error('tutorial skip error:', error)
    return NextResponse.json({ error: 'Failed to skip tutorial' }, { status: 500 })
  }
}
