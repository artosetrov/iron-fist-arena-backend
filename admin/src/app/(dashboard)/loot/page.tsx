import { getAllConfigs } from '@/actions/config'
import { getAdminUser } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { LootClient } from './loot-client'

export default async function LootPage() {
  const admin = await getAdminUser()
  if (!admin) redirect('/login')

  const configs = await getAllConfigs()

  const dropChances = configs
    .filter((c) => c.category === 'drop_chances')
    .map((c) => ({
      key: c.key,
      value: c.value as number,
      description: c.description,
    }))

  const rarityDistribution = configs
    .filter((c) => c.category === 'rarity_distribution')
    .map((c) => ({
      key: c.key,
      value: c.value as number,
      description: c.description,
    }))

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Loot Tables</h1>
        <p className="text-muted-foreground">
          Configure item drop chances and rarity distribution weights.
        </p>
      </div>
      <LootClient
        dropChances={dropChances}
        rarityDistribution={rarityDistribution}
        adminId={admin.id}
      />
    </div>
  )
}
