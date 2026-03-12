'use client'

import { useState, useTransition, useCallback, useRef } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Switch } from '@/components/ui/switch'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import {
  ArrowLeft, Save, Plus, Trash2, ChevronDown, ChevronUp, Upload,
  Sword, Shield, Zap, Heart, Eye, Castle, Skull, Sparkles, Package, Image as ImageIcon,
} from 'lucide-react'

// ─── Types ─────────────────────────────────────────────────

type AbilityForm = {
  id?: string
  name: string
  abilityType: string
  damage: number
  cooldown: number
  specialEffect: string
  description: string
}

type BossForm = {
  id?: string
  name: string
  bossType: string
  level: number
  hp: number
  damage: number
  defense: number
  speed: number
  critChance: number
  description: string
  lore: string
  imageUrl: string
  imagePrompt: string
  floorNumber: number
  sortOrder: number
  abilities: AbilityForm[]
}

type WaveEnemyForm = {
  id?: string
  enemyType: string
  level: number
  count: number
}

type WaveForm = {
  id?: string
  waveNumber: number
  enemies: WaveEnemyForm[]
}

type DropForm = {
  id?: string
  itemId: string
  itemName: string
  dropChance: number
  minQuantity: number
  maxQuantity: number
}

type ItemOption = {
  id: string
  itemName: string
  rarity: string
  itemType: string
  itemLevel: number
}

type DungeonData = {
  id: string
  slug: string
  name: string
  description: string | null
  lore: string | null
  levelReq: number
  difficulty: string
  dungeonType: string
  energyCost: number
  imageUrl: string | null
  backgroundUrl: string | null
  imagePrompt: string | null
  imageStyle: string | null
  isActive: boolean
  sortOrder: number
  goldReward: number
  xpReward: number
  bosses: (BossForm & { abilities: AbilityForm[] })[]
  waves: (WaveForm & { enemies: WaveEnemyForm[] })[]
  drops: (DropForm & { item: ItemOption })[]
}

// ─── Constants ─────────────────────────────────────────────

const DIFFICULTIES = ['easy', 'normal', 'hard', 'nightmare']
const DUNGEON_TYPES = ['story', 'side', 'event', 'endgame']
const IMAGE_STYLES = ['fantasy', 'dark_dungeon', 'cave', 'castle']
const ABILITY_TYPES = ['physical', 'magical', 'fire', 'ice', 'lightning', 'poison', 'shadow', 'holy', 'buff', 'debuff', 'heal', 'aoe']
const ENEMY_TYPES = [
  'skeleton', 'zombie', 'ghost', 'spider', 'rat', 'bat', 'golem', 'imp',
  'goblin', 'orc', 'troll', 'demon', 'wraith', 'necromancer', 'banshee',
  'slime', 'elemental', 'drake', 'knight', 'mage', 'assassin', 'archer',
  'berserker', 'cultist', 'gargoyle', 'mimic', 'lich', 'dragon',
]
const BOSS_TYPES = [
  'undead', 'beast', 'demon', 'elemental', 'humanoid', 'construct',
  'dragon', 'aberration', 'celestial', 'fiend',
]

const DIFFICULTY_COLORS: Record<string, string> = {
  easy: 'bg-green-600/20 text-green-400 border-green-600',
  normal: 'bg-blue-600/20 text-blue-400 border-blue-600',
  hard: 'bg-orange-600/20 text-orange-400 border-orange-600',
  nightmare: 'bg-red-600/20 text-red-400 border-red-600',
}

const RARITY_COLORS: Record<string, string> = {
  common: 'text-zinc-400',
  uncommon: 'text-green-400',
  rare: 'text-blue-400',
  epic: 'text-purple-400',
  legendary: 'text-orange-400',
}

// ─── Helpers ───────────────────────────────────────────────

function emptyBoss(floor: number): BossForm {
  return {
    name: '', bossType: '', level: 1, hp: 100, damage: 10, defense: 5,
    speed: 5, critChance: 0, description: '', lore: '', imageUrl: '',
    imagePrompt: '', floorNumber: floor, sortOrder: floor - 1, abilities: [],
  }
}

function emptyAbility(): AbilityForm {
  return { name: '', abilityType: 'physical', damage: 0, cooldown: 0, specialEffect: '', description: '' }
}

function emptyWave(num: number): WaveForm {
  return { waveNumber: num, enemies: [{ enemyType: 'skeleton', level: 1, count: 1 }] }
}

function emptyDrop(): DropForm {
  return { itemId: '', itemName: '', dropChance: 10, minQuantity: 1, maxQuantity: 1 }
}

// ─── Main Component ────────────────────────────────────────

export function DungeonEditor({ dungeon, items }: { dungeon: DungeonData; items: ItemOption[] }) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState('')
  const [saved, setSaved] = useState(false)

  // General fields
  const [name, setName] = useState(dungeon.name)
  const [slug, setSlug] = useState(dungeon.slug)
  const [description, setDescription] = useState(dungeon.description || '')
  const [lore, setLore] = useState(dungeon.lore || '')
  const [levelReq, setLevelReq] = useState(dungeon.levelReq)
  const [difficulty, setDifficulty] = useState(dungeon.difficulty)
  const [dungeonType, setDungeonType] = useState(dungeon.dungeonType)
  const [energyCost, setEnergyCost] = useState(dungeon.energyCost)
  const [isActive, setIsActive] = useState(dungeon.isActive)
  const [sortOrder, setSortOrder] = useState(dungeon.sortOrder)
  const [goldReward, setGoldReward] = useState(dungeon.goldReward)
  const [xpReward, setXpReward] = useState(dungeon.xpReward)

  // Images
  const [imageUrl, setImageUrl] = useState(dungeon.imageUrl || '')
  const [backgroundUrl, setBackgroundUrl] = useState(dungeon.backgroundUrl || '')
  const [imagePrompt, setImagePrompt] = useState(dungeon.imagePrompt || '')
  const [imageStyle, setImageStyle] = useState(dungeon.imageStyle || '')

  // Bosses
  const [bosses, setBosses] = useState<BossForm[]>(
    dungeon.bosses.map((b) => ({
      ...b,
      bossType: b.bossType || '',
      description: b.description || '',
      lore: b.lore || '',
      imageUrl: b.imageUrl || '',
      imagePrompt: b.imagePrompt || '',
      abilities: b.abilities.map((a) => ({
        ...a,
        specialEffect: a.specialEffect || '',
        description: a.description || '',
      })),
    }))
  )

  // Waves
  const [waves, setWaves] = useState<WaveForm[]>(
    dungeon.waves.map((w) => ({
      ...w,
      enemies: w.enemies.map((e) => ({ ...e })),
    }))
  )

  // Drops
  const [drops, setDrops] = useState<DropForm[]>(
    dungeon.drops.map((d) => ({
      itemId: d.itemId,
      itemName: d.item?.itemName || d.itemName || '',
      dropChance: d.dropChance,
      minQuantity: d.minQuantity,
      maxQuantity: d.maxQuantity,
    }))
  )

  // Boss accordion state
  const [expandedBoss, setExpandedBoss] = useState<number | null>(null)

  // Upload ref
  const fileInputRef = useRef<HTMLInputElement>(null)
  const bgFileInputRef = useRef<HTMLInputElement>(null)
  const [uploadTarget, setUploadTarget] = useState<'dungeon' | 'background' | { bossIdx: number }>('dungeon')
  const bossFileInputRef = useRef<HTMLInputElement>(null)

  // ─── Image Upload ──────────────────────────────────────

  const handleUpload = useCallback(async (file: File, target: typeof uploadTarget) => {
    const formData = new FormData()
    formData.append('file', file)
    try {
      const res = await fetch('/api/upload', { method: 'POST', body: formData })
      if (!res.ok) {
        const data = await res.json()
        setError(data.error || 'Upload failed')
        return
      }
      const { url } = await res.json()
      if (target === 'dungeon') setImageUrl(url)
      else if (target === 'background') setBackgroundUrl(url)
      else if (typeof target === 'object' && 'bossIdx' in target) {
        setBosses((prev) => prev.map((b, i) => i === target.bossIdx ? { ...b, imageUrl: url } : b))
      }
    } catch {
      setError('Upload failed')
    }
  }, [])

  // ─── Save ──────────────────────────────────────────────

  function handleSave() {
    setError('')
    setSaved(false)

    if (!name.trim()) { setError('Dungeon name is required'); return }
    if (!slug.trim()) { setError('Slug is required'); return }

    // Validate drops
    for (const d of drops) {
      if (d.dropChance < 0 || d.dropChance > 100) {
        setError('Drop chances must be between 0 and 100')
        return
      }
    }

    startTransition(async () => {
      try {
        const body = {
          name, slug, description, lore, levelReq, difficulty, dungeonType,
          energyCost, imageUrl, backgroundUrl, imagePrompt, imageStyle,
          isActive, sortOrder, goldReward, xpReward,
          bosses: bosses.map((b) => ({
            name: b.name, bossType: b.bossType, level: b.level, hp: b.hp,
            damage: b.damage, defense: b.defense, speed: b.speed,
            critChance: b.critChance, description: b.description, lore: b.lore,
            imageUrl: b.imageUrl, imagePrompt: b.imagePrompt,
            floorNumber: b.floorNumber, sortOrder: b.sortOrder,
            abilities: b.abilities.map((a) => ({
              name: a.name, abilityType: a.abilityType, damage: a.damage,
              cooldown: a.cooldown, specialEffect: a.specialEffect, description: a.description,
            })),
          })),
          waves: waves.map((w) => ({
            waveNumber: w.waveNumber,
            enemies: w.enemies.map((e) => ({
              enemyType: e.enemyType, level: e.level, count: e.count,
            })),
          })),
          drops: drops.filter((d) => d.itemId).map((d) => ({
            itemId: d.itemId, dropChance: d.dropChance,
            minQuantity: d.minQuantity, maxQuantity: d.maxQuantity,
          })),
        }

        const res = await fetch(`/api/dungeons/${dungeon.id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body),
        })

        if (!res.ok) {
          const data = await res.json()
          setError(data.error || 'Failed to save')
          return
        }

        setSaved(true)
        setTimeout(() => setSaved(false), 3000)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save')
      }
    })
  }

  // ─── Boss helpers ──────────────────────────────────────

  function updateBoss(idx: number, field: string, value: unknown) {
    setBosses((prev) => prev.map((b, i) => i === idx ? { ...b, [field]: value } : b))
  }

  function addBoss() {
    setBosses((prev) => [...prev, emptyBoss(prev.length + 1)])
    setExpandedBoss(bosses.length)
  }

  function removeBoss(idx: number) {
    setBosses((prev) => prev.filter((_, i) => i !== idx).map((b, i) => ({ ...b, floorNumber: i + 1, sortOrder: i })))
    setExpandedBoss(null)
  }

  function moveBoss(idx: number, dir: -1 | 1) {
    setBosses((prev) => {
      const next = [...prev]
      const target = idx + dir
      if (target < 0 || target >= next.length) return prev
      ;[next[idx], next[target]] = [next[target], next[idx]]
      return next.map((b, i) => ({ ...b, floorNumber: i + 1, sortOrder: i }))
    })
  }

  // Ability helpers
  function addAbility(bossIdx: number) {
    setBosses((prev) => prev.map((b, i) =>
      i === bossIdx ? { ...b, abilities: [...b.abilities, emptyAbility()] } : b
    ))
  }

  function updateAbility(bossIdx: number, abilityIdx: number, field: string, value: unknown) {
    setBosses((prev) => prev.map((b, i) =>
      i === bossIdx ? {
        ...b,
        abilities: b.abilities.map((a, j) => j === abilityIdx ? { ...a, [field]: value } : a),
      } : b
    ))
  }

  function removeAbility(bossIdx: number, abilityIdx: number) {
    setBosses((prev) => prev.map((b, i) =>
      i === bossIdx ? { ...b, abilities: b.abilities.filter((_, j) => j !== abilityIdx) } : b
    ))
  }

  // ─── Wave helpers ──────────────────────────────────────

  function addWave() {
    setWaves((prev) => [...prev, emptyWave(prev.length + 1)])
  }

  function removeWave(idx: number) {
    setWaves((prev) => prev.filter((_, i) => i !== idx).map((w, i) => ({ ...w, waveNumber: i + 1 })))
  }

  function addEnemy(waveIdx: number) {
    setWaves((prev) => prev.map((w, i) =>
      i === waveIdx ? { ...w, enemies: [...w.enemies, { enemyType: 'skeleton', level: 1, count: 1 }] } : w
    ))
  }

  function updateEnemy(waveIdx: number, enemyIdx: number, field: string, value: unknown) {
    setWaves((prev) => prev.map((w, i) =>
      i === waveIdx ? {
        ...w,
        enemies: w.enemies.map((e, j) => j === enemyIdx ? { ...e, [field]: value } : e),
      } : w
    ))
  }

  function removeEnemy(waveIdx: number, enemyIdx: number) {
    setWaves((prev) => prev.map((w, i) =>
      i === waveIdx ? { ...w, enemies: w.enemies.filter((_, j) => j !== enemyIdx) } : w
    ))
  }

  // ─── Drop helpers ──────────────────────────────────────

  function addDrop() {
    setDrops((prev) => [...prev, emptyDrop()])
  }

  function updateDrop(idx: number, field: string, value: unknown) {
    setDrops((prev) => prev.map((d, i) => i === idx ? { ...d, [field]: value } : d))
  }

  function removeDrop(idx: number) {
    setDrops((prev) => prev.filter((_, i) => i !== idx))
  }

  function selectDropItem(idx: number, itemId: string) {
    const item = items.find((it) => it.id === itemId)
    if (item) {
      setDrops((prev) => prev.map((d, i) => i === idx ? { ...d, itemId: item.id, itemName: item.itemName } : d))
    }
  }

  // ─── Render ────────────────────────────────────────────

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <Link href="/dungeons">
            <Button variant="ghost" size="icon"><ArrowLeft className="h-4 w-4" /></Button>
          </Link>
          <div>
            <h1 className="text-2xl font-bold tracking-tight">{name || 'Untitled Dungeon'}</h1>
            <p className="text-sm text-muted-foreground font-mono">{dungeon.id}</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          {saved && <span className="text-sm text-green-400">Saved!</span>}
          {error && <span className="text-sm text-destructive max-w-md truncate">{error}</span>}
          <Button onClick={handleSave} disabled={isPending}>
            <Save className="mr-2 h-4 w-4" />
            {isPending ? 'Saving...' : 'Save Dungeon'}
          </Button>
        </div>
      </div>

      {/* Main layout: Editor + Preview */}
      <div className="flex gap-6">
        {/* Editor (left) */}
        <div className="flex-1 min-w-0">
          <Tabs defaultValue="general">
            <TabsList className="mb-4">
              <TabsTrigger value="general">General</TabsTrigger>
              <TabsTrigger value="bosses">Bosses ({bosses.length})</TabsTrigger>
              <TabsTrigger value="waves">Waves ({waves.length})</TabsTrigger>
              <TabsTrigger value="drops">Drops ({drops.length})</TabsTrigger>
              <TabsTrigger value="images">Images</TabsTrigger>
            </TabsList>

            {/* ═══ GENERAL TAB ═══ */}
            <TabsContent value="general">
              <Card>
                <CardHeader><CardTitle>Dungeon Properties</CardTitle></CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label>Dungeon Name</Label>
                      <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="Training Camp" />
                    </div>
                    <div className="space-y-2">
                      <Label>Slug (unique ID)</Label>
                      <Input value={slug} onChange={(e) => setSlug(e.target.value)} placeholder="training_camp" className="font-mono" />
                    </div>
                  </div>
                  <div className="grid grid-cols-3 gap-4">
                    <div className="space-y-2">
                      <Label>Difficulty</Label>
                      <Select value={difficulty} onValueChange={setDifficulty}>
                        <SelectTrigger><SelectValue /></SelectTrigger>
                        <SelectContent>
                          {DIFFICULTIES.map((d) => <SelectItem key={d} value={d}>{d.charAt(0).toUpperCase() + d.slice(1)}</SelectItem>)}
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="space-y-2">
                      <Label>Dungeon Type</Label>
                      <Select value={dungeonType} onValueChange={setDungeonType}>
                        <SelectTrigger><SelectValue /></SelectTrigger>
                        <SelectContent>
                          {DUNGEON_TYPES.map((t) => <SelectItem key={t} value={t}>{t.charAt(0).toUpperCase() + t.slice(1)}</SelectItem>)}
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="space-y-2">
                      <Label>Level Requirement</Label>
                      <Input type="number" min={1} value={levelReq} onChange={(e) => setLevelReq(Number(e.target.value))} />
                    </div>
                  </div>
                  <div className="grid grid-cols-4 gap-4">
                    <div className="space-y-2">
                      <Label>Energy Cost</Label>
                      <Input type="number" min={0} value={energyCost} onChange={(e) => setEnergyCost(Number(e.target.value))} />
                    </div>
                    <div className="space-y-2">
                      <Label>Gold Reward</Label>
                      <Input type="number" min={0} value={goldReward} onChange={(e) => setGoldReward(Number(e.target.value))} />
                    </div>
                    <div className="space-y-2">
                      <Label>XP Reward</Label>
                      <Input type="number" min={0} value={xpReward} onChange={(e) => setXpReward(Number(e.target.value))} />
                    </div>
                    <div className="space-y-2">
                      <Label>Sort Order</Label>
                      <Input type="number" min={0} value={sortOrder} onChange={(e) => setSortOrder(Number(e.target.value))} />
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Switch checked={isActive} onCheckedChange={setIsActive} />
                    <Label>Active (visible to players)</Label>
                  </div>
                  <div className="space-y-2">
                    <Label>Description</Label>
                    <Textarea value={description} onChange={(e) => setDescription(e.target.value)} rows={3} placeholder="A brief description of the dungeon..." />
                  </div>
                  <div className="space-y-2">
                    <Label>Lore</Label>
                    <Textarea value={lore} onChange={(e) => setLore(e.target.value)} rows={4} placeholder="The ancient catacombs beneath the mountain..." />
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* ═══ BOSSES TAB ═══ */}
            <TabsContent value="bosses">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold">Bosses ({bosses.length})</h3>
                  <Button onClick={addBoss} size="sm"><Plus className="mr-1 h-3 w-3" /> Add Boss</Button>
                </div>
                {bosses.length === 0 && (
                  <Card>
                    <CardContent className="py-8 text-center text-muted-foreground">
                      <Skull className="mx-auto mb-2 h-8 w-8 opacity-40" />
                      <p>No bosses yet. Add a boss to populate this dungeon.</p>
                    </CardContent>
                  </Card>
                )}
                {bosses.map((boss, bIdx) => (
                  <Card key={bIdx} className="overflow-hidden">
                    <div
                      className="flex items-center justify-between px-4 py-3 cursor-pointer hover:bg-muted/30 transition-colors"
                      onClick={() => setExpandedBoss(expandedBoss === bIdx ? null : bIdx)}
                    >
                      <div className="flex items-center gap-3">
                        <span className="text-xs font-mono text-muted-foreground w-6">#{boss.floorNumber}</span>
                        <Skull className="h-4 w-4 text-red-400" />
                        <span className="font-medium">{boss.name || 'Unnamed Boss'}</span>
                        <Badge variant="secondary">Lv.{boss.level}</Badge>
                        <span className="text-xs text-muted-foreground">HP:{boss.hp} DMG:{boss.damage}</span>
                        {boss.abilities.length > 0 && (
                          <Badge variant="secondary">{boss.abilities.length} abilities</Badge>
                        )}
                      </div>
                      <div className="flex items-center gap-1">
                        <Button variant="ghost" size="icon" onClick={(e) => { e.stopPropagation(); moveBoss(bIdx, -1) }} disabled={bIdx === 0}>
                          <ChevronUp className="h-3 w-3" />
                        </Button>
                        <Button variant="ghost" size="icon" onClick={(e) => { e.stopPropagation(); moveBoss(bIdx, 1) }} disabled={bIdx === bosses.length - 1}>
                          <ChevronDown className="h-3 w-3" />
                        </Button>
                        <Button variant="ghost" size="icon" onClick={(e) => { e.stopPropagation(); removeBoss(bIdx) }}>
                          <Trash2 className="h-3 w-3 text-destructive" />
                        </Button>
                        {expandedBoss === bIdx ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
                      </div>
                    </div>

                    {expandedBoss === bIdx && (
                      <CardContent className="border-t border-border pt-4 space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                          <div className="space-y-2">
                            <Label>Boss Name</Label>
                            <Input value={boss.name} onChange={(e) => updateBoss(bIdx, 'name', e.target.value)} placeholder="Arena Warden" />
                          </div>
                          <div className="space-y-2">
                            <Label>Boss Type</Label>
                            <Select value={boss.bossType || 'none'} onValueChange={(v) => updateBoss(bIdx, 'bossType', v === 'none' ? '' : v)}>
                              <SelectTrigger><SelectValue placeholder="Select type" /></SelectTrigger>
                              <SelectContent>
                                <SelectItem value="none">None</SelectItem>
                                {BOSS_TYPES.map((t) => <SelectItem key={t} value={t}>{t.charAt(0).toUpperCase() + t.slice(1)}</SelectItem>)}
                              </SelectContent>
                            </Select>
                          </div>
                        </div>
                        <div className="grid grid-cols-4 gap-3">
                          <div className="space-y-1">
                            <Label className="text-xs flex items-center gap-1"><Sword className="h-3 w-3" /> Level</Label>
                            <Input type="number" min={1} value={boss.level} onChange={(e) => updateBoss(bIdx, 'level', Number(e.target.value))} />
                          </div>
                          <div className="space-y-1">
                            <Label className="text-xs flex items-center gap-1"><Heart className="h-3 w-3 text-red-400" /> HP</Label>
                            <Input type="number" min={1} value={boss.hp} onChange={(e) => updateBoss(bIdx, 'hp', Number(e.target.value))} />
                          </div>
                          <div className="space-y-1">
                            <Label className="text-xs flex items-center gap-1"><Sword className="h-3 w-3 text-orange-400" /> Damage</Label>
                            <Input type="number" min={0} value={boss.damage} onChange={(e) => updateBoss(bIdx, 'damage', Number(e.target.value))} />
                          </div>
                          <div className="space-y-1">
                            <Label className="text-xs flex items-center gap-1"><Shield className="h-3 w-3 text-blue-400" /> Defense</Label>
                            <Input type="number" min={0} value={boss.defense} onChange={(e) => updateBoss(bIdx, 'defense', Number(e.target.value))} />
                          </div>
                        </div>
                        <div className="grid grid-cols-3 gap-3">
                          <div className="space-y-1">
                            <Label className="text-xs flex items-center gap-1"><Zap className="h-3 w-3 text-yellow-400" /> Speed</Label>
                            <Input type="number" min={0} value={boss.speed} onChange={(e) => updateBoss(bIdx, 'speed', Number(e.target.value))} />
                          </div>
                          <div className="space-y-1">
                            <Label className="text-xs">Crit Chance (%)</Label>
                            <Input type="number" min={0} max={100} step={0.1} value={boss.critChance} onChange={(e) => updateBoss(bIdx, 'critChance', Number(e.target.value))} />
                          </div>
                          <div className="space-y-1">
                            <Label className="text-xs">Floor Number</Label>
                            <Input type="number" min={1} value={boss.floorNumber} onChange={(e) => updateBoss(bIdx, 'floorNumber', Number(e.target.value))} />
                          </div>
                        </div>
                        <div className="space-y-2">
                          <Label>Boss Description</Label>
                          <Textarea value={boss.description} onChange={(e) => updateBoss(bIdx, 'description', e.target.value)} rows={2} />
                        </div>
                        <div className="space-y-2">
                          <Label>Boss Lore</Label>
                          <Textarea value={boss.lore} onChange={(e) => updateBoss(bIdx, 'lore', e.target.value)} rows={2} />
                        </div>

                        {/* Boss Image */}
                        <div className="grid grid-cols-2 gap-4">
                          <div className="space-y-2">
                            <Label>Boss Image URL</Label>
                            <div className="flex gap-2">
                              <Input value={boss.imageUrl} onChange={(e) => updateBoss(bIdx, 'imageUrl', e.target.value)} placeholder="https://..." className="flex-1" />
                              <Button type="button" variant="outline" size="icon" onClick={() => {
                                setUploadTarget({ bossIdx: bIdx })
                                bossFileInputRef.current?.click()
                              }}>
                                <Upload className="h-4 w-4" />
                              </Button>
                            </div>
                          </div>
                          <div className="space-y-2">
                            <Label>Boss Image Prompt</Label>
                            <Input value={boss.imagePrompt} onChange={(e) => updateBoss(bIdx, 'imagePrompt', e.target.value)} placeholder="A fearsome undead warden..." />
                          </div>
                        </div>
                        {boss.imageUrl && (
                          <div className="w-24 h-24 rounded-lg border border-border overflow-hidden bg-muted">
                            <img src={boss.imageUrl} alt={boss.name} className="w-full h-full object-cover" />
                          </div>
                        )}

                        {/* Abilities */}
                        <div className="border-t border-border pt-4">
                          <div className="flex items-center justify-between mb-3">
                            <h4 className="font-semibold text-sm flex items-center gap-2">
                              <Sparkles className="h-4 w-4 text-purple-400" />
                              Abilities ({boss.abilities.length})
                            </h4>
                            <Button onClick={() => addAbility(bIdx)} size="sm" variant="outline">
                              <Plus className="mr-1 h-3 w-3" /> Add Ability
                            </Button>
                          </div>
                          {boss.abilities.map((ability, aIdx) => (
                            <div key={aIdx} className="border border-border rounded-lg p-3 mb-2 space-y-2">
                              <div className="flex items-center justify-between">
                                <span className="text-xs font-mono text-muted-foreground">Ability #{aIdx + 1}</span>
                                <Button variant="ghost" size="icon" onClick={() => removeAbility(bIdx, aIdx)}>
                                  <Trash2 className="h-3 w-3 text-destructive" />
                                </Button>
                              </div>
                              <div className="grid grid-cols-2 gap-3">
                                <div className="space-y-1">
                                  <Label className="text-xs">Name</Label>
                                  <Input value={ability.name} onChange={(e) => updateAbility(bIdx, aIdx, 'name', e.target.value)} placeholder="Fire Slam" />
                                </div>
                                <div className="space-y-1">
                                  <Label className="text-xs">Type</Label>
                                  <Select value={ability.abilityType} onValueChange={(v) => updateAbility(bIdx, aIdx, 'abilityType', v)}>
                                    <SelectTrigger><SelectValue /></SelectTrigger>
                                    <SelectContent>
                                      {ABILITY_TYPES.map((t) => <SelectItem key={t} value={t}>{t.charAt(0).toUpperCase() + t.slice(1)}</SelectItem>)}
                                    </SelectContent>
                                  </Select>
                                </div>
                              </div>
                              <div className="grid grid-cols-3 gap-3">
                                <div className="space-y-1">
                                  <Label className="text-xs">Damage</Label>
                                  <Input type="number" min={0} value={ability.damage} onChange={(e) => updateAbility(bIdx, aIdx, 'damage', Number(e.target.value))} />
                                </div>
                                <div className="space-y-1">
                                  <Label className="text-xs">Cooldown (turns)</Label>
                                  <Input type="number" min={0} value={ability.cooldown} onChange={(e) => updateAbility(bIdx, aIdx, 'cooldown', Number(e.target.value))} />
                                </div>
                                <div className="space-y-1">
                                  <Label className="text-xs">Special Effect</Label>
                                  <Input value={ability.specialEffect} onChange={(e) => updateAbility(bIdx, aIdx, 'specialEffect', e.target.value)} placeholder="Burn, Stun, etc." />
                                </div>
                              </div>
                              <div className="space-y-1">
                                <Label className="text-xs">Description</Label>
                                <Input value={ability.description} onChange={(e) => updateAbility(bIdx, aIdx, 'description', e.target.value)} />
                              </div>
                            </div>
                          ))}
                        </div>
                      </CardContent>
                    )}
                  </Card>
                ))}
              </div>
            </TabsContent>

            {/* ═══ WAVES TAB ═══ */}
            <TabsContent value="waves">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold">Enemy Waves ({waves.length})</h3>
                  <Button onClick={addWave} size="sm"><Plus className="mr-1 h-3 w-3" /> Add Wave</Button>
                </div>
                {waves.length === 0 && (
                  <Card>
                    <CardContent className="py-8 text-center text-muted-foreground">
                      <Shield className="mx-auto mb-2 h-8 w-8 opacity-40" />
                      <p>No enemy waves. Add waves to populate the dungeon with enemies.</p>
                    </CardContent>
                  </Card>
                )}
                {waves.map((wave, wIdx) => (
                  <Card key={wIdx}>
                    <CardHeader className="py-3">
                      <div className="flex items-center justify-between">
                        <CardTitle className="text-sm">Wave {wave.waveNumber}</CardTitle>
                        <div className="flex items-center gap-2">
                          <Button onClick={() => addEnemy(wIdx)} size="sm" variant="outline">
                            <Plus className="mr-1 h-3 w-3" /> Add Enemy
                          </Button>
                          <Button variant="ghost" size="icon" onClick={() => removeWave(wIdx)}>
                            <Trash2 className="h-3 w-3 text-destructive" />
                          </Button>
                        </div>
                      </div>
                    </CardHeader>
                    <CardContent className="pt-0 space-y-2">
                      {wave.enemies.map((enemy, eIdx) => (
                        <div key={eIdx} className="flex items-center gap-3">
                          <Select value={enemy.enemyType} onValueChange={(v) => updateEnemy(wIdx, eIdx, 'enemyType', v)}>
                            <SelectTrigger className="w-[180px]"><SelectValue /></SelectTrigger>
                            <SelectContent>
                              {ENEMY_TYPES.map((t) => <SelectItem key={t} value={t}>{t.charAt(0).toUpperCase() + t.slice(1)}</SelectItem>)}
                            </SelectContent>
                          </Select>
                          <div className="flex items-center gap-1">
                            <Label className="text-xs text-muted-foreground">Lv</Label>
                            <Input type="number" min={1} value={enemy.level} onChange={(e) => updateEnemy(wIdx, eIdx, 'level', Number(e.target.value))} className="w-20" />
                          </div>
                          <div className="flex items-center gap-1">
                            <Label className="text-xs text-muted-foreground">x</Label>
                            <Input type="number" min={1} value={enemy.count} onChange={(e) => updateEnemy(wIdx, eIdx, 'count', Number(e.target.value))} className="w-20" />
                          </div>
                          <span className="text-xs text-muted-foreground flex-1">
                            {enemy.enemyType.charAt(0).toUpperCase() + enemy.enemyType.slice(1)} x{enemy.count}
                          </span>
                          <Button variant="ghost" size="icon" onClick={() => removeEnemy(wIdx, eIdx)}>
                            <Trash2 className="h-3 w-3 text-destructive" />
                          </Button>
                        </div>
                      ))}
                      {wave.enemies.length === 0 && (
                        <p className="text-xs text-muted-foreground py-2">No enemies in this wave.</p>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </div>
            </TabsContent>

            {/* ═══ DROPS TAB ═══ */}
            <TabsContent value="drops">
              <div className="space-y-3">
                <Card>
                  <CardHeader className="py-3">
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-sm flex items-center gap-2">
                        <Package className="h-4 w-4" /> Base Rewards
                      </CardTitle>
                    </div>
                  </CardHeader>
                  <CardContent className="pt-0">
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label>Gold Reward (base)</Label>
                        <Input type="number" min={0} value={goldReward} onChange={(e) => setGoldReward(Number(e.target.value))} />
                      </div>
                      <div className="space-y-2">
                        <Label>XP Reward (base)</Label>
                        <Input type="number" min={0} value={xpReward} onChange={(e) => setXpReward(Number(e.target.value))} />
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold">Item Drop Table ({drops.length})</h3>
                  <Button onClick={addDrop} size="sm"><Plus className="mr-1 h-3 w-3" /> Add Drop</Button>
                </div>
                {drops.length === 0 && (
                  <Card>
                    <CardContent className="py-8 text-center text-muted-foreground">
                      <Package className="mx-auto mb-2 h-8 w-8 opacity-40" />
                      <p>No item drops configured. Add items from the catalog.</p>
                    </CardContent>
                  </Card>
                )}

                <div className="rounded-lg border border-border">
                  {drops.length > 0 && (
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-border bg-muted/50">
                          <th className="px-3 py-2 text-left font-medium text-muted-foreground">Item</th>
                          <th className="px-3 py-2 text-left font-medium text-muted-foreground">Drop %</th>
                          <th className="px-3 py-2 text-left font-medium text-muted-foreground">Min Qty</th>
                          <th className="px-3 py-2 text-left font-medium text-muted-foreground">Max Qty</th>
                          <th className="px-3 py-2 text-right font-medium text-muted-foreground"></th>
                        </tr>
                      </thead>
                      <tbody>
                        {drops.map((drop, dIdx) => (
                          <tr key={dIdx} className="border-b border-border">
                            <td className="px-3 py-2">
                              <Select value={drop.itemId || 'none'} onValueChange={(v) => v !== 'none' && selectDropItem(dIdx, v)}>
                                <SelectTrigger className="w-[280px]">
                                  <SelectValue placeholder="Select item..." />
                                </SelectTrigger>
                                <SelectContent>
                                  <SelectItem value="none" disabled>Select an item</SelectItem>
                                  {items.map((item) => (
                                    <SelectItem key={item.id} value={item.id}>
                                      <span className={RARITY_COLORS[item.rarity] || ''}>
                                        [{item.rarity}] {item.itemName} (Lv.{item.itemLevel})
                                      </span>
                                    </SelectItem>
                                  ))}
                                </SelectContent>
                              </Select>
                            </td>
                            <td className="px-3 py-2">
                              <Input
                                type="number" min={0} max={100} step={0.1}
                                value={drop.dropChance}
                                onChange={(e) => updateDrop(dIdx, 'dropChance', Number(e.target.value))}
                                className="w-24"
                              />
                            </td>
                            <td className="px-3 py-2">
                              <Input
                                type="number" min={1}
                                value={drop.minQuantity}
                                onChange={(e) => updateDrop(dIdx, 'minQuantity', Number(e.target.value))}
                                className="w-20"
                              />
                            </td>
                            <td className="px-3 py-2">
                              <Input
                                type="number" min={1}
                                value={drop.maxQuantity}
                                onChange={(e) => updateDrop(dIdx, 'maxQuantity', Number(e.target.value))}
                                className="w-20"
                              />
                            </td>
                            <td className="px-3 py-2 text-right">
                              <Button variant="ghost" size="icon" onClick={() => removeDrop(dIdx)}>
                                <Trash2 className="h-3 w-3 text-destructive" />
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                </div>
              </div>
            </TabsContent>

            {/* ═══ IMAGES TAB ═══ */}
            <TabsContent value="images">
              <div className="space-y-4">
                <Card>
                  <CardHeader><CardTitle className="flex items-center gap-2"><ImageIcon className="h-4 w-4" /> Dungeon Image</CardTitle></CardHeader>
                  <CardContent className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label>Image URL</Label>
                        <div className="flex gap-2">
                          <Input value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} placeholder="https://..." className="flex-1" />
                          <Button type="button" variant="outline" onClick={() => {
                            setUploadTarget('dungeon')
                            fileInputRef.current?.click()
                          }}>
                            <Upload className="mr-2 h-4 w-4" /> Upload
                          </Button>
                        </div>
                      </div>
                      <div className="space-y-2">
                        <Label>Background Image URL</Label>
                        <div className="flex gap-2">
                          <Input value={backgroundUrl} onChange={(e) => setBackgroundUrl(e.target.value)} placeholder="https://..." className="flex-1" />
                          <Button type="button" variant="outline" onClick={() => {
                            setUploadTarget('background')
                            bgFileInputRef.current?.click()
                          }}>
                            <Upload className="mr-2 h-4 w-4" /> Upload
                          </Button>
                        </div>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label>Image Prompt (for AI generation)</Label>
                        <Textarea value={imagePrompt} onChange={(e) => setImagePrompt(e.target.value)} rows={2} placeholder="A dark catacomb with glowing runes..." />
                      </div>
                      <div className="space-y-2">
                        <Label>Image Style</Label>
                        <Select value={imageStyle || 'none'} onValueChange={(v) => setImageStyle(v === 'none' ? '' : v)}>
                          <SelectTrigger><SelectValue placeholder="Select style" /></SelectTrigger>
                          <SelectContent>
                            <SelectItem value="none">None</SelectItem>
                            {IMAGE_STYLES.map((s) => (
                              <SelectItem key={s} value={s}>
                                {s.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>
                    </div>
                    {/* Previews */}
                    <div className="flex gap-4">
                      {imageUrl && (
                        <div className="space-y-1">
                          <Label className="text-xs text-muted-foreground">Dungeon Image Preview</Label>
                          <div className="w-48 h-32 rounded-lg border border-border overflow-hidden bg-muted">
                            <img src={imageUrl} alt="Dungeon" className="w-full h-full object-cover" />
                          </div>
                        </div>
                      )}
                      {backgroundUrl && (
                        <div className="space-y-1">
                          <Label className="text-xs text-muted-foreground">Background Preview</Label>
                          <div className="w-48 h-32 rounded-lg border border-border overflow-hidden bg-muted">
                            <img src={backgroundUrl} alt="Background" className="w-full h-full object-cover" />
                          </div>
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              </div>
            </TabsContent>
          </Tabs>
        </div>

        {/* ═══ LIVE PREVIEW (right side) ═══ */}
        <div className="w-80 shrink-0 hidden xl:block">
          <div className="sticky top-20 space-y-4">
            <Card className="overflow-hidden">
              <div className="relative">
                {imageUrl ? (
                  <img src={imageUrl} alt={name} className="w-full h-40 object-cover" />
                ) : (
                  <div className="w-full h-40 bg-gradient-to-br from-zinc-800 to-zinc-900 flex items-center justify-center">
                    <Castle className="h-12 w-12 text-zinc-600" />
                  </div>
                )}
                <div className="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/80 to-transparent p-3">
                  <h3 className="text-lg font-bold text-white">{name || 'Untitled Dungeon'}</h3>
                  <div className="flex gap-2 mt-1">
                    <Badge className={DIFFICULTY_COLORS[difficulty] || ''} >{difficulty}</Badge>
                    <Badge variant="secondary">Lv.{levelReq}+</Badge>
                    {!isActive && <Badge variant="secondary">Disabled</Badge>}
                  </div>
                </div>
              </div>
              <CardContent className="p-3 space-y-3">
                {description && (
                  <p className="text-xs text-muted-foreground">{description}</p>
                )}
                <div className="grid grid-cols-3 gap-2 text-center">
                  <div className="rounded-md bg-muted p-2">
                    <div className="text-xs text-muted-foreground">Energy</div>
                    <div className="font-bold text-sm">{energyCost}</div>
                  </div>
                  <div className="rounded-md bg-muted p-2">
                    <div className="text-xs text-muted-foreground">Gold</div>
                    <div className="font-bold text-sm text-yellow-400">{goldReward}</div>
                  </div>
                  <div className="rounded-md bg-muted p-2">
                    <div className="text-xs text-muted-foreground">XP</div>
                    <div className="font-bold text-sm text-blue-400">{xpReward}</div>
                  </div>
                </div>

                {/* Boss Preview */}
                {bosses.length > 0 && (
                  <div>
                    <h4 className="text-xs font-semibold text-muted-foreground mb-2 flex items-center gap-1">
                      <Skull className="h-3 w-3" /> BOSSES ({bosses.length})
                    </h4>
                    <div className="space-y-1">
                      {bosses.map((b, i) => (
                        <div key={i} className="flex items-center justify-between text-xs py-1 px-2 rounded bg-muted/50">
                          <span className="flex items-center gap-2">
                            <span className="font-mono text-muted-foreground">#{b.floorNumber}</span>
                            <span className="font-medium">{b.name || 'Unnamed'}</span>
                          </span>
                          <span className="text-muted-foreground">
                            Lv.{b.level} HP:{b.hp}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Waves Preview */}
                {waves.length > 0 && (
                  <div>
                    <h4 className="text-xs font-semibold text-muted-foreground mb-2 flex items-center gap-1">
                      <Eye className="h-3 w-3" /> ENEMY WAVES ({waves.length})
                    </h4>
                    <div className="space-y-1">
                      {waves.map((w, i) => (
                        <div key={i} className="text-xs py-1 px-2 rounded bg-muted/50">
                          <span className="font-mono text-muted-foreground">Wave {w.waveNumber}: </span>
                          {w.enemies.map((e, j) => (
                            <span key={j}>
                              {j > 0 && ', '}
                              {e.enemyType} x{e.count}
                            </span>
                          ))}
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Drops Preview */}
                {drops.filter(d => d.itemId).length > 0 && (
                  <div>
                    <h4 className="text-xs font-semibold text-muted-foreground mb-2 flex items-center gap-1">
                      <Package className="h-3 w-3" /> DROP TABLE ({drops.filter(d => d.itemId).length})
                    </h4>
                    <div className="space-y-1">
                      {drops.filter(d => d.itemId).map((d, i) => (
                        <div key={i} className="flex items-center justify-between text-xs py-1 px-2 rounded bg-muted/50">
                          <span className="font-medium">{d.itemName}</span>
                          <span className="text-muted-foreground">{d.dropChance}%</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Hidden file inputs */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/png,image/jpeg,image/webp,image/gif"
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0]
          if (file) handleUpload(file, 'dungeon')
          e.target.value = ''
        }}
      />
      <input
        ref={bgFileInputRef}
        type="file"
        accept="image/png,image/jpeg,image/webp,image/gif"
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0]
          if (file) handleUpload(file, 'background')
          e.target.value = ''
        }}
      />
      <input
        ref={bossFileInputRef}
        type="file"
        accept="image/png,image/jpeg,image/webp,image/gif"
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0]
          if (file) handleUpload(file, uploadTarget)
          e.target.value = ''
        }}
      />
    </div>
  )
}
