export const ACHIEVEMENT_CATEGORIES = [
  'pvp',
  'revenge',
  'progression',
  'prestige',
  'equipment',
  'dungeon',
  'economy',
  'minigame',
  'ranking',
  'daily',
] as const

export const ACHIEVEMENT_REWARD_TYPES = ['gold', 'gems', 'xp'] as const
const LEGACY_ACHIEVEMENT_REWARD_TYPES = ['title', 'frame'] as const
const STORED_ACHIEVEMENT_REWARD_TYPES = [
  ...ACHIEVEMENT_REWARD_TYPES,
  ...LEGACY_ACHIEVEMENT_REWARD_TYPES,
] as const

export type AchievementCategory = typeof ACHIEVEMENT_CATEGORIES[number]
export type AchievementRewardType = typeof ACHIEVEMENT_REWARD_TYPES[number]
type StoredAchievementRewardType = typeof STORED_ACHIEVEMENT_REWARD_TYPES[number]

export type AchievementDefinitionRecord = {
  id: string
  key: string
  title: string
  description: string
  category: string
  target: number
  rewardType: string
  rewardAmount: number
  rewardId: string | null
  icon: string | null
  active: boolean
  sortOrder: number
}

export type AchievementDefinitionInput = {
  key?: string
  title?: string
  description?: string
  category?: string
  target?: number
  rewardType?: string
  rewardAmount?: number
  rewardId?: string | null
  icon?: string | null
  active?: boolean
  sortOrder?: number
}

function parsePositiveInt(value: unknown, label: string): number {
  const parsed = typeof value === 'number' ? value : Number.parseInt(String(value), 10)
  if (!Number.isInteger(parsed) || parsed < 1) {
    throw new Error(`${label} must be a positive integer`)
  }

  return parsed
}

function parseNonNegativeInt(value: unknown, label: string): number {
  const parsed = typeof value === 'number' ? value : Number.parseInt(String(value), 10)
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new Error(`${label} must be a non-negative integer`)
  }

  return parsed
}

export function normalizeAchievementKey(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
}

export function parseAchievementCategory(value: unknown): AchievementCategory {
  if (typeof value !== 'string') {
    throw new Error('Category is required')
  }

  const normalized = value.trim().toLowerCase()
  if (!ACHIEVEMENT_CATEGORIES.includes(normalized as AchievementCategory)) {
    throw new Error('Invalid category')
  }

  return normalized as AchievementCategory
}

export function parseAchievementRewardType(value: unknown): AchievementRewardType {
  if (typeof value !== 'string') {
    throw new Error('Reward type is required')
  }

  const normalized = value.trim().toLowerCase()
  if (!ACHIEVEMENT_REWARD_TYPES.includes(normalized as AchievementRewardType)) {
    throw new Error('Invalid reward type')
  }

  return normalized as AchievementRewardType
}

function parseStoredAchievementRewardType(
  value: unknown
): StoredAchievementRewardType {
  if (typeof value !== 'string') {
    throw new Error('Reward type is required')
  }

  const normalized = value.trim().toLowerCase()
  if (
    !STORED_ACHIEVEMENT_REWARD_TYPES.includes(
      normalized as StoredAchievementRewardType
    )
  ) {
    throw new Error('Invalid reward type')
  }

  return normalized as StoredAchievementRewardType
}

export function sanitizeAchievementDefinitionInput(
  input: AchievementDefinitionInput,
  existing?: Omit<AchievementDefinitionRecord, 'id'>
) {
  const key = input.key !== undefined
    ? normalizeAchievementKey(input.key)
    : existing?.key ?? ''
  const title = input.title !== undefined ? input.title.trim() : existing?.title ?? ''
  const description = input.description !== undefined ? input.description.trim() : existing?.description ?? ''

  if (!key) throw new Error('Achievement key is required')
  if (!title) throw new Error('Title is required')
  if (!description) throw new Error('Description is required')

  const category = input.category !== undefined
    ? parseAchievementCategory(input.category)
    : parseAchievementCategory(existing?.category ?? '')
  const rewardType = input.rewardType !== undefined
    ? parseAchievementRewardType(input.rewardType)
    : parseStoredAchievementRewardType(existing?.rewardType ?? '')

  return {
    key,
    title,
    description,
    category,
    target: input.target !== undefined
      ? parsePositiveInt(input.target, 'Target')
      : parsePositiveInt(existing?.target, 'Target'),
    rewardType,
    rewardAmount: input.rewardAmount !== undefined
      ? parsePositiveInt(input.rewardAmount, 'Reward amount')
      : parsePositiveInt(existing?.rewardAmount, 'Reward amount'),
    rewardId: null,
    icon: input.icon !== undefined
      ? input.icon?.trim() || null
      : existing?.icon ?? null,
    active: input.active ?? existing?.active ?? true,
    sortOrder: input.sortOrder !== undefined
      ? parseNonNegativeInt(input.sortOrder, 'Sort order')
      : existing?.sortOrder ?? 0,
  }
}
