/**
 * Dice table (play mat) picked for a duel — src/lib/game/dice-tables.ts.
 * Spec: docs/06_game_systems/DICE_3D_THROW.md §7.
 */
import { describe, expect, it } from 'vitest'
import { DICE_TABLE_KEYS, diceTableFor, isDiceTableKey } from '@/lib/game/dice-tables'

describe('diceTableFor', () => {
  it('fights on the defender class table in PvP and against bots', () => {
    expect(diceTableFor({ opponentType: 'pvp', defenderClass: 'warrior' })).toBe('warrior')
    expect(diceTableFor({ opponentType: 'pvp', defenderClass: 'rogue' })).toBe('rogue')
    expect(diceTableFor({ opponentType: 'bot', defenderClass: 'mage' })).toBe('mage')
    expect(diceTableFor({ opponentType: 'bot', defenderClass: 'tank' })).toBe('tank')
  })

  it('falls back to the tavern table for an unknown or missing class', () => {
    expect(diceTableFor({ opponentType: 'bot', defenderClass: null })).toBe('tavern')
    expect(diceTableFor({ opponentType: 'pvp', defenderClass: 'paladin' })).toBe('tavern')
  })

  it('uses the mode table in dungeons', () => {
    expect(diceTableFor({ opponentType: 'dungeon_boss', defenderClass: 'warrior' })).toBe('dragon')
    expect(diceTableFor({ opponentType: 'dungeon_rush', rushRoomType: 'miniboss' })).toBe('dragon')
    expect(diceTableFor({ opponentType: 'dungeon_rush', rushRoomType: 'combat' })).toBe('dungeon')
  })

  it('lets an equipped cosmetic table win, ignoring unknown keys', () => {
    expect(diceTableFor({ opponentType: 'pvp', defenderClass: 'rogue', cosmetic: 'royal' })).toBe('royal')
    expect(diceTableFor({ opponentType: 'dungeon_boss', cosmetic: 'frost' })).toBe('frost')
    expect(diceTableFor({ opponentType: 'pvp', defenderClass: 'rogue', cosmetic: 'gold-plated' })).toBe('rogue')
  })

  it('has the 10 keys the iOS client ships mats for', () => {
    expect(DICE_TABLE_KEYS).toHaveLength(10)
    expect(new Set(DICE_TABLE_KEYS).size).toBe(10)
    for (const k of DICE_TABLE_KEYS) expect(isDiceTableKey(k)).toBe(true)
    expect(isDiceTableKey('felt')).toBe(false)
  })
})
