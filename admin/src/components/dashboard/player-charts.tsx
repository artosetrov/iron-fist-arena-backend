'use client'

import {
  ResponsiveContainer, AreaChart, Area,
  XAxis, YAxis, CartesianGrid, Tooltip,
} from 'recharts'
import { ChartCard } from './chart-card'
import { Badge } from '@/components/ui/badge'
import type { PlayerSnapshot } from '@/types/dashboard'

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

function RetentionBadge({ label, value }: { label: string; value: number }) {
  let color = 'bg-green-500/20 text-green-400'
  if (value < 20) color = 'bg-red-500/20 text-red-400'
  else if (value < 40) color = 'bg-yellow-500/20 text-yellow-400'

  return (
    <div className="text-center">
      <p className="text-xs text-muted-foreground mb-1">{label}</p>
      <Badge className={`text-xs ${color}`}>
        {value > 0 ? `${value.toFixed(0)}%` : 'N/A'}
      </Badge>
    </div>
  )
}

export function PlayerCharts({ players }: { players: PlayerSnapshot }) {
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4 flex-wrap">
        <div className="text-sm">
          <span className="text-muted-foreground">Active Today: </span>
          <span className="font-medium">{players.activeToday.toLocaleString()}</span>
        </div>
        <div className="text-sm">
          <span className="text-muted-foreground">New: </span>
          <span className="font-medium">{players.newUsersToday}</span>
        </div>
        <div className="text-sm">
          <span className="text-muted-foreground">Returning: </span>
          <span className="font-medium">{players.returningToday}</span>
        </div>
        <div className="text-sm">
          <span className="text-muted-foreground">Guest: </span>
          <span className="font-medium">{players.guestCount}</span>
          <span className="text-muted-foreground"> / Registered: </span>
          <span className="font-medium">{players.registeredCount}</span>
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <ChartCard title="Registrations (7 days)">
            <div className="h-[200px]">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={players.registrationsByDay} margin={{ top: 4, right: 4, bottom: 0, left: -20 }}>
                  <defs>
                    <linearGradient id="regGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#60a5fa" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#60a5fa" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#27272a" />
                  <XAxis dataKey="date" stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} tickFormatter={shortDate} />
                  <YAxis stroke="#71717a" fontSize={11} tickLine={false} axisLine={false} allowDecimals={false} />
                  <Tooltip contentStyle={tooltipStyle} />
                  <Area type="monotone" dataKey="value" stroke="#60a5fa" strokeWidth={2} fill="url(#regGrad)" name="Users" />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </ChartCard>
        </div>

        <ChartCard title="Retention" description="TODO: Requires login event tracking">
          <div className="flex items-center justify-around py-6">
            <RetentionBadge label="D1" value={players.retentionD1} />
            <RetentionBadge label="D7" value={players.retentionD7} />
            <RetentionBadge label="D30" value={players.retentionD30} />
          </div>
          <div className="text-center">
            <p className="text-xs text-muted-foreground">
              Conversion: <span className="text-foreground font-medium">{players.guestConversionRate}%</span> registered
            </p>
          </div>
        </ChartCard>
      </div>
    </div>
  )
}
