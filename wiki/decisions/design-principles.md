---
title: Core Design Principles
category: decisions
tags: [design, ux, architecture, rules]
sources: [docs/retro/*, docs/09_rules_and_guidelines/UI_UX_PRINCIPLES.md]
updated: 2026-04-14
---

# Core Design Principles

Extracted from 23 retros (2026-03-21 to 2026-04-13) and UI/UX principles doc.

## UX Principles

- **3-Second Rule** — player understands goal + action + outcome in ≤3 seconds
- **One Goal Per Screen** — single primary CTA, everything else secondary
- **No Dead Ends** — every state has a clear next action
- **Short Sessions** — target 2–5 minutes per session (single combat = 1–2 min)
- **Monetization = Acceleration only** — never hard-block fair play

## Touch & Typography

- Touch targets ≥ 48pt, primary buttons ≥ 56pt
- Minimum font: 11px (badges), body ≥ 14px, headers ≥ 18px
- See [[design-system]] for full token reference

## Architecture Principles (from retros)

### Server-Authoritative
Client NEVER calculates combat results, rewards, ratings, or economy values. Client validates for instant UX feedback, server is final authority.

### Single Source of Truth
Balance constants auto-generated from `balance.ts` → docs. Never maintain parallel copies manually. CI guard (`check_ios_backend_drift.sh`) catches iOS ↔ backend constant drift. See [[why-auto-generated-balance-docs]].

### Guard Patterns
All async network calls need guard flags set **BEFORE** `await` to prevent double-tap/race conditions. Found 3× in retros: arena fight, shop buy, quest claim (2026-04-12).

### Root-Level Overlays
UI state that must survive screen transitions (loading, ceremony, daily login) mounts at `HexboundApp.swift` root, NOT inside source screens. Source screens unmount during `currentScreen` cross-fade. Learned from BUG-53 (Daily Login) and BUG-08 (Hero Forge).

### ViewModel Cleanup
Loading/submitting flags require `defer { flag = false }`. View struct unmount not guaranteed — SwiftUI has no deinit. Never rely on view unmount for cleanup.

### Atomic Commits
Large features split by logical domain (feat(pvp), feat(tutorial)), not files-per-commit. Mega-commits (166+ files) hide individual failures in bisect. Learned 2026-04-08.

### Scanners Enforce Rules
Rules in docs don't prevent mistakes. Must be automated via grep-checks and CI guards. Example: `character.gold → user.gold` migration needed 7 fix commits because scanner didn't detect the pattern (2026-04-09).

## See Also

- [[design-system]]
- [[economy]]
- [[bug-patterns]]
