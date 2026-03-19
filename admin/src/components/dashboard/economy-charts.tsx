'use client'

import {
  ResponsiveContainer, AreaChart, Area, BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Tooltip, ReferenceLine,
} from 'recharts'
import { ChartCard } from './chart-card'
import { Badge } from '@/components/ui/badge'
import type { EconomySnapshot } from '@/types/dashboard'

const tooltipStyle = {
  backgroundColor: '#0f0f12',
  border: '1px solid #27272a',
  borderRadius: '0.5rem',
  color: '#fafafa',
  fontSize: '0.75rem',
}

const shortDate = (v: string) => {
  const d = new Date(v + 'T00:00:00')
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

const riskColor: Record<string, string> = {
  low: 'bg-green-500/20 text-green-400',
  medium: 'bg-yellow-500/20 text-yellow-400',
  high: 'bg-red-500/20 text-red-400',
}

export function EconomyCharts({ economy }: { economy: EconomySnapshot }) {
  // Merge inflow/outflow into single dataset
  const flowData = economy.goldInflow.map(p => {
    const outPoint = economy.goldOutflow.find(o => o.date === p.date)
    return { date: p.date, inflow: p.value, outflow: outPoint?.value ?? 0 }
  })

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3 flex-wrap">
        <div className="text-sm">
          <span className="text-muted-foreground">Gold: </span>
          <span className="font-medium">{economy.totalGoldCirculation.toLocaleString()}</span>
        </div>
        <div className="text-sm">
          <span className="text-muted-foreground">Gems: </span>
          <span className="font-medium">{economy.totalGemsCirculation.toLocaleString()}</span>
        </div>
        <Badge className={`text-xs ${riskColor[economy.inflationRisk]}`}>
          Inflation Risk: {economy.inflationRisk}
        </Badge>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <ChartCard title="Gold Flow (7 days)" description="Inflow from rewards vs outflow from sinks">
          <div className="h-[200px]">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={flowData} margin={{ top: 4, right: 4, bottom: 0, left: -20 }}>
                <defs>
                  <linearGradient id="inflowGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#4ade80" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#4ade80" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="outflowGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#f87171" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#f87171" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#27272a" />
                <XAxis dataKey="date" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} tickFormatter={shortDate} />
                <YAxis stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} />
                <Tooltip contentStyle={tooltipStyle} />
                <Area type="monotone" dataKey="inflow" stroke="#4ade80" strokeWidth={2} fill="url(#inflowGrad)" name="Inflow" />
                <Area type="monotone" dataKey="outflow" stroke="#f87171" strokeWidth={2} fill="url(#outflowGrad)" name="Outflow" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </ChartCard>

        <ChartCard title="Gold Sinks" description="Where gold is being spent">
          <div className="h-[200px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={economy.goldSinkBreakdown} layout="vertical" margin={{ top: 4, right: 4, bottom: 0, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#27272a" horizontal={false} />
                <XAxis type="number" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis dataKey="source" type="category" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} width={100} />
                <Tooltip contentStyle={tooltipStyle} />
                <Bar dataKey="amount" fill="#a78bfa" radius={[0, 4, 4, 0]} name="Gold" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </ChartCard>
      </div>
    </div>
  )
}
