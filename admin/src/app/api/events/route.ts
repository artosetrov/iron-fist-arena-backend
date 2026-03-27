import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

// GET — list all events (paginated, newest first)
export async function GET(req: NextRequest) {
  try {
    const page = parseInt(req.nextUrl.searchParams.get('page') ?? '1')
    const limit = parseInt(req.nextUrl.searchParams.get('limit') ?? '20')
    const activeOnly = req.nextUrl.searchParams.get('active') === 'true'

    const where = activeOnly ? { isActive: true } : {}

    const [events, total] = await Promise.all([
      prisma.event.findMany({
        where,
        orderBy: { startAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.event.count({ where }),
    ])

    return NextResponse.json({ events, total, page, limit })
  } catch (error) {
    console.error('admin events list error:', error)
    return NextResponse.json({ error: 'Failed to fetch events' }, { status: 500 })
  }
}

// POST — create a new event
export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { eventKey, title, description, eventType, config, startAt, endAt, isActive } = body

    if (!eventKey || !title || !eventType || !startAt || !endAt) {
      return NextResponse.json(
        { error: 'eventKey, title, eventType, startAt, endAt are required' },
        { status: 400 }
      )
    }

    // Validate event type
    const validTypes = ['boss_rush', 'gold_rush', 'double_xp', 'drop_rate_boost', 'class_spotlight', 'tournament', 'weekend_warrior']
    if (!validTypes.includes(eventType)) {
      return NextResponse.json({ error: `Invalid eventType. Valid: ${validTypes.join(', ')}` }, { status: 400 })
    }

    // Validate dates
    const start = new Date(startAt)
    const end = new Date(endAt)
    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      return NextResponse.json({ error: 'Invalid date format' }, { status: 400 })
    }
    if (end <= start) {
      return NextResponse.json({ error: 'endAt must be after startAt' }, { status: 400 })
    }

    const event = await prisma.event.create({
      data: {
        eventKey,
        title,
        description: description ?? '',
        eventType,
        config: config ?? {},
        startAt: start,
        endAt: end,
        isActive: isActive ?? true,
      },
    })

    return NextResponse.json({ event }, { status: 201 })
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : 'Unknown error'
    if (msg.includes('Unique constraint')) {
      return NextResponse.json({ error: 'Event with this key already exists' }, { status: 409 })
    }
    console.error('admin create event error:', error)
    return NextResponse.json({ error: 'Failed to create event' }, { status: 500 })
  }
}

// PATCH — update an existing event
export async function PATCH(req: NextRequest) {
  try {
    const body = await req.json()
    const { id, ...updates } = body

    if (!id) {
      return NextResponse.json({ error: 'Event id is required' }, { status: 400 })
    }

    // Convert date strings
    if (updates.startAt) updates.startAt = new Date(updates.startAt)
    if (updates.endAt) updates.endAt = new Date(updates.endAt)

    const event = await prisma.event.update({
      where: { id },
      data: updates,
    })

    return NextResponse.json({ event })
  } catch (error) {
    console.error('admin update event error:', error)
    return NextResponse.json({ error: 'Failed to update event' }, { status: 500 })
  }
}

// DELETE — deactivate an event (soft delete)
export async function DELETE(req: NextRequest) {
  try {
    const id = req.nextUrl.searchParams.get('id')
    if (!id) {
      return NextResponse.json({ error: 'Event id is required' }, { status: 400 })
    }

    const event = await prisma.event.update({
      where: { id },
      data: { isActive: false },
    })

    return NextResponse.json({ event })
  } catch (error) {
    console.error('admin delete event error:', error)
    return NextResponse.json({ error: 'Failed to deactivate event' }, { status: 500 })
  }
}
