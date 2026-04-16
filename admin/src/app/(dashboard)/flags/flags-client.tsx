'use client'

import { useMemo, useState } from 'react'
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
import {
  EMPTY_FEATURE_FLAG_FORM,
  coerceFeatureFlagType,
  displayFeatureFlagValue,
  formatFeatureFlagValueForForm,
  normalizeFeatureFlagTags,
  readFeatureFlagTargeting,
  sanitizeFeatureFlagTargeting,
  sanitizeFeatureFlagValue,
  type FeatureFlagFormData,
  type FeatureFlagRecord,
  type FeatureFlagStats,
  type FeatureFlagType,
} from '@/lib/feature-flags'

const FLAG_TYPES: Array<{ value: FeatureFlagType; label: string; desc: string; icon: typeof Power }> = [
  { value: 'boolean', label: 'Boolean', icon: Power, desc: 'On/off toggle' },
  { value: 'percentage', label: 'Percentage', icon: Percent, desc: 'Gradual rollout (0-100%)' },
  { value: 'segment', label: 'Segment', icon: Shield, desc: 'Targeted boolean rollout' },
  { value: 'json', label: 'JSON', icon: FileJson, desc: 'Custom JSON config' },
]

const TYPE_COLORS: Record<FeatureFlagType, string> = {
  boolean: 'bg-blue-900/40 text-blue-300 border-blue-700/50',
  percentage: 'bg-amber-900/40 text-amber-300 border-amber-700/50',
  segment: 'bg-emerald-900/40 text-emerald-300 border-emerald-700/50',
  json: 'bg-purple-900/40 text-purple-300 border-purple-700/50',
}

export function FlagsClient({
  initialFlags,
  stats,
}: {
  initialFlags: FeatureFlagRecord[]
  stats: FeatureFlagStats
}) {
  const router = useRouter()
  const [search, setSearch] = useState('')
  const [typeFilter, setTypeFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [dialogOpen, setDialogOpen] = useState(false)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [editingFlag, setEditingFlag] = useState<FeatureFlagRecord | null>(null)
  const [deletingFlag, setDeletingFlag] = useState<FeatureFlagRecord | null>(null)
  const [form, setForm] = useState<FeatureFlagFormData>(EMPTY_FEATURE_FLAG_FORM)
  const [saving, setSaving] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [seeding, setSeeding] = useState(false)
  const [togglingFlagId, setTogglingFlagId] = useState<string | null>(null)
  const [seedResult, setSeedResult] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  const refresh = () => router.refresh()
  const updateField = (field: keyof FeatureFlagFormData, value: string) => {
    setForm((current) => ({ ...current, [field]: value }))
  }

  const openCreate = () => {
    setEditingFlag(null)
    setForm(EMPTY_FEATURE_FLAG_FORM)
    setError(null)
    setMessage(null)
    setDialogOpen(true)
  }

  const openEdit = (flag: FeatureFlagRecord) => {
    const flagType = coerceFeatureFlagType(flag.flagType)
    const targeting = readFeatureFlagTargeting(flag.targeting)

    setEditingFlag(flag)
    setForm({
      key: flag.key,
      title: flag.title,
      description: flag.description ?? '',
      flagType,
      value: formatFeatureFlagValueForForm(flagType, flag.value),
      environment: flag.environment === 'production' || flag.environment === 'staging' || flag.environment === 'development'
        ? flag.environment
        : 'all',
      tags: flag.tags.join(', '),
      minLevel: targeting?.minLevel?.toString() ?? '',
      maxLevel: targeting?.maxLevel?.toString() ?? '',
      class: targeting?.class ?? '',
      userIds: targeting?.userIds?.join(', ') ?? '',
    })
    setError(null)
    setMessage(null)
    setDialogOpen(true)
  }

  const handleSave = async () => {
    setSaving(true)
    setError(null)
    try {
      const parsedValue = sanitizeFeatureFlagValue(form.flagType, form.value)
      const targeting = sanitizeFeatureFlagTargeting({
        minLevel: form.minLevel,
        maxLevel: form.maxLevel,
        class: form.class,
        userIds: form.userIds,
      })
      const tags = normalizeFeatureFlagTags(form.tags)

      if (editingFlag) {
        await updateFeatureFlag(editingFlag.id, {
          title: form.title,
          description: form.description || undefined,
          flagType: form.flagType,
          value: parsedValue,
          targeting,
          environment: form.environment,
          tags,
        })
      } else {
        await createFeatureFlag({
          key: form.key,
          title: form.title,
          description: form.description || undefined,
          flagType: form.flagType,
          value: parsedValue,
          targeting,
          environment: form.environment,
          tags,
        })
      }

      setDialogOpen(false)
      setMessage(editingFlag ? 'Feature flag updated.' : 'Feature flag created.')
      refresh()
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  const handleToggle = async (flag: FeatureFlagRecord) => {
    setError(null)
    setTogglingFlagId(flag.id)
    try {
      await toggleFeatureFlag(flag.id)
      setMessage(`Flag ${flag.key} ${flag.isActive ? 'disabled' : 'enabled'}.`)
      refresh()
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Toggle failed')
    } finally {
      setTogglingFlagId(null)
    }
  }

  const handleDelete = async () => {
    if (!deletingFlag) return

    setDeleting(true)
    setError(null)
    try {
      await deleteFeatureFlag(deletingFlag.id)
      setDeleteDialogOpen(false)
      setMessage(`Flag ${deletingFlag.key} deleted.`)
      refresh()
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Delete failed')
    } finally {
      setDeleting(false)
    }
  }

  const handleSeed = async () => {
    setSeeding(true)
    setSeedResult(null)
    setError(null)
    try {
      const result = await seedDefaultFlags()
      setSeedResult(`Created ${result.created}, skipped ${result.skipped}`)
      setMessage('Default feature flags seeded.')
      refresh()
    } catch (error) {
      const msg = error instanceof Error ? error.message : 'Seed failed'
      setSeedResult(msg)
      setError(msg)
    } finally {
      setSeeding(false)
    }
  }

  const filtered = useMemo(() => {
    let list = initialFlags

    if (typeFilter !== 'all') {
      list = list.filter((flag) => flag.flagType === typeFilter)
    }
    if (statusFilter === 'active') {
      list = list.filter((flag) => flag.isActive)
    }
    if (statusFilter === 'inactive') {
      list = list.filter((flag) => !flag.isActive)
    }
    if (search) {
      const query = search.toLowerCase()
      list = list.filter((flag) =>
        flag.key.includes(query) ||
        flag.title.toLowerCase().includes(query) ||
        (flag.description ?? '').toLowerCase().includes(query)
      )
    }

    return list
  }, [initialFlags, search, statusFilter, typeFilter])

  return (
    <>
      {error && (
        <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
          {error}
        </div>
      )}
      {message && (
        <div className="rounded-md bg-green-600/10 border border-green-600/30 px-4 py-3 text-sm text-green-400">
          {message}
        </div>
      )}

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

      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[200px] max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search flags..."
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            className="pl-9"
          />
        </div>
        <Select value={typeFilter} onValueChange={setTypeFilter}>
          <SelectTrigger className="w-[140px]"><SelectValue placeholder="Type" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Types</SelectItem>
            {FLAG_TYPES.map((option) => (
              <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
            ))}
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
        <div className="ml-auto flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={handleSeed} disabled={seeding}>
            {seeding ? <Loader2 className="mr-1 h-4 w-4 animate-spin" /> : <Download className="mr-1 h-4 w-4" />}
            Seed Defaults
          </Button>
          <Button size="sm" onClick={openCreate}>
            <Plus className="mr-1 h-4 w-4" /> New Flag
          </Button>
        </div>
      </div>

      {seedResult && <p className="text-sm text-muted-foreground">{seedResult}</p>}

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
              filtered.map((flag) => {
                const flagType = coerceFeatureFlagType(flag.flagType)
                const isBooleanLike = flagType === 'boolean' || flagType === 'segment'
                const isEnabled = displayFeatureFlagValue(flag) === 'ON'

                return (
                  <tr key={flag.id} className="border-b border-border transition-colors hover:bg-muted/30">
                    <td className="px-4 py-3">
                      <div>
                        <span className="font-mono text-xs text-muted-foreground">{flag.key}</span>
                        <div className="font-medium">{flag.title}</div>
                        {flag.description && (
                          <div className="mt-0.5 max-w-[300px] truncate text-xs text-muted-foreground">
                            {flag.description}
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <Badge variant="outline" className={TYPE_COLORS[flagType]}>
                        {flag.flagType}
                      </Badge>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`font-mono text-sm ${isBooleanLike ? (isEnabled ? 'text-green-400' : 'text-red-400') : 'text-foreground'}`}>
                        {displayFeatureFlagValue(flag)}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-xs text-muted-foreground">{flag.environment}</span>
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => handleToggle(flag)}
                        className="flex items-center gap-1 text-xs"
                        title="Toggle"
                        disabled={togglingFlagId === flag.id}
                      >
                        {flag.isActive ? (
                          <>
                            <ToggleRight className="h-4 w-4 text-green-400" />
                            <span className="text-green-400">{togglingFlagId === flag.id ? 'Updating...' : 'Active'}</span>
                          </>
                        ) : (
                          <>
                            <ToggleLeft className="h-4 w-4 text-muted-foreground" />
                            <span className="text-muted-foreground">{togglingFlagId === flag.id ? 'Updating...' : 'Off'}</span>
                          </>
                        )}
                      </button>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <Button variant="ghost" size="sm" onClick={() => openEdit(flag)} disabled={togglingFlagId === flag.id}>
                          <Pencil className="h-3.5 w-3.5" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          disabled={togglingFlagId === flag.id}
                          onClick={() => {
                            setDeletingFlag(flag)
                            setDeleteDialogOpen(true)
                          }}
                          className="text-red-400 hover:text-red-300"
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                )
              })
            )}
          </tbody>
        </table>
      </div>
      <p className="text-sm text-muted-foreground">Showing {filtered.length} of {initialFlags.length} flags</p>

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-h-[85vh] max-w-lg overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingFlag ? 'Edit Flag' : 'New Feature Flag'}</DialogTitle>
            <DialogDescription>
              {editingFlag ? `Editing ${editingFlag.key}` : 'Create a new feature flag for controlled rollout.'}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-2">
            {!editingFlag && (
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Key</label>
                <Input
                  placeholder="e.g. new_combat_ui"
                  value={form.key}
                  onChange={(event) => updateField('key', event.target.value)}
                />
                <p className="text-xs text-muted-foreground">Unique snake_case identifier. Cannot change after creation.</p>
              </div>
            )}

            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Title</label>
                <Input
                  placeholder="New Combat UI"
                  value={form.title}
                  onChange={(event) => updateField('title', event.target.value)}
                />
              </div>
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Type</label>
                <Select
                  value={form.flagType}
                  onValueChange={(value: FeatureFlagType) => {
                    updateField('flagType', value)
                    if (value === 'percentage') updateField('value', '50')
                    else if (value === 'json') updateField('value', '{}')
                    else updateField('value', 'true')
                  }}
                >
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {FLAG_TYPES.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label} - {option.desc}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid gap-1.5">
              <label className="text-sm font-medium">Description</label>
              <Input
                placeholder="What this flag controls"
                value={form.description}
                onChange={(event) => updateField('description', event.target.value)}
              />
            </div>

            <div className="grid gap-1.5">
              <label className="text-sm font-medium">Value</label>
              {form.flagType === 'boolean' || form.flagType === 'segment' ? (
                <Select value={form.value} onValueChange={(value) => updateField('value', value)}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">True (ON)</SelectItem>
                    <SelectItem value="false">False (OFF)</SelectItem>
                  </SelectContent>
                </Select>
              ) : form.flagType === 'percentage' ? (
                <div className="flex items-center gap-2">
                  <Input
                    type="number"
                    min={0}
                    max={100}
                    value={form.value}
                    onChange={(event) => updateField('value', event.target.value)}
                  />
                  <span className="text-sm text-muted-foreground">%</span>
                </div>
              ) : (
                <textarea
                  className="min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 font-mono text-sm ring-offset-background"
                  placeholder='{"key": "value"}'
                  value={form.value}
                  onChange={(event) => updateField('value', event.target.value)}
                />
              )}
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Environment</label>
                <Select value={form.environment} onValueChange={(value) => updateField('environment', value)}>
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
                <Input
                  placeholder="combat, ui, event"
                  value={form.tags}
                  onChange={(event) => updateField('tags', event.target.value)}
                />
              </div>
            </div>

            <div className="border-t border-border pt-4">
              <p className="mb-3 flex items-center gap-1 text-sm font-medium">
                <Shield className="h-3.5 w-3.5" /> Targeting (optional)
              </p>
              <div className="grid grid-cols-2 gap-4">
                <div className="grid gap-1.5">
                  <label className="text-xs text-muted-foreground">Min Level</label>
                  <Input
                    type="number"
                    placeholder="1"
                    value={form.minLevel}
                    onChange={(event) => updateField('minLevel', event.target.value)}
                  />
                </div>
                <div className="grid gap-1.5">
                  <label className="text-xs text-muted-foreground">Max Level</label>
                  <Input
                    type="number"
                    placeholder="100"
                    value={form.maxLevel}
                    onChange={(event) => updateField('maxLevel', event.target.value)}
                  />
                </div>
              </div>
              <div className="mt-3 grid grid-cols-2 gap-4">
                <div className="grid gap-1.5">
                  <label className="text-xs text-muted-foreground">Class</label>
                  <Select value={form.class || 'any'} onValueChange={(value) => updateField('class', value === 'any' ? '' : value)}>
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
                  <label className="text-xs text-muted-foreground">User IDs (comma-separated)</label>
                  <Input
                    placeholder="uuid1, uuid2"
                    value={form.userIds}
                    onChange={(event) => updateField('userIds', event.target.value)}
                  />
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)} disabled={saving}>Cancel</Button>
            <Button onClick={handleSave} disabled={saving || !form.title || (!editingFlag && !form.key)}>
              {saving && <Loader2 className="mr-1 h-4 w-4 animate-spin" />}
              {editingFlag ? 'Save' : 'Create'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Delete Flag</DialogTitle>
            <DialogDescription>
              Delete <strong>{deletingFlag?.key}</strong>? This will immediately remove the flag from all environments.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)} disabled={deleting}>Cancel</Button>
            <Button variant="destructive" onClick={handleDelete} disabled={deleting}>
              {deleting && <Loader2 className="mr-1 h-4 w-4 animate-spin" />}
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}
