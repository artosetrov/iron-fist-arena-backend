import { getAdminUser } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { getBalanceSummary, getSimulationHistory } from '@/actions/item-balance'
import { BalanceDashboardClient } from './dashboard-client'

export default async function ItemBalancePage() {
  const admin = await getAdminUser()
  if (!admin) redirect('/login')

  const [summary, recentSims] = await Promise.all([
    getBalanceSummary(),
    getSimulationHistory(undefined, 5),
  ])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Item Balance</h1>
        <p className="text-muted-foreground">
          Overview of item balance, power scores, and simulation history.
        </p>
      </div>
      <BalanceDashboardClient
        summary={{
          ...summary,
          lastSimDate: summary.lastSimDate?.toISOString() ?? null,
        }}
        recentSims={recentSims.map((s: { id: string; runType: string; summary: string | null; createdAt: Date }) => ({
          id: s.id,
          runType: s.runType,
          summary: s.summary,
          createdAt: s.createdAt.toISOString(),
        }))}
        adminId={admin.id}
      />
    </div>
  )
}
