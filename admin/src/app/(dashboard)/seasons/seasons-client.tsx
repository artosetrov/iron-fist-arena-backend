'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from '@/components/ui/dialog'
import { Plus, Pencil, Trash2, Trophy } from 'lucide-react'
import { formatDate } from '@/lib/utils'

type Season = {
  id: string
  number: number
  theme: string | null
  startAt: string
  endAt: string
  createdAt: string
}

const emptyForm = {
  number: 1,
  theme: '',
  startAt: '',
  endAt: '',
}

function getSeasonStatus(season: Season): { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' } {
  const now = new Date()
  const start = new Date(season.startAt)
  const end = new Date(season.endAt)
  if (now < start) return { label: 'Upcoming', variant: 'warning' }
  if (now > end) return { label: 'Ended', variant: 'secondary' }
  return { label: 'Active', variant: 'success' }
}

export function SeasonsClient({ seasons }: { seasons: Season[] }) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [dialogOpen, setDialogOpen] = useState(false)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [editingSeason, setEditingSeason] = useState<Season | null>(null)
  const [deletingSeason, setDeletingSeason] = useState<Season | null>(null)
  const [form, setForm] = useState(emptyForm)
  const [error, setError] = useState('')

  function toDatetimeLocal(dateStr: string) {
    if (!dateStr) return ''
    return new Date(dateStr).toISOString().slice(0, 16)
  }

  function openCreate() {
    setEditingSeason(null)
    setForm({
      ...emptyForm,
      number: seasons.length > 0 ? Math.max(...seasons.map((s) => s.number)) + 1 : 1,
    })
    setError('')
    setDialogOpen(true)
  }

  function openEdit(season: Season) {
    setEditingSeason(season)
    setForm({
      number: season.number,
      theme: season.theme || '',
      startAt: toDatetimeLocal(season.startAt),
      endAt: toDatetimeLocal(season.endAt),
    })
    setError('')
    setDialogOpen(true)
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')

    startTransition(async () => {
      try {
        const res = await fetch('/api/seasons', {
          method: editingSeason ? 'PUT' : 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(
            editingSeason
              ? { id: editingSeason.id, ...form, startAt: new Date(form.startAt).toISOString(), endAt: new Date(form.endAt).toISOString() }
              : { ...form, startAt: new Date(form.startAt).toISOString(), endAt: new Date(form.endAt).toISOString() }
          ),
        })
        if (!res.ok) {
          const data = await res.json()
          setError(data.error || 'Failed to save season')
          return
        }
        setDialogOpen(false)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save season')
      }
    })
  }

  async function handleDelete() {
    if (!deletingSeason) return
    startTransition(async () => {
      try {
        const res = await fetch(`/api/seasons?id=${deletingSeason.id}`, { method: 'DELETE' })
        if (!res.ok) {
          const data = await res.json()
          setError(data.error || 'Failed to delete season')
          return
        }
        setDeleteDialogOpen(false)
        setDeletingSeason(null)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to delete')
      }
    })
  }

  return (
    <>
      <div className="flex justify-end">
        <Button onClick={openCreate}>
          <Plus className="mr-2 h-4 w-4" />
          Create Season
        </Button>
      </div>

      {seasons.length === 0 ? (
        <div className="rounded-lg border border-border p-8 text-center text-muted-foreground">
          <Trophy className="mx-auto h-12 w-12 mb-4 opacity-50" />
          <p>No seasons created yet.</p>
        </div>
      ) : (
        <div className="rounded-lg border border-border">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/50">
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Season</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Theme</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Start</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">End</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
                <th className="px-4 py-3 text-right font-medium text-muted-foreground">Actions</th>
              </tr>
            </thead>
            <tbody>
              {seasons.map((season) => {
                const status = getSeasonStatus(season)
                return (
                  <tr key={season.id} className="border-b border-border hover:bg-muted/30 transition-colors">
                    <td className="px-4 py-3 font-medium">Season {season.number}</td>
                    <td className="px-4 py-3 text-muted-foreground">{season.theme || '---'}</td>
                    <td className="px-4 py-3 text-muted-foreground">{formatDate(season.startAt)}</td>
                    <td className="px-4 py-3 text-muted-foreground">{formatDate(season.endAt)}</td>
                    <td className="px-4 py-3">
                      <Badge variant={status.variant}>{status.label}</Badge>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <Button variant="ghost" size="icon" onClick={() => openEdit(season)}>
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => {
                            setDeletingSeason(season)
                            setDeleteDialogOpen(true)
                          }}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Create / Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingSeason ? 'Edit Season' : 'Create Season'}</DialogTitle>
            <DialogDescription>
              {editingSeason ? 'Update season details.' : 'Create a new competitive season.'}
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
              <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
                {error}
              </div>
            )}
            <div className="space-y-2">
              <Label htmlFor="number">Season Number</Label>
              <Input
                id="number"
                type="number"
                min={1}
                value={form.number}
                onChange={(e) => setForm({ ...form, number: Number(e.target.value) })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="theme">Theme</Label>
              <Input
                id="theme"
                value={form.theme}
                onChange={(e) => setForm({ ...form, theme: e.target.value })}
                placeholder="e.g. Rise of the Dragon"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="startAt">Start At</Label>
                <Input
                  id="startAt"
                  type="datetime-local"
                  value={form.startAt}
                  onChange={(e) => setForm({ ...form, startAt: e.target.value })}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="endAt">End At</Label>
                <Input
                  id="endAt"
                  type="datetime-local"
                  value={form.endAt}
                  onChange={(e) => setForm({ ...form, endAt: e.target.value })}
                  required
                />
              </div>
            </div>
            <div className="flex justify-end gap-3 pt-2">
              <Button type="button" variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
              <Button type="submit" disabled={isPending}>
                {isPending ? 'Saving...' : editingSeason ? 'Update Season' : 'Create Season'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Season</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete Season {deletingSeason?.number}? This action cannot be undone.
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
