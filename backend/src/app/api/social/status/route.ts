import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/social/status?character_id=xxx
 * Returns badge counts for the Guild Hall building on hub.
 * Also updates lastActiveAt for online status tracking.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { id: true, userId: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    // Update lastActiveAt (fire-and-forget)
    prisma.character.update({
      where: { id: characterId },
      data: { lastActiveAt: new Date() },
    }).catch(() => {})

    // Count pending friend requests (incoming)
    const pendingRequests = await prisma.friendship.count({
      where: { friendId: characterId, status: 'pending' },
    })

    // Count unread messages
    const unreadMessages = await prisma.directMessage.count({
      where: { receiverId: characterId, isRead: false },
    })

    // Count unseen revenge entries
    const pendingRevenges = await prisma.revengeQueue.count({
      where: {
        victimId: characterId,
        isUsed: false,
        isSeen: false,
        expiresAt: { gt: new Date() },
      },
    })

    // Count pending duel challenges (incoming)
    const pendingChallenges = await prisma.challenge.count({
      where: {
        defenderId: characterId,
        status: 'pending',
        expiresAt: { gt: new Date() },
      },
    })

    const totalBadge = pendingRequests + unreadMessages + pendingRevenges + pendingChallenges

    return NextResponse.json({
      pendingRequests,
      unreadMessages,
      pendingRevenges,
      pendingChallenges,
      totalBadge,
    })
  } catch (error) {
    console.error('GET /api/social/status error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

/**
 * GET /api/social/status/friendship?character_id=xxx&target_id=yyy
 * Returns friendship status between two characters (for button states).
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, target_id } = body as { character_id: string; target_id: string }

    if (!character_id || !target_id) {
      return NextResponse.json({ error: 'character_id and target_id required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: character_id },
      select: { id: true, userId: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    // Check both directions
    const [sentToTarget, receivedFromTarget] = await Promise.all([
      prisma.friendship.findUnique({
        where: { userId_friendId: { userId: character_id, friendId: target_id } },
      }),
      prisma.friendship.findUnique({
        where: { userId_friendId: { userId: target_id, friendId: character_id } },
      }),
    ])

    // Determine status
    let status: 'none' | 'friends' | 'request_sent' | 'request_received' | 'blocked' | 'blocked_by'
    if (sentToTarget?.status === 'blocked') {
      status = 'blocked'
    } else if (receivedFromTarget?.status === 'blocked') {
      status = 'blocked_by'
    } else if (sentToTarget?.status === 'accepted' || receivedFromTarget?.status === 'accepted') {
      status = 'friends'
    } else if (sentToTarget?.status === 'pending') {
      status = 'request_sent'
    } else if (receivedFromTarget?.status === 'pending') {
      status = 'request_received'
    } else {
      status = 'none'
    }

    return NextResponse.json({ status })
  } catch (error) {
    console.error('POST /api/social/status error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
