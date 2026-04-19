import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getPassivesConfig } from '@/lib/game/live-config'
import { getRankCosts } from '@/lib/game/passives'
import { recalculateFullDerivedStats } from '@/lib/game/build-stats'
import { cacheDelete } from '@/lib/cache'
import { rateLimit } from '@/lib/rate-limit'

// POST — Respec (reset) all passives, refund points.
//
// Talents v2 (2026-04-19):
//   - One free respec per rolling FREE_RESPEC_WINDOW_DAYS window (default 7d),
//     tracked via Character.lastFreeRespecAt. Null or older than window ⇒ free.
//   - Otherwise costs PASSIVES.RESPEC_GEM_COST gems.
//   - Refund is the sum of per-rank costs actually paid: for a 3-rank node at
//     currentRank=2, refund is rankCosts[0] + rankCosts[1] = 1 + 2 = 3 SP.
//     Legacy single-rank nodes (cost 3 or 5) refund their full cost at rank 1.
//
// Request body:
//   { character_id: string, use_free?: boolean }
//
// `use_free` defaults to true when a free respec is available. If the client
// explicitly passes `use_free: false` the player pays gems and preserves their
// free window (opt-out is useful before a big session where they'd rather save
// the free one for mid-week experimentation).
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`passives-respec:${user.id}`, 5, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const PASSIVES = await getPassivesConfig()
    const body = await req.json()
    const { character_id, use_free: useFreeRaw } = body ?? {}

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const useFreeRequested = useFreeRaw !== false // default true

    const result = await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true, passivePointsAvailable: true, lastFreeRespecAt: true },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Determine whether a free respec is available right now.
      const windowMs = PASSIVES.FREE_RESPEC_WINDOW_DAYS * 24 * 60 * 60 * 1000
      const now = new Date()
      const freeAvailable =
        character.lastFreeRespecAt == null ||
        now.getTime() - character.lastFreeRespecAt.getTime() >= windowMs
      const useFree = freeAvailable && useFreeRequested

      // Gems are only checked on the paid path.
      let gemsRemainingAfter = 0
      let gemsSpent = 0
      if (!useFree) {
        const dbUser = await tx.user.findUnique({
          where: { id: user.id },
          select: { gems: true },
        })
        if (!dbUser || dbUser.gems < PASSIVES.RESPEC_GEM_COST) {
          throw new Error('NOT_ENOUGH_GEMS')
        }
        gemsSpent = PASSIVES.RESPEC_GEM_COST
        gemsRemainingAfter = dbUser.gems - PASSIVES.RESPEC_GEM_COST
      }

      // Load unlocked passives with enough data to compute per-rank refund.
      const passives = await tx.characterPassive.findMany({
        where: { characterId: character_id },
        select: {
          currentRank: true,
          node: { select: { cost: true } },
        },
      })

      if (passives.length === 0) throw new Error('NO_PASSIVES')

      // Talents v2 refund: sum the first `currentRank` entries of each node's
      // rank-cost schedule. Single-rank nodes collapse to [totalCost] and
      // refund their full cost, preserving legacy behavior.
      const totalPointsRefund = passives.reduce((sum, p) => {
        const schedule = getRankCosts(p.node.cost)
        const paidRanks = Math.max(0, Math.min(p.currentRank, schedule.length))
        for (let i = 0; i < paidRanks; i++) sum += schedule[i]
        return sum
      }, 0)

      // Wipe unlocks
      await tx.characterPassive.deleteMany({
        where: { characterId: character_id },
      })

      // Clear active slots — they reference unlocked nodes that no longer exist
      await tx.characterActiveSlot.deleteMany({
        where: { characterId: character_id },
      })

      // Refund SP (+ stamp last_free_respec_at when consuming the free path)
      await tx.character.update({
        where: { id: character_id },
        data: {
          passivePointsAvailable: { increment: totalPointsRefund },
          ...(useFree ? { lastFreeRespecAt: now } : {}),
        },
      })

      // Deduct gems on paid path
      if (!useFree) {
        await tx.user.update({
          where: { id: user.id },
          data: { gems: { decrement: PASSIVES.RESPEC_GEM_COST } },
        })
      }

      // Recalculate stats
      const stats = await recalculateFullDerivedStats(character_id, tx)

      // Compute nextFreeRespecAt for UI ("free again in N days")
      const nextFreeAt = useFree
        ? new Date(now.getTime() + windowMs)
        : character.lastFreeRespecAt
          ? new Date(character.lastFreeRespecAt.getTime() + windowMs)
          : now // never used free before → already free

      return {
        pointsRefunded: totalPointsRefund,
        passivePointsAvailable: character.passivePointsAvailable + totalPointsRefund,
        gemsSpent,
        gemsRemaining: gemsRemainingAfter,
        usedFreeRespec: useFree,
        nextFreeRespecAt: nextFreeAt.toISOString(),
        stats,
      }
    })

    // Invalidate cache
    await cacheDelete(`passives:char:v2:${character_id}`)
    await cacheDelete(`active-slots:char:${character_id}`)

    return NextResponse.json({
      success: true,
      points_refunded: result.pointsRefunded,
      passive_points_available: result.passivePointsAvailable,
      gems_spent: result.gemsSpent,
      gems_remaining: result.gemsRemaining,
      used_free_respec: result.usedFreeRespec,
      next_free_respec_at: result.nextFreeRespecAt,
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
