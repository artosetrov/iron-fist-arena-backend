import { requireAdmin } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { MinigameSessionsClient, type MinigameSessionRow, type PerGameCount } from './minigame-sessions-client'

async function loadData() {
  const [sessions, perGameCounts] = await Promise.all([
    prisma.minigameSession.findMany({
      include: {
        character: {
          select: {
            characterName: true,
            user: { select: { email: true, username: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 200,
    }),
    prisma.minigameSession.groupBy({
      by: ['gameType'],
      _count: true,
      orderBy: { gameType: 'asc' },
    }),
  ])

  const rows: MinigameSessionRow[] = sessions.map((s) => ({
    id: s.id,
    characterId: s.characterId,
    characterName: s.character.characterName,
    userEmail: s.character.user?.email ?? null,
    userUsername: s.character.user?.username ?? null,
    gameType: s.gameType,
    status: s.status,
    betAmount: s.betAmount,
    claimedGold: s.claimedGold,
    claimedGems: s.claimedGems,
    createdAt: s.createdAt.toISOString(),
    claimedAt: s.claimedAt?.toISOString() ?? null,
    expiresAt: s.expiresAt?.toISOString() ?? null,
  }))

  const counts: PerGameCount[] = perGameCounts.map((g) => ({
    gameType: g.gameType,
    count: g._count,
  }))

  return { rows, counts }
}

export default async function MinigameSessionsPage() {
  await requireAdmin()
  const { rows, counts } = await loadData()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Minigame Sessions</h1>
        <p className="text-muted-foreground">
          Recent Gold Mine, Shell Game, Fortune Wheel, and other minigame
          activity. Filter by game type or character to audit daily-limit
          enforcement.
        </p>
      </div>
      <MinigameSessionsClient rows={rows} counts={counts} />
    </div>
  )
}
