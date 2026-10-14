/**
 * Premium Pass benefits that the purchase screen advertises — 2026-10-14 audit.
 *
 * Nine benefits were listed; two existed (+10% gold, 300 gems per renewal).
 * These pin the ones added so the screen and the server agree.
 */
import { describe, expect, it } from 'vitest'
import {
  freePvpPerDay,
  goldBonusMultiplier,
  xpBonusMultiplier,
  PREMIUM_FREE_PVP_PER_DAY,
  PREMIUM_XP_MULTIPLIER,
} from '../../src/lib/game/premium'

const now = new Date('2026-10-14T12:00:00Z')
const premium = { premiumUntil: new Date('2027-01-01T00:00:00Z'), premiumSubscription: null }
const expired = { premiumUntil: new Date('2026-01-01T00:00:00Z'), premiumSubscription: null }
const free = { premiumUntil: null, premiumSubscription: null }

describe('premium benefits', () => {
  it('gives +20% XP alongside the existing +10% gold', () => {
    expect(xpBonusMultiplier(premium, now)).toBe(PREMIUM_XP_MULTIPLIER)
    expect(goldBonusMultiplier(premium, now)).toBe(1.1)
    expect(xpBonusMultiplier(free, now)).toBe(1)
    expect(xpBonusMultiplier(expired, now)).toBe(1)
  })

  it('raises the free PvP allowance to 5, and never below the base', () => {
    expect(freePvpPerDay(premium, 3, now)).toBe(PREMIUM_FREE_PVP_PER_DAY)
    expect(freePvpPerDay(free, 3, now)).toBe(3)
    expect(freePvpPerDay(expired, 3, now)).toBe(3)
    // A live-config base above the premium value is kept as-is.
    expect(freePvpPerDay(premium, 7, now)).toBe(7)
    // Routes that have no user loaded fall back to the base.
    expect(freePvpPerDay(null, 3, now)).toBe(3)
  })
})
