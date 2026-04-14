---
title: Bug Patterns & Lessons
category: decisions
tags: [bugs, patterns, lessons, retro]
sources: [docs/retro/*, docs/09_rules_and_guidelines/ERROR_CATALOG.md]
updated: 2026-04-14
---

# Bug Patterns & Lessons

Recurring bug patterns extracted from 23 retros. Each pattern appeared 2+ times.

## CodingKeys Double-Conversion

**Pattern:** Explicit `CodingKeys` with snake_case raw values + `APIClient.convertFromSnakeCase` = double conversion → silent nil.

**Occurrences:** 2026-03-24 (socialStatus nil → no Guild Hall badge), 2026-04-13 (talents + interactive combat).

**Rule:** Backend sends camelCase (default Next.js) → do NOT add CodingKeys. Only add CodingKeys for Swift keywords (`case characterClass = "class"`).

## TOCTOU Race Conditions

**Pattern:** Read resource → check → write without transaction lock. Parallel requests pass the check simultaneously.

**Occurrences:** 2026-03-24 (PvP stamina — free fights via parallel requests), 2026-04-12 (arena/shop/claim double-tap).

**Rule:** All purchases/mutations use `$transaction` with row lock. Guard flags set BEFORE first `await`.

## Silent try? Failures

**Pattern:** `try?` swallows the error → decode failure invisible → feature silently broken.

**Occurrences:** 2026-03-30 (mail messages), multiple inventory decode issues.

**Rule:** Use `do/catch` with error logging. `try?` only for genuinely optional operations.

## Junk Files in Repository

**Pattern:** `.bak`, `.backup`, `" 2.swift"` files committed via `git add -A`.

**Occurrences:** 2026-04-03 (Xcode backup), 2026-04-06 (conflict-save duplicates).

**Rule:** Never `git add -A`. Add specific files. `.gitignore` patterns for `*.bak`, `*.backup`, `*" "*`.

## iOS ↔ Backend Constant Drift

**Pattern:** Hardcoded constants on iOS (`freePvpPerDay`, `maxStamina`) diverge from `balance.ts` after rebalance.

**Occurrences:** 2026-04-10 (CRIT: free PvP count wrong on iOS after balance change).

**Rule:** CI guard `check_ios_backend_drift.sh`. iOS reads constants from server config, not hardcoded.

## Overlay Unmount During Transition

**Pattern:** Loading/ceremony overlay mounted inside a screen that transitions away → overlay disappears → user sees black.

**Occurrences:** BUG-53 (Daily Login), BUG-08 (Hero Forge).

**Rule:** Root-level overlays in `HexboundApp.swift`. See [[design-principles]].

## See Also

- [[design-principles]]
- [[economy]] (race conditions in purchases)
- [[combat]] (server-authoritative rule)
