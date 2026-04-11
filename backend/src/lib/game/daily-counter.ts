// =============================================================================
// daily-counter.ts — Shared lazy-reset counter helpers (W3.D4)
// =============================================================================
//
// Several per-character counters reset at the start of each calendar day:
//   - dungeon_clears_today       (training/dungeon XP DR)
//   - stamina_refills_today      (stamina refill DR)
//   - first_win_today            (pre-existing)
//   - stat_purchases_today       (pre-existing)
//
// Instead of a scheduled job, we reset lazily: whenever we read/write a
// counter, we check its companion `*_date` column against today. If the date
// differs, we treat the counter as 0 and update the date.
//
// All helpers here are pure — they take "now" as a Date so tests can stub it.

/**
 * Return true when `stored` is not the same UTC calendar day as `now`.
 * Null/undefined dates are treated as "stale" (counter should start fresh).
 */
export function isDifferentUtcDay(stored: Date | null | undefined, now: Date): boolean {
  if (!stored) return true;
  return (
    stored.getUTCFullYear() !== now.getUTCFullYear() ||
    stored.getUTCMonth() !== now.getUTCMonth() ||
    stored.getUTCDate() !== now.getUTCDate()
  );
}

/**
 * Compute the effective counter value with lazy reset applied.
 *
 * @param stored       The value currently stored in DB.
 * @param storedDate   The companion *_date column currently in DB.
 * @param now          Current timestamp (passed in for testability).
 * @returns            `0` if the date is stale (new day), otherwise `stored`.
 */
export function currentDailyValue(
  stored: number,
  storedDate: Date | null | undefined,
  now: Date,
): number {
  return isDifferentUtcDay(storedDate, now) ? 0 : stored;
}

/**
 * Compute the next value + date for a counter that is being incremented.
 *
 * Use this before writing to DB to keep the reset logic in one place:
 *
 *   const { nextValue, nextDate } = incrementDaily(
 *     character.dungeonClearsToday,
 *     character.dungeonClearsDate,
 *     now,
 *   );
 */
export function incrementDaily(
  stored: number,
  storedDate: Date | null | undefined,
  now: Date,
  delta = 1,
): { nextValue: number; nextDate: Date } {
  const base = currentDailyValue(stored, storedDate, now);
  return { nextValue: base + delta, nextDate: now };
}
