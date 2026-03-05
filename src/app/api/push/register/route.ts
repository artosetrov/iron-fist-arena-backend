import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { platform, token } = body

    if (!platform || !token) {
      return NextResponse.json(
        { error: 'platform and token are required' },
        { status: 400 }
      )
    }

    // Deactivate old tokens for this user+platform that differ from the new one
    await prisma.pushToken.updateMany({
      where: {
        userId: user.id,
        platform,
        token: { not: token },
      },
      data: { isActive: false },
    })

    // Upsert the new token
    await prisma.pushToken.upsert({
      where: {
        userId_platform_token: {
          userId: user.id,
          platform,
          token,
        },
      },
      update: { isActive: true },
      create: {
        userId: user.id,
        platform,
        token,
        isActive: true,
      },
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('push register error:', error)
    return NextResponse.json(
      { error: 'Failed to register push token' },
      { status: 500 }
    )
  }
}
