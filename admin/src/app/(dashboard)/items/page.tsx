import { prisma } from '@/lib/prisma'
import { resolveImagesForItems } from '@/lib/item-image-resolver'
import { ItemsClient } from './items-client'

async function getItems() {
  const raw = await prisma.item.findMany({
    orderBy: [{ rarity: 'desc' }, { itemLevel: 'desc' }, { itemName: 'asc' }],
  })

  // Borrow art from siblings of the same itemType+rarity for items that have
  // no own imageKey/imageUrl. The flag `imageBorrowed` lets the UI badge them
  // so admins can tell what still needs real art uploaded.
  const resolved = await resolveImagesForItems(prisma, raw)

  return resolved
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
