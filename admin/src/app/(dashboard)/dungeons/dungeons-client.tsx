'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from '@/components/ui/dialog'
import { Plus, Search, Trash2, Pencil, Castle } from 'lucide-react'

type DungeonSummary = {
  id: string
  slug: string
  name: string
  levelReq: number
  difficulty: string
  dungeonType: string
  energyCost: number
  isActive: boolean
  sortOrder: number
  goldReward: number
  xpReward: number
  bosses: { id: string; name: string; floorNumber: number }[]
  _count: { waves: number; drops: number }
}

const DIFFICULTY_COLORS: Record<string, string> = {
  easy: 'bg-green-600/20 text-green-400 border-green-600',
  normal: 'bg-blue-600/20 text-blue-400 border-blue-600',
  hard: 'bg-orange-600/20 text-orange-400 border-orange-600',
  nightmare: 'bg-red-600/20 text-red-400 border-red-600',
}

const TYPE_COLORS: Record<string, string> = {
  story: 'bg-purple-600/20 text-purple-400 border-purple-600',
  side: 'bg-zinc-600/20 text-zinc-400 border-zinc-600',
  event: 'bg-yellow-600/20 text-yellow-400 border-yellow-600',
  endgame: 'bg-red-600/20 text-red-400 border-red-600',
}

export function DungeonsClient({ dungeons }: { dungeons: DungeonSummary[] }) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [search, setSearch] = useState('')
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [deletingDungeon, setDeletingDungeon] = useState<DungeonSummary | null>(null)
  const [error, setError] = useState('')

  const filtered = dungeons.filter((d) =>
    d.name.toLowerCase().includes(search.toLowerCase()) ||
    d.slug.toLowerCase().includes(search.toLowerCase())
  )

  function handleCreate() {
    startTransition(async () => {
      try {
        const res = await fetch('/api/dungeons', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name: 'New Dungeon', slug: `dungeon_${Date.now()}` }),
        })
        if (!res.ok) {
          const data = await res.json()
          setError(data.error || 'Failed to create dungeon')
          return
        }
        const dungeon = await res.json()
        router.push(`/dungeons/${dungeon.id}`)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to create dungeon')
      }
    })
  }

  function openDelete(d: DungeonSummary) {
    setDeletingDungeon(d)
    setDeleteDialogOpen(true)
  }

  async function handleDelete() {
    if (!deletingDungeon) return
    startTransition(async () => {
      try {
        const res = await fetch(`/api/dungeons/${deletingDungeon.id}`, { method: 'DELETE' })
        if (!res.ok) {
          const data = await res.json()
          setError(data.error || 'Failed to delete dungeon')
          return
        }
        setDeleteDialogOpen(false)
        setDeletingDungeon(null)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to delete')
      }
    })
  }

  return (
    <>
      {error && (
        <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
          {error}
          <button className="ml-2 underline" onClick={() => setError('')}>Dismiss</button>
        </div>
      )}

      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[200px] max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search dungeons..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
        <Button onClick={handleCreate} disabled={isPending}>
          <Plus className="mr-2 h-4 w-4" />
          {isPending ? 'Creating...' : 'Create New Dungeon'}
        </Button>
      </div>

      <div className="rounded-lg border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/50">
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Dungeon</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Slug</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Level Req</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Difficulty</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Type</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Bosses</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
              <th className="px-4 py-3 text-right font-medium text-muted-foreground">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={8} className="px-4 py-12 text-center text-muted-foreground">
                  <Castle className="mx-auto mb-3 h-8 w-8 opacity-40" />
                  <p>No dungeons found.</p>
                  <p className="text-xs mt-1">Create your first dungeon to get started.</p>
                </td>
              </tr>
            ) : (
              filtered.map((d) => (
                <tr
                  key={d.id}
                  className="border-b border-border hover:bg-muted/30 cursor-pointer transition-colors"
                  onClick={() => router.push(`/dungeons/${d.id}`)}
                >
                  <td className="px-4 py-3 font-medium">{d.name}</td>
                  <td className="px-4 py-3 text-muted-foreground font-mono text-xs">{d.slug}</td>
                  <td className="px-4 py-3">{d.levelReq}</td>
                  <td className="px-4 py-3">
                    <Badge className={DIFFICULTY_COLORS[d.difficulty] ?? ''}>
                      {d.difficulty}
                    </Badge>
                  </td>
                  <td className="px-4 py-3">
                    <Badge className={TYPE_COLORS[d.dungeonType] ?? ''}>
                      {d.dungeonType}
                    </Badge>
                  </td>
                  <td className="px-4 py-3">
                    {d.bosses.length > 0
                      ? `${d.bosses.length} (${d.bosses[d.bosses.length - 1]?.name})`
                      : '0'}
                  </td>
                  <td className="px-4 py-3">
                    <Badge className={d.isActive
                      ? 'bg-green-600/20 text-green-400 border-green-600'
                      : 'bg-zinc-600/20 text-zinc-400 border-zinc-600'
                    }>
                      {d.isActive ? 'Active' : 'Disabled'}
                    </Badge>
                  </td>
                  <td className="px-4 py-3 text-right">
                    <div className="flex items-center justify-end gap-1">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={(e) => { e.stopPropagation(); router.push(`/dungeons/${d.id}`) }}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={(e) => { e.stopPropagation(); openDelete(d) }}
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
        Showing {filtered.length} of {dungeons.length} dungeons
      </p>

      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Dungeon</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete &quot;{deletingDungeon?.name}&quot;?
              This will remove all bosses, waves, abilities, and drop tables. This action cannot be undone.
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
