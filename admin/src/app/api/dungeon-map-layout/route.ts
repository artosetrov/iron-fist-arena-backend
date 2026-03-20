import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

const DUNGEON_MAP_LAYOUT_KEY = 'dungeon_map_layout'

export async function GET() {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const config = await prisma.gameConfig.findUnique({
      where: { key: DUNGEON_MAP_LAYOUT_KEY },
    })
    return NextResponse.json({ layout: config?.value ?? {} })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to fetch dungeon map layout'
    return NextResponse.json({ error: message }, { status: 500 })
  }
}

export async function POST(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { layout } = body

    if (!layout || typeof layout !== 'object') {
      return NextResponse.json({ error: 'layout object is required' }, { status: 400 })
    }

    const config = await prisma.gameConfig.upsert({
      where: { key: DUNGEON_MAP_LAYOUT_KEY },
      update: {
        value: layout,
        updatedBy: admin.id,
      },
      create: {
        key: DUNGEON_MAP_LAYOUT_KEY,
        value: layout,
        category: 'ui',
        description: 'Dungeon map node positions (admin-editable)',
        updatedBy: admin.id,
      },
    })

    return NextResponse.json({ layout: config.value })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to save dungeon map layout'
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
