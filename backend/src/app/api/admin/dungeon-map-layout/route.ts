import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

const DUNGEON_MAP_LAYOUT_KEY = 'dungeon_map_layout'

/**
 * GET /api/admin/dungeon-map-layout
 * Returns the current dungeon map node layout.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const config = await prisma.gameConfig.findUnique({
      where: { key: DUNGEON_MAP_LAYOUT_KEY },
    })

    return NextResponse.json({
      layout: config?.value ?? {},
    })
  } catch (error) {
    console.error('admin dungeon-map-layout GET error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch dungeon map layout' },
      { status: 500 }
    )
  }
}

/**
 * POST /api/admin/dungeon-map-layout
 * Save dungeon node positions on the map.
 * Body: { layout: { training_camp: { x, y, size }, desecrated_catacombs: { x, y, size }, ... } }
 * Stored in game_config table as JSON, served to all users via /game/init.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const body = await req.json()
    const { layout } = body

    if (!layout || typeof layout !== 'object') {
      return NextResponse.json(
        { error: 'layout object is required' },
        { status: 400 }
      )
    }

    const config = await prisma.gameConfig.upsert({
      where: { key: DUNGEON_MAP_LAYOUT_KEY },
      update: {
        value: layout,
        updatedBy: user.id,
      },
      create: {
        key: DUNGEON_MAP_LAYOUT_KEY,
        value: layout,
        category: 'ui',
        description: 'Dungeon map node positions (admin-editable)',
        updatedBy: user.id,
      },
    })

    // Log the action
    await prisma.adminLog.create({
      data: {
        adminId: user.id,
        action: 'update_dungeon_map_layout',
        details: layout,
      },
    })

    return NextResponse.json({ layout: config.value })
  } catch (error) {
    console.error('admin dungeon-map-layout POST error:', error)
    return NextResponse.json(
      { error: 'Failed to save dungeon map layout' },
      { status: 500 }
    )
  }
}
