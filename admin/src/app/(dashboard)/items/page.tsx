import { prisma } from '@/lib/prisma'
import { ItemsClient } from './items-client'

async function getItems() {
  return prisma.item.findMany({
    orderBy: [{ rarity: 'desc' }, { itemLevel: 'desc' }, { itemName: 'asc' }],
  })
}

export default async function ItemsPage() {
  const items = await getItems()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Item Catalog</h1>
        <p className="text-muted-foreground">
          Manage the game item catalog. {items.length} items total.
        </p>
      </div>
      <ItemsClient items={JSON.parse(JSON.stringify(items))} />
    </div>
  )
}
