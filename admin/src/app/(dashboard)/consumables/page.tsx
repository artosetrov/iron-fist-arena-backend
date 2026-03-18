import { getAdminUser } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { ConsumablesClient } from './consumables-client'

export default async function ConsumablesPage() {
  const admin = await getAdminUser()
  if (!admin) redirect('/login')

  // Fetch consumable items from catalog
  const consumableItems = await prisma.item.findMany({
    where: { itemType: 'consumable' },
    orderBy: { catalogId: 'asc' },
  })

  // Fetch consumable-related configs
  const configs = await prisma.gameConfig.findMany({
    where: {
      key: { startsWith: 'consumable.' },
    },
    orderBy: { key: 'asc' },
  })

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Consumables</h1>
        <p className="text-muted-foreground">
          Manage potion prices, effects, and consumable items. {consumableItems.length} consumables in catalog.
        </p>
      </div>
      <ConsumablesClient
        items={JSON.parse(JSON.stringify(consumableItems))}
        configs={JSON.parse(JSON.stringify(configs))}
      />
    </div>
  )
}
