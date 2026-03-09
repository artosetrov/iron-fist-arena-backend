import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { canClaimDailyLogin, shouldResetStreak, getDailyReward } from '@/lib/game/daily-login'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`daily-login:${user.id}`, 5, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: character_id },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Get or create the daily login record
    let loginReward = await prisma.dailyLoginReward.findUnique({
      where: { characterId: character_id },
    })

    if (!loginReward) {
      loginReward = await prisma.dailyLoginReward.create({
        data: {
          characterId: character_id,
          currentDay: 1,
          streak: 0,
          totalClaims: 0,
        },
      })
    }

    // Check eligibility
    if (!canClaimDailyLogin(loginReward.lastClaimDate)) {
      return NextResponse.json(
        { error: 'Daily login reward already claimed today' },
        { status: 400 }
      )
    }

    // Determine if streak resets
    const resetStreak = shouldResetStreak(loginReward.lastClaimDate)
    const newDay = resetStreak ? 1 : loginReward.currentDay
    const newStreak = resetStreak ? 1 : loginReward.streak + 1

    // Get the reward for the current day
    const reward = getDailyReward(newDay)

    // Apply reward + update record atomically
    const updatedLogin = await prisma.$transaction(async (tx) => {
      if (reward.type === 'gold') {
        await tx.character.update({
          where: { id: character_id },
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

      return tx.dailyLoginReward.update({
        where: { characterId: character_id },
        data: {
          currentDay: nextDay,
          lastClaimDate: new Date(),
          streak: newStreak,
          totalClaims: { increment: 1 },
        },
      })
    })

    return NextResponse.json({
      reward: {
        type: reward.type,
        amount: reward.amount,
        itemId: reward.itemId ?? null,
      },
      currentDay: updatedLogin.currentDay,
      streak: updatedLogin.streak,
      totalClaims: updatedLogin.totalClaims,
    })
  } catch (error) {
    console.error('claim daily login error:', error)
    return NextResponse.json(
      { error: 'Failed to claim daily login reward' },
      { status: 500 }
    )
  }
}
