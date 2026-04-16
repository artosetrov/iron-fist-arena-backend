import type { Prisma } from '@prisma/client'
import { prisma } from '@/lib/prisma'

// In-memory cache (5 min TTL) so we don't hit DB on every request
let flagCache: { data: RawFlag[]; expires: number } | null = null
const CACHE_TTL = 5 * 60 * 1000

type FeatureFlagValue = Prisma.JsonValue

type FlagTargeting = {
  minLevel?: number
  maxLevel?: number
  class?: string
  userIds?: string[]
}

type RawFlag = {
  key: string
  flagType: string
  value: FeatureFlagValue
  targeting: FeatureFlagValue
  environment: string
}

type CharacterCtx = { id: string; level: number; class: string } | null

function parseTargeting(targeting: FeatureFlagValue): FlagTargeting | null {
  if (!targeting || typeof targeting !== 'object' || Array.isArray(targeting)) {
    return null
  }

  const record = targeting as Record<string, unknown>
  const userIds = Array.isArray(record.userIds)
    ? record.userIds.filter((id): id is string => typeof id === 'string')
    : undefined

  return {
    minLevel: typeof record.minLevel === 'number' ? record.minLevel : undefined,
    maxLevel: typeof record.maxLevel === 'number' ? record.maxLevel : undefined,
    class: typeof record.class === 'string' ? record.class : undefined,
    userIds,
  }
}

export function getRuntimeFlagEnvironment(): 'production' | 'staging' | 'development' {
  const vercelEnvironment = process.env.VERCEL_ENV

  if (vercelEnvironment === 'production' || process.env.NODE_ENV === 'production') {
    return 'production'
  }

  if (vercelEnvironment === 'preview' || process.env.APP_ENV === 'staging') {
    return 'staging'
  }

  return 'development'
}

function matchesEnvironment(flagEnvironment: string, runtimeEnvironment: string): boolean {
  return flagEnvironment === 'all' || flagEnvironment === runtimeEnvironment
}

export async function getActiveFlags(): Promise<RawFlag[]> {
  if (flagCache && Date.now() < flagCache.expires) {
    return flagCache.data
  }

  const flags = await prisma.featureFlag.findMany({
    where: { isActive: true },
    select: {
      key: true,
      flagType: true,
      value: true,
      targeting: true,
      environment: true,
    },
  })

  flagCache = { data: flags, expires: Date.now() + CACHE_TTL }
  return flags
}

export function invalidateFlagCache() {
  flagCache = null
}

/**
 * Resolve all active flags for a given user/character context.
 * Returns { [flagKey]: resolved_value }
 */
export async function resolveAllFlags(
  userId: string,
  character: CharacterCtx
): Promise<Record<string, FeatureFlagValue>> {
  const flags = await getActiveFlags()
  const resolved: Record<string, FeatureFlagValue> = {}
  const runtimeEnvironment = getRuntimeFlagEnvironment()

  for (const flag of flags) {
    resolved[flag.key] = resolveFlag(flag, userId, character, runtimeEnvironment)
  }

  return resolved
}

// --- Flag Resolution Logic ---

function resolveFlag(
  flag: RawFlag,
  userId: string,
  character: CharacterCtx,
  runtimeEnvironment: string,
): FeatureFlagValue {
  if (!matchesEnvironment(flag.environment, runtimeEnvironment)) {
    return getDefaultForType(flag.flagType)
  }

  const targeting = parseTargeting(flag.targeting)

  // Check user-level targeting first
  if (targeting?.userIds && targeting.userIds.length > 0) {
    if (!targeting.userIds.includes(userId)) {
      return getDefaultForType(flag.flagType)
    }
  }

  // Check character-level targeting
  if (character && targeting) {
    if (targeting.minLevel !== undefined && character.level < targeting.minLevel) {
      return getDefaultForType(flag.flagType)
    }
    if (targeting.maxLevel !== undefined && character.level > targeting.maxLevel) {
      return getDefaultForType(flag.flagType)
    }
    if (targeting.class && character.class !== targeting.class) {
      return getDefaultForType(flag.flagType)
    }
  }

  switch (flag.flagType) {
    case 'boolean':
      return flag.value === true || flag.value === 'true'

    case 'percentage': {
      const pct = typeof flag.value === 'number' ? flag.value : parseInt(String(flag.value), 10) || 0
      const hash = simpleHash(userId) % 100
      return hash < pct
    }

    case 'json':
      return flag.value

    default:
      return flag.value
  }
}

function getDefaultForType(type: string): FeatureFlagValue {
  switch (type) {
    case 'boolean': return false
    case 'percentage': return false
    case 'json': return null
    default: return null
  }
}

function simpleHash(str: string): number {
  let hash = 0
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash = hash & hash
  }
  return Math.abs(hash)
}
