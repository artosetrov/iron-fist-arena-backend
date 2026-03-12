import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const existing = await prisma.user.findUnique({ where: { id: user.id } })
    if (existing) {
      return NextResponse.json({ user: existing })
    }

    const randomDigits = Math.floor(1000 + Math.random() * 9000)
    const guestUsername = `Guest${randomDigits}`

    const dbUser = await prisma.user.create({
      data: {
        id: user.id,
        username: guestUsername,
        authProvider: 'anonymous',
      },
    })

    return NextResponse.json({ user: dbUser })
  } catch (error) {
    console.error('guest auth error:', error)
    return NextResponse.json(
      { error: 'Failed to create guest user' },
      { status: 500 }
    )
  }
}
