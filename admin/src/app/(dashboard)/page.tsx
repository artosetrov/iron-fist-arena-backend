import { prisma } from '@/lib/prisma'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Users, Swords, Trophy, DollarSign } from 'lucide-react'
import { RegistrationChart } from './registration-chart'

async function getStats() {
  const [totalPlayers, activeCharacters, pvpMatches, totalTransactions] =
    await Promise.all([
      prisma.user.count(),
      prisma.character.count(),
      prisma.pvpMatch.count(),
      prisma.iapTransaction.count({
        where: { status: 'verified' },
      }),
    ])

  return { totalPlayers, activeCharacters, pvpMatches, totalTransactions }
}

async function getRegistrationData() {
  const thirtyDaysAgo = new Date()
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)

  const users = await prisma.user.findMany({
    where: { createdAt: { gte: thirtyDaysAgo } },
    select: { createdAt: true },
    orderBy: { createdAt: 'asc' },
  })

  const dailyCounts = new Map<string, number>()

  for (let d = new Date(thirtyDaysAgo); d <= new Date(); d.setDate(d.getDate() + 1)) {
    const key = d.toISOString().split('T')[0]
    dailyCounts.set(key, 0)
  }

  for (const user of users) {
    const key = user.createdAt.toISOString().split('T')[0]
    dailyCounts.set(key, (dailyCounts.get(key) || 0) + 1)
  }

  return Array.from(dailyCounts.entries()).map(([date, count]) => ({
    date,
    registrations: count,
  }))
}

const statCards = [
  { label: 'Total Players', key: 'totalPlayers' as const, icon: Users, color: 'text-blue-400' },
  { label: 'Active Characters', key: 'activeCharacters' as const, icon: Swords, color: 'text-green-400' },
  { label: 'PvP Matches', key: 'pvpMatches' as const, icon: Trophy, color: 'text-purple-400' },
  { label: 'Total Revenue', key: 'totalTransactions' as const, icon: DollarSign, color: 'text-amber-400' },
]

export default async function DashboardPage() {
  const [stats, registrationData] = await Promise.all([
    getStats(),
    getRegistrationData(),
  ])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">
          Overview of Hexbound game metrics.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {statCards.map((card) => {
          const Icon = card.icon
          const value = stats[card.key]
          return (
            <Card key={card.key}>
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  {card.label}
                </CardTitle>
                <Icon className={`h-4 w-4 ${card.color}`} />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {card.key === 'totalTransactions'
                    ? `${value.toLocaleString()} txns`
                    : value.toLocaleString()}
                </div>
              </CardContent>
            </Card>
          )
        })}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Player Registrations (Last 30 Days)</CardTitle>
        </CardHeader>
        <CardContent>
          <RegistrationChart data={registrationData} />
        </CardContent>
      </Card>
    </div>
  )
}
