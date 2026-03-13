import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { cacheGet, cacheSet } from '@/lib/cache'

const CACHE_TTL = 10 * 60 * 1000 // 10 minutes

interface CachedTree {
  nodes: unknown[]
  connections: unknown[]
}

// GET — Get the full passive skill tree (all nodes + connections)
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const cacheKey = 'passives:tree'
  let tree = await cacheGet<CachedTree>(cacheKey)

  if (!tree) {
    const [nodes, connections] = await Promise.all([
      prisma.passiveNode.findMany({
        where: { isActive: true },
        orderBy: [{ tier: 'asc' }, { name: 'asc' }],
        select: {
          id: true, nodeKey: true, name: true, description: true,
          bonusType: true, bonusStat: true, bonusValue: true,
          tier: true, positionX: true, positionY: true, cost: true,
          icon: true, classRestriction: true, isStartNode: true,
        },
      }),
      prisma.passiveConnection.findMany({
        select: { id: true, fromId: true, toId: true },
      }),
    ])

    tree = { nodes, connections }
    await cacheSet(cacheKey, tree, CACHE_TTL)
  }

  return NextResponse.json(tree)
}
