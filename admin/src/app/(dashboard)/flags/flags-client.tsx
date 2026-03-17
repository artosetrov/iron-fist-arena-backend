'use client'

import { useState, useMemo, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  Dialog, DialogContent, DialogDescription, DialogFooter,
  DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import {
  Search, Flag, ToggleLeft, ToggleRight, Plus, Pencil,
  Trash2, Loader2, Download, Power, Zap, Percent,
  FileJson, Shield,
} from 'lucide-react'
import {
  createFeatureFlag,
  updateFeatureFlag,
  toggleFeatureFlag,
  deleteFeatureFlag,
  seedDefaultFlags,
} from '@/actions/feature-flags'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type FeatureFlag = {
  id: string
  key: string
  title: string
  description: string | null
  flagType: string
  value: any
  targeting: any
  isActive: boolean
  environment: string
  tags: string[]
  createdAt: Date
  updatedAt: Date
}

type Stats = {
  total: number
  active: number
  inactive: number
  booleanCount: number
  percentageCount: number
}

type FormData = {
  key: string
  title: string
  description: string
  flagType: string
  value: string
  environment: string
  tags: string
  // Targeting
  minLevel: string
  maxLevel: string
  class: string
  userIds: string
}

const EMPTY_FORM: FormData = {
  key: '', title: '', description: '', flagType: 'boolean', value: 'true',
  environment: 'all', tags: '', minLevel: '', maxLevel: '', class: '', userIds: '',
}

const FLAG_TYPES = [
  { value: 'boolean', label: 'Boolean', icon: Power, desc: 'On/Off toggle' },
  { value: 'percentage', label: 'Percentage', icon: Percent, desc: 'Gradual rollout (0-100%)' },
  { value: 'json', label: 'JSON', icon: FileJson, desc: 'Custom JSON config' },
]

const TYPE_COLORS: Record<string, string> = {
  boolean: 'bg-blue-900/40 text-blue-300 border-blue-700/50',
  percentage: 'bg-amber-900/40 text-amber-300 border-amber-700/50',
  json: 'bg-purple-900/40 text-purple-300 border-purple-700/50',
  segment: 'bg-emerald-900/40 text-emerald-300 border-emerald-700/50',
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function FlagsClient({
  initialFlags,
  stats,
}: {
  initialFlags: FeatureFlag[]
  stats: Stats
}) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [search, setSearch] = useState('')
  const [typeFilter, setTypeFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')

  // Dialog state
  const [dialogOpen, setDialogOpen] = useState(false)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [editingFlag, setEditingFlag] = useState<FeatureFlag | null>(null)
  const [deletingFlag, setDeletingFlag] = useState<FeatureFlag | null>(null)
  const [form, setForm] = useState<FormData>(EMPTY_FORM)
  const [saving, setSaving] = useState(false)
  const [seeding, setSeeding] = useState(false)
  const [seedResult, setSeedResult] = useState<string | null>(null)

  const refresh = () => startTransition(() => router.refresh())
  const updateField = (field: keyof FormData, value: string) =>
    setForm((f) => ({ ...f, [field]: value }))

  const openCreate = () => {
    setEditingFlag(null)
    setForm(EMPTY_FORM)
    setDialogOpen(true)
  }

  const openEdit = (flag: FeatureFlag) => {
    setEditingFlag(flag)
    const targeting = flag.targeting as any
    setForm({
      key: flag.key,
      title: flag.title,
      description: flag.description ?? '',
      flagType: flag.flagType,
      value: typeof flag.value === 'object' ? JSON.stringify(flag.value, null, 2) : String(flag.value),
      environment: flag.environment,
      tags: flag.tags.join(', '),
      minLevel: targeting?.minLevel?.toString() ?? '',
      maxLevel: targeting?.maxLevel?.toString() ?? '',
      class: targeting?.class ?? '',
      userIds: targeting?.userIds?.join(', ') ?? '',
    })
    setDialogOpen(true)
  }

  const handleSave = async () => {
    setSaving(true)
    try {
      let parsedValue: any = form.value
      if (form.flagType === 'boolean') {
        parsedValue = form.value === 'true'
      } else if (form.flagType === 'percentage') {
        parsedValue = parseInt(form.value, 10) || 0
      } else if (form.flagType === 'json') {
        parsedValue = JSON.parse(form.value)
      }

      const targeting: any = {}
      if (form.minLevel) targeting.minLevel = parseInt(form.minLevel, 10)
      if (form.maxLevel) targeting.maxLevel = parseInt(form.maxLevel, 10)
      if (form.class) targeting.class = form.class
      if (form.userIds) targeting.userIds = form.userIds.split(',').map(s => s.trim()).filter(Boolean)

      const hasTargeting = Object.keys(targeting).length > 0

      if (editingFlag) {
        await updateFeatureFlag(editingFlag.id, {
          title: form.title,
          description: form.description || undefined,
          flagType: form.flagType,
          value: parsedValue,
          targeting: hasTargeting ? targeting : null,
          environment: form.environment,
          tags: form.tags ? form.tags.split(',').map(s => s.trim()).filter(Boolean) : [],
        })
      } else {
        await createFeatureFlag({
          key: form.key,
          title: form.title,
          description: form.description || undefined,
          flagType: form.flagType,
          value: parsedValue,
          targeting: hasTargeting ? targeting : undefined,
          environment: form.environment,
          tags: form.tags ? form.tags.split(',').map(s => s.trim()).filter(Boolean) : [],
        })
      }
      setDialogOpen(false)
      refresh()
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  const handleToggle = async (flag: FeatureFlag) => {
    try {
      await toggleFeatureFlag(flag.id)
      refresh()
    } catch (e) {
      console.error(e)
    }
  }

  const handleDelete = async () => {
    if (!deletingFlag) return
    setSaving(true)
    try {
      await deleteFeatureFlag(deletingFlag.id)
      setDeleteDialogOpen(false)
      refresh()
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Delete failed')
    } finally {
      setSaving(false)
    }
  }

  const handleSeed = async () => {
    setSeeding(true)
    setSeedResult(null)
    try {
      const r = await seedDefaultFlags()
      setSeedResult(`Created ${r.created}, skipped ${r.skipped}`)
      refresh()
    } catch (e) {
      setSeedResult(e instanceof Error ? e.message : 'Seed failed')
    } finally {
      setSeeding(false)
    }
  }

  // Filter
  const filtered = useMemo(() => {
    let list = initialFlags
    if (typeFilter !== 'all') list = list.filter(f => f.flagType === typeFilter)
    if (statusFilter === 'active') list = list.filter(f => f.isActive)
    if (statusFilter === 'inactive') list = list.filter(f => !f.isActive)
    if (search) {
      const q = search.toLowerCase()
      list = list.filter(f =>
        f.key.includes(q) || f.title.toLowerCase().includes(q) ||
        (f.description ?? '').toLowerCase().includes(q)
      )
    }
    return list
  }, [initialFlags, typeFilter, statusFilter, search])

  const displayValue = (flag: FeatureFlag) => {
    if (flag.flagType === 'boolean') return flag.value === true || flag.value === 'true' ? 'ON' : 'OFF'
    if (flag.flagType === 'percentage') return `${flag.value}%`
    if (flag.flagType === 'json') return 'JSON'
    return String(flag.value)
  }

  return (
    <>
      {/* Stats */}
      <div className="grid gap-4 sm:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Total Flags</CardTitle>
            <Flag className="h-4 w-4 text-blue-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.total}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Active</CardTitle>
            <Zap className="h-4 w-4 text-green-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-400">{stats.active}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Boolean</CardTitle>
            <Power className="h-4 w-4 text-blue-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.booleanCount}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">A/B Tests</CardTitle>
            <Percent className="h-4 w-4 text-amber-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.percentageCount}</div>
          </CardContent>
        </Card>
      </div>

      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[200px] max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input placeholder="Search flags..." value={search} onChange={(e) => setSearch(e.target.value)} className="pl-9" />
        </div>
        <Select value={typeFilter} onValueChange={setTypeFilter}>
          <SelectTrigger className="w-[140px]"><SelectValue placeholder="Type" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Types</SelectItem>
            <SelectItem value="boolean">Boolean</SelectItem>
            <SelectItem value="percentage">Percentage</SelectItem>
            <SelectItem value="json">JSON</SelectItem>
          </SelectContent>
        </Select>
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-[140px]"><SelectValue placeholder="Status" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Status</SelectItem>
            <SelectItem value="active">Active</SelectItem>
            <SelectItem value="inactive">Inactive</SelectItem>
          </SelectContent>
        </Select>
        <div className="flex items-center gap-2 ml-auto">
          <Button variant="outline" size="sm" onClick={handleSeed} disabled={seeding}>
            {seeding ? <Loader2 className="h-4 w-4 mr-1 animate-spin" /> : <Download className="h-4 w-4 mr-1" />}
            Seed Defaults
          </Button>
          <Button size="sm" onClick={openCreate}>
            <Plus className="h-4 w-4 mr-1" /> New Flag
          </Button>
        </div>
      </div>

      {seedResult && <p className="text-sm text-muted-foreground">{seedResult}</p>}

      {/* Table */}
      <div className="rounded-lg border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/50">
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Flag</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Type</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Value</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Env</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
              <th className="px-4 py-3 text-right font-medium text-muted-foreground">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-muted-foreground">
                  {initialFlags.length === 0
                    ? 'No flags yet. Click "Seed Defaults" to create common flags.'
                    : 'No matching flags.'}
                </td>
              </tr>
            ) : (
              filtered.map((flag) => (
                <tr key={flag.id} className="border-b border-border hover:bg-muted/30 transition-colors">
                  <td className="px-4 py-3">
                    <div>
                      <span className="font-mono text-xs text-muted-foreground">{flag.key}</span>
                      <div className="font-medium">{flag.title}</div>
                      {flag.description && (
                        <div className="text-xs text-muted-foreground mt-0.5 max-w-[300px] truncate">{flag.description}</div>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <Badge variant="outline" className={TYPE_COLORS[flag.flagType] ?? ''}>{flag.flagType}</Badge>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`font-mono text-sm ${
                      flag.flagType === 'boolean'
                        ? (flag.value === true || flag.value === 'true' ? 'text-green-400' : 'text-red-400')
                        : 'text-foreground'
                    }`}>
                      {displayValue(flag)}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span className="text-xs text-muted-foreground">{flag.environment}</span>
                  </td>
                  <td className="px-4 py-3">
                    <button onClick={() => handleToggle(flag)} className="flex items-center gap-1 text-xs" title="Toggle">
                      {flag.isActive ? (
                        <><ToggleRight className="h-4 w-4 text-green-400" /> <span className="text-green-400">Active</span></>
                      ) : (
                        <><ToggleLeft className="h-4 w-4 text-muted-foreground" /> <span className="text-muted-foreground">Off</span></>
                      )}
                    </button>
                  </td>
                  <td className="px-4 py-3 text-right">
                    <div className="flex items-center justify-end gap-1">
                      <Button variant="ghost" size="sm" onClick={() => openEdit(flag)}>
                        <Pencil className="h-3.5 w-3.5" />
                      </Button>
                      <Button variant="ghost" size="sm" onClick={() => { setDeletingFlag(flag); setDeleteDialogOpen(true) }} className="text-red-400 hover:text-red-300">
                        <Trash2 className="h-3.5 w-3.5" />
                      </Button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
      <p className="text-sm text-muted-foreground">Showing {filtered.length} of {initialFlags.length} flags</p>

      {/* Create / Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-lg max-h-[85vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingFlag ? 'Edit Flag' : 'New Feature Flag'}</DialogTitle>
            <DialogDescription>{editingFlag ? `Editing ${editingFlag.key}` : 'Create a new feature flag for controlled rollout.'}</DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-2">
            {!editingFlag && (
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Key</label>
                <Input placeholder="e.g. new_combat_ui" value={form.key} onChange={(e) => updateField('key', e.target.value)} />
                <p className="text-xs text-muted-foreground">Unique snake_case identifier. Cannot change after creation.</p>
              </div>
            )}

            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Title</label>
                <Input placeholder="New Combat UI" value={form.title} onChange={(e) => updateField('title', e.target.value)} />
              </div>
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Type</label>
                <Select value={form.flagType} onValueChange={(v) => {
                  updateField('flagType', v)
                  if (v === 'boolean') updateField('value', 'true')
                  else if (v === 'percentage') updateField('value', '50')
                  else if (v === 'json') updateField('value', '{}')
                }}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {FLAG_TYPES.map(t => (
                      <SelectItem key={t.value} value={t.value}>{t.label} — {t.desc}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid gap-1.5">
              <label className="text-sm font-medium">Description</label>
              <Input placeholder="What this flag controls" value={form.description} onChange={(e) => updateField('description', e.target.value)} />
            </div>

            {/* Value input based on type */}
            <div className="grid gap-1.5">
              <label className="text-sm font-medium">Value</label>
              {form.flagType === 'boolean' ? (
                <Select value={form.value} onValueChange={(v) => updateField('value', v)}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">True (ON)</SelectItem>
                    <SelectItem value="false">False (OFF)</SelectItem>
                  </SelectContent>
                </Select>
              ) : form.flagType === 'percentage' ? (
                <div className="flex items-center gap-2">
                  <Input type="number" min={0} max={100} value={form.value} onChange={(e) => updateField('value', e.target.value)} />
                  <span className="text-sm text-muted-foreground">%</span>
                </div>
              ) : (
                <textarea
                  className="flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background font-mono min-h-[80px]"
                  placeholder='{"key": "value"}'
                  value={form.value}
                  onChange={(e) => updateField('value', e.target.value)}
                />
              )}
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Environment</label>
                <Select value={form.environment} onValueChange={(v) => updateField('environment', v)}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All</SelectItem>
                    <SelectItem value="production">Production</SelectItem>
                    <SelectItem value="staging">Staging</SelectItem>
                    <SelectItem value="development">Development</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Tags</label>
                <Input placeholder="combat, ui, event" value={form.tags} onChange={(e) => updateField('tags', e.target.value)} />
              </div>
            </div>

            {/* Targeting */}
            <div className="border-t border-border pt-4">
              <p className="text-sm font-medium mb-3 flex items-center gap-1">
                <Shield className="h-3.5 w-3.5" /> Targeting (optional)
              </p>
              <div className="grid grid-cols-2 gap-4">
                <div className="grid gap-1.5">
                  <label className="text-xs text-muted-foreground">Min Level</label>
                  <Input type="number" placeholder="1" value={form.minLevel} onChange={(e) => updateField('minLevel', e.target.value)} />
                </div>
                <div className="grid gap-1.5">
                  <label className="text-xs text-muted-foreground">Max Level</label>
                  <Input type="number" placeholder="100" value={form.maxLevel} onChange={(e) => updateField('maxLevel', e.target.value)} />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4 mt-3">
                <div className="grid gap-1.5">
                  <label className="text-xs text-muted-foreground">Class</label>
                  <Select value={form.class || 'any'} onValueChange={(v) => updateField('class', v === 'any' ? '' : v)}>
                    <SelectTrigger><SelectValue placeholder="Any" /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="any">Any class</SelectItem>
                      <SelectItem value="warrior">Warrior</SelectItem>
                      <SelectItem value="rogue">Rogue</SelectItem>
                      <SelectItem value="mage">Mage</SelectItem>
                      <SelectItem value="tank">Tank</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="grid gap-1.5">
                  <label className="text-xs text-muted-foreground">User IDs (comma-sep)</label>
                  <Input placeholder="uuid1, uuid2" value={form.userIds} onChange={(e) => updateField('userIds', e.target.value)} />
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)} disabled={saving}>Cancel</Button>
            <Button onClick={handleSave} disabled={saving || !form.title || (!editingFlag && !form.key)}>
              {saving && <Loader2 className="h-4 w-4 mr-1 animate-spin" />}
              {editingFlag ? 'Save' : 'Create'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Delete Flag</DialogTitle>
            <DialogDescription>
              Delete <strong>{deletingFlag?.key}</strong>? This will immediately remove the flag from all environments.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)} disabled={saving}>Cancel</Button>
            <Button variant="destructive" onClick={handleDelete} disabled={saving}>
              {saving && <Loader2 className="h-4 w-4 mr-1 animate-spin" />}
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}
