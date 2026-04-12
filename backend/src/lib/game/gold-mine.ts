import { PrismaClient } from '@prisma/client'
import { getGemCostsConfig } from './live-config'

export const MINE_DURATION_HOURS = 4
// Economy v2 — reduced to align gold mine with ~5-8% of daily income, not 15-20%
export const MINE_REWARD_MIN = 40
export const MINE_REWARD_MAX = 100
export const MAX_GOLD_MINE_SLOTS = 3

// Lazy getters for gem costs (read from live config)
let _cachedGemConfig: Awaited<ReturnType<typeof getGemCostsConfig>> | null = null

async function getGemConfig() {
  if (!_cachedGemConfig) {
    _cachedGemConfig = await getGemCostsConfig()
  }
  return _cachedGemConfig
}

export async function getBOOST_COST_GEMS(): Promise<number> {
  const config = await getGemConfig()
  return config.GOLD_MINE_BOOST
}

export async function getSLOT_COST_GEMS(): Promise<number> {
  const config = await getGemConfig()
  return config.GOLD_MINE_BUY_SLOT
}

// Gem (crystal) random drop from mining
export const GEM_DROP_CHANCE = 0.10 // 10% chance per collect
export const GEM_DROP_MIN = 1
export const GEM_DROP_MAX = 3

export type SlotStatus = 'idle' | 'mining' | 'ready'

export interface SlotStats {
  total_gold_mined: number
  sessions_completed: number
  best_haul: number
  current_streak: number
}

export interface SlotInfo {
  slot_index: number
  status: SlotStatus
  session_id?: string
  started_at?: string
  ends_at?: string
  reward?: number
  gem_reward?: number
  boosted?: boolean
  // Per-slot bonus mini-game (Variant D Phase 2).
  // `minigame_played` = true once the player has completed the bonus game
  // for this slot. A slot cannot be collected until this is true.
  minigame_played?: boolean
  // When a minigame session is currently in flight for this slot, this is
  // the id of the MinigameSession row. The client uses this to resume a
  // fullscreen cover if the player came back mid-session.
  minigame_session_id?: string | null
  // Per-slot lifetime statistics (aggregated from collected sessions).
  stats?: SlotStats
}

/**
 * Aggregates lifetime statistics for each slot from collected sessions.
 * Returns a Map<slotIndex, SlotStats>. Runs a single grouped query.
 */
async function aggregateSlotStats(
  prisma: PrismaClient,
  characterId: string,
  maxSlots: number
): Promise<Map<number, SlotStats>> {
  const agg = await prisma.goldMineSession.groupBy({
    by: ['slotIndex'],
    where: { characterId, collected: true },
    _sum: { reward: true },
    _count: { _all: true },
    _max: { reward: true },
  })

  const statsMap = new Map<number, SlotStats>()

  for (const row of agg) {
    statsMap.set(row.slotIndex, {
      total_gold_mined: row._sum.reward ?? 0,
      sessions_completed: row._count._all,
      best_haul: row._max.reward ?? 0,
      current_streak: 0, // computed below per slot
    })
  }

  // Compute current streak per slot: count consecutive collected sessions
  // from the most recent backwards, stopping at the first gap > 5 hours
  // (session is 4h, so 5h allows some slack for late collection).
  const STREAK_GAP_MS = 5 * 60 * 60 * 1000
  for (let i = 0; i < maxSlots; i++) {
    const recentSessions = await prisma.goldMineSession.findMany({
      where: { characterId, slotIndex: i, collected: true },
      orderBy: { endsAt: 'desc' },
      take: 50,
      select: { endsAt: true, startedAt: true },
    })

    let streak = 0
    let prevStart: Date | null = null
    for (const s of recentSessions) {
      if (prevStart && (prevStart.getTime() - s.endsAt.getTime()) > STREAK_GAP_MS) {
        break
      }
      streak++
      prevStart = s.startedAt
    }

    const existing = statsMap.get(i) ?? {
      total_gold_mined: 0,
      sessions_completed: 0,
      best_haul: 0,
      current_streak: 0,
    }
    existing.current_streak = streak
    statsMap.set(i, existing)
  }

  return statsMap
}

/**
 * Builds a slots array with status for the iOS client.
 * Returns one entry per slot (0..maxSlots-1), each with a computed status.
 */
export async function buildSlotsArray(
  prisma: PrismaClient,
  characterId: string,
  maxSlots: number,
  includeStats: boolean = false
): Promise<SlotInfo[]> {
  const activeSessions = await prisma.goldMineSession.findMany({
    where: {
      characterId,
      collected: false,
    },
    orderBy: { slotIndex: 'asc' },
  })

  const sessionBySlot = new Map<number, typeof activeSessions[0]>()
  for (const s of activeSessions) {
    sessionBySlot.set(s.slotIndex, s)
  }

  // Optionally aggregate per-slot lifetime stats (only on /status calls)
  const statsMap = includeStats
    ? await aggregateSlotStats(prisma, characterId, maxSlots)
    : new Map<number, SlotStats>()

  const now = new Date()
  const slots: SlotInfo[] = []

  for (let i = 0; i < maxSlots; i++) {
    const session = sessionBySlot.get(i)
    const stats = statsMap.get(i)

    if (!session) {
      slots.push({
        slot_index: i,
        status: 'idle',
        stats,
      })
    } else {
      const isReady = now >= session.endsAt
      slots.push({
        slot_index: i,
        status: isReady ? 'ready' : 'mining',
        session_id: session.id,
        started_at: session.startedAt.toISOString(),
        ends_at: session.endsAt.toISOString(),
        reward: isReady ? session.reward : undefined,
        gem_reward: isReady && session.gemReward > 0 ? session.gemReward : undefined,
        boosted: session.boosted,
        minigame_played: session.minigamePlayedAt != null,
        minigame_session_id: session.minigameSessionId,
        stats,
      })
    }
  }

  return slots
}
