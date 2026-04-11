import { prisma } from '@/lib/prisma'
import { notFound } from 'next/navigation'
import { resolveImageForItem } from '@/lib/item-image-resolver'
import { ItemEditorClient } from '../../_components/item-editor-client'

export default async function EditItemPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const item = await prisma.item.findUnique({ where: { id } })
  if (!item) notFound()

  // If the item has no own art, compute a borrowed fallback so the editor's
  // preview card can show something meaningful. The editor itself must NEVER
  // write the borrowed URL/key back into the item — that's tracked via the
  // imageBorrowed flag and the editor guards against it.
  const resolved = await resolveImageForItem(prisma, item)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Edit Item</h1>
        <p className="text-muted-foreground">Editing: {item.itemName}</p>
      </div>
      <ItemEditorClient
        item={JSON.parse(JSON.stringify(item))}
        fallbackImageUrl={resolved.imageBorrowed ? resolved.imageUrl : null}
        fallbackImageKey={resolved.imageBorrowed ? resolved.imageKey : null}
      />
    </div>
  )
}
