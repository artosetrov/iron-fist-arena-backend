'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  Package, Settings, Layers, ShieldAlert, Activity,
  ArrowRight, RefreshCw,
} from 'lucide-react'

interface BalanceSummary {
  totalItems: number
  totalConfigs: number
  totalProfiles: number
  lastSimDate: string | null
  lastSimType: string | null
  lastSimSummary: string | null
}

interface SimRun {
  id: string
  runType: string
  summary: string | null
  createdAt: string
}

const RUN_TYPE_LABELS: Record<string, string> = {
  combat_sim: 'Combat Sim',
  class_matchups: 'Class Matchups',
  item_impact: 'Item Impact',
  item_audit: 'Item Audit',
}

const RUN_TYPE_COLORS: Record<string, string> = {
  combat_sim: 'bg-blue-500/10 text-blue-600',
  class_matchups: 'bg-purple-500/10 text-purple-600',
  item_impact: 'bg-orange-500/10 text-orange-600',
  item_audit: 'bg-green-500/10 text-green-600',
}

export function BalanceDashboardClient({
  summary,
  recentSims,
  adminId,
}: {
  summary: BalanceSummary
  recentSims: SimRun[]
  adminId: string
}) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [validating, setValidating] = useState(false)
  const [validationResult, setValidationResult] = useState<{
    totalItems: number
    flaggedItems: number
    overpowered: number
    underpowered: number
  } | null>(null)

  async function runValidation() {
    setValidating(true)
    try {
      const res = await fetch('/api/admin/item-balance/validate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
      })
      if (res.ok) {
        const data = await res.json()
        setValidationResult({
          totalItems: data.totalItems,
          flaggedItems: data.flaggedItems.length,
          overpowered: data.stats.overpoweredCount,
          underpowered: data.stats.underpoweredCount,
        })
        startTransition(() => router.refresh())
      }
    } finally {
      setValidating(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Items</CardTitle>
            <Package className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{summary.totalItems}</div>
            <p className="text-xs text-muted-foreground">Equipment items in catalog</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Config Values</CardTitle>
            <Settings className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{summary.totalConfigs}</div>
            <p className="text-xs text-muted-foreground">Balance parameters</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Item Profiles</CardTitle>
            <Layers className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{summary.totalProfiles}</div>
            <p className="text-xs text-muted-foreground">Item type profiles</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Last Simulation</CardTitle>
            <Activity className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {summary.lastSimDate
                ? new Date(summary.lastSimDate).toLocaleDateString()
                : 'Never'}
            </div>
            <p className="text-xs text-muted-foreground">
              {summary.lastSimType ? RUN_TYPE_LABELS[summary.lastSimType] ?? summary.lastSimType : 'No simulations run'}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Link href="/item-balance/config">
          <Card className="cursor-pointer hover:bg-accent/50 transition-colors">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm">Config Editor</CardTitle>
              <CardDescription>Edit power scores, stat ranges, economy, combat formulas</CardDescription>
            </CardHeader>
            <CardContent>
              <ArrowRight className="h-4 w-4 text-muted-foreground" />
            </CardContent>
          </Card>
        </Link>

        <Link href="/item-balance/profiles">
          <Card className="cursor-pointer hover:bg-accent/50 transition-colors">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm">Item Profiles</CardTitle>
              <CardDescription>Configure stat weights per item type</CardDescription>
            </CardHeader>
            <CardContent>
              <ArrowRight className="h-4 w-4 text-muted-foreground" />
            </CardContent>
          </Card>
        </Link>

        <Link href="/item-balance/validation">
          <Card className="cursor-pointer hover:bg-accent/50 transition-colors">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm">Validation</CardTitle>
              <CardDescription>Detect overpowered or underpowered items</CardDescription>
            </CardHeader>
            <CardContent>
              <ArrowRight className="h-4 w-4 text-muted-foreground" />
            </CardContent>
          </Card>
        </Link>

        <Link href="/item-balance/simulation">
          <Card className="cursor-pointer hover:bg-accent/50 transition-colors">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm">Simulation</CardTitle>
              <CardDescription>Run combat sims, class matchups, item impact</CardDescription>
            </CardHeader>
            <CardContent>
              <ArrowRight className="h-4 w-4 text-muted-foreground" />
            </CardContent>
          </Card>
        </Link>
      </div>

      {/* Quick Validation */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <ShieldAlert className="h-5 w-5" />
                Quick Validation
              </CardTitle>
              <CardDescription>Run a balance check on all items in the catalog</CardDescription>
            </div>
            <Button onClick={runValidation} disabled={validating} size="sm">
              <RefreshCw className={`h-4 w-4 mr-2 ${validating ? 'animate-spin' : ''}`} />
              {validating ? 'Validating...' : 'Run Validation'}
            </Button>
          </div>
        </CardHeader>
        {validationResult && (
          <CardContent>
            <div className="grid grid-cols-4 gap-4 text-center">
              <div>
                <div className="text-lg font-bold">{validationResult.totalItems}</div>
                <div className="text-xs text-muted-foreground">Total Items</div>
              </div>
              <div>
                <div className={`text-lg font-bold ${validationResult.flaggedItems > 0 ? 'text-red-500' : 'text-green-500'}`}>
                  {validationResult.flaggedItems}
                </div>
                <div className="text-xs text-muted-foreground">Flagged</div>
              </div>
              <div>
                <div className="text-lg font-bold text-orange-500">{validationResult.overpowered}</div>
                <div className="text-xs text-muted-foreground">Overpowered</div>
              </div>
              <div>
                <div className="text-lg font-bold text-blue-500">{validationResult.underpowered}</div>
                <div className="text-xs text-muted-foreground">Underpowered</div>
              </div>
            </div>
            {validationResult.flaggedItems > 0 && (
              <div className="mt-4">
                <Link href="/item-balance/validation">
                  <Button variant="outline" size="sm">
                    View Details <ArrowRight className="h-3 w-3 ml-1" />
                  </Button>
                </Link>
              </div>
            )}
          </CardContent>
        )}
      </Card>

      {/* Recent Simulations */}
      {recentSims.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Recent Simulations</CardTitle>
            <CardDescription>Last 5 simulation runs</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {recentSims.map((sim) => (
                <div key={sim.id} className="flex items-center justify-between py-2 border-b last:border-0">
                  <div className="flex items-center gap-3">
                    <Badge variant="secondary" className={RUN_TYPE_COLORS[sim.runType] ?? ''}>
                      {RUN_TYPE_LABELS[sim.runType] ?? sim.runType}
                    </Badge>
                    <span className="text-sm text-muted-foreground">{sim.summary ?? '—'}</span>
                  </div>
                  <span className="text-xs text-muted-foreground">
                    {new Date(sim.createdAt).toLocaleString()}
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
