'use client'

import { useState, useTransition, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { createAppearance, updateAppearance, deleteAppearance } from '@/actions/appearances'
import { uploadAsset } from '@/actions/assets'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Switch } from '@/components/ui/switch'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from '@/components/ui/dialog'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import { Plus, Pencil, Trash2, Upload, ImageIcon, Coins } from 'lucide-react'

type Skin = {
  id: string
  skinKey: string
  name: string
  origin: string
  gender: string
  rarity: string
  priceGold: number
  priceGems: number
  imageUrl: string | null
  imageKey: string | null
  isDefault: boolean
  sortOrder: number
  createdAt: string
}

const ORIGINS = ['human', 'orc', 'skeleton', 'demon', 'dogfolk'] as const
const GENDERS = ['male', 'female'] as const
const RARITIES = ['common', 'rare', 'epic', 'legendary'] as const

const RARITY_COLORS: Record<string, string> = {
  common: 'bg-zinc-600/20 text-zinc-400 border-zinc-600',
  rare: 'bg-blue-600/20 text-blue-400 border-blue-600',
  epic: 'bg-purple-600/20 text-purple-400 border-purple-600',
  legendary: 'bg-orange-600/20 text-orange-400 border-orange-600',
}

const GENDER_COLORS: Record<string, string> = {
  male: 'bg-sky-600/20 text-sky-400 border-sky-600',
  female: 'bg-pink-600/20 text-pink-400 border-pink-600',
}

const ORIGIN_COLORS: Record<string, string> = {
  human: 'bg-amber-600/20 text-amber-400 border-amber-600',
  orc: 'bg-green-600/20 text-green-400 border-green-600',
  skeleton: 'bg-gray-600/20 text-gray-300 border-gray-500',
  demon: 'bg-red-600/20 text-red-400 border-red-600',
  dogfolk: 'bg-teal-600/20 text-teal-400 border-teal-600',
}

const emptyForm = {
  skinKey: '',
  name: '',
  origin: 'human' as string,
  gender: 'male' as string,
  rarity: 'common' as string,
  priceGold: 0,
  priceGems: 0,
  imageUrl: '' as string,
  isDefault: false,
  sortOrder: 0,
}

export function AppearancesClient({ skins }: { skins: Skin[] }) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [dialogOpen, setDialogOpen] = useState(false)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [editingSkin, setEditingSkin] = useState<Skin | null>(null)
  const [deletingSkin, setDeletingSkin] = useState<Skin | null>(null)
  const [form, setForm] = useState(emptyForm)
  const [error, setError] = useState('')
  const [uploading, setUploading] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [filterOrigin, setFilterOrigin] = useState<string>('all')
  const [filterGender, setFilterGender] = useState<string>('all')

  const filteredSkins = skins.filter((s) => {
    if (filterOrigin !== 'all' && s.origin !== filterOrigin) return false
    if (filterGender !== 'all' && s.gender !== filterGender) return false
    return true
  })

  // Group skins by origin for sectioned display
  const skinsByOrigin = ORIGINS.reduce((acc, origin) => {
    const group = filteredSkins.filter((s) => s.origin === origin)
    if (group.length > 0) acc.push({ origin, skins: group })
    return acc
  }, [] as { origin: string; skins: Skin[] }[])

  function openCreate() {
    setEditingSkin(null)
    setForm(emptyForm)
    setError('')
    setDialogOpen(true)
  }

  function openEdit(skin: Skin) {
    setEditingSkin(skin)
    setForm({
      skinKey: skin.skinKey,
      name: skin.name,
      origin: skin.origin,
      gender: skin.gender,
      rarity: skin.rarity,
      priceGold: skin.priceGold,
      priceGems: skin.priceGems,
      imageUrl: skin.imageUrl || '',
      isDefault: skin.isDefault,
      sortOrder: skin.sortOrder,
    })
    setError('')
    setDialogOpen(true)
  }

  async function handleImageUpload(fileList: FileList | null) {
    if (!fileList || fileList.length === 0) return
    const file = fileList[0]

    if (!file.type.startsWith('image/')) {
      setError('Only image files are allowed')
      return
    }

    setUploading(true)
    try {
      const key = form.skinKey || `skin_${Date.now()}`
      const ext = file.name.split('.').pop() || 'png'
      const uploadPath = `appearances/${key}.${ext}`
      const formData = new FormData()
      formData.append('file', file)
      const result = await uploadAsset('assets', uploadPath, formData)
      setForm((prev) => ({ ...prev, imageUrl: result.publicUrl }))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Upload failed')
    } finally {
      setUploading(false)
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')

    if (!form.skinKey.trim()) {
      setError('Skin Key is required')
      return
    }
    if (!form.name.trim()) {
      setError('Name is required')
      return
    }

    startTransition(async () => {
      try {
        const payload = {
          skinKey: form.skinKey.trim(),
          name: form.name.trim(),
          origin: form.origin as 'human' | 'orc' | 'skeleton' | 'demon' | 'dogfolk',
          gender: form.gender as 'male' | 'female',
          rarity: form.rarity,
          priceGold: form.priceGold,
          priceGems: form.priceGems,
          imageUrl: form.imageUrl || null,
          imageKey: form.skinKey.trim() || null,
          isDefault: form.isDefault,
          sortOrder: form.sortOrder,
        }

        if (editingSkin) {
          await updateAppearance(editingSkin.id, payload)
        } else {
          await createAppearance(payload)
        }
        setDialogOpen(false)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save')
      }
    })
  }

  async function handleDelete() {
    if (!deletingSkin) return
    startTransition(async () => {
      try {
        await deleteAppearance(deletingSkin.id)
        setDeleteDialogOpen(false)
        setDeletingSkin(null)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to delete')
      }
    })
  }

  function capitalize(s: string) {
    return s.charAt(0).toUpperCase() + s.slice(1)
  }

  return (
    <>
      {/* Toolbar */}
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <Select value={filterOrigin} onValueChange={setFilterOrigin}>
            <SelectTrigger className="w-36">
              <SelectValue placeholder="Race" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Races</SelectItem>
              {ORIGINS.map((o) => (
                <SelectItem key={o} value={o}>{capitalize(o)}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select value={filterGender} onValueChange={setFilterGender}>
            <SelectTrigger className="w-32">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="male">Male</SelectItem>
              <SelectItem value="female">Female</SelectItem>
            </SelectContent>
          </Select>
          <span className="text-sm text-muted-foreground">
            {filteredSkins.length} skin(s)
          </span>
        </div>
        <Button onClick={openCreate}>
          <Plus className="mr-2 h-4 w-4" />
          Add Skin
        </Button>
      </div>

      {/* Grouped Grid */}
      {filteredSkins.length === 0 ? (
        <div className="rounded-lg border border-border p-8 text-center text-muted-foreground">
          <ImageIcon className="mx-auto h-12 w-12 mb-4 opacity-50" />
          <p>No skins match filters.</p>
        </div>
      ) : (
        <div className="space-y-8">
          {skinsByOrigin.map(({ origin, skins: group }) => (
            <div key={origin}>
              <div className="flex items-center gap-2 mb-3">
                <Badge className={`${ORIGIN_COLORS[origin] ?? ''} text-xs`}>
                  {capitalize(origin)}
                </Badge>
                <span className="text-xs text-muted-foreground">{group.length} skins</span>
              </div>
              <div className="grid gap-3 grid-cols-2 sm:grid-cols-4 md:grid-cols-4 lg:grid-cols-8">
                {group.map((skin) => (
                  <Card
                    key={skin.id}
                    className="overflow-hidden hover:border-primary/50 transition-colors"
                  >
                    <div className="aspect-square bg-muted flex items-center justify-center overflow-hidden relative">
                      {skin.imageUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={skin.imageUrl}
                          key={skin.imageUrl}
                          alt={skin.name}
                          className="w-full h-full object-cover"
                          loading="lazy"
                        />
                      ) : (
                        <ImageIcon className="h-10 w-10 text-muted-foreground opacity-30" />
                      )}
                      {skin.isDefault && (
                        <Badge className="absolute top-0.5 right-0.5 bg-green-600/80 text-white text-[8px] px-1 py-0">
                          DEF
                        </Badge>
                      )}
                    </div>
                    <CardContent className="p-2 space-y-1">
                      <p className="text-xs font-medium truncate">{skin.name}</p>
                      <div className="flex gap-0.5 flex-wrap">
                        <Badge className={`text-[9px] px-1 py-0 ${GENDER_COLORS[skin.gender] ?? ''}`}>
                          {skin.gender === 'male' ? '♂' : '♀'}
                        </Badge>
                        <Badge className={`text-[9px] px-1 py-0 ${RARITY_COLORS[skin.rarity] ?? ''}`}>
                          {skin.rarity}
                        </Badge>
                      </div>
                      {(skin.priceGold > 0 || skin.priceGems > 0) && (
                        <div className="flex items-center gap-1.5 text-[10px] text-muted-foreground">
                          {skin.priceGold > 0 && (
                            <span className="flex items-center gap-0.5">
                              <Coins className="h-2.5 w-2.5 text-yellow-500" />
                              {skin.priceGold}
                            </span>
                          )}
                          {skin.priceGems > 0 && (
                            <span className="flex items-center gap-0.5">
                              <span className="text-cyan-400">&#9670;</span>
                              {skin.priceGems}
                            </span>
                          )}
                        </div>
                      )}
                      <div className="flex justify-end gap-0.5">
                        <Button variant="ghost" size="icon" className="h-6 w-6" onClick={() => openEdit(skin)}>
                          <Pencil className="h-3 w-3" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-6 w-6"
                          onClick={() => {
                            setDeletingSkin(skin)
                            setDeleteDialogOpen(true)
                          }}
                        >
                          <Trash2 className="h-3 w-3 text-destructive" />
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create / Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingSkin ? 'Edit Skin' : 'Add Skin'}</DialogTitle>
            <DialogDescription>
              {editingSkin ? 'Update skin details.' : 'Create a new hero appearance skin.'}
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
              <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
                {error}
              </div>
            )}

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="skinKey">Skin Key</Label>
                <Input
                  id="skinKey"
                  value={form.skinKey}
                  onChange={(e) => setForm({ ...form, skinKey: e.target.value })}
                  placeholder="e.g. human_m_knight"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="name">Display Name</Label>
                <Input
                  id="name"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder="Knight"
                  required
                />
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>Race</Label>
                <Select value={form.origin} onValueChange={(v) => setForm({ ...form, origin: v })}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {ORIGINS.map((o) => (
                      <SelectItem key={o} value={o}>{capitalize(o)}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Gender</Label>
                <Select value={form.gender} onValueChange={(v) => setForm({ ...form, gender: v })}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {GENDERS.map((g) => (
                      <SelectItem key={g} value={g}>{capitalize(g)}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Rarity</Label>
                <Select value={form.rarity} onValueChange={(v) => setForm({ ...form, rarity: v })}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {RARITIES.map((r) => (
                      <SelectItem key={r} value={r}>{capitalize(r)}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="priceGold">Gold</Label>
                <Input
                  id="priceGold"
                  type="number"
                  min={0}
                  value={form.priceGold}
                  onChange={(e) => setForm({ ...form, priceGold: parseInt(e.target.value) || 0 })}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="priceGems">Gems</Label>
                <Input
                  id="priceGems"
                  type="number"
                  min={0}
                  value={form.priceGems}
                  onChange={(e) => setForm({ ...form, priceGems: parseInt(e.target.value) || 0 })}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="sortOrder">Sort</Label>
                <Input
                  id="sortOrder"
                  type="number"
                  value={form.sortOrder}
                  onChange={(e) => setForm({ ...form, sortOrder: parseInt(e.target.value) || 0 })}
                />
              </div>
            </div>

            <div className="flex items-center gap-3">
              <Switch
                checked={form.isDefault}
                onCheckedChange={(v) => setForm({ ...form, isDefault: v })}
              />
              <Label>Default skin (free for new characters)</Label>
            </div>

            {/* Image Upload */}
            <div className="space-y-2">
              <Label>Image</Label>
              {form.imageUrl ? (
                <div className="space-y-2">
                  <div className="rounded-lg border border-border overflow-hidden bg-muted">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={form.imageUrl}
                      key={form.imageUrl}
                      alt="Preview"
                      className="w-full max-h-48 object-contain"
                    />
                  </div>
                  <div className="flex gap-2">
                    <Input
                      value={form.imageUrl}
                      onChange={(e) => setForm({ ...form, imageUrl: e.target.value })}
                      placeholder="Image URL"
                      className="font-mono text-xs"
                    />
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={() => fileInputRef.current?.click()}
                      disabled={uploading}
                    >
                      {uploading ? 'Uploading...' : 'Replace'}
                    </Button>
                  </div>
                </div>
              ) : (
                <div
                  className="border-2 border-dashed border-border rounded-lg p-6 text-center cursor-pointer hover:border-primary/50 transition-colors"
                  onClick={() => fileInputRef.current?.click()}
                  onDrop={(e) => {
                    e.preventDefault()
                    handleImageUpload(e.dataTransfer.files)
                  }}
                  onDragOver={(e) => e.preventDefault()}
                >
                  <Upload className="mx-auto h-6 w-6 text-muted-foreground mb-1" />
                  <p className="text-sm text-muted-foreground">
                    {uploading ? 'Uploading...' : 'Click or drag image to upload'}
                  </p>
                </div>
              )}
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => handleImageUpload(e.target.files)}
              />
            </div>

            <div className="flex justify-end gap-3 pt-2">
              <Button type="button" variant="outline" onClick={() => setDialogOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={isPending || uploading}>
                {isPending ? 'Saving...' : editingSkin ? 'Update Skin' : 'Create Skin'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Skin</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete &quot;{deletingSkin?.name}&quot;? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
            <Button variant="destructive" onClick={handleDelete} disabled={isPending}>
              {isPending ? 'Deleting...' : 'Delete'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  )
}
