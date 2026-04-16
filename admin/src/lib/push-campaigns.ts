import type { Prisma } from '@prisma/client'

export type JsonValue = Prisma.JsonValue

const CHARACTER_CLASSES = ['warrior', 'rogue', 'mage', 'tank'] as const
type CharacterClass = typeof CHARACTER_CLASSES[number]

export const PUSH_TARGET_TYPES = ['broadcast', 'segment', 'user'] as const
export type PushTargetType = typeof PUSH_TARGET_TYPES[number]

export type PushCampaignData = {
  route?: string
  offerId?: string
  eventId?: string
}

export type PushCampaignTargetFilter = {
  minLevel?: number
  maxLevel?: number
  class?: CharacterClass
  userIds?: string[]
}

export type PushCampaignRecord = {
  id: string
  title: string
  body: string
  data: JsonValue | null
  targetType: string
  targetFilter: JsonValue | null
  status: string
  sentCount: number
  failCount: number
  scheduledAt: Date | string | null
  sentAt: Date | string | null
  createdBy: string | null
  createdAt: Date | string
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function parsePositiveInteger(value: unknown, label: string): number | undefined {
  if (value === undefined || value === null || value === '') return undefined

  const parsed = typeof value === 'number' ? value : Number.parseInt(String(value), 10)
  if (!Number.isInteger(parsed) || parsed < 1) {
    throw new Error(`${label} must be a positive integer`)
  }

  return parsed
}

export function parsePushTargetType(value: unknown): PushTargetType {
  if (typeof value !== 'string' || !PUSH_TARGET_TYPES.includes(value as PushTargetType)) {
    throw new Error('Invalid push target type')
  }

  return value as PushTargetType
}

export function sanitizePushCampaignData(value: unknown): PushCampaignData | null {
  if (value === undefined || value === null) return null
  if (!isPlainObject(value)) throw new Error('Push data must be an object')

  const route = typeof value.route === 'string' && value.route.trim() ? value.route.trim() : undefined
  const offerId = typeof value.offerId === 'string' && value.offerId.trim() ? value.offerId.trim() : undefined
  const eventId = typeof value.eventId === 'string' && value.eventId.trim() ? value.eventId.trim() : undefined

  const data: PushCampaignData = {
    ...(route && { route }),
    ...(offerId && { offerId }),
    ...(eventId && { eventId }),
  }

  return Object.keys(data).length > 0 ? data : null
}

export function sanitizePushCampaignTargetFilter(
  targetType: PushTargetType,
  value: unknown
): PushCampaignTargetFilter | null {
  if (targetType === 'broadcast') {
    return null
  }

  if (!isPlainObject(value)) {
    throw new Error('Target filter is required')
  }

  if (targetType === 'user') {
    const rawUserIds = Array.isArray(value.userIds) ? value.userIds : String(value.userIds ?? '').split(',')
    const userIds = [...new Set(rawUserIds
      .filter((entry): entry is string => typeof entry === 'string')
      .map((entry) => entry.trim())
      .filter(Boolean))]

    if (userIds.length === 0) {
      throw new Error('User-targeted campaigns require at least one user ID')
    }

    return { userIds }
  }

  const minLevel = parsePositiveInteger(value.minLevel, 'Min level')
  const maxLevel = parsePositiveInteger(value.maxLevel, 'Max level')
  if (minLevel !== undefined && maxLevel !== undefined && minLevel > maxLevel) {
    throw new Error('Min level cannot exceed max level')
  }

  let characterClass: CharacterClass | undefined
  if (value.class !== undefined && value.class !== null && value.class !== '') {
    if (typeof value.class !== 'string' || !CHARACTER_CLASSES.includes(value.class as CharacterClass)) {
      throw new Error('Invalid target class')
    }
    characterClass = value.class as CharacterClass
  }

  const filter: PushCampaignTargetFilter = {
    ...(minLevel !== undefined && { minLevel }),
    ...(maxLevel !== undefined && { maxLevel }),
    ...(characterClass && { class: characterClass }),
  }

  if (Object.keys(filter).length === 0) {
    throw new Error('Segment campaigns require at least one filter')
  }

  return filter
}

export function readPushCampaignTargetFilter(
  targetTypeValue: unknown,
  value: unknown
): PushCampaignTargetFilter | null {
  try {
    return sanitizePushCampaignTargetFilter(parsePushTargetType(targetTypeValue), value)
  } catch {
    return null
  }
}

export function parseOptionalScheduledAt(value: string | null | undefined): Date | null {
  if (!value) return null

  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) {
    throw new Error('Scheduled time is invalid')
  }

  return parsed
}
