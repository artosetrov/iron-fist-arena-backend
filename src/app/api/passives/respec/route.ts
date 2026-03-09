import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { PASSIVES } from '@/lib/game/balance'
import { recalculateFullDerivedStats } from '@/lib/game/build-stats'
import { cacheDelete } from '@/lib/cache'
import { rateLimit } from '@/lib/rate-limit'

// POST — Respec (reset) all passives, refund points. Costs gems.
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`passives-respec:${user.id}`, 5, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const { character_id } = await req.json()

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true, passivePointsAvailable: true },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Check gems
      const dbUser = await tx.user.findUnique({
        where: { id: user.id },
        select: { gems: true },
      })
      if (!dbUser || dbUser.gems < PASSIVES.RESPEC_GEM_COST) {
        throw new Error('NOT_ENOUGH_GEMS')
      }

      // Calculate total points to refund
      const passives = await tx.characterPassive.findMany({
        where: { characterId: character_id },
        include: { node: { select: { cost: true } } },
      })

      if (passives.length === 0) throw new Error('NO_PASSIVES')

      const totalPointsRefund = passives.reduce((sum, p) => sum + p.node.cost, 0)

      // Delete all character passives
      await tx.characterPassive.deleteMany({
        where: { characterId: character_id },
      })

      // Refund points
      await tx.character.update({
        where: { id: character_id },
        data: {
          passivePointsAvailable: { increment: totalPointsRefund },
        },
      })

      // Deduct gems
      await tx.user.update({
        where: { id: user.id },
        data: { gems: { decrement: PASSIVES.RESPEC_GEM_COST } },
      })

      // Recalculate stats
      const stats = await recalculateFullDerivedStats(character_id, tx)

      return {
        pointsRefunded: totalPointsRefund,
        passivePointsAvailable: character.passivePointsAvailable + totalPointsRefund,
        gemsRemaining: dbUser.gems - PASSIVES.RESPEC_GEM_COST,
        stats,
      }
    })

    // Invalidate cache
    cacheDelete(`passives:char:${character_id}`)

    return NextResponse.json({
      success: true,
      points_refunded: result.pointsRefunded,
      passive_points_available: result.passivePointsAvailable,
      gems_spent: PASSIVES.RESPEC_GEM_COST,
      gems_remaining: result.gemsRemaining,
      stats: {
        max_hp: result.stats.maxHp,
        armor: result.stats.armor,
        magic_resist: result.stats.magicResist,
      },
    })
  } catch (error) {
    if (error instanceof Error) {
      const map: Record<string, { msg: string; status: number }> = {
        NOT_FOUND: { msg: 'Character not found', status: 404 },
        FORBIDDEN: { msg: 'Forbidden', status: 403 },
        NOT_ENOUGH_GEMS: { msg: 'Not enough gems', status: 400 },
        NO_PASSIVES: { msg: 'No passives to reset', status: 400 },
      }
      const mapped = map[error.message]
      if (mapped) return NextResponse.json({ error: mapped.msg }, { status: mapped.status })
    }
    console.error('respec passives error:', error)
    return NextResponse.json({ error: 'Failed to respec passives' }, { status: 500 })
  }
}
