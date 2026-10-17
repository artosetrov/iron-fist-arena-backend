/**
 * diceHitProfile — the dice snapshot is the EXPECTED value of one classic
 * strike (2026-10-16 balance audit §2). Before this, LUK, AGI dodge/crit,
 * CHA and every crit/dodge passive node did nothing in live PvP.
 */
import { beforeEach, describe, expect, it, vi } from 'vitest'

const configMock = vi.hoisted(() => ({ getGameConfig: vi.fn(), getGameConfigs: vi.fn() }))
vi.mock('@/lib/prisma', () => ({ prisma: {} }))
vi.mock('../../src/lib/game/config', () => ({
  getGameConfig: configMock.getGameConfig,
  getGameConfigs: configMock.getGameConfigs,
}))

import { diceHitProfile, DICE_DAMAGE_REDUCTION_CAP, type CharacterStats } from '../../src/lib/game/combat'
import { emptyPassiveBonuses } from '../../src/lib/game/passives'
import { COMBAT } from '../../src/lib/game/balance'

function fighter(id: string, over: Partial<CharacterStats> = {}): CharacterStats {
  return {
    id, name: id, class: 'warrior', level: 25,
    str: 199, agi: 0, vit: 147, end: 101, int: 10, wis: 10, luk: 0, cha: 0,
    maxHp: 1121, armor: 303, magicResist: 180,
    combatStance: { attack: 'chest', defense: 'chest' },
    ...over,
  }
}

describe('diceHitProfile', () => {
  beforeEach(() => {
    configMock.getGameConfig.mockImplementation(async (_k: string, fallback: unknown) => fallback)
    configMock.getGameConfigs.mockImplementation(async (defaults: Record<string, unknown>) => defaults)
  })

  it('folds crit chance in as expectation — LUK and passive crit both count', async () => {
    const base = (await diceHitProfile(fighter('a'), fighter('b'))).hit
    const luk = (await diceHitProfile(fighter('a', { luk: 50 }), fighter('b'))).hit // 30% crit
    const passive = (await diceHitProfile(
      fighter('a', { passiveBonuses: { ...emptyPassiveBonuses(), flatCritChance: 30 } }),
      fighter('b'),
    )).hit
    const expected = Math.round(base * (1 + 0.3 * (COMBAT.CRIT_MULTIPLIER - 1)))
    expect(luk).toBeGreaterThan(base)
    expect(Math.abs(luk - expected)).toBeLessThanOrEqual(1)
    expect(Math.abs(passive - luk)).toBeLessThanOrEqual(1)
  })

  it('folds the defender dodge and CHA miss in as 1 − p', async () => {
    const base = (await diceHitProfile(fighter('a'), fighter('b'))).hit
    const dodgy = (await diceHitProfile(
      fighter('a'),
      fighter('b', { passiveBonuses: { ...emptyPassiveBonuses(), flatDodgeChance: 20 } }),
    )).hit
    const charming = (await diceHitProfile(fighter('a'), fighter('b', { cha: 50 }))).hit // 10% miss
    expect(Math.abs(dodgy - Math.round(base * 0.8))).toBeLessThanOrEqual(1)
    expect(Math.abs(charming - Math.round(base * 0.9))).toBeLessThanOrEqual(1)
  })

  it('caps tank class reduction and passive DR together', async () => {
    const base = (await diceHitProfile(fighter('a'), fighter('b'))).hit
    const tankWall = (await diceHitProfile(
      fighter('a'),
      fighter('b', { class: 'tank', passiveBonuses: { ...emptyPassiveBonuses(), damageReduction: 50 } }),
    )).hit
    // 15 (class) + 50 (passives) = 65 → capped at DICE_DAMAGE_REDUCTION_CAP.
    expect(Math.abs(tankWall - Math.round(base * (1 - DICE_DAMAGE_REDUCTION_CAP / 100)))).toBeLessThanOrEqual(1)
    expect(tankWall).toBeGreaterThan(base * 0.5)
  })
})
