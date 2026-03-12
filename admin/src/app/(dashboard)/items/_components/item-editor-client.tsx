'use client'

import { useState, useTransition, useEffect, useRef, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Separator } from '@/components/ui/separator'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import {
  ArrowLeft, Save, Upload, X, Wand2,
  Swords, BarChart3, TrendingUp, Sparkles, Coins, Image as ImageIcon, FileText,
} from 'lucide-react'
import { uploadAsset } from '@/actions/assets'
import {
  ITEM_TYPES, RARITIES, CLASS_RESTRICTIONS, STAT_KEYS, SCALING_TYPES,
  UPGRADE_STAT_KEYS, IMAGE_STYLES, IMAGE_SIZES,
  EMPTY_FORM, generateCatalogId,
  type ItemFormData,
} from '@/lib/item-constants'
import { ItemPreviewCard } from './item-preview-card'

type DbItem = {
  id: string
  catalogId: string
  itemName: string
  itemType: string
  rarity: string
  itemLevel: number
  baseStats: unknown
  specialEffect: string | null
  uniquePassive: string | null
  classRestriction: string | null
  setName: string | null
  buyPrice: number
  sellPrice: number
  description: string | null
  imageUrl: string | null
  imageKey: string | null
  dropChance: number | null
  itemClass: string | null
  upgradeConfig: unknown
}

export function ItemEditorClient({ item }: { item: DbItem | null }) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [form, setForm] = useState<ItemFormData>(EMPTY_FORM)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [catalogIdManual, setCatalogIdManual] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  // Populate form from existing item
  useEffect(() => {
    if (item) {
      const stats = (item.baseStats as Record<string, number>) ?? {}
      const uc = (item.upgradeConfig as Record<string, unknown>) ?? {}
      setForm({
        catalogId: item.catalogId,
        itemName: item.itemName,
        itemType: item.itemType,
        itemClass: item.itemClass ?? '',
        rarity: item.rarity,
        itemLevel: item.itemLevel,
        classRestriction: item.classRestriction ?? 'none',
        setName: item.setName ?? '',
        stats,
        maxUpgradeLevel: (uc.maxLevel as number) ?? 10,
        scalingType: (uc.scalingType as string) ?? 'linear',
        upgradeScaling: (uc.perLevel as Record<string, number>) ?? {},
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
      })
      setCatalogIdManual(true) // don't auto-overwrite existing catalog IDs
    }
  }, [item])

  // Auto-generate catalog ID and imageKey for new items
  useEffect(() => {
    if (!catalogIdManual && form.itemName && form.itemType) {
      const id = generateCatalogId(form.itemType, form.itemName)
      setForm(prev => ({ ...prev, catalogId: id, imageKey: id }))
    }
  }, [form.itemType, form.itemName, catalogIdManual])

  const updateField = useCallback(<K extends keyof ItemFormData>(key: K, value: ItemFormData[K]) => {
    setForm(prev => ({ ...prev, [key]: value }))
  }, [])

  const updateStat = useCallback((key: string, value: number) => {
    setForm(prev => ({ ...prev, stats: { ...prev.stats, [key]: value } }))
  }, [])

  const updateUpgradeStat = useCallback((key: string, value: number) => {
    setForm(prev => ({ ...prev, upgradeScaling: { ...prev.upgradeScaling, [key]: value } }))
  }, [])

  // Image upload
  async function handleImageUpload(fileList: FileList | null) {
    if (!fileList || fileList.length === 0) return

    const file = fileList[0]
    if (!file.type.match(/^image\/(png|jpe?g|webp)$/)) {
      setError('Only PNG, JPG, and WebP images are allowed.')
      return
    }
    if (file.size > 2 * 1024 * 1024) {
      setError('Image must be under 2MB.')
      return
    }

    setError('')
    const slug = form.catalogId || `item_${Date.now()}`
    const ext = file.name.split('.').pop() ?? 'png'
    const uploadPath = `items/${slug}.${ext}`
    const formData = new FormData()
    formData.append('file', file)

    startTransition(async () => {
      try {
        const result = await uploadAsset('assets', uploadPath, formData)
        updateField('imageUrl', result.publicUrl)
        setSuccess('Image uploaded successfully.')
        setTimeout(() => setSuccess(''), 3000)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Upload failed')
      }
    })
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault()
    handleImageUpload(e.dataTransfer.files)
  }

  // Save handler
  async function handleSave() {
    setError('')
    setSuccess('')

    if (!form.itemName.trim()) {
      setError('Item Name is required.')
      return
    }
    if (!form.catalogId.trim()) {
      setError('Catalog ID is required.')
      return
    }

    // Filter out zero stats to keep JSON clean
    const cleanStats: Record<string, number> = {}
    for (const [k, v] of Object.entries(form.stats)) {
      if (v && v !== 0) cleanStats[k] = v
    }

    const cleanUpgradeScaling: Record<string, number> = {}
    for (const [k, v] of Object.entries(form.upgradeScaling)) {
      if (v && v !== 0) cleanUpgradeScaling[k] = v
    }

    const body = {
      catalogId: form.catalogId,
      itemName: form.itemName,
      itemType: form.itemType,
      itemClass: form.itemClass || null,
      rarity: form.rarity,
      itemLevel: form.itemLevel,
      baseStats: cleanStats,
      specialEffect: form.specialEffect || null,
      uniquePassive: form.uniquePassive || null,
      classRestriction: form.classRestriction === 'none' ? null : form.classRestriction,
      setName: form.setName || null,
      buyPrice: form.buyPrice,
      sellPrice: form.sellPrice,
      dropChance: form.dropChance,
      upgradeConfig: {
        maxLevel: form.maxUpgradeLevel,
        scalingType: form.scalingType,
        perLevel: cleanUpgradeScaling,
      },
      description: form.description || null,
      imageUrl: form.imageUrl || null,
      imageKey: form.imageKey || form.catalogId || null,
    }

    startTransition(async () => {
      try {
        const res = await fetch('/api/items', {
          method: item ? 'PUT' : 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(item ? { id: item.id, ...body } : body),
        })
        if (!res.ok) {
          const data = await res.json()
          setError(data.error || 'Failed to save item')
          return
        }
        router.push('/items')
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save item')
      }
    })
  }

  return (
    <div className="flex gap-6 items-start">
      {/* Left: Tabbed Form */}
      <div className="flex-1 min-w-0 space-y-4">
        {error && (
          <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
            {error}
          </div>
        )}
        {success && (
          <div className="rounded-md bg-green-600/10 border border-green-600/30 px-4 py-3 text-sm text-green-400">
            {success}
          </div>
        )}

        <Tabs defaultValue="basic" className="w-full">
          <TabsList className="w-full justify-start flex-wrap h-auto gap-1 bg-transparent p-0">
            <TabsTrigger value="basic" className="gap-1.5 data-[state=active]:bg-muted">
              <Swords className="h-3.5 w-3.5" /> Basic
            </TabsTrigger>
            <TabsTrigger value="stats" className="gap-1.5 data-[state=active]:bg-muted">
              <BarChart3 className="h-3.5 w-3.5" /> Stats
            </TabsTrigger>
            <TabsTrigger value="upgrade" className="gap-1.5 data-[state=active]:bg-muted">
              <TrendingUp className="h-3.5 w-3.5" /> Upgrade
            </TabsTrigger>
            <TabsTrigger value="effects" className="gap-1.5 data-[state=active]:bg-muted">
              <Sparkles className="h-3.5 w-3.5" /> Effects
            </TabsTrigger>
            <TabsTrigger value="economy" className="gap-1.5 data-[state=active]:bg-muted">
              <Coins className="h-3.5 w-3.5" /> Economy
            </TabsTrigger>
            <TabsTrigger value="image" className="gap-1.5 data-[state=active]:bg-muted">
              <ImageIcon className="h-3.5 w-3.5" /> Image
            </TabsTrigger>
            <TabsTrigger value="description" className="gap-1.5 data-[state=active]:bg-muted">
              <FileText className="h-3.5 w-3.5" /> Description
            </TabsTrigger>
          </TabsList>

          {/* ─── BASIC INFO ─── */}
          <TabsContent value="basic" className="space-y-4 mt-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="itemName">Item Name *</Label>
                <Input
                  id="itemName"
                  value={form.itemName}
                  onChange={e => updateField('itemName', e.target.value)}
                  placeholder="Iron Sword"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="catalogId">
                  Catalog ID *
                  {!catalogIdManual && (
                    <span className="ml-2 text-xs text-muted-foreground">(auto)</span>
                  )}
                </Label>
                <Input
                  id="catalogId"
                  value={form.catalogId}
                  onChange={e => {
                    setCatalogIdManual(true)
                    updateField('catalogId', e.target.value)
                  }}
                  placeholder="wpn_iron_sword"
                  required
                />
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>Item Type</Label>
                <Select value={form.itemType} onValueChange={v => updateField('itemType', v)}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {ITEM_TYPES.map(t => (
                      <SelectItem key={t} value={t}>
                        {t.charAt(0).toUpperCase() + t.slice(1)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Rarity</Label>
                <Select value={form.rarity} onValueChange={v => updateField('rarity', v)}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {RARITIES.map(r => (
                      <SelectItem key={r} value={r}>
                        {r.charAt(0).toUpperCase() + r.slice(1)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="itemLevel">Item Level</Label>
                <Input
                  id="itemLevel"
                  type="number"
                  min={1}
                  value={form.itemLevel}
                  onChange={e => updateField('itemLevel', Number(e.target.value))}
                />
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="itemClass">Item Class</Label>
                <Input
                  id="itemClass"
                  value={form.itemClass}
                  onChange={e => updateField('itemClass', e.target.value)}
                  placeholder="sword, axe, bow..."
                />
              </div>
              <div className="space-y-2">
                <Label>Class Restriction</Label>
                <Select value={form.classRestriction} onValueChange={v => updateField('classRestriction', v)}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {CLASS_RESTRICTIONS.map(c => (
                      <SelectItem key={c} value={c}>
                        {c.charAt(0).toUpperCase() + c.slice(1)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="setName">Set Name</Label>
                <Input
                  id="setName"
                  value={form.setName}
                  onChange={e => updateField('setName', e.target.value)}
                  placeholder="Dragon Set"
                />
              </div>
            </div>
          </TabsContent>

          {/* ─── STATS ─── */}
          <TabsContent value="stats" className="space-y-4 mt-4">
            <p className="text-sm text-muted-foreground">
              Set base stat values. Only non-zero stats are saved.
            </p>
            <div className="grid grid-cols-3 gap-4">
              {STAT_KEYS.map(s => (
                <div key={s.key} className="space-y-2">
                  <Label htmlFor={`stat-${s.key}`}>{s.label}</Label>
                  <Input
                    id={`stat-${s.key}`}
                    type="number"
                    min={0}
                    value={form.stats[s.key] ?? 0}
                    onChange={e => updateStat(s.key, Number(e.target.value))}
                  />
                </div>
              ))}
            </div>
          </TabsContent>

          {/* ─── UPGRADE ─── */}
          <TabsContent value="upgrade" className="space-y-4 mt-4">
            <p className="text-sm text-muted-foreground">
              Configure how this item scales with upgrades (+1 through +max).
            </p>
            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="maxUpgrade">Max Upgrade Level</Label>
                <Input
                  id="maxUpgrade"
                  type="number"
                  min={0}
                  max={15}
                  value={form.maxUpgradeLevel}
                  onChange={e => updateField('maxUpgradeLevel', Number(e.target.value))}
                />
              </div>
              <div className="space-y-2">
                <Label>Scaling Type</Label>
                <Select value={form.scalingType} onValueChange={v => updateField('scalingType', v)}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {SCALING_TYPES.map(s => (
                      <SelectItem key={s} value={s}>
                        {s.charAt(0).toUpperCase() + s.slice(1)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <Separator />
            <p className="text-sm font-medium">Per Upgrade Level Increase</p>
            <div className="grid grid-cols-3 gap-4">
              {UPGRADE_STAT_KEYS.map(s => (
                <div key={s.key} className="space-y-2">
                  <Label htmlFor={`upgrade-${s.key}`}>{s.label}</Label>
                  <Input
                    id={`upgrade-${s.key}`}
                    type="number"
                    min={0}
                    step={0.1}
                    value={form.upgradeScaling[s.key] ?? 0}
                    onChange={e => updateUpgradeStat(s.key, Number(e.target.value))}
                  />
                </div>
              ))}
            </div>
          </TabsContent>

          {/* ─── EFFECTS ─── */}
          <TabsContent value="effects" className="space-y-4 mt-4">
            <div className="space-y-2">
              <Label htmlFor="specialEffect">Special Effect</Label>
              <Input
                id="specialEffect"
                value={form.specialEffect}
                onChange={e => updateField('specialEffect', e.target.value)}
                placeholder="+20% all damage, +10% crit"
              />
              <p className="text-xs text-muted-foreground">Active ability or on-hit effect text</p>
            </div>
            <div className="space-y-2">
              <Label htmlFor="uniquePassive">Unique Passive</Label>
              <Input
                id="uniquePassive"
                value={form.uniquePassive}
                onChange={e => updateField('uniquePassive', e.target.value)}
                placeholder="Critical hits restore 5% HP"
              />
              <p className="text-xs text-muted-foreground">Always-active passive bonus text</p>
            </div>
          </TabsContent>

          {/* ─── ECONOMY ─── */}
          <TabsContent value="economy" className="space-y-4 mt-4">
            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="buyPrice">Buy Price (gold)</Label>
                <Input
                  id="buyPrice"
                  type="number"
                  min={0}
                  value={form.buyPrice}
                  onChange={e => updateField('buyPrice', Number(e.target.value))}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="sellPrice">Sell Price (gold)</Label>
                <Input
                  id="sellPrice"
                  type="number"
                  min={0}
                  value={form.sellPrice}
                  onChange={e => updateField('sellPrice', Number(e.target.value))}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="dropChance">Drop Chance (0-1)</Label>
                <Input
                  id="dropChance"
                  type="number"
                  min={0}
                  max={1}
                  step={0.01}
                  value={form.dropChance}
                  onChange={e => updateField('dropChance', Number(e.target.value))}
                />
              </div>
            </div>
          </TabsContent>

          {/* ─── IMAGE ─── */}
          <TabsContent value="image" className="space-y-4 mt-4">
            {/* Upload area */}
            <div
              className="border-2 border-dashed border-border rounded-lg p-6 text-center cursor-pointer hover:border-primary/50 transition-colors"
              onDrop={handleDrop}
              onDragOver={e => e.preventDefault()}
              onClick={() => fileInputRef.current?.click()}
            >
              <Upload className="mx-auto h-8 w-8 text-muted-foreground mb-2" />
              <p className="text-sm text-muted-foreground">
                Drag & drop an image, or click to browse
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                PNG, JPG, WebP &middot; Max 2MB
              </p>
              <input
                ref={fileInputRef}
                type="file"
                accept=".png,.jpg,.jpeg,.webp"
                className="hidden"
                onChange={e => handleImageUpload(e.target.files)}
              />
            </div>

            {/* Manual URL input */}
            <div className="space-y-2">
              <Label htmlFor="imageUrl">Or paste Image URL manually</Label>
              <Input
                id="imageUrl"
                value={form.imageUrl}
                onChange={e => updateField('imageUrl', e.target.value)}
                placeholder="https://..."
              />
            </div>

            {/* Current image preview */}
            {form.imageUrl && (
              <div className="flex items-start gap-3">
                <div className="w-24 h-24 rounded-lg border border-border overflow-hidden bg-muted">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={form.imageUrl} key={form.imageUrl} alt="Item" className="w-full h-full object-cover" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-muted-foreground truncate">{form.imageUrl}</p>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="mt-1 text-destructive"
                    onClick={() => updateField('imageUrl', '')}
                  >
                    <X className="h-3.5 w-3.5 mr-1" /> Remove
                  </Button>
                </div>
              </div>
            )}

            <Separator />
            <div className="space-y-2">
              <Label htmlFor="imageKey">Image Key (iOS Asset Catalog)</Label>
              <Input
                id="imageKey"
                value={form.imageKey}
                onChange={e => updateField('imageKey', e.target.value)}
                placeholder="wpn_iron_sword"
              />
              <p className="text-xs text-muted-foreground">
                Used by the iOS app to load a local bundled image. Auto-generated from Catalog ID.
              </p>
            </div>
            <Separator />
            <p className="text-sm font-medium flex items-center gap-1.5">
              <Wand2 className="h-4 w-4" /> AI Generation (metadata)
            </p>
            <p className="text-xs text-muted-foreground">
              These fields are saved client-side for future AI image generation integration.
            </p>
            <div className="space-y-2">
              <Label htmlFor="imagePrompt">Image Prompt</Label>
              <Textarea
                id="imagePrompt"
                value={form.imagePrompt}
                onChange={e => updateField('imagePrompt', e.target.value)}
                placeholder="A glowing legendary sword with dragon engravings..."
                rows={2}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Image Style</Label>
                <Select value={form.imageStyle} onValueChange={v => updateField('imageStyle', v)}>
                  <SelectTrigger><SelectValue placeholder="Select style" /></SelectTrigger>
                  <SelectContent>
                    {IMAGE_STYLES.map(s => (
                      <SelectItem key={s} value={s}>{s}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Image Size</Label>
                <Select value={form.imageSize} onValueChange={v => updateField('imageSize', v)}>
                  <SelectTrigger><SelectValue placeholder="Select size" /></SelectTrigger>
                  <SelectContent>
                    {IMAGE_SIZES.map(s => (
                      <SelectItem key={s} value={s}>{s}x{s}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
          </TabsContent>

          {/* ─── DESCRIPTION ─── */}
          <TabsContent value="description" className="space-y-4 mt-4">
            <div className="space-y-2">
              <Label htmlFor="description">Item Description / Lore</Label>
              <Textarea
                id="description"
                value={form.description}
                onChange={e => updateField('description', e.target.value)}
                placeholder="The legendary sword of kings..."
                rows={6}
              />
            </div>
          </TabsContent>
        </Tabs>

        {/* Action bar */}
        <Separator />
        <div className="flex items-center justify-between pt-2">
          <Button type="button" variant="outline" onClick={() => router.push('/items')}>
            <ArrowLeft className="h-4 w-4 mr-2" /> Back to Items
          </Button>
          <Button onClick={handleSave} disabled={isPending}>
            <Save className="h-4 w-4 mr-2" />
            {isPending ? 'Saving...' : item ? 'Update Item' : 'Create Item'}
          </Button>
        </div>
      </div>

      {/* Right: Sticky Preview */}
      <div className="w-[340px] shrink-0 hidden lg:block">
        <div className="sticky top-6">
          <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-3">Live Preview</p>
          <ItemPreviewCard form={form} />
        </div>
      </div>
    </div>
  )
}
