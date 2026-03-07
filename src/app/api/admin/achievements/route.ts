import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

async function requireAdmin(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return null
  const dbUser = await prisma.user.findUnique({ where: { id: user.id } })
  if (!dbUser || dbUser.role !== 'admin') return null
  return user
}

/**
 * GET /api/admin/achievements
 * Returns achievement completion statistics across all characters.
 */
export async function GET(req: NextRequest) {
  const user = await requireAdmin(req)
  if (!user) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

  try {
    const [byKey, recentlyCompleted] = await Promise.all([
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
    ])

    const totalAchievements = await prisma.achievement.count()
    const totalCompleted = await prisma.achievement.count({ where: { completed: true } })
    const totalClaimed = await prisma.achievement.count({
      where: { completed: true, rewardClaimed: true },
    })

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
