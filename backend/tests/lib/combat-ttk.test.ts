/**
 * Time-to-kill guard — 2026-10-14 balance audit.
 *
 * Armor reduced damage by 100/(100+armor) with no ceiling while damage grew
 * linearly, so from L1 to L50 effective HP grew ×69 against damage ×28. The
 * measured result: 29% of L25 mirror matches and ~100% of L50 ones ran into
 * the 15-turn cap and were decided by an HP% comparison instead of a kill.
 *
 * This runs the real `runCombat` (config mocked to the balance.ts defaults)
 * over seeded mirror matches and pins the turn-cap rate, so a future armor or
 * HP change that makes fights mushy again fails here instead of in play.
 */
import { beforeEach, describe, expect, it, vi } from 'vitest'

const configMock = vi.hoisted(() => ({
  getGameConfig: vi.fn(),
  getGameConfigs: vi.fn(),
}))
vi.mock('@/lib/prisma', () => ({ prisma: {} }))
vi.mock('../../src/lib/game/config', () => ({
  getGameConfig: configMock.getGameConfig,
  getGameConfigs: configMock.getGameConfigs,
}))

import { runCombat, type CharacterStats } from '../../src/lib/game/combat'
import { COMBAT } from '../../src/lib/game/balance'

/** Level-appropriate warrior, numbers from the audit's gear model. */
function warrior(id: string, level: 25 | 50): CharacterStats {
  const stats = level === 50
    ? { str: 388, agi: 150, vit: 281, end: 193, luk: 40, cha: 32, maxHp: 2064, armor: 580 }
    : { str: 199, agi: 95,  vit: 147, end: 101, luk: 30, cha: 20, maxHp: 1121, armor: 303 }
  return {
    id, name: id, class: 'warrior', level,
    ...stats,
    int: 10, wis: 10,
    magicResist: Math.floor(stats.armor * 0.6),
    combatStance: { attack: 'chest', defense: 'chest' },
  }
}

async function turnCapRate(level: 25 | 50, fights: number): Promise<{ cap: number; rounds: number }> {
  let capped = 0
  let rounds = 0
  for (let i = 0; i < fights; i++) {
    const result = await runCombat(warrior('a', level), warrior('b', level), 1000 + i)
    // `turns` holds one entry per attack, two per round. A timeout is the only
    // way both fighters finish with HP left.
    rounds += result.totalTurns / 2
    if (result.finalHp.a > 0 && result.finalHp.b > 0) capped++
  }
  return { cap: capped / fights, rounds: rounds / fights }
}

function useResistCap(value: number) {
  configMock.getGameConfigs.mockImplementation(async (defaults: Record<string, unknown>) => ({
    ...defaults,
    'combat.max_resist_reduction': value,
  }))
}

describe('mirror-match time to kill', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    configMock.getGameConfig.mockImplementation(async (_k: string, fallback: unknown) => fallback)
    configMock.getGameConfigs.mockImplementation(async (defaults: Record<string, unknown>) => defaults)
  })

  it('documents the uncapped baseline the audit measured', async () => {
    useResistCap(1)
    const l50 = await turnCapRate(50, 120)
    // Uncapped, essentially every L50 mirror runs out the clock.
    expect(l50.cap).toBeGreaterThan(0.9)
  })

  it('with the shipped cap, mirrors end in a kill in roughly ten rounds', async () => {
    useResistCap(COMBAT.MAX_RESIST_REDUCTION)
    const l50 = await turnCapRate(50, 150)
    const l25 = await turnCapRate(25, 150)
    // Both bounds matter: too many timeouts is the mush this fixes, and a
    // fight that ends in 4 rounds is decided by the first crit roll.
    expect(l50.cap).toBeLessThan(0.1)
    expect(l25.cap).toBeLessThan(0.1)
    expect(l50.rounds).toBeGreaterThan(7)
    expect(l50.rounds).toBeLessThan(13)
    expect(l25.rounds).toBeGreaterThan(7)
    expect(l25.rounds).toBeLessThan(13)
  })
})

describe.skip('sweep (run manually: npx vitest run tests/lib/combat-ttk.test.ts -t sweep)', () => {
  it('sweep', async () => {
    configMock.getGameConfig.mockImplementation(async (_k: string, fallback: unknown) => fallback)
    for (const cap of [1, 0.75, 0.65, 0.6, 0.55, 0.5]) {
      useResistCap(cap)
      const l25 = await turnCapRate(25, 150)
      const l50 = await turnCapRate(50, 150)
      // eslint-disable-next-line no-console
      console.info(`cap ${cap}: L25 ${(l25.cap * 100).toFixed(0)}% / ${l25.rounds.toFixed(1)}r   L50 ${(l50.cap * 100).toFixed(0)}% / ${l50.rounds.toFixed(1)}r`)
    }
  })
})
