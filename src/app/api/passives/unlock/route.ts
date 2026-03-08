import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { canUnlockNode } from '@/lib/game/passives'
import { recalculateFullDerivedStats } from '@/lib/game/build-stats'
import { cacheDelete } from '@/lib/cache'

// POST — Unlock a passive node
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { character_id, node_id } = await req.json()

    if (!character_id || !node_id) {
      return NextResponse.json({ error: 'character_id and node_id are required' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true, class: true, passivePointsAvailable: true },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const node = await tx.passiveNode.findUnique({ where: { id: node_id } })
      if (!node || !node.isActive) throw new Error('NODE_NOT_FOUND')

      // Check class restriction
      if (node.classRestriction && node.classRestriction !== character.class) {
        throw new Error('CLASS_RESTRICTED')
      }

      // Check already unlocked
      const existing = await tx.characterPassive.findUnique({
        where: { characterId_nodeId: { characterId: character_id, nodeId: node_id } },
      })
      if (existing) throw new Error('ALREADY_UNLOCKED')

      // Check passive points
      if (character.passivePointsAvailable < node.cost) {
        throw new Error('NOT_ENOUGH_POINTS')
      }

      // Check connectivity — get all connections and already-unlocked nodes
      const [connections, unlockedPassives] = await Promise.all([
        tx.passiveConnection.findMany({
          select: { fromId: true, toId: true },
        }),
        tx.characterPassive.findMany({
          where: { characterId: character_id },
          select: { nodeId: true },
        }),
      ])

      const unlockedIds = new Set(unlockedPassives.map((p) => p.nodeId))

      if (!canUnlockNode(node_id, connections, unlockedIds, node.isStartNode)) {
        throw new Error('NOT_CONNECTED')
      }

      // Deduct points
      await tx.character.update({
        where: { id: character_id },
        data: { passivePointsAvailable: { decrement: node.cost } },
      })

      // Create passive record
      await tx.characterPassive.create({
        data: { characterId: character_id, nodeId: node_id },
      })

      // Recalculate derived stats
      const stats = await recalculateFullDerivedStats(character_id, tx)

      return {
        passivePointsAvailable: character.passivePointsAvailable - node.cost,
        stats,
      }
    })

    // Invalidate cache
    cacheDelete(`passives:char:${character_id}`)

    return NextResponse.json({
      success: true,
      passive_points_available: result.passivePointsAvailable,
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
        NODE_NOT_FOUND: { msg: 'Passive node not found', status: 404 },
        CLASS_RESTRICTED: { msg: 'This passive is not available for your class', status: 400 },
        ALREADY_UNLOCKED: { msg: 'Passive already unlocked', status: 400 },
        NOT_ENOUGH_POINTS: { msg: 'Not enough passive points', status: 400 },
        NOT_CONNECTED: { msg: 'Node is not connected to any unlocked node', status: 400 },
      }
      const mapped = map[error.message]
      if (mapped) return NextResponse.json({ error: mapped.msg }, { status: mapped.status })
    }
    console.error('unlock passive error:', error)
    return NextResponse.json({ error: 'Failed to unlock passive' }, { status: 500 })
  }
}
