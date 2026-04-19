'use client'

import { useState, useMemo } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'

export interface MinigameSessionRow {
  id: string
  characterId: string
  characterName: string
  userEmail: string | null
  userUsername: string | null
  gameType: string
  status: string
  betAmount: number
  claimedGold: number | null
  claimedGems: number | null
  createdAt: string
  claimedAt: string | null
  expiresAt: string | null
}

export interface PerGameCount {
  gameType: string
  count: number
}

function formatDate(iso: string | null) {
  if (!iso) return '—'
  const d = new Date(iso)
  return d.toLocaleString('en-GB', {
    day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit',
  })
}

function statusBadge(status: string) {
  const map: Record<string, string> = {
    active: 'bg-blue-500/20 text-blue-300',
    completed: 'bg-green-500/20 text-green-300',
    expired: 'bg-gray-500/20 text-gray-300',
    claimed: 'bg-purple-500/20 text-purple-300',
  }
  return map[status] ?? 'bg-muted text-muted-foreground'
}

export function MinigameSessionsClient({ rows, counts }: { rows: MinigameSessionRow[], counts: PerGameCount[] }) {
  const [gameFilter, setGameFilter] = useState<string>('all')
  const [playerFilter, setPlayerFilter] = useState('')

  const gameTypes = useMemo(
    () => ['all', ...counts.map((c) => c.gameType)],
    [counts],
  )

  const filtered = rows.filter((r) => {
    if (gameFilter !== 'all' && r.gameType !== gameFilter) return false
    if (playerFilter) {
      const q = playerFilter.toLowerCase()
      const hay = `${r.characterName} ${r.userEmail ?? ''} ${r.userUsername ?? ''}`.toLowerCase()
      if (!hay.includes(q)) return false
    }
    return true
  })

  return (
    <div className="space-y-4">
      <div className="grid gap-3 grid-cols-2 md:grid-cols-4">
        {counts.map((c) => (
          <Card key={c.gameType}>
            <CardHeader className="pb-2">
              <CardTitle className="text-xs text-muted-foreground font-mono">{c.gameType}</CardTitle>
            </CardHeader>
            <CardContent className="text-2xl font-bold">{c.count.toLocaleString()}</CardContent>
          </Card>
        ))}
      </div>

      <div className="flex flex-wrap gap-3 items-center">
        <select
          className="rounded-md border border-border bg-background px-3 py-2 text-sm"
          value={gameFilter}
          onChange={(e) => setGameFilter(e.target.value)}
        >
          {gameTypes.map((g) => (
            <option key={g} value={g}>{g === 'all' ? 'All games' : g}</option>
          ))}
        </select>
        <Input
          type="search"
          placeholder="Filter by player name / email / username…"
          value={playerFilter}
          onChange={(e) => setPlayerFilter(e.target.value)}
          className="max-w-sm"
        />
        <span className="text-xs text-muted-foreground">
          {filtered.length} of {rows.length} sessions
        </span>
      </div>

      <div className="rounded-lg border border-border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/50">
            <tr>
              <th className="text-left p-3 font-medium">Game</th>
              <th className="text-left p-3 font-medium">Player</th>
              <th className="text-left p-3 font-medium">Status</th>
              <th className="text-right p-3 font-medium">Bet</th>
              <th className="text-right p-3 font-medium">Gold</th>
              <th className="text-right p-3 font-medium">Gems</th>
              <th className="text-left p-3 font-medium">Created</th>
              <th className="text-left p-3 font-medium">Claimed</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((r) => (
              <tr key={r.id} className="border-t border-border">
                <td className="p-3 font-mono text-xs">{r.gameType}</td>
                <td className="p-3">
                  <div className="font-medium">{r.characterName}</div>
                  <div className="text-xs text-muted-foreground">
                    {r.userUsername ?? r.userEmail ?? r.characterId}
                  </div>
                </td>
                <td className="p-3">
                  <Badge className={statusBadge(r.status)}>{r.status}</Badge>
                </td>
                <td className="p-3 text-right">{r.betAmount || '—'}</td>
                <td className="p-3 text-right">{r.claimedGold ?? '—'}</td>
                <td className="p-3 text-right">{r.claimedGems ?? '—'}</td>
                <td className="p-3 text-xs">{formatDate(r.createdAt)}</td>
                <td className="p-3 text-xs">{formatDate(r.claimedAt)}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && (
          <div className="p-8 text-center text-muted-foreground text-sm">
            No sessions match the current filter.
          </div>
        )}
      </div>
    </div>
  )
}
