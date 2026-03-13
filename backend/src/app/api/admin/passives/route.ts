import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { cacheDelete } from '@/lib/cache'

// GET — List all passive nodes with connections
export async function GET(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  const [nodes, connections] = await Promise.all([
    prisma.passiveNode.findMany({
      orderBy: [{ tier: 'asc' }, { name: 'asc' }],
    }),
    prisma.passiveConnection.findMany({
      include: {
        fromNode: { select: { name: true, nodeKey: true } },
        toNode: { select: { name: true, nodeKey: true } },
      },
    }),
  ])

  return NextResponse.json({ nodes, connections })
}

// POST — Create a new passive node
export async function POST(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  try {
    const body = await req.json()
    const {
      node_key, name, description, bonus_type, bonus_stat,
      bonus_value, tier, position_x, position_y, cost,
      icon, class_restriction, is_start_node, is_active,
    } = body

    if (!node_key || !name || !bonus_type || bonus_value === undefined) {
      return NextResponse.json(
        { error: 'node_key, name, bonus_type, and bonus_value are required' },
        { status: 400 },
      )
    }

    const node = await prisma.passiveNode.create({
      data: {
        nodeKey: node_key,
        name,
        description: description ?? null,
        bonusType: bonus_type,
        bonusStat: bonus_stat ?? null,
        bonusValue: bonus_value,
        tier: tier ?? 1,
        positionX: position_x ?? 0,
        positionY: position_y ?? 0,
        cost: cost ?? 1,
        icon: icon ?? null,
        classRestriction: class_restriction ?? null,
        isStartNode: is_start_node ?? false,
        isActive: is_active ?? true,
      },
    })

    await cacheDelete('passives:tree')
    return NextResponse.json({ node }, { status: 201 })
  } catch (error: unknown) {
    if (error instanceof Error && error.message.includes('Unique constraint')) {
      return NextResponse.json({ error: 'Node key already exists' }, { status: 409 })
    }
    console.error('admin create passive node error:', error)
    return NextResponse.json({ error: 'Failed to create passive node' }, { status: 500 })
  }
}

// PUT — Update a passive node
export async function PUT(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  try {
    const body = await req.json()
    const { id, ...updates } = body

    if (!id) {
      return NextResponse.json({ error: 'id is required' }, { status: 400 })
    }

    const dataMap: Record<string, string> = {
      node_key: 'nodeKey', name: 'name', description: 'description',
      bonus_type: 'bonusType', bonus_stat: 'bonusStat', bonus_value: 'bonusValue',
      tier: 'tier', position_x: 'positionX', position_y: 'positionY',
      cost: 'cost', icon: 'icon', class_restriction: 'classRestriction',
      is_start_node: 'isStartNode', is_active: 'isActive',
    }

    const data: Record<string, unknown> = {}
    for (const [snakeKey, prismaKey] of Object.entries(dataMap)) {
      if (updates[snakeKey] !== undefined) {
        data[prismaKey] = updates[snakeKey]
      }
    }

    const node = await prisma.passiveNode.update({ where: { id }, data })

    await cacheDelete('passives:tree')
    return NextResponse.json({ node })
  } catch (error) {
    console.error('admin update passive node error:', error)
    return NextResponse.json({ error: 'Failed to update passive node' }, { status: 500 })
  }
}

// DELETE — Delete a passive node (cascades connections)
export async function DELETE(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  const id = req.nextUrl.searchParams.get('id')
  if (!id) {
    return NextResponse.json({ error: 'id query param required' }, { status: 400 })
  }

  try {
    await prisma.passiveNode.delete({ where: { id } })
    await cacheDelete('passives:tree')
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('admin delete passive node error:', error)
    return NextResponse.json({ error: 'Failed to delete passive node' }, { status: 500 })
  }
}
