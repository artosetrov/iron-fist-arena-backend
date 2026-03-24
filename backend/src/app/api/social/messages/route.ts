import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const MAX_MESSAGES_PER_DAY = 50
const MESSAGE_RATE_LIMIT_SECONDS = 3
const MESSAGE_EXPIRY_DAYS = 30
const MAX_CONTENT_LENGTH = 200

const QUICK_MESSAGES: Record<string, string> = {
  gg: 'Good game!',
  rematch: 'Rematch?',
  thanks: 'Thanks!',
  nice_fight: 'Nice fight!',
  well_played: 'Well played!',
  haha: 'Haha!',
  wow: 'Wow!',
  oops: 'Oops!',
}

/**
 * GET /api/social/messages?character_id=xxx
 * Returns conversations list grouped by the other character.
 * Each conversation includes: other character info, last message, unread count
 * Sorted by unread first, then by most recent message.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    const withCharacterId = req.nextUrl.searchParams.get('with')

    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    // Verify character ownership
    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { id: true, userId: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    // Thread view: messages between two specific characters
    if (withCharacterId) {
      const otherChar = await prisma.character.findUnique({
        where: { id: withCharacterId },
        select: { id: true },
      })
      if (!otherChar) return NextResponse.json({ error: 'Other character not found' }, { status: 404 })

      // Fetch last 50 messages in thread, ordered DESC
      const messages = await prisma.directMessage.findMany({
        where: {
          OR: [
            { senderId: characterId, receiverId: withCharacterId },
            { senderId: withCharacterId, receiverId: characterId },
          ],
        },
        select: {
          id: true,
          senderId: true,
          content: true,
          isQuick: true,
          quickId: true,
          isRead: true,
          createdAt: true,
        },
        orderBy: { createdAt: 'desc' },
        take: 50,
      })

      // Mark all unread messages FROM withCharacterId as read
      await prisma.directMessage.updateMany({
        where: {
          senderId: withCharacterId,
          receiverId: characterId,
          isRead: false,
        },
        data: { isRead: true },
      })

      // Reverse to ascending order for response
      return NextResponse.json({
        messages: messages.reverse(),
      })
    }

    // Conversations list view: group by other character
    const allMessages = await prisma.directMessage.findMany({
      where: {
        OR: [
          { senderId: characterId },
          { receiverId: characterId },
        ],
      },
      orderBy: { createdAt: 'desc' },
    })

    // Group by conversation partner (the "other" character)
    const conversationMap = new Map<string, any>()

    for (const msg of allMessages) {
      const otherCharId = msg.senderId === characterId ? msg.receiverId : msg.senderId
      if (!conversationMap.has(otherCharId)) {
        conversationMap.set(otherCharId, {
          otherCharacterId: otherCharId,
          lastMessage: msg,
          unreadCount: 0,
        })
      }
      const conv = conversationMap.get(otherCharId)
      if (!conv.lastMessage) {
        conv.lastMessage = msg
      }
      if (msg.receiverId === characterId && !msg.isRead) {
        conv.unreadCount += 1
      }
    }

    const conversations = Array.from(conversationMap.values())

    // Batch-load all character details in one query (fix N+1)
    const otherCharIds = conversations.map((c) => c.otherCharacterId)
    const otherChars = otherCharIds.length > 0
      ? await prisma.character.findMany({
          where: { id: { in: otherCharIds } },
          select: {
            id: true,
            characterName: true,
            class: true,
            level: true,
            pvpRating: true,
            avatar: true,
          },
        })
      : []
    const charMap = new Map(otherChars.map((c) => [c.id, c]))

    const conversationDetails = conversations.map((conv) => ({
      ...conv,
      otherCharacter: charMap.get(conv.otherCharacterId) ?? null,
    }))

    // Sort: unread first, then by most recent message
    conversationDetails.sort((a, b) => {
      if (a.unreadCount > 0 && b.unreadCount === 0) return -1
      if (a.unreadCount === 0 && b.unreadCount > 0) return 1
      return b.lastMessage.createdAt.getTime() - a.lastMessage.createdAt.getTime()
    })

    return NextResponse.json({
      conversations: conversationDetails.map((conv) => ({
        otherCharacter: conv.otherCharacter,
        lastMessage: {
          content: conv.lastMessage.content,
          createdAt: conv.lastMessage.createdAt,
          isRead: conv.lastMessage.isRead,
          senderId: conv.lastMessage.senderId,
        },
        unreadCount: conv.unreadCount,
      })),
    })
  } catch (err: any) {
    console.error('GET /api/social/messages error:', err)
    return NextResponse.json({ error: 'Failed to fetch messages' }, { status: 500 })
  }
}

/**
 * POST /api/social/messages
 * Actions: send, send_quick, mark_read
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, action } = body

    if (!character_id || !action) {
      return NextResponse.json({ error: 'character_id and action are required' }, { status: 400 })
    }

    // Verify character ownership
    const character = await prisma.character.findUnique({
      where: { id: character_id },
      select: { id: true, userId: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    switch (action) {
      case 'send':
        return await handleSend(character_id, body)
      case 'send_quick':
        return await handleSendQuick(character_id, body)
      case 'mark_read':
        return await handleMarkRead(character_id, body)
      default:
        return NextResponse.json({ error: `Unknown action: ${action}` }, { status: 400 })
    }
  } catch (err: any) {
    console.error('POST /api/social/messages error:', err)
    return NextResponse.json({ error: 'Failed to process message' }, { status: 500 })
  }
}

async function handleSend(senderId: string, body: any) {
  const { target_id, content } = body

  if (!target_id) {
    return NextResponse.json({ error: 'target_id is required' }, { status: 400 })
  }
  if (!content) {
    return NextResponse.json({ error: 'content is required' }, { status: 400 })
  }
  if (senderId === target_id) {
    return NextResponse.json({ error: 'Cannot message yourself' }, { status: 400 })
  }

  // Validate content length
  if (content.length > MAX_CONTENT_LENGTH) {
    return NextResponse.json(
      { error: `Content exceeds ${MAX_CONTENT_LENGTH} characters` },
      { status: 400 }
    )
  }

  // Verify target exists
  const target = await prisma.character.findUnique({
    where: { id: target_id },
    select: { id: true, characterName: true },
  })
  if (!target) {
    return NextResponse.json({ error: 'Target not found' }, { status: 404 })
  }

  // Check if either party has blocked the other (blocked users can't message)
  const blocked = await prisma.friendship.findFirst({
    where: {
      OR: [
        { userId: senderId, friendId: target_id, status: 'blocked' },
        { userId: target_id, friendId: senderId, status: 'blocked' },
      ],
    },
  })
  if (blocked) {
    return NextResponse.json({ error: 'Cannot send message to this player' }, { status: 403 })
  }

  const now = new Date()
  const todayStart = new Date()
  todayStart.setUTCHours(0, 0, 0, 0)

  // Check daily limit
  const sentToday = await prisma.directMessage.count({
    where: {
      senderId,
      createdAt: { gte: todayStart },
    },
  })
  if (sentToday >= MAX_MESSAGES_PER_DAY) {
    return NextResponse.json(
      { error: `Daily message limit reached (${MAX_MESSAGES_PER_DAY})` },
      { status: 429 }
    )
  }

  // Check rate limit (3 seconds between messages)
  const lastMessage = await prisma.directMessage.findFirst({
    where: { senderId },
    orderBy: { createdAt: 'desc' },
    take: 1,
  })
  if (lastMessage) {
    const secondsSinceLastMessage = (now.getTime() - lastMessage.createdAt.getTime()) / 1000
    if (secondsSinceLastMessage < MESSAGE_RATE_LIMIT_SECONDS) {
      return NextResponse.json(
        { error: `Rate limited. Wait ${MESSAGE_RATE_LIMIT_SECONDS} seconds between messages` },
        { status: 429 }
      )
    }
  }

  // Create message
  const expiresAt = new Date(now.getTime() + MESSAGE_EXPIRY_DAYS * 24 * 60 * 60 * 1000)

  const message = await prisma.directMessage.create({
    data: {
      senderId,
      receiverId: target_id,
      content,
      isQuick: false,
      expiresAt,
    },
  })

  return NextResponse.json({
    message: {
      id: message.id,
      content: message.content,
      createdAt: message.createdAt,
    },
  })
}

async function handleSendQuick(senderId: string, body: any) {
  const { target_id, quick_id } = body

  if (!target_id) {
    return NextResponse.json({ error: 'target_id is required' }, { status: 400 })
  }
  if (!quick_id) {
    return NextResponse.json({ error: 'quick_id is required' }, { status: 400 })
  }
  if (senderId === target_id) {
    return NextResponse.json({ error: 'Cannot message yourself' }, { status: 400 })
  }

  // Validate quick_id
  if (!QUICK_MESSAGES[quick_id]) {
    return NextResponse.json(
      { error: `Unknown quick_id: ${quick_id}. Valid: ${Object.keys(QUICK_MESSAGES).join(', ')}` },
      { status: 400 }
    )
  }

  // Verify target exists
  const target = await prisma.character.findUnique({
    where: { id: target_id },
    select: { id: true, characterName: true },
  })
  if (!target) {
    return NextResponse.json({ error: 'Target not found' }, { status: 404 })
  }

  // Check if either party has blocked the other
  const blocked = await prisma.friendship.findFirst({
    where: {
      OR: [
        { userId: senderId, friendId: target_id, status: 'blocked' },
        { userId: target_id, friendId: senderId, status: 'blocked' },
      ],
    },
  })
  if (blocked) {
    return NextResponse.json({ error: 'Cannot send message to this player' }, { status: 403 })
  }

  const now = new Date()
  const todayStart = new Date()
  todayStart.setUTCHours(0, 0, 0, 0)

  // Check daily limit
  const sentToday = await prisma.directMessage.count({
    where: {
      senderId,
      createdAt: { gte: todayStart },
    },
  })
  if (sentToday >= MAX_MESSAGES_PER_DAY) {
    return NextResponse.json(
      { error: `Daily message limit reached (${MAX_MESSAGES_PER_DAY})` },
      { status: 429 }
    )
  }

  // Check rate limit
  const lastMessage = await prisma.directMessage.findFirst({
    where: { senderId },
    orderBy: { createdAt: 'desc' },
    take: 1,
  })
  if (lastMessage) {
    const secondsSinceLastMessage = (now.getTime() - lastMessage.createdAt.getTime()) / 1000
    if (secondsSinceLastMessage < MESSAGE_RATE_LIMIT_SECONDS) {
      return NextResponse.json(
        { error: `Rate limited. Wait ${MESSAGE_RATE_LIMIT_SECONDS} seconds between messages` },
        { status: 429 }
      )
    }
  }

  // Create quick message
  const expiresAt = new Date(now.getTime() + MESSAGE_EXPIRY_DAYS * 24 * 60 * 60 * 1000)
  const content = QUICK_MESSAGES[quick_id]

  const message = await prisma.directMessage.create({
    data: {
      senderId,
      receiverId: target_id,
      content,
      isQuick: true,
      quickId: quick_id,
      expiresAt,
    },
  })

  return NextResponse.json({
    message: {
      id: message.id,
      content: message.content,
      quickId: quick_id,
      createdAt: message.createdAt,
    },
  })
}

async function handleMarkRead(characterId: string, body: any) {
  const { sender_id } = body

  if (!sender_id) {
    return NextResponse.json({ error: 'sender_id is required' }, { status: 400 })
  }

  // Mark all messages from sender_id to characterId as read
  const result = await prisma.directMessage.updateMany({
    where: {
      senderId: sender_id,
      receiverId: characterId,
      isRead: false,
    },
    data: { isRead: true },
  })

  return NextResponse.json({
    markedCount: result.count,
    message: 'Messages marked as read',
  })
}
