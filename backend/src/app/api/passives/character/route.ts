import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { cacheGet, cacheSet } from '@/lib/cache'

const CACHE_TTL = 5 * 60 * 1000 // 5 minutes

// GET — Get a character's unlocked passive nodes
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true, passivePointsAvailable: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    const cacheKey = `passives:char:${characterId}`
    const cached = await cacheGet<unknown[]>(cacheKey)
    if (cached) {
      return NextResponse.json({
        passive_points_available: character.passivePointsAvailable,
        unlocked_nodes: cached,
      })
    }

    const passives = await prisma.characterPassive.findMany({
      where: { characterId },
      include: {
        node: {
          select: {
            id: true, nodeKey: true, name: true, description: true,
            bonusType: true, bonusStat: true, bonusValue: true,
            tier: true, cost: true, icon: true,
          },
        },
      },
    })

    const unlocked_nodes = passives.map((p) => ({
      id: p.id,
      node_id: p.nodeId,
      node_key: p.node.nodeKey,
      name: p.node.name,
      description: p.node.description,
      bonus_type: p.node.bonusType,
      bonus_stat: p.node.bonusStat,
      bonus_value: p.node.bonusValue,
      tier: p.node.tier,
      cost: p.node.cost,
      icon: p.node.icon,
      unlocked_at: p.unlockedAt,
    }))

    await cacheSet(cacheKey, unlocked_nodes, CACHE_TTL)

    return NextResponse.json({
      passive_points_available: character.passivePointsAvailable,
      unlocked_nodes,
    })
  } catch (error) {
    console.error('passives character error:', error)
    return NextResponse.json({ error: 'Failed to fetch character passives' }, { status: 500 })
  }
}
