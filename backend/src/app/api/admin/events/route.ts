import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
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
