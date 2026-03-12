'use client'

import { useState, useTransition, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import { updateConfig } from '@/actions/config'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Separator } from '@/components/ui/separator'
import { Save, AlertTriangle } from 'lucide-react'

type ConfigValue = {
  key: string
  value: number
  description: string | null
}

const SOURCE_LABELS: Record<string, string> = {
  'drop_chances.pvp': 'PvP Matches',
  'drop_chances.training': 'Training',
  'drop_chances.dungeon_easy': 'Dungeon (Easy)',
  'drop_chances.dungeon_normal': 'Dungeon (Normal)',
  'drop_chances.dungeon_hard': 'Dungeon (Hard)',
  'drop_chances.boss': 'Boss Fights',
}

const RARITY_LABELS: Record<string, string> = {
  'rarity_distribution.common': 'Common',
  'rarity_distribution.uncommon': 'Uncommon',
  'rarity_distribution.rare': 'Rare',
  'rarity_distribution.epic': 'Epic',
  'rarity_distribution.legendary': 'Legendary',
}

const RARITY_COLORS: Record<string, string> = {
  'rarity_distribution.common': 'bg-zinc-500',
  'rarity_distribution.uncommon': 'bg-green-500',
  'rarity_distribution.rare': 'bg-blue-500',
  'rarity_distribution.epic': 'bg-purple-500',
  'rarity_distribution.legendary': 'bg-orange-500',
}

export function LootClient({
  dropChances,
  rarityDistribution,
  adminId,
}: {
  dropChances: ConfigValue[]
  rarityDistribution: ConfigValue[]
  adminId: string
}) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [drops, setDrops] = useState<Record<string, number>>(
    Object.fromEntries(dropChances.map((d) => [d.key, typeof d.value === 'number' ? d.value : Number(d.value)]))
  )
  const [rarities, setRarities] = useState<Record<string, number>>(
    Object.fromEntries(rarityDistribution.map((r) => [r.key, typeof r.value === 'number' ? r.value : Number(r.value)]))
  )
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')

  const raritySum = useMemo(() => {
    return Object.values(rarities).reduce((sum, v) => sum + v, 0)
  }, [rarities])

  const raritySumValid = Math.abs(raritySum - 100) < 0.01

  function handleDropChange(key: string, value: number) {
    setDrops((prev) => ({ ...prev, [key]: value }))
  }

  function handleRarityChange(key: string, value: number) {
    setRarities((prev) => ({ ...prev, [key]: value }))
  }

  async function handleSaveDrops() {
    setError('')
    setMessage('')
    startTransition(async () => {
      try {
        for (const [key, value] of Object.entries(drops)) {
          await updateConfig(key, value, adminId)
        }
        setMessage('Drop chances saved successfully.')
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save')
      }
    })
  }

  async function handleSaveRarities() {
    if (!raritySumValid) {
      setError('Rarity distribution must sum to 100%')
      return
    }
    setError('')
    setMessage('')
    startTransition(async () => {
      try {
        for (const [key, value] of Object.entries(rarities)) {
          await updateConfig(key, value, adminId)
        }
        setMessage('Rarity distribution saved successfully.')
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save')
      }
    })
  }

  return (
    <div className="space-y-6">
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

      {/* Drop Chances by Source */}
      <Card>
        <CardHeader>
          <CardTitle>Drop Chances by Source</CardTitle>
          <CardDescription>Probability of receiving an item drop from each source.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          {dropChances.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              No drop chance configs found. Seed defaults from the Config page.
            </p>
          ) : (
            <>
              {dropChances.map((dc) => {
                const val = drops[dc.key] ?? 0
                const pct = Math.round(val * 100)
                return (
                  <div key={dc.key} className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">
                        {SOURCE_LABELS[dc.key] || dc.key}
                      </span>
                      <span className="text-sm font-mono text-muted-foreground">
                        {pct}%
                      </span>
                    </div>
                    <div className="flex items-center gap-3">
                      <input
                        type="range"
                        min={0}
                        max={100}
                        value={pct}
                        onChange={(e) => handleDropChange(dc.key, Number(e.target.value) / 100)}
                        className="flex-1 h-2 rounded-lg appearance-none bg-muted accent-primary cursor-pointer"
                      />
                      <Input
                        type="number"
                        min={0}
                        max={100}
                        value={pct}
                        onChange={(e) => handleDropChange(dc.key, Number(e.target.value) / 100)}
                        className="w-20 text-center font-mono text-xs"
                      />
                    </div>
                  </div>
                )
              })}
              <Separator />
              <div className="flex justify-end">
                <Button onClick={handleSaveDrops} disabled={isPending}>
                  <Save className="mr-2 h-4 w-4" />
                  {isPending ? 'Saving...' : 'Save Drop Chances'}
                </Button>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* Rarity Distribution */}
      <Card>
        <CardHeader>
          <CardTitle>Rarity Distribution</CardTitle>
          <CardDescription>Weight distribution for item rarities when a drop occurs. Must total 100%.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          {rarityDistribution.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              No rarity distribution configs found. Seed defaults from the Config page.
            </p>
          ) : (
            <>
              {/* Bar Chart Visualization */}
              <div className="flex h-8 w-full overflow-hidden rounded-lg border border-border">
                {rarityDistribution.map((rd) => {
                  const val = rarities[rd.key] ?? 0
                  if (val <= 0) return null
                  return (
                    <div
                      key={rd.key}
                      className={`${RARITY_COLORS[rd.key] || 'bg-zinc-500'} transition-all duration-300 flex items-center justify-center text-xs font-bold text-white`}
                      style={{ width: `${val}%` }}
                      title={`${RARITY_LABELS[rd.key] || rd.key}: ${val}%`}
                    >
                      {val >= 8 ? `${val}%` : ''}
                    </div>
                  )
                })}
              </div>

              {!raritySumValid && (
                <div className="flex items-center gap-2 rounded-md bg-amber-600/10 border border-amber-600/30 px-4 py-3 text-sm text-amber-400">
                  <AlertTriangle className="h-4 w-4 shrink-0" />
                  Rarity values sum to {raritySum}% (must be 100%)
                </div>
              )}

              {rarityDistribution.map((rd) => {
                const val = rarities[rd.key] ?? 0
                return (
                  <div key={rd.key} className="space-y-2">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className={`h-3 w-3 rounded-full ${RARITY_COLORS[rd.key] || 'bg-zinc-500'}`} />
                        <span className="text-sm font-medium">
                          {RARITY_LABELS[rd.key] || rd.key}
                        </span>
                      </div>
                      <span className="text-sm font-mono text-muted-foreground">
                        {val}%
                      </span>
                    </div>
                    <div className="flex items-center gap-3">
                      <input
                        type="range"
                        min={0}
                        max={100}
                        value={val}
                        onChange={(e) => handleRarityChange(rd.key, Number(e.target.value))}
                        className="flex-1 h-2 rounded-lg appearance-none bg-muted accent-primary cursor-pointer"
                      />
                      <Input
                        type="number"
                        min={0}
                        max={100}
                        value={val}
                        onChange={(e) => handleRarityChange(rd.key, Number(e.target.value))}
                        className="w-20 text-center font-mono text-xs"
                      />
                    </div>
                  </div>
                )
              })}
              <Separator />
              <div className="flex items-center justify-between">
                <p className="text-sm text-muted-foreground">
                  Total: <span className={raritySumValid ? 'text-green-400' : 'text-amber-400'}>{raritySum}%</span>
                </p>
                <Button onClick={handleSaveRarities} disabled={isPending || !raritySumValid}>
                  <Save className="mr-2 h-4 w-4" />
                  {isPending ? 'Saving...' : 'Save Rarity Distribution'}
                </Button>
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
