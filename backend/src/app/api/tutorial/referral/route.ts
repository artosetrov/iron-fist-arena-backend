import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import {
  REFERRAL_BONUS,
  generateReferralCode,
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

    // Count how many people used this code
    const referralCount = await prisma.character.count({
      where: { referredBy: referralCode },
    })

    // Count how many reached level threshold (referrer got rewarded)
    const qualifiedCount = await prisma.character.count({
      where: {
        referredBy: referralCode,
        level: { gte: REFERRAL_BONUS.inviteeLevelThreshold },
      },
    })

    return NextResponse.json({
      referralCode,
      referredBy: character.referredBy ?? null,
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

  const limited = await rateLimit(user.id, 'tutorial_referral', 5, 60)
  if (limited) return NextResponse.json({ error: 'Rate limited' }, { status: 429 })

  try {
    const body = await req.json()
    const { character_id, referral_code } = body

    if (!character_id || !referral_code) {
      return NextResponse.json(
        { error: 'character_id and referral_code are required' },
        { status: 400 },
      )
    }

    const code = (referral_code as string).toUpperCase().trim()

    const character = await prisma.character.findUnique({
      where: { id: character_id },
      select: {
        id: true,
        userId: true,
        referredBy: true,
        referralCode: true,
      },
    })

    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    // Already has a referral
    if (character.referredBy) {
      return NextResponse.json(
        { error: 'Already referred', alreadyReferred: true },
        { status: 400 },
      )
    }

    // Can't use own code
    if (character.referralCode === code) {
      return NextResponse.json(
        { error: 'Cannot use your own referral code' },
        { status: 400 },
      )
    }

    // Validate code exists
    const referrer = await prisma.character.findFirst({
      where: { referralCode: code },
      select: { id: true, referralCode: true },
    })

    if (!referrer) {
      return NextResponse.json(
        { error: 'Invalid referral code', invalidCode: true },
        { status: 400 },
      )
    }

    // Check referrer hasn't hit max
    const referralCount = await prisma.character.count({
      where: { referredBy: code },
    })

    if (referralCount >= REFERRAL_BONUS.maxReferrals) {
      return NextResponse.json(
        { error: 'Referral code has reached maximum uses' },
        { status: 400 },
      )
    }

    // Apply referral — give bonus gold to invitee
    await prisma.character.update({
      where: { id: character_id },
      data: {
        referredBy: code,
        gold: { increment: REFERRAL_BONUS.extraGold },
      },
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
      referredBy: code,
    })
  } catch (error) {
    console.error('POST /tutorial/referral error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
