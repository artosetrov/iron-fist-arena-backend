/**
 * One class matrix for loot, equip and shop; one prestige-aware level gate
 * for gear (2026-10-14).
 */
import { describe, expect, it, vi } from 'vitest'

// loot.ts pulls in live-config → prisma; this test never touches the DB.
vi.mock('@/lib/prisma', () => ({ prisma: {} }))
import { CLASS_COMPAT, canClassWear, wearableRestrictions } from '@/lib/game/class-compat'
import { CLASS_COMPAT as LOOT_CLASS_COMPAT } from '@/lib/game/loot'
import { effectiveGearLevel } from '@/lib/game/gear-level'
import { PRESTIGE } from '@/lib/game/balance'

describe('class-compat', () => {
  it('is the same object loot.ts uses', () => {
    expect(LOOT_CLASS_COMPAT).toBe(CLASS_COMPAT)
  })

  it('warrior and tank share, rogue and mage are isolated', () => {
    expect(canClassWear('warrior', 'tank')).toBe(true)
    expect(canClassWear('tank', 'warrior')).toBe(true)
    expect(canClassWear('rogue', 'warrior')).toBe(false)
    expect(canClassWear('mage', 'rogue')).toBe(false)
    expect(canClassWear('mage', 'mage')).toBe(true)
  })

  it('treats null / empty / whitespace / mixed-case restrictions as universal or case-insensitive', () => {
    expect(canClassWear('rogue', null)).toBe(true)
    expect(canClassWear('rogue', '')).toBe(true)
    expect(canClassWear('rogue', '   ')).toBe(true)
    expect(canClassWear('tank', ' Warrior ')).toBe(true)
  })

  it('an unknown class can only wear its own restriction', () => {
    expect(wearableRestrictions('paladin')).toEqual(['paladin'])
    expect(canClassWear('paladin', 'warrior')).toBe(false)
  })
})

describe('effectiveGearLevel', () => {
  it('is the plain level without prestige', () => {
    expect(effectiveGearLevel(17, 0)).toBe(17)
    expect(effectiveGearLevel(17, null)).toBe(17)
    expect(effectiveGearLevel(17, undefined)).toBe(17)
  })

  it('is at least MAX_LEVEL once prestiged, whatever the current level', () => {
    expect(effectiveGearLevel(1, 1)).toBe(PRESTIGE.MAX_LEVEL)
    expect(effectiveGearLevel(33, 2)).toBe(PRESTIGE.MAX_LEVEL)
    expect(effectiveGearLevel(60, 1, 50)).toBe(60)
  })

  it('sanitises garbage levels', () => {
    expect(effectiveGearLevel(Number.NaN, 0)).toBe(1)
    expect(effectiveGearLevel(-4, 0)).toBe(1)
    expect(effectiveGearLevel(7.9, 0)).toBe(7)
  })
})
