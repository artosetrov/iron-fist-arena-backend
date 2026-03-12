'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { updateBalanceConfig } from '@/actions/item-balance'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Save, Check } from 'lucide-react'

interface ConfigEntry {
  key: string
  value: unknown
  description: string | null
}

const TABS = [
  { id: 'power', label: 'Power Scores', keys: ['power_stat_weights', 'power_upgrade_multiplier', 'power_rarity_multipliers'] },
  { id: 'stats', label: 'Stat Ranges', keys: ['stat_ranges', 'rarity_multipliers'] },
  { id: 'scaling', label: 'Level Scaling', keys: ['level_scaling_formula', 'level_scaling_base', 'level_scaling_exponent', 'level_variance'] },
  { id: 'economy', label: 'Economy', keys: ['sell_price_by_rarity', 'buy_price_multiplier', 'power_to_price_ratio'] },
  { id: 'upgrades', label: 'Upgrades', keys: ['upgrade_stat_bonus_per_level', 'upgrade_cost_formula', 'upgrade_cost_base', 'upgrade_cost_exponent', 'upgrade_failure_downgrade_threshold', 'upgrade_protection_gem_cost'] },
  { id: 'combat', label: 'Combat Formulas', keys: ['hp_base', 'hp_per_vit', 'hp_per_end', 'armor_per_end', 'armor_per_str', 'mr_per_wis', 'mr_per_int', 'class_damage_scaling'] },
  { id: 'drops', label: 'Drop Tuning', keys: ['luk_drop_bonus_per_point', 'drop_chance_cap', 'level_rarity_bonus_per_level', 'level_rarity_bonus_distribution'] },
  { id: 'validation', label: 'Validation', keys: ['validation_power_deviation_threshold', 'validation_stat_cap_multiplier'] },
]

function getTabForKey(key: string): string {
  const shortKey = key.replace('item_balance.', '')
  for (const tab of TABS) {
    if (tab.keys.some((k) => shortKey.startsWith(k))) return tab.id
  }
  return 'power'
}

function formatLabel(key: string): string {
  return key
    .replace('item_balance.', '')
    .split('_')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ')
}

export function ConfigEditorClient({
  configs,
  adminId,
}: {
  configs: ConfigEntry[]
  adminId: string
}) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [editValues, setEditValues] = useState<Record<string, string>>(
    Object.fromEntries(
      configs.map((c) => [
        c.key,
        typeof c.value === 'object' ? JSON.stringify(c.value, null, 2) : String(c.value),
      ])
    )
  )
  const [savedKeys, setSavedKeys] = useState<Set<string>>(new Set())
  const [message, setMessage] = useState('')

  function isJsonValue(key: string): boolean {
    const config = configs.find((c) => c.key === key)
    return config ? typeof config.value === 'object' : false
  }

  async function saveConfig(key: string) {
    const rawValue = editValues[key]
    let parsedValue: unknown

    if (isJsonValue(key)) {
      try {
        parsedValue = JSON.parse(rawValue)
      } catch {
        setMessage(`Invalid JSON for ${key}`)
        return
      }
    } else {
      const num = Number(rawValue)
      parsedValue = isNaN(num) ? rawValue : num
    }

    try {
      await updateBalanceConfig(key, parsedValue, adminId)
      setSavedKeys((prev) => new Set([...prev, key]))
      setTimeout(() => setSavedKeys((prev) => {
        const next = new Set(prev)
        next.delete(key)
        return next
      }), 2000)
      setMessage('')
      startTransition(() => router.refresh())
    } catch (err) {
      setMessage(`Failed to save ${key}`)
    }
  }

  // Group configs by tab
  const grouped: Record<string, ConfigEntry[]> = {}
  for (const tab of TABS) {
    grouped[tab.id] = []
  }
  for (const config of configs) {
    const tabId = getTabForKey(config.key)
    if (grouped[tabId]) grouped[tabId].push(config)
  }

  return (
    <div className="space-y-4">
      {message && (
        <div className="bg-red-500/10 text-red-600 rounded-md p-3 text-sm">{message}</div>
      )}

      <Tabs defaultValue="power" className="space-y-4">
        <TabsList className="flex-wrap h-auto gap-1">
          {TABS.map((tab) => (
            <TabsTrigger key={tab.id} value={tab.id} className="text-xs">
              {tab.label}
              {grouped[tab.id]?.length > 0 && (
                <span className="ml-1 text-muted-foreground">({grouped[tab.id].length})</span>
              )}
            </TabsTrigger>
          ))}
        </TabsList>

        {TABS.map((tab) => (
          <TabsContent key={tab.id} value={tab.id} className="space-y-4">
            {grouped[tab.id]?.map((config) => (
              <Card key={config.key}>
                <CardHeader className="pb-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle className="text-sm font-mono">{config.key}</CardTitle>
                      {config.description && (
                        <CardDescription className="text-xs">{config.description}</CardDescription>
                      )}
                    </div>
                    <Button
                      size="sm"
                      variant={savedKeys.has(config.key) ? 'default' : 'outline'}
                      onClick={() => saveConfig(config.key)}
                      disabled={isPending}
                    >
                      {savedKeys.has(config.key) ? (
                        <><Check className="h-3 w-3 mr-1" /> Saved</>
                      ) : (
                        <><Save className="h-3 w-3 mr-1" /> Save</>
                      )}
                    </Button>
                  </div>
                </CardHeader>
                <CardContent>
                  {isJsonValue(config.key) ? (
                    <textarea
                      className="w-full font-mono text-xs bg-muted rounded-md p-3 min-h-[100px] border"
                      value={editValues[config.key] ?? ''}
                      onChange={(e) =>
                        setEditValues((prev) => ({ ...prev, [config.key]: e.target.value }))
                      }
                    />
                  ) : (
                    <Input
                      value={editValues[config.key] ?? ''}
                      onChange={(e) =>
                        setEditValues((prev) => ({ ...prev, [config.key]: e.target.value }))
                      }
                      className="font-mono text-sm"
                    />
                  )}
                </CardContent>
              </Card>
            ))}
            {(!grouped[tab.id] || grouped[tab.id].length === 0) && (
              <div className="text-center py-8 text-muted-foreground">
                No config values in this category. Run the balance seed script first.
              </div>
            )}
          </TabsContent>
        ))}
      </Tabs>
    </div>
  )
}
