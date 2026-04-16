'use server'

import type { Prisma } from '@prisma/client'
import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import {
  normalizeOfferKey,
  normalizeOfferTags,
  parseOfferCurrency,
  parseOfferType,
  parseOptionalOfferDate,
  sanitizeOfferContents,
  type OfferContentItem,
  type ShopOfferCurrency,
  type ShopOfferType,
} from '@/lib/shop-offers'

type CreateOfferInput = {
  key: string
  title: string
  description?: string
  offerType?: unknown
  contents: unknown
  originalPrice: number
  salePrice: number
  currency?: unknown
  discountPct?: number
  maxPurchases?: number
  minLevel?: number
  maxLevel?: number
  sortOrder?: number
  imageKey?: string
  tags?: unknown
  isActive?: boolean
  startsAt?: string | null
  endsAt?: string | null
}

type UpdateOfferInput = Partial<CreateOfferInput> & { id: string }

type ExistingOfferShape = {
  key: string
  title: string
  description: string | null
  offerType: string
  contents: Prisma.JsonValue
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
  startsAt: Date | null
  endsAt: Date | null
}

type NormalizedOfferInput = {
  key: string
  title: string
  description: string | null
  offerType: ShopOfferType
  contents: OfferContentItem[]
  originalPrice: number
  salePrice: number
  currency: ShopOfferCurrency
  discountPct: number
  maxPurchases: number
  minLevel: number
  maxLevel: number
  sortOrder: number
  imageKey: string | null
  tags: string[]
  isActive: boolean
  startsAt: Date | null
  endsAt: Date | null
}

function parseInteger(value: unknown, label: string, minimum: number): number {
  const parsed = typeof value === 'number' ? value : Number.parseInt(String(value), 10)
  if (!Number.isInteger(parsed) || parsed < minimum) {
    throw new Error(`${label} must be an integer >= ${minimum}`)
  }

  return parsed
}

function normalizeOfferInput(
  input: Partial<CreateOfferInput>,
  existing?: ExistingOfferShape
): NormalizedOfferInput {
  const key = input.key !== undefined ? normalizeOfferKey(input.key) : normalizeOfferKey(existing?.key ?? '')
  const title = input.title !== undefined ? input.title.trim() : existing?.title?.trim() ?? ''

  if (!key) throw new Error('Offer key is required')
  if (!title) throw new Error('Offer title is required')

  const offerType = input.offerType !== undefined
    ? parseOfferType(input.offerType)
    : parseOfferType(existing?.offerType ?? 'bundle')

  const contents = input.contents !== undefined
    ? sanitizeOfferContents(input.contents)
    : sanitizeOfferContents(existing?.contents ?? [])

  const originalPrice = input.originalPrice !== undefined
    ? parseInteger(input.originalPrice, 'Original price', 0)
    : existing?.originalPrice ?? 0
  const salePrice = input.salePrice !== undefined
    ? parseInteger(input.salePrice, 'Sale price', 0)
    : existing?.salePrice ?? 0

  if (originalPrice > 0 && salePrice > originalPrice) {
    throw new Error('Sale price cannot exceed original price')
  }

  const discountPct = input.discountPct !== undefined
    ? parseInteger(input.discountPct, 'Discount', 0)
    : existing?.discountPct ?? 0
  if (discountPct > 100) throw new Error('Discount must be between 0 and 100')

  const minLevel = input.minLevel !== undefined
    ? parseInteger(input.minLevel, 'Min level', 1)
    : existing?.minLevel ?? 1
  const maxLevel = input.maxLevel !== undefined
    ? parseInteger(input.maxLevel, 'Max level', 1)
    : existing?.maxLevel ?? 999
  if (minLevel > maxLevel) throw new Error('Min level cannot exceed max level')

  const startsAt = input.startsAt !== undefined
    ? parseOptionalOfferDate(input.startsAt)
    : existing?.startsAt ?? null
  const endsAt = input.endsAt !== undefined
    ? parseOptionalOfferDate(input.endsAt)
    : existing?.endsAt ?? null
  if (startsAt && endsAt && startsAt > endsAt) {
    throw new Error('Offer end time must be after start time')
  }

  return {
    key,
    title,
    description: input.description !== undefined ? input.description.trim() || null : existing?.description ?? null,
    offerType,
    contents,
    originalPrice,
    salePrice,
    currency: input.currency !== undefined ? parseOfferCurrency(input.currency) : parseOfferCurrency(existing?.currency ?? 'gold'),
    discountPct,
    maxPurchases: input.maxPurchases !== undefined ? parseInteger(input.maxPurchases, 'Max purchases', 0) : existing?.maxPurchases ?? 1,
    minLevel,
    maxLevel,
    sortOrder: input.sortOrder !== undefined ? parseInteger(input.sortOrder, 'Sort order', 0) : existing?.sortOrder ?? 0,
    imageKey: input.imageKey !== undefined ? input.imageKey.trim() || null : existing?.imageKey ?? null,
    tags: input.tags !== undefined ? normalizeOfferTags(input.tags) : normalizeOfferTags(existing?.tags ?? []),
    isActive: input.isActive ?? existing?.isActive ?? false,
    startsAt,
    endsAt,
  }
}

async function requireAdminUser() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return admin
}

export async function listShopOffers() {
  await requireAdminUser()

  return prisma.shopOffer.findMany({
    orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
    include: {
      _count: { select: { purchases: true } },
    },
  })
}

export async function getShopOffer(id: string) {
  await requireAdminUser()

  return prisma.shopOffer.findUnique({
    where: { id },
    include: {
      purchases: {
        take: 50,
        orderBy: { createdAt: 'desc' },
        include: {
          character: { select: { characterName: true, level: true } },
        },
      },
      _count: { select: { purchases: true } },
    },
  })
}

export async function createShopOffer(input: CreateOfferInput) {
  const admin = await requireAdminUser()
  const normalized = normalizeOfferInput(input)

  return prisma.shopOffer.create({
    data: {
      key: normalized.key,
      title: normalized.title,
      description: normalized.description,
      offerType: normalized.offerType,
      contents: normalized.contents as unknown as Prisma.InputJsonValue,
      originalPrice: normalized.originalPrice,
      salePrice: normalized.salePrice,
      currency: normalized.currency,
      discountPct: normalized.discountPct,
      maxPurchases: normalized.maxPurchases,
      minLevel: normalized.minLevel,
      maxLevel: normalized.maxLevel,
      sortOrder: normalized.sortOrder,
      imageKey: normalized.imageKey,
      tags: normalized.tags,
      isActive: normalized.isActive,
      startsAt: normalized.startsAt,
      endsAt: normalized.endsAt,
      createdBy: admin.email ?? admin.id,
    },
  })
}

export async function updateShopOffer(input: UpdateOfferInput) {
  await requireAdminUser()

  const current = await prisma.shopOffer.findUnique({
    where: { id: input.id },
    select: {
      key: true,
      title: true,
      description: true,
      offerType: true,
      contents: true,
      originalPrice: true,
      salePrice: true,
      currency: true,
      discountPct: true,
      maxPurchases: true,
      minLevel: true,
      maxLevel: true,
      sortOrder: true,
      imageKey: true,
      tags: true,
      isActive: true,
      startsAt: true,
      endsAt: true,
    },
  })

  if (!current) throw new Error('Offer not found')

  const normalized = normalizeOfferInput(input, current)

  return prisma.shopOffer.update({
    where: { id: input.id },
    data: {
      key: normalized.key,
      title: normalized.title,
      description: normalized.description,
      offerType: normalized.offerType,
      contents: normalized.contents as unknown as Prisma.InputJsonValue,
      originalPrice: normalized.originalPrice,
      salePrice: normalized.salePrice,
      currency: normalized.currency,
      discountPct: normalized.discountPct,
      maxPurchases: normalized.maxPurchases,
      minLevel: normalized.minLevel,
      maxLevel: normalized.maxLevel,
      sortOrder: normalized.sortOrder,
      imageKey: normalized.imageKey,
      tags: normalized.tags,
      isActive: normalized.isActive,
      startsAt: normalized.startsAt,
      endsAt: normalized.endsAt,
    },
  })
}

export async function toggleShopOffer(id: string) {
  await requireAdminUser()

  const offer = await prisma.shopOffer.findUnique({ where: { id }, select: { isActive: true } })
  if (!offer) throw new Error('Offer not found')

  return prisma.shopOffer.update({
    where: { id },
    data: { isActive: !offer.isActive },
  })
}

export async function deleteShopOffer(id: string) {
  await requireAdminUser()
  return prisma.shopOffer.delete({ where: { id } })
}

export async function getOfferStats() {
  await requireAdminUser()

  const [total, active, totalPurchases, revenue] = await Promise.all([
    prisma.shopOffer.count(),
    prisma.shopOffer.count({ where: { isActive: true } }),
    prisma.shopOfferPurchase.count(),
    prisma.shopOfferPurchase.aggregate({ _sum: { price: true } }),
  ])

  return {
    total,
    active,
    totalPurchases,
    totalRevenue: revenue._sum.price ?? 0,
  }
}

export async function seedDefaultOffers() {
  const admin = await requireAdminUser()

  const defaults: Array<Omit<CreateOfferInput, 'contents'> & { contents: OfferContentItem[] }> = [
    {
      key: 'starter_pack',
      title: 'Starter Pack',
      description: 'Everything a new adventurer needs! Great value.',
      offerType: 'starter_pack',
      contents: [
        { type: 'gold', quantity: 500 },
        { type: 'gems', quantity: 50 },
        { type: 'consumable', id: 'stamina_potion_large', quantity: 3 },
        { type: 'consumable', id: 'health_potion_large', quantity: 3 },
      ],
      originalPrice: 200,
      salePrice: 99,
      currency: 'gems',
      discountPct: 50,
      maxPurchases: 1,
      minLevel: 1,
      maxLevel: 10,
      sortOrder: 1,
      tags: ['new_player', 'featured'],
    },
    {
      key: 'gold_rush_bundle',
      title: 'Gold Rush Bundle',
      description: 'A mountain of gold for the ambitious warrior.',
      offerType: 'bundle',
      contents: [
        { type: 'gold', quantity: 5000 },
        { type: 'xp', quantity: 500 },
      ],
      originalPrice: 300,
      salePrice: 199,
      currency: 'gems',
      discountPct: 33,
      maxPurchases: 3,
      sortOrder: 2,
      tags: ['popular'],
    },
    {
      key: 'potion_mega_pack',
      title: 'Potion Mega Pack',
      description: 'Stock up on potions for your adventures.',
      offerType: 'bundle',
      contents: [
        { type: 'consumable', id: 'stamina_potion_large', quantity: 10 },
        { type: 'consumable', id: 'health_potion_large', quantity: 10 },
      ],
      originalPrice: 2000,
      salePrice: 1200,
      currency: 'gold',
      discountPct: 40,
      maxPurchases: 0,
      sortOrder: 3,
      tags: ['potions'],
    },
    {
      key: 'level_up_boost',
      title: 'Level-Up Boost',
      description: 'Celebrate your milestone with bonus rewards!',
      offerType: 'level_up',
      contents: [
        { type: 'gold', quantity: 1000 },
        { type: 'gems', quantity: 25 },
        { type: 'xp', quantity: 300 },
      ],
      originalPrice: 150,
      salePrice: 75,
      currency: 'gems',
      discountPct: 50,
      maxPurchases: 1,
      minLevel: 5,
      sortOrder: 4,
      tags: ['milestone'],
    },
    {
      key: 'weekend_flash_sale',
      title: 'Weekend Flash Sale',
      description: 'Limited time! Gems at half price.',
      offerType: 'flash_sale',
      contents: [
        { type: 'gems', quantity: 100 },
        { type: 'gold', quantity: 2000 },
      ],
      originalPrice: 3000,
      salePrice: 1500,
      currency: 'gold',
      discountPct: 50,
      maxPurchases: 1,
      sortOrder: 5,
      tags: ['flash', 'weekend'],
    },
  ]

  let created = 0
  for (const definition of defaults) {
    const exists = await prisma.shopOffer.findUnique({ where: { key: definition.key } })
    if (exists) continue

    const normalized = normalizeOfferInput(definition)
    await prisma.shopOffer.create({
      data: {
        key: normalized.key,
        title: normalized.title,
        description: normalized.description,
        offerType: normalized.offerType,
        contents: normalized.contents as unknown as Prisma.InputJsonValue,
        originalPrice: normalized.originalPrice,
        salePrice: normalized.salePrice,
        currency: normalized.currency,
        discountPct: normalized.discountPct,
        maxPurchases: normalized.maxPurchases,
        minLevel: normalized.minLevel,
        maxLevel: normalized.maxLevel,
        sortOrder: normalized.sortOrder,
        imageKey: normalized.imageKey,
        tags: normalized.tags,
        isActive: false,
        startsAt: normalized.startsAt,
        endsAt: normalized.endsAt,
        createdBy: admin.email ?? admin.id,
      },
    })
    created++
  }

  return { created, skipped: defaults.length - created }
}
