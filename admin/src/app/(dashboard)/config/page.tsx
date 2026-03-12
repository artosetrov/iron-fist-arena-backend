import { getAllConfigs } from '@/actions/config'
import { getAdminUser } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { ConfigClient } from './config-client'

export default async function ConfigPage() {
  const admin = await getAdminUser()
  if (!admin) redirect('/login')

  const configs = await getAllConfigs()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Live Config</h1>
        <p className="text-muted-foreground">
          Manage game configuration values in real-time. {configs.length} config keys.
        </p>
      </div>
      <ConfigClient
        configs={JSON.parse(JSON.stringify(configs))}
        adminId={admin.id}
      />
    </div>
  )
}
