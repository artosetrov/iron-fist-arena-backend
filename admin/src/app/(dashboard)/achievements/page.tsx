import { prisma } from '@/lib/prisma'
import { AchievementsClient } from './achievements-client'

async function getAchievementStats() {
  const results: { achievement_key: string; total_count: string; completed_count: string }[] = await prisma.$queryRaw`
    SELECT
      achievement_key,
      COUNT(*)::text as total_count,
      COUNT(*) FILTER (WHERE completed = true)::text as completed_count
    FROM achievements
    GROUP BY achievement_key
    ORDER BY achievement_key ASC
  `

  return results.map((r) => ({
    achievementKey: r.achievement_key,
    totalCount: parseInt(r.total_count, 10),
    completedCount: parseInt(r.completed_count, 10),
    completionRate: parseInt(r.total_count, 10) > 0
      ? Math.round((parseInt(r.completed_count, 10) / parseInt(r.total_count, 10)) * 100)
      : 0,
  }))
}

async function getOverallStats() {
  const result: { total: string; completed: string }[] = await prisma.$queryRaw`
    SELECT
      COUNT(*)::text as total,
      COUNT(*) FILTER (WHERE completed = true)::text as completed
    FROM achievements
  `

  const total = parseInt(result[0]?.total ?? '0', 10)
  const completed = parseInt(result[0]?.completed ?? '0', 10)

  return {
    totalAchievements: total,
    completedAchievements: completed,
    overallCompletionRate: total > 0 ? Math.round((completed / total) * 100) : 0,
  }
}

export default async function AchievementsPage() {
  const [stats, overall] = await Promise.all([
    getAchievementStats(),
    getOverallStats(),
  ])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Achievements</h1>
        <p className="text-muted-foreground">
          Overview of achievement statistics across all players.
        </p>
      </div>
      <AchievementsClient stats={stats} overall={overall} />
    </div>
  )
}
