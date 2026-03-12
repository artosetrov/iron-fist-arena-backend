import { prisma } from '@/lib/prisma'
import { notFound } from 'next/navigation'
import { ItemEditorClient } from '../../_components/item-editor-client'

export default async function EditItemPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const item = await prisma.item.findUnique({ where: { id } })
  if (!item) notFound()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Edit Item</h1>
        <p className="text-muted-foreground">Editing: {item.itemName}</p>
      </div>
      <ItemEditorClient item={JSON.parse(JSON.stringify(item))} />
    </div>
  )
}
