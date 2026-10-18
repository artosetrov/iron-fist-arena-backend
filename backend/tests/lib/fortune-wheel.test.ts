import { describe, expect, it } from 'vitest'
import {
  JACKPOT_SECTOR_INDEX, WHEEL_SECTORS, WHEEL_TREASURY, treasuryFeed, treasuryShare, wheelOdds,
} from '../../src/lib/game/fortune-wheel'

describe('fortune wheel — sector table', () => {
  const total = WHEEL_SECTORS.reduce((s, x) => s + x.weight, 0)

  it('has 12 sectors indexed in order', () => {
    expect(WHEEL_SECTORS).toHaveLength(12)
    WHEEL_SECTORS.forEach((s, i) => expect(s.index).toBe(i))
  })

  it('pays back about 88 % before the Treasury', () => {
    const rtp = WHEEL_SECTORS.reduce((s, x) => s + x.weight * x.multiplier, 0) / total
    expect(rtp).toBeGreaterThan(0.87)
    expect(rtp).toBeLessThan(0.9)
  })

  it('pays on close to half the spins', () => {
    const paying = WHEEL_SECTORS.filter((s) => s.multiplier > 0).reduce((s, x) => s + x.weight, 0) / total
    expect(paying).toBeGreaterThan(0.45)
    expect(paying).toBeLessThan(0.5)
  })

  it('the jackpot sector is the top multiplier', () => {
    const top = Math.max(...WHEEL_SECTORS.map((s) => s.multiplier))
    expect(WHEEL_SECTORS[JACKPOT_SECTOR_INDEX].multiplier).toBe(top)
  })

  it('discloses odds that add up to 100 %', () => {
    const odds = wheelOdds()
    const sum = odds.reduce((s, o) => s + o.percent, 0)
    expect(sum).toBeGreaterThan(99.8)
    expect(sum).toBeLessThan(100.2)
    expect(odds[0].multiplier).toBe(0)
  })
})

describe('fortune wheel — Treasury', () => {
  it('feeds 2 % of a bet, at least 1', () => {
    expect(treasuryFeed(1_000)).toBe(20)
    expect(treasuryFeed(10)).toBe(1)
  })

  it('pays a max bet a fifth of the Treasury and smaller bets less', () => {
    expect(treasuryShare(12_345, WHEEL_TREASURY.maxBet)).toBe(2_469)
    expect(treasuryShare(12_345, WHEEL_TREASURY.maxBet * 3)).toBe(2_469)
    expect(treasuryShare(10_000, 100)).toBe(200)
  })

  it('keeps the wheel near 91 % with the Treasury (simulated)', () => {
    // Deterministic LCG so the run is the same every time.
    let s = 12345
    const rnd = () => ((s = (s * 1103515245 + 12345) % 2 ** 31) / 2 ** 31)
    const total = WHEEL_SECTORS.reduce((a, x) => a + x.weight, 0)
    const bets = [50, 100, 200, 500, 1000]
    let treasury: number = WHEEL_TREASURY.seed
    let staked = 0
    let paid = 0
    for (let i = 0; i < 400_000; i++) {
      const bet = bets[Math.floor(rnd() * bets.length)]
      staked += bet
      treasury += treasuryFeed(bet)
      let r = rnd() * total
      const sector = WHEEL_SECTORS.find((x) => (r -= x.weight) < 0) ?? WHEEL_SECTORS[0]
      paid += bet * sector.multiplier
      if (sector.index === JACKPOT_SECTOR_INDEX) {
        const share = treasuryShare(treasury, bet)
        paid += share
        treasury = Math.max(WHEEL_TREASURY.seed, treasury - share)
      }
    }
    const rtp = paid / staked
    expect(rtp).toBeGreaterThan(0.88)
    expect(rtp).toBeLessThan(0.94)
  })
})
