'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { createEvent, updateEvent, deleteEvent, toggleEventActive } from '@/actions/events'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Textarea } from '@/components/ui/textarea'
import { Switch } from '@/components/ui/switch'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from '@/components/ui/dialog'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import { Plus, Pencil, Trash2, Calendar, Zap } from 'lucide-react'
import { formatDate } from '@/lib/utils'

type Event = {
  id: string
  eventKey: string
  title: string
  description: string
  eventType: string
  config: unknown
  startAt: string
  endAt: string
  isActive: boolean
  createdAt: string
}

const EVENT_TYPES = ['boss_rush', 'gold_rush', 'class_spotlight', 'tournament']

const EVENT_TYPE_COLORS: Record<string, string> = {
  boss_rush: 'bg-red-600/20 text-red-400 border-red-600',
  gold_rush: 'bg-amber-600/20 text-amber-400 border-amber-600',
  class_spotlight: 'bg-blue-600/20 text-blue-400 border-blue-600',
  tournament: 'bg-purple-600/20 text-purple-400 border-purple-600',
}

const emptyForm = {
  eventKey: '',
  title: '',
  description: '',
  eventType: 'boss_rush',
  config: '{}',
  startAt: '',
  endAt: '',
}

export function EventsClient({ events }: { events: Event[] }) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [dialogOpen, setDialogOpen] = useState(false)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [editingEvent, setEditingEvent] = useState<Event | null>(null)
  const [deletingEvent, setDeletingEvent] = useState<Event | null>(null)
  const [form, setForm] = useState(emptyForm)
  const [error, setError] = useState('')

  function toDatetimeLocal(dateStr: string) {
    if (!dateStr) return ''
    const d = new Date(dateStr)
    return d.toISOString().slice(0, 16)
  }

  function isExpired(endAt: string) {
    return new Date(endAt) < new Date()
  }

  function isUpcoming(startAt: string) {
    return new Date(startAt) > new Date()
  }

  function openCreate() {
    setEditingEvent(null)
    setForm(emptyForm)
    setError('')
    setDialogOpen(true)
  }

  function openEdit(event: Event) {
    setEditingEvent(event)
    setForm({
      eventKey: event.eventKey,
      title: event.title,
      description: event.description,
      eventType: event.eventType,
      config: JSON.stringify(event.config ?? {}, null, 2),
      startAt: toDatetimeLocal(event.startAt),
      endAt: toDatetimeLocal(event.endAt),
    })
    setError('')
    setDialogOpen(true)
  }

  function handleToggleActive(event: Event) {
    startTransition(async () => {
      await toggleEventActive(event.id)
      router.refresh()
    })
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')

    let parsedConfig: unknown
    try {
      parsedConfig = JSON.parse(form.config || '{}')
    } catch {
      setError('Invalid JSON in Config field')
      return
    }

    startTransition(async () => {
      try {
        if (editingEvent) {
          await updateEvent(editingEvent.id, {
            eventKey: form.eventKey,
            title: form.title,
            description: form.description,
            eventType: form.eventType as 'boss_rush' | 'gold_rush' | 'class_spotlight' | 'tournament',
            config: parsedConfig,
            startAt: new Date(form.startAt),
            endAt: new Date(form.endAt),
          })
        } else {
          await createEvent({
            eventKey: form.eventKey,
            title: form.title,
            description: form.description,
            eventType: form.eventType as 'boss_rush' | 'gold_rush' | 'class_spotlight' | 'tournament',
            config: parsedConfig,
            startAt: new Date(form.startAt),
            endAt: new Date(form.endAt),
          })
        }
        setDialogOpen(false)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save event')
      }
    })
  }

  async function handleDelete() {
    if (!deletingEvent) return
    startTransition(async () => {
      try {
        await deleteEvent(deletingEvent.id)
        setDeleteDialogOpen(false)
        setDeletingEvent(null)
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
          Create Event
        </Button>
      </div>

      {events.length === 0 ? (
        <div className="rounded-lg border border-border p-8 text-center text-muted-foreground">
          <Calendar className="mx-auto h-12 w-12 mb-4 opacity-50" />
          <p>No events created yet.</p>
        </div>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {events.map((event) => {
            const expired = isExpired(event.endAt)
            const upcoming = isUpcoming(event.startAt)
            return (
              <Card
                key={event.id}
                className={
                  event.isActive && !expired
                    ? 'border-green-600/50'
                    : expired
                    ? 'border-zinc-700 opacity-60'
                    : ''
                }
              >
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between">
                    <div className="space-y-1">
                      <CardTitle className="text-base">{event.title}</CardTitle>
                      <p className="text-xs text-muted-foreground font-mono">{event.eventKey}</p>
                    </div>
                    <Badge className={EVENT_TYPE_COLORS[event.eventType] ?? ''}>
                      {event.eventType.replace(/_/g, ' ')}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent className="space-y-3">
                  <p className="text-sm text-muted-foreground line-clamp-2">
                    {event.description}
                  </p>
                  <div className="text-xs text-muted-foreground space-y-1">
                    <p>Start: {formatDate(event.startAt)}</p>
                    <p>End: {formatDate(event.endAt)}</p>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Switch
                        checked={event.isActive}
                        onCheckedChange={() => handleToggleActive(event)}
                        disabled={isPending}
                      />
                      <span className="text-xs text-muted-foreground">
                        {event.isActive ? 'Active' : 'Inactive'}
                      </span>
                      {expired && (
                        <Badge variant="secondary" className="text-xs">Expired</Badge>
                      )}
                      {upcoming && (
                        <Badge className="bg-blue-600/20 text-blue-400 border-blue-600 text-xs">
                          Upcoming
                        </Badge>
                      )}
                      {event.isActive && !expired && !upcoming && (
                        <Zap className="h-3 w-3 text-green-400" />
                      )}
                    </div>
                    <div className="flex gap-1">
                      <Button variant="ghost" size="icon" onClick={() => openEdit(event)}>
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => {
                          setDeletingEvent(event)
                          setDeleteDialogOpen(true)
                        }}
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )
          })}
        </div>
      )}

      {/* Create / Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingEvent ? 'Edit Event' : 'Create Event'}</DialogTitle>
            <DialogDescription>
              {editingEvent ? 'Update event details.' : 'Schedule a new in-game event.'}
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
              <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
                {error}
              </div>
            )}
            <div className="space-y-2">
              <Label htmlFor="eventKey">Event Key</Label>
              <Input
                id="eventKey"
                value={form.eventKey}
                onChange={(e) => setForm({ ...form, eventKey: e.target.value })}
                placeholder="e.g. gold_rush_march_2026"
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="title">Title</Label>
              <Input
                id="title"
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
                placeholder="March Gold Rush"
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="description">Description</Label>
              <Textarea
                id="description"
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
                rows={2}
                required
              />
            </div>
            <div className="space-y-2">
              <Label>Event Type</Label>
              <Select value={form.eventType} onValueChange={(v) => setForm({ ...form, eventType: v })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {EVENT_TYPES.map((t) => (
                    <SelectItem key={t} value={t}>
                      {t.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="config">Config (JSON)</Label>
              <Textarea
                id="config"
                value={form.config}
                onChange={(e) => setForm({ ...form, config: e.target.value })}
                placeholder='{"multiplier": 2}'
                className="font-mono text-xs"
                rows={4}
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
              <Button type="button" variant="outline" onClick={() => setDialogOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={isPending}>
                {isPending ? 'Saving...' : editingEvent ? 'Update Event' : 'Create Event'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Event</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete &quot;{deletingEvent?.title}&quot;? This action cannot be undone.
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
