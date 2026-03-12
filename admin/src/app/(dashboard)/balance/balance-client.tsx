'use client'

import { useState, useTransition, useMemo, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { batchUpdateBalanceConfigs } from '@/actions/balance'
import { updateConfig, seedDefaultConfigs } from '@/actions/config'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  Save, RefreshCw, Check, RotateCcw, Database,
  Swords, Coins, TrendingUp, Settings2, AlertTriangle,
  X,
} from 'lucide-react'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type ConfigItem = {
  key: string
  value: unknown
  category: string
  description: string | null
  updatedAt: string
  updatedBy: string | null
}

type FieldDef = {
  key: string
  label: string
  description: string
  defaultValue: number
  unit?: string
  step?: number
  min?: number
  max?: number
}

type SectionDef = {
  id: string
  title: string
  description?: string
  fields: FieldDef[]
}

type TabDef = {
  id: string
  label: string
  icon: React.ReactNode
  sections: SectionDef[]
}

// ---------------------------------------------------------------------------
// Balance Schema — defines all fields, defaults, and organization
// ---------------------------------------------------------------------------

const BALANCE_TABS: TabDef[] = [
  {
    id: 'combat',
    label: 'Combat',
    icon: <Swords className="h-4 w-4" />,
    sections: [
      {
        id: 'combat_core',
        title: 'Core Mechanics',
        description: 'Fundamental combat parameters',
        fields: [
          { key: 'combat.max_turns', label: 'Max Turns', description: 'Maximum turns per combat encounter', defaultValue: 15, step: 1, min: 5 },
          { key: 'combat.min_damage', label: 'Min Damage', description: 'Minimum damage dealt per attack', defaultValue: 1, step: 1, min: 0 },
          { key: 'combat.crit_multiplier', label: 'Crit Multiplier', description: 'Critical hit damage multiplier', defaultValue: 1.5, unit: 'x', step: 0.1, min: 1 },
          { key: 'combat.damage_variance', label: 'Damage Variance', description: 'Damage variance range (e.g. 0.10 = \u00b110%)', defaultValue: 0.10, unit: '\u00b1%', step: 0.01, min: 0, max: 1 },
          { key: 'combat.tank_damage_reduction', label: 'Tank DR Multiplier', description: 'Tank damage multiplier (0.85 = 15% reduction)', defaultValue: 0.85, unit: 'x', step: 0.01, min: 0, max: 1 },
        ],
      },
      {
        id: 'combat_crit',
        title: 'Critical Hit Formula',
        description: 'Crit chance = LUK \u00d7 CritPerLuk + AGI \u00d7 CritPerAgi',
        fields: [
          { key: 'combat.crit_per_luk', label: 'Crit per LUK', description: 'Crit chance % gained per LUK point', defaultValue: 0.7, unit: '%/pt', step: 0.05, min: 0 },
          { key: 'combat.crit_per_agi', label: 'Crit per AGI', description: 'Crit chance % gained per AGI point', defaultValue: 0.15, unit: '%/pt', step: 0.05, min: 0 },
          { key: 'combat.max_crit_chance', label: 'Max Crit Chance', description: 'Hard cap on critical hit chance', defaultValue: 50, unit: '%', step: 1, min: 0, max: 100 },
        ],
      },
      {
        id: 'combat_dodge',
        title: 'Dodge Formula',
        description: 'Dodge chance = AGI \u00d7 DodgePerAgi + LUK \u00d7 DodgePerLuk',
        fields: [
          { key: 'combat.dodge_per_agi', label: 'Dodge per AGI', description: 'Dodge chance % gained per AGI point', defaultValue: 0.2, unit: '%/pt', step: 0.05, min: 0 },
          { key: 'combat.dodge_per_luk', label: 'Dodge per LUK', description: 'Dodge chance % gained per LUK point', defaultValue: 0.1, unit: '%/pt', step: 0.05, min: 0 },
          { key: 'combat.max_dodge_chance', label: 'Max Dodge Chance', description: 'Hard cap on dodge chance', defaultValue: 30, unit: '%', step: 1, min: 0, max: 100 },
          { key: 'combat.rogue_dodge_bonus', label: 'Rogue Dodge Bonus', description: 'Extra dodge % for rogue class', defaultValue: 3, unit: '%', step: 1, min: 0 },
        ],
      },
      {
        id: 'combat_special',
        title: 'Special Mechanics',
        description: 'CHA intimidation and poison mechanics',
        fields: [
          { key: 'combat.cha_intimidation_per_point', label: 'CHA Intimidation/pt', description: 'Damage reduction % per defender CHA point', defaultValue: 0.15, unit: '%/pt', step: 0.01, min: 0 },
          { key: 'combat.cha_intimidation_cap', label: 'CHA Intimidation Cap', description: 'Maximum damage reduction from CHA intimidation', defaultValue: 15, unit: '%', step: 1, min: 0, max: 100 },
          { key: 'combat.poison_armor_penetration', label: 'Poison Armor Pen', description: 'Fraction of armor ignored by poison damage', defaultValue: 0.3, step: 0.05, min: 0, max: 1 },
        ],
      },
    ],
  },
  {
    id: 'rewards',
    label: 'Rewards & Economy',
    icon: <Coins className="h-4 w-4" />,
    sections: [
      {
        id: 'gold_rewards',
        title: 'Gold Rewards',
        description: 'Base gold earned from various activities',
        fields: [
          { key: 'gold_rewards.pvp_win_base', label: 'PvP Win', description: 'Base gold reward for PvP win', defaultValue: 150, unit: 'gold', step: 10 },
          { key: 'gold_rewards.pvp_loss_base', label: 'PvP Loss', description: 'Base gold reward for PvP loss', defaultValue: 50, unit: 'gold', step: 5 },
          { key: 'gold_rewards.training_win', label: 'Training Win', description: 'Gold reward for training win', defaultValue: 50, unit: 'gold', step: 5 },
          { key: 'gold_rewards.training_loss', label: 'Training Loss', description: 'Gold reward for training loss', defaultValue: 20, unit: 'gold', step: 5 },
          { key: 'gold_rewards.revenge_multiplier', label: 'Revenge Multiplier', description: 'Gold multiplier for revenge matches', defaultValue: 1.5, unit: 'x', step: 0.1, min: 1 },
        ],
      },
      {
        id: 'xp_rewards',
        title: 'XP Rewards',
        description: 'Experience points earned from activities',
        fields: [
          { key: 'xp_rewards.pvp_win_xp', label: 'PvP Win XP', description: 'XP reward for PvP win', defaultValue: 120, unit: 'xp', step: 10 },
          { key: 'xp_rewards.pvp_loss_xp', label: 'PvP Loss XP', description: 'XP reward for PvP loss', defaultValue: 40, unit: 'xp', step: 5 },
          { key: 'xp_rewards.training_win_xp', label: 'Training Win XP', description: 'XP reward for training win', defaultValue: 60, unit: 'xp', step: 5 },
          { key: 'xp_rewards.training_loss_xp', label: 'Training Loss XP', description: 'XP reward for training loss', defaultValue: 20, unit: 'xp', step: 5 },
        ],
      },
      {
        id: 'first_win_bonus',
        title: 'First Win of the Day',
        description: 'Bonus multipliers for the first daily win',
        fields: [
          { key: 'first_win_bonus.gold_mult', label: 'Gold Multiplier', description: 'Gold multiplier for first win', defaultValue: 2, unit: 'x', step: 0.5, min: 1 },
          { key: 'first_win_bonus.xp_mult', label: 'XP Multiplier', description: 'XP multiplier for first win', defaultValue: 2, unit: 'x', step: 0.5, min: 1 },
        ],
      },
      {
        id: 'win_streak',
        title: 'Win Streak Bonuses',
        description: 'Gold bonus multipliers based on consecutive wins',
        fields: [
          { key: 'win_streak.3_bonus', label: '3-Win Streak', description: 'Gold bonus at 3 consecutive wins', defaultValue: 0.2, unit: '+%', step: 0.05, min: 0 },
          { key: 'win_streak.5_bonus', label: '5-Win Streak', description: 'Gold bonus at 5 consecutive wins', defaultValue: 0.5, unit: '+%', step: 0.05, min: 0 },
          { key: 'win_streak.8_bonus', label: '8+ Win Streak', description: 'Gold bonus at 8+ consecutive wins', defaultValue: 1.0, unit: '+%', step: 0.1, min: 0 },
        ],
      },
      {
        id: 'drop_chances',
        title: 'Item Drop Chances',
        description: 'Probability of receiving an item drop',
        fields: [
          { key: 'drop_chances.pvp', label: 'PvP Match', description: 'Drop chance from PvP matches', defaultValue: 0.15, step: 0.01, min: 0, max: 1 },
          { key: 'drop_chances.training', label: 'Training', description: 'Drop chance from training', defaultValue: 0.05, step: 0.01, min: 0, max: 1 },
          { key: 'drop_chances.dungeon_easy', label: 'Dungeon (Easy)', description: 'Drop chance from easy dungeons', defaultValue: 0.20, step: 0.01, min: 0, max: 1 },
          { key: 'drop_chances.dungeon_normal', label: 'Dungeon (Normal)', description: 'Drop chance from normal dungeons', defaultValue: 0.30, step: 0.01, min: 0, max: 1 },
          { key: 'drop_chances.dungeon_hard', label: 'Dungeon (Hard)', description: 'Drop chance from hard dungeons', defaultValue: 0.40, step: 0.01, min: 0, max: 1 },
          { key: 'drop_chances.boss', label: 'Boss Fight', description: 'Drop chance from boss fights', defaultValue: 0.75, step: 0.01, min: 0, max: 1 },
        ],
      },
      {
        id: 'rarity_distribution',
        title: 'Rarity Distribution',
        description: 'Drop weight by item rarity (should sum to 100%)',
        fields: [
          { key: 'rarity_distribution.common', label: 'Common', description: 'Common item drop weight', defaultValue: 50, unit: '%', step: 1, min: 0, max: 100 },
          { key: 'rarity_distribution.uncommon', label: 'Uncommon', description: 'Uncommon item drop weight', defaultValue: 30, unit: '%', step: 1, min: 0, max: 100 },
          { key: 'rarity_distribution.rare', label: 'Rare', description: 'Rare item drop weight', defaultValue: 15, unit: '%', step: 1, min: 0, max: 100 },
          { key: 'rarity_distribution.epic', label: 'Epic', description: 'Epic item drop weight', defaultValue: 4, unit: '%', step: 1, min: 0, max: 100 },
          { key: 'rarity_distribution.legendary', label: 'Legendary', description: 'Legendary item drop weight', defaultValue: 1, unit: '%', step: 1, min: 0, max: 100 },
        ],
      },
    ],
  },
  {
    id: 'progression',
    label: 'Progression',
    icon: <TrendingUp className="h-4 w-4" />,
    sections: [
      {
        id: 'stamina',
        title: 'Stamina',
        description: 'Energy system that gates activity frequency',
        fields: [
          { key: 'stamina.max', label: 'Max Stamina', description: 'Maximum stamina capacity', defaultValue: 120, unit: 'pts', step: 5, min: 1 },
          { key: 'stamina.regen_rate', label: 'Regen Rate', description: 'Stamina points regenerated per tick', defaultValue: 1, unit: 'pts', step: 1, min: 1 },
          { key: 'stamina.regen_interval_minutes', label: 'Regen Interval', description: 'Minutes between stamina regeneration ticks', defaultValue: 8, unit: 'min', step: 1, min: 1 },
          { key: 'stamina.pvp_cost', label: 'PvP Cost', description: 'Stamina cost per PvP match', defaultValue: 10, unit: 'pts', step: 1, min: 0 },
          { key: 'stamina.dungeon_easy', label: 'Dungeon Easy', description: 'Stamina cost for easy dungeon', defaultValue: 15, unit: 'pts', step: 1, min: 0 },
          { key: 'stamina.dungeon_normal', label: 'Dungeon Normal', description: 'Stamina cost for normal dungeon', defaultValue: 20, unit: 'pts', step: 1, min: 0 },
          { key: 'stamina.dungeon_hard', label: 'Dungeon Hard', description: 'Stamina cost for hard dungeon', defaultValue: 25, unit: 'pts', step: 1, min: 0 },
          { key: 'stamina.boss', label: 'Boss Fight', description: 'Stamina cost for boss fight', defaultValue: 40, unit: 'pts', step: 1, min: 0 },
          { key: 'stamina.training', label: 'Training', description: 'Stamina cost per training session', defaultValue: 5, unit: 'pts', step: 1, min: 0 },
          { key: 'stamina.free_pvp_per_day', label: 'Free PvP/Day', description: 'Free PvP matches per day (no stamina cost)', defaultValue: 3, step: 1, min: 0 },
        ],
      },
      {
        id: 'elo',
        title: 'ELO Rating',
        description: 'PvP matchmaking rating system parameters',
        fields: [
          { key: 'elo.k_calibration', label: 'K-Factor (Calibration)', description: 'K-factor for first N calibration matches (higher = more volatile)', defaultValue: 48, step: 1, min: 1 },
          { key: 'elo.k_default', label: 'K-Factor (Default)', description: 'K-factor for regular matches', defaultValue: 32, step: 1, min: 1 },
          { key: 'elo.calibration_games', label: 'Calibration Games', description: 'Number of games before stable rating', defaultValue: 10, step: 1, min: 1 },
          { key: 'elo.min_rating', label: 'Min Rating', description: 'Minimum possible ELO rating (floor)', defaultValue: 0, step: 50, min: 0 },
        ],
      },
      {
        id: 'prestige',
        title: 'Prestige System',
        description: 'Character progression and prestige mechanics',
        fields: [
          { key: 'prestige.max_level', label: 'Max Level', description: 'Maximum character level before prestige', defaultValue: 50, step: 1, min: 1 },
          { key: 'prestige.stat_bonus_per_prestige', label: 'Stat Bonus/Prestige', description: 'Stat bonus per prestige level (0.05 = 5%)', defaultValue: 0.05, unit: 'x', step: 0.01, min: 0 },
          { key: 'prestige.stat_points_per_level', label: 'Stat Pts/Level', description: 'Stat points awarded per level up', defaultValue: 3, unit: 'pts', step: 1, min: 1 },
        ],
      },
    ],
  },
  {
    id: 'systems',
    label: 'Systems',
    icon: <Settings2 className="h-4 w-4" />,
    sections: [
      {
        id: 'battle_pass',
        title: 'Battle Pass',
        description: 'XP earned toward the seasonal battle pass',
        fields: [
          { key: 'battle_pass.bp_xp_per_pvp', label: 'XP per PvP', description: 'Battle Pass XP earned per PvP match', defaultValue: 20, unit: 'bp xp', step: 5, min: 0 },
          { key: 'battle_pass.bp_xp_per_dungeon_floor', label: 'XP per Dungeon Floor', description: 'Battle Pass XP per dungeon floor cleared', defaultValue: 30, unit: 'bp xp', step: 5, min: 0 },
          { key: 'battle_pass.bp_xp_per_quest', label: 'XP per Quest', description: 'Battle Pass XP per daily quest completed', defaultValue: 50, unit: 'bp xp', step: 5, min: 0 },
          { key: 'battle_pass.bp_xp_per_achievement', label: 'XP per Achievement', description: 'Battle Pass XP per achievement completed', defaultValue: 100, unit: 'bp xp', step: 10, min: 0 },
        ],
      },
      {
        id: 'matchmaking',
        title: 'Matchmaking',
        description: 'Opponent selection parameters',
        fields: [
          { key: 'matchmaking.level_range', label: 'Level Range', description: 'Level range for opponent matching (\u00b1)', defaultValue: 3, unit: '\u00b1 lvl', step: 1, min: 1 },
          { key: 'matchmaking.gear_score_tolerance', label: 'Gear Score Tolerance', description: 'Gear score tolerance range (0.3 = \u00b130%)', defaultValue: 0.3, unit: '\u00b1%', step: 0.05, min: 0, max: 1 },
        ],
      },
      {
        id: 'gem_costs',
        title: 'Gem Costs',
        description: 'Premium currency costs for various actions',
        fields: [
          { key: 'gem_costs.stamina_refill', label: 'Stamina Refill', description: 'Gems to fully refill stamina', defaultValue: 30, unit: 'gems', step: 5, min: 0 },
          { key: 'gem_costs.extra_pvp_combat', label: 'Extra PvP Combat', description: 'Gems for extra PvP when out of stamina', defaultValue: 50, unit: 'gems', step: 5, min: 0 },
          { key: 'gem_costs.battle_pass_premium', label: 'Battle Pass Premium', description: 'Gems to unlock premium battle pass', defaultValue: 500, unit: 'gems', step: 50, min: 0 },
          { key: 'gem_costs.gold_mine_buy_slot', label: 'Gold Mine Slot', description: 'Gems to buy additional gold mine slot', defaultValue: 50, unit: 'gems', step: 5, min: 0 },
          { key: 'gem_costs.gold_mine_boost', label: 'Gold Mine Boost', description: 'Gems to boost gold mine (2x reward)', defaultValue: 10, unit: 'gems', step: 1, min: 0 },
        ],
      },
      {
        id: 'skills',
        title: 'Active Skills',
        description: 'Active skill system configuration',
        fields: [
          { key: 'skills.max_equipped_slots', label: 'Max Equipped', description: 'Maximum equipped skill slots', defaultValue: 4, step: 1, min: 1, max: 8 },
          { key: 'skills.upgrade_gold_base', label: 'Upgrade Base Cost', description: 'Base gold cost to upgrade a skill', defaultValue: 500, unit: 'gold', step: 50, min: 0 },
          { key: 'skills.upgrade_gold_per_rank', label: 'Upgrade Cost/Rank', description: 'Additional gold per rank for skill upgrade', defaultValue: 500, unit: 'gold', step: 50, min: 0 },
          { key: 'skills.learn_gold_cost', label: 'Learn Cost', description: 'Gold cost to learn a new skill', defaultValue: 200, unit: 'gold', step: 25, min: 0 },
        ],
      },
      {
        id: 'passives',
        title: 'Passive Tree',
        description: 'Passive skill tree configuration',
        fields: [
          { key: 'passives.points_per_level', label: 'Points per Level', description: 'Passive points gained per level up', defaultValue: 1, unit: 'pts', step: 1, min: 0 },
          { key: 'passives.max_passive_points', label: 'Max Points', description: 'Maximum total passive points', defaultValue: 50, unit: 'pts', step: 5, min: 0 },
          { key: 'passives.respec_gem_cost', label: 'Respec Cost', description: 'Gems to reset passive tree', defaultValue: 50, unit: 'gems', step: 5, min: 0 },
        ],
      },
      {
        id: 'inventory',
        title: 'Inventory',
        description: 'Inventory capacity and expansion',
        fields: [
          { key: 'inventory.max_slots', label: 'Max Slots (Hard Cap)', description: 'Absolute maximum inventory slots', defaultValue: 100, step: 10, min: 1 },
          { key: 'inventory.base_slots', label: 'Base Slots', description: 'Starting inventory slots', defaultValue: 28, step: 1, min: 1 },
          { key: 'inventory.expand_amount', label: 'Expand Amount', description: 'Slots added per expansion', defaultValue: 10, step: 1, min: 1 },
          { key: 'inventory.expand_cost_gold', label: 'Expand Cost', description: 'Gold cost per inventory expansion', defaultValue: 5000, unit: 'gold', step: 500, min: 0 },
          { key: 'inventory.max_expansions', label: 'Max Expansions', description: 'Maximum number of inventory expansions', defaultValue: 3, step: 1, min: 0 },
        ],
      },
      {
        id: 'hp_regen',
        title: 'HP Regeneration',
        description: 'Out-of-combat health regeneration',
        fields: [
          { key: 'hp_regen.regen_rate', label: 'Regen Rate', description: '% of maxHP regenerated per tick', defaultValue: 1, unit: '%', step: 0.5, min: 0 },
          { key: 'hp_regen.regen_interval_minutes', label: 'Regen Interval', description: 'Minutes between HP regen ticks', defaultValue: 5, unit: 'min', step: 1, min: 1 },
        ],
      },
    ],
  },
]

// Upgrade chances special field (array stored as single config key)
const UPGRADE_KEY = 'upgrade_chances'
const UPGRADE_DEFAULTS = [100, 100, 100, 100, 100, 80, 60, 40, 25, 15]

// Build a flat map of all field defaults
const ALL_DEFAULTS = new Map<string, number>()
for (const tab of BALANCE_TABS) {
  for (const section of tab.sections) {
    for (const field of section.fields) {
      ALL_DEFAULTS.set(field.key, field.defaultValue)
    }
  }
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function BalanceClient({
  configs,
  adminId,
}: {
  configs: ConfigItem[]
  adminId: string
}) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [editedValues, setEditedValues] = useState<Record<string, string>>({})
  const [editedUpgrades, setEditedUpgrades] = useState<number[] | null>(null)
  const [savedKeys, setSavedKeys] = useState<Set<string>>(new Set())
  const [error, setError] = useState('')
  const [successMsg, setSuccessMsg] = useState('')
  const [seedMessage, setSeedMessage] = useState('')

  // Map config entries by key for fast lookup
  const configMap = useMemo(() => {
    const m = new Map<string, ConfigItem>()
    for (const c of configs) m.set(c.key, c)
    return m
  }, [configs])

  // Count unsaved changes
  const changeCount = Object.keys(editedValues).length + (editedUpgrades ? 1 : 0)

  // Get current value for a field (edited > db > default)
  const getValue = useCallback(
    (key: string, defaultValue: number): string => {
      if (editedValues[key] !== undefined) return editedValues[key]
      const dbConfig = configMap.get(key)
      if (dbConfig !== undefined) return String(dbConfig.value)
      return String(defaultValue)
    },
    [editedValues, configMap]
  )

  // Get upgrade chances array (edited > db > default)
  const getUpgradeChances = useCallback((): number[] => {
    if (editedUpgrades) return editedUpgrades
    const dbConfig = configMap.get(UPGRADE_KEY)
    if (dbConfig && Array.isArray(dbConfig.value)) return dbConfig.value as number[]
    return [...UPGRADE_DEFAULTS]
  }, [editedUpgrades, configMap])

  // Check if a value differs from its default
  function isModified(key: string, defaultValue: number): boolean {
    const dbConfig = configMap.get(key)
    if (!dbConfig) return false
    return Number(dbConfig.value) !== defaultValue
  }

  function handleChange(key: string, value: string) {
    setEditedValues((prev) => ({ ...prev, [key]: value }))
    setSavedKeys((prev) => {
      const next = new Set(prev)
      next.delete(key)
      return next
    })
    setSuccessMsg('')
  }

  function handleUpgradeChange(index: number, value: number) {
    const current = getUpgradeChances()
    const updated = [...current]
    updated[index] = value
    setEditedUpgrades(updated)
    setSavedKeys((prev) => {
      const next = new Set(prev)
      next.delete(UPGRADE_KEY)
      return next
    })
    setSuccessMsg('')
  }

  function handleResetField(key: string, defaultValue: number) {
    setEditedValues((prev) => ({ ...prev, [key]: String(defaultValue) }))
    setSuccessMsg('')
  }

  // Save a single field
  async function handleSaveSingle(key: string) {
    const rawValue = editedValues[key]
    if (rawValue === undefined) return

    let parsedValue: unknown
    try {
      parsedValue = JSON.parse(rawValue)
    } catch {
      parsedValue = isNaN(Number(rawValue)) ? rawValue : Number(rawValue)
    }

    setError('')
    startTransition(async () => {
      try {
        await updateConfig(key, parsedValue, adminId)
        setSavedKeys((prev) => new Set(prev).add(key))
        setEditedValues((prev) => {
          const next = { ...prev }
          delete next[key]
          return next
        })
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save')
      }
    })
  }

  // Save all pending changes at once
  async function handleSaveAll() {
    const updates: { key: string; value: unknown }[] = []

    for (const [key, rawValue] of Object.entries(editedValues)) {
      let parsedValue: unknown
      try {
        parsedValue = JSON.parse(rawValue)
      } catch {
        parsedValue = isNaN(Number(rawValue)) ? rawValue : Number(rawValue)
      }
      updates.push({ key, value: parsedValue })
    }

    if (editedUpgrades) {
      updates.push({ key: UPGRADE_KEY, value: editedUpgrades })
    }

    if (updates.length === 0) return

    setError('')
    setSuccessMsg('')
    startTransition(async () => {
      try {
        await batchUpdateBalanceConfigs(updates, adminId)
        setSavedKeys(new Set(updates.map((u) => u.key)))
        setEditedValues({})
        setEditedUpgrades(null)
        setSuccessMsg(`Saved ${updates.length} balance value${updates.length > 1 ? 's' : ''}`)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save')
      }
    })
  }

  // Discard all changes
  function handleDiscardAll() {
    setEditedValues({})
    setEditedUpgrades(null)
    setSuccessMsg('')
  }

  // Seed defaults
  async function handleSeed() {
    setSeedMessage('')
    setError('')
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

  // Calculate rarity sum for validation
  function getRaritySum(): number {
    const keys = ['rarity_distribution.common', 'rarity_distribution.uncommon', 'rarity_distribution.rare', 'rarity_distribution.epic', 'rarity_distribution.legendary']
    return keys.reduce((sum, key) => {
      const field = BALANCE_TABS[1].sections[5].fields.find((f) => f.key === key)
      return sum + Number(getValue(key, field?.defaultValue ?? 0))
    }, 0)
  }

  // Calculate stamina regen time
  function getStaminaRegenTime(): string {
    const max = Number(getValue('stamina.max', 120))
    const rate = Number(getValue('stamina.regen_rate', 1))
    const interval = Number(getValue('stamina.regen_interval_minutes', 8))
    const totalMinutes = (max / rate) * interval
    const hours = Math.floor(totalMinutes / 60)
    const mins = Math.round(totalMinutes % 60)
    return `${hours}h ${mins}m`
  }

  // --- Render field ---
  function renderField(field: FieldDef) {
    const hasEdit = editedValues[field.key] !== undefined
    const isSaved = savedKeys.has(field.key)
    const modified = isModified(field.key, field.defaultValue)
    const currentVal = getValue(field.key, field.defaultValue)
    const isDefault = Number(currentVal) === field.defaultValue && !hasEdit

    return (
      <div
        key={field.key}
        className={`flex items-center gap-3 rounded-lg border px-3 py-2.5 transition-colors ${
          hasEdit
            ? 'border-primary/40 bg-primary/5'
            : isSaved
              ? 'border-green-500/30 bg-green-500/5'
              : 'border-border'
        }`}
      >
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <p className="text-sm font-medium">{field.label}</p>
            {modified && !hasEdit && (
              <Badge variant="outline" className="text-[10px] px-1.5 py-0">
                customized
              </Badge>
            )}
          </div>
          <p className="text-xs text-muted-foreground mt-0.5">{field.description}</p>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          {!isDefault && (
            <button
              className="text-xs text-muted-foreground hover:text-foreground transition-colors"
              onClick={() => handleResetField(field.key, field.defaultValue)}
              title={`Default: ${field.defaultValue}`}
            >
              <RotateCcw className="h-3 w-3" />
            </button>
          )}
          <Input
            type="number"
            value={currentVal}
            onChange={(e) => handleChange(field.key, e.target.value)}
            step={field.step ?? 1}
            min={field.min}
            max={field.max}
            className="w-24 text-right font-mono text-sm h-8"
          />
          {field.unit && (
            <span className="text-xs text-muted-foreground w-12 text-left">{field.unit}</span>
          )}
          {!field.unit && <span className="w-12" />}
          <Button
            size="icon"
            variant={hasEdit ? 'default' : 'outline'}
            className="h-8 w-8"
            onClick={() => handleSaveSingle(field.key)}
            disabled={!hasEdit || isPending}
            title="Save this field"
          >
            {isSaved ? (
              <Check className="h-3.5 w-3.5 text-green-400" />
            ) : (
              <Save className="h-3.5 w-3.5" />
            )}
          </Button>
        </div>
      </div>
    )
  }

  // --- Render upgrade chances (special array field) ---
  function renderUpgradeChances() {
    const chances = getUpgradeChances()
    const hasEdit = editedUpgrades !== null
    const isSaved = savedKeys.has(UPGRADE_KEY)

    return (
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-base">Equipment Upgrade Chances</CardTitle>
              <CardDescription className="text-xs mt-1">
                Success rate (%) for each upgrade level +1 through +10
              </CardDescription>
            </div>
            {hasEdit && (
              <Badge variant="default" className="text-xs">
                modified
              </Badge>
            )}
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-5 gap-2">
            {chances.map((chance, idx) => {
              const isLow = chance < 50
              const isMed = chance >= 50 && chance < 100
              return (
                <div
                  key={idx}
                  className={`rounded-lg border p-2 text-center ${
                    isLow
                      ? 'border-red-500/30 bg-red-500/5'
                      : isMed
                        ? 'border-yellow-500/30 bg-yellow-500/5'
                        : 'border-green-500/30 bg-green-500/5'
                  }`}
                >
                  <p className="text-xs font-medium text-muted-foreground mb-1">
                    +{idx + 1}
                  </p>
                  <Input
                    type="number"
                    value={chance}
                    onChange={(e) =>
                      handleUpgradeChange(idx, Math.max(0, Math.min(100, Number(e.target.value))))
                    }
                    min={0}
                    max={100}
                    step={1}
                    className="text-center font-mono text-sm h-8"
                  />
                  <p className="text-[10px] text-muted-foreground mt-0.5">%</p>
                </div>
              )
            })}
          </div>
        </CardContent>
      </Card>
    )
  }

  // --- Render section ---
  function renderSection(section: SectionDef) {
    return (
      <Card key={section.id}>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">{section.title}</CardTitle>
          {section.description && (
            <CardDescription className="text-xs">{section.description}</CardDescription>
          )}
        </CardHeader>
        <CardContent className="space-y-2">
          {section.fields.map(renderField)}
        </CardContent>
      </Card>
    )
  }

  // --- Empty state ---
  if (configs.length === 0) {
    return (
      <Card>
        <CardContent className="flex flex-col items-center justify-center py-12">
          <Database className="h-12 w-12 mb-4 text-muted-foreground opacity-50" />
          <p className="text-muted-foreground mb-2">No balance configuration found.</p>
          <p className="text-sm text-muted-foreground mb-4">
            Seed the default balance values to get started.
          </p>
          <Button onClick={handleSeed} disabled={isPending}>
            <RefreshCw className={`mr-2 h-4 w-4 ${isPending ? 'animate-spin' : ''}`} />
            {isPending ? 'Seeding...' : 'Seed Default Balance'}
          </Button>
          {seedMessage && (
            <p className="mt-3 text-sm text-green-400">{seedMessage}</p>
          )}
        </CardContent>
      </Card>
    )
  }

  // --- Summary cards ---
  const totalFields = BALANCE_TABS.reduce(
    (sum, tab) => sum + tab.sections.reduce((s, sec) => s + sec.fields.length, 0),
    0
  ) + 1 // +1 for upgrade_chances

  const configuredCount = configs.length
  const raritySum = getRaritySum()
  const regenTime = getStaminaRegenTime()

  return (
    <>
      {/* Info banner */}
      <div className="rounded-md bg-blue-500/10 border border-blue-500/30 px-4 py-3 text-sm text-blue-400 flex items-start gap-2">
        <AlertTriangle className="h-4 w-4 mt-0.5 shrink-0" />
        <div>
          <p className="font-medium">Reference Configuration</p>
          <p className="text-xs text-blue-400/80 mt-0.5">
            These values are stored in the GameConfig table. The game backend currently reads from
            hardcoded constants (<code className="px-1 py-0.5 bg-blue-500/20 rounded text-[11px]">balance.ts</code>).
            After making changes here, update the backend code to apply them to production.
          </p>
        </div>
      </div>

      {/* Error / Success messages */}
      {error && (
        <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
          {error}
        </div>
      )}
      {successMsg && (
        <div className="rounded-md bg-green-600/10 border border-green-600/30 px-4 py-3 text-sm text-green-400">
          {successMsg}
        </div>
      )}

      {/* Summary cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardContent className="pt-4 pb-3">
            <p className="text-xs text-muted-foreground">Configured Values</p>
            <p className="text-2xl font-bold">{configuredCount}</p>
            <p className="text-xs text-muted-foreground">of {totalFields} total fields</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3">
            <p className="text-xs text-muted-foreground">Rarity Distribution Sum</p>
            <p className={`text-2xl font-bold ${raritySum === 100 ? 'text-green-400' : 'text-yellow-400'}`}>
              {raritySum}%
            </p>
            <p className="text-xs text-muted-foreground">{raritySum === 100 ? 'Valid' : 'Should be 100%'}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3">
            <p className="text-xs text-muted-foreground">Stamina 0\u2192Full</p>
            <p className="text-2xl font-bold">{regenTime}</p>
            <p className="text-xs text-muted-foreground">regeneration time</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3">
            <p className="text-xs text-muted-foreground">Pending Changes</p>
            <p className={`text-2xl font-bold ${changeCount > 0 ? 'text-primary' : ''}`}>
              {changeCount}
            </p>
            <p className="text-xs text-muted-foreground">
              {changeCount > 0 ? 'unsaved' : 'all saved'}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Actions row */}
      <div className="flex items-center justify-between">
        <Button variant="outline" size="sm" onClick={handleSeed} disabled={isPending}>
          <RefreshCw className={`mr-2 h-3.5 w-3.5 ${isPending ? 'animate-spin' : ''}`} />
          Seed Missing Defaults
        </Button>
        {seedMessage && (
          <span className="text-sm text-green-400">{seedMessage}</span>
        )}
      </div>

      {/* Main tabs */}
      <Tabs defaultValue="combat" className="w-full">
        <TabsList className="flex flex-wrap h-auto gap-1 bg-transparent p-0">
          {BALANCE_TABS.map((tab) => (
            <TabsTrigger
              key={tab.id}
              value={tab.id}
              className="data-[state=active]:bg-primary/10 data-[state=active]:text-primary flex items-center gap-1.5"
            >
              {tab.icon}
              {tab.label}
            </TabsTrigger>
          ))}
        </TabsList>

        {BALANCE_TABS.map((tab) => (
          <TabsContent key={tab.id} value={tab.id} className="mt-4 space-y-4">
            {tab.sections.map(renderSection)}
            {/* Show upgrade chances in Progression tab */}
            {tab.id === 'progression' && renderUpgradeChances()}
          </TabsContent>
        ))}
      </Tabs>

      {/* Floating save bar */}
      {changeCount > 0 && (
        <div className="sticky bottom-4 z-30">
          <div className="flex items-center justify-between rounded-lg border border-primary/30 bg-background/95 backdrop-blur-sm px-4 py-3 shadow-lg">
            <div className="flex items-center gap-2">
              <div className="h-2 w-2 rounded-full bg-primary animate-pulse" />
              <span className="text-sm font-medium">
                {changeCount} unsaved change{changeCount > 1 ? 's' : ''}
              </span>
            </div>
            <div className="flex items-center gap-2">
              <Button variant="outline" size="sm" onClick={handleDiscardAll} disabled={isPending}>
                <X className="mr-1.5 h-3.5 w-3.5" />
                Discard
              </Button>
              <Button size="sm" onClick={handleSaveAll} disabled={isPending}>
                {isPending ? (
                  <RefreshCw className="mr-1.5 h-3.5 w-3.5 animate-spin" />
                ) : (
                  <Save className="mr-1.5 h-3.5 w-3.5" />
                )}
                Save All Changes
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
