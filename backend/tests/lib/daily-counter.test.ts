/**
 * W3.D4 — Lazy-reset daily counter helpers.
 *
 * Tests the pure date-comparison helpers used by stamina refills and
 * dungeon training XP DR. No DB, no mocks — just Date objects.
 */
import { describe, it, expect } from 'vitest';
import {
  isDifferentUtcDay,
  currentDailyValue,
  incrementDaily,
} from '../../src/lib/game/daily-counter';

describe('isDifferentUtcDay (W3.D4)', () => {
  it('returns true when stored date is null', () => {
    expect(isDifferentUtcDay(null, new Date())).toBe(true);
  });

  it('returns true when stored date is undefined', () => {
    expect(isDifferentUtcDay(undefined, new Date())).toBe(true);
  });

  it('returns false when both dates are the same UTC day', () => {
    const a = new Date(Date.UTC(2026, 3, 10, 1, 0, 0));
    const b = new Date(Date.UTC(2026, 3, 10, 23, 59, 59));
    expect(isDifferentUtcDay(a, b)).toBe(false);
  });

  it('returns true across midnight UTC boundary', () => {
    const a = new Date(Date.UTC(2026, 3, 10, 23, 59, 59));
    const b = new Date(Date.UTC(2026, 3, 11, 0, 0, 1));
    expect(isDifferentUtcDay(a, b)).toBe(true);
  });

  it('returns true across month boundary', () => {
    const a = new Date(Date.UTC(2026, 2, 31, 23, 0, 0));
    const b = new Date(Date.UTC(2026, 3, 1, 0, 30, 0));
    expect(isDifferentUtcDay(a, b)).toBe(true);
  });

  it('returns true across year boundary', () => {
    const a = new Date(Date.UTC(2025, 11, 31, 23, 59, 59));
    const b = new Date(Date.UTC(2026, 0, 1, 0, 0, 0));
    expect(isDifferentUtcDay(a, b)).toBe(true);
  });

  it('ignores local timezone — compares in UTC only', () => {
    // 23:00 UTC on day X and 01:00 UTC on day X+1 are different days
    // regardless of the user's local TZ
    const a = new Date(Date.UTC(2026, 3, 10, 23, 0, 0));
    const b = new Date(Date.UTC(2026, 3, 11, 1, 0, 0));
    expect(isDifferentUtcDay(a, b)).toBe(true);
  });
});

describe('currentDailyValue (W3.D4)', () => {
  const today = new Date(Date.UTC(2026, 3, 10, 12, 0, 0));

  it('returns 0 when storedDate is null (new account / first use)', () => {
    expect(currentDailyValue(42, null, today)).toBe(0);
  });

  it('returns 0 when storedDate is from a previous day (lazy reset)', () => {
    const yesterday = new Date(Date.UTC(2026, 3, 9, 23, 0, 0));
    expect(currentDailyValue(42, yesterday, today)).toBe(0);
  });

  it('returns the stored value when storedDate is the same day', () => {
    const earlierToday = new Date(Date.UTC(2026, 3, 10, 3, 0, 0));
    expect(currentDailyValue(42, earlierToday, today)).toBe(42);
  });

  it('returns 0 for zero-valued stored counter on same day', () => {
    const earlierToday = new Date(Date.UTC(2026, 3, 10, 3, 0, 0));
    expect(currentDailyValue(0, earlierToday, today)).toBe(0);
  });
});

describe('incrementDaily (W3.D4)', () => {
  const today = new Date(Date.UTC(2026, 3, 10, 12, 0, 0));

  it('starts at 1 when there is no prior date (fresh counter)', () => {
    const { nextValue, nextDate } = incrementDaily(0, null, today);
    expect(nextValue).toBe(1);
    expect(nextDate).toBe(today);
  });

  it('resets and then increments when the prior date was yesterday', () => {
    const yesterday = new Date(Date.UTC(2026, 3, 9, 23, 0, 0));
    // Stored value was 42 yesterday — treated as 0 today, then +1 = 1
    const { nextValue } = incrementDaily(42, yesterday, today);
    expect(nextValue).toBe(1);
  });

  it('increments the existing same-day counter', () => {
    const earlierToday = new Date(Date.UTC(2026, 3, 10, 3, 0, 0));
    const { nextValue } = incrementDaily(5, earlierToday, today);
    expect(nextValue).toBe(6);
  });

  it('supports custom delta', () => {
    const earlierToday = new Date(Date.UTC(2026, 3, 10, 3, 0, 0));
    const { nextValue } = incrementDaily(5, earlierToday, today, 3);
    expect(nextValue).toBe(8);
  });

  it('always sets nextDate to now (refreshes the date stamp)', () => {
    const earlierToday = new Date(Date.UTC(2026, 3, 10, 3, 0, 0));
    const { nextDate } = incrementDaily(5, earlierToday, today);
    expect(nextDate).toBe(today);
  });
});
