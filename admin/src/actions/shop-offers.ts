'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type OfferContentItem = {
  type: 'gold' | 'gems' | 'item' | 'consumable' | 'xp'
  id?: string
  quantity: number
}

type CreateOfferInput = {
  key: string
  title: string
  description?: string
  offerType?: string
  contents: OfferContentItem[]
  originalPrice: number
  salePrice: number
  currency?: string
  discountPct?: number
  maxPurchases?: number
  minLevel?: number
  maxLevel?: number
  sortOrder?: number
  imageKey?: string
  tags?: string[]
  isActive?: boolean
  startsAt?: string | null
  endsAt?: string | null
}

type UpdateOfferInput = Partial<CreateOfferInput> & { id: string }

// ---------------------------------------------------------------------------
// CRUD
// ---------------------------------------------------------------------------

export async function listShopOffers() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.shopOffer.findMany({
    orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
    include: {
      _count: { select: { purchases: true } },
    },
  })
}

export async function getShopOffer(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
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
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized: Admin user not found')
  const adminUser = admin!
  return prisma.shopOffer.create({
    data: {
      key: input.key,
      title: input.title,
      description: input.description ?? null,
      offerType: input.offerType ?? 'bundle',
      contents: input.contents as any,
      originalPrice: input.originalPrice,
      salePrice: input.salePrice,
      currency: input.currency ?? 'gold',
      discountPct: input.discountPct ?? 0,
      maxPurchases: input.maxPurchases ?? 1,
      minLevel: input.minLevel ?? 1,
      maxLevel: input.maxLevel ?? 999,
      sortOrder: input.sortOrder ?? 0,
      imageKey: input.imageKey ?? null,
      tags: input.tags ?? [],
      isActive: input.isActive ?? false,
      startsAt: input.startsAt ? new Date(input.startsAt) : null,
      endsAt: input.endsAt ? new Date(input.endsAt) : null,
      createdBy: adminUser.email ?? adminUser.id,
    },
  })
}

export async function updateShopOffer(input: UpdateOfferInput) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const { id, startsAt, endsAt, ...rest } = input
  const data: any = { ...rest }
  if (startsAt !== undefined) data.startsAt = startsAt ? new Date(startsAt) : null
  if (endsAt !== undefined) data.endsAt = endsAt ? new Date(endsAt) : null
  if (rest.contents) data.contents = rest.contents as any
  return prisma.shopOffer.update({ where: { id }, data })
}

export async function toggleShopOffer(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const offer = await prisma.shopOffer.findUnique({ where: { id }, select: { isActive: true } })
  if (!offer) throw new Error('Offer not found')
  return prisma.shopOffer.update({
    where: { id },
    data: { isActive: !offer.isActive },
  })
}

export async function deleteShopOffer(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.shopOffer.delete({ where: { id } })
}

export async function getOfferStats() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
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
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized: Admin user not found')
  const defaults: CreateOfferInput[] = [
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
  for (const d of defaults) {
    const exists = await prisma.shopOffer.findUnique({ where: { key: d.key } })
    if (!exists) {
      await prisma.shopOffer.create({
        data: {
          key: d.key,
          title: d.title,
          description: d.description ?? null,
          offerType: d.offerType ?? 'bundle',
          contents: d.contents as any,
          originalPrice: d.originalPrice,
          salePrice: d.salePrice,
          currency: d.currency ?? 'gold',
          discountPct: d.discountPct ?? 0,
          maxPurchases: d.maxPurchases ?? 1,
          minLevel: d.minLevel ?? 1,
          maxLevel: d.maxLevel ?? 999,
          sortOrder: d.sortOrder ?? 0,
          tags: d.tags ?? [],
          isActive: false,
          createdBy: admin.email ?? admin.id,
        },
      })
      created++
    }
  }

  return { created, skipped: defaults.length - created }
}
