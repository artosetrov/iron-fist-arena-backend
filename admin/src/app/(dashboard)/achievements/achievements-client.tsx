'use client'

import { useState, useMemo } from 'react'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Search, Trophy, Target, TrendingUp } from 'lucide-react'

type AchievementStat = {
  achievementKey: string
  totalCount: number
  completedCount: number
  completionRate: number
}

type OverallStats = {
  totalAchievements: number
  completedAchievements: number
  overallCompletionRate: number
}

export function AchievementsClient({
  stats,
  overall,
}: {
  stats: AchievementStat[]
  overall: OverallStats
}) {
  const [search, setSearch] = useState('')

  const filtered = useMemo(() => {
    if (!search) return stats
    return stats.filter((s) =>
      s.achievementKey.toLowerCase().includes(search.toLowerCase())
    )
  }, [stats, search])

  const uniqueKeys = stats.length

  return (
    <>
      {/* Summary Cards */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Unique Achievements
            </CardTitle>
            <Trophy className="h-4 w-4 text-amber-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{uniqueKeys}</div>
            <p className="text-xs text-muted-foreground">defined achievement keys</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Earned
            </CardTitle>
            <Target className="h-4 w-4 text-green-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{overall.completedAchievements.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">of {overall.totalAchievements.toLocaleString()} tracked</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Completion Rate
            </CardTitle>
            <TrendingUp className="h-4 w-4 text-purple-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{overall.overallCompletionRate}%</div>
            <p className="text-xs text-muted-foreground">across all players</p>
          </CardContent>
        </Card>
      </div>

      {/* Search */}
      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          placeholder="Filter achievements..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="pl-9"
        />
      </div>

      {/* Table */}
      <div className="rounded-lg border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/50">
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Achievement Key</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Total Tracked</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Completed</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Completion %</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Progress</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-muted-foreground">
                  No achievements found.
                </td>
              </tr>
            ) : (
              filtered.map((stat) => (
                <tr key={stat.achievementKey} className="border-b border-border hover:bg-muted/30 transition-colors">
                  <td className="px-4 py-3 font-mono text-sm">{stat.achievementKey}</td>
                  <td className="px-4 py-3">{stat.totalCount.toLocaleString()}</td>
                  <td className="px-4 py-3">{stat.completedCount.toLocaleString()}</td>
                  <td className="px-4 py-3 font-medium">
                    <span className={
                      stat.completionRate >= 75 ? 'text-green-400' :
                      stat.completionRate >= 50 ? 'text-amber-400' :
                      stat.completionRate >= 25 ? 'text-orange-400' :
                      'text-red-400'
                    }>
                      {stat.completionRate}%
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <div className="h-2 flex-1 max-w-[120px] rounded-full bg-muted overflow-hidden">
                        <div
                          className="h-full rounded-full bg-primary transition-all"
                          style={{ width: `${stat.completionRate}%` }}
                        />
                      </div>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <p className="text-sm text-muted-foreground">
        Showing {filtered.length} of {stats.length} achievement types
      </p>
    </>
  )
}
