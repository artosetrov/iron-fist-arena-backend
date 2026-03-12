import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

export async function PUT(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  // Only admins can change roles
  if (admin.role !== 'admin') {
    return NextResponse.json({ error: 'Only admins can change roles' }, { status: 403 })
  }

  try {
    const body = await req.json()
    const { userId, role } = body

    if (!userId || !role) {
      return NextResponse.json({ error: 'Missing userId or role' }, { status: 400 })
    }

    const validRoles = ['admin', 'moderator', 'developer', 'player']
    if (!validRoles.includes(role)) {
      return NextResponse.json({ error: 'Invalid role' }, { status: 400 })
    }

    await prisma.user.update({
      where: { id: userId },
      data: { role },
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to update role'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}
