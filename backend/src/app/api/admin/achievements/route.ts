import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/admin/achievements
 * Returns achievement completion statistics across all characters.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const [byKey, recentlyCompleted, totalAchievements, totalCompleted, totalClaimed] =
      await Promise.all([
        prisma.achievement.groupBy({
          by: ['achievementKey'],
          _count: { _all: true },
          where: { completed: true },
          orderBy: { _count: { achievementKey: 'desc' } },
        }),
        prisma.achievement.findMany({
          where: { completed: true },
          select: {
            achievementKey: true,
            completedAt: true,
            rewardClaimed: true,
            character: { select: { characterName: true, level: true } },
          },
          orderBy: { completedAt: 'desc' },
          take: 50,
        }),
        prisma.achievement.count(),
        prisma.achievement.count({ where: { completed: true } }),
        prisma.achievement.count({
          where: { completed: true, rewardClaimed: true },
        }),
      ])

    return NextResponse.json({
      stats: {
        total: totalAchievements,
        completed: totalCompleted,
        claimed: totalClaimed,
        completion_rate: totalAchievements > 0
          ? Math.round((totalCompleted / totalAchievements) * 100)
          : 0,
      },
      by_achievement: byKey.map((a) => ({
        achievement_key: a.achievementKey,
        completed_count: a._count._all,
      })),
      recently_completed: recentlyCompleted,
    })
  } catch (error) {
    console.error('admin achievements error:', error)
    return NextResponse.json({ error: 'Failed to fetch achievement stats' }, { status: 500 })
  }
}
