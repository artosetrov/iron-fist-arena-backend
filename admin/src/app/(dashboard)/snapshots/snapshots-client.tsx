'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import {
  createConfigSnapshot,
  rollbackToSnapshot,
  deleteConfigSnapshot,
  getConfigSnapshot,
} from '@/actions/snapshots'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Separator } from '@/components/ui/separator'
import { Badge } from '@/components/ui/badge'
import { Save, Trash2, RotateCcw, Plus, AlertCircle, CheckCircle2 } from 'lucide-react'

type Snapshot = {
  id: string
  name: string
  description: string | null
  createdBy: string
  createdAt: string
  configCount: number
}

export function SnapshotsClient({ snapshots, adminId }: { snapshots: Snapshot[]; adminId: string }) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [snapshotName, setSnapshotName] = useState('')
  const [snapshotDesc, setSnapshotDesc] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false)
  const [rollbackConfirm, setRollbackConfirm] = useState<string | null>(null)
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null)
  const [expandedSnapshot, setExpandedSnapshot] = useState<string | null>(null)
  const [snapshotDetails, setSnapshotDetails] = useState<Record<string, any>>({})

  function handleCreateSnapshot() {
    if (!snapshotName.trim()) {
      setError('Snapshot name is required')
      return
    }

    setError('')
    setSuccess('')

    startTransition(async () => {
      try {
        await createConfigSnapshot(snapshotName, snapshotDesc || undefined)
        setSnapshotName('')
        setSnapshotDesc('')
        setIsCreateDialogOpen(false)
        setSuccess('Snapshot created successfully')
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to create snapshot')
      }
    })
  }

  function handleRollback(snapshotId: string, snapshotName: string) {
    setRollbackConfirm(null)
    setError('')
    setSuccess('')

    startTransition(async () => {
      try {
        const result = await rollbackToSnapshot(snapshotId)
        setSuccess(`Rolled back to "${snapshotName}". Restored ${result.restoredCount} configs.`)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to rollback snapshot')
      }
    })
  }

  function handleDelete(snapshotId: string) {
    setDeleteConfirm(null)
    setError('')
    setSuccess('')

    startTransition(async () => {
      try {
        await deleteConfigSnapshot(snapshotId)
        setSuccess('Snapshot deleted successfully')
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to delete snapshot')
      }
    })
  }

  async function handleExpand(snapshotId: string) {
    if (expandedSnapshot === snapshotId) {
      setExpandedSnapshot(null)
    } else {
      try {
        const snapshot = await getConfigSnapshot(snapshotId)
        if (snapshot) {
          setSnapshotDetails((prev) => ({
            ...prev,
            [snapshotId]: snapshot,
          }))
        }
        setExpandedSnapshot(snapshotId)
      } catch (err) {
        setError('Failed to load snapshot details')
      }
    }
  }

  const formatDate = (isoString: string) => {
    const date = new Date(isoString)
    return date.toLocaleString()
  }

  const getShortDate = (isoString: string) => {
    const date = new Date(isoString)
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  }

  if (snapshots.length === 0) {
    return (
      <div className="space-y-4">
        {error && (
          <Card className="border-red-500 bg-red-50">
            <CardContent className="flex items-start gap-3 pt-6">
              <AlertCircle className="h-5 w-5 text-red-600 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-red-800">{error}</div>
            </CardContent>
          </Card>
        )}

        <Card>
          <CardContent className="flex flex-col items-center justify-center py-12">
            <div className="text-center space-y-4">
              <p className="text-muted-foreground">No snapshots created yet.</p>
              <p className="text-sm text-muted-foreground">
                Create snapshots before making config changes to protect against mistakes.
              </p>
              <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
                <DialogTrigger asChild>
                  <Button>
                    <Plus className="mr-2 h-4 w-4" />
                    Create First Snapshot
                  </Button>
                </DialogTrigger>
                <DialogContent>
                  <DialogHeader>
                    <DialogTitle>Create Config Snapshot</DialogTitle>
                  </DialogHeader>
                  <div className="space-y-4 py-4">
                    <div>
                      <label className="text-sm font-medium mb-2 block">Snapshot Name</label>
                      <Input
                        placeholder="e.g., Pre-release balance update"
                        value={snapshotName}
                        onChange={(e) => setSnapshotName(e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="text-sm font-medium mb-2 block">Description (optional)</label>
                      <Textarea
                        placeholder="Add notes about this snapshot..."
                        value={snapshotDesc}
                        onChange={(e) => setSnapshotDesc(e.target.value)}
                        className="min-h-20"
                      />
                    </div>
                    <div className="flex justify-end gap-2">
                      <Button variant="outline" onClick={() => setIsCreateDialogOpen(false)}>
                        Cancel
                      </Button>
                      <Button onClick={handleCreateSnapshot} disabled={isPending}>
                        <Save className="mr-2 h-4 w-4" />
                        {isPending ? 'Creating...' : 'Create Snapshot'}
                      </Button>
                    </div>
                  </div>
                </DialogContent>
              </Dialog>
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {error && (
        <Card className="border-red-500 bg-red-50">
          <CardContent className="flex items-start gap-3 pt-6">
            <AlertCircle className="h-5 w-5 text-red-600 flex-shrink-0 mt-0.5" />
            <div className="text-sm text-red-800">{error}</div>
          </CardContent>
        </Card>
      )}

      {success && (
        <Card className="border-green-500 bg-green-50">
          <CardContent className="flex items-start gap-3 pt-6">
            <CheckCircle2 className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
            <div className="text-sm text-green-800">{success}</div>
          </CardContent>
        </Card>
      )}

      <div className="flex justify-end">
        <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
          <DialogTrigger asChild>
            <Button>
              <Plus className="mr-2 h-4 w-4" />
              Create Snapshot
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Create Config Snapshot</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div>
                <label className="text-sm font-medium mb-2 block">Snapshot Name</label>
                <Input
                  placeholder="e.g., Pre-release balance update"
                  value={snapshotName}
                  onChange={(e) => setSnapshotName(e.target.value)}
                />
              </div>
              <div>
                <label className="text-sm font-medium mb-2 block">Description (optional)</label>
                <Textarea
                  placeholder="Add notes about this snapshot..."
                  value={snapshotDesc}
                  onChange={(e) => setSnapshotDesc(e.target.value)}
                  className="min-h-20"
                />
              </div>
              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => setIsCreateDialogOpen(false)}>
                  Cancel
                </Button>
                <Button onClick={handleCreateSnapshot} disabled={isPending}>
                  <Save className="mr-2 h-4 w-4" />
                  {isPending ? 'Creating...' : 'Create Snapshot'}
                </Button>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardContent className="pt-6">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Configs</TableHead>
                <TableHead>Created</TableHead>
                <TableHead>Description</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {snapshots.map((snapshot) => (
                <TableRow key={snapshot.id}>
                  <TableCell className="font-medium">{snapshot.name}</TableCell>
                  <TableCell>
                    <Badge variant="secondary">{snapshot.configCount} configs</Badge>
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">{getShortDate(snapshot.createdAt)}</TableCell>
                  <TableCell className="text-sm text-muted-foreground max-w-xs truncate">
                    {snapshot.description || 'No description'}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-2">
                      <Dialog
                        open={rollbackConfirm === snapshot.id}
                        onOpenChange={(open) => setRollbackConfirm(open ? snapshot.id : null)}
                      >
                        <DialogTrigger asChild>
                          <Button variant="outline" size="sm" title="Rollback to this snapshot">
                            <RotateCcw className="h-4 w-4" />
                          </Button>
                        </DialogTrigger>
                        <DialogContent>
                          <DialogHeader>
                            <DialogTitle>Confirm Rollback</DialogTitle>
                          </DialogHeader>
                          <div className="py-4 space-y-4">
                            <p className="text-sm">
                              Rollback to <strong>{snapshot.name}</strong>?
                            </p>
                            <p className="text-sm text-muted-foreground">
                              Your current config will be automatically backed up before rollback.
                            </p>
                            <div className="flex justify-end gap-2">
                              <Button
                                variant="outline"
                                onClick={() => setRollbackConfirm(null)}
                              >
                                Cancel
                              </Button>
                              <Button
                                variant="destructive"
                                onClick={() => handleRollback(snapshot.id, snapshot.name)}
                                disabled={isPending}
                              >
                                {isPending ? 'Rolling back...' : 'Confirm Rollback'}
                              </Button>
                            </div>
                          </div>
                        </DialogContent>
                      </Dialog>

                      <Dialog
                        open={deleteConfirm === snapshot.id}
                        onOpenChange={(open) => setDeleteConfirm(open ? snapshot.id : null)}
                      >
                        <DialogTrigger asChild>
                          <Button variant="destructive" size="sm" title="Delete this snapshot">
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </DialogTrigger>
                        <DialogContent>
                          <DialogHeader>
                            <DialogTitle>Delete Snapshot</DialogTitle>
                          </DialogHeader>
                          <div className="py-4 space-y-4">
                            <p className="text-sm">
                              Delete snapshot <strong>{snapshot.name}</strong>?
                            </p>
                            <p className="text-sm text-muted-foreground">
                              This action cannot be undone.
                            </p>
                            <div className="flex justify-end gap-2">
                              <Button
                                variant="outline"
                                onClick={() => setDeleteConfirm(null)}
                              >
                                Cancel
                              </Button>
                              <Button
                                variant="destructive"
                                onClick={() => handleDelete(snapshot.id)}
                                disabled={isPending}
                              >
                                {isPending ? 'Deleting...' : 'Delete Snapshot'}
                              </Button>
                            </div>
                          </div>
                        </DialogContent>
                      </Dialog>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
