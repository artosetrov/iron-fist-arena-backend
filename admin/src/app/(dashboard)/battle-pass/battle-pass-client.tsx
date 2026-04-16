'use client'

import { useMemo, useState } from 'react'
import { Trash2, Plus, Wand2, Gift } from 'lucide-react'
import { toast } from 'sonner'
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
  bulkCreateBattlePassRewards,
  createBattlePassReward,
  deleteBattlePassReward,
  getBattlePassRewards,
  updateBattlePassReward,
} from '@/actions/battle-pass-rewards'
import {
  BATTLE_PASS_REWARD_TYPES,
  battlePassRewardTypeRequiresId,
  type BattlePassRewardRecord,
  type BattlePassRewardType,
  type SeasonRecord,
} from '@/lib/battle-pass-rewards'

type BattlePassReward = BattlePassRewardRecord
type Season = SeasonRecord

type EditingField = 'rewardType' | 'rewardAmount' | 'rewardId'

type EditingState = {
  rewardId: string
  field: EditingField
  value: string | number
}

function getErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message : 'Request failed'
}

function sortRewards(rewards: BattlePassReward[]): BattlePassReward[] {
  return [...rewards].sort((left, right) => {
    if (left.seasonId !== right.seasonId) {
      return left.seasonId.localeCompare(right.seasonId)
    }

    if (left.bpLevel !== right.bpLevel) {
      return left.bpLevel - right.bpLevel
    }

    return Number(left.isPremium) - Number(right.isPremium)
  })
}

function parseOptionalRewardId(value: string): string | undefined {
  const normalized = value.trim()
  return normalized.length > 0 ? normalized : undefined
}

function parseRewardTypeForIdRequirement(
  value: string
): BattlePassRewardType | null {
  if (BATTLE_PASS_REWARD_TYPES.includes(value as BattlePassRewardType)) {
    return value as BattlePassRewardType
  }

  return null
}

export function BattlePassClient({
  rewards: initialRewards,
  seasons,
}: {
  rewards: BattlePassReward[]
  seasons: Season[]
}) {
  const [rewards, setRewards] = useState<BattlePassReward[]>(
    sortRewards(initialRewards)
  )
  const [selectedSeasonId, setSelectedSeasonId] = useState<string>(
    seasons[0]?.id || ''
  )
  const [isAddOpen, setIsAddOpen] = useState(false)
  const [isBulkOpen, setIsBulkOpen] = useState(false)
  const [bulkMaxLevel, setBulkMaxLevel] = useState('50')
  const [editing, setEditing] = useState<EditingState | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const seasonRewards = useMemo(() => {
    return rewards.filter((reward) => reward.seasonId === selectedSeasonId)
  }, [rewards, selectedSeasonId])

  const selectedSeason = seasons.find((season) => season.id === selectedSeasonId)

  const rewardsByLevel = useMemo(() => {
    const map = new Map<number, { free?: BattlePassReward; premium?: BattlePassReward }>()

    for (const reward of seasonRewards) {
      if (!map.has(reward.bpLevel)) {
        map.set(reward.bpLevel, {})
      }

      const levelRewards = map.get(reward.bpLevel)
      if (!levelRewards) continue

      if (reward.isPremium) {
        levelRewards.premium = reward
      } else {
        levelRewards.free = reward
      }
    }

    return Array.from(map.entries())
      .sort((left, right) => left[0] - right[0])
      .map(([level, levelRewards]) => ({ level, ...levelRewards }))
  }, [seasonRewards])

  const refreshSeasonRewards = async (seasonId: string) => {
    const refreshed = await getBattlePassRewards(seasonId)
    setRewards((current) =>
      sortRewards([
        ...current.filter((reward) => reward.seasonId !== seasonId),
        ...(refreshed as BattlePassReward[]),
      ])
    )
  }

  const handleAddReward = async (data: {
    bpLevel: number
    isPremium: boolean
    rewardType: BattlePassRewardType
    rewardId?: string
    rewardAmount: number
  }) => {
    if (!selectedSeasonId) {
      toast.error('Select a season first')
      return
    }

    setIsLoading(true)
    try {
      await createBattlePassReward({
        seasonId: selectedSeasonId,
        ...data,
      })
      await refreshSeasonRewards(selectedSeasonId)
      setIsAddOpen(false)
      toast.success('Reward created')
    } catch (error) {
      toast.error(getErrorMessage(error))
    } finally {
      setIsLoading(false)
    }
  }

  const handleUpdateReward = async (
    rewardId: string,
    field: EditingField,
    value: string | number
  ) => {
    if (!selectedSeasonId) {
      toast.error('Select a season first')
      return
    }

    setIsLoading(true)
    try {
      await updateBattlePassReward(rewardId, {
        ...(field === 'rewardType' && { rewardType: String(value) }),
        ...(field === 'rewardAmount' && { rewardAmount: Number(value) }),
        ...(field === 'rewardId' && { rewardId: String(value) }),
      })
      await refreshSeasonRewards(selectedSeasonId)
      setEditing(null)
      toast.success('Reward updated')
    } catch (error) {
      toast.error(getErrorMessage(error))
    } finally {
      setIsLoading(false)
    }
  }

  const handleDeleteReward = async (rewardId: string) => {
    if (!confirm('Delete this reward?')) return
    if (!selectedSeasonId) {
      toast.error('Select a season first')
      return
    }

    setIsLoading(true)
    try {
      await deleteBattlePassReward(rewardId)
      await refreshSeasonRewards(selectedSeasonId)
      toast.success('Reward deleted')
    } catch (error) {
      toast.error(getErrorMessage(error))
    } finally {
      setIsLoading(false)
    }
  }

  const handleBulkCreate = async () => {
    if (!selectedSeasonId) {
      toast.error('Select a season first')
      return
    }

    const level = Number.parseInt(bulkMaxLevel, 10)
    if (!level || level < 1) {
      toast.error('Invalid max level')
      return
    }

    setIsLoading(true)
    try {
      await bulkCreateBattlePassRewards(selectedSeasonId, level)
      await refreshSeasonRewards(selectedSeasonId)
      setIsBulkOpen(false)
      toast.success('Default rewards generated')
    } catch (error) {
      toast.error(getErrorMessage(error))
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center gap-4">
            <div className="flex-1">
              <label className="text-sm font-medium text-muted-foreground">
                Season
              </label>
              <Select value={selectedSeasonId} onValueChange={setSelectedSeasonId}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {seasons.map((season) => (
                    <SelectItem key={season.id} value={season.id}>
                      {season.theme || `Season ${season.number}`}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <Dialog open={isBulkOpen} onOpenChange={setIsBulkOpen}>
              <DialogTrigger asChild>
                <Button
                  variant="outline"
                  className="mt-6"
                  disabled={!selectedSeasonId}
                >
                  <Wand2 className="mr-2 h-4 w-4" />
                  Generate Default Rewards
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Generate Default Rewards</DialogTitle>
                  <DialogDescription>
                    Create default free and premium rewards for all levels up to
                    the specified maximum. Existing rewards will be skipped.
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4">
                  <div>
                    <label className="text-sm font-medium">Max Level</label>
                    <Input
                      type="number"
                      value={bulkMaxLevel}
                      onChange={(event) => setBulkMaxLevel(event.target.value)}
                      min="1"
                      max="500"
                    />
                  </div>
                  <Button
                    onClick={handleBulkCreate}
                    disabled={isLoading || !selectedSeasonId}
                    className="w-full"
                  >
                    Generate
                  </Button>
                </div>
              </DialogContent>
            </Dialog>

            <Dialog open={isAddOpen} onOpenChange={setIsAddOpen}>
              <DialogTrigger asChild>
                <Button className="mt-6" disabled={!selectedSeasonId}>
                  <Plus className="mr-2 h-4 w-4" />
                  Add Reward
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Add Reward</DialogTitle>
                </DialogHeader>
                <AddRewardForm onSubmit={handleAddReward} isLoading={isLoading} />
              </DialogContent>
            </Dialog>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium">
            {selectedSeason?.theme || `Season ${selectedSeason?.number}`} Rewards
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

      <div className="overflow-hidden rounded-lg border border-border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/50">
              <th className="w-20 px-4 py-3 text-left font-medium text-muted-foreground">
                Level
              </th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">
                Free Reward
              </th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">
                Premium Reward
              </th>
            </tr>
          </thead>
          <tbody>
            {rewardsByLevel.length === 0 ? (
              <tr>
                <td
                  colSpan={3}
                  className="px-4 py-8 text-center text-muted-foreground"
                >
                  No rewards configured. Use `Generate Default Rewards` or `Add
                  Reward` to get started.
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
                      <span className="text-xs text-muted-foreground">—</span>
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
                      <span className="text-xs text-muted-foreground">—</span>
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
  onUpdate: (
    rewardId: string,
    field: EditingField,
    value: string | number
  ) => Promise<void>
  onDelete: (rewardId: string) => Promise<void>
  isLoading: boolean
}) {
  const isEditingType =
    editing?.rewardId === reward.id && editing.field === 'rewardType'
  const isEditingAmount =
    editing?.rewardId === reward.id && editing.field === 'rewardAmount'
  const isEditingRewardId =
    editing?.rewardId === reward.id && editing.field === 'rewardId'
  const rewardType = parseRewardTypeForIdRequirement(reward.rewardType)
  const rewardIdRequired = rewardType
    ? battlePassRewardTypeRequiresId(rewardType)
    : false

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap items-center gap-2">
        {isEditingType ? (
          <Select
            value={String(editing.value)}
            onValueChange={(value) => {
              onEdit({
                rewardId: reward.id,
                field: 'rewardType',
                value,
              })
              void onUpdate(reward.id, 'rewardType', value)
            }}
          >
            <SelectTrigger className="h-7 w-[150px] text-xs">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {BATTLE_PASS_REWARD_TYPES.map((type) => (
                <SelectItem key={type} value={type}>
                  {type}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
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
            min="1"
            onChange={(event) =>
              onEdit({
                rewardId: reward.id,
                field: 'rewardAmount',
                value: Number.parseInt(event.target.value, 10) || 0,
              })
            }
            onBlur={() => {
              void onUpdate(reward.id, 'rewardAmount', editing.value)
            }}
            onKeyDown={(event) => {
              if (event.key === 'Enter') {
                void onUpdate(reward.id, 'rewardAmount', editing.value)
              } else if (event.key === 'Escape') {
                onEdit(null)
              }
            }}
            className="h-7 w-20 text-xs"
          />
        ) : (
          <button
            type="button"
            className="text-xs hover:underline"
            onClick={() =>
              onEdit({
                rewardId: reward.id,
                field: 'rewardAmount',
                value: reward.rewardAmount,
              })
            }
          >
            ×{reward.rewardAmount}
          </button>
        )}

        <Button
          variant="ghost"
          size="sm"
          onClick={() => void onDelete(reward.id)}
          disabled={isLoading}
          className="h-7 px-2"
        >
          <Trash2 className="h-4 w-4 text-red-400" />
        </Button>
      </div>

      <div className="flex items-center gap-2 text-xs">
        <span className="text-muted-foreground">Reward ID</span>
        {isEditingRewardId ? (
          <Input
            autoFocus
            value={String(editing.value)}
            onChange={(event) =>
              onEdit({
                rewardId: reward.id,
                field: 'rewardId',
                value: event.target.value,
              })
            }
            onBlur={() => {
              void onUpdate(reward.id, 'rewardId', String(editing.value))
            }}
            onKeyDown={(event) => {
              if (event.key === 'Enter') {
                void onUpdate(reward.id, 'rewardId', String(editing.value))
              } else if (event.key === 'Escape') {
                onEdit(null)
              }
            }}
            className="h-7 w-[180px] text-xs"
          />
        ) : (
          <button
            type="button"
            className={`truncate text-left ${
              rewardIdRequired && !reward.rewardId
                ? 'text-red-500 hover:underline'
                : 'text-muted-foreground hover:underline'
            }`}
            onClick={() =>
              onEdit({
                rewardId: reward.id,
                field: 'rewardId',
                value: reward.rewardId ?? '',
              })
            }
          >
            {reward.rewardId ?? (rewardIdRequired ? 'Set required reward ID' : 'No reward ID')}
          </button>
        )}
      </div>
    </div>
  )
}

function AddRewardForm({
  onSubmit,
  isLoading,
}: {
  onSubmit: (data: {
    bpLevel: number
    isPremium: boolean
    rewardType: BattlePassRewardType
    rewardId?: string
    rewardAmount: number
  }) => Promise<void>
  isLoading: boolean
}) {
  const [level, setLevel] = useState('1')
  const [isPremium, setIsPremium] = useState(false)
  const [rewardType, setRewardType] = useState<BattlePassRewardType>('gold')
  const [rewardId, setRewardId] = useState('')
  const [amount, setAmount] = useState('100')
  const requiresRewardId = battlePassRewardTypeRequiresId(rewardType)

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault()
    const numLevel = Number.parseInt(level, 10)
    const numAmount = Number.parseInt(amount, 10)

    if (!numLevel || numAmount < 1) {
      toast.error('Invalid input')
      return
    }

    await onSubmit({
      bpLevel: numLevel,
      isPremium,
      rewardType,
      rewardId: parseOptionalRewardId(rewardId),
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
          onChange={(event) => setLevel(event.target.value)}
          min="1"
          max="500"
        />
      </div>

      <div>
        <label className="text-sm font-medium">Track</label>
        <Select
          value={isPremium ? 'premium' : 'free'}
          onValueChange={(value) => setIsPremium(value === 'premium')}
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
        <Select
          value={rewardType}
          onValueChange={(value) => {
            setRewardType(value as BattlePassRewardType)
            if (
              !battlePassRewardTypeRequiresId(value as BattlePassRewardType)
            ) {
              setRewardId('')
            }
          }}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {BATTLE_PASS_REWARD_TYPES.map((type) => (
              <SelectItem key={type} value={type}>
                {type}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div>
        <label className="text-sm font-medium">Reward ID</label>
        <Input
          value={rewardId}
          onChange={(event) => setRewardId(event.target.value)}
          placeholder={
            requiresRewardId
              ? 'Required for this reward type'
              : 'Optional for this reward type'
          }
        />
      </div>

      <div>
        <label className="text-sm font-medium">Amount</label>
        <Input
          type="number"
          value={amount}
          onChange={(event) => setAmount(event.target.value)}
          min="1"
        />
      </div>

      <Button type="submit" disabled={isLoading} className="w-full">
        Create Reward
      </Button>
    </form>
  )
}
