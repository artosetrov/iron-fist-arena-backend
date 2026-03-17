'use client'

import { useState } from 'react'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
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
  Plus, Send, Trash2, Bell, Smartphone, Users, CheckCircle, XCircle,
} from 'lucide-react'

type Campaign = {
  id: string
  title: string
  body: string
  data: any
  targetType: string
  targetFilter: any
  status: string
  sentCount: number
  failCount: number
  scheduledAt: string | null
  sentAt: string | null
  createdBy: string | null
  createdAt: string
}

type Stats = {
  totalTokens: number
  activeTokens: number
  iosTokens: number
  totalCampaigns: number
  sentCampaigns: number
  totalLogsSent: number
  totalLogsFailed: number
}

const statusColors: Record<string, string> = {
  draft: 'bg-gray-500/20 text-gray-400',
  sending: 'bg-yellow-500/20 text-yellow-400',
  sent: 'bg-green-500/20 text-green-400',
  failed: 'bg-red-500/20 text-red-400',
}

export function PushClient({ initialCampaigns, stats: initialStats }: {
  initialCampaigns: Campaign[]
  stats: Stats
}) {
  const [campaigns, setCampaigns] = useState<Campaign[]>(initialCampaigns)
  const [stats, setStats] = useState<Stats>(initialStats)
  const [showCreate, setShowCreate] = useState(false)
  const [confirmSend, setConfirmSend] = useState<string | null>(null)
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  // Form
  const [form, setForm] = useState({
    title: '', body: '', targetType: 'broadcast',
    route: '', minLevel: '', maxLevel: '', class: '', userIds: '',
  })

  const refresh = async () => {
    const [c, s] = await Promise.all([listCampaigns(), getPushStats()])
    setCampaigns(JSON.parse(JSON.stringify(c)))
    setStats(s)
  }

  const handleCreate = async () => {
    setLoading(true)
    try {
      const targetFilter: any = {}
      if (form.minLevel) targetFilter.minLevel = parseInt(form.minLevel)
      if (form.maxLevel) targetFilter.maxLevel = parseInt(form.maxLevel)
      if (form.class) targetFilter.class = form.class
      if (form.userIds) targetFilter.userIds = form.userIds.split(',').map(s => s.trim()).filter(Boolean)

      const data: any = {}
      if (form.route) data.route = form.route

      await createCampaign({
        title: form.title,
        body: form.body,
        data: Object.keys(data).length > 0 ? data : undefined,
        targetType: form.targetType,
        targetFilter: Object.keys(targetFilter).length > 0 ? targetFilter : undefined,
      })
      setShowCreate(false)
      setForm({ title: '', body: '', targetType: 'broadcast', route: '', minLevel: '', maxLevel: '', class: '', userIds: '' })
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

  const fmtDate = (d: string | null) => {
    if (!d) return '—'
    return new Date(d).toLocaleString('en-GB', {
      day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
    })
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Push Notifications</h1>
          <p className="text-muted-foreground">Create and send push campaigns to players.</p>
        </div>
        <Button onClick={() => setShowCreate(true)}>
          <Plus className="w-4 h-4 mr-1" /> New Campaign
        </Button>
      </div>

      {/* Stats */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card><CardContent className="pt-4">
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">Active Tokens</p>
            <Smartphone className="w-4 h-4 text-blue-400" />
          </div>
          <p className="text-2xl font-bold">{stats.activeTokens}</p>
          <p className="text-xs text-muted-foreground">{stats.iosTokens} iOS · {stats.totalTokens} total</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4">
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">Campaigns</p>
            <Bell className="w-4 h-4 text-purple-400" />
          </div>
          <p className="text-2xl font-bold">{stats.totalCampaigns}</p>
          <p className="text-xs text-muted-foreground">{stats.sentCampaigns} sent</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4">
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">Pushes Sent</p>
            <CheckCircle className="w-4 h-4 text-green-400" />
          </div>
          <p className="text-2xl font-bold text-green-400">{stats.totalLogsSent}</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4">
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">Failed</p>
            <XCircle className="w-4 h-4 text-red-400" />
          </div>
          <p className="text-2xl font-bold text-red-400">{stats.totalLogsFailed}</p>
        </CardContent></Card>
      </div>

      {/* Campaigns Table */}
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
            {campaigns.map(c => (
              <TableRow key={c.id}>
                <TableCell>
                  <div>
                    <span className="font-medium">{c.title}</span>
                    <br />
                    <span className="text-xs text-muted-foreground line-clamp-1">{c.body}</span>
                  </div>
                </TableCell>
                <TableCell>
                  <Badge variant="outline" className="capitalize">{c.targetType}</Badge>
                </TableCell>
                <TableCell>
                  <Badge className={statusColors[c.status] ?? ''}>{c.status}</Badge>
                </TableCell>
                <TableCell>
                  {c.sentCount > 0 ? (
                    <span>{c.sentCount} <span className="text-muted-foreground text-xs">({c.failCount} failed)</span></span>
                  ) : '—'}
                </TableCell>
                <TableCell className="text-xs">{fmtDate(c.createdAt)}</TableCell>
                <TableCell className="text-xs">{fmtDate(c.sentAt)}</TableCell>
                <TableCell>
                  <div className="flex gap-1">
                    {c.status === 'draft' && (
                      <Button size="sm" variant="ghost" onClick={() => setConfirmSend(c.id)}>
                        <Send className="w-4 h-4 text-green-400" />
                      </Button>
                    )}
                    <Button size="sm" variant="ghost" onClick={() => setDeleteId(c.id)}>
                      <Trash2 className="w-4 h-4 text-red-400" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
            {campaigns.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} className="text-center text-muted-foreground py-8">
                  No campaigns yet. Create one to get started.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </Card>

      {/* Create Dialog */}
      <Dialog open={showCreate} onOpenChange={setShowCreate}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>New Push Campaign</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Title</Label>
              <Input value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} placeholder="Daily rewards await!" />
            </div>
            <div>
              <Label>Body</Label>
              <Textarea value={form.body} onChange={e => setForm({ ...form, body: e.target.value })} rows={3} placeholder="Your daily login bonus is ready. Claim it before midnight!" />
            </div>
            <div>
              <Label>Target</Label>
              <Select value={form.targetType} onValueChange={v => setForm({ ...form, targetType: v })}>
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
                  <Input type="number" value={form.minLevel} onChange={e => setForm({ ...form, minLevel: e.target.value })} />
                </div>
                <div>
                  <Label>Max Level</Label>
                  <Input type="number" value={form.maxLevel} onChange={e => setForm({ ...form, maxLevel: e.target.value })} />
                </div>
                <div>
                  <Label>Class</Label>
                  <Select value={form.class || 'any'} onValueChange={v => setForm({ ...form, class: v === 'any' ? '' : v })}>
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
                <Input value={form.userIds} onChange={e => setForm({ ...form, userIds: e.target.value })} placeholder="uuid1, uuid2" />
              </div>
            )}
            <div>
              <Label>Deep Link Route (optional)</Label>
              <Input value={form.route} onChange={e => setForm({ ...form, route: e.target.value })} placeholder="inbox, shop, events" />
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

      {/* Send Confirmation */}
      <Dialog open={!!confirmSend} onOpenChange={() => setConfirmSend(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Send Push Campaign?</DialogTitle>
          </DialogHeader>
          <p className="text-muted-foreground">This will send push notifications to all targeted devices. This action cannot be undone.</p>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmSend(null)}>Cancel</Button>
            <Button onClick={handleSend} disabled={loading}>
              <Send className="w-4 h-4 mr-1" /> Send Now
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={!!deleteId} onOpenChange={() => setDeleteId(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Delete Campaign?</DialogTitle></DialogHeader>
          <p className="text-muted-foreground">This will permanently delete this campaign.</p>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteId(null)}>Cancel</Button>
            <Button variant="destructive" onClick={handleDelete}>Delete</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
