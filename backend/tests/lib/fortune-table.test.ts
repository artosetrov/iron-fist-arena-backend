import { describe, expect, it } from 'vitest'
import {
  FORTUNE_TABLE, chestItemChance, commitmentFor, drawWinner, generateBots, openRound, payoutFor,
  playerStake, potOf, seatsAt, ticketFor, tierFor, topUpRejection, withTopUp, asRoundSecret,
} from '../../src/lib/game/fortune-table'

const copper = tierFor('copper')!
const gold = tierFor('gold')!

function seedN(n: number): string {
  return n.toString(16).padStart(64, '0')
}

describe('fortune table — round set-up', () => {
  it('seats 4–6 at every table, bots within the tier limits', () => {
    for (let n = 0; n < 300; n++) {
      const round = openRound({ tier: copper, stake: 200, playerName: 'Hero', seed: seedN(n) })
      const seats = seatsAt(round, Number.POSITIVE_INFINITY)
      expect(seats.length).toBeGreaterThanOrEqual(FORTUNE_TABLE.seatsMin)
      expect(seats.length).toBeLessThanOrEqual(FORTUNE_TABLE.seatsMax)
      for (const bot of round.bots) {
        const total = bot.entries.reduce((s, e) => s + e.amount, 0)
        expect(total).toBeLessThanOrEqual(copper.maxStake)
        expect(bot.entries[0].amount).toBeGreaterThanOrEqual(copper.minStake)
        for (const e of bot.entries) {
          expect(e.at).toBeGreaterThanOrEqual(0)
          expect(e.at).toBeLessThan(FORTUNE_TABLE.lobbyMs - FORTUNE_TABLE.topUpCloseMs)
        }
        expect(bot.portrait).toMatch(/^hero_portrait_(0[1-9]|1[0-6])$/)
      }
      expect(new Set(round.bots.map((b) => b.name)).size).toBe(round.bots.length)
    }
  })

  it('is deterministic for a seed and commits to it', () => {
    const a = openRound({ tier: gold, stake: 5_000, playerName: 'Hero', seed: seedN(7) })
    const b = openRound({ tier: gold, stake: 5_000, playerName: 'Hero', seed: seedN(7) })
    expect(a.bots).toEqual(b.bots)
    expect(a.commitment).toBe(commitmentFor(seedN(7)))
    expect(a.commitment).toMatch(/^[0-9a-f]{64}$/)
  })

  it('keeps the player chance in a sensible band on average', () => {
    let sum = 0
    const N = 500
    for (let n = 0; n < N; n++) {
      const round = openRound({ tier: copper, stake: 200, playerName: 'Hero', seed: seedN(1000 + n) })
      const seats = seatsAt(round, Number.POSITIVE_INFINITY)
      sum += 200 / potOf(seats)
    }
    const mean = sum / N
    expect(mean).toBeGreaterThan(0.15)
    expect(mean).toBeLessThan(0.45)
  })

  it('shows only who has sat down so far, player first on a tie', () => {
    const round = openRound({ tier: copper, stake: 100, playerName: 'Hero', seed: seedN(3) })
    const atOpen = seatsAt(round, 0)
    expect(atOpen[0].isYou).toBe(true)
    expect(atOpen.length).toBeLessThanOrEqual(3)
    const later = seatsAt(round, FORTUNE_TABLE.lobbyMs)
    expect(later.length).toBeGreaterThanOrEqual(atOpen.length)
    expect(later.map((s) => s.seat)).toEqual(later.map((_, i) => i))
  })
})

describe('fortune table — the draw', () => {
  it('ticket is in [0,1) and fixed by the seed', () => {
    for (let n = 0; n < 200; n++) {
      const t = ticketFor(seedN(n))
      expect(t).toBeGreaterThanOrEqual(0)
      expect(t).toBeLessThan(1)
      expect(ticketFor(seedN(n))).toBe(t)
    }
  })

  it('winner is the seat whose slice holds the ticket', () => {
    for (let n = 0; n < 200; n++) {
      const round = openRound({ tier: copper, stake: 300, playerName: 'Hero', seed: seedN(n) })
      const draw = drawWinner(round)
      const seats = seatsAt(round, Number.POSITIVE_INFINITY)
      const pot = potOf(seats)
      let start = 0
      for (const s of seats.slice(0, draw.winnerSeat)) start += s.stake
      const end = start + seats[draw.winnerSeat].stake
      expect(draw.ticket).toBeGreaterThanOrEqual(start / pot)
      expect(draw.ticket).toBeLessThan(end / pot)
      expect(draw.playerWon).toBe(seats[draw.winnerSeat].isYou)
      expect(draw.payout).toBe(draw.playerWon ? payoutFor(pot) : 0)
    }
  })

  it('pays the player their share minus the tithe over many rounds', () => {
    let staked = 0
    let paid = 0
    const N = 6_000
    for (let n = 0; n < N; n++) {
      const round = openRound({ tier: copper, stake: 200, playerName: 'Hero', seed: seedN(50_000 + n) })
      const draw = drawWinner(round)
      staked += playerStake(round)
      paid += draw.payout
    }
    const rtp = paid / staked
    // Expected 0.95; ±0.06 covers the sampling spread of a 6k-round run.
    expect(rtp).toBeGreaterThan(0.89)
    expect(rtp).toBeLessThan(1.01)
  })

  it('chest item chance grows with the pot and is capped at 1', () => {
    expect(chestItemChance(100)).toBe(FORTUNE_TABLE.chestItemMinChance)
    expect(chestItemChance(5_000)).toBeCloseTo(0.5)
    expect(chestItemChance(50_000)).toBe(1)
  })
})

describe('fortune table — top-ups', () => {
  const round = openRound({ tier: copper, stake: 100, playerName: 'Hero', seed: seedN(11) })

  it('accepts a top-up within limits before bets close', () => {
    expect(topUpRejection(round, copper, 100, 5_000)).toBeNull()
    const after = withTopUp(round, 100, 5_000)
    expect(playerStake(after)).toBe(200)
    expect(seatsAt(after, 6_000).find((s) => s.isYou)?.stake).toBe(200)
  })

  it('rejects late, small and over-cap top-ups', () => {
    expect(topUpRejection(round, copper, 100, FORTUNE_TABLE.lobbyMs - FORTUNE_TABLE.topUpCloseMs)).toBe('LOCKED')
    expect(topUpRejection(round, copper, 10, 1_000)).toBe('BELOW_MIN')
    expect(topUpRejection(round, copper, 450, 1_000)).toBe('OVER_MAX')
    expect(topUpRejection(round, copper, 1.5, 1_000)).toBe('BELOW_MIN')
  })

  it('round-trips through JSON', () => {
    const parsed = asRoundSecret(JSON.parse(JSON.stringify(round)))
    expect(parsed).not.toBeNull()
    expect(drawWinner(parsed!)).toEqual(drawWinner(round))
    expect(asRoundSecret({ v: 2 })).toBeNull()
    expect(asRoundSecret(null)).toBeNull()
  })

  it('bots never depend on the player top-ups', () => {
    const before = generateBots(seedN(11), copper, 100)
    expect(withTopUp(round, 300, 2_000).bots).toEqual(before)
  })
})
