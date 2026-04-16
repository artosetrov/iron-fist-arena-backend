import type { Prisma } from '@prisma/client'

export type JsonValue = Prisma.JsonValue

export const SHOP_OFFER_TYPES = ['bundle', 'daily_deal', 'flash_sale', 'starter_pack', 'level_up'] as const
export type ShopOfferType = typeof SHOP_OFFER_TYPES[number]

export const SHOP_OFFER_CURRENCIES = ['gold', 'gems'] as const
export type ShopOfferCurrency = typeof SHOP_OFFER_CURRENCIES[number]

export const SHOP_OFFER_CONTENT_TYPES = ['gold', 'gems', 'item', 'consumable', 'xp'] as const
export type ShopOfferContentType = typeof SHOP_OFFER_CONTENT_TYPES[number]

export type OfferContentItem = {
  type: ShopOfferContentType
  id?: string
  quantity: number
}

export type ShopOfferRecord = {
  id: string
  key: string
  title: string
  description: string | null
  offerType: string
  contents: OfferContentItem[]
  originalPrice: number
  salePrice: number
  currency: string
  discountPct: number
  maxPurchases: number
  minLevel: number
  maxLevel: number
  sortOrder: number
  imageKey: string | null
  tags: string[]
  isActive: boolean
  startsAt: string | null
  endsAt: string | null
  createdBy: string | null
  createdAt: string
  _count: { purchases: number }
}

function parseInteger(value: unknown, label: string, minimum = 0): number {
  const parsed = typeof value === 'number' ? value : Number.parseInt(String(value), 10)
  if (!Number.isInteger(parsed) || parsed < minimum) {
    throw new Error(`${label} must be an integer >= ${minimum}`)
  }

  return parsed
}

export function normalizeOfferKey(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
}

export function parseOfferType(value: unknown): ShopOfferType {
  if (typeof value !== 'string' || !SHOP_OFFER_TYPES.includes(value as ShopOfferType)) {
    throw new Error('Invalid offer type')
  }

  return value as ShopOfferType
}

export function parseOfferCurrency(value: unknown): ShopOfferCurrency {
  if (typeof value !== 'string' || !SHOP_OFFER_CURRENCIES.includes(value as ShopOfferCurrency)) {
    throw new Error('Invalid offer currency')
  }

  return value as ShopOfferCurrency
}

export function normalizeOfferTags(value: unknown): string[] {
  const raw = Array.isArray(value) ? value : typeof value === 'string' ? value.split(',') : []
  return [...new Set(raw
    .filter((entry): entry is string => typeof entry === 'string')
    .map((entry) => entry.trim())
    .filter(Boolean))]
}

export function sanitizeOfferContents(value: unknown): OfferContentItem[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new Error('Offer contents must include at least one item')
  }

  return value.map((entry, index) => {
    if (typeof entry !== 'object' || entry === null || Array.isArray(entry)) {
      throw new Error(`Offer content #${index + 1} must be an object`)
    }

    const type = (entry as { type?: unknown }).type
    if (typeof type !== 'string' || !SHOP_OFFER_CONTENT_TYPES.includes(type as ShopOfferContentType)) {
      throw new Error(`Offer content #${index + 1} has invalid type`)
    }

    const quantity = parseInteger((entry as { quantity?: unknown }).quantity, `Offer content #${index + 1} quantity`, 1)
    const rawId = (entry as { id?: unknown }).id
    const id = typeof rawId === 'string' && rawId.trim() ? rawId.trim() : undefined

    if ((type === 'item' || type === 'consumable') && !id) {
      throw new Error(`Offer content #${index + 1} requires an id for ${type}`)
    }

    return {
      type: type as ShopOfferContentType,
      ...(id && (type === 'item' || type === 'consumable') && { id }),
      quantity,
    }
  })
}

export function parseOptionalOfferDate(value: string | null | undefined): Date | null {
  if (!value) return null

  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) {
    throw new Error('Offer schedule time is invalid')
  }

  return parsed
}
