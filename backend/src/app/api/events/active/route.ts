import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    const now = new Date()

    const events = await prisma.event.findMany({
      where: {
        isActive: true,
        startAt: { lte: now },
        endAt: { gte: now },
      },
      orderBy: { startAt: 'asc' },
    })

    return NextResponse.json({ events })
  } catch (error) {
    console.error('active events error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch active events' },
      { status: 500 }
    )
  }
}
