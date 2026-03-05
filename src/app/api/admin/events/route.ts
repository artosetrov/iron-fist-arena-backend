import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    // Verify admin role
    const dbUser = await prisma.user.findUnique({
      where: { id: user.id },
    })

    if (!dbUser || dbUser.role !== 'admin') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const body = await req.json()
    const { eventKey, title, description, eventType, config, startAt, endAt } = body

    if (!eventKey || !title || !description || !eventType || !startAt || !endAt) {
      return NextResponse.json(
        { error: 'eventKey, title, description, eventType, startAt, and endAt are required' },
        { status: 400 }
      )
    }

    const event = await prisma.event.create({
      data: {
        eventKey,
        title,
        description,
        eventType,
        config: config || {},
        startAt: new Date(startAt),
        endAt: new Date(endAt),
        isActive: true,
      },
    })

    return NextResponse.json({ event })
  } catch (error) {
    console.error('admin events error:', error)
    return NextResponse.json(
      { error: 'Failed to create event' },
      { status: 500 }
    )
  }
}
