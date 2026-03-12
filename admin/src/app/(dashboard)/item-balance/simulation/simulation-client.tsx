'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Play, Loader2 } from 'lucide-react'

const CLASSES = ['warrior', 'tank', 'rogue', 'mage'] as const
const STATS = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha'] as const

interface SimHistory {
  id: string
  runType: string
  config: Record<string, unknown>
  results: Record<string, unknown>
  summary: string | null
  createdAt: string
}

const RUN_TYPE_LABELS: Record<string, string> = {
  combat_sim: 'Combat Sim',
  class_matchups: 'Class Matchups',
  item_impact: 'Item Impact',
  item_audit: 'Item Audit',
}

export function SimulationClient({
  history,
  adminId,
}: {
  history: SimHistory[]
  adminId: string
}) {
  const router = useRouter()

  // --- Combat Sim State ---
  const [classA, setClassA] = useState('warrior')
  const [classB, setClassB] = useState('rogue')
  const [levelA, setLevelA] = useState(10)
  const [levelB, setLevelB] = useState(10)
  const [gearA, setGearA] = useState(0)
  const [gearB, setGearB] = useState(0)
  const [combatIterations, setCombatIterations] = useState(1000)
  const [combatRunning, setCombatRunning] = useState(false)
  const [combatResult, setCombatResult] = useState<Record<string, unknown> | null>(null)

  // --- Matchups State ---
  const [matchupLevel, setMatchupLevel] = useState(10)
  const [matchupGear, setMatchupGear] = useState(0)
  const [matchupIterations, setMatchupIterations] = useState(500)
  const [matchupRunning, setMatchupRunning] = useState(false)
  const [matchupResult, setMatchupResult] = useState<{ matrix: Record<string, Record<string, number>>; classes: string[] } | null>(null)

  // --- Item Impact State ---
  const [impactClass, setImpactClass] = useState('warrior')
  const [impactLevel, setImpactLevel] = useState(10)
  const [impactStats, setImpactStats] = useState<Record<string, number>>({ str: 5, vit: 3 })
  const [impactRunning, setImpactRunning] = useState(false)
  const [impactResult, setImpactResult] = useState<Record<string, unknown> | null>(null)

  async function runCombatSim() {
    setCombatRunning(true)
    setCombatResult(null)
    try {
      const res = await fetch('/api/admin/item-balance/simulate/combat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          charA: { class: classA, level: levelA, gearPowerScore: gearA },
          charB: { class: classB, level: levelB, gearPowerScore: gearB },
          iterations: combatIterations,
        }),
      })
      if (res.ok) setCombatResult(await res.json())
    } finally {
      setCombatRunning(false)
    }
  }

  async function runMatchups() {
    setMatchupRunning(true)
    setMatchupResult(null)
    try {
      const res = await fetch('/api/admin/item-balance/simulate/matchups', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          level: matchupLevel,
          gearPowerScore: matchupGear,
          iterations: matchupIterations,
        }),
      })
      if (res.ok) setMatchupResult(await res.json())
    } finally {
      setMatchupRunning(false)
    }
  }

  async function runItemImpact() {
    setImpactRunning(true)
    setImpactResult(null)
    try {
      const res = await fetch('/api/admin/item-balance/simulate/item-impact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          itemStats: impactStats,
          characterClass: impactClass,
          characterLevel: impactLevel,
        }),
      })
      if (res.ok) setImpactResult(await res.json())
    } finally {
      setImpactRunning(false)
    }
  }

  function getHeatmapColor(value: number): string {
    if (value >= 60) return 'bg-green-500 text-white'
    if (value >= 55) return 'bg-green-400 text-white'
    if (value >= 52) return 'bg-green-300 text-green-900'
    if (value >= 48) return 'bg-zinc-200 text-zinc-700'
    if (value >= 45) return 'bg-red-300 text-red-900'
    if (value >= 40) return 'bg-red-400 text-white'
    return 'bg-red-500 text-white'
  }

  return (
    <Tabs defaultValue="combat" className="space-y-4">
      <TabsList>
        <TabsTrigger value="combat">Combat Simulator</TabsTrigger>
        <TabsTrigger value="matchups">Class Matchups</TabsTrigger>
        <TabsTrigger value="impact">Item Impact</TabsTrigger>
        <TabsTrigger value="history">History</TabsTrigger>
      </TabsList>

      {/* Combat Simulator */}
      <TabsContent value="combat" className="space-y-4">
        <Card>
          <CardHeader>
            <CardTitle>1v1 Combat Simulation</CardTitle>
            <CardDescription>Configure two fighters and run thousands of simulated fights.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid md:grid-cols-2 gap-6">
              {/* Fighter A */}
              <div className="space-y-3">
                <h3 className="font-medium text-sm">Fighter A</h3>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <Label className="text-xs">Class</Label>
                    <Select value={classA} onValueChange={setClassA}>
                      <SelectTrigger><SelectValue /></SelectTrigger>
                      <SelectContent>
                        {CLASSES.map((c) => (
                          <SelectItem key={c} value={c} className="capitalize">{c}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label className="text-xs">Level</Label>
                    <Input type="number" value={levelA} onChange={(e) => setLevelA(+e.target.value)} min={1} max={50} />
                  </div>
                  <div className="col-span-2">
                    <Label className="text-xs">Gear Power Score</Label>
                    <Input type="number" value={gearA} onChange={(e) => setGearA(+e.target.value)} min={0} />
                  </div>
                </div>
              </div>

              {/* Fighter B */}
              <div className="space-y-3">
                <h3 className="font-medium text-sm">Fighter B</h3>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <Label className="text-xs">Class</Label>
                    <Select value={classB} onValueChange={setClassB}>
                      <SelectTrigger><SelectValue /></SelectTrigger>
                      <SelectContent>
                        {CLASSES.map((c) => (
                          <SelectItem key={c} value={c} className="capitalize">{c}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label className="text-xs">Level</Label>
                    <Input type="number" value={levelB} onChange={(e) => setLevelB(+e.target.value)} min={1} max={50} />
                  </div>
                  <div className="col-span-2">
                    <Label className="text-xs">Gear Power Score</Label>
                    <Input type="number" value={gearB} onChange={(e) => setGearB(+e.target.value)} min={0} />
                  </div>
                </div>
              </div>
            </div>

            <div className="flex items-end gap-4 mt-4">
              <div>
                <Label className="text-xs">Iterations</Label>
                <Input type="number" value={combatIterations} onChange={(e) => setCombatIterations(+e.target.value)} min={100} max={10000} className="w-32" />
              </div>
              <Button onClick={runCombatSim} disabled={combatRunning}>
                {combatRunning ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : <Play className="h-4 w-4 mr-2" />}
                {combatRunning ? 'Running...' : 'Run Simulation'}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Combat Results */}
        {combatResult && (
          <Card>
            <CardHeader>
              <CardTitle>Results</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {[
                  { label: `${classA} Win Rate`, value: `${combatResult.winRateA}%`, color: Number(combatResult.winRateA) > 50 ? 'text-green-500' : 'text-red-500' },
                  { label: `${classB} Win Rate`, value: `${combatResult.winRateB}%`, color: Number(combatResult.winRateB) > 50 ? 'text-green-500' : 'text-red-500' },
                  { label: 'Avg Turns', value: String(combatResult.avgTurns) },
                  { label: `${classA} Avg DMG/Hit`, value: String(combatResult.avgDamagePerHitA) },
                  { label: `${classB} Avg DMG/Hit`, value: String(combatResult.avgDamagePerHitB) },
                  { label: `${classA} Crit Rate`, value: `${combatResult.critRateA}%` },
                  { label: `${classB} Crit Rate`, value: `${combatResult.critRateB}%` },
                  { label: `${classA} Dodge Rate`, value: `${combatResult.dodgeRateA}%` },
                  { label: `${classB} Dodge Rate`, value: `${combatResult.dodgeRateB}%` },
                ].map(({ label, value, color }) => (
                  <div key={label} className="text-center p-3 border rounded-md">
                    <div className={`text-lg font-bold ${color ?? ''}`}>{value}</div>
                    <div className="text-xs text-muted-foreground capitalize">{label}</div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}
      </TabsContent>

      {/* Class Matchups */}
      <TabsContent value="matchups" className="space-y-4">
        <Card>
          <CardHeader>
            <CardTitle>Class Matchup Matrix</CardTitle>
            <CardDescription>4x4 round-robin win rate matrix at a given level and gear power.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-end gap-4">
              <div>
                <Label className="text-xs">Level</Label>
                <Input type="number" value={matchupLevel} onChange={(e) => setMatchupLevel(+e.target.value)} min={1} max={50} className="w-24" />
              </div>
              <div>
                <Label className="text-xs">Gear Power</Label>
                <Input type="number" value={matchupGear} onChange={(e) => setMatchupGear(+e.target.value)} min={0} className="w-24" />
              </div>
              <div>
                <Label className="text-xs">Iterations</Label>
                <Input type="number" value={matchupIterations} onChange={(e) => setMatchupIterations(+e.target.value)} min={100} max={5000} className="w-24" />
              </div>
              <Button onClick={runMatchups} disabled={matchupRunning}>
                {matchupRunning ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : <Play className="h-4 w-4 mr-2" />}
                {matchupRunning ? 'Running...' : 'Run Matchups'}
              </Button>
            </div>
          </CardContent>
        </Card>

        {matchupResult && (
          <Card>
            <CardHeader>
              <CardTitle>Win Rate Heatmap</CardTitle>
              <CardDescription>Row = attacker, Column = defender. Values show attacker win rate %.</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr>
                      <th className="p-2 text-left" />
                      {matchupResult.classes.map((cls) => (
                        <th key={cls} className="p-2 text-center capitalize font-medium">{cls}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {matchupResult.classes.map((rowCls) => (
                      <tr key={rowCls}>
                        <td className="p-2 capitalize font-medium">{rowCls}</td>
                        {matchupResult.classes.map((colCls) => {
                          const value = matchupResult.matrix[rowCls]?.[colCls] ?? 50
                          return (
                            <td key={colCls} className={`p-2 text-center font-mono text-sm rounded ${getHeatmapColor(value)}`}>
                              {value.toFixed(1)}%
                            </td>
                          )
                        })}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        )}
      </TabsContent>

      {/* Item Impact */}
      <TabsContent value="impact" className="space-y-4">
        <Card>
          <CardHeader>
            <CardTitle>Item Impact Simulation</CardTitle>
            <CardDescription>See how adding specific stats affects combat performance.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                <div>
                  <Label className="text-xs">Class</Label>
                  <Select value={impactClass} onValueChange={setImpactClass}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {CLASSES.map((c) => (
                        <SelectItem key={c} value={c} className="capitalize">{c}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label className="text-xs">Level</Label>
                  <Input type="number" value={impactLevel} onChange={(e) => setImpactLevel(+e.target.value)} min={1} max={50} />
                </div>
              </div>

              <div>
                <Label className="text-xs mb-2 block">Item Stats</Label>
                <div className="grid grid-cols-4 md:grid-cols-8 gap-2">
                  {STATS.map((stat) => (
                    <div key={stat}>
                      <Label className="text-xs uppercase">{stat}</Label>
                      <Input
                        type="number"
                        value={impactStats[stat] ?? 0}
                        onChange={(e) => setImpactStats((prev) => ({ ...prev, [stat]: +e.target.value }))}
                        min={0}
                        className="h-8 text-xs"
                      />
                    </div>
                  ))}
                </div>
              </div>

              <Button onClick={runItemImpact} disabled={impactRunning}>
                {impactRunning ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : <Play className="h-4 w-4 mr-2" />}
                {impactRunning ? 'Running...' : 'Run Simulation'}
              </Button>
            </div>
          </CardContent>
        </Card>

        {impactResult && (
          <Card>
            <CardHeader>
              <CardTitle>Impact Results</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-3 gap-4">
                {[
                  { label: 'DPS Change', value: `${Number(impactResult.dpsChangePercent) > 0 ? '+' : ''}${impactResult.dpsChangePercent}%`, sub: `${impactResult.baselineDps} → ${impactResult.withItemDps}` },
                  { label: 'Win Rate Change', value: `${Number(impactResult.winRateChange) > 0 ? '+' : ''}${impactResult.winRateChange}%`, sub: `${impactResult.baselineWinRate}% → ${impactResult.withItemWinRate}%` },
                  { label: 'TTK Change', value: `${Number(impactResult.ttkChange) > 0 ? '+' : ''}${impactResult.ttkChange}`, sub: `${impactResult.baselineTtk} → ${impactResult.withItemTtk} turns` },
                ].map(({ label, value, sub }) => (
                  <div key={label} className="text-center p-4 border rounded-md">
                    <div className={`text-xl font-bold ${Number(value) > 0 ? 'text-green-500' : Number(value) < 0 ? 'text-red-500' : ''}`}>
                      {value}
                    </div>
                    <div className="text-sm font-medium">{label}</div>
                    <div className="text-xs text-muted-foreground">{sub}</div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}
      </TabsContent>

      {/* History */}
      <TabsContent value="history" className="space-y-4">
        <Card>
          <CardHeader>
            <CardTitle>Simulation History</CardTitle>
            <CardDescription>Past simulation runs</CardDescription>
          </CardHeader>
          <CardContent>
            {history.length > 0 ? (
              <div className="space-y-3">
                {history.map((sim) => (
                  <div key={sim.id} className="flex items-center justify-between py-3 border-b last:border-0">
                    <div className="flex items-center gap-3">
                      <Badge variant="secondary">
                        {RUN_TYPE_LABELS[sim.runType] ?? sim.runType}
                      </Badge>
                      <span className="text-sm">{sim.summary ?? '—'}</span>
                    </div>
                    <span className="text-xs text-muted-foreground">
                      {new Date(sim.createdAt).toLocaleString()}
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8 text-muted-foreground">
                No simulation runs yet. Run a simulation above to see results here.
              </div>
            )}
          </CardContent>
        </Card>
      </TabsContent>
    </Tabs>
  )
}
