'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { searchPlayers, banPlayer, unbanPlayer } from '@/actions/players'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { Search, ChevronLeft, ChevronRight, Ban, ShieldCheck } from 'lucide-react'
import { formatDate } from '@/lib/utils'

type Player = {
  id: string
  email: string | null
  username: string | null
  gems: number
  role: string
  createdAt: string
  lastLogin: string | null
  isBanned: boolean
  banReason: string | null
  characterCount: number
}

export function PlayersClient({
  initialPlayers,
  initialTotal,
  initialPage,
  pageSize,
}: {
  initialPlayers: Player[]
  initialTotal: number
  initialPage: number
  pageSize: number
}) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [players, setPlayers] = useState(initialPlayers)
  const [total, setTotal] = useState(initialTotal)
  const [page, setPage] = useState(initialPage)
  const [query, setQuery] = useState('')
  const [banDialogOpen, setBanDialogOpen] = useState(false)
  const [banTarget, setBanTarget] = useState<Player | null>(null)
  const [banReason, setBanReason] = useState('')

  const totalPages = Math.ceil(total / pageSize)

  function doSearch(q: string, p: number) {
    startTransition(async () => {
      const result = await searchPlayers(q, p)
      setPlayers(JSON.parse(JSON.stringify(result.users)))
      setTotal(result.total)
      setPage(result.page)
    })
  }

  function handleSearch(e: React.FormEvent) {
    e.preventDefault()
    doSearch(query, 1)
  }

  function handlePageChange(newPage: number) {
    doSearch(query, newPage)
  }

  function handleBan(player: Player) {
    setBanTarget(player)
    setBanReason('')
    setBanDialogOpen(true)
  }

  async function confirmBan() {
    if (!banTarget) return
    startTransition(async () => {
      if (banTarget.isBanned) {
        await unbanPlayer(banTarget.id)
      } else {
        await banPlayer(banTarget.id, banReason)
      }
      setBanDialogOpen(false)
      doSearch(query, page)
    })
  }

  return (
    <>
      <form onSubmit={handleSearch} className="flex gap-3">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search by username or email..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="pl-9"
          />
        </div>
        <Button type="submit" disabled={isPending}>
          {isPending ? 'Searching...' : 'Search'}
        </Button>
      </form>

      <div className="rounded-lg border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/50">
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Username</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Email</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Gems</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Role</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Characters</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Joined</th>
              <th className="px-4 py-3 text-right font-medium text-muted-foreground">Actions</th>
            </tr>
          </thead>
          <tbody>
            {players.length === 0 ? (
              <tr>
                <td colSpan={8} className="px-4 py-8 text-center text-muted-foreground">
                  No players found.
                </td>
              </tr>
            ) : (
              players.map((player) => (
                <tr
                  key={player.id}
                  className="border-b border-border hover:bg-muted/30 cursor-pointer transition-colors"
                  onClick={() => router.push(`/players/${player.id}`)}
                >
                  <td className="px-4 py-3 font-medium">{player.username || '---'}</td>
                  <td className="px-4 py-3 text-muted-foreground">{player.email || '---'}</td>
                  <td className="px-4 py-3">{player.gems.toLocaleString()}</td>
                  <td className="px-4 py-3">
                    <Badge variant="secondary">{player.role}</Badge>
                  </td>
                  <td className="px-4 py-3">
                    {player.isBanned ? (
                      <Badge variant="destructive">Banned</Badge>
                    ) : (
                      <Badge variant="success">Active</Badge>
                    )}
                  </td>
                  <td className="px-4 py-3">{player.characterCount}</td>
                  <td className="px-4 py-3 text-muted-foreground">{formatDate(player.createdAt)}</td>
                  <td className="px-4 py-3 text-right">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={(e) => {
                        e.stopPropagation()
                        handleBan(player)
                      }}
                    >
                      {player.isBanned ? (
                        <>
                          <ShieldCheck className="mr-1 h-4 w-4" />
                          Unban
                        </>
                      ) : (
                        <>
                          <Ban className="mr-1 h-4 w-4" />
                          Ban
                        </>
                      )}
                    </Button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">
            Page {page} of {totalPages} ({total} total)
          </p>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page <= 1 || isPending}
              onClick={() => handlePageChange(page - 1)}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={page >= totalPages || isPending}
              onClick={() => handlePageChange(page + 1)}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}

      {/* Ban / Unban Dialog */}
      <Dialog open={banDialogOpen} onOpenChange={setBanDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {banTarget?.isBanned ? 'Unban Player' : 'Ban Player'}
            </DialogTitle>
            <DialogDescription>
              {banTarget?.isBanned
                ? `Remove ban from ${banTarget?.username || banTarget?.email || 'this player'}?`
                : `Ban ${banTarget?.username || banTarget?.email || 'this player'} from the game.`}
            </DialogDescription>
          </DialogHeader>
          {!banTarget?.isBanned && (
            <div className="space-y-2">
              <Label htmlFor="banReason">Ban Reason</Label>
              <Input
                id="banReason"
                value={banReason}
                onChange={(e) => setBanReason(e.target.value)}
                placeholder="Reason for the ban..."
                required
              />
            </div>
          )}
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setBanDialogOpen(false)}>Cancel</Button>
            <Button
              variant={banTarget?.isBanned ? 'default' : 'destructive'}
              onClick={confirmBan}
              disabled={isPending || (!banTarget?.isBanned && !banReason)}
            >
              {isPending ? 'Processing...' : banTarget?.isBanned ? 'Unban' : 'Ban Player'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  )
}
