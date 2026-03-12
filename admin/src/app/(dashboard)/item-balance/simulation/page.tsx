import { getAdminUser } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { getSimulationHistory } from '@/actions/item-balance'
import { SimulationClient } from './simulation-client'

export default async function SimulationPage() {
  const admin = await getAdminUser()
  if (!admin) redirect('/login')

  const history = await getSimulationHistory(undefined, 20)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Combat Simulation</h1>
        <p className="text-muted-foreground">
          Run combat simulations to test balance between classes, items, and configurations.
        </p>
      </div>
      <SimulationClient
        history={history.map((h: { id: string; runType: string; config: unknown; results: unknown; summary: string | null; createdAt: Date }) => ({
          id: h.id,
          runType: h.runType,
          config: h.config as Record<string, unknown>,
          results: h.results as Record<string, unknown>,
          summary: h.summary,
          createdAt: h.createdAt.toISOString(),
        }))}
        adminId={admin.id}
      />
    </div>
  )
}
