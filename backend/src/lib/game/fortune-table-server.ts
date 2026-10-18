/**
 * Fortune's Table — DB side (rounds live in `MinigameSession`, gameType
 * `fortune_table`; the round secret is `secretData`, the outcome `result`).
 * See `fortune-table.ts` for the rules.
 */
import type { Prisma, PrismaClient } from '@prisma/client'
import { claimPreviewedLoot, previewLootDrop, type LootResponseItem } from './loot'
import {
  FORTUNE_TABLE, asRoundSecret, chestItemChance, drawWinner, payoutFor, playerStake, potOf, seatsAt,
  type FortuneRoundSecret, type FortuneSeat,
} from './fortune-table'

export const FORTUNE_TABLE_GAME = 'fortune_table'

type Db = PrismaClient | Prisma.TransactionClient

/**
 * A Serializable transaction (backend rule for bets) retried on Prisma's
 * P2034 — write conflict or deadlock. Two quick taps on "take a seat" queue
 * on the user row lock; the loser of the conflict retries, sees the round the
 * winner opened and resumes it instead of failing with a 500.
 */
export async function serializableTx<T>(
  db: PrismaClient,
  fn: (tx: Prisma.TransactionClient) => Promise<T>,
  attempts = 3,
): Promise<T> {
  for (let attempt = 1; ; attempt++) {
    try {
      return await db.$transaction(fn, { isolationLevel: 'Serializable' })
    } catch (error) {
      if ((error as { code?: string }).code === 'P2034' && attempt < attempts) continue
      throw error
    }
  }
}

export interface FortuneRoundRow {
  readonly id: string
  readonly createdAt: Date
  readonly status: string
  readonly secretData: unknown
  readonly result: unknown
}

export interface StoredFortuneResult {
  readonly won: boolean
  readonly winner_seat: number
  readonly ticket: number
  readonly pot: number
  readonly payout: number
  readonly chest: LootResponseItem[]
}

function seatJson(s: FortuneSeat) {
  return {
    seat: s.seat,
    is_you: s.isYou,
    name: s.name,
    portrait: s.portrait,
    style: s.style,
    stake: s.stake,
    joined_ms: s.joinedAt,
  }
}

/** What the client sees of a round at `nowMs`. The seed only after the draw. */
export function roundView(row: FortuneRoundRow, nowMs: number) {
  const secret = asRoundSecret(row.secretData)
  if (!secret) return null
  const elapsed = nowMs - row.createdAt.getTime()
  const settled = row.status === 'completed'
  const seats = seatsAt(secret, settled ? Number.POSITIVE_INFINITY : elapsed)
  const pot = potOf(seats)
  const mine = playerStake(secret)
  const result = settled ? (row.result as StoredFortuneResult | null) : null
  return {
    id: row.id,
    tier: secret.tier,
    status: settled ? 'settled' : elapsed >= FORTUNE_TABLE.lobbyMs ? 'drawing' : 'lobby',
    commitment: secret.commitment,
    seed: settled ? secret.seed : null,
    lobby_ms: FORTUNE_TABLE.lobbyMs,
    ms_to_lock: Math.max(0, FORTUNE_TABLE.lobbyMs - elapsed),
    top_up_close_ms: FORTUNE_TABLE.topUpCloseMs,
    rake: FORTUNE_TABLE.rake,
    pot,
    payout_if_win: payoutFor(pot),
    chest_item_chance: Math.round(chestItemChance(pot) * 100) / 100,
    your_stake: mine,
    your_chance: pot > 0 ? Math.round((mine / pot) * 1000) / 1000 : 0,
    seats: seats.map(seatJson),
    result: result
      ? {
          won: result.won,
          winner_seat: result.winner_seat,
          ticket: result.ticket,
          payout: result.payout,
          chest: result.chest,
        }
      : null,
  }
}

/**
 * Draw and pay a round whose lobby has ended. Locks the round row, so two
 * callers at the lock settle it once. Returns false when there was nothing
 * to do (not due yet, already settled, not this character's).
 */
export async function settleRound(
  tx: Prisma.TransactionClient,
  args: { roundId: string; characterId: string; userId: string; level: number; nowMs: number },
): Promise<boolean> {
  const locked = await tx.$queryRaw<{ id: string }[]>`
    SELECT id FROM "minigame_sessions" WHERE id = ${args.roundId} FOR UPDATE
  `
  if (locked.length === 0) return false
  const row = await tx.minigameSession.findUnique({ where: { id: args.roundId } })
  if (!row || row.characterId !== args.characterId || row.gameType !== FORTUNE_TABLE_GAME) return false
  if (row.status !== 'active') return false
  if (args.nowMs - row.createdAt.getTime() < FORTUNE_TABLE.lobbyMs) return false
  const secret = asRoundSecret(row.secretData)
  if (!secret) {
    // Corrupt round: refund the stake rather than keep it.
    const refund = row.betAmount
    if (refund > 0) await tx.user.update({ where: { id: args.userId }, data: { gold: { increment: refund } } })
    await tx.minigameSession.update({ where: { id: row.id }, data: { status: 'void' } })
    return true
  }

  const draw = drawWinner(secret)
  let chest: LootResponseItem[] = []
  if (draw.playerWon) {
    await tx.$queryRaw`SELECT id FROM "users" WHERE id = ${args.userId} FOR UPDATE`
    await tx.user.update({ where: { id: args.userId }, data: { gold: { increment: draw.payout } } })
    if (draw.chestHasItem) {
      const preview = await previewLootDrop(tx, args.characterId, args.level)
      if (preview) chest = await claimPreviewedLoot(tx, args.characterId, [preview])
    }
  }

  const stored: StoredFortuneResult = {
    won: draw.playerWon,
    winner_seat: draw.winnerSeat,
    ticket: draw.ticket,
    pot: draw.pot,
    payout: draw.payout,
    chest,
  }
  await tx.minigameSession.update({
    where: { id: row.id },
    data: {
      status: 'completed',
      result: stored as unknown as Prisma.InputJsonValue,
    },
  })
  return true
}

/**
 * Settle every overdue round on the server (cron): rounds a player walked away
 * from would otherwise wait for them to reopen the table to be paid.
 */
export async function settleAllDueRounds(db: PrismaClient, nowMs: number, limit = 200): Promise<number> {
  const due = await db.minigameSession.findMany({
    where: {
      gameType: FORTUNE_TABLE_GAME,
      status: 'active',
      createdAt: { lte: new Date(nowMs - FORTUNE_TABLE.lobbyMs) },
    },
    select: { id: true, characterId: true, character: { select: { userId: true, level: true } } },
    orderBy: { createdAt: 'asc' },
    take: limit,
  })
  let settled = 0
  for (const r of due) {
    if (!r.character) continue
    const done = await db.$transaction((tx) => settleRound(tx, {
      roundId: r.id,
      characterId: r.characterId,
      userId: r.character.userId,
      level: r.character.level,
      nowMs,
    }))
    if (done) settled++
  }
  return settled
}

/** Settle every round of this character whose lobby is over (normally 0 or 1). */
export async function settleDueRounds(
  db: PrismaClient,
  args: { characterId: string; userId: string; level: number; nowMs: number },
): Promise<void> {
  const due = await db.minigameSession.findMany({
    where: {
      characterId: args.characterId,
      gameType: FORTUNE_TABLE_GAME,
      status: 'active',
      createdAt: { lte: new Date(args.nowMs - FORTUNE_TABLE.lobbyMs) },
    },
    select: { id: true },
    take: 5,
  })
  for (const r of due) {
    // Read Committed + the row lock in settleRound: a second caller waits on
    // the lock, then sees the round settled and does nothing.
    await db.$transaction((tx) => settleRound(tx, { ...args, roundId: r.id }))
  }
}

export async function activeRound(db: Db, characterId: string, nowMs: number) {
  return db.minigameSession.findFirst({
    where: {
      characterId,
      gameType: FORTUNE_TABLE_GAME,
      status: 'active',
      createdAt: { gt: new Date(nowMs - FORTUNE_TABLE.lobbyMs) },
    },
    orderBy: { createdAt: 'desc' },
  })
}

export function todayStart(nowMs: number): Date {
  return new Date(new Date(nowMs).toISOString().split('T')[0])
}

/** The player's last few rounds for the table's history strip. */
export async function recentHistory(db: Db, characterId: string) {
  const rows = await db.minigameSession.findMany({
    where: { characterId, gameType: FORTUNE_TABLE_GAME, status: 'completed' },
    orderBy: { createdAt: 'desc' },
    take: 10,
    select: { id: true, createdAt: true, secretData: true, result: true },
  })
  return rows.flatMap((r) => {
    const secret = asRoundSecret(r.secretData)
    const res = r.result as StoredFortuneResult | null
    if (!secret || !res) return []
    const seats = seatsAt(secret, Number.POSITIVE_INFINITY)
    const winner = seats[res.winner_seat]
    return [{
      id: r.id,
      at: r.createdAt.toISOString(),
      tier: secret.tier,
      pot: res.pot,
      won: res.won,
      payout: res.payout,
      your_stake: playerStake(secret),
      winner_name: winner?.isYou ? null : winner?.name ?? null,
    }]
  })
}

export type FortuneRoundSecretJson = FortuneRoundSecret
