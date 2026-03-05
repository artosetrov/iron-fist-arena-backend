import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const PREMIUM_COST_GEMS = 500

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

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

    // Find active season
    const now = new Date()
    const activeSeason = await prisma.season.findFirst({
      where: {
        startAt: { lte: now },
        endAt: { gte: now },
      },
    })

    if (!activeSeason) {
      return NextResponse.json({ error: 'No active season' }, { status: 404 })
    }

    // Get battle pass
    let battlePass = await prisma.battlePass.findFirst({
      where: { characterId: character_id, seasonId: activeSeason.id },
    })

    if (!battlePass) {
      battlePass = await prisma.battlePass.create({
        data: {
          characterId: character_id,
          seasonId: activeSeason.id,
          premium: false,
          bpXp: 0,
        },
      })
    }

    if (battlePass.premium) {
      return NextResponse.json(
        { error: 'Battle pass is already premium' },
        { status: 400 }
      )
    }

    // Check user gems
    const dbUser = await prisma.user.findUnique({
      where: { id: user.id },
    })

    if (!dbUser) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    if (dbUser.gems < PREMIUM_COST_GEMS) {
      return NextResponse.json(
        { error: `Not enough gems. Need ${PREMIUM_COST_GEMS}, have ${dbUser.gems}` },
        { status: 400 }
      )
    }

    // Deduct gems and upgrade to premium in a transaction
    const [updatedUser, updatedBattlePass] = await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: { gems: { decrement: PREMIUM_COST_GEMS } },
      }),
      prisma.battlePass.update({
        where: { id: battlePass.id },
        data: { premium: true },
      }),
    ])

    return NextResponse.json({
      battlePass: {
        id: updatedBattlePass.id,
        premium: updatedBattlePass.premium,
        bpXp: updatedBattlePass.bpXp,
      },
      gemsRemaining: updatedUser.gems,
      cost: PREMIUM_COST_GEMS,
    })
  } catch (error) {
    console.error('buy premium error:', error)
    return NextResponse.json(
      { error: 'Failed to buy premium battle pass' },
      { status: 500 }
    )
  }
}
