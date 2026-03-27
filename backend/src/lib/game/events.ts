// =============================================================================
// events.ts — Live event multiplier engine
// Reads active events from DB and returns multipliers for gold, XP, drops
// =============================================================================

import { prisma } from '@/lib/prisma'

/** Event effect multipliers applied to rewards */
export interface EventMultipliers {
  goldMult: number       // 1.0 = no bonus, 2.0 = double gold
  xpMult: number         // 1.0 = no bonus, 2.0 = double XP
  dropRateMult: number   // 1.0 = no bonus, 1.5 = +50% drop rate
  staminaDiscount: number // 0 = no discount, 0.5 = half stamina cost
  activeEvents: ActiveEventInfo[]
}

export interface ActiveEventInfo {
  eventKey: string
  title: string
  eventType: string
  endsAt: string // ISO date
  config: Record<string, unknown>
}

// In-memory cache to avoid DB hit on every combat
let cachedMultipliers: EventMultipliers | null = null
let cacheExpiresAt = 0
const CACHE_TTL_MS = 30_000 // 30 seconds

/**
 * Get current event multipliers. Cached for 30s.
 * Call this in reward calculation paths (pvp/fight, dungeon, etc.)
 */
export async function getActiveEventMultipliers(): Promise<EventMultipliers> {
  const now = Date.now()
  if (cachedMultipliers && now < cacheExpiresAt) {
    return cachedMultipliers
  }

  const nowDate = new Date()
  const events = await prisma.event.findMany({
    where: {
      isActive: true,
      startAt: { lte: nowDate },
      endAt: { gte: nowDate },
    },
  })

  let goldMult = 1.0
  let xpMult = 1.0
  let dropRateMult = 1.0
  let staminaDiscount = 0

  const activeEvents: ActiveEventInfo[] = []

  for (const event of events) {
    const cfg = (event.config ?? {}) as Record<string, unknown>

    activeEvents.push({
      eventKey: event.eventKey,
      title: event.title,
      eventType: event.eventType,
      endsAt: event.endAt.toISOString(),
      config: cfg,
    })

    switch (event.eventType) {
      case 'gold_rush':
        goldMult *= (typeof cfg.goldMultiplier === 'number' ? cfg.goldMultiplier : 2.0)
        break
      case 'double_xp':
        xpMult *= (typeof cfg.xpMultiplier === 'number' ? cfg.xpMultiplier : 2.0)
        break
      case 'drop_rate_boost':
        dropRateMult *= (typeof cfg.dropRateMultiplier === 'number' ? cfg.dropRateMultiplier : 1.5)
        break
      case 'boss_rush':
        // Boss rush: bonus XP + higher drop rates
        xpMult *= (typeof cfg.xpMultiplier === 'number' ? cfg.xpMultiplier : 1.5)
        dropRateMult *= (typeof cfg.dropRateMultiplier === 'number' ? cfg.dropRateMultiplier : 1.5)
        break
      case 'class_spotlight':
        // Class spotlight: XP bonus for specific class (applied per-character in route)
        xpMult *= (typeof cfg.xpMultiplier === 'number' ? cfg.xpMultiplier : 1.25)
        break
      case 'tournament':
        // Tournament: reduced stamina cost for PvP
        staminaDiscount = Math.max(staminaDiscount, typeof cfg.staminaDiscount === 'number' ? cfg.staminaDiscount : 0.5)
        break
      case 'weekend_warrior':
        // Weekend special: gold + XP + drops all boosted
        goldMult *= (typeof cfg.goldMultiplier === 'number' ? cfg.goldMultiplier : 1.5)
        xpMult *= (typeof cfg.xpMultiplier === 'number' ? cfg.xpMultiplier : 1.5)
        dropRateMult *= (typeof cfg.dropRateMultiplier === 'number' ? cfg.dropRateMultiplier : 1.25)
        break
    }
  }

  // Cap multipliers to prevent abuse
  goldMult = Math.min(goldMult, 3.0)
  xpMult = Math.min(xpMult, 3.0)
  dropRateMult = Math.min(dropRateMult, 2.5)
  staminaDiscount = Math.min(staminaDiscount, 0.75)

  cachedMultipliers = { goldMult, xpMult, dropRateMult, staminaDiscount, activeEvents }
  cacheExpiresAt = now + CACHE_TTL_MS

  return cachedMultipliers
}

/** Force-clear the cache (call after admin updates events) */
export function clearEventCache(): void {
  cachedMultipliers = null
  cacheExpiresAt = 0
}

/** Apply gold multiplier from active events */
export function applyEventGoldMultiplier(baseGold: number, multipliers: EventMultipliers): number {
  return Math.floor(baseGold * multipliers.goldMult)
}

/** Apply XP multiplier from active events */
export function applyEventXpMultiplier(baseXp: number, multipliers: EventMultipliers): number {
  return Math.floor(baseXp * multipliers.xpMult)
}
