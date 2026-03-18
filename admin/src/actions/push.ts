'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type CreateCampaignInput = {
  title: string
  body: string
  data?: Record<string, any>
  targetType?: string
  targetFilter?: Record<string, any>
  scheduledAt?: string | null
}

// ---------------------------------------------------------------------------
// Campaigns CRUD
// ---------------------------------------------------------------------------

export async function listCampaigns() {
  await getAdminUser()
  return prisma.pushCampaign.findMany({
    orderBy: { createdAt: 'desc' },
    take: 100,
  })
}

export async function createCampaign(input: CreateCampaignInput) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.pushCampaign.create({
    data: {
      title: input.title,
      body: input.body,
      data: input.data ?? undefined,
      targetType: input.targetType ?? 'broadcast',
      targetFilter: input.targetFilter ?? undefined,
      scheduledAt: input.scheduledAt ? new Date(input.scheduledAt) : null,
      createdBy: admin.email ?? admin.id,
    },
  })
}

export async function deleteCampaign(id: string) {
  await getAdminUser()
  return prisma.pushCampaign.delete({ where: { id } })
}

/**
 * "Send" a campaign — in real prod this would call the backend push API.
 * For admin panel, we update status and simulate the send.
 * In production, this should call a backend endpoint that does the actual APNS sends.
 */
export async function sendCampaign(id: string) {
  await getAdminUser()

  const campaign = await prisma.pushCampaign.findUnique({ where: { id } })
  if (!campaign) throw new Error('Campaign not found')
  if (campaign.status === 'sent') throw new Error('Already sent')

  // Count target tokens
  const filter = campaign.targetFilter as {
    minLevel?: number; maxLevel?: number; class?: string; userIds?: string[]
  } | null

  let tokenCount = 0

  if (campaign.targetType === 'user' && filter?.userIds?.length) {
    tokenCount = await prisma.pushToken.count({
      where: { userId: { in: filter.userIds }, isActive: true },
    })
  } else if (campaign.targetType === 'segment' && filter) {
    const charWhere: any = {}
    if (filter.minLevel) charWhere.level = { gte: filter.minLevel }
    if (filter.maxLevel) charWhere.level = { ...charWhere.level, lte: filter.maxLevel }
    if (filter.class) charWhere.class = filter.class

    const chars = await prisma.character.findMany({
      where: charWhere,
      select: { userId: true },
      distinct: ['userId'],
    })
    const userIds = chars.map(c => c.userId)
    tokenCount = await prisma.pushToken.count({
      where: { userId: { in: userIds }, isActive: true },
    })
  } else {
    // broadcast
    tokenCount = await prisma.pushToken.count({ where: { isActive: true } })
  }

  // Mark as sent (actual sending would happen via backend push service)
  await prisma.pushCampaign.update({
    where: { id },
    data: {
      status: 'sent',
      sentCount: tokenCount,
      sentAt: new Date(),
    },
  })

  return { tokenCount }
}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------

export async function getPushStats() {
  await getAdminUser()

  const [
    totalTokens,
    activeTokens,
    iosTokens,
    totalCampaigns,
    sentCampaigns,
    totalLogsSent,
    totalLogsFailed,
  ] = await Promise.all([
    prisma.pushToken.count(),
    prisma.pushToken.count({ where: { isActive: true } }),
    prisma.pushToken.count({ where: { isActive: true, platform: 'ios' } }),
    prisma.pushCampaign.count(),
    prisma.pushCampaign.count({ where: { status: 'sent' } }),
    prisma.pushLog.count({ where: { status: 'sent' } }),
    prisma.pushLog.count({ where: { status: 'failed' } }),
  ])

  return {
    totalTokens,
    activeTokens,
    iosTokens,
    totalCampaigns,
    sentCampaigns,
    totalLogsSent,
    totalLogsFailed,
  }
}

// ---------------------------------------------------------------------------
// Recent logs
// ---------------------------------------------------------------------------

export async function getRecentLogs(limit = 50) {
  await getAdminUser()
  return prisma.pushLog.findMany({
    orderBy: { createdAt: 'desc' },
    take: limit,
  })
}
