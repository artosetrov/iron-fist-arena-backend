'use client'

import {
  ResponsiveContainer, BarChart, Bar, AreaChart, Area,
  XAxis, YAxis, CartesianGrid, Tooltip, ReferenceLine, Cell,
} from 'recharts'
import { ChartCard } from './chart-card'
import { Badge } from '@/components/ui/badge'
import type { PvpSnapshot } from '@/types/dashboard'

const tooltipStyle = {
  backgroundColor: '#0f0f12',
  border: '1px solid #27272a',
  borderRadius: '0.5rem',
  color: '#fafafa',
  fontSize: '0.75rem',
}

const classColors: Record<string, string> = {
  warrior: '#ef4444',
  rogue: '#22c55e',
  mage: '#3b82f6',
  tank: '#eab308',
}

const shortDate = (v: string) => {
  const d = new Date(v + 'T00:00:00')
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

export function PvpCharts({ pvp }: { pvp: PvpSnapshot }) {
  const winRateData = pvp.classWinRates.map(c => ({
    ...c,
    class: c.class.charAt(0).toUpperCase() + c.class.slice(1),
    winRate: Math.round(c.winRate * 10) / 10,
  }))

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4 flex-wrap">
        <div className="text-sm">
          <span className="text-muted-foreground">Matches Today: </span>
          <span className="font-medium">{pvp.totalMatchesToday.toLocaleString()}</span>
        </div>
        <div className="text-sm">
          <span className="text-muted-foreground">Avg Duration: </span>
          <span className="font-medium">{pvp.avgFightDuration}s</span>
        </div>
        <div className="text-sm">
          <span className="text-muted-foreground">Fairness: </span>
          <Badge className={`text-xs ${pvp.matchmakingFairness >= 0.7 ? 'bg-green-500/20 text-green-400' : 'bg-yellow-500/20 text-yellow-400'}`}>
            {(pvp.matchmakingFairness * 100).toFixed(0)}%
          </Badge>
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <ChartCard title="Class Win Rates" description="50% is perfectly balanced">
          <div className="h-[200px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={winRateData} layout="vertical" margin={{ top: 4, right: 4, bottom: 0, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#27272a" horizontal={false} />
                <XAxis type="number" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} domain={[0, 100]} />
                <YAxis dataKey="class" type="category" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} width={70} />
                <Tooltip contentStyle={tooltipStyle} formatter={(v: number) => `${v}%`} />
                <ReferenceLine x={50} stroke="#71717a" strokeDasharray="3 3" />
                <Bar dataKey="winRate" radius={[0, 4, 4, 0]} name="Win Rate">
                  {winRateData.map(entry => (
                    <Cell key={entry.class} fill={classColors[entry.class.toLowerCase()] || '#a78bfa'} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </ChartCard>

        <ChartCard title="Match Volume (7 days)">
          <div className="h-[200px]">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={pvp.matchVolumeByDay} margin={{ top: 4, right: 4, bottom: 0, left: -20 }}>
                <defs>
                  <linearGradient id="matchGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#a78bfa" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#a78bfa" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#27272a" />
                <XAxis dataKey="date" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} tickFormatter={shortDate} />
                <YAxis stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} allowDecimals={false} />
                <Tooltip contentStyle={tooltipStyle} />
                <Area type="monotone" dataKey="value" stroke="#a78bfa" strokeWidth={2} fill="url(#matchGrad)" name="Matches" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </ChartCard>
      </div>

      {pvp.ratingDistribution.length > 0 && (
        <ChartCard title="Rating Distribution">
          <div className="h-[160px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={pvp.ratingDistribution} margin={{ top: 4, right: 4, bottom: 0, left: -20 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#27272a" />
                <XAxis dataKey="bucket" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} allowDecimals={false} />
                <Tooltip contentStyle={tooltipStyle} />
                <Bar dataKey="count" fill="#60a5fa" radius={[4, 4, 0, 0]} name="Players" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </ChartCard>
      )}
    </div>
  )
}
