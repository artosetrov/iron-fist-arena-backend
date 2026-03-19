import { prisma } from '@/lib/prisma'

// In-memory cache (5 min TTL) so we don't hit DB on every request
let flagCache: { data: RawFlag[]; expires: number } | null = null
const CACHE_TTL = 5 * 60 * 1000

type RawFlag = {
  key: string
  flagType: string
  value: any
  targeting: any
  environment: string
}

type CharacterCtx = { id: string; level: number; class: string } | null

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
): Promise<Record<string, any>> {
  const flags = await getActiveFlags()
  const resolved: Record<string, any> = {}

  for (const flag of flags) {
    resolved[flag.key] = resolveFlag(flag, userId, character)
  }

  return resolved
}

// --- Flag Resolution Logic ---

function resolveFlag(flag: RawFlag, userId: string, character: CharacterCtx): any {
  const targeting = flag.targeting as {
    minLevel?: number
    maxLevel?: number
    class?: string
    userIds?: string[]
  } | null

  // Check user-level targeting first
  if (targeting?.userIds && targeting.userIds.length > 0) {
    if (!targeting.userIds.includes(userId)) {
      return getDefaultForType(flag.flagType)
    }
  }

  // Check character-level targeting
  if (character && targeting) {
    if (targeting.minLevel && character.level < targeting.minLevel) {
      return getDefaultForType(flag.flagType)
    }
    if (targeting.maxLevel && character.level > targeting.maxLevel) {
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

function getDefaultForType(type: string): any {
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
