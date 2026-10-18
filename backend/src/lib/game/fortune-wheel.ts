import type { Prisma, PrismaClient } from '@prisma/client'

/**
 * Fortune Wheel sectors — server-authoritative. Shared by /spin (roll) and
 * /status (odds disclosure for the client — App Store 3.1.1).
 *
 * 2026-10-17 rebalance: the old table paid back 59.3 % (2 spins in 3 lost,
 * the usual "win" was +50 %). Now LOSE weighs 20 (was 40) and the jackpot 4
 * (was 5): 47.6 % of spins pay, base RTP 88.4 %, and the jackpot sector also
 * pays a share of Fortuna's Treasury (fed by 2 % of every bet) — ≈ 91 % in all
 * (simulated: 90.8 %, the house tops the seed up with ≈ 0.3 % of bets).
 */
export const WHEEL_SECTORS = [
  { index: 0, multiplier: 0,   label: 'LOSE',  weight: 20 },
  { index: 1, multiplier: 1.5, label: 'x1.5',  weight: 25 },
  { index: 2, multiplier: 0,   label: 'LOSE',  weight: 20 },
  { index: 3, multiplier: 2,   label: 'x2',    weight: 20 },
  { index: 4, multiplier: 0,   label: 'LOSE',  weight: 20 },
  { index: 5, multiplier: 1.5, label: 'x1.5',  weight: 25 },
  { index: 6, multiplier: 0,   label: 'LOSE',  weight: 20 },
  { index: 7, multiplier: 3,   label: 'x3',    weight: 10 },
  { index: 8, multiplier: 0,   label: 'LOSE',  weight: 20 },
  { index: 9, multiplier: 1.5, label: 'x1.5',  weight: 25 },
  { index: 10, multiplier: 0,  label: 'LOSE',  weight: 20 },
  { index: 11, multiplier: 5,  label: 'x5',    weight: 4  }, // JACKPOT — x5 + Treasury share
] as const
// Total weight 229. EV ≈ 0.884 → 88.4 % RTP before the Treasury.

export const JACKPOT_SECTOR_INDEX = 11

/**
 * Fortuna's Treasury — one progressive jackpot shared by every player. Each
 * bet feeds 2 %; the jackpot sector pays takeRate × Treasury × (bet / max bet),
 * so a max bet takes a fifth of it. It never drops below the seed (the house
 * refills). Stored as a runtime row in `game_config` (no migration).
 *
 * Why a fifth, not all of it: with "max bet takes all" the seed refill alone
 * paid ~+8 % RTP (the Treasury sits at the 5 000 floor most of the time, so a
 * x5 at max bet paid ~x10), ≈ 98 % in all. takeRate 0.2 → ≈ 91 %, the
 * Treasury floats around 6–7 k and the house adds ≈ 0.3 % of bets.
 */
export const WHEEL_TREASURY = {
  key: 'fortune_wheel_treasury',
  seed: 5_000,
  feedRate: 0.02,
  maxBet: 1_000,
  takeRate: 0.2,
} as const

export function treasuryFeed(bet: number): number {
  return Math.max(1, Math.floor(bet * WHEEL_TREASURY.feedRate))
}

export function treasuryShare(treasury: number, bet: number): number {
  return Math.floor(treasury * Math.min(1, bet / WHEEL_TREASURY.maxBet) * WHEEL_TREASURY.takeRate)
}

type Db = PrismaClient | Prisma.TransactionClient

export async function readTreasury(db: Db): Promise<number> {
  const row = await db.gameConfig.findUnique({ where: { key: WHEEL_TREASURY.key }, select: { value: true } })
  const amount = Number((row?.value as { amount?: unknown } | null)?.amount)
  return Number.isFinite(amount) ? Math.max(WHEEL_TREASURY.seed, Math.floor(amount)) : WHEEL_TREASURY.seed
}

/** Add `feed` atomically (creating the row at the seed) and return the new total. */
export async function feedTreasury(tx: Prisma.TransactionClient, feed: number): Promise<number> {
  const rows = await tx.$queryRaw<{ amount: bigint }[]>`
    INSERT INTO "game_config" (key, value, category, description, updated_at)
    VALUES (
      ${WHEEL_TREASURY.key},
      jsonb_build_object('amount', ${WHEEL_TREASURY.seed + feed}::bigint),
      'runtime',
      'Fortune Wheel progressive jackpot (runtime counter, written by /spin)',
      now()
    )
    ON CONFLICT (key) DO UPDATE SET
      value = jsonb_build_object(
        'amount',
        GREATEST(${WHEEL_TREASURY.seed}::bigint, COALESCE(("game_config".value->>'amount')::bigint, ${WHEEL_TREASURY.seed}::bigint)) + ${feed}::bigint
      ),
      updated_at = now()
    RETURNING (value->>'amount')::bigint AS amount
  `
  return Number(rows[0]?.amount ?? WHEEL_TREASURY.seed + feed)
}

/** Pay `share` out of the Treasury (never below the seed); returns what is left. */
export async function drainTreasury(tx: Prisma.TransactionClient, share: number): Promise<number> {
  const rows = await tx.$queryRaw<{ amount: bigint }[]>`
    UPDATE "game_config" SET
      value = jsonb_build_object(
        'amount',
        GREATEST(${WHEEL_TREASURY.seed}::bigint, COALESCE((value->>'amount')::bigint, ${WHEEL_TREASURY.seed}::bigint) - ${share}::bigint)
      ),
      updated_at = now()
    WHERE key = ${WHEEL_TREASURY.key}
    RETURNING (value->>'amount')::bigint AS amount
  `
  return Number(rows[0]?.amount ?? WHEEL_TREASURY.seed)
}

export type WheelOdd = { label: string; multiplier: number; percent: number }

/** Per-outcome probabilities, merged by multiplier, sorted by multiplier. */
export function wheelOdds(): WheelOdd[] {
  const total = WHEEL_SECTORS.reduce((s, x) => s + x.weight, 0)
  const byMult = new Map<number, { label: string; weight: number }>()
  for (const s of WHEEL_SECTORS) {
    const cur = byMult.get(s.multiplier)
    byMult.set(s.multiplier, { label: s.label, weight: (cur?.weight ?? 0) + s.weight })
  }
  return Array.from(byMult.entries())
    .map(([multiplier, { label, weight }]) => ({
      label,
      multiplier,
      percent: Math.round((1000 * weight) / total) / 10,
    }))
    .sort((a, b) => a.multiplier - b.multiplier)
}
