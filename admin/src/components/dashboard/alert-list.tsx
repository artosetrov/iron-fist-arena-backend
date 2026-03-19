'use client'

import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { AlertTriangle, Info, AlertCircle, CheckCircle2 } from 'lucide-react'
import Link from 'next/link'
import type { DashboardAlert } from '@/types/dashboard'

const severityStyles: Record<string, { dot: string; icon: typeof AlertTriangle }> = {
  info: { dot: 'bg-blue-500', icon: Info },
  warning: { dot: 'bg-yellow-500', icon: AlertTriangle },
  critical: { dot: 'bg-red-500', icon: AlertCircle },
}

function timeAgo(dateStr: string): string {
  const diffMs = Date.now() - new Date(dateStr).getTime()
  const mins = Math.floor(diffMs / 60000)
  if (mins < 60) return `${mins}m ago`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours}h ago`
  return `${Math.floor(hours / 24)}d ago`
}

export function AlertList({ alerts }: { alerts: DashboardAlert[] }) {
  if (alerts.length === 0) {
    return (
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium">Alerts</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2 py-4 text-sm text-muted-foreground">
            <CheckCircle2 className="h-4 w-4 text-green-500" />
            No active alerts
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium">
          Alerts
          <span className="ml-2 inline-flex items-center justify-center rounded-full bg-red-500/20 text-red-400 px-2 py-0.5 text-xs font-medium">
            {alerts.length}
          </span>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-1">
        {alerts.map(alert => {
          const style = severityStyles[alert.severity]
          const content = (
            <div className="flex items-start gap-3 rounded-md p-2 hover:bg-zinc-800/50 transition-colors">
              <span className={`mt-1.5 h-2 w-2 rounded-full flex-shrink-0 ${style.dot}`} />
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium truncate">{alert.title}</p>
                <p className="text-xs text-muted-foreground truncate">{alert.description}</p>
              </div>
              <span className="text-xs text-muted-foreground flex-shrink-0">{timeAgo(alert.detectedAt)}</span>
            </div>
          )

          if (alert.linkTarget) {
            return <Link key={alert.id} href={alert.linkTarget}>{content}</Link>
          }
          return <div key={alert.id}>{content}</div>
        })}
      </CardContent>
    </Card>
  )
}
