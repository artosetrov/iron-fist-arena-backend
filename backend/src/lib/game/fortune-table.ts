/**
 * Fortune's Table — a jackpot wheel for 4–6 seats (2026-10-17).
 *
 * Everyone at the table stakes gold; the wheel is cut in proportion to the
 * stakes, one ticket is drawn, and whoever's slice it lands in takes the pot
 * minus Fortuna's tithe (RAKE), plus Fortuna's chest. Phase 1 fills the other
 * seats with tavern regulars (bots) — virtual, never in the DB.
 *
 * Pure module: no DB, no clock. The routes pass `nowMs` in and persist the
 * `FortuneRoundSecret` in `MinigameSession.secretData`.
 *
 * Fairness: the round's seed is fixed when the round opens and its SHA-256 is
 * shown to the player at once (`commitment`); the ticket is derived from the
 * seed alone, and the seed is revealed after the draw. Bot entries are also
 * fixed at open — nothing reacts to the player's top-ups. The player's
 * expected result is always −RAKE of what they staked, whatever the bots do.
 */
import { createHash, createHmac, randomBytes } from 'node:crypto'

export type FortuneTierKey = 'copper' | 'silver' | 'gold'

export interface FortuneTier {
  readonly key: FortuneTierKey
  /** Smallest single entry (join or top-up). */
  readonly minStake: number
  /** Cap on one seat's total stake in a round (join + top-ups). */
  readonly maxStake: number
  readonly minLevel: number
}

export const FORTUNE_TABLE = {
  /** Fortuna's tithe, taken from the pot before it is paid out. */
  rake: 0.05,
  /** Lobby length; the draw happens when it ends. */
  lobbyMs: 20_000,
  /** Top-ups close this long before the lock, so the last one lands in time. */
  topUpCloseMs: 1_000,
  dailyRounds: 20,
  /**
   * A pot this big always puts an item in the chest; smaller pots scale down.
   * Item chance per round ≈ P(win) × pot / chestItemPot = stake / 10 000 — so
   * an item costs the same rake whatever the table (was pot/5 000, floor 15 %:
   * a 50-gold copper seat got ~3 % items per round for 2.5 gold of rake).
   */
  chestItemPot: 10_000,
  chestItemMinChance: 0.02,
  seatsMin: 4,
  seatsMax: 6,
  tiers: [
    { key: 'copper', minStake: 50, maxStake: 500, minLevel: 1 },
    { key: 'silver', minStake: 300, maxStake: 3_000, minLevel: 10 },
    { key: 'gold', minStake: 2_000, maxStake: 20_000, minLevel: 20 },
  ] as readonly FortuneTier[],
} as const

export function tierFor(key: string): FortuneTier | undefined {
  return FORTUNE_TABLE.tiers.find((t) => t.key === key)
}

// ---------------------------------------------------------------------------
// Persisted round
// ---------------------------------------------------------------------------

export type BotStyle = 'cautious' | 'steady' | 'whale' | 'gambler'

export interface FortuneEntry {
  /** ms after the round opened */
  readonly at: number
  readonly amount: number
}

export interface FortuneBot {
  readonly id: string
  readonly name: string
  readonly portrait: string
  readonly style: BotStyle
  /** First entry is the join; any later ones are top-ups. */
  readonly entries: readonly FortuneEntry[]
}

export interface FortuneRoundSecret {
  readonly v: 1
  readonly tier: FortuneTierKey
  readonly seed: string
  readonly commitment: string
  readonly playerName: string
  readonly playerEntries: readonly FortuneEntry[]
  readonly bots: readonly FortuneBot[]
}

export interface FortuneSeat {
  readonly seat: number
  readonly isYou: boolean
  readonly name: string
  readonly portrait: string | null
  readonly style: BotStyle | 'you'
  readonly stake: number
  /** ms after open when this seat first sat down */
  readonly joinedAt: number
}

// ---------------------------------------------------------------------------
// Seeded randomness
// ---------------------------------------------------------------------------

export type Rng = () => number

/** mulberry32 — small, fast, good enough for cosmetic bot behaviour. */
export function mulberry32(seed: number): Rng {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

/** A stream derived from the seed for one purpose, so streams never overlap. */
export function seededRng(seed: string, purpose: string): Rng {
  const h = createHmac('sha256', seed).update(purpose).digest()
  return mulberry32(h.readUInt32BE(0))
}

export function newSeed(): string {
  return randomBytes(32).toString('hex')
}

export function commitmentFor(seed: string): string {
  return createHash('sha256').update(seed).digest('hex')
}

/** The ticket: a point in [0, 1) on the wheel, fixed by the seed alone. */
export function ticketFor(seed: string): number {
  const h = createHmac('sha256', seed).update('ticket').digest()
  // 52 bits → exact in a double
  const hi = h.readUInt32BE(0) >>> 12 // 20 bits
  const lo = h.readUInt32BE(4) // 32 bits
  return (hi * 2 ** 32 + lo) / 2 ** 52
}

// ---------------------------------------------------------------------------
// Tavern regulars
// ---------------------------------------------------------------------------

const BOT_NAMES = [
  'Grimm', 'Sela', 'Old Bram', 'Vex', 'Marrow', 'Tilda Two-Coins', 'Hollis', 'Rook',
  'Mad Agna', 'Corvin', 'Pell', 'Ysolde', 'Brother Ashe', 'Kettle', 'Ivo the Red', 'Nan Hesk',
  'Fennick', 'Dagny', 'Lark', 'One-Eyed Jory',
] as const

/** Bundled hero portraits on the client (`hero_portrait_01…16`). */
const PORTRAIT_COUNT = 16

const STYLE_WEIGHT: Record<BotStyle, number> = { cautious: 0.6, steady: 1.0, whale: 2.2, gambler: 1.0 }

function pick<T>(rng: Rng, list: readonly T[]): T {
  return list[Math.floor(rng() * list.length)]
}

function shuffled<T>(rng: Rng, list: readonly T[]): T[] {
  const out = [...list]
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1))
    ;[out[i], out[j]] = [out[j], out[i]]
  }
  return out
}

function roundTo(value: number, step: number): number {
  return Math.max(step, Math.round(value / step) * step)
}

/**
 * Seat the regulars for a round. Their total stake is 1.5×–5× the player's
 * opening stake (so the player's chance usually sits around 15–40 %), split
 * by temperament; some are already seated, the rest drift in during the
 * lobby; gamblers top up near the end. Fixed at open, never adjusted.
 */
export function generateBots(seed: string, tier: FortuneTier, openingStake: number): FortuneBot[] {
  const rng = seededRng(seed, 'bots')
  const seatsTotal = FORTUNE_TABLE.seatsMin + Math.floor(rng() * (FORTUNE_TABLE.seatsMax - FORTUNE_TABLE.seatsMin + 1))
  const botCount = seatsTotal - 1
  const styles: BotStyle[] = Array.from({ length: botCount }, () =>
    pick(rng, ['cautious', 'steady', 'steady', 'whale', 'gambler'] as const))
  const weightSum = styles.reduce((s, st) => s + STYLE_WEIGHT[st], 0)
  const totalBotStake = openingStake * (1.5 + rng() * 3.5)

  const names = shuffled(rng, BOT_NAMES)
  const portraits = shuffled(rng, Array.from({ length: PORTRAIT_COUNT }, (_, i) => i + 1))
  const step = tier.minStake >= 1_000 ? 100 : 10
  const alreadySeated = 1 + Math.floor(rng() * 2) // 1–2 regulars are there before you

  return styles.map((style, i) => {
    const share = (STYLE_WEIGHT[style] / weightSum) * (0.8 + rng() * 0.4)
    const stake = Math.min(tier.maxStake, Math.max(tier.minStake, roundTo(totalBotStake * share, step)))
    const joinAt = i < alreadySeated
      ? 0
      : Math.round(2_000 + rng() * (FORTUNE_TABLE.lobbyMs - 5_000))
    const entries: FortuneEntry[] = [{ at: joinAt, amount: stake }]
    if (style === 'gambler') {
      const extra = Math.min(tier.maxStake - stake, roundTo(stake * (0.3 + rng() * 0.5), step))
      if (extra >= tier.minStake) {
        const at = Math.max(joinAt + 1_000,
          Math.round(FORTUNE_TABLE.lobbyMs - 7_000 + rng() * (7_000 - FORTUNE_TABLE.topUpCloseMs - 500)))
        entries.push({ at: Math.min(at, FORTUNE_TABLE.lobbyMs - FORTUNE_TABLE.topUpCloseMs - 100), amount: extra })
      }
    }
    const portraitNo = portraits[i % portraits.length]
    return {
      id: `bot_${i}`,
      name: names[i % names.length],
      portrait: `hero_portrait_${String(portraitNo).padStart(2, '0')}`,
      style,
      entries,
    }
  })
}

export function openRound(args: {
  tier: FortuneTier
  stake: number
  playerName: string
  seed?: string
}): FortuneRoundSecret {
  const seed = args.seed ?? newSeed()
  return {
    v: 1,
    tier: args.tier.key,
    seed,
    commitment: commitmentFor(seed),
    playerName: args.playerName,
    playerEntries: [{ at: 0, amount: args.stake }],
    bots: generateBots(seed, args.tier, args.stake),
  }
}

// ---------------------------------------------------------------------------
// Reading a round at a moment
// ---------------------------------------------------------------------------

/** Seats as they stand `elapsedMs` into the round (everything, once locked). */
export function seatsAt(round: FortuneRoundSecret, elapsedMs: number): FortuneSeat[] {
  const visible = (entries: readonly FortuneEntry[]) => entries.filter((e) => e.at <= elapsedMs)
  const raw: Omit<FortuneSeat, 'seat'>[] = []
  const mine = visible(round.playerEntries)
  if (mine.length > 0) {
    raw.push({
      isYou: true, name: round.playerName, portrait: null, style: 'you',
      stake: mine.reduce((s, e) => s + e.amount, 0), joinedAt: mine[0].at,
    })
  }
  for (const bot of round.bots) {
    const seen = visible(bot.entries)
    if (seen.length === 0) continue
    raw.push({
      isYou: false, name: bot.name, portrait: bot.portrait, style: bot.style,
      stake: seen.reduce((s, e) => s + e.amount, 0), joinedAt: seen[0].at,
    })
  }
  // Seat order = order of arrival; the player goes first on a tie (opening the round).
  raw.sort((a, b) => a.joinedAt - b.joinedAt || Number(b.isYou) - Number(a.isYou))
  return raw.map((s, seat) => ({ ...s, seat }))
}

export function potOf(seats: readonly FortuneSeat[]): number {
  return seats.reduce((s, x) => s + x.stake, 0)
}

export function playerStake(round: FortuneRoundSecret): number {
  return round.playerEntries.reduce((s, e) => s + e.amount, 0)
}

export function payoutFor(pot: number): number {
  return Math.floor(pot * (1 - FORTUNE_TABLE.rake))
}

export function chestItemChance(pot: number): number {
  return Math.min(1, Math.max(FORTUNE_TABLE.chestItemMinChance, pot / FORTUNE_TABLE.chestItemPot))
}

export interface FortuneDraw {
  readonly ticket: number
  readonly winnerSeat: number
  readonly playerWon: boolean
  readonly pot: number
  readonly payout: number
  /** Whether the chest holds an item (only matters when the player wins). */
  readonly chestHasItem: boolean
}

/** The draw over the final seats: the ticket falls in one slice. */
export function drawWinner(round: FortuneRoundSecret): FortuneDraw {
  const seats = seatsAt(round, Number.POSITIVE_INFINITY)
  const pot = potOf(seats)
  const ticket = ticketFor(round.seed)
  let cum = 0
  let winnerSeat = seats.length - 1
  for (const s of seats) {
    cum += s.stake
    if (ticket < cum / pot) { winnerSeat = s.seat; break }
  }
  const playerWon = seats[winnerSeat]?.isYou ?? false
  const chestRoll = seededRng(round.seed, 'chest')()
  return {
    ticket,
    winnerSeat,
    playerWon,
    pot,
    payout: playerWon ? payoutFor(pot) : 0,
    chestHasItem: playerWon && chestRoll < chestItemChance(pot),
  }
}

export type TopUpRejection = 'LOCKED' | 'BELOW_MIN' | 'OVER_MAX'

/** Can the player add `amount` now? Returns null when allowed. */
export function topUpRejection(round: FortuneRoundSecret, tier: FortuneTier, amount: number, elapsedMs: number): TopUpRejection | null {
  if (elapsedMs >= FORTUNE_TABLE.lobbyMs - FORTUNE_TABLE.topUpCloseMs) return 'LOCKED'
  if (!Number.isInteger(amount) || amount < tier.minStake) return 'BELOW_MIN'
  if (playerStake(round) + amount > tier.maxStake) return 'OVER_MAX'
  return null
}

export function withTopUp(round: FortuneRoundSecret, amount: number, elapsedMs: number): FortuneRoundSecret {
  return { ...round, playerEntries: [...round.playerEntries, { at: Math.max(0, Math.round(elapsedMs)), amount }] }
}

/** Safe parse of the JSON stored in MinigameSession.secretData. */
export function asRoundSecret(value: unknown): FortuneRoundSecret | null {
  if (!value || typeof value !== 'object') return null
  const v = value as Partial<FortuneRoundSecret>
  if (v.v !== 1 || typeof v.seed !== 'string' || !Array.isArray(v.playerEntries) || !Array.isArray(v.bots)) return null
  if (!tierFor(String(v.tier))) return null
  return v as FortuneRoundSecret
}
