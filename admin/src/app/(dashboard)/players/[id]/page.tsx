import { getPlayerDetails } from '@/actions/players'
import { prisma } from '@/lib/prisma'
import { notFound } from 'next/navigation'
import { PlayerDetailClient } from './player-client'

async function getMatchHistory(characterIds: string[]) {
  if (characterIds.length === 0) return []
  return prisma.pvpMatch.findMany({
    where: {
      OR: [
        { player1Id: { in: characterIds } },
        { player2Id: { in: characterIds } },
      ],
    },
    orderBy: { playedAt: 'desc' },
    take: 50,
    select: {
      id: true,
      player1Id: true,
      player2Id: true,
      winnerId: true,
      player1RatingBefore: true,
      player1RatingAfter: true,
      player2RatingBefore: true,
      player2RatingAfter: true,
      goldReward: true,
      xpReward: true,
      matchType: true,
      isRevenge: true,
      turnsTaken: true,
      playedAt: true,
      player1: { select: { characterName: true } },
      player2: { select: { characterName: true } },
    },
  })
}

async function getPurchases(userId: string) {
  return prisma.iapTransaction.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    take: 50,
  })
}

export default async function PlayerDetailPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  let player
  try {
    player = await getPlayerDetails(id)
  } catch {
    notFound()
  }

  const characterIds = player.characters.map((c) => c.id)
  const [matchHistory, purchases] = await Promise.all([
    getMatchHistory(characterIds),
    getPurchases(player.id),
  ])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">
          Player: {player.username || player.email || 'Unknown'}
        </h1>
        <p className="text-muted-foreground">
          Player ID: {player.id}
        </p>
      </div>
      <PlayerDetailClient
        player={JSON.parse(JSON.stringify(player))}
        matchHistory={JSON.parse(JSON.stringify(matchHistory))}
        purchases={JSON.parse(JSON.stringify(purchases))}
      />
    </div>
  )
}
