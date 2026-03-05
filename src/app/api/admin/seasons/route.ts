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
    const { number, theme, startAt, endAt } = body

    if (number == null || !startAt || !endAt) {
      return NextResponse.json(
        { error: 'number, startAt, and endAt are required' },
        { status: 400 }
      )
    }

    const season = await prisma.season.create({
      data: {
        number,
        theme: theme || null,
        startAt: new Date(startAt),
        endAt: new Date(endAt),
      },
    })

    return NextResponse.json({ season })
  } catch (error) {
    console.error('admin seasons error:', error)
    return NextResponse.json(
      { error: 'Failed to create season' },
      { status: 500 }
    )
  }
}
