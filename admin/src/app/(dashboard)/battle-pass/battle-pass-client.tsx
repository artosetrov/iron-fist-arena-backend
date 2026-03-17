'use client'

import { useState, useMemo } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import { Badge } from '@/components/ui/badge'
import {
  createBattlePassReward,
  updateBattlePassReward,
  deleteBattlePassReward,
  bulkCreateBattlePassRewards,
} from '@/actions/battle-pass-rewards'
import { Trash2, Plus, Wand2, Gift } from 'lucide-react'
import { toast } from 'sonner'

type Season = {
  id: string
  number: number
  theme: string | null
}

type BattlePassReward = {
  id: string
  seasonId: string
  bpLevel: number
  isPremium: boolean
  rewardType: string
  rewardId: string | null
  rewardAmount: number
  season: Season
}

type EditingState = {
  rewardId: string
  field: 'rewardType' | 'rewardAmount'
  value: string | number
}

export function BattlePassClient({
  rewards: initialRewards,
  seasons,
}: {
  rewards: BattlePassReward[]
  seasons: Season[]
}) {
  const [rewards, setRewards] = useState<BattlePassReward[]>(initialRewards)
  const [selectedSeasonId, setSelectedSeasonId] = useState<string>(
    seasons[0]?.id || ''
  )
  const [isAddOpen, setIsAddOpen] = useState(false)
  const [isBulkOpen, setIsBulkOpen] = useState(false)
  const [bulkMaxLevel, setBulkMaxLevel] = useState('50')
  const [editing, setEditing] = useState<EditingState | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const seasonRewards = useMemo(() => {
    return rewards.filter((r) => r.seasonId === selectedSeasonId)
  }, [rewards, selectedSeasonId])

  const selectedSeason = seasons.find((s) => s.id === selectedSeasonId)

  // Group rewards by level
  const rewardsByLevel = useMemo(() => {
    const map = new Map<number, { free?: BattlePassReward; premium?: BattlePassReward }>()
    seasonRewards.forEach((r) => {
      const level = r.bpLevel
      if (!map.has(level)) map.set(level, {})
      if (r.isPremium) {
        map.get(level)!.premium = r
      } else {
        map.get(level)!.free = r
      }
    })
    return Array.from(map.entries())
      .sort((a, b) => a[0] - b[0])
      .map(([level, rewards]) => ({ level, ...rewards }))
  }, [seasonRewards])

  const handleAddReward = async (data: {
    bpLevel: number
    isPremium: boolean
    rewardType: string
    rewardAmount: number
  }) => {
    setIsLoading(true)
    try {
      const newReward = await createBattlePassReward({
        seasonId: selectedSeasonId,
        ...data,
      })
      setRewards((prev) => [...prev, newReward])
      setIsAddOpen(false)
      toast.success('Reward created')
    } catch (error) {
      toast.error(String(error))
    } finally {
      setIsLoading(false)
    }
  }

  const handleUpdateReward = async (rewardId: string, field: string, value: unknown) => {
    setIsLoading(true)
    try {
      const updated = await updateBattlePassReward(rewardId, {
        [field]: value,
      } as never)
      setRewards((prev) =>
        prev.map((r) => (r.id === rewardId ? { ...r, [field]: value } : r))
      )
      setEditing(null)
      toast.success('Reward updated')
    } catch (error) {
      toast.error(String(error))
    } finally {
      setIsLoading(false)
    }
  }

  const handleDeleteReward = async (rewardId: string) => {
    if (!confirm('Delete this reward?')) return
    setIsLoading(true)
    try {
      await deleteBattlePassReward(rewardId)
      setRewards((prev) => prev.filter((r) => r.id !== rewardId))
      toast.success('Reward deleted')
    } catch (error) {
      toast.error(String(error))
    } finally {
      setIsLoading(false)
    }
  }

  const handleBulkCreate = async () => {
    const level = parseInt(bulkMaxLevel, 10)
    if (!level || level < 1) {
      toast.error('Invalid max level')
      return
    }

    setIsLoading(true)
    try {
      const result = await bulkCreateBattlePassRewards(selectedSeasonId, level)
      // Refresh rewards
      const updated = rewards.filter((r) => r.seasonId !== selectedSeasonId)
      // We need to refetch, so just toggle and refetch
      window.location.reload()
    } catch (error) {
      toast.error(String(error))
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Season Selector */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center gap-4">
            <div className="flex-1">
              <label className="text-sm font-medium text-muted-foreground">Season</label>
              <Select value={selectedSeasonId} onValueChange={setSelectedSeasonId}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {seasons.map((s) => (
                    <SelectItem key={s.id} value={s.id}>
                      {s.theme || `Season ${s.number}`}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Bulk Create Dialog */}
            <Dialog open={isBulkOpen} onOpenChange={setIsBulkOpen}>
              <DialogTrigger asChild>
                <Button variant="outline" className="mt-6">
                  <Wand2 className="mr-2 h-4 w-4" />
                  Generate Default Rewards
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Generate Default Rewards</DialogTitle>
                  <DialogDescription>
                    Create default free and premium rewards for all levels up to the
                    specified maximum. Existing rewards will be skipped.
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4">
                  <div>
                    <label className="text-sm font-medium">Max Level</label>
                    <Input
                      type="number"
                      value={bulkMaxLevel}
                      onChange={(e) => setBulkMaxLevel(e.target.value)}
                      min="1"
                      max="500"
                    />
                  </div>
                  <Button
                    onClick={handleBulkCreate}
                    disabled={isLoading}
                    className="w-full"
                  >
                    Generate
                  </Button>
                </div>
              </DialogContent>
            </Dialog>

            {/* Add Reward Dialog */}
            <Dialog open={isAddOpen} onOpenChange={setIsAddOpen}>
              <DialogTrigger asChild>
                <Button className="mt-6">
                  <Plus className="mr-2 h-4 w-4" />
                  Add Reward
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Add Reward</DialogTitle>
                </DialogHeader>
                <AddRewardForm
                  onSubmit={handleAddReward}
                  isLoading={isLoading}
                  existingLevels={seasonRewards.map((r) => r.bpLevel)}
                />
              </DialogContent>
            </Dialog>
          </div>
        </CardContent>
      </Card>

      {/* Summary Card */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium">
            {selectedSeason?.theme || `Season ${selectedSeason?.number}`} - Rewards
          </CardTitle>
          <Gift className="h-4 w-4 text-amber-400" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{seasonRewards.length}</div>
          <p className="text-xs text-muted-foreground">
            {rewardsByLevel.length} levels configured
          </p>
        </CardContent>
      </Card>

      {/* Rewards Table */}
      <div className="rounded-lg border border-border overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/50">
              <th className="px-4 py-3 text-left font-medium text-muted-foreground w-20">
                Level
              </th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">
                Free Reward
              </th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">
                Premium Reward
              </th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground w-20">
                Actions
              </th>
            </tr>
          </thead>
          <tbody>
            {rewardsByLevel.length === 0 ? (
              <tr>
                <td colSpan={4} className="px-4 py-8 text-center text-muted-foreground">
                  No rewards configured. Use "Generate Default Rewards" or "Add Reward" to
                  get started.
                </td>
              </tr>
            ) : (
              rewardsByLevel.map(({ level, free, premium }) => (
                <tr
                  key={`level-${level}`}
                  className="border-b border-border hover:bg-muted/50"
                >
                  <td className="px-4 py-3 font-medium">{level}</td>
                  <td className="px-4 py-3">
                    {free ? (
                      <RewardCell
                        reward={free}
                        editing={editing}
                        onEdit={setEditing}
                        onUpdate={handleUpdateReward}
                        onDelete={handleDeleteReward}
                        isLoading={isLoading}
                      />
                    ) : (
                      <span className="text-muted-foreground text-xs">—</span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {premium ? (
                      <RewardCell
                        reward={premium}
                        editing={editing}
                        onEdit={setEditing}
                        onUpdate={handleUpdateReward}
                        onDelete={handleDeleteReward}
                        isLoading={isLoading}
                      />
                    ) : (
                      <span className="text-muted-foreground text-xs">—</span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {free && (
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDeleteReward(free.id)}
                        disabled={isLoading}
                      >
                        <Trash2 className="h-4 w-4 text-red-400" />
                      </Button>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function RewardCell({
  reward,
  editing,
  onEdit,
  onUpdate,
  onDelete,
  isLoading,
}: {
  reward: BattlePassReward
  editing: EditingState | null
  onEdit: (state: EditingState | null) => void
  onUpdate: (rewardId: string, field: string, value: unknown) => Promise<void>
  onDelete: (rewardId: string) => Promise<void>
  isLoading: boolean
}) {
  const isEditingType = editing?.rewardId === reward.id && editing?.field === 'rewardType'
  const isEditingAmount =
    editing?.rewardId === reward.id && editing?.field === 'rewardAmount'

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-2">
        {isEditingType ? (
          <Input
            autoFocus
            value={editing.value}
            onChange={(e) =>
              onEdit({
                rewardId: reward.id,
                field: 'rewardType',
                value: e.target.value,
              })
            }
            onBlur={() => {
              onUpdate(reward.id, 'rewardType', editing.value)
            }}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                onUpdate(reward.id, 'rewardType', editing.value)
              } else if (e.key === 'Escape') {
                onEdit(null)
              }
            }}
            className="h-7 w-20 text-xs"
          />
        ) : (
          <Badge
            variant="outline"
            className="cursor-pointer hover:bg-muted"
            onClick={() =>
              onEdit({
                rewardId: reward.id,
                field: 'rewardType',
                value: reward.rewardType,
              })
            }
          >
            {reward.rewardType}
          </Badge>
        )}

        {isEditingAmount ? (
          <Input
            autoFocus
            type="number"
            value={editing.value}
            onChange={(e) =>
              onEdit({
                rewardId: reward.id,
                field: 'rewardAmount',
                value: parseInt(e.target.value, 10) || 0,
              })
            }
            onBlur={() => {
              onUpdate(reward.id, 'rewardAmount', editing.value)
            }}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                onUpdate(reward.id, 'rewardAmount', editing.value)
              } else if (e.key === 'Escape') {
                onEdit(null)
              }
            }}
            className="h-7 w-16 text-xs"
          />
        ) : (
          <span
            className="text-xs cursor-pointer hover:underline"
            onClick={() =>
              onEdit({
                rewardId: reward.id,
                field: 'rewardAmount',
                value: reward.rewardAmount,
              })
            }
          >
            ×{reward.rewardAmount}
          </span>
        )}
      </div>
    </div>
  )
}

function AddRewardForm({
  onSubmit,
  isLoading,
  existingLevels,
}: {
  onSubmit: (data: {
    bpLevel: number
    isPremium: boolean
    rewardType: string
    rewardAmount: number
  }) => Promise<void>
  isLoading: boolean
  existingLevels: number[]
}) {
  const [level, setLevel] = useState('1')
  const [isPremium, setIsPremium] = useState(false)
  const [rewardType, setRewardType] = useState('gold')
  const [amount, setAmount] = useState('100')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const numLevel = parseInt(level, 10)
    const numAmount = parseInt(amount, 10)

    if (!numLevel || numAmount < 1) {
      toast.error('Invalid input')
      return
    }

    await onSubmit({
      bpLevel: numLevel,
      isPremium,
      rewardType,
      rewardAmount: numAmount,
    })
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="text-sm font-medium">Level</label>
        <Input
          type="number"
          value={level}
          onChange={(e) => setLevel(e.target.value)}
          min="1"
          max="500"
        />
      </div>

      <div>
        <label className="text-sm font-medium">Track</label>
        <Select
          value={isPremium ? 'premium' : 'free'}
          onValueChange={(v) => setIsPremium(v === 'premium')}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="free">Free</SelectItem>
            <SelectItem value="premium">Premium</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div>
        <label className="text-sm font-medium">Reward Type</label>
        <Select value={rewardType} onValueChange={setRewardType}>
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="gold">Gold</SelectItem>
            <SelectItem value="gems">Gems</SelectItem>
            <SelectItem value="xp">XP</SelectItem>
            <SelectItem value="cosmetic">Cosmetic</SelectItem>
            <SelectItem value="chest">Chest</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div>
        <label className="text-sm font-medium">Amount</label>
        <Input
          type="number"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          min="1"
        />
      </div>

      <Button type="submit" disabled={isLoading} className="w-full">
        Create Reward
      </Button>
    </form>
  )
}
