import { prisma } from '@/lib/prisma'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Swords, Trophy, Zap } from 'lucide-react'
import Link from 'next/link'

async function getMatchStats() {
  const now = new Date()
  const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate())

  const [total, today, revenge] = await Promise.all([
    prisma.pvpMatch.count(),
    prisma.pvpMatch.count({ where: { playedAt: { gte: startOfDay } } }),
    prisma.pvpMatch.count({ where: { isRevenge: true } }),
  ])

  return { total, today, revenge }
}

async function getMatches() {
  return prisma.pvpMatch.findMany({
    orderBy: { playedAt: 'desc' },
    take: 100,
    select: {
      id: true,
      player1Id: true,
      player2Id: true,
      winnerId: true,
      player1RatingBefore: true,
      player1RatingAfter: true,
      player2RatingBefore: true,
      player2RatingAfter: true,
      goldReward: true,
      xpReward: true,
      matchType: true,
      isRevenge: true,
      turnsTaken: true,
      seasonNumber: true,
      playedAt: true,
      player1: { select: { characterName: true, user: { select: { id: true } } } },
      player2: { select: { characterName: true, user: { select: { id: true } } } },
    },
  })
}

function formatDate(date: Date | string) {
  return new Date(date).toLocaleString('en-GB', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}

export default async function MatchesPage() {
  const [stats, matches] = await Promise.all([getMatchStats(), getMatches()])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Arena Matches</h1>
        <p className="text-muted-foreground">PvP match history across all players.</p>
      </div>

      {/* Stats */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Matches</CardTitle>
            <Swords className="h-4 w-4 text-purple-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.total.toLocaleString()}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Matches Today</CardTitle>
            <Trophy className="h-4 w-4 text-amber-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.today.toLocaleString()}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Revenge Matches</CardTitle>
            <Zap className="h-4 w-4 text-orange-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.revenge.toLocaleString()}</div>
          </CardContent>
        </Card>
      </div>

      {/* Match Table */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Matches (last 100)</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="rounded-b-lg overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Players</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Type</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Result</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">P1 Rating</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">P2 Rating</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Rewards</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Turns</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Date</th>
                </tr>
              </thead>
              <tbody>
                {matches.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="px-4 py-8 text-center text-muted-foreground">No matches yet.</td>
                  </tr>
                ) : (
                  matches.map((match) => {
                    const p1Delta = match.player1RatingAfter - match.player1RatingBefore
                    const p2Delta = match.player2RatingAfter - match.player2RatingBefore

                    return (
                      <tr key={match.id} className="border-b border-border hover:bg-muted/30 transition-colors">
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-1 flex-wrap">
                            {match.player1.user?.id ? (
                              <Link
                                href={`/players/${match.player1.user.id}`}
                                className="font-medium text-primary hover:underline"
                              >
                                {match.player1.characterName}
                              </Link>
                            ) : (
                              <span className="font-medium">{match.player1.characterName}</span>
                            )}
                            <span className="text-muted-foreground">vs</span>
                            {match.player2.user?.id ? (
                              <Link
                                href={`/players/${match.player2.user.id}`}
                                className="font-medium text-primary hover:underline"
                              >
                                {match.player2.characterName}
                              </Link>
                            ) : (
                              <span className="font-medium">{match.player2.characterName}</span>
                            )}
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex gap-1">
                            <Badge variant="secondary">{match.matchType}</Badge>
                            {match.isRevenge && <Badge variant="warning">Revenge</Badge>}
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          {match.winnerId === match.player1Id ? (
                            <span className="text-xs"><Badge variant="success">P1 Win</Badge></span>
                          ) : match.winnerId === match.player2Id ? (
                            <span className="text-xs"><Badge variant="destructive">P2 Win</Badge></span>
                          ) : (
                            <Badge variant="secondary">Draw</Badge>
                          )}
                        </td>
                        <td className="px-4 py-3 font-mono text-xs">
                          {match.player1RatingBefore}{' '}
                          <span className={p1Delta >= 0 ? 'text-green-400' : 'text-red-400'}>
                            ({p1Delta >= 0 ? '+' : ''}{p1Delta})
                          </span>
                        </td>
                        <td className="px-4 py-3 font-mono text-xs">
                          {match.player2RatingBefore}{' '}
                          <span className={p2Delta >= 0 ? 'text-green-400' : 'text-red-400'}>
                            ({p2Delta >= 0 ? '+' : ''}{p2Delta})
                          </span>
                        </td>
                        <td className="px-4 py-3 text-xs text-muted-foreground">
                          {match.goldReward}g / {match.xpReward}xp
                        </td>
                        <td className="px-4 py-3 text-xs text-muted-foreground">
                          {match.turnsTaken}
                        </td>
                        <td className="px-4 py-3 text-xs text-muted-foreground whitespace-nowrap">
                          {formatDate(match.playedAt)}
                        </td>
                      </tr>
                    )
                  })
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
