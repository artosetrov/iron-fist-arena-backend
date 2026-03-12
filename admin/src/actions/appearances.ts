'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import { auditLog } from '@/lib/audit-log'
import type { CharacterGender, CharacterOrigin } from '@prisma/client'

export async function getAppearances() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.appearanceSkin.findMany({
    orderBy: [{ origin: 'asc' }, { gender: 'asc' }, { sortOrder: 'asc' }],
  })
}

export async function createAppearance(data: {
  skinKey: string
  name: string
  origin: CharacterOrigin
  gender: CharacterGender
  rarity: string
  priceGold: number
  priceGems: number
  imageUrl?: string | null
  imageKey?: string | null
  isDefault: boolean
  sortOrder: number
}) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const skin = await prisma.appearanceSkin.create({
    data: {
      skinKey: data.skinKey,
      name: data.name,
      origin: data.origin,
      gender: data.gender,
      rarity: data.rarity,
      priceGold: data.priceGold,
      priceGems: data.priceGems,
      imageUrl: data.imageUrl ?? null,
      imageKey: data.imageKey ?? data.skinKey,
      isDefault: data.isDefault,
      sortOrder: data.sortOrder,
    },
  })

  auditLog(admin, 'create_appearance', `appearance/${skin.id}`, {
    skinKey: data.skinKey,
    name: data.name,
    gender: data.gender,
  })

  return skin
}

export async function updateAppearance(
  id: string,
  data: {
    skinKey?: string
    name?: string
    origin?: CharacterOrigin
    gender?: CharacterGender
    rarity?: string
    priceGold?: number
    priceGems?: number
    imageUrl?: string | null
    imageKey?: string | null
    isDefault?: boolean
    sortOrder?: number
  }
) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const updateData: Record<string, unknown> = {}
  if (data.skinKey !== undefined) updateData.skinKey = data.skinKey
  if (data.name !== undefined) updateData.name = data.name
  if (data.origin !== undefined) updateData.origin = data.origin
  if (data.gender !== undefined) updateData.gender = data.gender
  if (data.rarity !== undefined) updateData.rarity = data.rarity
  if (data.priceGold !== undefined) updateData.priceGold = data.priceGold
  if (data.priceGems !== undefined) updateData.priceGems = data.priceGems
  if (data.imageUrl !== undefined) updateData.imageUrl = data.imageUrl
  if (data.imageKey !== undefined) updateData.imageKey = data.imageKey
  if (data.isDefault !== undefined) updateData.isDefault = data.isDefault
  if (data.sortOrder !== undefined) updateData.sortOrder = data.sortOrder

  const updated = await prisma.appearanceSkin.update({
    where: { id },
    data: updateData,
  })

  auditLog(admin, 'update_appearance', `appearance/${id}`, {
    updatedFields: Object.keys(updateData),
  })

  return updated
}

export async function deleteAppearance(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const skin = await prisma.appearanceSkin.findUnique({
    where: { id },
    select: { skinKey: true, name: true },
  })

  await prisma.appearanceSkin.delete({ where: { id } })

  auditLog(admin, 'delete_appearance', `appearance/${id}`, {
    skinKey: skin?.skinKey,
    name: skin?.name,
  })

  return { success: true }
}
