import { describe, it, expect } from 'vitest'
import { containsBlockedWords, isCharacterNameAllowed, normalizeForFilter } from '../../src/lib/moderation'

describe('moderation filter', () => {
  it('folds leetspeak and punctuation', () => {
    expect(normalizeForFilter('F.u_c-K')).toBe('fuck')
    expect(normalizeForFilter('sh1t')).toBe('shit')
    expect(normalizeForFilter('@$$')).toBe('ass')
  })

  it('catches obvious profanity in messages, including obfuscated forms', () => {
    expect(containsBlockedWords('go fuck yourself')).toBe(true)
    expect(containsBlockedWords('F U C K')).toBe(true)
    expect(containsBlockedWords('fuuuuck')).toBe(true)
    expect(containsBlockedWords('n1gga')).toBe(true)
  })

  it('lets ordinary game chat through', () => {
    expect(containsBlockedWords('gg wp, rematch?')).toBe(false)
    expect(containsBlockedWords('Nice build, what talents?')).toBe(false)
    expect(containsBlockedWords('')).toBe(false)
  })

  it('blocks impersonation and profanity in names, allows normal names', () => {
    expect(isCharacterNameAllowed('AdminBob')).toBe(false)
    expect(isCharacterNameAllowed('HexboundGM')).toBe(false)
    expect(isCharacterNameAllowed('Sh1tLord')).toBe(false)
    expect(isCharacterNameAllowed('ShadowBlade')).toBe(true)
    expect(isCharacterNameAllowed('Degon')).toBe(true)
  })
})
