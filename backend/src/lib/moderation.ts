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

const LEET: Record<string, string> = {
  '0': 'o', '1': 'i', '!': 'i', '3': 'e', '4': 'a', '@': 'a', '5': 's', '$': 's', '7': 't', '8': 'b', '|': 'l',
}

export function normalizeForFilter(input: string): string {
  const mapped = input
    .toLowerCase()
    .split('')
    .map((ch) => LEET[ch] ?? ch)
    .join('')
  // strip everything that is not a letter so "f.u.c.k" and "f_u_c_k" collapse
  return mapped.replace(/[^a-z]/g, '')
}

/** True when the text contains a blocked stem after leet/punctuation folding. */
export function containsBlockedWords(text: string): boolean {
  if (!text) return false
  const norm = normalizeForFilter(text)
  if (!norm) return false
  // collapse any run of repeated letters to one ("fuuuck" → "fuck");
  // check both forms so stems with real double letters ("asshole") still match.
  const collapsed = norm.replace(/(.)\1+/g, '$1')
  return BLOCKED_STEMS.some((stem) => norm.includes(stem) || collapsed.includes(stem))
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
