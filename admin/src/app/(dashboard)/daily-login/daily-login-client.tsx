'use client'

import { useState, useCallback } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from '@/components/ui/dialog'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { updateConfig } from '@/actions/config'
import { useToast } from '@/hooks/use-toast'

interface DailyLoginReward {
  type: 'gold' | 'gems' | 'consumable'
  amount: number
  itemId?: string
}

interface DailyLoginClientProps {
  rewards: DailyLoginReward[]
}

const CONSUMABLE_TYPES = [
  { id: 'stamina_potion_small', name: 'Small Stamina Potion' },
  { id: 'stamina_potion_medium', name: 'Medium Stamina Potion' },
  { id: 'stamina_potion_large', name: 'Large Stamina Potion' },
  { id: 'health_potion_small', name: 'Small Health Potion' },
  { id: 'health_potion_medium', name: 'Medium Health Potion' },
  { id: 'health_potion_large', name: 'Large Health Potion' },
]

export function DailyLoginClient({ rewards: initialRewards }: DailyLoginClientProps) {
  const [rewards, setRewards] = useState<DailyLoginReward[]>(initialRewards)
  const [editingDay, setEditingDay] = useState<number | null>(null)
  const [editForm, setEditForm] = useState<DailyLoginReward>({ type: 'gold', amount: 0 })
  const [isLoading, setIsLoading] = useState(false)
  const { toast } = useToast()

  const defaultRewards = [
    { type: 'gold' as const, amount: 200 },
    { type: 'consumable' as const, amount: 1, itemId: 'stamina_potion_small' },
    { type: 'gold' as const, amount: 500 },
    { type: 'consumable' as const, amount: 2, itemId: 'stamina_potion_small' },
    { type: 'gold' as const, amount: 1000 },
    { type: 'consumable' as const, amount: 1, itemId: 'stamina_potion_large' },
    { type: 'gems' as const, amount: 5 },
  ]

  const handleOpenEdit = (day: number) => {
    setEditingDay(day)
    setEditForm(rewards[day] || { type: 'gold', amount: 0 })
  }

  const handleSaveReward = useCallback(async () => {
    if (editingDay === null) return

    const newRewards = [...rewards]
    newRewards[editingDay] = editForm
    setRewards(newRewards)
    setEditingDay(null)

    setIsLoading(true)
    try {
      // updateConfig is a server action and will handle auth
      await updateConfig('daily_login_rewards', newRewards)
      toast({ title: 'Success', description: `Day ${editingDay + 1} reward updated` })
    } catch (error: any) {
      toast({ title: 'Error', description: error.message, variant: 'destructive' })
      // Revert change
      setRewards(rewards)
    } finally {
      setIsLoading(false)
    }
  }, [editingDay, editForm, rewards, toast])

  const handleReset = useCallback(async () => {
    setRewards(defaultRewards)
    setIsLoading(true)
    try {
      // updateConfig is a server action and will handle auth
      await updateConfig('daily_login_rewards', defaultRewards)
      toast({ title: 'Success', description: 'Daily login rewards reset to defaults' })
    } catch (error: any) {
      toast({ title: 'Error', description: error.message, variant: 'destructive' })
      setRewards(rewards)
    } finally {
      setIsLoading(false)
    }
  }, [defaultRewards, rewards, toast])

  const getRewardDisplay = (reward: DailyLoginReward): string => {
    if (reward.type === 'gold') return `${reward.amount} Gold`
    if (reward.type === 'gems') return `${reward.amount} Gems`
    const consumable = CONSUMABLE_TYPES.find(c => c.id === reward.itemId)
    return `${reward.amount}x ${consumable?.name || 'Unknown'}`
  }

  const getRewardColor = (type: 'gold' | 'gems' | 'consumable'): string => {
    if (type === 'gold') return 'bg-yellow-500/20 text-yellow-700 dark:text-yellow-300'
    if (type === 'gems') return 'bg-purple-500/20 text-purple-700 dark:text-purple-300'
    return 'bg-blue-500/20 text-blue-700 dark:text-blue-300'
  }

  return (
    <div className="space-y-4">
      <div className="flex gap-2">
        <Button variant="outline" onClick={handleReset} disabled={isLoading}>
          Reset to Defaults
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {rewards.map((reward, day) => (
          <Card key={day} className="relative">
            <CardHeader className="pb-3">
              <CardTitle className="text-lg">Day {day + 1}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Badge className={`${getRewardColor(reward.type)} border-0`}>
                  {getRewardDisplay(reward)}
                </Badge>
              </div>
              <Dialog>
                <DialogTrigger asChild>
                  <Button
                    variant="outline"
                    size="sm"
                    className="w-full"
                    onClick={() => handleOpenEdit(day)}
                  >
                    Edit
                  </Button>
                </DialogTrigger>
                <DialogContent>
                  <DialogHeader>
                    <DialogTitle>Edit Day {day + 1} Reward</DialogTitle>
                  </DialogHeader>
                  <div className="space-y-4">
                    <div>
                      <Label>Reward Type</Label>
                      <Select
                        value={editForm.type}
                        onValueChange={(value: any) => {
                          const newForm = { ...editForm, type: value }
                          if (value === 'consumable' && !newForm.itemId) {
                            newForm.itemId = 'stamina_potion_small'
                          }
                          setEditForm(newForm)
                        }}
                      >
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="gold">Gold</SelectItem>
                          <SelectItem value="gems">Gems</SelectItem>
                          <SelectItem value="consumable">Consumable</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    <div>
                      <Label>Amount</Label>
                      <Input
                        type="number"
                        value={editForm.amount}
                        onChange={(e) =>
                          setEditForm({ ...editForm, amount: parseInt(e.target.value) || 0 })
                        }
                        min="1"
                      />
                    </div>

                    {editForm.type === 'consumable' && (
                      <div>
                        <Label>Consumable Type</Label>
                        <Select
                          value={editForm.itemId || ''}
                          onValueChange={(value) =>
                            setEditForm({ ...editForm, itemId: value })
                          }
                        >
                          <SelectTrigger>
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            {CONSUMABLE_TYPES.map((c) => (
                              <SelectItem key={c.id} value={c.id}>
                                {c.name}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>
                    )}
                  </div>
                  <DialogFooter>
                    <Button
                      variant="outline"
                      onClick={() => setEditingDay(null)}
                    >
                      Cancel
                    </Button>
                    <Button onClick={handleSaveReward} disabled={isLoading}>
                      {isLoading ? 'Saving...' : 'Save'}
                    </Button>
                  </DialogFooter>
                </DialogContent>
              </Dialog>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Preview</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-sm space-y-2">
            <p>Players receive one of these rewards each day for 7 consecutive days:</p>
            <ul className="list-disc list-inside space-y-1">
              {rewards.map((reward, i) => (
                <li key={i}>
                  Day {i + 1}: {getRewardDisplay(reward)}
                </li>
              ))}
            </ul>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
