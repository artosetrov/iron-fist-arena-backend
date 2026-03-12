import { getAdminUser } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { getBalanceProfiles } from '@/actions/item-balance'
import { ProfilesClient } from './profiles-client'

export default async function ProfilesPage() {
  const admin = await getAdminUser()
  if (!admin) redirect('/login')

  const profiles = await getBalanceProfiles()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Item Balance Profiles</h1>
        <p className="text-muted-foreground">
          Configure stat weights and power weight per item type. These determine how items generate stats on drop.
        </p>
      </div>
      <ProfilesClient
        profiles={profiles.map((p: { id: string; itemType: string; statWeights: unknown; powerWeight: number; description: string | null; updatedAt: Date }) => ({
          id: p.id,
          itemType: p.itemType,
          statWeights: p.statWeights as Record<string, number>,
          powerWeight: p.powerWeight,
          description: p.description,
          updatedAt: p.updatedAt.toISOString(),
        }))}
        adminId={admin.id}
      />
    </div>
  )
}
