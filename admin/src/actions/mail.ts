'use server'

import { prisma } from '@/lib/prisma'
import { Prisma } from '@prisma/client'
import { getAdminUser } from '@/lib/auth'
import { auditLog } from '@/lib/audit-log'

// ============================================================================
// Types
// ============================================================================

export interface Attachment {
  type: string
  amount: number
  itemId?: string
}

export interface SendMailInput {
  subject: string
  body: string
  senderType?: string
  senderName?: string
  attachments?: Attachment[]
  targetType: 'broadcast' | 'character' | 'segment'
  targetCharacterId?: string
  targetFilter?: {
    minLevel?: number
    maxLevel?: number
    class?: string
  }
  expiresAt?: Date
  createdBy?: string
}

export interface MailMessageWithRecipients {
  id: string
  subject: string
  body: string
  senderType: string
  senderName: string
  attachments: unknown
  targetType: string
  targetFilter: unknown
  expiresAt: Date | null
  createdBy: string | null
  createdAt: Date
  recipients: Array<{
    id: string
    messageId: string
    characterId: string
    isRead: boolean
    isClaimed: boolean
    isDeleted: boolean
    readAt: Date | null
    claimedAt: Date | null
    createdAt: Date
    character?: {
      characterName: string
      class: string
      level: number
    }
  }>
  _count?: {
    recipients: number
  }
}

// ============================================================================
// Main Actions
// ============================================================================

/**
 * Send mail to players based on target type
 */
export async function sendMail(data: SendMailInput) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const {
    subject,
    body,
    senderType = 'admin',
    senderName = 'Game Master',
    attachments,
    targetType,
    targetCharacterId,
    targetFilter,
    expiresAt,
    createdBy,
  } = data

  // Validate input
  if (!subject?.trim()) throw new Error('Subject is required')
  if (!body?.trim()) throw new Error('Body is required')
  if (!targetType) throw new Error('Target type is required')

  if (targetType === 'character' && !targetCharacterId) {
    throw new Error('Target character ID is required for character target type')
  }

  // Create the mail message
  const message = await prisma.mailMessage.create({
    data: {
      subject,
      body,
      senderType,
      senderName,
      attachments: (attachments ?? Prisma.JsonNull) as unknown as Prisma.InputJsonValue,
      targetType,
      targetFilter: (targetFilter ?? Prisma.JsonNull) as unknown as Prisma.InputJsonValue,
      expiresAt: expiresAt ? new Date(expiresAt) : null,
      createdBy: createdBy || admin.id,
    },
  })

  // Determine which characters to send to
  let characterIds: string[] = []

  if (targetType === 'broadcast') {
    // Get all active characters
    const characters = await prisma.character.findMany({
      select: { id: true },
    })
    characterIds = characters.map(c => c.id)
  } else if (targetType === 'character') {
    // Single character
    characterIds = [targetCharacterId!]
  } else if (targetType === 'segment') {
    // Query based on filter
    const where: Record<string, unknown> = {}

    if (targetFilter?.minLevel !== undefined) {
      where.level = { gte: targetFilter.minLevel }
    }
    if (targetFilter?.maxLevel !== undefined) {
      if (where.level && typeof where.level === 'object') {
        ;(where.level as Record<string, unknown>).lte = targetFilter.maxLevel
      } else {
        where.level = { lte: targetFilter.maxLevel }
      }
    }
    if (targetFilter?.class) {
      where.class = targetFilter.class
    }

    const characters = await prisma.character.findMany({
      where,
      select: { id: true },
    })
    characterIds = characters.map(c => c.id)
  }

  // Create mail recipients in bulk
  if (characterIds.length > 0) {
    await prisma.mailRecipient.createMany({
      data: characterIds.map(characterId => ({
        messageId: message.id,
        characterId,
      })),
    })
  }

  auditLog(admin, 'send_mail', `mail/${message.id}`, {
    subject,
    targetType,
    recipientCount: characterIds.length,
  })

  return {
    messageId: message.id,
    recipientCount: characterIds.length,
  }
}

/**
 * List all sent mail messages with pagination
 */
export async function listMailMessages(page = 1, limit = 20) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  if (page < 1) page = 1
  if (limit < 1 || limit > 100) limit = 20

  const skip = (page - 1) * limit

  const [messages, total] = await Promise.all([
    prisma.mailMessage.findMany({
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        _count: {
          select: { recipients: true },
        },
      },
    }),
    prisma.mailMessage.count(),
  ])

  // Get read and claimed counts for each message
  const enrichedMessages = await Promise.all(
    messages.map(async msg => {
      const [readCount, claimedCount] = await Promise.all([
        prisma.mailRecipient.count({
          where: { messageId: msg.id, isRead: true },
        }),
        prisma.mailRecipient.count({
          where: { messageId: msg.id, isClaimed: true },
        }),
      ])

      return {
        ...msg,
        readCount,
        claimedCount,
      }
    })
  )

  return {
    messages: enrichedMessages,
    total,
    page,
    limit,
  }
}

/**
 * Get a single mail message with its recipients
 */
export async function getMailMessage(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const message = await prisma.mailMessage.findUnique({
    where: { id },
    include: {
      recipients: {
        take: 100,
        orderBy: { createdAt: 'desc' },
        include: {
          character: {
            select: {
              characterName: true,
              class: true,
              level: true,
            },
          },
        },
      },
      _count: {
        select: { recipients: true },
      },
    },
  })

  if (!message) throw new Error('Mail message not found')

  return message
}

/**
 * Get overall mail stats
 */
export async function getMailStats() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const [totalMessages, totalRecipients, totalRead, totalClaimed, messagesCount] = await Promise.all([
    prisma.mailMessage.count(),
    prisma.mailRecipient.count(),
    prisma.mailRecipient.count({ where: { isRead: true } }),
    prisma.mailRecipient.count({ where: { isClaimed: true } }),
    prisma.mailMessage.count({
      where: {
        createdAt: {
          gte: new Date(new Date().setHours(0, 0, 0, 0)),
        },
      },
    }),
  ])

  return {
    totalMessages,
    totalRecipients,
    totalRead,
    totalClaimed,
    messagesToday: messagesCount,
  }
}

/**
 * Delete a mail message and all its recipients
 */
export async function deleteMailMessage(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  // Fetch the message info before deleting for audit log
  const message = await prisma.mailMessage.findUnique({
    where: { id },
    select: {
      subject: true,
      targetType: true,
    },
  })

  if (!message) throw new Error('Mail message not found')

  // Delete message and recipients (cascade)
  await prisma.mailMessage.delete({
    where: { id },
  })

  auditLog(admin, 'delete_mail', `mail/${id}`, {
    subject: message.subject,
    targetType: message.targetType,
  })

  return { success: true }
}
