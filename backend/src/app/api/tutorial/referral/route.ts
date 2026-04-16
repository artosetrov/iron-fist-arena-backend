import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import {
  REFERRAL_BONUS,
  generateReferralCode,
  getReferralLinkValues,
  isReferralCodeLike,
  normalizeReferralCode,
} from '@/lib/game/tutorial'
import { logTutorialEvent } from '@/lib/game/tutorial-analytics'

/**
 * GET /api/tutorial/referral?character_id=xxx
 * Returns the character's referral code + stats (how many invited, rewards earned).
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const characterId = req.nextUrl.searchParams.get('character_id')
  if (!characterId) {
    return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
  }

  try {
    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: {
        id: true,
        userId: true,
        referralCode: true,
        referredBy: true,
      },
    })

    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    // Generate referral code if doesn't exist yet
    let referralCode = character.referralCode
    if (!referralCode) {
      referralCode = generateReferralCode()
      await prisma.character.update({
        where: { id: characterId },
        data: { referralCode },
      })
    }

    const referralKeys = getReferralLinkValues(character.id, referralCode)
    const linkedReferrer = character.referredBy
      ? await prisma.character.findFirst({
          where: {
            OR: [
              { id: character.referredBy },
              { referralCode: normalizeReferralCode(character.referredBy) },
            ],
          },
          select: {
            id: true,
            referralCode: true,
          },
        })
      : null

    const referredByCharacterId = linkedReferrer?.id ?? null
    const referredByCode = linkedReferrer?.referralCode
      ?? (character.referredBy && isReferralCodeLike(character.referredBy)
        ? normalizeReferralCode(character.referredBy)
        : null)

    // Count how many people used this code
    const referralCount = await prisma.character.count({
      where: {
        referredBy: { in: referralKeys },
      },
    })

    // Count how many reached level threshold (referrer got rewarded)
    const qualifiedCount = await prisma.character.count({
      where: {
        referredBy: { in: referralKeys },
        level: { gte: REFERRAL_BONUS.inviteeLevelThreshold },
      },
    })

    return NextResponse.json({
      referralCode,
      referredBy: referredByCode ?? character.referredBy ?? null,
      referredByCode,
      referredByCharacterId,
      referralCount,
      qualifiedCount,
      maxReferrals: REFERRAL_BONUS.maxReferrals,
      referrerReward: {
        gold: REFERRAL_BONUS.referrerGold,
        gems: REFERRAL_BONUS.referrerGems,
      },
    })
  } catch (error) {
    console.error('GET /tutorial/referral error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

/**
 * POST /api/tutorial/referral
 * Apply a referral code to an existing character (if they didn't enter one at creation).
 * Body: { character_id, referral_code }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`tutorial_referral:${user.id}`, 5, 60_000))) {
    return NextResponse.json({ error: 'Rate limited' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, referral_code } = body

    if (!character_id || !referral_code) {
      return NextResponse.json(
        { error: 'character_id and referral_code are required' },
        { status: 400 },
      )
    }

    const code = normalizeReferralCode(referral_code as string)

    const result = await prisma.$transaction(async (tx) => {
      const [character] = await tx.$queryRawUnsafe<
        Array<{
          id: string
          user_id: string
          referred_by: string | null
          referral_code: string | null
        }>
      >(
        `SELECT id, user_id, referred_by, referral_code
         FROM characters
         WHERE id = $1
         FOR UPDATE`,
        character_id,
      )

      if (!character || character.user_id !== user.id) {
        throw new Error('CHARACTER_NOT_FOUND')
      }

      if (character.referred_by) {
        throw new Error('ALREADY_REFERRED')
      }

      if (character.referral_code && normalizeReferralCode(character.referral_code) === code) {
        throw new Error('OWN_CODE')
      }

      const [referrer] = await tx.$queryRawUnsafe<
        Array<{ id: string; referral_code: string }>
      >(
        `SELECT id, referral_code
         FROM characters
         WHERE referral_code = $1
         FOR UPDATE`,
        code,
      )

      if (!referrer) {
        throw new Error('INVALID_CODE')
      }

      if (referrer.id === character_id) {
        throw new Error('OWN_CODE')
      }

      const referralCount = await tx.character.count({
        where: {
          referredBy: {
            in: getReferralLinkValues(referrer.id, referrer.referral_code),
          },
        },
      })

      if (referralCount >= REFERRAL_BONUS.maxReferrals) {
        throw new Error('MAX_REFERRALS_REACHED')
      }

      await tx.character.update({
        where: { id: character_id },
        data: { referredBy: referrer.id },
      })
      await tx.user.update({
        where: { id: user.id },
        data: { gold: { increment: REFERRAL_BONUS.extraGold } },
      })

      return {
        referrerId: referrer.id,
        referrerCode: referrer.referral_code,
      }
    })

    logTutorialEvent({
      event: 'referral_applied',
      characterId: character_id,
      referrerCode: code,
      bonusGold: REFERRAL_BONUS.extraGold,
    })

    return NextResponse.json({
      success: true,
      bonusGold: REFERRAL_BONUS.extraGold,
      referredBy: result.referrerCode,
      referredByCode: result.referrerCode,
      referredByCharacterId: result.referrerId,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'CHARACTER_NOT_FOUND') {
        return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      }
      if (error.message === 'ALREADY_REFERRED') {
        return NextResponse.json(
          { error: 'Already referred', alreadyReferred: true },
          { status: 400 },
        )
      }
      if (error.message === 'OWN_CODE') {
        return NextResponse.json(
          { error: 'Cannot use your own referral code' },
          { status: 400 },
        )
      }
      if (error.message === 'INVALID_CODE') {
        return NextResponse.json(
          { error: 'Invalid referral code', invalidCode: true },
          { status: 400 },
        )
      }
      if (error.message === 'MAX_REFERRALS_REACHED') {
        return NextResponse.json(
          { error: 'Referral code has reached maximum uses' },
          { status: 400 },
        )
      }
    }
    console.error('POST /tutorial/referral error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
