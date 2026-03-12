import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
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
