import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

export async function GET() {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const dungeons = await prisma.dungeon.findMany({
      include: {
        bosses: { orderBy: { floorNumber: 'asc' } },
        waves: { include: { enemies: true }, orderBy: { waveNumber: 'asc' } },
        drops: { include: { item: true } },
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
    })
    return NextResponse.json(dungeons)
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to fetch dungeons'
    return NextResponse.json({ error: message }, { status: 500 })
  }
}

function slugify(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '')
}

export async function POST(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const slug = body.slug || slugify(body.name)

    const dungeon = await prisma.dungeon.create({
      data: {
        slug,
        name: body.name,
        description: body.description || null,
        lore: body.lore || null,
        levelReq: Number(body.levelReq) || 1,
        difficulty: body.difficulty || 'normal',
        dungeonType: body.dungeonType || 'story',
        energyCost: Number(body.energyCost) || 20,
        imageUrl: body.imageUrl || null,
        backgroundUrl: body.backgroundUrl || null,
        imagePrompt: body.imagePrompt || null,
        imageStyle: body.imageStyle || null,
        isActive: body.isActive ?? true,
        sortOrder: Number(body.sortOrder) || 0,
        goldReward: Number(body.goldReward) || 0,
        xpReward: Number(body.xpReward) || 0,
        bosses: {
          create: (body.bosses || []).map((b: Record<string, unknown>, i: number) => ({
            name: b.name as string,
            bossType: (b.bossType as string) || null,
            level: Number(b.level) || 1,
            hp: Number(b.hp) || 100,
            damage: Number(b.damage) || 0,
            defense: Number(b.defense) || 0,
            speed: Number(b.speed) || 0,
            critChance: Number(b.critChance) || 0,
            description: (b.description as string) || null,
            lore: (b.lore as string) || null,
            imageUrl: (b.imageUrl as string) || null,
            imagePrompt: (b.imagePrompt as string) || null,
            floorNumber: Number(b.floorNumber) || i + 1,
            sortOrder: Number(b.sortOrder) || i,
            abilities: {
              create: ((b.abilities as Record<string, unknown>[]) || []).map((a: Record<string, unknown>) => ({
                name: a.name as string,
                abilityType: (a.abilityType as string) || 'physical',
                damage: Number(a.damage) || 0,
                cooldown: Number(a.cooldown) || 0,
                specialEffect: (a.specialEffect as string) || null,
                description: (a.description as string) || null,
              })),
            },
          })),
        },
        waves: {
          create: (body.waves || []).map((w: Record<string, unknown>) => ({
            waveNumber: Number(w.waveNumber) || 1,
            enemies: {
              create: ((w.enemies as Record<string, unknown>[]) || []).map((e: Record<string, unknown>) => ({
                enemyType: e.enemyType as string,
                level: Number(e.level) || 1,
                count: Number(e.count) || 1,
              })),
            },
          })),
        },
        drops: {
          create: (body.drops || []).map((d: Record<string, unknown>) => ({
            itemId: d.itemId as string,
            dropChance: Number(d.dropChance) || 0,
            minQuantity: Number(d.minQuantity) || 1,
            maxQuantity: Number(d.maxQuantity) || 1,
          })),
        },
      },
      include: {
        bosses: { include: { abilities: true }, orderBy: { floorNumber: 'asc' } },
        waves: { include: { enemies: true }, orderBy: { waveNumber: 'asc' } },
        drops: { include: { item: true } },
      },
    })

    return NextResponse.json(dungeon)
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to create dungeon'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}
