import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
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
