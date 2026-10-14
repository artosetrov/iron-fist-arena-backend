/**
 * Content moderation helpers (AUDIT-2026-10-13 Sprint 4 / App Store 1.2).
 *
 * `containsBlockedWords` is a deliberately simple substring/leet filter for
 * character names and direct messages. It is not a classifier; it catches
 * the obvious cases so the game is not shipping unfiltered UGC, and the
 * report queue (user_reports) handles the rest.
 *
 * Keep the list short and high-precision — false positives on names are
 * worse than misses (players cannot rename for free).
 */

const BLOCKED_STEMS = [
  // profanity
  'fuck', 'shit', 'cunt', 'bitch', 'asshole', 'dick', 'cock', 'pussy', 'whore', 'slut',
  'motherfuck', 'bastard', 'faggot', 'retard',
  // slurs / hate (stems)
  'nigger', 'nigga', 'kike', 'spic', 'chink', 'tranny', 'wetback', 'raghead',
  // sexual / minors
  'rape', 'pedo', 'cp4', 'loli',
  // extremist
  'hitler', 'nazi', 'kkk',
]

// Separate list for names only: generic words we don't want as a player name.
const BLOCKED_NAME_STEMS = ['admin', 'moderator', 'hexbound', 'support', 'official', 'gamemaster']

/**
 * Ordinary words that contain a blocked stem.
 *
 * The header above says false positives on names are worse than misses, and
 * substring matching on `cock`, `dick` and `rape` breaks that promise: it
 * rejected Peacock, Cockpit, Cockatrice, Woodcock, Shuttlecock, Hitchcock,
 * Dickens, Dickinson, Grape, Grapeshot and Scunthorpe — most of them plausible
 * names in a fantasy RPG — and refused any message containing them. A stem
 * that falls inside one of these is ignored.
 *
 * Shortening the stems instead is not an option: `cock` cannot be made
 * shorter, and dropping it entirely is a bigger miss than this list is a
 * maintenance cost. Add to this list whenever a stem is added above.
 */
const ALLOWED_WORDS = [
  // cock
  'cockpit', 'cocktail', 'cockatrice', 'cockroach', 'peacock', 'woodcock',
  'shuttlecock', 'hitchcock', 'weathercock', 'cockle',
  // dick
  'dickens', 'dickinson', 'dicker',
  // rape
  'grape', 'grapes', 'grapeshot', 'grapevine', 'drape', 'drapes', 'scrape',
  'scraper', 'trapeze', 'rapeseed',
  // cunt
  'scunthorpe', 'countess',
  // pussy / puss
  'pussycat', 'pussyfoot', 'octopus',
  // spic
  'spice', 'spices', 'spicy', 'suspicion', 'suspicious', 'conspicuous', 'auspicious',
  'despicable',
  // chink
  'chinkapin',
  // shit
  'shiitake', 'shitake',
  // slut
  'sluice',
  // nazi / kkk have no innocent English host words worth listing.
]

const LEET: Record<string, string> = {
  '0': 'o', '1': 'i', '!': 'i', '3': 'e', '4': 'a', '@': 'a', '5': 's', '$': 's', '7': 't', '8': 'b', '|': 'l',
}

export function normalizeForFilter(input: string): string {
  const mapped = input
    .toLowerCase()
    // Decompose accents and drop the combining marks. Without this the fold
    // strips the whole accented letter as "not a letter", so "fück" became
    // "fck" and matched nothing — the filter passed the word it exists to
    // catch while rejecting "Peacock".
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .split('')
    .map((ch) => LEET[ch] ?? ch)
    .join('')
  // strip everything that is not a letter so "f.u.c.k" and "f_u_c_k" collapse
  return mapped.replace(/[^a-z]/g, '')
}

/** Collapse runs of a repeated letter: "fuuuck" → "fuck", "woodcock" → "wodcock". */
function collapseRuns(folded: string): string {
  return folded.replace(/(.)\1+/g, '$1')
}

// The shield lists are built once, in the two forms the haystack comes in.
// Both sides of every comparison have to go through the same transform: the
// first version of this fix folded the allowed words but compared them against
// the COLLAPSED haystack, so "woodcock" collapsed to "wodcock", the folded
// shield "woodcock" was not found in it, and Woodcock was rejected anyway.
const SHIELDS_FOLDED = ALLOWED_WORDS.map(normalizeForFilter)
const SHIELDS_COLLAPSED = SHIELDS_FOLDED.map(collapseRuns)

/**
 * True when `stem` occurs in `haystack` somewhere that is not inside one of
 * `shields` — words we know are innocent.
 */
function hasUnshieldedStem(haystack: string, stem: string, shields: string[]): boolean {
  let at = haystack.indexOf(stem)

  while (at !== -1) {
    const shielded = shields.some((word) => {
      if (word.length <= stem.length) return false

      let wordAt = haystack.indexOf(word)
      while (wordAt !== -1) {
        // The stem sits entirely inside this innocent word.
        if (at >= wordAt && at + stem.length <= wordAt + word.length) return true
        wordAt = haystack.indexOf(word, wordAt + 1)
      }
      return false
    })

    if (!shielded) return true
    at = haystack.indexOf(stem, at + 1)
  }

  return false
}

function haystackHasStem(folded: string): boolean {
  if (!folded) return false
  const collapsed = collapseRuns(folded)
  return BLOCKED_STEMS.some(
    (stem) =>
      hasUnshieldedStem(folded, stem, SHIELDS_FOLDED) ||
      hasUnshieldedStem(collapsed, stem, SHIELDS_COLLAPSED),
  )
}

/**
 * True when the text contains a blocked stem after leet/punctuation folding.
 *
 * Screened token by token FIRST, because the fold deletes spaces and that
 * invents words: "and rape" folds to "andrape", which contains the allowed
 * word "drape", so a whole-string-only check shielded a real hit. Splitting on
 * whitespace keeps the boundaries the player actually typed.
 *
 * The whole-string pass still runs, to catch a stem spread across spaces
 * ("f u c k", "ni gger"). It inherits the phantom-word weakness by
 * construction — a stem whose preceding characters happen to complete an
 * allowed word ("grape and rape") is missed. That is a miss, not a false
 * positive, and this file's contract is that misses are the cheaper error.
 */
export function containsBlockedWords(text: string): boolean {
  if (!text) return false

  for (const token of text.split(/\s+/)) {
    if (haystackHasStem(normalizeForFilter(token))) return true
  }

  return haystackHasStem(normalizeForFilter(text))
}

/** Names: profanity + impersonation words. */
export function isCharacterNameAllowed(name: string): boolean {
  if (containsBlockedWords(name)) return false
  const norm = normalizeForFilter(name)
  return !BLOCKED_NAME_STEMS.some((stem) => norm.includes(stem))
}

export const REPORT_CATEGORIES = [
  'harassment',
  'hate',
  'spam',
  'cheating',
  'inappropriate_name',
  'other',
] as const
export type ReportCategory = (typeof REPORT_CATEGORIES)[number]

export const REPORT_CONTEXTS = ['profile', 'message', 'challenge', 'leaderboard'] as const
export type ReportContext = (typeof REPORT_CONTEXTS)[number]
