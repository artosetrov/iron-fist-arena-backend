import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

const HUB_LAYOUT_KEY = 'hub_layout'

/**
 * GET /api/admin/hub-layout
 * Returns the current hub building layout.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const config = await prisma.gameConfig.findUnique({
      where: { key: HUB_LAYOUT_KEY },
    })

    return NextResponse.json({
      layout: config?.value ?? {},
    })
  } catch (error) {
    console.error('admin hub-layout GET error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch hub layout' },
      { status: 500 }
    )
  }
}

/**
 * POST /api/admin/hub-layout
 * Save building positions. Body: { layout: { shop: { x, y }, arena: { x, y }, ... } }
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
      where: { key: HUB_LAYOUT_KEY },
      update: {
        value: layout,
        updatedBy: user.id,
      },
      create: {
        key: HUB_LAYOUT_KEY,
        value: layout,
        category: 'ui',
        description: 'Hub map building positions (admin-editable)',
        updatedBy: user.id,
      },
    })

    // Log the action
    await prisma.adminLog.create({
      data: {
        adminId: user.id,
        action: 'update_hub_layout',
        details: layout,
      },
    })

    return NextResponse.json({ layout: config.value })
  } catch (error) {
    console.error('admin hub-layout POST error:', error)
    return NextResponse.json(
      { error: 'Failed to save hub layout' },
      { status: 500 }
    )
  }
}
