import { getAdminUser } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { getBalanceConfigs } from '@/actions/item-balance'
import { ConfigEditorClient } from './config-editor-client'

export default async function ConfigEditorPage() {
  const admin = await getAdminUser()
  if (!admin) redirect('/login')

  const configs = await getBalanceConfigs()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Balance Config Editor</h1>
        <p className="text-muted-foreground">
          Edit all item balance parameters. Changes take effect immediately via config cache.
        </p>
      </div>
      <ConfigEditorClient
        configs={configs.map((c) => ({
          key: c.key,
          value: c.value,
          description: c.description,
        }))}
        adminId={admin.id}
      />
    </div>
  )
}
