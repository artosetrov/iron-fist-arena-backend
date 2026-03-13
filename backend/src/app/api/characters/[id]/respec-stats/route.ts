import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { recalculateDerivedStats } from '@/lib/game/equipment-stats'
import { invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { rateLimit } from '@/lib/rate-limit'
import { CharacterOrigin } from '@prisma/client'

const STAT_KEYS = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha'] as const

const ORIGIN_BONUSES: Record<CharacterOrigin, Partial<Record<string, number>>> = {
  human:    { cha: 2, wis: 1 },
  orc:      { str: 3, int: -1 },
  skeleton: { end: 2, agi: 1 },
  demon:    { int: 2, wis: 2, cha: -1 },
  dogfolk:  { agi: 2, luk: 1 },
}

const BASE_STAT_VALUE = 10
const STAT_POINTS_PER_LEVEL = 3
const INITIAL_STAT_POINTS = 5
const RESPEC_GEM_COST = 50

// POST — Respec (reset) all base stats to initial values, refund stat points. Costs gems.
export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`respec-stats:${user.id}`, 5, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const { id } = await params

    await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id },
        select: {
          userId: true, level: true, origin: true,
          str: true, agi: true, vit: true, end: true,
          int: true, wis: true, luk: true, cha: true,
          statPointsAvailable: true,
        },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Check gems on user
      const dbUser = await tx.user.findUnique({
        where: { id: user.id },
        select: { gems: true },
      })
      if (!dbUser || dbUser.gems < RESPEC_GEM_COST) {
        throw new Error('NOT_ENOUGH_GEMS')
      }

      // Calculate base stats (initial values for this origin)
      const bonuses = ORIGIN_BONUSES[character.origin] ?? {}
      const baseStats: Record<string, number> = {}
      for (const key of STAT_KEYS) {
        baseStats[key] = BASE_STAT_VALUE + (bonuses[key] ?? 0)
      }

      // Calculate total allocated points (current stats minus base stats)
      let totalAllocated = 0
      for (const key of STAT_KEYS) {
        const current = (character as unknown as Record<string, number>)[key]
        totalAllocated += current - baseStats[key]
      }

      if (totalAllocated <= 0) {
        throw new Error('NO_STATS_TO_RESET')
      }

      // Reset stats to base values, refund all allocated points
      await tx.character.update({
        where: { id },
        data: {
          str: baseStats.str,
          agi: baseStats.agi,
          vit: baseStats.vit,
          end: baseStats.end,
          int: baseStats.int,
          wis: baseStats.wis,
          luk: baseStats.luk,
          cha: baseStats.cha,
          statPointsAvailable: character.statPointsAvailable + totalAllocated,
        },
      })

      // Deduct gems
      await tx.user.update({
        where: { id: user.id },
        data: { gems: { decrement: RESPEC_GEM_COST } },
      })
    })

    // Recalculate derived stats
    await recalculateDerivedStats(id)

    // Invalidate combat caches
    await invalidateSkillCache(id)
    await invalidatePassiveCache(id)

    const updated = await prisma.character.findUnique({ where: { id } })
    return NextResponse.json({ character: updated })
  } catch (error) {
    if (error instanceof Error) {
      const map: Record<string, { msg: string; status: number }> = {
        NOT_FOUND: { msg: 'Character not found', status: 404 },
        FORBIDDEN: { msg: 'Forbidden', status: 403 },
        NOT_ENOUGH_GEMS: { msg: 'Not enough gems (need 50)', status: 400 },
        NO_STATS_TO_RESET: { msg: 'No stat points to reset', status: 400 },
      }
      const mapped = map[error.message]
      if (mapped) return NextResponse.json({ error: mapped.msg }, { status: mapped.status })
    }
    console.error('respec-stats error:', error)
    return NextResponse.json({ error: 'Failed to respec stats' }, { status: 500 })
  }
}
