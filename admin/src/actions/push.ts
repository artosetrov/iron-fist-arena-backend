'use server'

import { Prisma } from '@prisma/client'
import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import {
  parseOptionalScheduledAt,
  parsePushTargetType,
  sanitizePushCampaignData,
  sanitizePushCampaignTargetFilter,
  type JsonValue,
  type PushCampaignTargetFilter,
  type PushTargetType,
} from '@/lib/push-campaigns'

type CreateCampaignInput = {
  title: string
  body: string
  data?: unknown
  targetType?: unknown
  targetFilter?: unknown
  scheduledAt?: string | null
}

type NormalizedCampaignInput = {
  title: string
  body: string
  data: JsonValue | null
  targetType: PushTargetType
  targetFilter: PushCampaignTargetFilter | null
  scheduledAt: Date | null
}

async function requireAdminUser() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return admin
}

function toNullableJsonInput(value: JsonValue | null): Prisma.InputJsonValue | Prisma.NullableJsonNullValueInput {
  return value === null ? Prisma.DbNull : value as Prisma.InputJsonValue
}

function normalizeCampaignInput(input: CreateCampaignInput): NormalizedCampaignInput {
  const title = input.title?.trim()
  const body = input.body?.trim()

  if (!title) throw new Error('Campaign title is required')
  if (!body) throw new Error('Campaign body is required')

  const targetType = input.targetType !== undefined
    ? parsePushTargetType(input.targetType)
    : 'broadcast'

  return {
    title,
    body,
    data: sanitizePushCampaignData(input.data),
    targetType,
    targetFilter: sanitizePushCampaignTargetFilter(targetType, input.targetFilter),
    scheduledAt: parseOptionalScheduledAt(input.scheduledAt),
  }
}

function buildCharacterWhere(filter: PushCampaignTargetFilter | null): Prisma.CharacterWhereInput {
  if (!filter) return {}

  return {
    ...(filter.minLevel !== undefined && {
      level: {
        ...(filter.minLevel !== undefined && { gte: filter.minLevel }),
        ...(filter.maxLevel !== undefined && { lte: filter.maxLevel }),
      },
    }),
    ...(filter.minLevel === undefined && filter.maxLevel !== undefined && {
      level: { lte: filter.maxLevel },
    }),
    ...(filter.class && { class: filter.class }),
  }
}

export async function listCampaigns() {
  await requireAdminUser()

  return prisma.pushCampaign.findMany({
    orderBy: { createdAt: 'desc' },
    take: 100,
  })
}

export async function createCampaign(input: CreateCampaignInput) {
  const admin = await requireAdminUser()
  const normalized = normalizeCampaignInput(input)

  return prisma.pushCampaign.create({
    data: {
      title: normalized.title,
      body: normalized.body,
      data: toNullableJsonInput(normalized.data),
      targetType: normalized.targetType,
      targetFilter: toNullableJsonInput(normalized.targetFilter as JsonValue | null),
      scheduledAt: normalized.scheduledAt,
      createdBy: admin.email ?? admin.id,
    },
  })
}

export async function deleteCampaign(id: string) {
  await requireAdminUser()
  return prisma.pushCampaign.delete({ where: { id } })
}

export async function sendCampaign(id: string) {
  await requireAdminUser()

  const campaign = await prisma.pushCampaign.findUnique({ where: { id } })
  if (!campaign) throw new Error('Campaign not found')
  if (campaign.status === 'sent') throw new Error('Already sent')

  const targetType = parsePushTargetType(campaign.targetType)
  const filter = sanitizePushCampaignTargetFilter(targetType, campaign.targetFilter)

  let tokenCount = 0

  if (targetType === 'user') {
    if (!filter?.userIds?.length) {
      throw new Error('User-targeted campaign is missing user IDs')
    }
    tokenCount = await prisma.pushToken.count({
      where: { userId: { in: filter.userIds }, isActive: true },
    })
  } else if (targetType === 'segment') {
    const characters = await prisma.character.findMany({
      where: buildCharacterWhere(filter),
      select: { userId: true },
      distinct: ['userId'],
    })

    const userIds = characters.map((character) => character.userId)
    if (userIds.length > 0) {
      tokenCount = await prisma.pushToken.count({
        where: { userId: { in: userIds }, isActive: true },
      })
    }
  } else {
    tokenCount = await prisma.pushToken.count({ where: { isActive: true } })
  }

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

export async function getPushStats() {
  await requireAdminUser()

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

export async function getRecentLogs(limit = 50) {
  await requireAdminUser()

  return prisma.pushLog.findMany({
    orderBy: { createdAt: 'desc' },
    take: limit,
  })
}
