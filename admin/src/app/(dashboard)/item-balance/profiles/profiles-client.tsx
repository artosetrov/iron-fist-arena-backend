'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { updateBalanceProfile } from '@/actions/item-balance'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Save, Check, X, Pencil } from 'lucide-react'

interface Profile {
  id: string
  itemType: string
  statWeights: Record<string, number>
  powerWeight: number
  description: string | null
  updatedAt: string
}

const STAT_NAMES = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha']

const STAT_COLORS: Record<string, string> = {
  str: 'bg-red-500',
  agi: 'bg-green-500',
  vit: 'bg-orange-500',
  end: 'bg-yellow-500',
  int: 'bg-blue-500',
  wis: 'bg-purple-500',
  luk: 'bg-pink-500',
  cha: 'bg-cyan-500',
}

export function ProfilesClient({
  profiles,
  adminId,
}: {
  profiles: Profile[]
  adminId: string
}) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editWeights, setEditWeights] = useState<Record<string, number>>({})
  const [editPower, setEditPower] = useState(1.0)
  const [savedId, setSavedId] = useState<string | null>(null)

  function startEdit(profile: Profile) {
    setEditingId(profile.id)
    setEditWeights({ ...profile.statWeights })
    setEditPower(profile.powerWeight)
  }

  function cancelEdit() {
    setEditingId(null)
  }

  async function saveProfile(profile: Profile) {
    try {
      await updateBalanceProfile(
        profile.itemType,
        editWeights,
        editPower,
        adminId,
        profile.description ?? undefined,
      )
      setEditingId(null)
      setSavedId(profile.id)
      setTimeout(() => setSavedId(null), 2000)
      startTransition(() => router.refresh())
    } catch {
      // silent fail
    }
  }

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {profiles.map((profile) => {
        const isEditing = editingId === profile.id
        const weights = isEditing ? editWeights : profile.statWeights
        const maxWeight = Math.max(...Object.values(weights), 1)

        return (
          <Card key={profile.id} className={savedId === profile.id ? 'ring-2 ring-green-500' : ''}>
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="text-sm capitalize">{profile.itemType}</CardTitle>
                  <p className="text-xs text-muted-foreground">{profile.description}</p>
                </div>
                {isEditing ? (
                  <div className="flex gap-1">
                    <Button size="sm" variant="ghost" onClick={cancelEdit}>
                      <X className="h-3 w-3" />
                    </Button>
                    <Button size="sm" onClick={() => saveProfile(profile)}>
                      <Save className="h-3 w-3" />
                    </Button>
                  </div>
                ) : savedId === profile.id ? (
                  <Badge variant="default" className="bg-green-500">
                    <Check className="h-3 w-3 mr-1" /> Saved
                  </Badge>
                ) : (
                  <Button size="sm" variant="ghost" onClick={() => startEdit(profile)}>
                    <Pencil className="h-3 w-3" />
                  </Button>
                )}
              </div>
            </CardHeader>
            <CardContent className="space-y-2">
              {/* Stat weight bars */}
              {STAT_NAMES.map((stat) => {
                const value = weights[stat] ?? 0
                const pct = maxWeight > 0 ? (value / maxWeight) * 100 : 0

                return (
                  <div key={stat} className="flex items-center gap-2">
                    <span className="text-xs font-mono w-8 uppercase">{stat}</span>
                    {isEditing ? (
                      <Input
                        type="number"
                        step="0.1"
                        min="0"
                        max="2"
                        value={editWeights[stat] ?? 0}
                        onChange={(e) =>
                          setEditWeights((prev) => ({
                            ...prev,
                            [stat]: parseFloat(e.target.value) || 0,
                          }))
                        }
                        className="h-6 w-16 text-xs"
                      />
                    ) : (
                      <>
                        <div className="flex-1 h-2 bg-muted rounded-full overflow-hidden">
                          <div
                            className={`h-full rounded-full ${STAT_COLORS[stat] ?? 'bg-zinc-500'}`}
                            style={{ width: `${pct}%` }}
                          />
                        </div>
                        <span className="text-xs text-muted-foreground w-8 text-right">
                          {value.toFixed(1)}
                        </span>
                      </>
                    )}
                  </div>
                )
              })}

              {/* Power weight */}
              <div className="flex items-center gap-2 pt-2 border-t">
                <span className="text-xs font-medium">Power Weight</span>
                {isEditing ? (
                  <Input
                    type="number"
                    step="0.05"
                    min="0"
                    max="2"
                    value={editPower}
                    onChange={(e) => setEditPower(parseFloat(e.target.value) || 1.0)}
                    className="h-6 w-16 text-xs"
                  />
                ) : (
                  <Badge variant="outline">{profile.powerWeight.toFixed(2)}</Badge>
                )}
              </div>
            </CardContent>
          </Card>
        )
      })}

      {profiles.length === 0 && (
        <div className="col-span-full text-center py-12 text-muted-foreground">
          No item balance profiles found. Run the balance seed script first.
        </div>
      )}
    </div>
  )
}
