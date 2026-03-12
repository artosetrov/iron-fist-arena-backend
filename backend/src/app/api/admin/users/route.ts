import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const { searchParams } = new URL(req.url)
    const skip = Math.max(0, parseInt(searchParams.get('skip') ?? '0', 10) || 0)
    const take = Math.min(100, Math.max(1, parseInt(searchParams.get('take') ?? '100', 10) || 100))

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        select: {
          id: true,
          email: true,
          username: true,
          gems: true,
          role: true,
          isBanned: true,
          banReason: true,
          createdAt: true,
          lastLogin: true,
          _count: {
            select: { characters: true },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take,
      }),
      prisma.user.count(),
    ])

    return NextResponse.json({ users, total, skip, take })
  } catch (error) {
    console.error('admin users error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch users' },
      { status: 500 }
    )
  }
}
