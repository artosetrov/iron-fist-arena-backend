'use client'

import { Card, CardContent } from '@/components/ui/card'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'
import type { KpiItem } from '@/types/dashboard'

function formatValue(value: number, format?: string): string {
  switch (format) {
    case 'percent':
      return `${value.toFixed(1)}%`
    case 'currency':
      return value.toLocaleString()
    case 'duration':
      return `${value}s`
    default:
      return value.toLocaleString()
  }
}

const statusBorder: Record<string, string> = {
  normal: 'border-l-transparent',
  warning: 'border-l-yellow-500',
  critical: 'border-l-red-500',
}

const trendColor: Record<string, string> = {
  up: 'text-green-400',
  down: 'text-red-400',
  flat: 'text-zinc-500',
}

export function KpiCard({ kpi }: { kpi: KpiItem }) {
  const TrendIcon = kpi.trend === 'up' ? TrendingUp : kpi.trend === 'down' ? TrendingDown : Minus

  return (
    <Card className={`border-l-2 ${statusBorder[kpi.status]}`}>
      <CardContent className="py-3 px-4">
        <p className="text-xs font-medium text-muted-foreground truncate">{kpi.label}</p>
        <div className="flex items-baseline gap-2 mt-1">
          <span className="text-xl font-bold tabular-nums">{formatValue(kpi.value, kpi.format)}</span>
          {kpi.deltaPercent !== 0 && (
            <span className={`flex items-center gap-0.5 text-xs font-medium ${trendColor[kpi.trend]}`}>
              <TrendIcon className="h-3 w-3" />
              {Math.abs(kpi.deltaPercent)}%
            </span>
          )}
        </div>
      </CardContent>
    </Card>
  )
}
