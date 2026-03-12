import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

export async function GET(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { searchParams } = new URL(req.url)
  const id = searchParams.get('id')

  if (id) {
    const item = await prisma.item.findUnique({ where: { id } })
    if (!item) return NextResponse.json({ error: 'Item not found' }, { status: 404 })
    return NextResponse.json(item)
  }

  const items = await prisma.item.findMany({
    orderBy: [{ rarity: 'desc' }, { itemLevel: 'desc' }, { itemName: 'asc' }],
  })
  return NextResponse.json(items)
}

export async function POST(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const item = await prisma.item.create({
      data: {
        catalogId: body.catalogId,
        itemName: body.itemName,
        itemType: body.itemType,
        rarity: body.rarity,
        itemLevel: body.itemLevel,
        baseStats: body.baseStats,
        specialEffect: body.specialEffect,
        uniquePassive: body.uniquePassive,
        classRestriction: body.classRestriction,
        setName: body.setName,
        buyPrice: body.buyPrice,
        sellPrice: body.sellPrice,
        description: body.description,
        imageUrl: body.imageUrl,
        imageKey: body.imageKey || null,
        dropChance: body.dropChance !== undefined ? Number(body.dropChance) : 0,
        itemClass: body.itemClass || null,
        upgradeConfig: body.upgradeConfig || null,
      },
    })
    return NextResponse.json(item)
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to create item'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}

export async function PUT(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { id, ...data } = body
    const item = await prisma.item.update({
      where: { id },
      data: {
        catalogId: data.catalogId,
        itemName: data.itemName,
        itemType: data.itemType,
        rarity: data.rarity,
        itemLevel: data.itemLevel,
        baseStats: data.baseStats,
        specialEffect: data.specialEffect,
        uniquePassive: data.uniquePassive,
        classRestriction: data.classRestriction,
        setName: data.setName,
        buyPrice: data.buyPrice,
        sellPrice: data.sellPrice,
        description: data.description,
        imageUrl: data.imageUrl,
        imageKey: data.imageKey !== undefined ? (data.imageKey || null) : undefined,
        dropChance: data.dropChance !== undefined ? Number(data.dropChance) : undefined,
        itemClass: data.itemClass !== undefined ? (data.itemClass || null) : undefined,
        upgradeConfig: data.upgradeConfig !== undefined ? (data.upgradeConfig || null) : undefined,
      },
    })
    return NextResponse.json(item)
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to update item'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}

export async function DELETE(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { searchParams } = new URL(req.url)
    const id = searchParams.get('id')
    if (!id) return NextResponse.json({ error: 'Missing id' }, { status: 400 })

    await prisma.item.delete({ where: { id } })
    return NextResponse.json({ success: true })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to delete item'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}
