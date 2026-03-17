'use client'

import { useState } from 'react'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  Table, TableHeader, TableRow, TableHead, TableBody, TableCell,
} from '@/components/ui/table'
import {
  Coins, Gem, TrendingUp, ShoppingBag, Users, BarChart3,
  AlertTriangle, Crown, Swords,
} from 'lucide-react'
import Link from 'next/link'

type Props = {
  summary: {
    totalCharacters: number
    totalUsers: number
    gold: { total: number; avg: number; min: number; max: number }
    gems: { total: number; avg: number; min: number; max: number }
    iap: { totalGems: number; totalTransactions: number }
    offers: { totalPurchases: number; totalRevenue: number }
  }
  goldByLevel: Array<{ level: number; avgGold: number; totalGold: number; count: number }>
  topGold: Array<{
    id: string; characterName: string; gold: number; level: number; class: string
    user: { id: string; username: string | null; email: string | null } | null
  }>
  topGems: Array<{
    id: string; username: string | null; email: string | null; gems: number
    characters: Array<{ characterName: string; level: number }>
  }>
  iapByProduct: Array<{ productId: string; count: number; totalGems: number }>
  recentTransactions: Array<{
    id: string; productId: string; transactionId: string
    gemsAwarded: number; status: string; createdAt: string
    user: { id: string; username: string | null; email: string | null } | null
  }>
  offerPurchases: Array<{
    offerId: string; title: string; key: string; currency: string
    count: number; totalRevenue: number
  }>
  wealthDistribution: {
    buckets: Array<{
      label: string; playerCount: number; totalGold: number
      avgGold: number; pctOfTotal: number
    }>
    giniCoefficient: number
  }
  byClass: Array<{
    class: string; count: number; avgGold: number
    totalGold: number; avgLevel: number
  }>
}

const classColors: Record<string, string> = {
  warrior: 'text-red-400',
  rogue: 'text-green-400',
  mage: 'text-blue-400',
  tank: 'text-yellow-400',
}

function fmt(n: number) { return n.toLocaleString() }

function fmtDate(d: string) {
  return new Date(d).toLocaleString('en-GB', {
    day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit',
  })
}

function GiniIndicator({ value }: { value: number }) {
  let color = 'text-green-400'
  let label = 'Healthy'
  if (value > 0.6) { color = 'text-red-400'; label = 'Very Unequal' }
  else if (value > 0.45) { color = 'text-yellow-400'; label = 'Moderate' }
  else if (value > 0.3) { color = 'text-amber-400'; label = 'Fair' }

  return (
    <div className="flex items-center gap-2">
      <span className={`text-2xl font-bold ${color}`}>{value.toFixed(3)}</span>
      <Badge className={color.replace('text-', 'bg-').replace('400', '500/20') + ' ' + color}>
        {label}
      </Badge>
    </div>
  )
}

export function EconomyClient(props: Props) {
  const { summary: s, goldByLevel, topGold, topGems, iapByProduct,
    recentTransactions, offerPurchases, wealthDistribution, byClass } = props

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Economy Dashboard</h1>
        <p className="text-muted-foreground">
          Gold &amp; gem flows, wealth distribution, IAP &amp; offers analytics.
        </p>
      </div>

      {/* ── Summary Cards ── */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Gold in Circulation</CardTitle>
            <Coins className="h-4 w-4 text-amber-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-amber-400">{fmt(s.gold.total)}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Avg {fmt(s.gold.avg)} · Min {fmt(s.gold.min)} · Max {fmt(s.gold.max)}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Gems in Circulation</CardTitle>
            <Gem className="h-4 w-4 text-purple-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-purple-400">{fmt(s.gems.total)}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Avg {fmt(s.gems.avg)} · Min {fmt(s.gems.min)} · Max {fmt(s.gems.max)}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">IAP Revenue</CardTitle>
            <TrendingUp className="h-4 w-4 text-green-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-400">{fmt(s.iap.totalGems)} 💎</div>
            <p className="text-xs text-muted-foreground mt-1">
              {fmt(s.iap.totalTransactions)} verified transactions
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Offer Sales</CardTitle>
            <ShoppingBag className="h-4 w-4 text-blue-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-blue-400">{fmt(s.offers.totalPurchases)}</div>
            <p className="text-xs text-muted-foreground mt-1">
              {fmt(s.offers.totalRevenue)} total revenue
            </p>
          </CardContent>
        </Card>
      </div>

      {/* ── Wealth Distribution & Gini ── */}
      <div className="grid gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="h-5 w-5" /> Wealth Distribution (Gold)
            </CardTitle>
          </CardHeader>
          <CardContent>
            {wealthDistribution.buckets.length > 0 ? (
              <div className="space-y-2">
                {wealthDistribution.buckets.map((b) => (
                  <div key={b.label} className="flex items-center gap-3 text-sm">
                    <span className="w-16 text-muted-foreground font-mono text-xs">{b.label}</span>
                    <div className="flex-1 h-6 bg-muted rounded overflow-hidden relative">
                      <div
                        className="h-full bg-amber-500/60 rounded"
                        style={{ width: `${Math.min(b.pctOfTotal * 2, 100)}%` }}
                      />
                      <span className="absolute inset-0 flex items-center px-2 text-xs font-medium">
                        {b.pctOfTotal}% of gold · {fmt(b.avgGold)} avg · {b.playerCount} players
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-muted-foreground text-center py-4">No data</p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5" /> Gini Coefficient
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <GiniIndicator value={wealthDistribution.giniCoefficient} />
            <p className="text-sm text-muted-foreground">
              0 = perfect equality, 1 = one player has everything.
              Mobile RPGs typically aim for 0.3–0.5.
            </p>
            <div className="space-y-2 pt-2 border-t">
              <p className="text-xs font-medium text-muted-foreground uppercase">Population</p>
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Characters</span>
                <span className="font-medium">{fmt(s.totalCharacters)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Users</span>
                <span className="font-medium">{fmt(s.totalUsers)}</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* ── Economy by Class ── */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Swords className="h-5 w-5" /> Economy by Class
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {byClass.map((c) => (
              <div key={c.class} className="border rounded-lg p-4">
                <div className="flex items-center justify-between mb-2">
                  <span className={`font-bold capitalize ${classColors[c.class] ?? 'text-white'}`}>
                    {c.class}
                  </span>
                  <Badge variant="outline">{c.count} players</Badge>
                </div>
                <div className="space-y-1 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Avg Gold</span>
                    <span className="text-amber-400 font-medium">{fmt(c.avgGold)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Total Gold</span>
                    <span>{fmt(c.totalGold)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Avg Level</span>
                    <span>{c.avgLevel}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* ── Tabs: Gold by Level · Top Holders · IAP · Offers ── */}
      <Tabs defaultValue="level">
        <TabsList>
          <TabsTrigger value="level">Gold by Level</TabsTrigger>
          <TabsTrigger value="holders">Top Holders</TabsTrigger>
          <TabsTrigger value="iap">IAP</TabsTrigger>
          <TabsTrigger value="offers">Offer Sales</TabsTrigger>
        </TabsList>

        {/* Gold by Level */}
        <TabsContent value="level">
          <Card>
            <CardContent className="pt-4">
              <div className="space-y-1">
                {goldByLevel.map((row) => (
                  <div key={row.level} className="flex items-center gap-3 text-sm">
                    <span className="w-12 text-right font-mono text-muted-foreground">Lv {row.level}</span>
                    <div className="flex-1 h-5 bg-muted rounded overflow-hidden relative">
                      <div
                        className="h-full bg-amber-500/50 rounded"
                        style={{
                          width: `${Math.min(
                            (row.avgGold / Math.max(...goldByLevel.map(g => g.avgGold), 1)) * 100,
                            100
                          )}%`
                        }}
                      />
                      <span className="absolute inset-0 flex items-center px-2 text-xs">
                        {fmt(row.avgGold)} avg · {row.count} chars · {fmt(row.totalGold)} total
                      </span>
                    </div>
                  </div>
                ))}
                {goldByLevel.length === 0 && (
                  <p className="text-center text-muted-foreground py-4">No data</p>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Top Holders */}
        <TabsContent value="holders">
          <div className="grid gap-6 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Coins className="h-4 w-4 text-amber-400" /> Top Gold Holders
                </CardTitle>
              </CardHeader>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>#</TableHead>
                    <TableHead>Character</TableHead>
                    <TableHead>Class</TableHead>
                    <TableHead>Lv</TableHead>
                    <TableHead className="text-right">Gold</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {topGold.map((c, i) => (
                    <TableRow key={c.id}>
                      <TableCell className="text-muted-foreground">{i + 1}</TableCell>
                      <TableCell>
                        {c.user ? (
                          <Link href={`/players/${c.user.id}`} className="text-primary hover:underline">
                            {c.characterName}
                          </Link>
                        ) : c.characterName}
                      </TableCell>
                      <TableCell>
                        <span className={`capitalize ${classColors[c.class] ?? ''}`}>{c.class}</span>
                      </TableCell>
                      <TableCell>{c.level}</TableCell>
                      <TableCell className="text-right font-medium text-amber-400">{fmt(c.gold)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Gem className="h-4 w-4 text-purple-400" /> Top Gem Holders
                </CardTitle>
              </CardHeader>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>#</TableHead>
                    <TableHead>User</TableHead>
                    <TableHead>Top Character</TableHead>
                    <TableHead className="text-right">Gems</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {topGems.map((u, i) => (
                    <TableRow key={u.id}>
                      <TableCell className="text-muted-foreground">{i + 1}</TableCell>
                      <TableCell>
                        <Link href={`/players/${u.id}`} className="text-primary hover:underline">
                          {u.username || u.email || 'Unknown'}
                        </Link>
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        {u.characters[0]?.characterName ?? '—'} (Lv {u.characters[0]?.level ?? 0})
                      </TableCell>
                      <TableCell className="text-right font-medium text-purple-400">{fmt(u.gems)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </Card>
          </div>
        </TabsContent>

        {/* IAP */}
        <TabsContent value="iap">
          <div className="grid gap-6 lg:grid-cols-2">
            <Card>
              <CardHeader><CardTitle>IAP by Product</CardTitle></CardHeader>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Product</TableHead>
                    <TableHead className="text-right">Sales</TableHead>
                    <TableHead className="text-right">Gems Sold</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {iapByProduct.map((r) => (
                    <TableRow key={r.productId}>
                      <TableCell className="font-medium">{r.productId}</TableCell>
                      <TableCell className="text-right">{r.count}</TableCell>
                      <TableCell className="text-right text-purple-400">{fmt(r.totalGems)}</TableCell>
                    </TableRow>
                  ))}
                  {iapByProduct.length === 0 && (
                    <TableRow>
                      <TableCell colSpan={3} className="text-center text-muted-foreground py-4">No IAP data</TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </Card>

            <Card>
              <CardHeader><CardTitle>Recent Transactions (30)</CardTitle></CardHeader>
              <CardContent className="p-0 max-h-[400px] overflow-y-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>User</TableHead>
                      <TableHead>Product</TableHead>
                      <TableHead className="text-right">Gems</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Date</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {recentTransactions.map((txn) => (
                      <TableRow key={txn.id}>
                        <TableCell>
                          {txn.user ? (
                            <Link href={`/players/${txn.user.id}`} className="text-primary hover:underline text-xs">
                              {txn.user.username || txn.user.email || '?'}
                            </Link>
                          ) : '—'}
                        </TableCell>
                        <TableCell className="text-xs">{txn.productId}</TableCell>
                        <TableCell className="text-right text-purple-400">+{txn.gemsAwarded}</TableCell>
                        <TableCell>
                          <Badge variant={txn.status === 'verified' ? 'default' : 'secondary'}>
                            {txn.status}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">{fmtDate(txn.createdAt)}</TableCell>
                      </TableRow>
                    ))}
                    {recentTransactions.length === 0 && (
                      <TableRow>
                        <TableCell colSpan={5} className="text-center text-muted-foreground py-4">No transactions</TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Offers */}
        <TabsContent value="offers">
          <Card>
            <CardHeader><CardTitle>Offer Purchase Analytics</CardTitle></CardHeader>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Offer</TableHead>
                  <TableHead>Key</TableHead>
                  <TableHead>Currency</TableHead>
                  <TableHead className="text-right">Purchases</TableHead>
                  <TableHead className="text-right">Total Revenue</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {offerPurchases.map((r) => (
                  <TableRow key={r.offerId}>
                    <TableCell className="font-medium">{r.title}</TableCell>
                    <TableCell className="font-mono text-xs text-muted-foreground">{r.key}</TableCell>
                    <TableCell>{r.currency === 'gems' ? '💎' : '💰'}</TableCell>
                    <TableCell className="text-right">{r.count}</TableCell>
                    <TableCell className="text-right font-medium">{fmt(r.totalRevenue)}</TableCell>
                  </TableRow>
                ))}
                {offerPurchases.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center text-muted-foreground py-4">No offer purchases yet</TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
