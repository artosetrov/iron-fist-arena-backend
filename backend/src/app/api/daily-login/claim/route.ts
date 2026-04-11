import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { canClaimDailyLogin, shouldResetStreak, getDailyReward } from '@/lib/game/daily-login'
import { rateLimit } from '@/lib/rate-limit'
import {
  hasPremium,
  hasPremiumGemsClaimedToday,
  PREMIUM_DAILY_GEMS,
} from '@/lib/game/premium'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`daily-login:${user.id}`, 5, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    // Verify ownership first (lightweight check)
    const character = await prisma.character.findUnique({
      where: { id: character_id },
      select: { id: true, userId: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Atomic claim in interactive transaction with row lock
    const result = await prisma.$transaction(async (tx) => {
      // Lock the daily login row with FOR UPDATE
      const rows = await tx.$queryRawUnsafe<any[]>(
        `SELECT id, current_day AS "currentDay", last_claim_date AS "lastClaimDate",
                streak, total_claims AS "totalClaims"
         FROM daily_login_rewards
         WHERE character_id = $1
         FOR UPDATE`,
        character_id
      )

      let loginReward = rows[0]

      if (!loginReward) {
        // Create initial record inside the transaction
        loginReward = await tx.dailyLoginReward.create({
          data: {
            characterId: character_id,
            currentDay: 1,
            streak: 0,
            totalClaims: 0,
          },
        })
      }

      // Check eligibility with locked data
      if (!canClaimDailyLogin(loginReward.lastClaimDate)) {
        throw new Error('ALREADY_CLAIMED')
      }

      // Determine if streak resets
      const resetStreak = shouldResetStreak(loginReward.lastClaimDate)
      const newDay = resetStreak ? 1 : loginReward.currentDay
      const newStreak = resetStreak ? 1 : loginReward.streak + 1

      // Get the reward for the current day
      const reward = await getDailyReward(newDay)

      // Apply reward
      if (reward.type === 'gold') {
        await tx.user.update({
          where: { id: user.id },
          data: { gold: { increment: reward.amount } },
        })
      } else if (reward.type === 'gems') {
        await tx.user.update({
          where: { id: user.id },
          data: { gems: { increment: reward.amount } },
        })
      } else if (reward.type === 'consumable' && reward.itemId) {
        await tx.consumableInventory.upsert({
          where: {
            characterId_consumableType: {
              characterId: character_id,
              consumableType: reward.itemId as any,
            },
          },
          update: { quantity: { increment: reward.amount } },
          create: {
            characterId: character_id,
            consumableType: reward.itemId as any,
            quantity: reward.amount,
          },
        })
      }

      // Wrap day back to 1 after day 7 (7-day cycle)
      const nextDay = (newDay % 7) + 1

      const updatedLogin = await tx.dailyLoginReward.update({
        where: { characterId: character_id },
        data: {
          currentDay: nextDay,
          lastClaimDate: new Date(),
          streak: newStreak,
          totalClaims: { increment: 1 },
        },
      })

      // W3.D5 — Premium Forever: +25 bonus gems per UTC day, additive to the
      // base daily reward. Applied inside the same transaction so premium
      // claim + daily reward are atomic. `hasPremiumGemsClaimedToday` compares
      // UTC day to prevent double-claim across streak resets.
      const currentUser = await tx.user.findUnique({
        where: { id: user.id },
        select: { premiumUntil: true, premiumGemClaimDate: true },
      })
      let premiumGemsAwarded = 0
      if (
        currentUser &&
        hasPremium(currentUser) &&
        !hasPremiumGemsClaimedToday(currentUser.premiumGemClaimDate)
      ) {
        await tx.user.update({
          where: { id: user.id },
          data: {
            gems: { increment: PREMIUM_DAILY_GEMS },
            premiumGemClaimDate: new Date(),
          },
        })
        premiumGemsAwarded = PREMIUM_DAILY_GEMS
      }

      return { reward, updatedLogin, premiumGemsAwarded }
    })

    return NextResponse.json({
      reward: {
        type: result.reward.type,
        amount: result.reward.amount,
        itemId: result.reward.itemId ?? null,
      },
      currentDay: result.updatedLogin.currentDay,
      streak: result.updatedLogin.streak,
      totalClaims: result.updatedLogin.totalClaims,
      // W3.D5 — Premium Forever bonus gems (0 if not premium or already claimed today)
      premiumGemsAwarded: result.premiumGemsAwarded,
    })
  } catch (error: any) {
    if (error.message === 'ALREADY_CLAIMED') {
      return NextResponse.json(
        { error: 'Daily login reward already claimed today' },
        { status: 400 }
      )
    }
    console.error('claim daily login error:', error)
    return NextResponse.json(
      { error: 'Failed to claim daily login reward' },
      { status: 500 }
    )
  }
}
