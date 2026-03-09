import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { recalculateDerivedStats } from '@/lib/game/equipment-stats'
import { invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { rateLimit } from '@/lib/rate-limit'

const STAT_KEYS = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha'] as const

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`allocate-stats:${user.id}`, 10, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const { id } = await params
    const body = await req.json()

    // Validate allocation values from body first (no DB needed)
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

    // Use interactive transaction with row-level lock to prevent TOCTOU
    await prisma.$transaction(async (tx) => {
      // Lock the character row for update
      const rows = await tx.$queryRawUnsafe<Array<{
        id: string; user_id: string; stat_points_available: number;
        str: number; agi: number; vit: number; end: number;
        int: number; wis: number; luk: number; cha: number
      }>>(
        `SELECT id, user_id, stat_points_available, str, agi, vit, "end", "int", wis, luk, cha FROM characters WHERE id = $1 FOR UPDATE`,
        id
      )

      const character = rows[0]
      if (!character) {
        throw new Error('NOT_FOUND')
      }

      if (character.user_id !== user.id) {
        throw new Error('FORBIDDEN')
      }

      if (totalPoints > character.stat_points_available) {
        throw new Error('NOT_ENOUGH_POINTS')
      }

      // Calculate new stat values
      const newStats: Record<string, number> = {}
      for (const key of STAT_KEYS) {
        newStats[key] = (character as unknown as Record<string, number>)[key] + (allocation[key] ?? 0)
      }

      await tx.character.update({
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
          statPointsAvailable: { decrement: totalPoints },
        },
      })
    })

    // Recalculate derived stats (maxHp, armor, magicResist) including equipment
    await recalculateDerivedStats(id)

    // Invalidate combat caches so PvP uses fresh stats
    invalidateSkillCache(id)
    invalidatePassiveCache(id)

    const updated = await prisma.character.findUnique({ where: { id } })
    return NextResponse.json({ character: updated })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') {
        return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      }
      if (error.message === 'FORBIDDEN') {
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      }
      if (error.message === 'NOT_ENOUGH_POINTS') {
        return NextResponse.json({ error: 'Not enough stat points' }, { status: 400 })
      }
    }
    console.error('allocate-stats error:', error)
    return NextResponse.json(
      { error: 'Failed to allocate stats' },
      { status: 500 }
    )
  }
}
