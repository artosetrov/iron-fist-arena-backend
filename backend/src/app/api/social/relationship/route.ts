import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/social/relationship?character_id=xxx&target_id=yyy
 * Returns relationship stats between two characters:
 * - friendship status (accepted / pending_sent / pending_received / none)
 * - PvP head-to-head stats (total battles, wins, losses, draws)
 * - last battle date
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    const targetId = req.nextUrl.searchParams.get('target_id')

    if (!characterId || !targetId) {
      return NextResponse.json({ error: 'character_id and target_id are required' }, { status: 400 })
    }

    // Verify character ownership
    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { id: true, userId: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    // Verify target exists
    const target = await prisma.character.findUnique({
      where: { id: targetId },
      select: { id: true },
    })
    if (!target) return NextResponse.json({ error: 'Target not found' }, { status: 404 })

    // Parallel: friendship + PvP stats
    const [friendship, pvpMatches] = await Promise.all([
      prisma.friendship.findFirst({
        where: {
          OR: [
            { userId: characterId, friendId: targetId },
            { userId: targetId, friendId: characterId },
          ],
        },
        select: { userId: true, status: true },
      }),
      prisma.pvpMatch.findMany({
        where: {
          OR: [
            { player1Id: characterId, player2Id: targetId },
            { player1Id: targetId, player2Id: characterId },
          ],
        },
        select: {
          winnerId: true,
          loserId: true,
          playedAt: true,
        },
        orderBy: { playedAt: 'desc' },
      }),
    ])

    // Resolve friendship status from current character's perspective
    let friendshipStatus: 'accepted' | 'pending_sent' | 'pending_received' | 'blocked' | 'none' = 'none'
    if (friendship) {
      if (friendship.status === 'accepted') {
        friendshipStatus = 'accepted'
      } else if (friendship.status === 'blocked') {
        friendshipStatus = 'blocked'
      } else if (friendship.status === 'pending') {
        friendshipStatus = friendship.userId === characterId ? 'pending_sent' : 'pending_received'
      }
    }

    // Calculate PvP head-to-head
    let wins = 0
    let losses = 0
    let draws = 0
    for (const match of pvpMatches) {
      if (match.winnerId === characterId) {
        wins++
      } else if (match.loserId === characterId) {
        losses++
      } else {
        draws++
      }
    }

    return NextResponse.json({
      friendshipStatus,
      pvp: {
        totalBattles: pvpMatches.length,
        wins,
        losses,
        draws,
        lastBattleAt: pvpMatches.length > 0 ? pvpMatches[0].playedAt : null,
      },
    })
  } catch (error) {
    console.error('GET /api/social/relationship error:', error)
    return NextResponse.json({ error: 'Failed to fetch relationship' }, { status: 500 })
  }
}
