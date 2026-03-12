import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { token } = body

    if (!token) {
      return NextResponse.json(
        { error: 'token is required' },
        { status: 400 }
      )
    }

    await prisma.pushToken.updateMany({
      where: {
        userId: user.id,
        token,
      },
      data: { isActive: false },
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('push unregister error:', error)
    return NextResponse.json(
      { error: 'Failed to unregister push token' },
      { status: 500 }
    )
  }
}
