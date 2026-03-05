import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { canClaimDailyLogin } from '@/lib/game/daily-login'

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')

    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Get or initialize daily login record
    let loginReward = await prisma.dailyLoginReward.findUnique({
      where: { characterId },
    })

    if (!loginReward) {
      loginReward = await prisma.dailyLoginReward.create({
        data: {
          characterId,
          currentDay: 1,
          streak: 0,
          totalClaims: 0,
        },
      })
    }

    const canClaim = canClaimDailyLogin(loginReward.lastClaimDate)

    return NextResponse.json({
      currentDay: loginReward.currentDay,
      streak: loginReward.streak,
      totalClaims: loginReward.totalClaims,
      lastClaimDate: loginReward.lastClaimDate,
      canClaim,
    })
  } catch (error) {
    console.error('get daily login status error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch daily login status' },
      { status: 500 }
    )
  }
}
