'use client'

import { useState } from 'react'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Textarea } from '@/components/ui/textarea'
import {
  Table, TableHeader, TableRow, TableHead, TableBody, TableCell,
} from '@/components/ui/table'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter,
} from '@/components/ui/dialog'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import {
  createCampaign, sendCampaign, deleteCampaign,
  listCampaigns, getPushStats,
} from '@/actions/push'
import {
  parsePushTargetType,
  readPushCampaignTargetFilter,
  type PushCampaignRecord,
} from '@/lib/push-campaigns'
import {
  Plus, Send, Trash2, Bell, Smartphone, CheckCircle, XCircle,
} from 'lucide-react'

type Stats = {
  totalTokens: number
  activeTokens: number
  iosTokens: number
  totalCampaigns: number
  sentCampaigns: number
  totalLogsSent: number
  totalLogsFailed: number
}

type CampaignForm = {
  title: string
  body: string
  targetType: 'broadcast' | 'segment' | 'user'
  route: string
  minLevel: string
  maxLevel: string
  class: string
  userIds: string
}

const EMPTY_FORM: CampaignForm = {
  title: '',
  body: '',
  targetType: 'broadcast',
  route: '',
  minLevel: '',
  maxLevel: '',
  class: '',
  userIds: '',
}

const statusColors: Record<string, string> = {
  draft: 'bg-gray-500/20 text-gray-400',
  sending: 'bg-yellow-500/20 text-yellow-400',
  sent: 'bg-green-500/20 text-green-400',
  failed: 'bg-red-500/20 text-red-400',
}

export function PushClient({
  initialCampaigns,
  stats: initialStats,
}: {
  initialCampaigns: PushCampaignRecord[]
  stats: Stats
}) {
  const [campaigns, setCampaigns] = useState<PushCampaignRecord[]>(initialCampaigns)
  const [stats, setStats] = useState<Stats>(initialStats)
  const [showCreate, setShowCreate] = useState(false)
  const [confirmSend, setConfirmSend] = useState<string | null>(null)
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [form, setForm] = useState<CampaignForm>(EMPTY_FORM)

  const refresh = async () => {
    const [nextCampaigns, nextStats] = await Promise.all([listCampaigns(), getPushStats()])
    setCampaigns(JSON.parse(JSON.stringify(nextCampaigns)))
    setStats(nextStats)
  }

  const handleCreate = async () => {
    setLoading(true)
    try {
      const targetType = parsePushTargetType(form.targetType)
      const targetFilter = targetType === 'broadcast'
        ? undefined
        : targetType === 'user'
          ? { userIds: form.userIds }
          : {
            minLevel: form.minLevel,
            maxLevel: form.maxLevel,
            class: form.class,
          }

      const data = form.route ? { route: form.route } : undefined

      await createCampaign({
        title: form.title,
        body: form.body,
        data,
        targetType,
        targetFilter,
      })

      setShowCreate(false)
      setForm(EMPTY_FORM)
      await refresh()
    } finally {
      setLoading(false)
    }
  }

  const handleSend = async () => {
    if (!confirmSend) return

    setLoading(true)
    try {
      await sendCampaign(confirmSend)
      setConfirmSend(null)
      await refresh()
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async () => {
    if (!deleteId) return

    await deleteCampaign(deleteId)
    setDeleteId(null)
    await refresh()
  }

  const fmtDate = (value: string | Date | null) => {
    if (!value) return '—'

    return new Date(value).toLocaleString('en-GB', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  const describeTarget = (campaign: PushCampaignRecord) => {
    const targetType = parsePushTargetType(campaign.targetType)
    const filter = readPushCampaignTargetFilter(targetType, campaign.targetFilter)

    if (targetType === 'broadcast') return 'broadcast'
    if (targetType === 'user') return `${filter?.userIds?.length ?? 0} users`

    const parts = [
      filter?.class ? `class=${filter.class}` : null,
      filter?.minLevel !== undefined ? `min=${filter.minLevel}` : null,
      filter?.maxLevel !== undefined ? `max=${filter.maxLevel}` : null,
    ].filter(Boolean)

    return parts.length > 0 ? parts.join(', ') : 'segment'
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Push Notifications</h1>
          <p className="text-muted-foreground">Create and send push campaigns to players.</p>
        </div>
        <Button onClick={() => setShowCreate(true)}>
          <Plus className="mr-1 h-4 w-4" /> New Campaign
        </Button>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card><CardContent className="pt-4">
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">Active Tokens</p>
            <Smartphone className="h-4 w-4 text-blue-400" />
          </div>
          <p className="text-2xl font-bold">{stats.activeTokens}</p>
          <p className="text-xs text-muted-foreground">{stats.iosTokens} iOS · {stats.totalTokens} total</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4">
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">Campaigns</p>
            <Bell className="h-4 w-4 text-purple-400" />
          </div>
          <p className="text-2xl font-bold">{stats.totalCampaigns}</p>
          <p className="text-xs text-muted-foreground">{stats.sentCampaigns} sent</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4">
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">Pushes Sent</p>
            <CheckCircle className="h-4 w-4 text-green-400" />
          </div>
          <p className="text-2xl font-bold text-green-400">{stats.totalLogsSent}</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4">
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">Failed</p>
            <XCircle className="h-4 w-4 text-red-400" />
          </div>
          <p className="text-2xl font-bold text-red-400">{stats.totalLogsFailed}</p>
        </CardContent></Card>
      </div>

      <Card>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Campaign</TableHead>
              <TableHead>Target</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Sent</TableHead>
              <TableHead>Created</TableHead>
              <TableHead>Sent At</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {campaigns.map((campaign) => (
              <TableRow key={campaign.id}>
                <TableCell>
                  <div>
                    <span className="font-medium">{campaign.title}</span>
                    <br />
                    <span className="line-clamp-1 text-xs text-muted-foreground">{campaign.body}</span>
                  </div>
                </TableCell>
                <TableCell>
                  <div className="space-y-1">
                    <Badge variant="outline" className="capitalize">{campaign.targetType}</Badge>
                    <div className="text-xs text-muted-foreground">{describeTarget(campaign)}</div>
                  </div>
                </TableCell>
                <TableCell>
                  <Badge className={statusColors[campaign.status] ?? ''}>{campaign.status}</Badge>
                </TableCell>
                <TableCell>
                  {campaign.sentCount > 0 ? (
                    <span>
                      {campaign.sentCount}{' '}
                      <span className="text-xs text-muted-foreground">({campaign.failCount} failed)</span>
                    </span>
                  ) : '—'}
                </TableCell>
                <TableCell className="text-xs">{fmtDate(campaign.createdAt)}</TableCell>
                <TableCell className="text-xs">{fmtDate(campaign.sentAt)}</TableCell>
                <TableCell>
                  <div className="flex gap-1">
                    {campaign.status === 'draft' && (
                      <Button size="sm" variant="ghost" onClick={() => setConfirmSend(campaign.id)}>
                        <Send className="h-4 w-4 text-green-400" />
                      </Button>
                    )}
                    <Button size="sm" variant="ghost" onClick={() => setDeleteId(campaign.id)}>
                      <Trash2 className="h-4 w-4 text-red-400" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
            {campaigns.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} className="py-8 text-center text-muted-foreground">
                  No campaigns yet. Create one to get started.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </Card>

      <Dialog open={showCreate} onOpenChange={setShowCreate}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>New Push Campaign</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Title</Label>
              <Input value={form.title} onChange={(event) => setForm({ ...form, title: event.target.value })} placeholder="Daily rewards await!" />
            </div>
            <div>
              <Label>Body</Label>
              <Textarea value={form.body} onChange={(event) => setForm({ ...form, body: event.target.value })} rows={3} placeholder="Your daily login bonus is ready. Claim it before midnight!" />
            </div>
            <div>
              <Label>Target</Label>
              <Select value={form.targetType} onValueChange={(value: CampaignForm['targetType']) => setForm({ ...form, targetType: value })}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="broadcast">Broadcast (all)</SelectItem>
                  <SelectItem value="segment">Segment (level/class)</SelectItem>
                  <SelectItem value="user">Specific Users</SelectItem>
                </SelectContent>
              </Select>
            </div>
            {form.targetType === 'segment' && (
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <Label>Min Level</Label>
                  <Input type="number" value={form.minLevel} onChange={(event) => setForm({ ...form, minLevel: event.target.value })} />
                </div>
                <div>
                  <Label>Max Level</Label>
                  <Input type="number" value={form.maxLevel} onChange={(event) => setForm({ ...form, maxLevel: event.target.value })} />
                </div>
                <div>
                  <Label>Class</Label>
                  <Select value={form.class || 'any'} onValueChange={(value) => setForm({ ...form, class: value === 'any' ? '' : value })}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="any">Any</SelectItem>
                      <SelectItem value="warrior">Warrior</SelectItem>
                      <SelectItem value="rogue">Rogue</SelectItem>
                      <SelectItem value="mage">Mage</SelectItem>
                      <SelectItem value="tank">Tank</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            )}
            {form.targetType === 'user' && (
              <div>
                <Label>User IDs (comma-separated)</Label>
                <Input value={form.userIds} onChange={(event) => setForm({ ...form, userIds: event.target.value })} placeholder="uuid1, uuid2" />
              </div>
            )}
            <div>
              <Label>Deep Link Route (optional)</Label>
              <Input value={form.route} onChange={(event) => setForm({ ...form, route: event.target.value })} placeholder="inbox, shop, guild-hall" />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowCreate(false)}>Cancel</Button>
            <Button onClick={handleCreate} disabled={loading || !form.title || !form.body}>
              Create Draft
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={Boolean(confirmSend)} onOpenChange={() => setConfirmSend(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Send Push Campaign?</DialogTitle>
          </DialogHeader>
          <p className="text-muted-foreground">
            This will mark the campaign as sent and target the currently eligible push tokens.
          </p>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmSend(null)}>Cancel</Button>
            <Button onClick={handleSend} disabled={loading}>
              <Send className="mr-1 h-4 w-4" /> Send
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={Boolean(deleteId)} onOpenChange={() => setDeleteId(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Campaign?</DialogTitle>
          </DialogHeader>
          <p className="text-muted-foreground">This will permanently delete the campaign record.</p>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteId(null)}>Cancel</Button>
            <Button variant="destructive" onClick={handleDelete}>Delete</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
