import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    const skins = await prisma.appearanceSkin.findMany({
      orderBy: [{ origin: 'asc' }, { gender: 'asc' }, { sortOrder: 'asc' }],
      select: {
        id: true,
        skinKey: true,
        name: true,
        origin: true,
        gender: true,
        rarity: true,
        priceGold: true,
        priceGems: true,
        imageUrl: true,
        imageKey: true,
        isDefault: true,
        sortOrder: true,
      },
    })

    return NextResponse.json({ skins })
  } catch (error) {
    console.error('Failed to fetch appearances:', error)
    return NextResponse.json({ error: 'Failed to fetch appearances' }, { status: 500 })
  }
}
