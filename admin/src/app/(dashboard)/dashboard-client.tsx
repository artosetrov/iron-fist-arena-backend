'use client'

import {
  Users, Swords, Coins, Gem, AlertTriangle, Activity,
  Scale, Castle, Scroll, ShoppingBag, Sliders, Shield,
} from 'lucide-react'
import {
  KpiGrid, SectionHeader, EconomyCharts, PvpCharts,
  PlayerCharts, AlertList, QuickLinks,
} from '@/components/dashboard'
import type { DashboardData } from '@/types/dashboard'

const quickLinks = [
  { label: 'Players', href: '/players', icon: Users, description: 'Search and manage players' },
  { label: 'Arena', href: '/matches', icon: Swords, description: 'PvP match history' },
  { label: 'Economy', href: '/economy', icon: Coins, description: 'Gold and gem analytics' },
  { label: 'Balance', href: '/item-balance', icon: Scale, description: 'Item & combat tuning' },
  { label: 'Dungeons', href: '/dungeons', icon: Castle, description: 'Dungeon editor' },
  { label: 'Quests', href: '/quests', icon: Scroll, description: 'Daily quest config' },
  { label: 'Offers', href: '/offers', icon: ShoppingBag, description: 'Shop offers' },
  { label: 'Config', href: '/config', icon: Sliders, description: 'Live config editor' },
]

export function DashboardClient({ data }: { data: DashboardData }) {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-xs text-muted-foreground">
            Last updated: {new Date(data.generatedAt).toLocaleString('en-GB', {
              day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit',
            })}
          </p>
        </div>
        {data.alerts.length > 0 && (
          <div className="flex items-center gap-1.5 text-sm text-yellow-400">
            <AlertTriangle className="h-4 w-4" />
            {data.alerts.length} active alert{data.alerts.length !== 1 ? 's' : ''}
          </div>
        )}
      </div>

      {/* KPIs */}
      <KpiGrid kpis={data.kpis} />

      {/* Alerts (show only if there are any) */}
      {data.alerts.length > 0 && (
        <>
          <SectionHeader title="Alerts" description="Issues that need attention" />
          <AlertList alerts={data.alerts} />
        </>
      )}

      {/* Economy */}
      <SectionHeader title="Economy" description="Gold and gem circulation health" />
      <EconomyCharts economy={data.economy} />

      {/* PvP / Balance */}
      <SectionHeader title="PvP & Balance" description="Class balance, matchmaking, and engagement" />
      <PvpCharts pvp={data.pvp} />

      {/* Players */}
      <SectionHeader title="Players" description="User acquisition, activity, and retention" />
      <PlayerCharts players={data.players} />

      {/* System Health (compact) */}
      <SectionHeader title="System Health" />
      <div className="grid gap-3 grid-cols-2 md:grid-cols-4">
        <StatBadge label="API Error Rate" value={`${(data.system.apiErrorRate * 100).toFixed(1)}%`}
          status={data.system.apiErrorRate > 0.05 ? 'warning' : 'normal'} />
        <StatBadge label="Avg Response" value={`${data.system.avgResponseTime}ms`}
          status={data.system.avgResponseTime > 500 ? 'warning' : 'normal'} />
        <StatBadge label="Slow Endpoints" value={String(data.system.slowEndpointsCount)}
          status={data.system.slowEndpointsCount > 5 ? 'warning' : 'normal'} />
        <StatBadge label="Recent Errors" value={String(data.system.recentErrors.length)}
          status={data.system.recentErrors.length > 0 ? 'warning' : 'normal'} />
      </div>

      {/* Quick Links */}
      <SectionHeader title="Quick Links" description="Jump to other admin sections" />
      <QuickLinks links={quickLinks} />
    </div>
  )
}

function StatBadge({ label, value, status }: { label: string; value: string; status: 'normal' | 'warning' }) {
  return (
    <div className={`rounded-lg border px-4 py-3 ${status === 'warning' ? 'border-yellow-500/30 bg-yellow-500/5' : 'border-zinc-800'}`}>
      <p className="text-xs text-muted-foreground">{label}</p>
      <p className="text-lg font-bold tabular-nums">{value}</p>
    </div>
  )
}
