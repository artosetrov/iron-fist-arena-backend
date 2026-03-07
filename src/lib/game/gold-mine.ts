import { PrismaClient } from '@prisma/client'

export const MINE_DURATION_HOURS = 4
export const MINE_REWARD_MIN = 200
export const MINE_REWARD_MAX = 500
export const BOOST_COST_GEMS = 10
export const MAX_GOLD_MINE_SLOTS = 6
export const SLOT_COST_GEMS = 50

export type SlotStatus = 'idle' | 'mining' | 'ready'

export interface SlotInfo {
  slot_index: number
  status: SlotStatus
  session_id?: string
  started_at?: string
  ends_at?: string
  reward?: number
  boosted?: boolean
}

/**
 * Builds a slots array with status for the iOS client.
 * Returns one entry per slot (0..maxSlots-1), each with a computed status.
 */
export async function buildSlotsArray(
  prisma: PrismaClient,
  characterId: string,
  maxSlots: number
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

  const now = new Date()
  const slots: SlotInfo[] = []

  for (let i = 0; i < maxSlots; i++) {
    const session = sessionBySlot.get(i)
    if (!session) {
      slots.push({ slot_index: i, status: 'idle' })
    } else {
      const isReady = now >= session.endsAt
      slots.push({
        slot_index: i,
        status: isReady ? 'ready' : 'mining',
        session_id: session.id,
        started_at: session.startedAt.toISOString(),
        ends_at: session.endsAt.toISOString(),
        reward: isReady ? session.reward : undefined,
        boosted: session.boosted,
      })
    }
  }

  return slots
}
