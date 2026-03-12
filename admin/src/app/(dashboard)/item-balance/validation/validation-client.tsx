'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from '@/components/ui/table'
import { RefreshCw, ShieldAlert, ChevronDown, ChevronUp, Wand2, Check } from 'lucide-react'

interface FlaggedItem {
  id: string
  catalogId: string
  itemName: string
  itemType: string
  rarity: string
  itemLevel: number
  baseStats: Record<string, number>
  powerScore: number
  expectedPower: number
  deviation: number
  deviationPercent: number
  status: 'overpowered' | 'underpowered'
  warnings: string[]
}

interface ValidationResult {
  totalItems: number
  validItems: number
  flaggedItems: FlaggedItem[]
  stats: {
    avgDeviation: number
    maxDeviation: number
    worstItem: string | null
    overpoweredCount: number
    underpoweredCount: number
  }
}

interface Suggestion {
  suggestedStats: Record<string, number>
  suggestedSellPrice: number
  reasoning: string[]
  currentPower: number
  targetPower: number
  adjustmentPercent: number
}

const RARITY_COLORS: Record<string, string> = {
  common: 'bg-zinc-500/10 text-zinc-600',
  uncommon: 'bg-green-500/10 text-green-600',
  rare: 'bg-blue-500/10 text-blue-600',
  epic: 'bg-purple-500/10 text-purple-600',
  legendary: 'bg-orange-500/10 text-orange-600',
}

export function ValidationClient({ adminId }: { adminId: string }) {
  const router = useRouter()
  const [running, setRunning] = useState(false)
  const [result, setResult] = useState<ValidationResult | null>(null)
  const [expandedId, setExpandedId] = useState<string | null>(null)
  const [suggestions, setSuggestions] = useState<Record<string, Suggestion>>({})
  const [loadingSuggestion, setLoadingSuggestion] = useState<string | null>(null)
  const [applyingId, setApplyingId] = useState<string | null>(null)
  const [appliedIds, setAppliedIds] = useState<Set<string>>(new Set())

  async function runValidation() {
    setRunning(true)
    setResult(null)
    try {
      const res = await fetch('/api/admin/item-balance/validate', {
        method: 'POST',
        credentials: 'include',
      })
      if (res.ok) {
        setResult(await res.json())
      }
    } finally {
      setRunning(false)
    }
  }

  async function loadSuggestion(itemId: string) {
    setLoadingSuggestion(itemId)
    try {
      const res = await fetch('/api/admin/item-balance/suggest', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ itemId }),
      })
      if (res.ok) {
        const data = await res.json()
        setSuggestions((prev) => ({ ...prev, [itemId]: data.suggestion }))
      }
    } finally {
      setLoadingSuggestion(null)
    }
  }

  async function applySuggestion(itemId: string) {
    const suggestion = suggestions[itemId]
    if (!suggestion) return

    setApplyingId(itemId)
    try {
      const res = await fetch('/api/admin/item-balance/apply-suggestions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          itemId,
          suggestedStats: suggestion.suggestedStats,
          suggestedSellPrice: suggestion.suggestedSellPrice,
        }),
      })
      if (res.ok) {
        setAppliedIds((prev) => new Set([...prev, itemId]))
      }
    } finally {
      setApplyingId(null)
    }
  }

  return (
    <div className="space-y-6">
      {/* Run Button */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <ShieldAlert className="h-5 w-5" />
                Balance Validation
              </CardTitle>
              <CardDescription>
                Scans all equipment items and flags any with power deviation beyond the configured threshold.
              </CardDescription>
            </div>
            <Button onClick={runValidation} disabled={running}>
              <RefreshCw className={`h-4 w-4 mr-2 ${running ? 'animate-spin' : ''}`} />
              {running ? 'Validating...' : 'Run Validation'}
            </Button>
          </div>
        </CardHeader>
      </Card>

      {/* Results Summary */}
      {result && (
        <>
          <div className="grid gap-4 md:grid-cols-5">
            <Card>
              <CardContent className="pt-6 text-center">
                <div className="text-2xl font-bold">{result.totalItems}</div>
                <div className="text-xs text-muted-foreground">Total Items</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6 text-center">
                <div className="text-2xl font-bold text-green-500">{result.validItems}</div>
                <div className="text-xs text-muted-foreground">Valid</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6 text-center">
                <div className="text-2xl font-bold text-red-500">{result.flaggedItems.length}</div>
                <div className="text-xs text-muted-foreground">Flagged</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6 text-center">
                <div className="text-2xl font-bold text-orange-500">{result.stats.overpoweredCount}</div>
                <div className="text-xs text-muted-foreground">Overpowered</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6 text-center">
                <div className="text-2xl font-bold text-blue-500">{result.stats.underpoweredCount}</div>
                <div className="text-xs text-muted-foreground">Underpowered</div>
              </CardContent>
            </Card>
          </div>

          {/* Flagged Items Table */}
          {result.flaggedItems.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Flagged Items</CardTitle>
                <CardDescription>
                  Sorted by deviation (worst first). Click a row to see details and suggestions.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Item</TableHead>
                      <TableHead>Type</TableHead>
                      <TableHead>Rarity</TableHead>
                      <TableHead>Level</TableHead>
                      <TableHead className="text-right">Power</TableHead>
                      <TableHead className="text-right">Expected</TableHead>
                      <TableHead className="text-right">Deviation</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead />
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {result.flaggedItems.map((item) => (
                      <>
                        <TableRow
                          key={item.id}
                          className="cursor-pointer hover:bg-accent/50"
                          onClick={() => setExpandedId(expandedId === item.id ? null : item.id)}
                        >
                          <TableCell className="font-medium">{item.itemName}</TableCell>
                          <TableCell className="capitalize">{item.itemType}</TableCell>
                          <TableCell>
                            <Badge variant="secondary" className={RARITY_COLORS[item.rarity] ?? ''}>
                              {item.rarity}
                            </Badge>
                          </TableCell>
                          <TableCell>{item.itemLevel}</TableCell>
                          <TableCell className="text-right font-mono">{item.powerScore}</TableCell>
                          <TableCell className="text-right font-mono">{item.expectedPower}</TableCell>
                          <TableCell className={`text-right font-mono ${item.deviationPercent > 0 ? 'text-orange-500' : 'text-blue-500'}`}>
                            {item.deviationPercent > 0 ? '+' : ''}{item.deviationPercent}%
                          </TableCell>
                          <TableCell>
                            <Badge variant={item.status === 'overpowered' ? 'destructive' : 'outline'}>
                              {item.status}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            {expandedId === item.id ? (
                              <ChevronUp className="h-4 w-4" />
                            ) : (
                              <ChevronDown className="h-4 w-4" />
                            )}
                          </TableCell>
                        </TableRow>

                        {/* Expanded detail row */}
                        {expandedId === item.id && (
                          <TableRow key={`${item.id}-detail`}>
                            <TableCell colSpan={9} className="bg-muted/30">
                              <div className="p-4 space-y-4">
                                {/* Current stats */}
                                <div>
                                  <h4 className="text-sm font-medium mb-2">Current Stats</h4>
                                  <div className="flex gap-2 flex-wrap">
                                    {Object.entries(item.baseStats).map(([stat, val]) => (
                                      <Badge key={stat} variant="outline" className="font-mono">
                                        {stat.toUpperCase()}: {val}
                                      </Badge>
                                    ))}
                                  </div>
                                </div>

                                {/* Warnings */}
                                {item.warnings.length > 0 && (
                                  <div>
                                    <h4 className="text-sm font-medium mb-2">Warnings</h4>
                                    <ul className="text-xs text-muted-foreground space-y-1">
                                      {item.warnings.map((w, i) => (
                                        <li key={i}>- {w}</li>
                                      ))}
                                    </ul>
                                  </div>
                                )}

                                {/* Suggestion */}
                                {suggestions[item.id] ? (
                                  <div className="border rounded-md p-3 space-y-3">
                                    <h4 className="text-sm font-medium">Suggested Changes</h4>
                                    <div className="flex gap-2 flex-wrap">
                                      {Object.entries(suggestions[item.id].suggestedStats).map(([stat, val]) => {
                                        const old = item.baseStats[stat] ?? 0
                                        const diff = val - old
                                        return (
                                          <Badge key={stat} variant="outline" className={`font-mono ${diff !== 0 ? 'border-green-500' : ''}`}>
                                            {stat.toUpperCase()}: {old} → {val}
                                            {diff !== 0 && ` (${diff > 0 ? '+' : ''}${diff})`}
                                          </Badge>
                                        )
                                      })}
                                    </div>
                                    <ul className="text-xs text-muted-foreground space-y-1">
                                      {suggestions[item.id].reasoning.map((r, i) => (
                                        <li key={i}>- {r}</li>
                                      ))}
                                    </ul>
                                    {appliedIds.has(item.id) ? (
                                      <Badge variant="default" className="bg-green-500">
                                        <Check className="h-3 w-3 mr-1" /> Applied
                                      </Badge>
                                    ) : (
                                      <Button
                                        size="sm"
                                        onClick={() => applySuggestion(item.id)}
                                        disabled={applyingId === item.id}
                                      >
                                        {applyingId === item.id ? 'Applying...' : 'Apply Changes'}
                                      </Button>
                                    )}
                                  </div>
                                ) : (
                                  <Button
                                    size="sm"
                                    variant="outline"
                                    onClick={() => loadSuggestion(item.id)}
                                    disabled={loadingSuggestion === item.id}
                                  >
                                    <Wand2 className="h-3 w-3 mr-1" />
                                    {loadingSuggestion === item.id ? 'Loading...' : 'Get Suggestions'}
                                  </Button>
                                )}
                              </div>
                            </TableCell>
                          </TableRow>
                        )}
                      </>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}

          {result.flaggedItems.length === 0 && (
            <Card>
              <CardContent className="py-12 text-center text-muted-foreground">
                All items are within the acceptable balance range.
              </CardContent>
            </Card>
          )}
        </>
      )}
    </div>
  )
}
