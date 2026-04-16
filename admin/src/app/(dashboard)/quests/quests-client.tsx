'use client'

import { useState } from 'react'
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
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import {
  createQuestDefinition,
  updateQuestDefinition,
  deleteQuestDefinition,
  seedQuestDefinitions,
  getQuestDefinitions,
} from '@/actions/quest-definitions'
import { useToast } from '@/hooks/use-toast'
import type { QuestDefinitionRecord } from '@/lib/quest-definitions'

interface QuestsClientProps {
  initialQuests: QuestDefinitionRecord[]
}

export function QuestsClient({ initialQuests }: QuestsClientProps) {
  const [quests, setQuests] = useState(initialQuests)
  const [isOpen, setIsOpen] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const { toast } = useToast()

  const [formData, setFormData] = useState({
    questType: '',
    title: '',
    description: '',
    icon: '',
    minTarget: 1,
    maxTarget: 5,
    rewardGold: 0,
    rewardXp: 0,
    rewardGems: 0,
  })

  const handleOpenDialog = (quest?: QuestDefinitionRecord) => {
    if (quest) {
      setFormData({
        questType: quest.questType,
        title: quest.title,
        description: quest.description,
        icon: quest.icon,
        minTarget: quest.minTarget,
        maxTarget: quest.maxTarget,
        rewardGold: quest.rewardGold,
        rewardXp: quest.rewardXp,
        rewardGems: quest.rewardGems,
      })
      setEditingId(quest.id)
    } else {
      setFormData({
        questType: '',
        title: '',
        description: '',
        icon: '',
        minTarget: 1,
        maxTarget: 5,
        rewardGold: 0,
        rewardXp: 0,
        rewardGems: 0,
      })
      setEditingId(null)
    }
    setIsOpen(true)
  }

  const getErrorMessage = (error: unknown) =>
    error instanceof Error ? error.message : 'Request failed'

  const sortQuests = (items: QuestDefinitionRecord[]) =>
    [...items].sort((left, right) => left.questType.localeCompare(right.questType))

  const parseWholeNumberInput = (value: string) => {
    const parsed = Number.parseInt(value, 10)
    return Number.isInteger(parsed) ? parsed : 0
  }

  const handleSave = async () => {
    if (!formData.questType || !formData.title || !formData.description) {
      toast({ title: 'Error', description: 'Quest Type, Title, and Description are required', variant: 'destructive' })
      return
    }

    setIsLoading(true)
    try {
      if (editingId) {
        const updated = await updateQuestDefinition(editingId, {
          title: formData.title,
          description: formData.description,
          icon: formData.icon,
          minTarget: formData.minTarget,
          maxTarget: formData.maxTarget,
          rewardGold: formData.rewardGold,
          rewardXp: formData.rewardXp,
          rewardGems: formData.rewardGems,
        })
        setQuests((current) =>
          sortQuests(current.map((quest) => (quest.id === editingId ? updated : quest)))
        )
        toast({ title: 'Success', description: 'Quest updated' })
      } else {
        const created = await createQuestDefinition({
          questType: formData.questType,
          title: formData.title,
          description: formData.description,
          icon: formData.icon,
          minTarget: formData.minTarget,
          maxTarget: formData.maxTarget,
          rewardGold: formData.rewardGold,
          rewardXp: formData.rewardXp,
          rewardGems: formData.rewardGems,
        })
        setQuests((current) => sortQuests([...current, created]))
        toast({ title: 'Success', description: 'Quest created' })
      }
      setIsOpen(false)
    } catch (error) {
      toast({ title: 'Error', description: getErrorMessage(error), variant: 'destructive' })
    } finally {
      setIsLoading(false)
    }
  }

  const handleDelete = async () => {
    if (!deleteId) return
    setIsLoading(true)
    try {
      await deleteQuestDefinition(deleteId)
      setQuests((current) => current.filter((quest) => quest.id !== deleteId))
      toast({ title: 'Success', description: 'Quest deleted' })
      setDeleteId(null)
    } catch (error) {
      toast({ title: 'Error', description: getErrorMessage(error), variant: 'destructive' })
    } finally {
      setIsLoading(false)
    }
  }

  const handleSeed = async () => {
    setIsLoading(true)
    try {
      await seedQuestDefinitions()
      const newQuests = await getQuestDefinitions()
      setQuests(sortQuests(newQuests))
      toast({ title: 'Success', description: 'Quest definitions seeded' })
    } catch (error) {
      toast({ title: 'Error', description: getErrorMessage(error), variant: 'destructive' })
    } finally {
      setIsLoading(false)
    }
  }

  const handleToggleActive = async (quest: QuestDefinitionRecord) => {
    setIsLoading(true)
    try {
      const updated = await updateQuestDefinition(quest.id, {
        active: !quest.active,
      })
      setQuests((current) =>
        sortQuests(current.map((item) => (item.id === quest.id ? updated : item)))
      )
      toast({
        title: 'Success',
        description: updated.active ? 'Quest activated' : 'Quest deactivated',
      })
    } catch (error) {
      toast({ title: 'Error', description: getErrorMessage(error), variant: 'destructive' })
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex gap-2">
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
          <DialogTrigger asChild>
            <Button onClick={() => handleOpenDialog()}>Add Quest</Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>{editingId ? 'Edit Quest' : 'Create Quest'}</DialogTitle>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <Label>Quest Type</Label>
                <Input
                  disabled={!!editingId}
                  value={formData.questType}
                  onChange={(e) => setFormData({ ...formData, questType: e.target.value })}
                  placeholder="e.g. pvp_wins"
                />
              </div>
              <div>
                <Label>Title</Label>
                <Input
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  placeholder="e.g. Warrior"
                />
              </div>
              <div>
                <Label>Description</Label>
                <Input
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="e.g. Win PvP battles"
                />
              </div>
              <div>
                <Label>Icon</Label>
                <Input
                  value={formData.icon}
                  onChange={(e) => setFormData({ ...formData, icon: e.target.value })}
                  placeholder="e.g. ⚔️"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Min Target</Label>
                  <Input
                    type="number"
                    value={formData.minTarget}
                    min="1"
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        minTarget: parseWholeNumberInput(e.target.value),
                      })
                    }
                  />
                </div>
                <div>
                  <Label>Max Target</Label>
                  <Input
                    type="number"
                    value={formData.maxTarget}
                    min="1"
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        maxTarget: parseWholeNumberInput(e.target.value),
                      })
                    }
                  />
                </div>
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <Label>Gold Reward</Label>
                  <Input
                    type="number"
                    value={formData.rewardGold}
                    min="0"
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        rewardGold: parseWholeNumberInput(e.target.value),
                      })
                    }
                  />
                </div>
                <div>
                  <Label>XP Reward</Label>
                  <Input
                    type="number"
                    value={formData.rewardXp}
                    min="0"
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        rewardXp: parseWholeNumberInput(e.target.value),
                      })
                    }
                  />
                </div>
                <div>
                  <Label>Gems Reward</Label>
                  <Input
                    type="number"
                    value={formData.rewardGems}
                    min="0"
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        rewardGems: parseWholeNumberInput(e.target.value),
                      })
                    }
                  />
                </div>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setIsOpen(false)}>Cancel</Button>
              <Button onClick={handleSave} disabled={isLoading}>{isLoading ? 'Saving...' : 'Save'}</Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
        <Button variant="outline" onClick={handleSeed} disabled={isLoading}>
          Seed Defaults
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Quests ({quests.length})</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Type</TableHead>
                <TableHead>Title</TableHead>
                <TableHead>Icon</TableHead>
                <TableHead>Target Range</TableHead>
                <TableHead>Gold</TableHead>
                <TableHead>XP</TableHead>
                <TableHead>Gems</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {quests.map((quest) => (
                <TableRow key={quest.id}>
                  <TableCell className="font-mono text-sm">{quest.questType}</TableCell>
                  <TableCell>{quest.title}</TableCell>
                  <TableCell>{quest.icon}</TableCell>
                  <TableCell className="text-sm">{quest.minTarget}-{quest.maxTarget}</TableCell>
                  <TableCell className="text-sm">{quest.rewardGold}</TableCell>
                  <TableCell className="text-sm">{quest.rewardXp}</TableCell>
                  <TableCell className="text-sm">{quest.rewardGems}</TableCell>
                  <TableCell>
                    <Badge variant={quest.active ? 'default' : 'secondary'}>
                      {quest.active ? 'Active' : 'Inactive'}
                    </Badge>
                  </TableCell>
                  <TableCell className="space-x-2">
                    <Button
                      variant="secondary"
                      size="sm"
                      onClick={() => handleToggleActive(quest)}
                      disabled={isLoading}
                    >
                      {quest.active ? 'Deactivate' : 'Activate'}
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleOpenDialog(quest)}
                    >
                      Edit
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      onClick={() => setDeleteId(quest.id)}
                    >
                      Delete
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <AlertDialog open={!!deleteId} onOpenChange={(open) => !open && setDeleteId(null)}>
        <AlertDialogContent>
          <AlertDialogTitle>Delete Quest</AlertDialogTitle>
          <AlertDialogDescription>
            Are you sure? This cannot be undone.
          </AlertDialogDescription>
          <AlertDialogCancel>Cancel</AlertDialogCancel>
          <AlertDialogAction onClick={handleDelete} disabled={isLoading}>
            {isLoading ? 'Deleting...' : 'Delete'}
          </AlertDialogAction>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
