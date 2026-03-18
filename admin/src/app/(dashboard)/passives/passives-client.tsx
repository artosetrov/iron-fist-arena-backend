'use client'

import { useState, useTransition, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Switch } from '@/components/ui/switch'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from '@/components/ui/dialog'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import { Plus, Pencil, Trash2, Search, GitBranch, Link } from 'lucide-react'

// --- Types ---

type PassiveNode = {
  id: string
  nodeKey: string
  name: string
  description: string | null
  bonusType: string
  bonusStat: string | null
  bonusValue: number
  tier: number
  positionX: number
  positionY: number
  cost: number
  icon: string | null
  classRestriction: string | null
  isStartNode: boolean
  isActive: boolean
  createdAt: string
}

type PassiveConnection = {
  id: string
  fromId: string
  toId: string
  fromNode: { id: string; name: string; nodeKey: string }
  toNode: { id: string; name: string; nodeKey: string }
}

// --- Constants ---

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001'

const BONUS_TYPES = [
  'flat_stat',
  'percent_stat',
  'flat_damage',
  'percent_damage',
  'flat_crit_chance',
  'flat_dodge_chance',
  'flat_hp',
  'percent_hp',
  'flat_armor',
  'flat_magic_resist',
  'percent_armor',
  'percent_magic_resist',
  'lifesteal',
  'cooldown_reduction',
  'damage_reduction',
]

const BONUS_STATS = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha']

const CLASSES = ['warrior', 'rogue', 'mage', 'tank']

const TIER_COLORS: Record<number, string> = {
  1: 'bg-zinc-600/20 text-zinc-400 border-zinc-600',
  2: 'bg-blue-600/20 text-blue-400 border-blue-600',
  3: 'bg-purple-600/20 text-purple-400 border-purple-600',
}

const emptyNodeForm = {
  nodeKey: '',
  name: '',
  description: '',
  bonusType: 'flat_stat',
  bonusStat: '',
  bonusValue: 0,
  tier: 1,
  positionX: 0,
  positionY: 0,
  cost: 1,
  icon: '',
  classRestriction: '',
  isStartNode: false,
  isActive: true,
}

// --- Helpers ---

function getToken(): string {
  const match = document.cookie.match(/(?:^|;\s*)admin-token=([^;]*)/)
  return match ? decodeURIComponent(match[1]) : ''
}

function formatBonusType(bt: string): string {
  return bt.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
}

// --- Component ---

export function PassivesClient({
  nodes,
  connections,
}: {
  nodes: PassiveNode[]
  connections: PassiveConnection[]
}) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()

  // Node state
  const [search, setSearch] = useState('')
  const [nodeDialogOpen, setNodeDialogOpen] = useState(false)
  const [deleteNodeDialogOpen, setDeleteNodeDialogOpen] = useState(false)
  const [editingNode, setEditingNode] = useState<PassiveNode | null>(null)
  const [deletingNode, setDeletingNode] = useState<PassiveNode | null>(null)
  const [nodeForm, setNodeForm] = useState(emptyNodeForm)
  const [nodeError, setNodeError] = useState('')

  // Connection state
  const [connDialogOpen, setConnDialogOpen] = useState(false)
  const [deleteConnDialogOpen, setDeleteConnDialogOpen] = useState(false)
  const [deletingConn, setDeletingConn] = useState<PassiveConnection | null>(null)
  const [connFromId, setConnFromId] = useState('')
  const [connToId, setConnToId] = useState('')
  const [connError, setConnError] = useState('')

  // Filtered nodes
  const filteredNodes = useMemo(() => {
    if (!search) return nodes
    const q = search.toLowerCase()
    return nodes.filter(
      (n) =>
        n.name.toLowerCase().includes(q) ||
        n.nodeKey.toLowerCase().includes(q)
    )
  }, [nodes, search])

  // --- Node CRUD ---

  function openCreateNode() {
    setEditingNode(null)
    setNodeForm(emptyNodeForm)
    setNodeError('')
    setNodeDialogOpen(true)
  }

  function openEditNode(node: PassiveNode) {
    setEditingNode(node)
    setNodeForm({
      nodeKey: node.nodeKey,
      name: node.name,
      description: node.description || '',
      bonusType: node.bonusType,
      bonusStat: node.bonusStat || '',
      bonusValue: node.bonusValue,
      tier: node.tier,
      positionX: node.positionX,
      positionY: node.positionY,
      cost: node.cost,
      icon: node.icon || '',
      classRestriction: node.classRestriction || '',
      isStartNode: node.isStartNode,
      isActive: node.isActive,
    })
    setNodeError('')
    setNodeDialogOpen(true)
  }

  async function handleNodeSubmit(e: React.FormEvent) {
    e.preventDefault()
    setNodeError('')

    const token = getToken()
    if (!token) {
      setNodeError('Not authenticated. Please log in again.')
      return
    }

    const payload: Record<string, unknown> = {
      node_key: nodeForm.nodeKey,
      name: nodeForm.name,
      description: nodeForm.description || null,
      bonus_type: nodeForm.bonusType,
      bonus_stat: nodeForm.bonusStat || null,
      bonus_value: nodeForm.bonusValue,
      tier: nodeForm.tier,
      position_x: nodeForm.positionX,
      position_y: nodeForm.positionY,
      cost: nodeForm.cost,
      icon: nodeForm.icon || null,
      class_restriction: nodeForm.classRestriction || null,
      is_start_node: nodeForm.isStartNode,
      is_active: nodeForm.isActive,
    }

    if (editingNode) {
      payload.id = editingNode.id
    }

    startTransition(async () => {
      try {
        const res = await fetch(`${API_URL}/api/admin/passives`, {
          method: editingNode ? 'PUT' : 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify(payload),
        })
        if (!res.ok) {
          const data = await res.json().catch(() => ({}))
          setNodeError(data.error || `Failed to save node (${res.status})`)
          return
        }
        setNodeDialogOpen(false)
        router.refresh()
      } catch (err) {
        setNodeError(err instanceof Error ? err.message : 'Failed to save node')
      }
    })
  }

  async function handleDeleteNode() {
    if (!deletingNode) return
    const token = getToken()
    if (!token) {
      setNodeError('Not authenticated. Please log in again.')
      return
    }

    startTransition(async () => {
      try {
        const res = await fetch(`${API_URL}/api/admin/passives?id=${deletingNode.id}`, {
          method: 'DELETE',
          headers: { Authorization: `Bearer ${token}` },
        })
        if (!res.ok) {
          const data = await res.json().catch(() => ({}))
          setNodeError(data.error || `Failed to delete node (${res.status})`)
          return
        }
        setDeleteNodeDialogOpen(false)
        setDeletingNode(null)
        router.refresh()
      } catch (err) {
        setNodeError(err instanceof Error ? err.message : 'Failed to delete node')
      }
    })
  }

  // --- Connection CRUD ---

  function openCreateConn() {
    setConnFromId('')
    setConnToId('')
    setConnError('')
    setConnDialogOpen(true)
  }

  async function handleConnSubmit(e: React.FormEvent) {
    e.preventDefault()
    setConnError('')

    if (!connFromId || !connToId) {
      setConnError('Please select both From and To nodes.')
      return
    }
    if (connFromId === connToId) {
      setConnError('From and To nodes must be different.')
      return
    }

    const token = getToken()
    if (!token) {
      setConnError('Not authenticated. Please log in again.')
      return
    }

    startTransition(async () => {
      try {
        const res = await fetch(`${API_URL}/api/admin/passives/connections`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            from_id: connFromId,
            to_id: connToId,
          }),
        })
        if (!res.ok) {
          const data = await res.json().catch(() => ({}))
          setConnError(data.error || `Failed to create connection (${res.status})`)
          return
        }
        setConnDialogOpen(false)
        router.refresh()
      } catch (err) {
        setConnError(err instanceof Error ? err.message : 'Failed to create connection')
      }
    })
  }

  async function handleDeleteConn() {
    if (!deletingConn) return
    const token = getToken()
    if (!token) {
      setConnError('Not authenticated. Please log in again.')
      return
    }

    startTransition(async () => {
      try {
        const res = await fetch(
          `${API_URL}/api/admin/passives/connections?id=${deletingConn.id}`,
          {
            method: 'DELETE',
            headers: { Authorization: `Bearer ${token}` },
          }
        )
        if (!res.ok) {
          const data = await res.json().catch(() => ({}))
          setConnError(data.error || `Failed to delete connection (${res.status})`)
          return
        }
        setDeleteConnDialogOpen(false)
        setDeletingConn(null)
        router.refresh()
      } catch (err) {
        setConnError(err instanceof Error ? err.message : 'Failed to delete connection')
      }
    })
  }

  // --- Render ---

  return (
    <Tabs defaultValue="nodes" className="space-y-4">
      <TabsList>
        <TabsTrigger value="nodes" className="gap-2">
          <GitBranch className="h-4 w-4" />
          Nodes ({nodes.length})
        </TabsTrigger>
        <TabsTrigger value="connections" className="gap-2">
          <Link className="h-4 w-4" />
          Connections ({connections.length})
        </TabsTrigger>
      </TabsList>

      {/* ==================== TAB 1: NODES ==================== */}
      <TabsContent value="nodes" className="space-y-4">
        {nodeError && (
          <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
            {nodeError}
            <button className="ml-2 underline" onClick={() => setNodeError('')}>Dismiss</button>
          </div>
        )}

        {/* Toolbar */}
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative flex-1 min-w-[200px] max-w-sm">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Search nodes..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9"
            />
          </div>
          <Button onClick={openCreateNode}>
            <Plus className="mr-2 h-4 w-4" />
            Create Node
          </Button>
        </div>

        {/* Nodes Table */}
        <div className="rounded-lg border border-border">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/50">
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Name</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Bonus Type</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Bonus Value</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Stat</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Tier</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Cost</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Class</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Start Node</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Active</th>
                <th className="px-4 py-3 text-right font-medium text-muted-foreground">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredNodes.length === 0 ? (
                <tr>
                  <td colSpan={10} className="px-4 py-12 text-center text-muted-foreground">
                    <GitBranch className="mx-auto mb-3 h-8 w-8 opacity-40" />
                    <p>No passive nodes found.</p>
                    <p className="text-xs mt-1">Create your first node to get started.</p>
                  </td>
                </tr>
              ) : (
                filteredNodes.map((node) => (
                  <tr
                    key={node.id}
                    className="border-b border-border hover:bg-muted/30 transition-colors"
                  >
                    <td className="px-4 py-3">
                      <div>
                        <span className="font-medium">{node.name}</span>
                        <p className="text-xs text-muted-foreground font-mono">{node.nodeKey}</p>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <Badge variant="secondary">{formatBonusType(node.bonusType)}</Badge>
                    </td>
                    <td className="px-4 py-3 font-mono">{node.bonusValue}</td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {node.bonusStat ? node.bonusStat.toUpperCase() : '---'}
                    </td>
                    <td className="px-4 py-3">
                      <Badge className={TIER_COLORS[node.tier] ?? ''}>
                        T{node.tier}
                      </Badge>
                    </td>
                    <td className="px-4 py-3">{node.cost}</td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {node.classRestriction
                        ? node.classRestriction.charAt(0).toUpperCase() + node.classRestriction.slice(1)
                        : '---'}
                    </td>
                    <td className="px-4 py-3">
                      {node.isStartNode ? (
                        <Badge className="bg-amber-600/20 text-amber-400 border-amber-600">Start</Badge>
                      ) : (
                        <span className="text-muted-foreground">---</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {node.isActive ? (
                        <Badge className="bg-green-600/20 text-green-400 border-green-600">Active</Badge>
                      ) : (
                        <Badge className="bg-zinc-600/20 text-zinc-400 border-zinc-600">Inactive</Badge>
                      )}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => openEditNode(node)}
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => {
                            setDeletingNode(node)
                            setDeleteNodeDialogOpen(true)
                          }}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <p className="text-sm text-muted-foreground">
          Showing {filteredNodes.length} of {nodes.length} nodes
        </p>
      </TabsContent>

      {/* ==================== TAB 2: CONNECTIONS ==================== */}
      <TabsContent value="connections" className="space-y-4">
        {connError && (
          <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
            {connError}
            <button className="ml-2 underline" onClick={() => setConnError('')}>Dismiss</button>
          </div>
        )}

        {/* Toolbar */}
        <div className="flex justify-end">
          <Button onClick={openCreateConn}>
            <Plus className="mr-2 h-4 w-4" />
            Add Connection
          </Button>
        </div>

        {/* Connections Table */}
        <div className="rounded-lg border border-border">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/50">
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">From Node</th>
                <th className="px-4 py-3 text-center font-medium text-muted-foreground"></th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">To Node</th>
                <th className="px-4 py-3 text-right font-medium text-muted-foreground">Actions</th>
              </tr>
            </thead>
            <tbody>
              {connections.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-4 py-12 text-center text-muted-foreground">
                    <Link className="mx-auto mb-3 h-8 w-8 opacity-40" />
                    <p>No connections yet.</p>
                    <p className="text-xs mt-1">Add connections to link passive nodes together.</p>
                  </td>
                </tr>
              ) : (
                connections.map((conn) => (
                  <tr
                    key={conn.id}
                    className="border-b border-border hover:bg-muted/30 transition-colors"
                  >
                    <td className="px-4 py-3">
                      <div>
                        <span className="font-medium">{conn.fromNode.name}</span>
                        <p className="text-xs text-muted-foreground font-mono">{conn.fromNode.nodeKey}</p>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-center text-muted-foreground">
                      &rarr;
                    </td>
                    <td className="px-4 py-3">
                      <div>
                        <span className="font-medium">{conn.toNode.name}</span>
                        <p className="text-xs text-muted-foreground font-mono">{conn.toNode.nodeKey}</p>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => {
                          setDeletingConn(conn)
                          setDeleteConnDialogOpen(true)
                        }}
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <p className="text-sm text-muted-foreground">
          {connections.length} connection{connections.length !== 1 ? 's' : ''} total
        </p>
      </TabsContent>

      {/* ==================== DIALOGS ==================== */}

      {/* Create / Edit Node Dialog */}
      <Dialog open={nodeDialogOpen} onOpenChange={setNodeDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingNode ? 'Edit Node' : 'Create Node'}</DialogTitle>
            <DialogDescription>
              {editingNode
                ? 'Update passive node details.'
                : 'Add a new node to the passive skill tree.'}
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleNodeSubmit} className="space-y-4">
            {nodeError && (
              <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
                {nodeError}
              </div>
            )}

            {/* Row 1: Node Key + Name */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="nodeKey">Node Key</Label>
                <Input
                  id="nodeKey"
                  value={nodeForm.nodeKey}
                  onChange={(e) => setNodeForm({ ...nodeForm, nodeKey: e.target.value })}
                  placeholder="e.g. str_tier1_01"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="nodeName">Name</Label>
                <Input
                  id="nodeName"
                  value={nodeForm.name}
                  onChange={(e) => setNodeForm({ ...nodeForm, name: e.target.value })}
                  placeholder="e.g. Iron Will"
                  required
                />
              </div>
            </div>

            {/* Description */}
            <div className="space-y-2">
              <Label htmlFor="nodeDesc">Description</Label>
              <Input
                id="nodeDesc"
                value={nodeForm.description}
                onChange={(e) => setNodeForm({ ...nodeForm, description: e.target.value })}
                placeholder="Optional description"
              />
            </div>

            {/* Row 2: Bonus Type + Bonus Stat + Bonus Value */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>Bonus Type</Label>
                <Select
                  value={nodeForm.bonusType}
                  onValueChange={(v) => setNodeForm({ ...nodeForm, bonusType: v })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {BONUS_TYPES.map((bt) => (
                      <SelectItem key={bt} value={bt}>
                        {formatBonusType(bt)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Bonus Stat</Label>
                <Select
                  value={nodeForm.bonusStat || '__none__'}
                  onValueChange={(v) =>
                    setNodeForm({ ...nodeForm, bonusStat: v === '__none__' ? '' : v })
                  }
                >
                  <SelectTrigger>
                    <SelectValue placeholder="None" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="__none__">None</SelectItem>
                    {BONUS_STATS.map((s) => (
                      <SelectItem key={s} value={s}>
                        {s.toUpperCase()}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="bonusValue">Bonus Value</Label>
                <Input
                  id="bonusValue"
                  type="number"
                  step="any"
                  value={nodeForm.bonusValue}
                  onChange={(e) =>
                    setNodeForm({ ...nodeForm, bonusValue: parseFloat(e.target.value) || 0 })
                  }
                  required
                />
              </div>
            </div>

            {/* Row 3: Tier + Cost + Class Restriction */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="tier">Tier</Label>
                <Select
                  value={String(nodeForm.tier)}
                  onValueChange={(v) => setNodeForm({ ...nodeForm, tier: Number(v) })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="1">Tier 1</SelectItem>
                    <SelectItem value="2">Tier 2</SelectItem>
                    <SelectItem value="3">Tier 3</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="cost">Cost</Label>
                <Input
                  id="cost"
                  type="number"
                  min={1}
                  value={nodeForm.cost}
                  onChange={(e) =>
                    setNodeForm({ ...nodeForm, cost: parseInt(e.target.value) || 1 })
                  }
                  required
                />
              </div>
              <div className="space-y-2">
                <Label>Class Restriction</Label>
                <Select
                  value={nodeForm.classRestriction || '__none__'}
                  onValueChange={(v) =>
                    setNodeForm({ ...nodeForm, classRestriction: v === '__none__' ? '' : v })
                  }
                >
                  <SelectTrigger>
                    <SelectValue placeholder="None" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="__none__">None (all classes)</SelectItem>
                    {CLASSES.map((c) => (
                      <SelectItem key={c} value={c}>
                        {c.charAt(0).toUpperCase() + c.slice(1)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* Row 4: Position X + Position Y + Icon */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="positionX">Position X</Label>
                <Input
                  id="positionX"
                  type="number"
                  step="any"
                  value={nodeForm.positionX}
                  onChange={(e) =>
                    setNodeForm({ ...nodeForm, positionX: parseFloat(e.target.value) || 0 })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="positionY">Position Y</Label>
                <Input
                  id="positionY"
                  type="number"
                  step="any"
                  value={nodeForm.positionY}
                  onChange={(e) =>
                    setNodeForm({ ...nodeForm, positionY: parseFloat(e.target.value) || 0 })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="icon">Icon</Label>
                <Input
                  id="icon"
                  value={nodeForm.icon}
                  onChange={(e) => setNodeForm({ ...nodeForm, icon: e.target.value })}
                  placeholder="e.g. sword_icon"
                />
              </div>
            </div>

            {/* Row 5: Switches */}
            <div className="flex items-center gap-8 pt-2">
              <div className="flex items-center gap-2">
                <Switch
                  id="isStartNode"
                  checked={nodeForm.isStartNode}
                  onCheckedChange={(checked) =>
                    setNodeForm({ ...nodeForm, isStartNode: checked })
                  }
                />
                <Label htmlFor="isStartNode" className="cursor-pointer">
                  Start Node
                </Label>
              </div>
              <div className="flex items-center gap-2">
                <Switch
                  id="isActive"
                  checked={nodeForm.isActive}
                  onCheckedChange={(checked) =>
                    setNodeForm({ ...nodeForm, isActive: checked })
                  }
                />
                <Label htmlFor="isActive" className="cursor-pointer">
                  Active
                </Label>
              </div>
            </div>

            {/* Actions */}
            <div className="flex justify-end gap-3 pt-2">
              <Button
                type="button"
                variant="outline"
                onClick={() => setNodeDialogOpen(false)}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={isPending}>
                {isPending
                  ? 'Saving...'
                  : editingNode
                  ? 'Update Node'
                  : 'Create Node'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Node Dialog */}
      <Dialog open={deleteNodeDialogOpen} onOpenChange={setDeleteNodeDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Node</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete &quot;{deletingNode?.name}&quot;? This will also
              remove all connections to and from this node. This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setDeleteNodeDialogOpen(false)}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDeleteNode} disabled={isPending}>
              {isPending ? 'Deleting...' : 'Delete'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Add Connection Dialog */}
      <Dialog open={connDialogOpen} onOpenChange={setConnDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Connection</DialogTitle>
            <DialogDescription>
              Create a directional edge between two passive nodes.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleConnSubmit} className="space-y-4">
            {connError && (
              <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
                {connError}
              </div>
            )}
            <div className="space-y-2">
              <Label>From Node</Label>
              <Select value={connFromId} onValueChange={setConnFromId}>
                <SelectTrigger>
                  <SelectValue placeholder="Select source node..." />
                </SelectTrigger>
                <SelectContent>
                  {nodes.map((n) => (
                    <SelectItem key={n.id} value={n.id}>
                      {n.name} ({n.nodeKey})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>To Node</Label>
              <Select value={connToId} onValueChange={setConnToId}>
                <SelectTrigger>
                  <SelectValue placeholder="Select target node..." />
                </SelectTrigger>
                <SelectContent>
                  {nodes.map((n) => (
                    <SelectItem key={n.id} value={n.id}>
                      {n.name} ({n.nodeKey})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="flex justify-end gap-3 pt-2">
              <Button
                type="button"
                variant="outline"
                onClick={() => setConnDialogOpen(false)}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={isPending}>
                {isPending ? 'Creating...' : 'Create Connection'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Connection Dialog */}
      <Dialog open={deleteConnDialogOpen} onOpenChange={setDeleteConnDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Connection</DialogTitle>
            <DialogDescription>
              Are you sure you want to remove the connection from &quot;{deletingConn?.fromNode.name}&quot; to &quot;{deletingConn?.toNode.name}&quot;? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setDeleteConnDialogOpen(false)}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDeleteConn} disabled={isPending}>
              {isPending ? 'Deleting...' : 'Delete'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </Tabs>
  )
}
