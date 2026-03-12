'use client'

import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from 'recharts'

interface RegistrationChartProps {
  data: { date: string; registrations: number }[]
}

export function RegistrationChart({ data }: RegistrationChartProps) {
  return (
    <div className="h-[300px] w-full">
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data} margin={{ top: 4, right: 4, bottom: 0, left: -20 }}>
          <defs>
            <linearGradient id="colorRegistrations" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#a78bfa" stopOpacity={0.3} />
              <stop offset="95%" stopColor="#a78bfa" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#27272a" />
          <XAxis
            dataKey="date"
            stroke="#71717a"
            fontSize={12}
            tickLine={false}
            axisLine={false}
            tickFormatter={(value: string) => {
              const d = new Date(value + 'T00:00:00')
              return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
            }}
            interval="preserveStartEnd"
          />
          <YAxis
            stroke="#71717a"
            fontSize={12}
            tickLine={false}
            axisLine={false}
            allowDecimals={false}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: '#0f0f12',
              border: '1px solid #27272a',
              borderRadius: '0.5rem',
              color: '#fafafa',
              fontSize: '0.875rem',
            }}
            labelFormatter={(value: string) => {
              const d = new Date(value + 'T00:00:00')
              return d.toLocaleDateString('en-US', {
                month: 'long',
                day: 'numeric',
                year: 'numeric',
              })
            }}
          />
          <Area
            type="monotone"
            dataKey="registrations"
            stroke="#a78bfa"
            strokeWidth={2}
            fillOpacity={1}
            fill="url(#colorRegistrations)"
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  )
}
