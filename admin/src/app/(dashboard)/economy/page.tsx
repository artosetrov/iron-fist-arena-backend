import { prisma } from '@/lib/prisma'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Coins, Gem, ShoppingBag, TrendingUp } from 'lucide-react'
import Link from 'next/link'

async function getEconomyData() {
  const [
    goldAgg,
    gemsAgg,
    iapAgg,
    iapByProduct,
    topGoldHolders,
    recentTransactions,
  ] = await Promise.all([
    prisma.character.aggregate({ _sum: { gold: true }, _avg: { gold: true } }),
    prisma.user.aggregate({ _sum: { gems: true }, _avg: { gems: true } }),
    prisma.iapTransaction.aggregate({
      where: { status: 'verified' },
      _sum: { gemsAwarded: true },
      _count: true,
    }),
    prisma.iapTransaction.groupBy({
      by: ['productId'],
      where: { status: 'verified' },
      _count: true,
      _sum: { gemsAwarded: true },
      orderBy: { _count: { productId: 'desc' } },
    }),
    prisma.character.findMany({
      orderBy: { gold: 'desc' },
      take: 10,
      select: {
        id: true,
        characterName: true,
        gold: true,
        level: true,
        user: { select: { id: true, username: true, email: true } },
      },
    }),
    prisma.iapTransaction.findMany({
      orderBy: { createdAt: 'desc' },
      take: 30,
      select: {
        id: true,
        productId: true,
        transactionId: true,
        gemsAwarded: true,
        status: true,
        createdAt: true,
        user: { select: { id: true, username: true, email: true } },
      },
    }),
  ])

  return { goldAgg, gemsAgg, iapAgg, iapByProduct, topGoldHolders, recentTransactions }
}

function formatDate(date: Date | string) {
  return new Date(date).toLocaleString('en-GB', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}

export default async function EconomyPage() {
  const { goldAgg, gemsAgg, iapAgg, iapByProduct, topGoldHolders, recentTransactions } =
    await getEconomyData()

  const totalGold = goldAgg._sum.gold ?? 0
  const totalGems = gemsAgg._sum.gems ?? 0
  const totalGemsFromIap = iapAgg._sum.gemsAwarded ?? 0
  const totalIapTxns = iapAgg._count

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Economy</h1>
        <p className="text-muted-foreground">Gold, gems, and in-app purchase overview.</p>
      </div>

      {/* Summary Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Gold in Circulation</CardTitle>
            <Coins className="h-4 w-4 text-amber-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalGold.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Avg: {Math.round(goldAgg._avg.gold ?? 0).toLocaleString()} per character
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Gems in Circulation</CardTitle>
            <Gem className="h-4 w-4 text-purple-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalGems.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Avg: {Math.round(gemsAgg._avg.gems ?? 0).toLocaleString()} per account
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Gems from IAP</CardTitle>
            <TrendingUp className="h-4 w-4 text-green-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalGemsFromIap.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">
              From {totalIapTxns} verified transactions
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">IAP Transactions</CardTitle>
            <ShoppingBag className="h-4 w-4 text-blue-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalIapTxns.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">Verified purchases</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Top Gold Holders */}
        <Card>
          <CardHeader>
            <CardTitle>Top Gold Holders</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">#</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Character</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Level</th>
                  <th className="px-4 py-3 text-right font-medium text-muted-foreground">Gold</th>
                </tr>
              </thead>
              <tbody>
                {topGoldHolders.map((char, i) => (
                  <tr key={char.id} className="border-b border-border">
                    <td className="px-4 py-3 text-muted-foreground">{i + 1}</td>
                    <td className="px-4 py-3">
                      {char.user?.id ? (
                        <Link href={`/players/${char.user.id}`} className="font-medium text-primary hover:underline">
                          {char.characterName}
                        </Link>
                      ) : (
                        <span className="font-medium">{char.characterName}</span>
                      )}
                      {char.user && (
                        <p className="text-xs text-muted-foreground">
                          {char.user.username || char.user.email || 'Guest'}
                        </p>
                      )}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">{char.level}</td>
                    <td className="px-4 py-3 text-right font-medium text-amber-400">
                      {char.gold.toLocaleString()}
                    </td>
                  </tr>
                ))}
                {topGoldHolders.length === 0 && (
                  <tr>
                    <td colSpan={4} className="px-4 py-6 text-center text-muted-foreground">No data.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </CardContent>
        </Card>

        {/* IAP by Product */}
        <Card>
          <CardHeader>
            <CardTitle>IAP by Product</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Product</th>
                  <th className="px-4 py-3 text-right font-medium text-muted-foreground">Count</th>
                  <th className="px-4 py-3 text-right font-medium text-muted-foreground">Gems Sold</th>
                </tr>
              </thead>
              <tbody>
                {iapByProduct.map((row) => (
                  <tr key={row.productId} className="border-b border-border">
                    <td className="px-4 py-3 font-medium">{row.productId}</td>
                    <td className="px-4 py-3 text-right text-muted-foreground">{row._count}</td>
                    <td className="px-4 py-3 text-right font-medium text-purple-400">
                      {(row._sum.gemsAwarded ?? 0).toLocaleString()}
                    </td>
                  </tr>
                ))}
                {iapByProduct.length === 0 && (
                  <tr>
                    <td colSpan={3} className="px-4 py-6 text-center text-muted-foreground">No IAP data.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </CardContent>
        </Card>
      </div>

      {/* Recent IAP Transactions */}
      <Card>
        <CardHeader>
          <CardTitle>Recent IAP Transactions (last 30)</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="rounded-b-lg overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">User</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Product</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Transaction ID</th>
                  <th className="px-4 py-3 text-right font-medium text-muted-foreground">Gems</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Date</th>
                </tr>
              </thead>
              <tbody>
                {recentTransactions.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-4 py-8 text-center text-muted-foreground">No transactions.</td>
                  </tr>
                ) : (
                  recentTransactions.map((txn) => (
                    <tr key={txn.id} className="border-b border-border hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3">
                        {txn.user?.id ? (
                          <Link href={`/players/${txn.user.id}`} className="text-primary hover:underline">
                            {txn.user.username || txn.user.email || 'Unknown'}
                          </Link>
                        ) : (
                          <span className="text-muted-foreground">Unknown</span>
                        )}
                      </td>
                      <td className="px-4 py-3 font-medium">{txn.productId}</td>
                      <td className="px-4 py-3 font-mono text-xs text-muted-foreground truncate max-w-[120px]">
                        {txn.transactionId}
                      </td>
                      <td className="px-4 py-3 text-right font-medium text-purple-400">
                        +{txn.gemsAwarded.toLocaleString()}
                      </td>
                      <td className="px-4 py-3">
                        <Badge variant={txn.status === 'verified' ? 'success' : 'warning'}>
                          {txn.status}
                        </Badge>
                      </td>
                      <td className="px-4 py-3 text-xs text-muted-foreground whitespace-nowrap">
                        {formatDate(txn.createdAt)}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
