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

  // ---------------------------------------------------------------------------
  // Regressions. The header of lib/moderation.ts says false positives on names
  // are worse than misses, because a player cannot rename for free — but
  // `cock`, `dick`, `rape`, `cunt` and `spic` were matched as bare substrings,
  // so the filter broke that promise on a dozen ordinary words while passing
  // the accented spelling of the word it exists to catch.
  // ---------------------------------------------------------------------------

  it.each([
    'Peacock', 'Cockpit', 'Cockatrice', 'Woodcock', 'Shuttlecock', 'Hitchcock',
    'Dickens', 'Dickinson', 'Grape', 'Grapeshot', 'Scunthorpe', 'Spiceweaver',
    'Shiitake', 'Octopus', 'Countess',
  ])('allows the ordinary name %s', (name) => {
    expect(isCharacterNameAllowed(name)).toBe(true)
  })

  it.each([
    'nice grape farm',
    'check the cockpit',
    'I love Dickens',
    'grapeshot build is suspicious',
    'that cockatrice hits hard',
  ])('lets the ordinary message "%s" through', (text) => {
    expect(containsBlockedWords(text)).toBe(false)
  })

  it('still catches the stem when it is not inside an allowed word', () => {
    // The shield is positional, not a blanket exemption for the stem.
    expect(containsBlockedWords('grape')).toBe(false)
    expect(containsBlockedWords('rape')).toBe(true)
    expect(containsBlockedWords('you deserve rape')).toBe(true)
    expect(containsBlockedWords('nice grape, bad cockpit')).toBe(false)
    expect(isCharacterNameAllowed('Peacock')).toBe(true)
    expect(isCharacterNameAllowed('Cockhead')).toBe(false)
    expect(isCharacterNameAllowed('Grapefuck')).toBe(false)
  })

  it('catches a stem next to an allowed word, because tokens are screened first', () => {
    // Folding deletes spaces, so the whole string "grape and rape" becomes
    // "grapeandrape", where the second hit sits inside the allowed word
    // "drape" and would be shielded. Screening each token first is what keeps
    // this a hit.
    expect(containsBlockedWords('grape and rape')).toBe(true)
    expect(containsBlockedWords('grape or rape')).toBe(true)
  })

  it('still catches a stem split across spaces', () => {
    for (const text of ['f u c k', 'ni gger', 'c ock', 'ra pe', 'g rape']) {
      expect(containsBlockedWords(text), text).toBe(true)
    }
  })

  it('documents the one evasion the shield costs', () => {
    // The residual weakness is narrow: a stem split across a space whose
    // joined form lands inside an allowed word. "gr ape" joins to "grape",
    // which is allowlisted, so it is shielded in the whole-string pass and
    // neither token carries a stem on its own.
    //
    // Closing it means dropping the allowlist and rejecting Peacock and Grape
    // again. This file's contract is that a miss is the cheaper error than a
    // false positive on a name, so this stays a known miss — and it is what
    // the report queue is for.
    expect(containsBlockedWords('gr ape')).toBe(false)
  })

  it('folds diacritics, which used to walk straight through the filter', () => {
    // The fold dropped accented letters as "not a letter", so fück became fck
    // and matched nothing.
    expect(normalizeForFilter('fück')).toBe('fuck')
    expect(containsBlockedWords('go fück yourself')).toBe(true)
    expect(containsBlockedWords('ní̈gger')).toBe(true)
    expect(isCharacterNameAllowed('Shítlord')).toBe(false)
  })
})
