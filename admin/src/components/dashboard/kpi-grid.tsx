'use client'

import type { KpiItem } from '@/types/dashboard'
import { KpiCard } from './kpi-card'

export function KpiGrid({ kpis }: { kpis: KpiItem[] }) {
  return (
    <div className="grid gap-3 grid-cols-2 md:grid-cols-3 xl:grid-cols-6">
      {kpis.map(kpi => (
        <KpiCard key={kpi.key} kpi={kpi} />
      ))}
    </div>
  )
}
