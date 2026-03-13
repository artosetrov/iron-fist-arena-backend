import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { cacheDelete, cacheDeletePrefix } from '@/lib/cache'

/**
 * GET /api/admin/item-balance/config
 * Returns all item_balance.* config values.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const configs = await prisma.gameConfig.findMany({
      where: { category: 'item_balance' },
      orderBy: { key: 'asc' },
    })

    return NextResponse.json({
      configs: configs.map((c) => ({
        key: c.key,
        value: c.value,
        category: c.category,
        description: c.description,
        updatedAt: c.updatedAt,
      })),
    })
  } catch (error) {
    console.error('get item balance config error:', error)
    return NextResponse.json({ error: 'Failed to fetch config' }, { status: 500 })
  }
}

/**
 * POST /api/admin/item-balance/config
 * Update a config value. Body: { key, value }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const { key, value } = await req.json()

    if (!key || value === undefined) {
      return NextResponse.json({ error: 'key and value are required' }, { status: 400 })
    }

    if (!key.startsWith('item_balance.')) {
      return NextResponse.json({ error: 'key must start with item_balance.' }, { status: 400 })
    }

    const updated = await prisma.gameConfig.upsert({
      where: { key },
      update: { value },
      create: {
        key,
        value,
        category: 'item_balance',
        description: '',
      },
    })

    // Invalidate cached config so changes take effect immediately
    await cacheDelete(`gameconfig:${key}`)
    await cacheDeletePrefix('gameconfig:batch:')

    // Log the admin action
    await prisma.adminLog.create({
      data: {
        adminId: user.id,
        action: 'update_balance_config',
        details: { key, value },
      },
    })

    return NextResponse.json({
      key: updated.key,
      value: updated.value,
      updatedAt: updated.updatedAt,
    })
  } catch (error) {
    console.error('update item balance config error:', error)
    return NextResponse.json({ error: 'Failed to update config' }, { status: 500 })
  }
}
