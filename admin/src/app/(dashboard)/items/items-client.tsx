'use client'

import { useState, useTransition, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from '@/components/ui/dialog'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import { Plus, Search, Trash2, Pencil, Eye, Sword } from 'lucide-react'
import { ITEM_TYPES, RARITIES, RARITY_COLORS, type ItemFormData } from '@/lib/item-constants'
import { ItemPreviewModal } from './_components/item-preview-modal'

type Item = {
  id: string
  catalogId: string
  itemName: string
  itemType: string
  rarity: string
  itemLevel: number
  buyPrice: number
  sellPrice: number
  imageUrl: string | null
  imageKey: string | null
  // Full data for preview
  baseStats: Record<string, number> | null
  specialEffect: string | null
  uniquePassive: string | null
  setName: string | null
  description: string | null
  classRestriction: string | null
  upgradeConfig: Record<string, unknown> | null
  dropChance: number | null
  itemClass: string | null
}

export function ItemsClient({ items }: { items: Item[] }) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [search, setSearch] = useState('')
  const [filterType, setFilterType] = useState<string>('all')
  const [filterRarity, setFilterRarity] = useState<string>('all')
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [deletingItem, setDeletingItem] = useState<Item | null>(null)
  const [previewItem, setPreviewItem] = useState<Item | null>(null)
  const [error, setError] = useState('')

  function itemToFormData(item: Item): ItemFormData {
    const cfg = (item.upgradeConfig ?? {}) as Record<string, unknown>
    return {
      catalogId: item.catalogId,
      itemName: item.itemName,
      itemType: item.itemType,
      itemClass: item.itemClass ?? '',
      rarity: item.rarity,
      itemLevel: item.itemLevel,
      classRestriction: item.classRestriction ?? 'none',
      setName: item.setName ?? '',
      stats: (item.baseStats ?? {}) as Record<string, number>,
      maxUpgradeLevel: (cfg.maxLevel as number) ?? 10,
      scalingType: (cfg.scalingType as string) ?? 'linear',
      upgradeScaling: ((cfg.perLevel as Record<string, number>) ?? {}),
      specialEffect: item.specialEffect ?? '',
      uniquePassive: item.uniquePassive ?? '',
      buyPrice: item.buyPrice,
      sellPrice: item.sellPrice,
      dropChance: item.dropChance ?? 0,
      imageUrl: item.imageUrl ?? '',
      imageKey: item.imageKey ?? item.catalogId,
      imagePrompt: '',
      imageStyle: '',
      imageSize: '',
      description: item.description ?? '',
    }
  }

  const filtered = useMemo(() => {
    return items.filter((item) => {
      const matchesSearch = item.itemName.toLowerCase().includes(search.toLowerCase())
      const matchesType = filterType === 'all' || item.itemType === filterType
      const matchesRarity = filterRarity === 'all' || item.rarity === filterRarity
      return matchesSearch && matchesType && matchesRarity
    })
  }, [items, search, filterType, filterRarity])

  function openDelete(item: Item) {
    setDeletingItem(item)
    setDeleteDialogOpen(true)
  }

  async function handleDelete() {
    if (!deletingItem) return
    startTransition(async () => {
      try {
        const res = await fetch(`/api/items?id=${deletingItem.id}`, { method: 'DELETE' })
        if (!res.ok) {
          const data = await res.json()
          setError(data.error || 'Failed to delete item')
          return
        }
        setDeleteDialogOpen(false)
        setDeletingItem(null)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to delete')
      }
    })
  }

  return (
    <>
      {error && (
        <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive mb-4">
          {error}
        </div>
      )}

      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[200px] max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search items..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
        <Select value={filterType} onValueChange={setFilterType}>
          <SelectTrigger className="w-[160px]">
            <SelectValue placeholder="Item Type" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Types</SelectItem>
            {ITEM_TYPES.map((t) => (
              <SelectItem key={t} value={t}>
                {t.charAt(0).toUpperCase() + t.slice(1)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={filterRarity} onValueChange={setFilterRarity}>
          <SelectTrigger className="w-[160px]">
            <SelectValue placeholder="Rarity" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Rarities</SelectItem>
            {RARITIES.map((r) => (
              <SelectItem key={r} value={r}>
                {r.charAt(0).toUpperCase() + r.slice(1)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Button onClick={() => router.push('/items/new')}>
          <Plus className="mr-2 h-4 w-4" />
          Create Item
        </Button>
      </div>

      {/* Table */}
      <div className="rounded-lg border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/50">
              <th className="px-4 py-3 text-left font-medium text-muted-foreground w-10"></th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Name</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Type</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Rarity</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Level</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Buy Price</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Sell Price</th>
              <th className="px-4 py-3 text-right font-medium text-muted-foreground">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={8} className="px-4 py-8 text-center text-muted-foreground">
                  No items found.
                </td>
              </tr>
            ) : (
              filtered.map((item) => (
                <tr
                  key={item.id}
                  className="border-b border-border hover:bg-muted/30 cursor-pointer transition-colors"
                  onClick={() => router.push(`/items/${item.id}/edit`)}
                >
                  <td className="px-4 py-2">
                    <div className={`w-10 h-10 rounded-lg border-2 flex items-center justify-center overflow-hidden ${item.imageUrl ? 'border-green-600/40 bg-muted' : 'border-dashed border-red-500/30 bg-red-500/5'}`}>
                      {item.imageUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={item.imageUrl} alt="" className="w-full h-full object-cover" />
                      ) : (
                        <Sword className="h-4 w-4 text-red-400/40" />
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3 font-medium">{item.itemName}</td>
                  <td className="px-4 py-3">
                    <Badge variant="secondary">{item.itemType}</Badge>
                  </td>
                  <td className="px-4 py-3">
                    <Badge className={RARITY_COLORS[item.rarity] ?? ''}>{item.rarity}</Badge>
                  </td>
                  <td className="px-4 py-3">{item.itemLevel}</td>
                  <td className="px-4 py-3">{item.buyPrice.toLocaleString()}</td>
                  <td className="px-4 py-3">{item.sellPrice.toLocaleString()}</td>
                  <td className="px-4 py-3 text-right">
                    <div className="flex items-center justify-end gap-1">
                      <Button
                        variant="ghost"
                        size="icon"
                        title="Preview"
                        onClick={(e) => {
                          e.stopPropagation()
                          setPreviewItem(item)
                        }}
                      >
                        <Eye className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={(e) => {
                          e.stopPropagation()
                          router.push(`/items/${item.id}/edit`)
                        }}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={(e) => {
                          e.stopPropagation()
                          openDelete(item)
                        }}
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <p className="text-sm text-muted-foreground">
        Showing {filtered.length} of {items.length} items
      </p>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Item</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete &quot;{deletingItem?.itemName}&quot;? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDelete} disabled={isPending}>
              {isPending ? 'Deleting...' : 'Delete'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Item Preview Modal */}
      {previewItem && (
        <ItemPreviewModal
          form={itemToFormData(previewItem)}
          open={!!previewItem}
          onOpenChange={(open) => { if (!open) setPreviewItem(null) }}
        />
      )}
    </>
  )
}
