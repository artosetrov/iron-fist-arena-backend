'use server'

import { Prisma } from '@prisma/client'
import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import {
  FEATURE_FLAG_ENVIRONMENTS,
  getDefaultFeatureFlagValue,
  normalizeFeatureFlagKey,
  normalizeFeatureFlagTags,
  parseFeatureFlagEnvironment,
  parseFeatureFlagType,
  sanitizeFeatureFlagTargeting,
  sanitizeFeatureFlagValue,
  type FeatureFlagEnvironment,
  type FeatureFlagType,
  type JsonValue,
} from '@/lib/feature-flags'

type FeatureFlagMutationInput = {
  key?: string
  title?: string
  description?: string
  flagType?: unknown
  value?: unknown
  targeting?: unknown
  isActive?: boolean
  environment?: unknown
  tags?: unknown
}

type CreateFlagInput = FeatureFlagMutationInput & {
  key: string
  title: string
}

type UpdateFlagInput = Omit<FeatureFlagMutationInput, 'key'>

type NormalizedFeatureFlagPayload = {
  title: string
  description: string | null
  flagType: FeatureFlagType
  value: JsonValue
  targeting: JsonValue | null
  isActive: boolean
  environment: FeatureFlagEnvironment
  tags: string[]
}

type DefaultFlagSeed = {
  key: string
  title: string
  description: string
  flagType: FeatureFlagType
  value: JsonValue
  isActive?: boolean
}

function toNullableJsonInput(value: JsonValue | null): Prisma.InputJsonValue | Prisma.NullableJsonNullValueInput {
  return value === null ? Prisma.DbNull : value as Prisma.InputJsonValue
}

function normalizePayload(
  input: FeatureFlagMutationInput,
  existing?: {
    title: string
    description: string | null
    flagType: string
    value: Prisma.JsonValue
    targeting: Prisma.JsonValue | null
    isActive: boolean
    environment: string
    tags: string[]
  }
): NormalizedFeatureFlagPayload {
  const title = input.title?.trim() ?? existing?.title?.trim() ?? ''
  if (!title) throw new Error('title is required')

  const flagType = input.flagType !== undefined
    ? parseFeatureFlagType(input.flagType)
    : parseFeatureFlagType(existing?.flagType ?? 'boolean')

  const description = input.description !== undefined
    ? input.description.trim() || null
    : existing?.description ?? null

  const value = input.value !== undefined
    ? sanitizeFeatureFlagValue(flagType, input.value)
    : existing?.value !== undefined && existing.value !== null
      ? sanitizeFeatureFlagValue(flagType, existing.value)
      : getDefaultFeatureFlagValue(flagType)

  const targeting = input.targeting !== undefined
    ? sanitizeFeatureFlagTargeting(input.targeting)
    : sanitizeFeatureFlagTargeting(existing?.targeting ?? null)

  const environment = input.environment !== undefined
    ? parseFeatureFlagEnvironment(input.environment)
    : parseFeatureFlagEnvironment(existing?.environment ?? 'all')

  const tags = input.tags !== undefined
    ? normalizeFeatureFlagTags(input.tags)
    : normalizeFeatureFlagTags(existing?.tags ?? [])

  return {
    title,
    description,
    flagType,
    value,
    targeting,
    isActive: input.isActive ?? existing?.isActive ?? false,
    environment,
    tags,
  }
}

async function logAction(adminId: string, action: string, target?: string, details?: JsonValue) {
  try {
    await prisma.adminLog.create({
      data: {
        adminId,
        action,
        target,
        ...(details !== undefined && { details: details as Prisma.InputJsonValue }),
      },
    })
  } catch {
    console.error('[audit] failed to log:', action, target)
  }
}

export async function listFeatureFlags() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  return prisma.featureFlag.findMany({
    orderBy: [{ isActive: 'desc' }, { key: 'asc' }],
  })
}

export async function getFeatureFlag(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  return prisma.featureFlag.findUnique({ where: { id } })
}

export async function createFeatureFlag(data: CreateFlagInput) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const key = normalizeFeatureFlagKey(data.key)
  if (!key) throw new Error('key is required')

  const existing = await prisma.featureFlag.findUnique({ where: { key } })
  if (existing) throw new Error(`Flag "${key}" already exists`)

  const payload = normalizePayload(data)

  const flag = await prisma.featureFlag.create({
    data: {
      key,
      title: payload.title,
      description: payload.description,
      flagType: payload.flagType,
      value: payload.value as Prisma.InputJsonValue,
      targeting: toNullableJsonInput(payload.targeting),
      isActive: payload.isActive,
      environment: payload.environment,
      tags: payload.tags,
      createdBy: admin.id,
    },
  })

  await logAction(admin.id, 'feature_flag.create', flag.key, {
    flagType: flag.flagType,
    environment: flag.environment,
    isActive: flag.isActive,
  })

  return flag
}

export async function updateFeatureFlag(id: string, data: UpdateFlagInput) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const current = await prisma.featureFlag.findUnique({
    where: { id },
    select: {
      id: true,
      key: true,
      title: true,
      description: true,
      flagType: true,
      value: true,
      targeting: true,
      isActive: true,
      environment: true,
      tags: true,
    },
  })

  if (!current) throw new Error('Flag not found')

  const payload = normalizePayload(data, current)

  const flag = await prisma.featureFlag.update({
    where: { id },
    data: {
      title: payload.title,
      description: payload.description,
      flagType: payload.flagType,
      value: payload.value as Prisma.InputJsonValue,
      targeting: toNullableJsonInput(payload.targeting),
      isActive: payload.isActive,
      environment: payload.environment,
      tags: payload.tags,
    },
  })

  await logAction(admin.id, 'feature_flag.update', flag.key, {
    flagType: flag.flagType,
    environment: flag.environment,
    isActive: flag.isActive,
  })

  return flag
}

export async function toggleFeatureFlag(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const current = await prisma.featureFlag.findUnique({ where: { id } })
  if (!current) throw new Error('Flag not found')

  const flag = await prisma.featureFlag.update({
    where: { id },
    data: { isActive: !current.isActive },
  })

  await logAction(admin.id, 'feature_flag.toggle', flag.key, {
    from: current.isActive,
    to: flag.isActive,
  })

  return flag
}

export async function deleteFeatureFlag(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const flag = await prisma.featureFlag.delete({ where: { id } })

  await logAction(admin.id, 'feature_flag.delete', flag.key)

  return flag
}

export async function getFeatureFlagStats() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const [total, active, booleanCount, percentageCount] = await Promise.all([
    prisma.featureFlag.count(),
    prisma.featureFlag.count({ where: { isActive: true } }),
    prisma.featureFlag.count({ where: { flagType: 'boolean' } }),
    prisma.featureFlag.count({ where: { flagType: 'percentage' } }),
  ])

  return { total, active, inactive: total - active, booleanCount, percentageCount }
}

export async function seedDefaultFlags() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const defaults: DefaultFlagSeed[] = [
    { key: 'maintenance_mode', title: 'Maintenance Mode', description: 'Show maintenance screen to all players', flagType: 'boolean', value: false },
    { key: 'pvp_enabled', title: 'PvP Enabled', description: 'Kill switch for PvP matchmaking', flagType: 'boolean', value: true, isActive: true },
    { key: 'dungeon_rush_enabled', title: 'Dungeon Rush Enabled', description: 'Enable/disable dungeon rush mode', flagType: 'boolean', value: true, isActive: true },
    { key: 'new_combat_ui', title: 'New Combat UI', description: 'Rollout of redesigned combat screen', flagType: 'percentage', value: 0 },
    { key: 'double_xp_event', title: 'Double XP Event', description: 'Temporarily double all XP gains', flagType: 'boolean', value: false },
    { key: 'shell_game_enabled', title: 'Shell Game Enabled', description: 'Enable/disable shell game minigame', flagType: 'boolean', value: true, isActive: true },
    { key: 'gold_mine_enabled', title: 'Gold Mine Enabled', description: 'Enable/disable gold mine', flagType: 'boolean', value: true, isActive: true },
    { key: 'iap_enabled', title: 'IAP Enabled', description: 'Kill switch for in-app purchases', flagType: 'boolean', value: true, isActive: true },
    { key: 'force_update', title: 'Force Update', description: 'Force users to update to latest app version', flagType: 'json', value: { minVersion: '1.0.0', message: 'Please update to continue playing' } },
    { key: 'new_loot_table', title: 'New Loot Table (A/B)', description: 'A/B test: new drop chances', flagType: 'percentage', value: 50 },
  ]

  let created = 0
  let skipped = 0

  for (const definition of defaults) {
    const exists = await prisma.featureFlag.findUnique({ where: { key: definition.key } })
    if (exists) {
      skipped++
      continue
    }

    await prisma.featureFlag.create({
      data: {
        key: definition.key,
        title: definition.title,
        description: definition.description,
        flagType: definition.flagType,
        value: definition.value as Prisma.InputJsonValue,
        isActive: definition.isActive ?? false,
        environment: FEATURE_FLAG_ENVIRONMENTS[0],
        tags: [],
        createdBy: admin.id,
      },
    })
    created++
  }

  return { created, skipped, total: defaults.length }
}
