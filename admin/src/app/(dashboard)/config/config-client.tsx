'use client'

import { useState, useTransition, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import { updateConfig, seedDefaultConfigs } from '@/actions/config'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Save, RefreshCw, Check, Database } from 'lucide-react'

type ConfigItem = {
  key: string
  value: unknown
  category: string
  description: string | null
  updatedAt: string
  updatedBy: string | null
}

const CATEGORY_LABELS: Record<string, string> = {
  stamina: 'Stamina',
  gold_rewards: 'Gold Rewards',
  xp_rewards: 'XP Rewards',
  drop_chances: 'Drop Chances',
  rarity_distribution: 'Rarity Distribution',
  elo: 'ELO',
  combat: 'Combat',
  prestige: 'Prestige',
  upgrade: 'Upgrade',
  battle_pass: 'Battle Pass',
  first_win_bonus: 'First Win Bonus',
  win_streak: 'Win Streak',
  matchmaking: 'Matchmaking',
  hp_regen: 'HP Regen',
  skills: 'Skills',
  passives: 'Passives',
  gem_costs: 'Gem Costs',
  inventory: 'Inventory',
  general: 'General',
}

export function ConfigClient({ configs, adminId }: { configs: ConfigItem[]; adminId: string }) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [editedValues, setEditedValues] = useState<Record<string, string>>({})
  const [savedKeys, setSavedKeys] = useState<Set<string>>(new Set())
  const [savingKey, setSavingKey] = useState<string | null>(null)
  const [error, setError] = useState('')
  const [seedMessage, setSeedMessage] = useState('')

  const categories = useMemo(() => {
    const cats = new Map<string, ConfigItem[]>()
    for (const config of configs) {
      const cat = config.category || 'general'
      if (!cats.has(cat)) cats.set(cat, [])
      cats.get(cat)!.push(config)
    }
    return cats
  }, [configs])

  const categoryKeys = useMemo(() => {
    const order = Object.keys(CATEGORY_LABELS)
    return Array.from(categories.keys()).sort((a, b) => {
      const ai = order.indexOf(a)
      const bi = order.indexOf(b)
      return (ai === -1 ? 999 : ai) - (bi === -1 ? 999 : bi)
    })
  }, [categories])

  function getDisplayValue(config: ConfigItem): string {
    if (editedValues[config.key] !== undefined) return editedValues[config.key]
    const val = config.value
    if (typeof val === 'object') return JSON.stringify(val)
    return String(val)
  }

  function handleValueChange(key: string, value: string) {
    setEditedValues((prev) => ({ ...prev, [key]: value }))
    setSavedKeys((prev) => {
      const next = new Set(prev)
      next.delete(key)
      return next
    })
  }

  async function handleSave(config: ConfigItem) {
    const rawValue = editedValues[config.key]
    if (rawValue === undefined) return

    let parsedValue: unknown
    try {
      parsedValue = JSON.parse(rawValue)
    } catch {
      parsedValue = isNaN(Number(rawValue)) ? rawValue : Number(rawValue)
    }

    setSavingKey(config.key)
    setError('')

    startTransition(async () => {
      try {
        await updateConfig(config.key, parsedValue, adminId)
        setSavedKeys((prev) => new Set(prev).add(config.key))
        setEditedValues((prev) => {
          const next = { ...prev }
          delete next[config.key]
          return next
        })
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save')
      } finally {
        setSavingKey(null)
      }
    })
  }

  async function handleSeed() {
    setSeedMessage('')
    startTransition(async () => {
      try {
        const result = await seedDefaultConfigs()
        setSeedMessage(`Seeded ${result.created} configs (${result.skipped} already existed)`)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to seed')
      }
    })
  }

  if (configs.length === 0) {
    return (
      <Card>
        <CardContent className="flex flex-col items-center justify-center py-12">
          <Database className="h-12 w-12 mb-4 text-muted-foreground opacity-50" />
          <p className="text-muted-foreground mb-4">No configuration keys found.</p>
          <Button onClick={handleSeed} disabled={isPending}>
            <RefreshCw className="mr-2 h-4 w-4" />
            {isPending ? 'Seeding...' : 'Seed Default Configs'}
          </Button>
          {seedMessage && (
            <p className="mt-3 text-sm text-green-400">{seedMessage}</p>
          )}
        </CardContent>
      </Card>
    )
  }

  return (
    <>
      {error && (
        <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
          {error}
        </div>
      )}

      <div className="flex justify-end">
        <Button variant="outline" onClick={handleSeed} disabled={isPending}>
          <RefreshCw className="mr-2 h-4 w-4" />
          Seed Defaults
        </Button>
      </div>

      {seedMessage && (
        <div className="rounded-md bg-green-600/10 border border-green-600/30 px-4 py-3 text-sm text-green-400">
          {seedMessage}
        </div>
      )}

      <Tabs defaultValue={categoryKeys[0]} className="w-full">
        <TabsList className="flex flex-wrap h-auto gap-1 bg-transparent p-0">
          {categoryKeys.map((cat) => (
            <TabsTrigger
              key={cat}
              value={cat}
              className="data-[state=active]:bg-primary/10 data-[state=active]:text-primary"
            >
              {CATEGORY_LABELS[cat] || cat}
            </TabsTrigger>
          ))}
        </TabsList>

        {categoryKeys.map((cat) => (
          <TabsContent key={cat} value={cat} className="mt-4 space-y-3">
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base">
                  {CATEGORY_LABELS[cat] || cat}
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {categories.get(cat)?.map((config) => {
                  const hasChanges = editedValues[config.key] !== undefined
                  const isSaving = savingKey === config.key
                  const isSaved = savedKeys.has(config.key)

                  return (
                    <div
                      key={config.key}
                      className="flex items-start gap-4 rounded-lg border border-border p-3"
                    >
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium font-mono">{config.key}</p>
                        {config.description && (
                          <p className="text-xs text-muted-foreground mt-0.5">
                            {config.description}
                          </p>
                        )}
                      </div>
                      <div className="flex items-center gap-2 shrink-0">
                        <Input
                          value={getDisplayValue(config)}
                          onChange={(e) => handleValueChange(config.key, e.target.value)}
                          className="w-48 font-mono text-xs"
                        />
                        <Button
                          size="icon"
                          variant={hasChanges ? 'default' : 'outline'}
                          onClick={() => handleSave(config)}
                          disabled={!hasChanges || isSaving}
                        >
                          {isSaving ? (
                            <RefreshCw className="h-4 w-4 animate-spin" />
                          ) : isSaved ? (
                            <Check className="h-4 w-4 text-green-400" />
                          ) : (
                            <Save className="h-4 w-4" />
                          )}
                        </Button>
                      </div>
                    </div>
                  )
                })}
              </CardContent>
            </Card>
          </TabsContent>
        ))}
      </Tabs>
    </>
  )
}
