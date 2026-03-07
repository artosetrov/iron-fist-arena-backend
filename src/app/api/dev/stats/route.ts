import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/dev/stats
 * Returns aggregate game statistics for development monitoring.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const dbUser = await prisma.user.findUnique({ where: { id: user.id } })
  if (!dbUser || !['admin', 'dev'].includes(dbUser.role)) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  try {
    const [
      totalUsers,
      totalCharacters,
      totalMatches,
      totalDungeonRuns,
      totalAchievements,
      dailyLoginStats,
      iapStats,
      topRankedCharacters,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.character.count(),
      prisma.pvpMatch.count(),
      prisma.dungeonRun.count(),
      prisma.achievement.count({ where: { completed: true } }),
      prisma.dailyLoginReward.aggregate({ _sum: { totalClaims: true }, _avg: { streak: true } }),
      prisma.iapTransaction.count({ where: { status: 'verified' } }),
      prisma.character.findMany({
        select: { characterName: true, pvpRating: true, pvpWins: true, pvpLosses: true, level: true },
        orderBy: { pvpRating: 'desc' },
        take: 5,
      }),
    ])

    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    const activeCharacters = await prisma.character.count({
      where: { lastPlayed: { gte: sevenDaysAgo } },
    })

    return NextResponse.json({
      users: { total: totalUsers },
      characters: { total: totalCharacters, active_last_7_days: activeCharacters },
      pvp: { total_matches: totalMatches, top_ranked: topRankedCharacters },
      dungeons: { total_runs: totalDungeonRuns },
      achievements: { total_completed: totalAchievements },
      daily_login: {
        total_claims: dailyLoginStats._sum.totalClaims ?? 0,
        avg_streak: Math.round((dailyLoginStats._avg.streak ?? 0) * 10) / 10,
      },
      iap: { verified_transactions: iapStats },
    })
  } catch (error) {
    console.error('dev stats error:', error)
    return NextResponse.json({ error: 'Failed to fetch stats' }, { status: 500 })
  }
}
