import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { canUnlockNode, getRankCosts, getMaxRank } from '@/lib/game/passives'
import { recalculateFullDerivedStats } from '@/lib/game/build-stats'
import { cacheDelete } from '@/lib/cache'
import { rateLimit } from '@/lib/rate-limit'

// POST — Unlock a passive node OR rank it up.
//
// Request body:
//   { character_id: string, node_id: string, rank?: 1 | 2 | 3 }
//
// Contract (Talents v2, 2026-04-19):
//   - If `rank` is omitted or equal to 1: first-time unlock. Creates a
//     CharacterPassive row with currentRank=1, deducts rankCosts[0] SP.
//   - If `rank >= 2`: rank-up. Requires the existing row to have
//     currentRank === rank - 1 exactly. Deducts rankCosts[rank-1] SP.
//   - `rank` must be in [1, maxRank] derived from node.cost via getMaxRank().
//
// Connectivity only checked on first unlock (rank=1). Rank-ups of an
// already-unlocked node skip the adjacency check.
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`passives-unlock:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const { character_id, node_id, rank: rawRank } = await req.json()

    if (!character_id || !node_id) {
      return NextResponse.json({ error: 'character_id and node_id are required' }, { status: 400 })
    }

    // Normalize rank: undefined → 1 (first unlock). Reject non-integers / out-of-range now.
    const rank = rawRank == null ? 1 : Number(rawRank)
    if (!Number.isInteger(rank) || rank < 1 || rank > 3) {
      return NextResponse.json({ error: 'rank must be an integer 1..3' }, { status: 400 })
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

      const rankCosts = getRankCosts(node.cost)
      const maxRank = getMaxRank(node.cost)
      if (rank > maxRank) throw new Error('RANK_OUT_OF_RANGE')

      const spCost = rankCosts[rank - 1]

      // Check passive points
      if (character.passivePointsAvailable < spCost) {
        throw new Error('NOT_ENOUGH_POINTS')
      }

      const existing = await tx.characterPassive.findUnique({
        where: { characterId_nodeId: { characterId: character_id, nodeId: node_id } },
      })

      if (rank === 1) {
        if (existing) throw new Error('ALREADY_UNLOCKED')

        // Check connectivity — only at first unlock
        const [connections, unlockedPassives] = await Promise.all([
          tx.passiveConnection.findMany({ select: { fromId: true, toId: true } }),
          tx.characterPassive.findMany({
            where: { characterId: character_id },
            select: { nodeId: true },
          }),
        ])
        const unlockedIds = new Set(unlockedPassives.map((p) => p.nodeId))
        if (!canUnlockNode(node_id, connections, unlockedIds, node.isStartNode)) {
          throw new Error('NOT_CONNECTED')
        }

        await tx.characterPassive.create({
          data: { characterId: character_id, nodeId: node_id, currentRank: 1 },
        })
      } else {
        // Rank-up path: row must exist and be at exactly rank-1
        if (!existing) throw new Error('NOT_UNLOCKED')
        if (existing.currentRank !== rank - 1) {
          throw new Error('RANK_MISMATCH')
        }
        await tx.characterPassive.update({
          where: { id: existing.id },
          data: { currentRank: rank },
        })
      }

      // Deduct points
      await tx.character.update({
        where: { id: character_id },
        data: { passivePointsAvailable: { decrement: spCost } },
      })

      // Recalculate derived stats
      const stats = await recalculateFullDerivedStats(character_id, tx)

      return {
        passivePointsAvailable: character.passivePointsAvailable - spCost,
        currentRank: rank,
        maxRank,
        spSpent: spCost,
        stats,
      }
    })

    // Invalidate cache
    await cacheDelete(`passives:char:v2:${character_id}`)

    return NextResponse.json({
      success: true,
      passive_points_available: result.passivePointsAvailable,
      current_rank: result.currentRank,
      max_rank: result.maxRank,
      sp_spent: result.spSpent,
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
        NOT_UNLOCKED: { msg: 'Unlock rank 1 first before ranking up', status: 400 },
        RANK_MISMATCH: { msg: 'Rank-up must target the next rank (current + 1)', status: 400 },
        RANK_OUT_OF_RANGE: { msg: 'Rank exceeds this node\'s maximum rank', status: 400 },
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
