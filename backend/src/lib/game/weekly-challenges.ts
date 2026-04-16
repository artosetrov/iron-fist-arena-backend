// =============================================================================
// weekly-challenges.ts — Battle Pass weekly challenges (W3.D5 — BAL-06)
// =============================================================================
//
// Every character gets BP_WEEKLY.SLOTS challenges per ISO week, chosen
// deterministically from WEEKLY_CHALLENGE_POOL by seeding a PRNG with the
// ISO-week string. No cron job, no nightly batch — rows materialize lazily
// the first time a player opens the Battle Pass screen for that week.
//
// Why ISO week: stable boundary across timezones (week starts Monday UTC),
// and the label "2026-W15" is stable to show in the UI.
//
// Why deterministic: every player on earth sees the *same* 5 challenges each
// week. This is industry-standard (Fortnite, Valorant, Apex) — it makes the
// meta discussable and streams/guides shareable.
//
// Extensibility:
//   - Pool order is load-bearing (historical rows reference slot_index +
//     goal_type). NEVER reorder the pool — only append. If you need to retire
//     an entry, set its weight to 0 instead of removing it.
//   - To ship a new challenge type, add a QuestType to the Prisma enum first
//     (migration required), then append a pool entry here.

import type { QuestType } from '@prisma/client'
import { BP_WEEKLY } from './balance'

// -----------------------------------------------------------------------------
// Challenge pool
// -----------------------------------------------------------------------------
//
// Each entry defines a kind of challenge and a range of targets the PRNG can
// pick from. Targets are scaled up slightly from dailies so a week of play
// is required — not a single evening — but they remain achievable for the
// median player (reference: ~3-5 sessions/week, ~15 minutes each).
//
// Weights bias the selection probability. Use 10 as the baseline; bump a slot
// up if it's core loop (PvP fights), drop it if it's niche (mining).

export interface WeeklyChallengeTemplate {
  readonly goalType: QuestType
  readonly minTarget: number
  readonly maxTarget: number
  readonly weight: number
  /** Human-readable label for the client. Keep short; iOS renders in a row. */
  readonly label: string
  /** One-line description — use {target} as a placeholder. */
  readonly description: string
}

export const WEEKLY_CHALLENGE_POOL: readonly WeeklyChallengeTemplate[] = [
  {
    goalType: 'pvp_wins',
    minTarget: 10,
    maxTarget: 20,
    weight: 15,
    label: 'Arena Conqueror',
    description: 'Win {target} PvP battles',
  },
  {
    goalType: 'pvp_wins',
    minTarget: 5,
    maxTarget: 10,
    weight: 10,
    label: 'Weekly Duelist',
    description: 'Win {target} PvP battles',
  },
  {
    goalType: 'dungeons_complete',
    minTarget: 15,
    maxTarget: 30,
    weight: 15,
    label: 'Dungeon Crawler',
    description: 'Clear {target} dungeon floors',
  },
  {
    goalType: 'dungeons_complete',
    minTarget: 8,
    maxTarget: 15,
    weight: 10,
    label: 'Deep Diver',
    description: 'Clear {target} dungeon floors',
  },
  {
    goalType: 'gold_spent',
    minTarget: 5000,
    maxTarget: 15000,
    weight: 10,
    label: 'Spendthrift',
    description: 'Spend {target} gold',
  },
  {
    goalType: 'item_upgrade',
    minTarget: 3,
    maxTarget: 8,
    weight: 10,
    label: 'Master Smith',
    description: 'Upgrade {target} items',
  },
  {
    goalType: 'consumable_use',
    minTarget: 10,
    maxTarget: 20,
    weight: 8,
    label: 'Alchemist',
    description: 'Use {target} consumables',
  },
  {
    goalType: 'shell_game_play',
    minTarget: 5,
    maxTarget: 10,
    weight: 6,
    label: 'Lucky Hand',
    description: 'Play Shell Game {target} times',
  },
  {
    goalType: 'gold_mine_collect',
    minTarget: 5,
    maxTarget: 10,
    weight: 6,
    label: 'Prospector',
    description: 'Collect from Gold Mines {target} times',
  },
] as const

// -----------------------------------------------------------------------------
// ISO week helpers
// -----------------------------------------------------------------------------

/**
 * Return the ISO-8601 week key for a given Date (default: now).
 * Format: "YYYY-Www" (zero-padded week, e.g. "2026-W15").
 *
 * Week 1 is the week containing the first Thursday of the year (ISO-8601).
 * This matches Postgres `to_char(..., 'IYYY-"W"IW')` and what the client's
 * `Calendar.Component.weekOfYear` returns with `.iso8601` calendar.
 */
export function isoWeekOf(date: Date = new Date()): string {
  // Copy to UTC so TZ doesn't shift weeks.
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()))
  // Thursday of current ISO week determines the year.
  const dayNum = d.getUTCDay() || 7 // Mon=1..Sun=7
  d.setUTCDate(d.getUTCDate() + 4 - dayNum)
  const isoYear = d.getUTCFullYear()
  const yearStart = new Date(Date.UTC(isoYear, 0, 1))
  const weekNum = Math.ceil(((d.getTime() - yearStart.getTime()) / 86_400_000 + 1) / 7)
  return `${isoYear}-W${String(weekNum).padStart(2, '0')}`
}

// -----------------------------------------------------------------------------
// Deterministic PRNG — mulberry32
// -----------------------------------------------------------------------------
//
// Pure, fast, small-state PRNG. Same seed → same sequence forever.
// Source: https://github.com/bryc/code/blob/master/jshash/PRNGs.md

function mulberry32(seed: number): () => number {
  let a = seed | 0
  return function () {
    a = (a + 0x6d2b79f5) | 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

/**
 * Hash an ISO-week string to a 32-bit seed using FNV-1a.
 * Deterministic across JS engines (no Object.hashCode reliance).
 */
function seedFromIsoWeek(isoWeek: string): number {
  let h = 0x811c9dc5
  for (let i = 0; i < isoWeek.length; i++) {
    h ^= isoWeek.charCodeAt(i)
    h = Math.imul(h, 0x01000193)
  }
  return h >>> 0
}

// -----------------------------------------------------------------------------
// Weighted sampling (without replacement)
// -----------------------------------------------------------------------------

/**
 * Pick N distinct indices from the pool, weighted by `weight`. Uses standard
 * O(pool × N) weighted-reservoir-style sampling: reweight remaining candidates
 * after each pick. Good enough for pool size < 100.
 */
function pickDistinct<T extends { weight: number }>(
  pool: readonly T[],
  n: number,
  rnd: () => number,
): T[] {
  const out: T[] = []
  const remaining = [...pool]

  for (let i = 0; i < n && remaining.length > 0; i++) {
    let total = 0
    for (const r of remaining) total += r.weight
    if (total <= 0) break
    let roll = rnd() * total
    let picked = 0
    for (let j = 0; j < remaining.length; j++) {
      roll -= remaining[j].weight
      if (roll <= 0) {
        picked = j
        break
      }
    }
    out.push(remaining[picked])
    remaining.splice(picked, 1)
  }
  return out
}

// -----------------------------------------------------------------------------
// Public API — build the 5 challenges for a given ISO week
// -----------------------------------------------------------------------------

export interface GeneratedWeeklyChallenge {
  /** 0..SLOTS-1 */
  readonly slotIndex: number
  readonly goalType: QuestType
  readonly goalTarget: number
  readonly bpXpAward: number
  readonly label: string
  readonly description: string
}

interface WeeklyChallengeProgressExecutor {
  $executeRawUnsafe(query: string, ...args: unknown[]): Promise<number>
}

/**
 * Return the canonical 5 challenges for the given ISO week.
 * Pure function — same isoWeek always produces the same output.
 *
 * This is *not* per-player: every player on earth sees the same 5 challenges
 * for "2026-W15". Per-player state lives in the WeeklyChallengeProgress
 * table (progress/claimed), not in this function.
 */
export function buildWeeklyChallenges(isoWeek: string): GeneratedWeeklyChallenge[] {
  const seed = seedFromIsoWeek(isoWeek)
  const rnd = mulberry32(seed)
  const picks = pickDistinct(WEEKLY_CHALLENGE_POOL, BP_WEEKLY.SLOTS, rnd)

  return picks.map((tpl, slotIndex) => {
    // Roll target uniformly in [minTarget, maxTarget], rounded to a nice step.
    const range = tpl.maxTarget - tpl.minTarget
    const roll = Math.floor(rnd() * (range + 1))
    const raw = tpl.minTarget + roll
    const target = niceStep(raw, tpl.minTarget)

    return {
      slotIndex,
      goalType: tpl.goalType,
      goalTarget: target,
      bpXpAward: BP_WEEKLY.XP_PER_CLEAR,
      label: tpl.label,
      description: tpl.description.replace('{target}', String(target)),
    }
  })
}

/**
 * Round to a "nice" step so targets look intentional (10, 15, 20 — not 13).
 * Step size scales with the minimum target.
 */
function niceStep(value: number, min: number): number {
  let step = 1
  if (min >= 1000) step = 500
  else if (min >= 100) step = 50
  else if (min >= 20) step = 5
  else if (min >= 10) step = 2
  else step = 1
  return Math.max(min, Math.round(value / step) * step)
}

// -----------------------------------------------------------------------------
// Progress tracking — called from game endpoints
// -----------------------------------------------------------------------------

/**
 * Atomically increment weekly challenge progress for all slots matching
 * `goalType` in the current ISO week. Mirrors `updateDailyQuestProgress` —
 * single SQL statement, no read-modify-write race.
 *
 * Call this from the same code paths that call `updateDailyQuestProgress`.
 * Weekly rows only exist if the player opened the BP screen this week, which
 * is fine — if they never opened it, there's nothing to progress yet.
 */
export async function updateWeeklyChallengeProgress(
  prisma: WeeklyChallengeProgressExecutor,
  characterId: string,
  goalType: QuestType,
  increment: number = 1,
): Promise<void> {
  const isoWeek = isoWeekOf()

  await prisma.$executeRawUnsafe(
    `UPDATE "weekly_challenge_progress"
     SET "progress" = LEAST("progress" + $1, "goal_target"),
         "completed_at" = CASE
           WHEN "progress" + $1 >= "goal_target" AND "completed_at" IS NULL
             THEN NOW()
           ELSE "completed_at"
         END
     WHERE "character_id" = $2
       AND "iso_week" = $3
       AND "goal_type" = $4::text::"QuestType"
       AND "progress" < "goal_target"
       AND "claimed" = false`,
    increment,
    characterId,
    isoWeek,
    goalType,
  )
}
