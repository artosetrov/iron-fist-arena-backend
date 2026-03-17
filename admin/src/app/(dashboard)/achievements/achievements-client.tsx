'use client'

import { useState, useMemo, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  Dialog, DialogContent, DialogDescription, DialogFooter,
  DialogHeader, DialogTitle, DialogTrigger,
} from '@/components/ui/dialog'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import {
  Search, Trophy, Target, TrendingUp, Plus, Pencil,
  Trash2, Download, Loader2, ToggleLeft, ToggleRight,
} from 'lucide-react'
import {
  createAchievementDefinition,
  updateAchievementDefinition,
  deleteAchievementDefinition,
  seedAchievementDefinitions,
} from '@/actions/achievement-definitions'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type AchievementStat = {
  achievementKey: string
  totalCount: number
  completedCount: number
  completionRate: number
}

type OverallStats = {
  totalAchievements: number
  completedAchievements: number
  overallCompletionRate: number
}

type AchievementDef = {
  id: string
  key: string
  title: string
  description: string
  category: string
  target: number
  rewardType: string
  rewardAmount: number
  rewardId: string | null
  icon: string | null
  active: boolean
  sortOrder: number
  createdAt: Date
  updatedAt: Date
}

type FormData = {
  key: string
  title: string
  description: string
  category: string
  target: string
  rewardType: string
  rewardAmount: string
  rewardId: string
  icon: string
  sortOrder: string
}

const EMPTY_FORM: FormData = {
  key: '', title: '', description: '', category: '',
  target: '1', rewardType: 'gold', rewardAmount: '100',
  rewardId: '', icon: '', sortOrder: '0',
}

const CATEGORIES = [
  'pvp', 'revenge', 'progression', 'prestige', 'equipment',
  'dungeon', 'economy', 'minigame', 'ranking', 'daily',
]

const REWARD_TYPES = ['gold', 'gems', 'xp', 'item']

const CATEGORY_COLORS: Record<string, string> = {
  pvp: 'bg-red-900/40 text-red-300 border-red-700/50',
  revenge: 'bg-orange-900/40 text-orange-300 border-orange-700/50',
  progression: 'bg-blue-900/40 text-blue-300 border-blue-700/50',
  prestige: 'bg-purple-900/40 text-purple-300 border-purple-700/50',
  equipment: 'bg-amber-900/40 text-amber-300 border-amber-700/50',
  dungeon: 'bg-emerald-900/40 text-emerald-300 border-emerald-700/50',
  economy: 'bg-yellow-900/40 text-yellow-300 border-yellow-700/50',
  minigame: 'bg-pink-900/40 text-pink-300 border-pink-700/50',
  ranking: 'bg-cyan-900/40 text-cyan-300 border-cyan-700/50',
  daily: 'bg-indigo-900/40 text-indigo-300 border-indigo-700/50',
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function AchievementsClient({
  stats,
  overall,
  definitions: initialDefs,
}: {
  stats: AchievementStat[]
  overall: OverallStats
  definitions: AchievementDef[]
}) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [search, setSearch] = useState('')
  const [categoryFilter, setCategoryFilter] = useState('all')
  const [tab, setTab] = useState<'definitions' | 'stats'>('definitions')

  // Dialog state
  const [dialogOpen, setDialogOpen] = useState(false)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [editingDef, setEditingDef] = useState<AchievementDef | null>(null)
  const [deletingDef, setDeletingDef] = useState<AchievementDef | null>(null)
  const [form, setForm] = useState<FormData>(EMPTY_FORM)
  const [saving, setSaving] = useState(false)
  const [seeding, setSeeding] = useState(false)
  const [seedResult, setSeedResult] = useState<string | null>(null)

  // ---- helpers ----

  const refresh = () => startTransition(() => router.refresh())

  const updateField = (field: keyof FormData, value: string) =>
    setForm((f) => ({ ...f, [field]: value }))

  const openCreate = () => {
    setEditingDef(null)
    setForm(EMPTY_FORM)
    setDialogOpen(true)
  }

  const openEdit = (def: AchievementDef) => {
    setEditingDef(def)
    setForm({
      key: def.key,
      title: def.title,
      description: def.description,
      category: def.category,
      target: String(def.target),
      rewardType: def.rewardType,
      rewardAmount: String(def.rewardAmount),
      rewardId: def.rewardId ?? '',
      icon: def.icon ?? '',
      sortOrder: String(def.sortOrder),
    })
    setDialogOpen(true)
  }

  const openDelete = (def: AchievementDef) => {
    setDeletingDef(def)
    setDeleteDialogOpen(true)
  }

  const handleSave = async () => {
    setSaving(true)
    try {
      if (editingDef) {
        await updateAchievementDefinition(editingDef.id, {
          title: form.title,
          description: form.description,
          category: form.category,
          target: parseInt(form.target, 10),
          rewardType: form.rewardType,
          rewardAmount: parseInt(form.rewardAmount, 10),
          rewardId: form.rewardId || null,
          icon: form.icon || null,
          sortOrder: parseInt(form.sortOrder, 10),
        })
      } else {
        await createAchievementDefinition({
          key: form.key.toLowerCase().replace(/\s+/g, '_'),
          title: form.title,
          description: form.description,
          category: form.category,
          target: parseInt(form.target, 10),
          rewardType: form.rewardType,
          rewardAmount: parseInt(form.rewardAmount, 10),
          rewardId: form.rewardId || undefined,
          icon: form.icon || undefined,
          sortOrder: parseInt(form.sortOrder, 10),
        })
      }
      setDialogOpen(false)
      refresh()
    } catch (e) {
      console.error(e)
      alert(e instanceof Error ? e.message : 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!deletingDef) return
    setSaving(true)
    try {
      await deleteAchievementDefinition(deletingDef.id)
      setDeleteDialogOpen(false)
      setDeletingDef(null)
      refresh()
    } catch (e) {
      console.error(e)
      alert(e instanceof Error ? e.message : 'Delete failed')
    } finally {
      setSaving(false)
    }
  }

  const handleToggleActive = async (def: AchievementDef) => {
    try {
      await updateAchievementDefinition(def.id, { active: !def.active })
      refresh()
    } catch (e) {
      console.error(e)
    }
  }

  const handleSeed = async () => {
    setSeeding(true)
    setSeedResult(null)
    try {
      const result = await seedAchievementDefinitions()
      setSeedResult(`Created ${result.created}, skipped ${result.skipped} (total ${result.total})`)
      refresh()
    } catch (e) {
      console.error(e)
      setSeedResult(e instanceof Error ? e.message : 'Seed failed')
    } finally {
      setSeeding(false)
    }
  }

  // ---- filtered lists ----

  const filteredDefs = useMemo(() => {
    let list = initialDefs
    if (categoryFilter !== 'all') {
      list = list.filter((d) => d.category === categoryFilter)
    }
    if (search) {
      const q = search.toLowerCase()
      list = list.filter(
        (d) =>
          d.key.toLowerCase().includes(q) ||
          d.title.toLowerCase().includes(q) ||
          d.description.toLowerCase().includes(q)
      )
    }
    return list
  }, [initialDefs, categoryFilter, search])

  const filteredStats = useMemo(() => {
    if (!search) return stats
    return stats.filter((s) =>
      s.achievementKey.toLowerCase().includes(search.toLowerCase())
    )
  }, [stats, search])

  const uniqueKeys = stats.length

  // ---- render ----

  return (
    <>
      {/* Summary Cards */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Definitions
            </CardTitle>
            <Trophy className="h-4 w-4 text-amber-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{initialDefs.length}</div>
            <p className="text-xs text-muted-foreground">
              {initialDefs.filter((d) => d.active).length} active / {initialDefs.filter((d) => !d.active).length} inactive
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Earned
            </CardTitle>
            <Target className="h-4 w-4 text-green-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{overall.completedAchievements.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">of {overall.totalAchievements.toLocaleString()} tracked</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Completion Rate
            </CardTitle>
            <TrendingUp className="h-4 w-4 text-purple-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{overall.overallCompletionRate}%</div>
            <p className="text-xs text-muted-foreground">across all players</p>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-4 border-b border-border pb-2">
        <button
          onClick={() => setTab('definitions')}
          className={`pb-2 text-sm font-medium transition-colors ${
            tab === 'definitions'
              ? 'border-b-2 border-primary text-foreground'
              : 'text-muted-foreground hover:text-foreground'
          }`}
        >
          Definitions ({initialDefs.length})
        </button>
        <button
          onClick={() => setTab('stats')}
          className={`pb-2 text-sm font-medium transition-colors ${
            tab === 'stats'
              ? 'border-b-2 border-primary text-foreground'
              : 'text-muted-foreground hover:text-foreground'
          }`}
        >
          Player Stats ({uniqueKeys})
        </button>
      </div>

      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[200px] max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search achievements..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>

        {tab === 'definitions' && (
          <Select value={categoryFilter} onValueChange={setCategoryFilter}>
            <SelectTrigger className="w-[160px]">
              <SelectValue placeholder="Category" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Categories</SelectItem>
              {CATEGORIES.map((c) => (
                <SelectItem key={c} value={c}>
                  {c.charAt(0).toUpperCase() + c.slice(1)}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        )}

        {tab === 'definitions' && (
          <div className="flex items-center gap-2 ml-auto">
            <Button variant="outline" size="sm" onClick={handleSeed} disabled={seeding}>
              {seeding ? <Loader2 className="h-4 w-4 mr-1 animate-spin" /> : <Download className="h-4 w-4 mr-1" />}
              Seed Defaults
            </Button>
            <Button size="sm" onClick={openCreate}>
              <Plus className="h-4 w-4 mr-1" /> Add Achievement
            </Button>
          </div>
        )}
      </div>

      {seedResult && (
        <p className="text-sm text-muted-foreground">{seedResult}</p>
      )}

      {/* DEFINITIONS TAB */}
      {tab === 'definitions' && (
        <>
          <div className="rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Key</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Title</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Category</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Target</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Reward</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
                  <th className="px-4 py-3 text-right font-medium text-muted-foreground">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredDefs.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-4 py-8 text-center text-muted-foreground">
                      {initialDefs.length === 0
                        ? 'No achievement definitions yet. Click "Seed Defaults" to populate from the catalog.'
                        : 'No matching achievements found.'}
                    </td>
                  </tr>
                ) : (
                  filteredDefs.map((def) => (
                    <tr key={def.id} className="border-b border-border hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3 font-mono text-xs">{def.key}</td>
                      <td className="px-4 py-3 font-medium">{def.title}</td>
                      <td className="px-4 py-3">
                        <Badge variant="outline" className={CATEGORY_COLORS[def.category] ?? ''}>
                          {def.category}
                        </Badge>
                      </td>
                      <td className="px-4 py-3 font-mono">{def.target.toLocaleString()}</td>
                      <td className="px-4 py-3">
                        <span className="font-medium">{def.rewardAmount}</span>{' '}
                        <span className="text-muted-foreground">{def.rewardType}</span>
                      </td>
                      <td className="px-4 py-3">
                        <button
                          onClick={() => handleToggleActive(def)}
                          className="flex items-center gap-1 text-xs"
                          title={def.active ? 'Click to deactivate' : 'Click to activate'}
                        >
                          {def.active ? (
                            <><ToggleRight className="h-4 w-4 text-green-400" /> <span className="text-green-400">Active</span></>
                          ) : (
                            <><ToggleLeft className="h-4 w-4 text-muted-foreground" /> <span className="text-muted-foreground">Inactive</span></>
                          )}
                        </button>
                      </td>
                      <td className="px-4 py-3 text-right">
                        <div className="flex items-center justify-end gap-1">
                          <Button variant="ghost" size="sm" onClick={() => openEdit(def)}>
                            <Pencil className="h-3.5 w-3.5" />
                          </Button>
                          <Button variant="ghost" size="sm" onClick={() => openDelete(def)} className="text-red-400 hover:text-red-300">
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
          <p className="text-sm text-muted-foreground">
            Showing {filteredDefs.length} of {initialDefs.length} definitions
          </p>
        </>
      )}

      {/* STATS TAB */}
      {tab === 'stats' && (
        <>
          <div className="rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Achievement Key</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Total Tracked</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Completed</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Completion %</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Progress</th>
                </tr>
              </thead>
              <tbody>
                {filteredStats.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-4 py-8 text-center text-muted-foreground">
                      No achievement stats found.
                    </td>
                  </tr>
                ) : (
                  filteredStats.map((stat) => (
                    <tr key={stat.achievementKey} className="border-b border-border hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3 font-mono text-sm">{stat.achievementKey}</td>
                      <td className="px-4 py-3">{stat.totalCount.toLocaleString()}</td>
                      <td className="px-4 py-3">{stat.completedCount.toLocaleString()}</td>
                      <td className="px-4 py-3 font-medium">
                        <span className={
                          stat.completionRate >= 75 ? 'text-green-400' :
                          stat.completionRate >= 50 ? 'text-amber-400' :
                          stat.completionRate >= 25 ? 'text-orange-400' :
                          'text-red-400'
                        }>
                          {stat.completionRate}%
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <div className="h-2 flex-1 max-w-[120px] rounded-full bg-muted overflow-hidden">
                            <div
                              className="h-full rounded-full bg-primary transition-all"
                              style={{ width: `${stat.completionRate}%` }}
                            />
                          </div>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
          <p className="text-sm text-muted-foreground">
            Showing {filteredStats.length} of {stats.length} achievement types
          </p>
        </>
      )}

      {/* CREATE / EDIT DIALOG */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editingDef ? 'Edit Achievement' : 'New Achievement'}</DialogTitle>
            <DialogDescription>
              {editingDef
                ? `Editing ${editingDef.key}`
                : 'Define a new achievement for players to earn.'}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-2">
            {!editingDef && (
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Key</label>
                <Input
                  placeholder="e.g. pvp_wins_200"
                  value={form.key}
                  onChange={(e) => updateField('key', e.target.value)}
                />
                <p className="text-xs text-muted-foreground">Unique snake_case identifier. Cannot be changed after creation.</p>
              </div>
            )}

            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Title</label>
                <Input
                  placeholder="Win 200 PvP Battles"
                  value={form.title}
                  onChange={(e) => updateField('title', e.target.value)}
                />
              </div>
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Category</label>
                <Select value={form.category} onValueChange={(v) => updateField('category', v)}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select..." />
                  </SelectTrigger>
                  <SelectContent>
                    {CATEGORIES.map((c) => (
                      <SelectItem key={c} value={c}>
                        {c.charAt(0).toUpperCase() + c.slice(1)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid gap-1.5">
              <label className="text-sm font-medium">Description</label>
              <Input
                placeholder="Win 200 PvP battles"
                value={form.description}
                onChange={(e) => updateField('description', e.target.value)}
              />
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Target</label>
                <Input
                  type="number"
                  value={form.target}
                  onChange={(e) => updateField('target', e.target.value)}
                />
              </div>
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Reward Type</label>
                <Select value={form.rewardType} onValueChange={(v) => updateField('rewardType', v)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {REWARD_TYPES.map((t) => (
                      <SelectItem key={t} value={t}>
                        {t.charAt(0).toUpperCase() + t.slice(1)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Amount</label>
                <Input
                  type="number"
                  value={form.rewardAmount}
                  onChange={(e) => updateField('rewardAmount', e.target.value)}
                />
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Reward ID</label>
                <Input
                  placeholder="item_id (optional)"
                  value={form.rewardId}
                  onChange={(e) => updateField('rewardId', e.target.value)}
                />
              </div>
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Icon</label>
                <Input
                  placeholder="icon name"
                  value={form.icon}
                  onChange={(e) => updateField('icon', e.target.value)}
                />
              </div>
              <div className="grid gap-1.5">
                <label className="text-sm font-medium">Sort Order</label>
                <Input
                  type="number"
                  value={form.sortOrder}
                  onChange={(e) => updateField('sortOrder', e.target.value)}
                />
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)} disabled={saving}>
              Cancel
            </Button>
            <Button
              onClick={handleSave}
              disabled={saving || !form.title || !form.category || !form.target}
            >
              {saving && <Loader2 className="h-4 w-4 mr-1 animate-spin" />}
              {editingDef ? 'Save Changes' : 'Create'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* DELETE DIALOG */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Delete Achievement</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete <strong>{deletingDef?.key}</strong>? This cannot be undone.
              Existing player progress for this achievement will remain but no new progress will be tracked.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)} disabled={saving}>
              Cancel
            </Button>
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
