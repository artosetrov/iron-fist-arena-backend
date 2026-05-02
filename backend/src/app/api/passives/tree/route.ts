import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { cacheGet, cacheSet } from '@/lib/cache'
import { getRankCosts } from '@/lib/game/passives'

const CACHE_TTL = 10 * 60 * 1000 // 10 minutes

interface CachedTree {
  nodes: unknown[]
  connections: unknown[]
}

// GET — Get the full passive skill tree (all nodes + connections).
//
// Talents v2 (2026-04-19): each node ships a `rank_costs` array derived from
// its total `cost`. Clients must consume this array rather than re-deriving it
// locally so the server remains the source of truth for rank economy.
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    // v4 — 2026-05-01: added `flavor` (narrative prose for the talent modal).
    const cacheKey = 'passives:tree:v4'
    let tree = await cacheGet<CachedTree>(cacheKey)

    if (!tree) {
      const [nodes, connections] = await Promise.all([
        prisma.passiveNode.findMany({
          where: { isActive: true },
          orderBy: [{ tier: 'asc' }, { name: 'asc' }],
          select: {
            id: true, nodeKey: true, name: true, description: true, flavor: true,
            bonusType: true, bonusStat: true, bonusValue: true,
            tier: true, positionX: true, positionY: true, cost: true,
            icon: true, classRestriction: true, isStartNode: true,
            isActivatable: true, activeActionType: true,
            activeCooldown: true, activeMagnitude: true,
          },
        }),
        prisma.passiveConnection.findMany({
          select: { id: true, fromId: true, toId: true },
        }),
      ])

      const withRankCosts = nodes.map((n) => {
        const schedule = getRankCosts(n.cost)
        return { ...n, rank_costs: schedule, max_rank: schedule.length }
      })

      tree = { nodes: withRankCosts, connections }
      await cacheSet(cacheKey, tree, CACHE_TTL)
    }

    return NextResponse.json(tree)
  } catch (error) {
    console.error('passives tree error:', error)
    return NextResponse.json({ error: 'Failed to fetch passive tree' }, { status: 500 })
  }
}
