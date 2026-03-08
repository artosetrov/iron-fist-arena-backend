import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { cacheDelete } from '@/lib/cache'

// GET — List all connections
export async function GET(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  const connections = await prisma.passiveConnection.findMany({
    include: {
      fromNode: { select: { id: true, name: true, nodeKey: true } },
      toNode: { select: { id: true, name: true, nodeKey: true } },
    },
  })

  return NextResponse.json({ connections })
}

// POST — Create a new connection
export async function POST(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  try {
    const body = await req.json()
    const { from_id, to_id } = body

    if (!from_id || !to_id) {
      return NextResponse.json({ error: 'from_id and to_id are required' }, { status: 400 })
    }

    if (from_id === to_id) {
      return NextResponse.json({ error: 'Cannot connect a node to itself' }, { status: 400 })
    }

    const connection = await prisma.passiveConnection.create({
      data: { fromId: from_id, toId: to_id },
      include: {
        fromNode: { select: { name: true, nodeKey: true } },
        toNode: { select: { name: true, nodeKey: true } },
      },
    })

    cacheDelete('passives:tree')
    return NextResponse.json({ connection }, { status: 201 })
  } catch (error: unknown) {
    if (error instanceof Error && error.message.includes('Unique constraint')) {
      return NextResponse.json({ error: 'Connection already exists' }, { status: 409 })
    }
    console.error('admin create connection error:', error)
    return NextResponse.json({ error: 'Failed to create connection' }, { status: 500 })
  }
}

// DELETE — Delete a connection
export async function DELETE(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  const id = req.nextUrl.searchParams.get('id')
  if (!id) {
    return NextResponse.json({ error: 'id query param required' }, { status: 400 })
  }

  try {
    await prisma.passiveConnection.delete({ where: { id } })
    cacheDelete('passives:tree')
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('admin delete connection error:', error)
    return NextResponse.json({ error: 'Failed to delete connection' }, { status: 500 })
  }
}
