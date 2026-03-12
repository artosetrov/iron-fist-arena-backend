import { ItemEditorClient } from '../_components/item-editor-client'

export default function NewItemPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Create Item</h1>
        <p className="text-muted-foreground">Add a new item to the catalog.</p>
      </div>
      <ItemEditorClient item={null} />
    </div>
  )
}
