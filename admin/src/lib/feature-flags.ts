import type { Prisma } from '@prisma/client'

export type JsonValue = Prisma.JsonValue

export const FEATURE_FLAG_TYPES = ['boolean', 'percentage', 'segment', 'json'] as const
export type FeatureFlagType = typeof FEATURE_FLAG_TYPES[number]

export const FEATURE_FLAG_ENVIRONMENTS = ['all', 'production', 'staging', 'development'] as const
export type FeatureFlagEnvironment = typeof FEATURE_FLAG_ENVIRONMENTS[number]

export const FEATURE_FLAG_CLASSES = ['warrior', 'rogue', 'mage', 'tank'] as const
export type FeatureFlagClass = typeof FEATURE_FLAG_CLASSES[number]

export type FeatureFlagTargeting = {
  minLevel?: number
  maxLevel?: number
  class?: FeatureFlagClass
  userIds?: string[]
}

export type FeatureFlagRecord = {
  id: string
  key: string
  title: string
  description: string | null
  flagType: string
  value: JsonValue
  targeting: JsonValue | null
  isActive: boolean
  environment: string
  tags: string[]
  createdAt: Date
  updatedAt: Date
}

export type FeatureFlagStats = {
  total: number
  active: number
  inactive: number
  booleanCount: number
  percentageCount: number
}

export type FeatureFlagFormData = {
  key: string
  title: string
  description: string
  flagType: FeatureFlagType
  value: string
  environment: FeatureFlagEnvironment
  tags: string
  minLevel: string
  maxLevel: string
  class: string
  userIds: string
}

export const EMPTY_FEATURE_FLAG_FORM: FeatureFlagFormData = {
  key: '',
  title: '',
  description: '',
  flagType: 'boolean',
  value: 'true',
  environment: 'all',
  tags: '',
  minLevel: '',
  maxLevel: '',
  class: '',
  userIds: '',
}

const BOOLEAN_TYPES = new Set<FeatureFlagType>(['boolean', 'segment'])

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

export function isJsonValue(value: unknown): value is JsonValue {
  if (
    value === null ||
    typeof value === 'string' ||
    typeof value === 'number' ||
    typeof value === 'boolean'
  ) {
    return true
  }

  if (Array.isArray(value)) {
    return value.every(isJsonValue)
  }

  if (isPlainObject(value)) {
    return Object.values(value).every(isJsonValue)
  }

  return false
}

function parseIntegerField(value: unknown, label: string): number | undefined {
  if (value === undefined || value === null || value === '') return undefined

  const parsed = typeof value === 'number' ? value : Number.parseInt(String(value), 10)
  if (!Number.isInteger(parsed) || parsed < 1) {
    throw new Error(`${label} must be a positive integer`)
  }

  return parsed
}

function parseBooleanLike(value: unknown): boolean {
  if (typeof value === 'boolean') return value
  if (typeof value === 'string') return value.trim().toLowerCase() === 'true'
  return Boolean(value)
}

function parsePercentageLike(value: unknown): number {
  const parsed = typeof value === 'number' ? value : Number.parseInt(String(value), 10)
  if (!Number.isFinite(parsed)) {
    throw new Error('Percentage value must be a number between 0 and 100')
  }

  return Math.min(100, Math.max(0, Math.round(parsed)))
}

export function normalizeFeatureFlagKey(raw: string): string {
  return raw
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
}

export function isFeatureFlagType(value: unknown): value is FeatureFlagType {
  return typeof value === 'string' && FEATURE_FLAG_TYPES.includes(value as FeatureFlagType)
}

export function coerceFeatureFlagType(value: unknown): FeatureFlagType {
  return isFeatureFlagType(value) ? value : 'json'
}

export function parseFeatureFlagType(value: unknown): FeatureFlagType {
  if (!isFeatureFlagType(value)) {
    throw new Error('Invalid flag type')
  }

  return value
}

export function isFeatureFlagEnvironment(value: unknown): value is FeatureFlagEnvironment {
  return typeof value === 'string' && FEATURE_FLAG_ENVIRONMENTS.includes(value as FeatureFlagEnvironment)
}

export function coerceFeatureFlagEnvironment(value: unknown): FeatureFlagEnvironment {
  return isFeatureFlagEnvironment(value) ? value : 'all'
}

export function parseFeatureFlagEnvironment(value: unknown): FeatureFlagEnvironment {
  if (!isFeatureFlagEnvironment(value)) {
    throw new Error('Invalid environment')
  }

  return value
}

export function getDefaultFeatureFlagValue(flagType: FeatureFlagType): JsonValue {
  switch (flagType) {
    case 'percentage':
      return 0
    case 'json':
      return {}
    case 'boolean':
    case 'segment':
    default:
      return true
  }
}

export function sanitizeFeatureFlagValue(flagType: FeatureFlagType, value: unknown): JsonValue {
  if (value === undefined) {
    return getDefaultFeatureFlagValue(flagType)
  }

  if (BOOLEAN_TYPES.has(flagType)) {
    return parseBooleanLike(value)
  }

  if (flagType === 'percentage') {
    return parsePercentageLike(value)
  }

  if (typeof value === 'string') {
    const parsed = JSON.parse(value)
    if (!isJsonValue(parsed)) {
      throw new Error('JSON value must be valid JSON')
    }
    return parsed
  }

  if (!isJsonValue(value)) {
    throw new Error('JSON value must be valid JSON')
  }

  return value
}

export function sanitizeFeatureFlagTargeting(value: unknown): FeatureFlagTargeting | null {
  if (value === undefined || value === null) return null
  if (!isPlainObject(value)) throw new Error('Targeting must be an object')

  const minLevel = parseIntegerField(value.minLevel, 'Min level')
  const maxLevel = parseIntegerField(value.maxLevel, 'Max level')

  if (minLevel !== undefined && maxLevel !== undefined && minLevel > maxLevel) {
    throw new Error('Min level cannot exceed max level')
  }

  let characterClass: FeatureFlagClass | undefined
  if (value.class !== undefined && value.class !== null && value.class !== '') {
    if (
      typeof value.class !== 'string' ||
      !FEATURE_FLAG_CLASSES.includes(value.class as FeatureFlagClass)
    ) {
      throw new Error('Invalid targeting class')
    }
    characterClass = value.class as FeatureFlagClass
  }

  let userIds: string[] | undefined
  if (value.userIds !== undefined && value.userIds !== null && value.userIds !== '') {
    const rawUserIds = Array.isArray(value.userIds)
      ? value.userIds
      : String(value.userIds).split(',')

    userIds = [...new Set(rawUserIds
      .filter((entry): entry is string => typeof entry === 'string')
      .map((entry) => entry.trim())
      .filter(Boolean))]
  }

  const targeting: FeatureFlagTargeting = {
    ...(minLevel !== undefined && { minLevel }),
    ...(maxLevel !== undefined && { maxLevel }),
    ...(characterClass && { class: characterClass }),
    ...(userIds && userIds.length > 0 && { userIds }),
  }

  return Object.keys(targeting).length > 0 ? targeting : null
}

export function readFeatureFlagTargeting(value: unknown): FeatureFlagTargeting | null {
  try {
    return sanitizeFeatureFlagTargeting(value)
  } catch {
    return null
  }
}

export function normalizeFeatureFlagTags(value: unknown): string[] {
  const rawTags = Array.isArray(value)
    ? value
    : typeof value === 'string'
      ? value.split(',')
      : []

  return [...new Set(
    rawTags
      .filter((entry): entry is string => typeof entry === 'string')
      .map((entry) => entry.trim())
      .filter(Boolean)
  )]
}

export function formatFeatureFlagValueForForm(flagTypeValue: unknown, value: unknown): string {
  const flagType = coerceFeatureFlagType(flagTypeValue)

  if (BOOLEAN_TYPES.has(flagType)) {
    return parseBooleanLike(value) ? 'true' : 'false'
  }

  if (flagType === 'percentage') {
    return String(parsePercentageLike(value))
  }

  return JSON.stringify(isJsonValue(value) ? value : {}, null, 2)
}

export function displayFeatureFlagValue(flag: Pick<FeatureFlagRecord, 'flagType' | 'value'>): string {
  const flagType = coerceFeatureFlagType(flag.flagType)

  if (BOOLEAN_TYPES.has(flagType)) {
    return parseBooleanLike(flag.value) ? 'ON' : 'OFF'
  }

  if (flagType === 'percentage') {
    return `${parsePercentageLike(flag.value)}%`
  }

  return 'JSON'
}
