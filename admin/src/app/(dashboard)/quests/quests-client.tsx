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
import { createQuestDefinition, updateQuestDefinition, deleteQuestDefinition, seedQuestDefinitions, getQuestDefinitions } from '@/actions/quest-definitions'
import { useToast } from '@/hooks/use-toast'

interface QuestDefinition {
  id: string
  questType: string
  title: string
  description: string
  icon: string
  minTarget: number
  maxTarget: number
  rewardGold: number
  rewardXp: number
  rewardGems: number
  active: boolean
}

interface QuestsClientProps {
  initialQuests: QuestDefinition[]
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

  const handleOpenDialog = (quest?: QuestDefinition) => {
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

  const handleSave = async () => {
    if (!formData.questType || !formData.title || !formData.description) {
      toast({ title: 'Error', description: 'Quest Type, Title, and Description are required', variant: 'destructive' })
      return
    }

    setIsLoading(true)
    try {
      if (editingId) {
        const existing = quests.find(q => q.id === editingId)
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
        setQuests(quests.map(q => q.id === editingId ? updated : q))
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
        setQuests([...quests, created])
        toast({ title: 'Success', description: 'Quest created' })
      }
      setIsOpen(false)
    } catch (error: any) {
      toast({ title: 'Error', description: error.message, variant: 'destructive' })
    } finally {
      setIsLoading(false)
    }
  }

  const handleDelete = async () => {
    if (!deleteId) return
    setIsLoading(true)
    try {
      await deleteQuestDefinition(deleteId)
      setQuests(quests.filter(q => q.id !== deleteId))
      toast({ title: 'Success', description: 'Quest deleted' })
      setDeleteId(null)
    } catch (error: any) {
      toast({ title: 'Error', description: error.message, variant: 'destructive' })
    } finally {
      setIsLoading(false)
    }
  }

  const handleSeed = async () => {
    setIsLoading(true)
    try {
      await seedQuestDefinitions()
      const newQuests = await getQuestDefinitions()
      setQuests(newQuests)
      toast({ title: 'Success', description: 'Quest definitions seeded' })
    } catch (error: any) {
      toast({ title: 'Error', description: error.message, variant: 'destructive' })
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
                    onChange={(e) => setFormData({ ...formData, minTarget: parseInt(e.target.value) || 0 })}
                  />
                </div>
                <div>
                  <Label>Max Target</Label>
                  <Input
                    type="number"
                    value={formData.maxTarget}
                    onChange={(e) => setFormData({ ...formData, maxTarget: parseInt(e.target.value) || 0 })}
                  />
                </div>
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <Label>Gold Reward</Label>
                  <Input
                    type="number"
                    value={formData.rewardGold}
                    onChange={(e) => setFormData({ ...formData, rewardGold: parseInt(e.target.value) || 0 })}
                  />
                </div>
                <div>
                  <Label>XP Reward</Label>
                  <Input
                    type="number"
                    value={formData.rewardXp}
                    onChange={(e) => setFormData({ ...formData, rewardXp: parseInt(e.target.value) || 0 })}
                  />
                </div>
                <div>
                  <Label>Gems Reward</Label>
                  <Input
                    type="number"
                    value={formData.rewardGems}
                    onChange={(e) => setFormData({ ...formData, rewardGems: parseInt(e.target.value) || 0 })}
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
