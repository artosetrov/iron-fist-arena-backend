'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import { auditLog } from '@/lib/audit-log'
import {
  sanitizeAppearanceSkinInput,
  type AppearanceSkinInput,
} from '@/lib/appearance-skins'

export async function getAppearances() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.appearanceSkin.findMany({
    orderBy: [{ origin: 'asc' }, { gender: 'asc' }, { sortOrder: 'asc' }],
  })
}

export async function createAppearance(data: AppearanceSkinInput) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const payload = sanitizeAppearanceSkinInput(data)
  const existing = await prisma.appearanceSkin.findUnique({
    where: { skinKey: payload.skinKey },
    select: { id: true },
  })

  if (existing) {
    throw new Error('Skin Key already exists')
  }

  const skin = await prisma.$transaction(async (tx) => {
    if (payload.isDefault) {
      await tx.appearanceSkin.updateMany({
        where: {
          origin: payload.origin,
          gender: payload.gender,
          isDefault: true,
        },
        data: { isDefault: false },
      })
    }

    return tx.appearanceSkin.create({
      data: payload,
    })
  })

  auditLog(admin, 'create_appearance', `appearance/${skin.id}`, {
    skinKey: payload.skinKey,
    name: payload.name,
    origin: payload.origin,
    gender: payload.gender,
    isDefault: payload.isDefault,
  })

  return skin
}

export async function updateAppearance(
  id: string,
  data: AppearanceSkinInput
) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const existing = await prisma.appearanceSkin.findUnique({
    where: { id },
  })

  if (!existing) {
    throw new Error('Appearance not found')
  }

  const payload = sanitizeAppearanceSkinInput(data, existing)
  const conflicting = await prisma.appearanceSkin.findUnique({
    where: { skinKey: payload.skinKey },
    select: { id: true },
  })

  if (conflicting && conflicting.id !== id) {
    throw new Error('Skin Key already exists')
  }

  const updated = await prisma.$transaction(async (tx) => {
    if (payload.isDefault) {
      await tx.appearanceSkin.updateMany({
        where: {
          origin: payload.origin,
          gender: payload.gender,
          isDefault: true,
          NOT: { id },
        },
        data: { isDefault: false },
      })
    }

    return tx.appearanceSkin.update({
      where: { id },
      data: payload,
    })
  })

  auditLog(admin, 'update_appearance', `appearance/${id}`, {
    skinKey: payload.skinKey,
    origin: payload.origin,
    gender: payload.gender,
    isDefault: payload.isDefault,
    updatedFields: Object.keys(data),
  })

  return updated
}

export async function deleteAppearance(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const skin = await prisma.appearanceSkin.findUnique({
    where: { id },
    select: { skinKey: true, name: true, isDefault: true },
  })

  if (skin?.isDefault) {
    throw new Error('Default skins cannot be deleted. Assign another default first.')
  }

  await prisma.appearanceSkin.delete({ where: { id } })

  auditLog(admin, 'delete_appearance', `appearance/${id}`, {
    skinKey: skin?.skinKey,
    name: skin?.name,
  })

  return { success: true }
}
