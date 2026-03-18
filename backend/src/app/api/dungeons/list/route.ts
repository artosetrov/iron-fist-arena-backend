import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

/**
 * GET /api/dungeons/list
 * Returns all active dungeons with their bosses from the database.
 * This allows the iOS client to dynamically load dungeons
 * instead of relying solely on hardcoded data.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`dungeons-list-full:${user.id}`, 20, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const dungeons = await prisma.dungeon.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
      include: {
        bosses: {
          orderBy: { floorNumber: 'asc' },
          select: {
            id: true,
            name: true,
            bossType: true,
            level: true,
            hp: true,
            damage: true,
            defense: true,
            speed: true,
            critChance: true,
            description: true,
            imageUrl: true,
            floorNumber: true,
            sortOrder: true,
          },
        },
      },
    })

    const result = dungeons.map((d) => ({
      id: d.id,
      slug: d.slug,
      name: d.name,
      description: d.description,
      lore: d.lore,
      level_req: d.levelReq,
      energy_cost: d.energyCost,
      image_url: d.imageUrl,
      background_url: d.backgroundUrl,
      difficulty: d.difficulty,
      dungeon_type: d.dungeonType,
      gold_reward: d.goldReward,
      xp_reward: d.xpReward,
      sort_order: d.sortOrder,
      total_bosses: d.bosses.length,
      bosses: d.bosses.map((b) => ({
        id: b.id,
        name: b.name,
        boss_type: b.bossType,
        level: b.level,
        hp: b.hp,
        damage: b.damage,
        defense: b.defense,
        speed: b.speed,
        crit_chance: b.critChance,
        description: b.description,
        image_url: b.imageUrl,
        floor_number: b.floorNumber,
      })),
    }))

    return NextResponse.json({ dungeons: result })
  } catch (error) {
    console.error('list dungeons error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch dungeons' },
      { status: 500 },
    )
  }
}
