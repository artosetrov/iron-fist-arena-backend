import type { CharacterGender, CharacterOrigin } from '@prisma/client'

export const APPEARANCE_ORIGINS = [
  'human',
  'orc',
  'skeleton',
  'demon',
  'dogfolk',
] as const

export const APPEARANCE_GENDERS = ['male', 'female'] as const
export const APPEARANCE_RARITIES = [
  'common',
  'rare',
  'epic',
  'legendary',
] as const

export type AppearanceOrigin = typeof APPEARANCE_ORIGINS[number]
export type AppearanceGender = typeof APPEARANCE_GENDERS[number]
export type AppearanceRarity = typeof APPEARANCE_RARITIES[number]

export type AppearanceSkinRecord = {
  id: string
  skinKey: string
  name: string
  origin: CharacterOrigin
  gender: CharacterGender
  rarity: string
  priceGold: number
  priceGems: number
  imageUrl: string | null
  imageKey: string | null
  isDefault: boolean
  sortOrder: number
}

export type AppearanceSkinInput = {
  skinKey?: string
  name?: string
  origin?: string
  gender?: string
  rarity?: string
  priceGold?: number
  priceGems?: number
  imageUrl?: string | null
  imageKey?: string | null
  isDefault?: boolean
  sortOrder?: number
}

function parseNonNegativeInt(value: unknown, label: string): number {
  const parsed = typeof value === 'number' ? value : Number.parseInt(String(value), 10)
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new Error(`${label} must be a non-negative integer`)
  }

  return parsed
}

export function normalizeSkinKey(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
}

function parseOrigin(value: unknown): AppearanceOrigin {
  if (typeof value !== 'string') {
    throw new Error('Origin is required')
  }

  const normalized = value.trim().toLowerCase()
  if (!APPEARANCE_ORIGINS.includes(normalized as AppearanceOrigin)) {
    throw new Error('Invalid origin')
  }

  return normalized as AppearanceOrigin
}

function parseGender(value: unknown): AppearanceGender {
  if (typeof value !== 'string') {
    throw new Error('Gender is required')
  }

  const normalized = value.trim().toLowerCase()
  if (!APPEARANCE_GENDERS.includes(normalized as AppearanceGender)) {
    throw new Error('Invalid gender')
  }

  return normalized as AppearanceGender
}

function parseRarity(value: unknown): AppearanceRarity {
  if (typeof value !== 'string') {
    throw new Error('Rarity is required')
  }

  const normalized = value.trim().toLowerCase()
  if (!APPEARANCE_RARITIES.includes(normalized as AppearanceRarity)) {
    throw new Error('Invalid rarity')
  }

  return normalized as AppearanceRarity
}

function normalizeNullableString(value: string | null | undefined): string | null {
  if (value === undefined || value === null) return null
  const normalized = value.trim()
  return normalized.length > 0 ? normalized : null
}

export function sanitizeAppearanceSkinInput(
  input: AppearanceSkinInput,
  existing?: Omit<AppearanceSkinRecord, 'id'>
) {
  const skinKey = input.skinKey !== undefined
    ? normalizeSkinKey(input.skinKey)
    : existing?.skinKey ?? ''
  const name = input.name !== undefined ? input.name.trim() : existing?.name ?? ''

  if (!skinKey) throw new Error('Skin Key is required')
  if (!name) throw new Error('Name is required')

  const origin = input.origin !== undefined
    ? parseOrigin(input.origin)
    : parseOrigin(existing?.origin ?? '')
  const gender = input.gender !== undefined
    ? parseGender(input.gender)
    : parseGender(existing?.gender ?? '')
  const rarity = input.rarity !== undefined
    ? parseRarity(input.rarity)
    : parseRarity(existing?.rarity ?? '')
  const isDefault = input.isDefault ?? existing?.isDefault ?? false

  const priceGold = isDefault
    ? 0
    : input.priceGold !== undefined
      ? parseNonNegativeInt(input.priceGold, 'Gold price')
      : existing?.priceGold ?? 0
  const priceGems = isDefault
    ? 0
    : input.priceGems !== undefined
      ? parseNonNegativeInt(input.priceGems, 'Gem price')
      : existing?.priceGems ?? 0

  return {
    skinKey,
    name,
    origin,
    gender,
    rarity,
    priceGold,
    priceGems,
    imageUrl: normalizeNullableString(
      input.imageUrl !== undefined ? input.imageUrl : existing?.imageUrl ?? null
    ),
    imageKey: normalizeNullableString(
      input.imageKey !== undefined ? input.imageKey : existing?.imageKey ?? skinKey
    ) ?? skinKey,
    isDefault,
    sortOrder: input.sortOrder !== undefined
      ? parseNonNegativeInt(input.sortOrder, 'Sort order')
      : existing?.sortOrder ?? 0,
  }
}
