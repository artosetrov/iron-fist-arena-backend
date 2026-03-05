import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
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

    const [totalUsers, totalCharacters, totalPvpMatches, avgLevel] =
      await Promise.all([
        prisma.user.count(),
        prisma.character.count(),
        prisma.pvpMatch.count(),
        prisma.character.aggregate({
          _avg: { level: true },
        }),
      ])

    return NextResponse.json({
      stats: {
        totalUsers,
        totalCharacters,
        totalPvpMatches,
        averageLevel: avgLevel._avg.level ?? 0,
      },
    })
  } catch (error) {
    console.error('admin stats error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch stats' },
      { status: 500 }
    )
  }
}
