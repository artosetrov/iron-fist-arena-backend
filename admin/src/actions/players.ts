'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import { auditLog } from '@/lib/audit-log'

// ---------------------------------------------------------------------------
// Validation constants
// ---------------------------------------------------------------------------

/** Maximum gold/gems that can be granted in a single operation. */
const MAX_GRANT_AMOUNT = 1_000_000

/** UUID v4 format check (loose). */
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

function validatePositiveInt(value: number, label: string): void {
  if (!Number.isFinite(value) || !Number.isInteger(value)) {
    throw new Error(`${label} must be an integer`)
  }
  if (value <= 0) throw new Error(`${label} must be positive`)
  if (value > MAX_GRANT_AMOUNT) {
    throw new Error(`${label} exceeds maximum allowed (${MAX_GRANT_AMOUNT})`)
  }
}

function validateUUID(value: string, label: string): void {
  if (!value || typeof value !== 'string' || !UUID_RE.test(value)) {
    throw new Error(`${label} must be a valid UUID`)
  }
}

export async function searchPlayers(query: string, page: number = 1) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const pageSize = 20
  const skip = (page - 1) * pageSize

  const where = query
    ? {
        OR: [
          { username: { contains: query, mode: 'insensitive' as const } },
          { email: { contains: query, mode: 'insensitive' as const } },
        ],
      }
    : {}

  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where,
      skip,
      take: pageSize,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        username: true,
        gems: true,
        role: true,
        createdAt: true,
        lastLogin: true,
        isBanned: true,
        banReason: true,
        _count: { select: { characters: true } },
      },
    }),
    prisma.user.count({ where }),
  ])

  return {
    users: users.map(u => ({
      ...u,
      characterCount: u._count.characters,
      _count: undefined,
    })),
    total,
    page,
    pageSize,
  }
}

export async function getPlayerDetails(userId: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      characters: {
        include: {
          equipment: {
            include: { item: true },
          },
          consumables: true,
          achievements: true,
        },
      },
    },
  })

  if (!user) throw new Error('User not found')

  return user
}

export async function banPlayer(userId: string, reason: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  validateUUID(userId, 'userId')
  if (!reason || typeof reason !== 'string' || reason.trim().length === 0) {
    throw new Error('Ban reason is required')
  }
  await prisma.user.update({
    where: { id: userId },
    data: { isBanned: true, banReason: reason.trim() },
  })
  auditLog(admin, 'ban_player', `user/${userId}`, { reason: reason.trim() })
  return { success: true }
}

export async function unbanPlayer(userId: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  validateUUID(userId, 'userId')
  await prisma.user.update({
    where: { id: userId },
    data: { isBanned: false, banReason: null },
  })
  auditLog(admin, 'unban_player', `user/${userId}`)
  return { success: true }
}

export async function grantGold(characterId: string, amount: number) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  validateUUID(characterId, 'characterId')
  validatePositiveInt(amount, 'Amount')
  await prisma.character.update({
    where: { id: characterId },
    data: { gold: { increment: amount } },
  })
  auditLog(admin, 'grant_gold', `character/${characterId}`, { amount })
  return { success: true }
}

export async function grantGems(userId: string, amount: number) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  validateUUID(userId, 'userId')
  validatePositiveInt(amount, 'Amount')
  await prisma.user.update({
    where: { id: userId },
    data: { gems: { increment: amount } },
  })
  auditLog(admin, 'grant_gems', `user/${userId}`, { amount })
  return { success: true }
}

export async function grantItem(characterId: string, itemId: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  validateUUID(characterId, 'characterId')
  validateUUID(itemId, 'itemId')

  // Verify the item actually exists before granting.
  const item = await prisma.item.findUnique({ where: { id: itemId }, select: { id: true, itemName: true } })
  if (!item) throw new Error('Item not found')

  await prisma.equipmentInventory.create({
    data: {
      characterId,
      itemId,
    },
  })
  auditLog(admin, 'grant_item', `character/${characterId}`, { itemId, itemName: item.itemName })
  return { success: true }
}

export async function resetInventory(characterId: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  validateUUID(characterId, 'characterId')
  const { count } = await prisma.equipmentInventory.deleteMany({
    where: { characterId },
  })
  auditLog(admin, 'reset_inventory', `character/${characterId}`, { deletedCount: count })
  return { success: true }
}
