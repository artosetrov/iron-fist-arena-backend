'use client'

import { useState } from 'react'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Textarea } from '@/components/ui/textarea'
import { Switch } from '@/components/ui/switch'
import {
  Table, TableHeader, TableRow, TableHead, TableBody, TableCell,
} from '@/components/ui/table'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter,
} from '@/components/ui/dialog'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import {
  createShopOffer, updateShopOffer, toggleShopOffer,
  deleteShopOffer, seedDefaultOffers, listShopOffers, getOfferStats,
} from '@/actions/shop-offers'
import {
  Plus, Trash2, Edit, Sprout, ShoppingBag, Package, Zap, Gift,
} from 'lucide-react'

type ContentItem = { type: string; id?: string; quantity: number }

type Offer = {
  id: string
  key: string
  title: string
  description: string | null
  offerType: string
  contents: ContentItem[]
  originalPrice: number
  salePrice: number
  currency: string
  discountPct: number
  maxPurchases: number
  minLevel: number
  maxLevel: number
  sortOrder: number
  imageKey: string | null
  tags: string[]
  isActive: boolean
  startsAt: string | null
  endsAt: string | null
  createdBy: string | null
  createdAt: string
  _count: { purchases: number }
}

type Stats = { total: number; active: number; totalPurchases: number; totalRevenue: number }

const OFFER_TYPES = [
  { value: 'bundle', label: 'Bundle' },
  { value: 'daily_deal', label: 'Daily Deal' },
  { value: 'flash_sale', label: 'Flash Sale' },
  { value: 'starter_pack', label: 'Starter Pack' },
  { value: 'level_up', label: 'Level-Up' },
]

const CONTENT_TYPES = ['gold', 'gems', 'xp', 'consumable', 'item']

const typeColors: Record<string, string> = {
  bundle: 'bg-blue-500/20 text-blue-400',
  daily_deal: 'bg-yellow-500/20 text-yellow-400',
  flash_sale: 'bg-red-500/20 text-red-400',
  starter_pack: 'bg-green-500/20 text-green-400',
  level_up: 'bg-purple-500/20 text-purple-400',
}

const typeIcons: Record<string, any> = {
  bundle: Package,
  flash_sale: Zap,
  starter_pack: Gift,
  daily_deal: ShoppingBag,
  level_up: Sprout,
}

export function OffersClient({ initialOffers, stats: initialStats }: {
  initialOffers: Offer[]
  stats: Stats
}) {
  const [offers, setOffers] = useState<Offer[]>(initialOffers)
  const [stats, setStats] = useState<Stats>(initialStats)
  const [search, setSearch] = useState('')
  const [typeFilter, setTypeFilter] = useState('all')
  const [showDialog, setShowDialog] = useState(false)
  const [editId, setEditId] = useState<string | null>(null)
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  // Form state
  const [form, setForm] = useState({
    key: '', title: '', description: '', offerType: 'bundle',
    originalPrice: 0, salePrice: 0, currency: 'gold', discountPct: 0,
    maxPurchases: 1, minLevel: 1, maxLevel: 999, sortOrder: 0,
    imageKey: '', tags: '', isActive: false,
    startsAt: '', endsAt: '',
  })
  const [contents, setContents] = useState<ContentItem[]>([])

  const refresh = async () => {
    const [o, s] = await Promise.all([listShopOffers(), getOfferStats()])
    setOffers(JSON.parse(JSON.stringify(o)))
    setStats(s)
  }

  const openCreate = () => {
    setEditId(null)
    setForm({
      key: '', title: '', description: '', offerType: 'bundle',
      originalPrice: 0, salePrice: 0, currency: 'gold', discountPct: 0,
      maxPurchases: 1, minLevel: 1, maxLevel: 999, sortOrder: 0,
      imageKey: '', tags: '', isActive: false, startsAt: '', endsAt: '',
    })
    setContents([{ type: 'gold', quantity: 100 }])
    setShowDialog(true)
  }

  const openEdit = (offer: Offer) => {
    setEditId(offer.id)
    setForm({
      key: offer.key,
      title: offer.title,
      description: offer.description ?? '',
      offerType: offer.offerType,
      originalPrice: offer.originalPrice,
      salePrice: offer.salePrice,
      currency: offer.currency,
      discountPct: offer.discountPct,
      maxPurchases: offer.maxPurchases,
      minLevel: offer.minLevel,
      maxLevel: offer.maxLevel,
      sortOrder: offer.sortOrder,
      imageKey: offer.imageKey ?? '',
      tags: offer.tags.join(', '),
      isActive: offer.isActive,
      startsAt: offer.startsAt ? offer.startsAt.slice(0, 16) : '',
      endsAt: offer.endsAt ? offer.endsAt.slice(0, 16) : '',
    })
    setContents(offer.contents ?? [])
    setShowDialog(true)
  }

  const handleSave = async () => {
    setLoading(true)
    try {
      const data = {
        key: form.key,
        title: form.title,
        description: form.description || undefined,
        offerType: form.offerType,
        contents,
        originalPrice: form.originalPrice,
        salePrice: form.salePrice,
        currency: form.currency,
        discountPct: form.discountPct,
        maxPurchases: form.maxPurchases,
        minLevel: form.minLevel,
        maxLevel: form.maxLevel,
        sortOrder: form.sortOrder,
        imageKey: form.imageKey || undefined,
        tags: form.tags ? form.tags.split(',').map(t => t.trim()).filter(Boolean) : [],
        isActive: form.isActive,
        startsAt: form.startsAt || null,
        endsAt: form.endsAt || null,
      }
      if (editId) {
        await updateShopOffer({ id: editId, ...data })
      } else {
        await createShopOffer(data)
      }
      setShowDialog(false)
      await refresh()
    } finally {
      setLoading(false)
    }
  }

  const handleToggle = async (id: string) => {
    await toggleShopOffer(id)
    await refresh()
  }

  const handleDelete = async () => {
    if (!deleteId) return
    await deleteShopOffer(deleteId)
    setDeleteId(null)
    await refresh()
  }

  const handleSeed = async () => {
    setLoading(true)
    try {
      await seedDefaultOffers()
      await refresh()
    } finally {
      setLoading(false)
    }
  }

  const addContent = () => setContents([...contents, { type: 'gold', quantity: 100 }])
  const removeContent = (i: number) => setContents(contents.filter((_, idx) => idx !== i))
  const updateContent = (i: number, field: string, value: any) => {
    const copy = [...contents]
    ;(copy[i] as any)[field] = value
    setContents(copy)
  }

  const filtered = offers.filter(o => {
    if (typeFilter !== 'all' && o.offerType !== typeFilter) return false
    if (search) {
      const q = search.toLowerCase()
      return o.key.toLowerCase().includes(q) || o.title.toLowerCase().includes(q)
    }
    return true
  })

  const formatDate = (d: string | null) => {
    if (!d) return '—'
    return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Shop Offers & Bundles</h1>
        <div className="flex gap-2">
          <Button variant="outline" onClick={handleSeed} disabled={loading}>
            <Sprout className="w-4 h-4 mr-1" /> Seed Defaults
          </Button>
          <Button onClick={openCreate}>
            <Plus className="w-4 h-4 mr-1" /> New Offer
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <Card><CardContent className="pt-4">
          <p className="text-sm text-muted-foreground">Total Offers</p>
          <p className="text-2xl font-bold">{stats.total}</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4">
          <p className="text-sm text-muted-foreground">Active</p>
          <p className="text-2xl font-bold text-green-400">{stats.active}</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4">
          <p className="text-sm text-muted-foreground">Total Purchases</p>
          <p className="text-2xl font-bold">{stats.totalPurchases}</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4">
          <p className="text-sm text-muted-foreground">Total Revenue</p>
          <p className="text-2xl font-bold">{stats.totalRevenue.toLocaleString()}</p>
        </CardContent></Card>
      </div>

      {/* Filters */}
      <div className="flex gap-3">
        <Input
          placeholder="Search by key or title..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="max-w-xs"
        />
        <Select value={typeFilter} onValueChange={setTypeFilter}>
          <SelectTrigger className="w-40"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Types</SelectItem>
            {OFFER_TYPES.map(t => (
              <SelectItem key={t.value} value={t.value}>{t.label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Table */}
      <Card>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Offer</TableHead>
              <TableHead>Type</TableHead>
              <TableHead>Price</TableHead>
              <TableHead>Discount</TableHead>
              <TableHead>Purchases</TableHead>
              <TableHead>Levels</TableHead>
              <TableHead>Schedule</TableHead>
              <TableHead>Active</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filtered.map(offer => {
              const Icon = typeIcons[offer.offerType] ?? Package
              return (
                <TableRow key={offer.id}>
                  <TableCell>
                    <div>
                      <span className="font-medium">{offer.title}</span>
                      <br />
                      <span className="text-xs text-muted-foreground font-mono">{offer.key}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge className={typeColors[offer.offerType] ?? 'bg-gray-500/20 text-gray-400'}>
                      <Icon className="w-3 h-3 mr-1" />
                      {offer.offerType}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div>
                      <span className="line-through text-muted-foreground text-xs">{offer.originalPrice}</span>
                      {' '}
                      <span className="font-bold">{offer.salePrice}</span>
                      {' '}
                      <span className="text-xs">{offer.currency === 'gems' ? '💎' : '💰'}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    {offer.discountPct > 0 && (
                      <Badge variant="destructive">-{offer.discountPct}%</Badge>
                    )}
                  </TableCell>
                  <TableCell>
                    {offer._count.purchases}
                    {offer.maxPurchases > 0 && <span className="text-xs text-muted-foreground">/{offer.maxPurchases}</span>}
                  </TableCell>
                  <TableCell className="text-xs">
                    {offer.minLevel}–{offer.maxLevel}
                  </TableCell>
                  <TableCell className="text-xs">
                    {formatDate(offer.startsAt)} → {formatDate(offer.endsAt)}
                  </TableCell>
                  <TableCell>
                    <Switch
                      checked={offer.isActive}
                      onCheckedChange={() => handleToggle(offer.id)}
                    />
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-1">
                      <Button size="sm" variant="ghost" onClick={() => openEdit(offer)}>
                        <Edit className="w-4 h-4" />
                      </Button>
                      <Button size="sm" variant="ghost" onClick={() => setDeleteId(offer.id)}>
                        <Trash2 className="w-4 h-4 text-red-400" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              )
            })}
            {filtered.length === 0 && (
              <TableRow>
                <TableCell colSpan={9} className="text-center text-muted-foreground py-8">
                  No offers found. Create one or seed defaults.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editId ? 'Edit Offer' : 'Create Offer'}</DialogTitle>
          </DialogHeader>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Key</Label>
              <Input value={form.key} onChange={e => setForm({ ...form, key: e.target.value })} placeholder="starter_pack" />
            </div>
            <div>
              <Label>Title</Label>
              <Input value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} placeholder="Starter Pack" />
            </div>
            <div className="col-span-2">
              <Label>Description</Label>
              <Textarea value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} rows={2} />
            </div>
            <div>
              <Label>Offer Type</Label>
              <Select value={form.offerType} onValueChange={v => setForm({ ...form, offerType: v })}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {OFFER_TYPES.map(t => <SelectItem key={t.value} value={t.value}>{t.label}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>Currency</Label>
              <Select value={form.currency} onValueChange={v => setForm({ ...form, currency: v })}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="gold">Gold 💰</SelectItem>
                  <SelectItem value="gems">Gems 💎</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>Original Price</Label>
              <Input type="number" value={form.originalPrice} onChange={e => setForm({ ...form, originalPrice: +e.target.value })} />
            </div>
            <div>
              <Label>Sale Price</Label>
              <Input type="number" value={form.salePrice} onChange={e => setForm({ ...form, salePrice: +e.target.value })} />
            </div>
            <div>
              <Label>Discount %</Label>
              <Input type="number" value={form.discountPct} onChange={e => setForm({ ...form, discountPct: +e.target.value })} min={0} max={100} />
            </div>
            <div>
              <Label>Max Purchases (0=unlimited)</Label>
              <Input type="number" value={form.maxPurchases} onChange={e => setForm({ ...form, maxPurchases: +e.target.value })} min={0} />
            </div>
            <div>
              <Label>Min Level</Label>
              <Input type="number" value={form.minLevel} onChange={e => setForm({ ...form, minLevel: +e.target.value })} min={1} />
            </div>
            <div>
              <Label>Max Level</Label>
              <Input type="number" value={form.maxLevel} onChange={e => setForm({ ...form, maxLevel: +e.target.value })} min={1} />
            </div>
            <div>
              <Label>Sort Order</Label>
              <Input type="number" value={form.sortOrder} onChange={e => setForm({ ...form, sortOrder: +e.target.value })} />
            </div>
            <div>
              <Label>Tags (comma-separated)</Label>
              <Input value={form.tags} onChange={e => setForm({ ...form, tags: e.target.value })} placeholder="featured, new_player" />
            </div>
            <div>
              <Label>Starts At</Label>
              <Input type="datetime-local" value={form.startsAt} onChange={e => setForm({ ...form, startsAt: e.target.value })} />
            </div>
            <div>
              <Label>Ends At</Label>
              <Input type="datetime-local" value={form.endsAt} onChange={e => setForm({ ...form, endsAt: e.target.value })} />
            </div>
          </div>

          {/* Contents editor */}
          <div className="mt-4">
            <div className="flex items-center justify-between mb-2">
              <Label className="text-base font-semibold">Bundle Contents</Label>
              <Button size="sm" variant="outline" onClick={addContent}>
                <Plus className="w-3 h-3 mr-1" /> Add Item
              </Button>
            </div>
            <div className="space-y-2">
              {contents.map((item, i) => (
                <div key={i} className="flex gap-2 items-center">
                  <Select value={item.type} onValueChange={v => updateContent(i, 'type', v)}>
                    <SelectTrigger className="w-32"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {CONTENT_TYPES.map(t => <SelectItem key={t} value={t}>{t}</SelectItem>)}
                    </SelectContent>
                  </Select>
                  {(item.type === 'consumable' || item.type === 'item') && (
                    <Input
                      value={item.id ?? ''}
                      onChange={e => updateContent(i, 'id', e.target.value)}
                      placeholder="consumable_type or item_id"
                      className="flex-1"
                    />
                  )}
                  <Input
                    type="number"
                    value={item.quantity}
                    onChange={e => updateContent(i, 'quantity', +e.target.value)}
                    className="w-24"
                    min={1}
                  />
                  <Button size="sm" variant="ghost" onClick={() => removeContent(i)}>
                    <Trash2 className="w-3 h-3" />
                  </Button>
                </div>
              ))}
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDialog(false)}>Cancel</Button>
            <Button onClick={handleSave} disabled={loading || !form.key || !form.title || contents.length === 0}>
              {editId ? 'Update' : 'Create'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={!!deleteId} onOpenChange={() => setDeleteId(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Offer?</DialogTitle>
          </DialogHeader>
          <p className="text-muted-foreground">This will permanently delete this offer and all purchase records. This cannot be undone.</p>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteId(null)}>Cancel</Button>
            <Button variant="destructive" onClick={handleDelete}>Delete</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
