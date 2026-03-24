import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const MAX_FRIENDS = 50
const MAX_REQUESTS_PER_DAY = 20
const REQUEST_COOLDOWN_HOURS = 24
const REQUEST_EXPIRY_DAYS = 7

/**
 * GET /api/social/friends?character_id=xxx
 * Returns friends list + pending requests for the character.
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

    // Fetch all friendships involving this character
    const [sentFriendships, receivedFriendships] = await Promise.all([
      prisma.friendship.findMany({
        where: { userId: characterId, status: { in: ['accepted', 'pending'] } },
        include: {
          friend: {
            select: {
              id: true, characterName: true, class: true, origin: true,
              level: true, pvpRating: true, avatar: true, lastActiveAt: true,
            },
          },
        },
        orderBy: { updatedAt: 'desc' },
      }),
      prisma.friendship.findMany({
        where: { friendId: characterId, status: { in: ['accepted', 'pending'] } },
        include: {
          user: {
            select: {
              id: true, characterName: true, class: true, origin: true,
              level: true, pvpRating: true, avatar: true, lastActiveAt: true,
            },
          },
        },
        orderBy: { updatedAt: 'desc' },
      }),
    ])

    // Build friends list (accepted from both directions)
    const friends = [
      ...sentFriendships
        .filter((f: any) => f.status === 'accepted')
        .map((f: any) => ({ ...f.friend, friendshipId: f.id })),
      ...receivedFriendships
        .filter((f: any) => f.status === 'accepted')
        .map((f: any) => ({ ...f.user, friendshipId: f.id })),
    ]

    // Pending requests RECEIVED (others sent to me)
    const incomingRequests = receivedFriendships
      .filter((f: any) => f.status === 'pending')
      .map((f: any) => ({
        friendshipId: f.id,
        ...f.user,
        requestedAt: f.createdAt,
      }))

    // Pending requests SENT (I sent to others)
    const outgoingRequests = sentFriendships
      .filter((f: any) => f.status === 'pending')
      .map((f: any) => ({
        friendshipId: f.id,
        ...f.friend,
        requestedAt: f.createdAt,
      }))

    // Blocked users
    const blocked = await prisma.friendship.findMany({
      where: { userId: characterId, status: 'blocked' },
      include: {
        friend: {
          select: { id: true, characterName: true, class: true, level: true },
        },
      },
    })

    return NextResponse.json({
      friends,
      incomingRequests,
      outgoingRequests,
      blockedUsers: blocked.map((b: any) => ({ friendshipId: b.id, ...b.friend })),
      count: friends.length,
      maxFriends: MAX_FRIENDS,
    })
  } catch (error) {
    console.error('GET /api/social/friends error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

/**
 * POST /api/social/friends
 * Actions: request, accept, decline, remove, block, unblock
 * Body: { character_id, target_id, action }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, target_id, action } = body as {
      character_id: string
      target_id: string
      action: 'request' | 'accept' | 'decline' | 'remove' | 'block' | 'unblock'
    }

    if (!character_id || !target_id || !action) {
      return NextResponse.json({ error: 'character_id, target_id, and action are required' }, { status: 400 })
    }
    if (character_id === target_id) {
      return NextResponse.json({ error: 'Cannot target yourself' }, { status: 400 })
    }

    // Verify ownership
    const character = await prisma.character.findUnique({
      where: { id: character_id },
      select: { id: true, userId: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    // Verify target exists
    const target = await prisma.character.findUnique({
      where: { id: target_id },
      select: { id: true, characterName: true },
    })
    if (!target) return NextResponse.json({ error: 'Target not found' }, { status: 404 })

    switch (action) {
      case 'request':
        return await handleRequest(character_id, target_id)
      case 'accept':
        return await handleAccept(character_id, target_id)
      case 'decline':
        return await handleDecline(character_id, target_id)
      case 'remove':
        return await handleRemove(character_id, target_id)
      case 'block':
        return await handleBlock(character_id, target_id)
      case 'unblock':
        return await handleUnblock(character_id, target_id)
      default:
        return NextResponse.json({ error: 'Invalid action' }, { status: 400 })
    }
  } catch (error) {
    console.error('POST /api/social/friends error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

// ──── Action Handlers ────

async function handleRequest(userId: string, friendId: string) {
  // Check if blocked by target
  const blockedByTarget = await prisma.friendship.findUnique({
    where: { userId_friendId: { userId: friendId, friendId: userId } },
  })
  if (blockedByTarget?.status === 'blocked') {
    return NextResponse.json({ error: 'Cannot send request' }, { status: 403 })
  }

  // Check if already friends or pending
  const existing = await prisma.friendship.findFirst({
    where: {
      OR: [
        { userId, friendId },
        { userId: friendId, friendId: userId },
      ],
      status: { in: ['accepted', 'pending'] },
    },
  })
  if (existing) {
    return NextResponse.json({ error: 'Already friends or request pending' }, { status: 409 })
  }

  // Check friend limit
  const friendCount = await prisma.friendship.count({
    where: {
      OR: [{ userId }, { friendId: userId }],
      status: 'accepted',
    },
  })
  if (friendCount >= MAX_FRIENDS) {
    return NextResponse.json({ error: 'Friend list full' }, { status: 400 })
  }

  // Check daily request limit
  const todayStart = new Date()
  todayStart.setHours(0, 0, 0, 0)
  const requestsToday = await prisma.friendship.count({
    where: {
      userId,
      status: 'pending',
      createdAt: { gte: todayStart },
    },
  })
  if (requestsToday >= MAX_REQUESTS_PER_DAY) {
    return NextResponse.json({ error: 'Too many requests today' }, { status: 429 })
  }

  // Check cooldown (declined request)
  const recentDeclined = await prisma.friendship.findFirst({
    where: {
      userId,
      friendId,
      status: 'pending',
      updatedAt: { gte: new Date(Date.now() - REQUEST_COOLDOWN_HOURS * 60 * 60 * 1000) },
    },
  })
  if (recentDeclined) {
    return NextResponse.json({ error: 'Cooldown active' }, { status: 429 })
  }

  // Delete old declined entry if exists, then create new
  await prisma.friendship.deleteMany({
    where: {
      OR: [
        { userId, friendId },
        { userId: friendId, friendId: userId },
      ],
      status: { notIn: ['accepted', 'blocked'] },
    },
  })

  const friendship = await prisma.friendship.create({
    data: { userId, friendId, status: 'pending' },
  })

  return NextResponse.json({ friendship, message: 'Request sent' })
}

async function handleAccept(characterId: string, requesterId: string) {
  // Find the pending request FROM requester TO me
  const request = await prisma.friendship.findUnique({
    where: { userId_friendId: { userId: requesterId, friendId: characterId } },
  })
  if (!request || request.status !== 'pending') {
    return NextResponse.json({ error: 'No pending request found' }, { status: 404 })
  }

  // Check friend limit for both
  const [myCount, theirCount] = await Promise.all([
    prisma.friendship.count({
      where: { OR: [{ userId: characterId }, { friendId: characterId }], status: 'accepted' },
    }),
    prisma.friendship.count({
      where: { OR: [{ userId: requesterId }, { friendId: requesterId }], status: 'accepted' },
    }),
  ])
  if (myCount >= MAX_FRIENDS) {
    return NextResponse.json({ error: 'Your friend list is full' }, { status: 400 })
  }
  if (theirCount >= MAX_FRIENDS) {
    return NextResponse.json({ error: 'Their friend list is full' }, { status: 400 })
  }

  const updated = await prisma.friendship.update({
    where: { id: request.id },
    data: { status: 'accepted' },
  })

  return NextResponse.json({ friendship: updated, message: 'Friend added' })
}

async function handleDecline(characterId: string, requesterId: string) {
  const request = await prisma.friendship.findUnique({
    where: { userId_friendId: { userId: requesterId, friendId: characterId } },
  })
  if (!request || request.status !== 'pending') {
    return NextResponse.json({ error: 'No pending request found' }, { status: 404 })
  }

  await prisma.friendship.delete({ where: { id: request.id } })
  return NextResponse.json({ message: 'Request declined' })
}

async function handleRemove(characterId: string, friendId: string) {
  const deleted = await prisma.friendship.deleteMany({
    where: {
      OR: [
        { userId: characterId, friendId, status: 'accepted' },
        { userId: friendId, friendId: characterId, status: 'accepted' },
      ],
    },
  })
  if (deleted.count === 0) {
    return NextResponse.json({ error: 'Not friends' }, { status: 404 })
  }
  return NextResponse.json({ message: 'Friend removed' })
}

async function handleBlock(characterId: string, targetId: string) {
  // Remove any existing friendship first
  await prisma.friendship.deleteMany({
    where: {
      OR: [
        { userId: characterId, friendId: targetId },
        { userId: targetId, friendId: characterId },
      ],
    },
  })

  // Create block entry
  await prisma.friendship.create({
    data: { userId: characterId, friendId: targetId, status: 'blocked' },
  })

  return NextResponse.json({ message: 'User blocked' })
}

async function handleUnblock(characterId: string, targetId: string) {
  const deleted = await prisma.friendship.deleteMany({
    where: { userId: characterId, friendId: targetId, status: 'blocked' },
  })
  if (deleted.count === 0) {
    return NextResponse.json({ error: 'Not blocked' }, { status: 404 })
  }
  return NextResponse.json({ message: 'User unblocked' })
}
