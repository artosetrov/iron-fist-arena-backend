'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import {
  banPlayer, unbanPlayer, grantGold, grantGems, resetInventory,
} from '@/actions/players'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import { Separator } from '@/components/ui/separator'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from '@/components/ui/dialog'
import {
  ArrowLeft, Ban, ShieldCheck, Coins, Gem, Trash2,
} from 'lucide-react'
import { formatDate, capitalize } from '@/lib/utils'

type Equipment = {
  id: string
  itemId: string
  upgradeLevel: number
  isEquipped: boolean
  equippedSlot: string | null
  item: {
    itemName: string
    itemType: string
    rarity: string
  }
}

type Character = {
  id: string
  characterName: string
  class: string
  origin: string
  level: number
  prestigeLevel: number
  gold: number
  arenaTokens: number
  statPointsAvailable: number
  pvpRating: number
  pvpWins: number
  pvpLosses: number
  pvpWinStreak: number
  pvpCalibrationGames: number
  firstWinToday: boolean
  freePvpToday: number
  str: number
  agi: number
  vit: number
  end: number
  int: number
  wis: number
  luk: number
  cha: number
  currentHp: number
  maxHp: number
  armor: number
  magicResist: number
  gearScore: number
  currentStamina: number
  maxStamina: number
  equipment: Equipment[]
  achievements: { achievementKey: string; progress: number; target: number; completed: boolean }[]
}

type Player = {
  id: string
  email: string | null
  username: string | null
  gems: number
  role: string
  premiumUntil: string | null
  createdAt: string
  lastLogin: string | null
  isBanned: boolean
  banReason: string | null
  characters: Character[]
}

type Match = {
  id: string
  player1Id: string
  player2Id: string
  winnerId: string | null
  player1RatingBefore: number
  player1RatingAfter: number
  player2RatingBefore: number
  player2RatingAfter: number
  goldReward: number
  xpReward: number
  matchType: string
  isRevenge: boolean
  turnsTaken: number
  playedAt: string
  player1: { characterName: string }
  player2: { characterName: string }
}

type Purchase = {
  id: string
  productId: string
  transactionId: string
  gemsAwarded: number
  status: string
  createdAt: string
}

const RARITY_COLORS: Record<string, string> = {
  common: 'bg-zinc-600/20 text-zinc-400 border-zinc-600',
  uncommon: 'bg-green-600/20 text-green-400 border-green-600',
  rare: 'bg-blue-600/20 text-blue-400 border-blue-600',
  epic: 'bg-purple-600/20 text-purple-400 border-purple-600',
  legendary: 'bg-orange-600/20 text-orange-400 border-orange-600',
}

export function PlayerDetailClient({
  player,
  matchHistory,
  purchases,
}: {
  player: Player
  matchHistory: Match[]
  purchases: Purchase[]
}) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [selectedChar, setSelectedChar] = useState<Character | null>(
    player.characters[0] ?? null
  )
  const [goldAmount, setGoldAmount] = useState('')
  const [gemAmount, setGemAmount] = useState('')
  const [banReason, setBanReason] = useState('')
  const [resetDialogOpen, setResetDialogOpen] = useState(false)
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')

  function showMessage(msg: string) {
    setMessage(msg)
    setError('')
    setTimeout(() => setMessage(''), 3000)
  }

  function showError(msg: string) {
    setError(msg)
    setMessage('')
  }

  function handleGrantGold() {
    if (!selectedChar || !goldAmount || Number(goldAmount) <= 0) return
    startTransition(async () => {
      try {
        await grantGold(selectedChar.id, Number(goldAmount))
        showMessage(`Granted ${goldAmount} gold to ${selectedChar.characterName}`)
        setGoldAmount('')
        router.refresh()
      } catch (err) {
        showError(err instanceof Error ? err.message : 'Failed to grant gold')
      }
    })
  }

  function handleGrantGems() {
    if (!gemAmount || Number(gemAmount) <= 0) return
    startTransition(async () => {
      try {
        await grantGems(player.id, Number(gemAmount))
        showMessage(`Granted ${gemAmount} gems to ${player.username || player.email}`)
        setGemAmount('')
        router.refresh()
      } catch (err) {
        showError(err instanceof Error ? err.message : 'Failed to grant gems')
      }
    })
  }

  function handleBanToggle() {
    startTransition(async () => {
      try {
        if (player.isBanned) {
          await unbanPlayer(player.id)
          showMessage('Player unbanned')
        } else {
          if (!banReason) {
            showError('Ban reason is required')
            return
          }
          await banPlayer(player.id, banReason)
          showMessage('Player banned')
          setBanReason('')
        }
        router.refresh()
      } catch (err) {
        showError(err instanceof Error ? err.message : 'Failed')
      }
    })
  }

  function handleResetInventory() {
    if (!selectedChar) return
    startTransition(async () => {
      try {
        await resetInventory(selectedChar.id)
        showMessage(`Inventory reset for ${selectedChar.characterName}`)
        setResetDialogOpen(false)
        router.refresh()
      } catch (err) {
        showError(err instanceof Error ? err.message : 'Failed to reset')
      }
    })
  }

  return (
    <>
      <Button variant="ghost" size="sm" onClick={() => router.push('/players')}>
        <ArrowLeft className="mr-2 h-4 w-4" />
        Back to Players
      </Button>

      {message && (
        <div className="rounded-md bg-green-600/10 border border-green-600/30 px-4 py-3 text-sm text-green-400">
          {message}
        </div>
      )}
      {error && (
        <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
          {error}
        </div>
      )}

      {/* Account Info Card */}
      <Card>
        <CardHeader>
          <CardTitle>Account Information</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div>
              <p className="text-xs text-muted-foreground">Email</p>
              <p className="text-sm font-medium">{player.email || '---'}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Username</p>
              <p className="text-sm font-medium">{player.username || '---'}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Gems</p>
              <p className="text-sm font-medium">{player.gems.toLocaleString()}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Role</p>
              <Badge variant="secondary">{player.role}</Badge>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Premium Until</p>
              <p className="text-sm font-medium">{player.premiumUntil ? formatDate(player.premiumUntil) : 'N/A'}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Joined</p>
              <p className="text-sm font-medium">{formatDate(player.createdAt)}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Last Login</p>
              <p className="text-sm font-medium">{player.lastLogin ? formatDate(player.lastLogin) : 'Never'}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Status</p>
              {player.isBanned ? (
                <Badge variant="destructive">Banned: {player.banReason}</Badge>
              ) : (
                <Badge variant="success">Active</Badge>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Tabs: Characters | Equipment | Match History | Purchases */}
      <Tabs defaultValue="characters" className="w-full">
        <TabsList>
          <TabsTrigger value="characters">Characters ({player.characters.length})</TabsTrigger>
          <TabsTrigger value="equipment">Equipment</TabsTrigger>
          <TabsTrigger value="matches">Match History ({matchHistory.length})</TabsTrigger>
          <TabsTrigger value="purchases">Purchases ({purchases.length})</TabsTrigger>
        </TabsList>

        {/* Characters Tab */}
        <TabsContent value="characters" className="space-y-4 mt-4">
          {player.characters.length === 0 ? (
            <p className="text-sm text-muted-foreground">No characters.</p>
          ) : (
            <div className="grid gap-4 md:grid-cols-2">
              {player.characters.map((char) => (
                <Card
                  key={char.id}
                  className={`cursor-pointer transition-colors ${
                    selectedChar?.id === char.id ? 'border-primary' : ''
                  }`}
                  onClick={() => setSelectedChar(char)}
                >
                  <CardHeader className="pb-2">
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-base">{char.characterName}</CardTitle>
                      <div className="flex gap-1">
                        <Badge variant="secondary">{capitalize(char.class)}</Badge>
                        <Badge variant="secondary">{capitalize(char.origin)}</Badge>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-4 gap-2 text-xs">
                      <div>
                        <span className="text-muted-foreground">Level</span>
                        <p className="font-medium">{char.level}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">Prestige</span>
                        <p className="font-medium">{char.prestigeLevel}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">Gold</span>
                        <p className="font-medium">{char.gold.toLocaleString()}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">Rating</span>
                        <p className="font-medium">{char.pvpRating}</p>
                      </div>
                    </div>
                    <Separator className="my-2" />
                    <div className="grid grid-cols-4 gap-2 text-xs">
                      <div>
                        <span className="text-muted-foreground">STR</span>
                        <p className="font-medium">{char.str}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">AGI</span>
                        <p className="font-medium">{char.agi}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">VIT</span>
                        <p className="font-medium">{char.vit}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">END</span>
                        <p className="font-medium">{char.end}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">INT</span>
                        <p className="font-medium">{char.int}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">WIS</span>
                        <p className="font-medium">{char.wis}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">LUK</span>
                        <p className="font-medium">{char.luk}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">CHA</span>
                        <p className="font-medium">{char.cha}</p>
                      </div>
                    </div>
                    <Separator className="my-2" />
                    <div className="grid grid-cols-4 gap-2 text-xs">
                      <div>
                        <span className="text-muted-foreground">HP</span>
                        <p className="font-medium">{char.currentHp}/{char.maxHp}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">Armor</span>
                        <p className="font-medium">{char.armor}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">MR</span>
                        <p className="font-medium">{char.magicResist}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">Gear Score</span>
                        <p className="font-medium">{char.gearScore}</p>
                      </div>
                    </div>
                    <Separator className="my-2" />
                    <div className="grid grid-cols-4 gap-2 text-xs">
                      <div>
                        <span className="text-muted-foreground">W/L</span>
                        <p className="font-medium">{char.pvpWins}/{char.pvpLosses}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">Stamina</span>
                        <p className="font-medium">{char.currentStamina}/{char.maxStamina}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">Stat Pts</span>
                        <p className="font-medium">{char.statPointsAvailable}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">Tokens</span>
                        <p className="font-medium">{char.arenaTokens}</p>
                      </div>
                    </div>
                    <Separator className="my-2" />
                    <div className="grid grid-cols-4 gap-2 text-xs">
                      <div>
                        <span className="text-muted-foreground">Calibration</span>
                        <p className="font-medium">{char.pvpCalibrationGames}/10</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">Win Streak</span>
                        <p className="font-medium">{char.pvpWinStreak}</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">Free PvP</span>
                        <p className="font-medium">{char.freePvpToday}/3</p>
                      </div>
                      <div>
                        <span className="text-muted-foreground">1st Win</span>
                        <p className="font-medium">{char.firstWinToday ? 'Used' : 'Available'}</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* Equipment Tab */}
        <TabsContent value="equipment" className="mt-4">
          {!selectedChar ? (
            <p className="text-sm text-muted-foreground">Select a character to view equipment.</p>
          ) : selectedChar.equipment.length === 0 ? (
            <p className="text-sm text-muted-foreground">No equipment for {selectedChar.characterName}.</p>
          ) : (
            <div className="rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/50">
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Item</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Type</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Rarity</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">+Level</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Slot</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Equipped</th>
                  </tr>
                </thead>
                <tbody>
                  {selectedChar.equipment.map((eq) => (
                    <tr key={eq.id} className="border-b border-border">
                      <td className="px-4 py-3 font-medium">{eq.item.itemName}</td>
                      <td className="px-4 py-3">
                        <Badge variant="secondary">{eq.item.itemType}</Badge>
                      </td>
                      <td className="px-4 py-3">
                        <Badge className={RARITY_COLORS[eq.item.rarity] ?? ''}>
                          {eq.item.rarity}
                        </Badge>
                      </td>
                      <td className="px-4 py-3">+{eq.upgradeLevel}</td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {eq.equippedSlot ? capitalize(eq.equippedSlot) : '---'}
                      </td>
                      <td className="px-4 py-3">
                        {eq.isEquipped ? (
                          <Badge variant="success">Yes</Badge>
                        ) : (
                          <span className="text-muted-foreground">No</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </TabsContent>

        {/* Match History Tab */}
        <TabsContent value="matches" className="mt-4">
          {matchHistory.length === 0 ? (
            <p className="text-sm text-muted-foreground">No match history.</p>
          ) : (
            <div className="rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/50">
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Players</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Type</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Result</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Rating</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Rewards</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Date</th>
                  </tr>
                </thead>
                <tbody>
                  {matchHistory.map((match) => {
                    const charIds = player.characters.map((c) => c.id)
                    const isPlayer1 = charIds.includes(match.player1Id)
                    const isWinner = match.winnerId && charIds.includes(match.winnerId)
                    const ratingBefore = isPlayer1 ? match.player1RatingBefore : match.player2RatingBefore
                    const ratingAfter = isPlayer1 ? match.player1RatingAfter : match.player2RatingAfter
                    const ratingDiff = ratingAfter - ratingBefore

                    return (
                      <tr key={match.id} className="border-b border-border">
                        <td className="px-4 py-3">
                          <span className="font-medium">{match.player1.characterName}</span>
                          <span className="text-muted-foreground mx-1">vs</span>
                          <span className="font-medium">{match.player2.characterName}</span>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex gap-1">
                            <Badge variant="secondary">{match.matchType}</Badge>
                            {match.isRevenge && <Badge variant="warning">Revenge</Badge>}
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          {isWinner ? (
                            <Badge variant="success">Win</Badge>
                          ) : match.winnerId ? (
                            <Badge variant="destructive">Loss</Badge>
                          ) : (
                            <Badge variant="secondary">Draw</Badge>
                          )}
                        </td>
                        <td className="px-4 py-3 font-mono text-xs">
                          {ratingBefore} {' '}
                          <span className={ratingDiff >= 0 ? 'text-green-400' : 'text-red-400'}>
                            ({ratingDiff >= 0 ? '+' : ''}{ratingDiff})
                          </span>
                        </td>
                        <td className="px-4 py-3 text-xs text-muted-foreground">
                          {match.goldReward}g / {match.xpReward}xp
                        </td>
                        <td className="px-4 py-3 text-xs text-muted-foreground">
                          {formatDate(match.playedAt)}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          )}
        </TabsContent>

        {/* Purchases Tab */}
        <TabsContent value="purchases" className="mt-4">
          {purchases.length === 0 ? (
            <p className="text-sm text-muted-foreground">No purchases.</p>
          ) : (
            <div className="rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/50">
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Product</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Transaction ID</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Gems</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Date</th>
                  </tr>
                </thead>
                <tbody>
                  {purchases.map((p) => (
                    <tr key={p.id} className="border-b border-border">
                      <td className="px-4 py-3 font-medium">{p.productId}</td>
                      <td className="px-4 py-3 font-mono text-xs text-muted-foreground">{p.transactionId}</td>
                      <td className="px-4 py-3">{p.gemsAwarded.toLocaleString()}</td>
                      <td className="px-4 py-3">
                        <Badge variant={p.status === 'verified' ? 'success' : 'warning'}>
                          {p.status}
                        </Badge>
                      </td>
                      <td className="px-4 py-3 text-xs text-muted-foreground">{formatDate(p.createdAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </TabsContent>
      </Tabs>

      {/* Admin Actions Panel */}
      <Card>
        <CardHeader>
          <CardTitle>Admin Actions</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Grant Gold */}
          <div className="flex items-end gap-3">
            <div className="space-y-2 flex-1 max-w-xs">
              <Label>Grant Gold {selectedChar ? `(${selectedChar.characterName})` : ''}</Label>
              <Input
                type="number"
                min={1}
                placeholder="Amount"
                value={goldAmount}
                onChange={(e) => setGoldAmount(e.target.value)}
                disabled={!selectedChar}
              />
            </div>
            <Button
              onClick={handleGrantGold}
              disabled={isPending || !selectedChar || !goldAmount}
            >
              <Coins className="mr-2 h-4 w-4" />
              Grant Gold
            </Button>
          </div>

          {/* Grant Gems */}
          <div className="flex items-end gap-3">
            <div className="space-y-2 flex-1 max-w-xs">
              <Label>Grant Gems (Account)</Label>
              <Input
                type="number"
                min={1}
                placeholder="Amount"
                value={gemAmount}
                onChange={(e) => setGemAmount(e.target.value)}
              />
            </div>
            <Button onClick={handleGrantGems} disabled={isPending || !gemAmount}>
              <Gem className="mr-2 h-4 w-4" />
              Grant Gems
            </Button>
          </div>

          <Separator />

          {/* Ban / Unban */}
          <div className="flex items-end gap-3">
            {!player.isBanned && (
              <div className="space-y-2 flex-1 max-w-xs">
                <Label>Ban Reason</Label>
                <Input
                  placeholder="Reason..."
                  value={banReason}
                  onChange={(e) => setBanReason(e.target.value)}
                />
              </div>
            )}
            <Button
              variant={player.isBanned ? 'default' : 'destructive'}
              onClick={handleBanToggle}
              disabled={isPending || (!player.isBanned && !banReason)}
            >
              {player.isBanned ? (
                <>
                  <ShieldCheck className="mr-2 h-4 w-4" />
                  Unban Player
                </>
              ) : (
                <>
                  <Ban className="mr-2 h-4 w-4" />
                  Ban Player
                </>
              )}
            </Button>
          </div>

          <Separator />

          {/* Reset Inventory */}
          <div className="flex items-center gap-3">
            <Button
              variant="destructive"
              onClick={() => setResetDialogOpen(true)}
              disabled={!selectedChar || isPending}
            >
              <Trash2 className="mr-2 h-4 w-4" />
              Reset Inventory {selectedChar ? `(${selectedChar.characterName})` : ''}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Reset Inventory Confirmation */}
      <Dialog open={resetDialogOpen} onOpenChange={setResetDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reset Inventory</DialogTitle>
            <DialogDescription>
              This will permanently delete all equipment from {selectedChar?.characterName}.
              This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setResetDialogOpen(false)}>Cancel</Button>
            <Button variant="destructive" onClick={handleResetInventory} disabled={isPending}>
              {isPending ? 'Resetting...' : 'Reset Inventory'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  )
}
