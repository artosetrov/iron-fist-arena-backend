import { NextRequest, NextResponse } from 'next/server'
import { invalidateBanCache } from '@/lib/auth'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const body = await req.json()
    const { user_id } = body

    if (!user_id) {
      return NextResponse.json(
        { error: 'user_id is required' },
        { status: 400 }
      )
    }

    const targetUser = await prisma.user.findUnique({
      where: { id: user_id },
      select: { id: true },
    })

    if (!targetUser) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    await prisma.user.update({
      where: { id: user_id },
      data: {
        isBanned: false,
        banReason: null,
      },
    })

    // Invalidate ban cache so the unban takes effect immediately
    invalidateBanCache(user_id)

    return NextResponse.json({ success: true, user_id, banned: false })
  } catch (error) {
    console.error('admin unban error:', error)
    return NextResponse.json(
      { error: 'Failed to unban user' },
      { status: 500 }
    )
  }
}
