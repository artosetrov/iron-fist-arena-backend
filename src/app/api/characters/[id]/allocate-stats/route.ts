import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const STAT_KEYS = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha'] as const

function calculateMaxHp(vit: number, end: number): number {
  return 80 + vit * 5 + end * 3
}

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { id } = await params
    const body = await req.json()

    const character = await prisma.character.findUnique({ where: { id } })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Validate allocation values
    let totalPoints = 0
    const allocation: Record<string, number> = {}

    for (const key of STAT_KEYS) {
      const value = body[key]
      if (value !== undefined && value !== null) {
        if (typeof value !== 'number' || value < 0 || !Number.isInteger(value)) {
          return NextResponse.json(
            { error: `Invalid value for ${key}. Must be a non-negative integer.` },
            { status: 400 }
          )
        }
        allocation[key] = value
        totalPoints += value
      }
    }

    if (totalPoints === 0) {
      return NextResponse.json(
        { error: 'No stat points to allocate' },
        { status: 400 }
      )
    }

    if (totalPoints > character.statPointsAvailable) {
      return NextResponse.json(
        {
          error: `Not enough stat points. Requested: ${totalPoints}, Available: ${character.statPointsAvailable}`,
        },
        { status: 400 }
      )
    }

    // Calculate new stat values
    const newStats: Record<string, number> = {}
    for (const key of STAT_KEYS) {
      newStats[key] = character[key] + (allocation[key] ?? 0)
    }

    const maxHp = calculateMaxHp(newStats.vit, newStats.end)

    const updated = await prisma.character.update({
      where: { id },
      data: {
        str: newStats.str,
        agi: newStats.agi,
        vit: newStats.vit,
        end: newStats.end,
        int: newStats.int,
        wis: newStats.wis,
        luk: newStats.luk,
        cha: newStats.cha,
        maxHp,
        statPointsAvailable: character.statPointsAvailable - totalPoints,
      },
    })

    return NextResponse.json({ character: updated })
  } catch (error) {
    console.error('allocate-stats error:', error)
    return NextResponse.json(
      { error: 'Failed to allocate stats' },
      { status: 500 }
    )
  }
}
