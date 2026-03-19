'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import type {
  DashboardData, KpiItem, DashboardAlert,
  EconomySnapshot, PvpSnapshot, PlayerSnapshot, SystemHealth, TimeSeriesPoint,
} from '@/types/dashboard'

function startOfDay(d: Date): Date {
  const r = new Date(d); r.setUTCHours(0, 0, 0, 0); return r
}

function daysAgo(n: number): Date {
  const d = startOfDay(new Date())
  d.setUTCDate(d.getUTCDate() - n)
  return d
}

function delta(cur: number, prev: number) {
  if (prev === 0) return { deltaPercent: cur > 0 ? 100 : 0, trend: 'flat' as const }
  const pct = Math.round(((cur - prev) / prev) * 1000) / 10
  return { deltaPercent: pct, trend: pct > 1 ? 'up' as const : pct < -1 ? 'down' as const : 'flat' as const }
}

function kpiStatus(key: string, _val: number, pct: number): 'normal' | 'warning' | 'critical' {
  if (key === 'dau' && pct < -30) return 'critical'
  if (key === 'dau' && pct < -15) return 'warning'
  if (key === 'total_gold' && pct > 50) return 'critical'
  if (key === 'total_gold' && pct > 20) return 'warning'
  if (key === 'pvp_today' && pct < -40) return 'critical'
  if (key === 'pvp_today' && pct < -20) return 'warning'
  return 'normal'
}

export async function getDashboardData(): Promise<DashboardData> {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const today = startOfDay(new Date())
  const yesterday = daysAgo(1)
  const sevenAgo = daysAgo(7)

  // ── Parallel queries ──
  const [
    newToday, newYesterday,
    dauToday, dauYesterday,
    totalUsers,
    guestUsers,
    totalGold, totalGems,
    pvpToday, pvpYesterday,
    classWinData,
    ratingBuckets,
    last7Matches,
    last7Regs,
    goldMineToday,
    avgMatchDuration,
  ] = await Promise.all([
    // New users today / yesterday
    prisma.user.count({ where: { createdAt: { gte: today } } }),
    prisma.user.count({ where: { createdAt: { gte: yesterday, lt: today } } }),
    // DAU (characters active today / yesterday)
    prisma.character.count({ where: { lastPlayed: { gte: today } } }),
    prisma.character.count({ where: { lastPlayed: { gte: yesterday, lt: today } } }),
    // Totals
    prisma.user.count(),
    prisma.user.count({ where: { OR: [{ authProvider: null }, { authProvider: 'guest' }] } }),
    // Economy totals
    prisma.character.aggregate({ _sum: { gold: true } }),
    prisma.user.aggregate({ _sum: { gems: true } }),
    // PvP today / yesterday
    prisma.pvpMatch.count({ where: { playedAt: { gte: today } } }),
    prisma.pvpMatch.count({ where: { playedAt: { gte: yesterday, lt: today } } }),
    // Class win rates (group by winner's class)
    prisma.$queryRaw<{ class: string; wins: bigint; total: bigint }[]>`
      SELECT c.class,
        COUNT(CASE WHEN pm.winner_id = c.id THEN 1 END)::bigint as wins,
        COUNT(*)::bigint as total
      FROM characters c
      JOIN pvp_matches pm ON pm.player1_id = c.id OR pm.player2_id = c.id
      WHERE pm.played_at >= ${sevenAgo}::timestamp
      GROUP BY c.class
    `,
    // Rating distribution
    prisma.$queryRaw<{ bucket: string; count: bigint }[]>`
      SELECT CASE
        WHEN pvp_rating < 1000 THEN '<1000'
        WHEN pvp_rating < 1200 THEN '1000-1200'
        WHEN pvp_rating < 1400 THEN '1200-1400'
        WHEN pvp_rating < 1600 THEN '1400-1600'
        ELSE '1600+'
      END as bucket, COUNT(*)::bigint as count
      FROM characters WHERE pvp_wins + pvp_losses > 0
      GROUP BY bucket ORDER BY bucket
    `,
    // Last 7 days match volume
    prisma.$queryRaw<{ date: string; count: bigint }[]>`
      SELECT DATE(played_at)::text as date, COUNT(*)::bigint as count
      FROM pvp_matches WHERE played_at >= ${sevenAgo}::timestamp
      GROUP BY DATE(played_at) ORDER BY date
    `,
    // Last 7 days registrations
    prisma.$queryRaw<{ date: string; count: bigint }[]>`
      SELECT DATE(created_at)::text as date, COUNT(*)::bigint as count
      FROM users WHERE created_at >= ${sevenAgo}::timestamp
      GROUP BY DATE(created_at) ORDER BY date
    `,
    // Gold mine income today
    prisma.goldMineSession.aggregate({
      _sum: { reward: true },
      where: { startedAt: { gte: today }, collected: true },
    }),
    // Average match duration (7d)
    prisma.pvpMatch.aggregate({
      _avg: { matchDuration: true },
      where: { playedAt: { gte: sevenAgo } },
    }),
  ])

  const numGold = totalGold._sum.gold ?? 0
  const numGems = totalGems._sum.gems ?? 0
  const registered = totalUsers - guestUsers

  // ── Build KPIs ──
  const { deltaPercent: dauPct, trend: dauT } = delta(dauToday, dauYesterday)
  const { deltaPercent: newPct, trend: newT } = delta(newToday, newYesterday)
  const { deltaPercent: pvpPct, trend: pvpT } = delta(pvpToday, pvpYesterday)

  const kpis: KpiItem[] = [
    { key: 'dau', label: 'Active Today', value: dauToday, previousValue: dauYesterday, deltaPercent: dauPct, trend: dauT, status: kpiStatus('dau', dauToday, dauPct), format: 'number' },
    { key: 'new_users', label: 'New Users', value: newToday, previousValue: newYesterday, deltaPercent: newPct, trend: newT, status: 'normal', format: 'number' },
    { key: 'total_users', label: 'Total Users', value: totalUsers, previousValue: totalUsers, deltaPercent: 0, trend: 'flat', status: 'normal', format: 'number' },
    { key: 'pvp_today', label: 'PvP Today', value: pvpToday, previousValue: pvpYesterday, deltaPercent: pvpPct, trend: pvpT, status: kpiStatus('pvp_today', pvpToday, pvpPct), format: 'number' },
    { key: 'total_gold', label: 'Gold Circulation', value: numGold, previousValue: numGold, deltaPercent: 0, trend: 'flat', status: 'normal', format: 'currency' },
    { key: 'total_gems', label: 'Gems Circulation', value: numGems, previousValue: numGems, deltaPercent: 0, trend: 'flat', status: 'normal', format: 'number' },
  ]

  // ── Economy ──
  const goldMineVal = goldMineToday._sum.reward ?? 0
  const economy: EconomySnapshot = {
    goldInflow: last7Matches.map(m => ({
      date: m.date,
      value: Number(m.count) * 50, // rough: ~50 gold per match reward
    })),
    goldOutflow: [],
    goldSinkBreakdown: [
      { source: 'PvP Rewards', amount: pvpToday * 50 },
      { source: 'Gold Mine', amount: goldMineVal },
      { source: 'Training', amount: 0 },
    ],
    gemSpendBreakdown: [],
    inflationRisk: 'low',
    totalGoldCirculation: numGold,
    totalGemsCirculation: numGems,
  }

  // ── PvP ──
  const classWinRates = classWinData.map(c => {
    const t = Number(c.total)
    const w = Number(c.wins)
    return { class: c.class, winRate: t > 0 ? (w / t) * 100 : 50, totalMatches: t }
  })

  const pvp: PvpSnapshot = {
    classWinRates,
    ratingDistribution: ratingBuckets.map(r => ({ bucket: r.bucket, count: Number(r.count) })),
    matchVolumeByDay: last7Matches.map(m => ({ date: m.date, value: Number(m.count) })),
    avgFightDuration: Math.round(avgMatchDuration._avg.matchDuration ?? 0),
    totalMatchesToday: pvpToday,
    matchmakingFairness: 0.75, // TODO: calculate from rating deltas
  }

  // ── Players ──
  const players: PlayerSnapshot = {
    newUsersToday: newToday,
    activeToday: dauToday,
    returningToday: Math.max(0, dauToday - newToday),
    guestCount: guestUsers,
    registeredCount: registered,
    guestConversionRate: totalUsers > 0 ? Math.round((registered / totalUsers) * 1000) / 10 : 0,
    registrationsByDay: last7Regs.map(r => ({ date: r.date, value: Number(r.count) })),
    retentionD1: 0, // TODO: requires login event tracking
    retentionD7: 0,
    retentionD30: 0,
  }

  // ── Alerts ──
  const alerts: DashboardAlert[] = []

  classWinRates.forEach(c => {
    if (c.winRate > 55 && c.totalMatches > 10) {
      alerts.push({
        id: `wr_${c.class}`,
        alertType: 'balance',
        severity: c.winRate > 60 ? 'critical' : 'warning',
        title: `${c.class.charAt(0).toUpperCase() + c.class.slice(1)} win rate ${c.winRate.toFixed(1)}%`,
        description: `Over ${c.totalMatches} matches in 7 days`,
        detectedAt: new Date().toISOString(),
        status: 'active',
        entityType: 'class',
        entityId: c.class,
        suggestedAction: 'Review class balance',
        linkTarget: '/item-balance',
      })
    }
  })

  if (dauPct < -15) {
    alerts.push({
      id: 'dau_drop',
      alertType: 'retention',
      severity: dauPct < -30 ? 'critical' : 'warning',
      title: `DAU down ${Math.abs(dauPct)}%`,
      description: `${dauToday} today vs ${dauYesterday} yesterday`,
      detectedAt: new Date().toISOString(),
      status: 'active',
      suggestedAction: 'Check recent patches or server issues',
    })
  }

  if (pvpPct < -20) {
    alerts.push({
      id: 'pvp_drop',
      alertType: 'engagement',
      severity: pvpPct < -40 ? 'critical' : 'warning',
      title: `PvP volume down ${Math.abs(pvpPct)}%`,
      description: `${pvpToday} matches today vs ${pvpYesterday} yesterday`,
      detectedAt: new Date().toISOString(),
      status: 'active',
      suggestedAction: 'Check PvP rewards and matchmaking',
      linkTarget: '/matches',
    })
  }

  // ── System ──
  const system: SystemHealth = {
    apiErrorRate: 0.02,
    slowEndpointsCount: 0,
    avgResponseTime: 150,
    recentErrors: [],
  }

  return { kpis, economy, pvp, players, alerts, system, generatedAt: new Date().toISOString() }
}
