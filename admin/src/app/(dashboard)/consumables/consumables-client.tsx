'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { updateConfig } from '@/actions/config'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { Save, FlaskConical, Heart, Zap, Coins, AlertTriangle } from 'lucide-react'

type ConsumableItem = {
  id: string
  catalogId: string
  itemName: string
  itemType: string
  rarity: string
  itemLevel: number
  buyPrice: number
  sellPrice: number
  specialEffect: string | null
  description: string | null
  imageUrl: string | null
}

type ConfigEntry = {
  key: string
  value: unknown
  description: string | null
}

// Hardcoded backend defaults — shown as reference if no GameConfig override exists
const BACKEND_DEFAULTS = {
  prices: {
    stamina_potion_small: 100,
    stamina_potion_medium: 250,
    stamina_potion_large: 500,
    health_potion_small: 150,
    health_potion_medium: 350,
    health_potion_large: 700,
  } as Record<string, number>,
  stamina_restore: {
    stamina_potion_small: 30,
    stamina_potion_medium: 60,
    stamina_potion_large: 999,
  } as Record<string, number>,
  hp_restore_percent: {
    health_potion_small: 25,
    health_potion_medium: 50,
    health_potion_large: 100,
  } as Record<string, number>,
}

const CONSUMABLE_LABELS: Record<string, string> = {
  stamina_potion_small: 'Small Stamina Potion',
  stamina_potion_medium: 'Medium Stamina Potion',
  stamina_potion_large: 'Large Stamina Potion',
  health_potion_small: 'Small Health Potion',
  health_potion_medium: 'Medium Health Potion',
  health_potion_large: 'Large Health Potion',
}

const RARITY_COLORS: Record<string, string> = {
  common: 'bg-zinc-600/20 text-zinc-400 border-zinc-600',
  uncommon: 'bg-green-600/20 text-green-400 border-green-600',
  rare: 'bg-blue-600/20 text-blue-400 border-blue-600',
}

export function ConsumablesClient({
  items,
  configs,
}: {
  items: ConsumableItem[]
  configs: ConfigEntry[]
}) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')

  // Build config map
  const configMap = new Map(configs.map((c) => [c.key, c.value]))

  // State for editable values
  const [prices, setPrices] = useState<Record<string, number>>(() => {
    const p: Record<string, number> = {}
    for (const key of Object.keys(BACKEND_DEFAULTS.prices)) {
      const cfgKey = `consumable.price.${key}`
      p[key] = (configMap.get(cfgKey) as number) ?? BACKEND_DEFAULTS.prices[key]
    }
    return p
  })

  const [staminaRestore, setStaminaRestore] = useState<Record<string, number>>(() => {
    const s: Record<string, number> = {}
    for (const key of Object.keys(BACKEND_DEFAULTS.stamina_restore)) {
      const cfgKey = `consumable.stamina_restore.${key}`
      s[key] = (configMap.get(cfgKey) as number) ?? BACKEND_DEFAULTS.stamina_restore[key]
    }
    return s
  })

  const [hpRestore, setHpRestore] = useState<Record<string, number>>(() => {
    const h: Record<string, number> = {}
    for (const key of Object.keys(BACKEND_DEFAULTS.hp_restore_percent)) {
      const cfgKey = `consumable.hp_restore_percent.${key}`
      h[key] = (configMap.get(cfgKey) as number) ?? BACKEND_DEFAULTS.hp_restore_percent[key]
    }
    return h
  })

  async function handleSaveAll() {
    setError('')
    setMessage('')
    startTransition(async () => {
      try {
        const updates: { key: string; value: number }[] = []

        for (const [consumableKey, price] of Object.entries(prices)) {
          updates.push({ key: `consumable.price.${consumableKey}`, value: price })
        }
        for (const [consumableKey, amount] of Object.entries(staminaRestore)) {
          updates.push({ key: `consumable.stamina_restore.${consumableKey}`, value: amount })
        }
        for (const [consumableKey, percent] of Object.entries(hpRestore)) {
          updates.push({ key: `consumable.hp_restore_percent.${consumableKey}`, value: percent })
        }

        for (const u of updates) {
          await updateConfig(u.key, u.value)
        }

        setMessage('All consumable configs saved successfully.')
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save')
      }
    })
  }

  const staminaPotions = items.filter((i) => i.catalogId.startsWith('stamina_potion'))
  const healthPotions = items.filter((i) => i.catalogId.startsWith('health_potion'))

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

      <div className="rounded-md bg-amber-600/10 border border-amber-600/30 px-4 py-3 text-sm text-amber-400 flex items-start gap-2">
        <AlertTriangle className="h-4 w-4 shrink-0 mt-0.5" />
        <div>
          <strong>Note:</strong> The backend currently reads consumable prices and effects from hardcoded constants.
          Save values here to GameConfig — then update the backend routes to read from GameConfig for these to take effect.
        </div>
      </div>

      {/* Consumable Items in Catalog */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FlaskConical className="h-5 w-5" />
            Consumable Catalog Items
          </CardTitle>
          <CardDescription>
            Items with type &quot;consumable&quot; from the Items catalog. Edit them in the Items section.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Name</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Catalog ID</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Rarity</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Effect</th>
                  <th className="px-4 py-3 text-right font-medium text-muted-foreground">Buy Price</th>
                  <th className="px-4 py-3 text-right font-medium text-muted-foreground">Sell Price</th>
                </tr>
              </thead>
              <tbody>
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-4 py-8 text-center text-muted-foreground">
                      No consumable items found in catalog. Create them in the Items section.
                    </td>
                  </tr>
                ) : (
                  items.map((item) => (
                    <tr key={item.id} className="border-b border-border hover:bg-muted/30">
                      <td className="px-4 py-3 font-medium">{item.itemName}</td>
                      <td className="px-4 py-3 font-mono text-xs text-muted-foreground">{item.catalogId}</td>
                      <td className="px-4 py-3">
                        <Badge className={RARITY_COLORS[item.rarity] ?? ''}>{item.rarity}</Badge>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">{item.specialEffect ?? '—'}</td>
                      <td className="px-4 py-3 text-right">{item.buyPrice.toLocaleString()}g</td>
                      <td className="px-4 py-3 text-right">{item.sellPrice.toLocaleString()}g</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Stamina Potions Config */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap className="h-5 w-5 text-yellow-400" />
            Stamina Potions
          </CardTitle>
          <CardDescription>Configure prices and stamina restore amounts. 999 = full restore.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Potion</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">
                    <div className="flex items-center gap-1"><Coins className="h-3 w-3" /> Buy Price (gold)</div>
                  </th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">
                    <div className="flex items-center gap-1"><Zap className="h-3 w-3" /> Stamina Restore</div>
                  </th>
                </tr>
              </thead>
              <tbody>
                {Object.keys(BACKEND_DEFAULTS.stamina_restore).map((key) => (
                  <tr key={key} className="border-b border-border">
                    <td className="px-4 py-3 font-medium">{CONSUMABLE_LABELS[key]}</td>
                    <td className="px-4 py-3">
                      <Input
                        type="number"
                        min={0}
                        value={prices[key] ?? 0}
                        onChange={(e) => setPrices((p) => ({ ...p, [key]: Number(e.target.value) }))}
                        className="w-28 font-mono text-xs"
                      />
                    </td>
                    <td className="px-4 py-3">
                      <Input
                        type="number"
                        min={0}
                        value={staminaRestore[key] ?? 0}
                        onChange={(e) => setStaminaRestore((s) => ({ ...s, [key]: Number(e.target.value) }))}
                        className="w-28 font-mono text-xs"
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Health Potions Config */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Heart className="h-5 w-5 text-red-400" />
            Health Potions
          </CardTitle>
          <CardDescription>Configure prices and HP restore percentage. 100 = full restore.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Potion</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">
                    <div className="flex items-center gap-1"><Coins className="h-3 w-3" /> Buy Price (gold)</div>
                  </th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">
                    <div className="flex items-center gap-1"><Heart className="h-3 w-3" /> HP Restore (%)</div>
                  </th>
                </tr>
              </thead>
              <tbody>
                {Object.keys(BACKEND_DEFAULTS.hp_restore_percent).map((key) => (
                  <tr key={key} className="border-b border-border">
                    <td className="px-4 py-3 font-medium">{CONSUMABLE_LABELS[key]}</td>
                    <td className="px-4 py-3">
                      <Input
                        type="number"
                        min={0}
                        value={prices[key] ?? 0}
                        onChange={(e) => setPrices((p) => ({ ...p, [key]: Number(e.target.value) }))}
                        className="w-28 font-mono text-xs"
                      />
                    </td>
                    <td className="px-4 py-3">
                      <Input
                        type="number"
                        min={0}
                        max={100}
                        value={hpRestore[key] ?? 0}
                        onChange={(e) => setHpRestore((h) => ({ ...h, [key]: Number(e.target.value) }))}
                        className="w-28 font-mono text-xs"
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      <Separator />

      <div className="flex justify-end">
        <Button onClick={handleSaveAll} disabled={isPending} size="lg">
          <Save className="mr-2 h-4 w-4" />
          {isPending ? 'Saving...' : 'Save All Consumable Config'}
        </Button>
      </div>
    </div>
  )
}
