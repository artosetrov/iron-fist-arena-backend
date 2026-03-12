'use client'

import { useState, useTransition, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Switch } from '@/components/ui/switch'
import { Textarea } from '@/components/ui/textarea'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from '@/components/ui/dialog'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import { Plus, Pencil, Trash2, Search } from 'lucide-react'

type Skill = {
  id: string
  skillKey: string
  name: string
  description: string | null
  classRestriction: string | null
  damageBase: number
  damageScaling: unknown
  damageType: string
  targetType: string
  cooldown: number
  manaCost: number
  effectJson: unknown
  unlockLevel: number
  maxRank: number
  rankScaling: number
  icon: string | null
  sortOrder: number
  isActive: boolean
  createdAt: string
}

const CLASS_OPTIONS = ['warrior', 'rogue', 'mage', 'tank'] as const
const DAMAGE_TYPES = ['physical', 'magical', 'true_damage'] as const
const TARGET_TYPES = ['single_enemy', 'self_buff', 'aoe'] as const

const CLASS_COLORS: Record<string, string> = {
  warrior: 'bg-red-600/20 text-red-400 border-red-600',
  rogue: 'bg-green-600/20 text-green-400 border-green-600',
  mage: 'bg-blue-600/20 text-blue-400 border-blue-600',
  tank: 'bg-amber-600/20 text-amber-400 border-amber-600',
}

const emptyForm = {
  skillKey: '',
  name: '',
  description: '',
  classRestriction: '' as string,
  damageBase: 0,
  damageScaling: '{}',
  damageType: 'physical',
  targetType: 'single_enemy',
  cooldown: 0,
  manaCost: 0,
  effectJson: '{}',
  unlockLevel: 1,
  maxRank: 5,
  rankScaling: 0.1,
  icon: '',
  sortOrder: 0,
  isActive: true,
}

function getToken() {
  return document.cookie
    .split('; ')
    .find((c) => c.startsWith('admin-token='))
    ?.split('=')[1]
}

function getApiUrl() {
  return process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001'
}

function formatLabel(value: string) {
  return value
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase())
}

export function SkillsClient({ skills }: { skills: Skill[] }) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [search, setSearch] = useState('')
  const [filterClass, setFilterClass] = useState<string>('all')
  const [dialogOpen, setDialogOpen] = useState(false)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [editingSkill, setEditingSkill] = useState<Skill | null>(null)
  const [deletingSkill, setDeletingSkill] = useState<Skill | null>(null)
  const [form, setForm] = useState(emptyForm)
  const [error, setError] = useState('')

  const filtered = useMemo(() => {
    return skills.filter((skill) => {
      const matchesSearch = skill.name.toLowerCase().includes(search.toLowerCase())
      const matchesClass =
        filterClass === 'all' ||
        (filterClass === 'universal' && !skill.classRestriction) ||
        skill.classRestriction === filterClass
      return matchesSearch && matchesClass
    })
  }, [skills, search, filterClass])

  function openCreate() {
    setEditingSkill(null)
    setForm(emptyForm)
    setError('')
    setDialogOpen(true)
  }

  function openEdit(skill: Skill) {
    setEditingSkill(skill)
    setForm({
      skillKey: skill.skillKey,
      name: skill.name,
      description: skill.description || '',
      classRestriction: skill.classRestriction || '',
      damageBase: skill.damageBase,
      damageScaling: JSON.stringify(skill.damageScaling ?? {}, null, 2),
      damageType: skill.damageType,
      targetType: skill.targetType,
      cooldown: skill.cooldown,
      manaCost: skill.manaCost,
      effectJson: JSON.stringify(skill.effectJson ?? {}, null, 2),
      unlockLevel: skill.unlockLevel,
      maxRank: skill.maxRank,
      rankScaling: skill.rankScaling,
      icon: skill.icon || '',
      sortOrder: skill.sortOrder,
      isActive: skill.isActive,
    })
    setError('')
    setDialogOpen(true)
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')

    let parsedDamageScaling: unknown
    try {
      parsedDamageScaling = JSON.parse(form.damageScaling || '{}')
    } catch {
      setError('Invalid JSON in Damage Scaling field')
      return
    }

    let parsedEffectJson: unknown
    try {
      parsedEffectJson = JSON.parse(form.effectJson || '{}')
    } catch {
      setError('Invalid JSON in Effect JSON field')
      return
    }

    const payload = {
      skill_key: form.skillKey,
      name: form.name,
      description: form.description || null,
      class_restriction: form.classRestriction || null,
      damage_base: form.damageBase,
      damage_scaling: parsedDamageScaling,
      damage_type: form.damageType,
      target_type: form.targetType,
      cooldown: form.cooldown,
      mana_cost: form.manaCost,
      effect_json: parsedEffectJson,
      unlock_level: form.unlockLevel,
      max_rank: form.maxRank,
      rank_scaling: form.rankScaling,
      icon: form.icon || null,
      sort_order: form.sortOrder,
      is_active: form.isActive,
    }

    startTransition(async () => {
      try {
        const token = getToken()
        const apiUrl = getApiUrl()
        const url = editingSkill
          ? `${apiUrl}/api/admin/skills`
          : `${apiUrl}/api/admin/skills`
        const res = await fetch(url, {
          method: editingSkill ? 'PUT' : 'POST',
          headers: {
            'Content-Type': 'application/json',
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
          },
          body: JSON.stringify(
            editingSkill ? { id: editingSkill.id, ...payload } : payload
          ),
        })
        if (!res.ok) {
          const data = await res.json().catch(() => ({}))
          setError(data.error || `Failed to ${editingSkill ? 'update' : 'create'} skill`)
          return
        }
        setDialogOpen(false)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save skill')
      }
    })
  }

  async function handleDelete() {
    if (!deletingSkill) return
    startTransition(async () => {
      try {
        const token = getToken()
        const apiUrl = getApiUrl()
        const res = await fetch(`${apiUrl}/api/admin/skills?id=${deletingSkill.id}`, {
          method: 'DELETE',
          headers: {
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
          },
        })
        if (!res.ok) {
          const data = await res.json().catch(() => ({}))
          setError(data.error || 'Failed to delete skill')
          return
        }
        setDeleteDialogOpen(false)
        setDeletingSkill(null)
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
            placeholder="Search skills..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
        <Select value={filterClass} onValueChange={setFilterClass}>
          <SelectTrigger className="w-[160px]">
            <SelectValue placeholder="Class" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Classes</SelectItem>
            {CLASS_OPTIONS.map((c) => (
              <SelectItem key={c} value={c}>
                {formatLabel(c)}
              </SelectItem>
            ))}
            <SelectItem value="universal">Universal</SelectItem>
          </SelectContent>
        </Select>
        <Button onClick={openCreate}>
          <Plus className="mr-2 h-4 w-4" />
          Create Skill
        </Button>
      </div>

      {/* Table */}
      <div className="rounded-lg border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/50">
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Name</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Class</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Damage Base</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Damage Type</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Cooldown</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Unlock Lvl</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Max Rank</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Active</th>
              <th className="px-4 py-3 text-right font-medium text-muted-foreground">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={9} className="px-4 py-8 text-center text-muted-foreground">
                  No skills found.
                </td>
              </tr>
            ) : (
              filtered.map((skill) => (
                <tr
                  key={skill.id}
                  className="border-b border-border hover:bg-muted/30 cursor-pointer transition-colors"
                  onClick={() => openEdit(skill)}
                >
                  <td className="px-4 py-3 font-medium">{skill.name}</td>
                  <td className="px-4 py-3">
                    {skill.classRestriction ? (
                      <Badge className={CLASS_COLORS[skill.classRestriction] ?? ''}>
                        {formatLabel(skill.classRestriction)}
                      </Badge>
                    ) : (
                      <Badge variant="secondary">Universal</Badge>
                    )}
                  </td>
                  <td className="px-4 py-3">{skill.damageBase}</td>
                  <td className="px-4 py-3">
                    <Badge variant="outline">{formatLabel(skill.damageType)}</Badge>
                  </td>
                  <td className="px-4 py-3">{skill.cooldown}</td>
                  <td className="px-4 py-3">{skill.unlockLevel}</td>
                  <td className="px-4 py-3">{skill.maxRank}</td>
                  <td className="px-4 py-3">
                    {skill.isActive ? (
                      <Badge variant="success">Active</Badge>
                    ) : (
                      <Badge variant="secondary">Inactive</Badge>
                    )}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <div className="flex items-center justify-end gap-1">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={(e) => {
                          e.stopPropagation()
                          openEdit(skill)
                        }}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={(e) => {
                          e.stopPropagation()
                          setDeletingSkill(skill)
                          setDeleteDialogOpen(true)
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
        Showing {filtered.length} of {skills.length} skills
      </p>

      {/* Create / Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingSkill ? 'Edit Skill' : 'Create Skill'}</DialogTitle>
            <DialogDescription>
              {editingSkill ? 'Update skill details.' : 'Add a new combat skill to the game.'}
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
              <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
                {error}
              </div>
            )}

            {/* Row 1: Key + Name */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="skillKey">Skill Key</Label>
                <Input
                  id="skillKey"
                  value={form.skillKey}
                  onChange={(e) => setForm({ ...form, skillKey: e.target.value })}
                  placeholder="e.g. fireball"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="name">Name</Label>
                <Input
                  id="name"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder="e.g. Fireball"
                  required
                />
              </div>
            </div>

            {/* Description */}
            <div className="space-y-2">
              <Label htmlFor="description">Description</Label>
              <Textarea
                id="description"
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
                placeholder="Skill description..."
                rows={2}
              />
            </div>

            {/* Row 2: Class + Damage Type + Target Type */}
            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>Class Restriction</Label>
                <Select
                  value={form.classRestriction || '_none'}
                  onValueChange={(v) => setForm({ ...form, classRestriction: v === '_none' ? '' : v })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="_none">Universal (none)</SelectItem>
                    {CLASS_OPTIONS.map((c) => (
                      <SelectItem key={c} value={c}>
                        {formatLabel(c)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Damage Type</Label>
                <Select
                  value={form.damageType}
                  onValueChange={(v) => setForm({ ...form, damageType: v })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {DAMAGE_TYPES.map((t) => (
                      <SelectItem key={t} value={t}>
                        {formatLabel(t)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Target Type</Label>
                <Select
                  value={form.targetType}
                  onValueChange={(v) => setForm({ ...form, targetType: v })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {TARGET_TYPES.map((t) => (
                      <SelectItem key={t} value={t}>
                        {formatLabel(t)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* Row 3: Damage Base + Cooldown + Mana Cost */}
            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="damageBase">Damage Base</Label>
                <Input
                  id="damageBase"
                  type="number"
                  min={0}
                  value={form.damageBase}
                  onChange={(e) => setForm({ ...form, damageBase: Number(e.target.value) })}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="cooldown">Cooldown</Label>
                <Input
                  id="cooldown"
                  type="number"
                  min={0}
                  value={form.cooldown}
                  onChange={(e) => setForm({ ...form, cooldown: Number(e.target.value) })}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="manaCost">Mana Cost</Label>
                <Input
                  id="manaCost"
                  type="number"
                  min={0}
                  value={form.manaCost}
                  onChange={(e) => setForm({ ...form, manaCost: Number(e.target.value) })}
                />
              </div>
            </div>

            {/* Row 4: Unlock Level + Max Rank + Rank Scaling */}
            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="unlockLevel">Unlock Level</Label>
                <Input
                  id="unlockLevel"
                  type="number"
                  min={1}
                  value={form.unlockLevel}
                  onChange={(e) => setForm({ ...form, unlockLevel: Number(e.target.value) })}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="maxRank">Max Rank</Label>
                <Input
                  id="maxRank"
                  type="number"
                  min={1}
                  value={form.maxRank}
                  onChange={(e) => setForm({ ...form, maxRank: Number(e.target.value) })}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="rankScaling">Rank Scaling</Label>
                <Input
                  id="rankScaling"
                  type="number"
                  step="0.01"
                  min={0}
                  value={form.rankScaling}
                  onChange={(e) => setForm({ ...form, rankScaling: Number(e.target.value) })}
                />
              </div>
            </div>

            {/* Row 5: Icon + Sort Order */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="icon">Icon</Label>
                <Input
                  id="icon"
                  value={form.icon}
                  onChange={(e) => setForm({ ...form, icon: e.target.value })}
                  placeholder="e.g. icon_fireball"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="sortOrder">Sort Order</Label>
                <Input
                  id="sortOrder"
                  type="number"
                  min={0}
                  value={form.sortOrder}
                  onChange={(e) => setForm({ ...form, sortOrder: Number(e.target.value) })}
                />
              </div>
            </div>

            {/* Damage Scaling JSON */}
            <div className="space-y-2">
              <Label htmlFor="damageScaling">Damage Scaling (JSON)</Label>
              <Textarea
                id="damageScaling"
                value={form.damageScaling}
                onChange={(e) => setForm({ ...form, damageScaling: e.target.value })}
                placeholder='{"str": 1.5, "int": 0.5}'
                className="font-mono text-xs"
                rows={3}
              />
            </div>

            {/* Effect JSON */}
            <div className="space-y-2">
              <Label htmlFor="effectJson">Effect JSON</Label>
              <Textarea
                id="effectJson"
                value={form.effectJson}
                onChange={(e) => setForm({ ...form, effectJson: e.target.value })}
                placeholder='{"burn": {"duration": 3, "tickDamage": 10}}'
                className="font-mono text-xs"
                rows={3}
              />
            </div>

            {/* Active toggle */}
            <div className="flex items-center gap-3">
              <Switch
                id="isActive"
                checked={form.isActive}
                onCheckedChange={(checked) => setForm({ ...form, isActive: checked })}
              />
              <Label htmlFor="isActive">Active</Label>
            </div>

            {/* Footer buttons */}
            <div className="flex justify-end gap-3 pt-2">
              <Button type="button" variant="outline" onClick={() => setDialogOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={isPending}>
                {isPending ? 'Saving...' : editingSkill ? 'Update Skill' : 'Create Skill'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Skill</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete &quot;{deletingSkill?.name}&quot;? This action cannot be undone.
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
    </>
  )
}
