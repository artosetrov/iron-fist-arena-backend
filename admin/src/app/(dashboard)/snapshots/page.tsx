import { getAdminUser } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { listConfigSnapshots } from '@/actions/snapshots'
import { SnapshotsClient } from './snapshots-client'

export default async function SnapshotsPage() {
  const admin = await getAdminUser()
  if (!admin) redirect('/login')

  const snapshots = await listConfigSnapshots()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Config Snapshots</h1>
        <p className="text-muted-foreground">
          Manage configuration snapshots. Create snapshots before making config changes and rollback to previous states if needed.
        </p>
      </div>
      <SnapshotsClient
        snapshots={snapshots.map((s: any) => ({
          id: s.id,
          name: s.name,
          description: s.description,
          createdBy: s.createdBy,
          createdAt: s.createdAt.toISOString(),
          configCount: Array.isArray(s.configs) ? s.configs.length : 0,
        }))}
        adminId={admin.id}
      />
    </div>
  )
}
