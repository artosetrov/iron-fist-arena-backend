import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const GEMS_TO_GOLD_RATE = 10 // 1 gem = 10 gold

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, gems_amount } = body

    if (!character_id || !gems_amount) {
      return NextResponse.json(
        { error: 'character_id and gems_amount are required' },
        { status: 400 }
      )
    }

    if (typeof gems_amount !== 'number' || gems_amount < 1 || !Number.isInteger(gems_amount)) {
      return NextResponse.json(
        { error: 'gems_amount must be a positive integer' },
        { status: 400 }
      )
    }

    // Verify character ownership
    const character = await prisma.character.findUnique({
      where: { id: character_id },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Check user's gems
    const dbUser = await prisma.user.findUnique({
      where: { id: user.id },
    })

    if (!dbUser) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    if (dbUser.gems < gems_amount) {
      return NextResponse.json(
        { error: 'Not enough gems', required: gems_amount, current: dbUser.gems },
        { status: 400 }
      )
    }

    const goldToAdd = gems_amount * GEMS_TO_GOLD_RATE

    // Deduct gems from user and add gold to character in a transaction
    const [updatedUser, updatedCharacter] = await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: { gems: { decrement: gems_amount } },
      }),
      prisma.character.update({
        where: { id: character_id },
        data: { gold: { increment: goldToAdd } },
      }),
    ])

    return NextResponse.json({
      character: {
        gold: updatedCharacter.gold,
        gems: updatedUser.gems,
      },
      gemsSpent: gems_amount,
      goldReceived: goldToAdd,
    })
  } catch (error) {
    console.error('buy gold error:', error)
    return NextResponse.json(
      { error: 'Failed to buy gold' },
      { status: 500 }
    )
  }
}
