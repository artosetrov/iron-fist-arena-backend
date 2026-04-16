import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockLoadCombatCharacter,
  mockGetScriptedOpponent,
  mockRunCombat,
  mockInitCombatConfig,
  mockApplyLevelUp,
  mockGetBuildingsUnlockedAt,
  mockLogTutorialEvent,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(),
  mockLoadCombatCharacter: vi.fn(),
  mockGetScriptedOpponent: vi.fn(),
  mockRunCombat: vi.fn(),
  mockInitCombatConfig: vi.fn(),
  mockApplyLevelUp: vi.fn(),
  mockGetBuildingsUnlockedAt: vi.fn(),
  mockLogTutorialEvent: vi.fn(),
  prismaMock: {
    character: {
      findUnique: vi.fn(),
    },
    $transaction: vi.fn(),
  },
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/rate-limit', () => ({
  rateLimit: mockRateLimit,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/game/combat-loader', () => ({
  loadCombatCharacter: mockLoadCombatCharacter,
}))

vi.mock('@/lib/game/tutorial-opponents', () => ({
  getScriptedOpponent: mockGetScriptedOpponent,
}))

vi.mock('@/lib/game/combat', () => ({
  runCombat: mockRunCombat,
  initCombatConfig: mockInitCombatConfig,
}))

vi.mock('@/lib/game/progression', () => ({
  applyLevelUp: mockApplyLevelUp,
}))

vi.mock('@/lib/game/tutorial', () => ({
  TUTORIAL_FIGHT_REWARDS: {
    gold: 150,
    xp: 50,
    itemCatalogKey: 'starter_blade',
    rateLimit: { max: 3, windowMs: 60_000 },
  },
  getBuildingsUnlockedAt: mockGetBuildingsUnlockedAt,
}))

vi.mock('@/lib/game/tutorial-analytics', () => ({
  logTutorialEvent: mockLogTutorialEvent,
}))

import { POST as preloadPOST } from '@/app/api/tutorial/scripted-fight/preload/route'
import { POST as resolvePOST } from '@/app/api/tutorial/scripted-fight/resolve/route'

describe('tutorial scripted-fight contracts', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    mockGetBuildingsUnlockedAt.mockReturnValue(['forge'])
  })

  it('preload returns canonical forced_stance plus legacy forcedStance alias', async () => {
    prismaMock.character.findUnique.mockResolvedValue({
      id: 'char-1',
      userId: 'user-1',
      tutorialCompleted: false,
      tutorialSkipped: false,
      tutorialStep: 0,
    })
    mockLoadCombatCharacter.mockResolvedValue({
      id: 'char-1',
      class: 'warrior',
      maxHp: 100,
    })
    mockGetScriptedOpponent.mockReturnValue({
      character: { id: 'npc-1', name: 'Orc Grunt', maxHp: 80 },
      forcedStance: { attack: 'head', defense: 'chest' },
    })

    const response = await preloadPOST(
      makeNextRequest('http://localhost/api/tutorial/scripted-fight/preload', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1' }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      forced_stance: { attack: 'head', defense: 'chest' },
      forcedStance: { attack: 'head', defense: 'chest' },
      scripted: true,
    })
  })

  it('resolve returns canonical snake_case progression fields and legacy aliases', async () => {
    mockInitCombatConfig.mockResolvedValue(undefined)
    mockLoadCombatCharacter.mockResolvedValue({
      id: 'char-1',
      class: 'warrior',
      maxHp: 100,
    })
    mockGetScriptedOpponent.mockReturnValue({
      character: { id: 'npc-1', maxHp: 80, currentHp: 80 },
      forcedStance: { attack: 'head', defense: 'chest' },
      guaranteedVictorySeed: 'seed-1',
    })
    mockRunCombat.mockResolvedValue({
      winnerId: 'char-1',
      totalTurns: 3,
    })
    mockApplyLevelUp.mockResolvedValue({
      leveledUp: true,
      newLevel: 2,
      remainingXp: 0,
      statPointsAwarded: 3,
      passivePointsAwarded: 1,
      atMaxLevel: false,
    })

    const tx = {
      $queryRawUnsafe: vi.fn(async () => [{
        id: 'char-1',
        user_id: 'user-1',
        level: 1,
        tutorial_completed: false,
        tutorial_skipped: false,
        tutorial_step: 0,
      }]),
      character: {
        update: vi.fn(async () => ({})),
      },
      user: {
        update: vi.fn(async () => ({})),
      },
      item: {
        findUnique: vi.fn(async () => ({ id: 'item-1', itemName: 'Starter Blade' })),
      },
      equipmentInventory: {
        create: vi.fn(async () => ({})),
      },
    }
    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: typeof tx) => Promise<unknown>) => callback(tx),
    )

    const response = await resolvePOST(
      makeNextRequest('http://localhost/api/tutorial/scripted-fight/resolve', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1' }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      rewards: {
        gold: 150,
        xp: 50,
        item_catalog_key: 'starter_blade',
        itemCatalogKey: 'starter_blade',
        itemName: 'Starter Blade',
      },
      level_up: {
        leveled_up: true,
        new_level: 2,
        stat_points_awarded: 3,
        passive_points_awarded: 1,
        at_max_level: false,
      },
      levelUp: {
        leveledUp: true,
        newLevel: 2,
        statPointsAwarded: 3,
        passivePointsAwarded: 1,
        atMaxLevel: false,
      },
      unlocks: ['forge'],
      sanity_check_passed: true,
      sanityCheckPassed: true,
    })
  })
})
