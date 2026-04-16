---
title: Block 046 — backend feature flags progression and runtime cleanup
category: audit
tags: [audit, backend, feature-flags, progression, combat, push, tests]
sources:
  - backend/src/lib/game/feature-flags.ts
  - backend/src/lib/game/progression.ts
  - backend/src/lib/game/combat-simulator.ts
  - backend/src/lib/game/combat.ts
  - backend/src/lib/push/send.ts
  - backend/tests/lib/feature-flags.test.ts
  - backend/tests/lib/progression.test.ts
updated: 2026-04-15
status: Fixed
---

# Block 046 — backend feature flags progression and runtime cleanup

## Scope

- `backend/src/lib/game/feature-flags.ts`
- `backend/src/lib/game/progression.ts`
- `backend/src/lib/game/combat-simulator.ts`
- `backend/src/lib/game/combat.ts`
- `backend/src/lib/push/send.ts`
- `backend/tests/lib/feature-flags.test.ts`
- `backend/tests/lib/progression.test.ts`

## Why this block

This pass started from warning-heavy helper files, but one of them contained a live product bug:

1. feature flags had an `environment` column in Prisma and a full admin UI for `all / production / staging / development`, but backend runtime ignored that field completely, so a production-only or staging-only flag could leak into the wrong environment.

The rest of the block was conservative cleanup: tighten helper contracts, remove dead combat internals that were only generating noise, and make push broadcast filtering safe under Prisma’s typed query surface.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[design-principles]]
- [[bug-patterns]]
- [[interactive-combat]]

## File notes

### `backend/src/lib/game/feature-flags.ts`

- **Zone:** backend / live config / flags
- **Purpose:** resolves active feature flags for a given user and optional character
- **Depends on:** Prisma feature flag table and `/api/flags`
- **Used by:** game init and dedicated flags endpoint
- **Problems found:**
  - `environment` was stored and editable but never enforced at runtime
  - `value` and `targeting` still relied on loose `any`
  - min/max targeting checks used truthy checks instead of explicit `undefined` handling
- **What was fixed:**
  - runtime now maps environments explicitly (`production`, `staging`, `development`) and respects `all`
  - Vercel preview now resolves as `staging`, so preview flags stop leaking into production/dev semantics
  - targeting parsing is now explicit and typed
  - resolution output uses a typed JSON value contract instead of `any`
- **Status:** Fixed

### `backend/src/lib/game/progression.ts`

- **Zone:** backend / progression
- **Purpose:** level-up and prestige helpers shared across reward flows
- **Depends on:** live config, achievements, milestones
- **Used by:** reward grant flows across PvP, dungeons, mail, achievements, and more
- **Problems found:** `applyLevelUp` still exposed a `Function`-typed transaction contract and one broad unknown-error log path
- **What was fixed:** narrowed the transaction surface to the exact `character.findUnique/update` contract and replaced the unsafe catch type with `unknown`
- **Status:** Fixed

### `backend/src/lib/game/combat-simulator.ts`

- **Zone:** backend / balance tooling
- **Purpose:** bulk combat simulation for admin/balance analysis
- **Depends on:** live combat engine and item-balance derived stats
- **Problems found:** stale unused parameters in the per-combat analysis helper
- **What was fixed:** removed dead arguments so the file reflects the metrics it actually computes
- **Status:** Fixed

### `backend/src/lib/game/combat.ts`

- **Zone:** backend / combat core
- **Purpose:** deterministic turn-based combat runtime and single-strike interactive resolution
- **Depends on:** balance config, live combat config, skills, passives
- **Used by:** PvP, dungeons, tutorial combat, balance simulation, interactive combat
- **Problems found:** dead import/state noise (`COMBAT`, cached config write, unused stance-switch local, needless mutable hp locals)
- **What was fixed:** removed dead internals without changing the combat pipeline
- **Status:** Fixed

### `backend/src/lib/push/send.ts`

- **Zone:** backend / notifications
- **Purpose:** sends APNS pushes directly or through user broadcast selection
- **Depends on:** Prisma push tokens/logs, APNS env vars, `fetch`
- **Used by:** push notification flows and campaign/broadcast helpers
- **Problems found:**
  - broadcast filter surface still relied on `any`
  - level filter construction broke under Prisma’s typed build contract
  - APNS error parsing and send-loop catches still used `any`
- **What was fixed:**
  - broadcast filter now uses typed Prisma filters and canonical `CharacterClass`
  - min/max level filters are built safely without invalid spread on Prisma unions
  - payload/error parsing now uses `unknown` and explicit helpers instead of `any`
- **Needs review:** Android/FCM path still intentionally returns `false` because real FCM delivery is not implemented here
- **Status:** Fixed

### `backend/tests/lib/feature-flags.test.ts`

- **Zone:** backend tests / live config
- **Purpose:** locks down environment-aware feature-flag resolution
- **What it covers now:**
  - Vercel preview resolves as `staging`
  - environment-mismatched flags fall back to typed defaults
  - user/level targeting still gates flag exposure safely
- **Status:** Fixed

### `backend/tests/lib/progression.test.ts`

- **Zone:** backend tests / progression
- **Purpose:** protects core level-up math
- **What it covers now:**
  - multiple level-ups in a single XP dump
  - prestige stat bonus application from live config values
- **Status:** Fixed

## Problems found

1. **Feature flag environment scoping was not enforced**
   - Risk: a flag marked `production` or `staging` in admin could resolve in the wrong runtime environment, making rollout controls untrustworthy.
   - Fix: added explicit environment resolution and environment matching before flag evaluation.

2. **Feature flag targeting contract was weakly typed**
   - Risk: malformed targeting JSON could silently behave like “no targeting” or be evaluated inconsistently.
   - Fix: parsed targeting explicitly and removed the `any` surface.

3. **Push broadcast filter was not actually safe under Prisma typing**
   - Risk: refactors around notification targeting could keep breaking in build-only paths instead of during local lint.
   - Fix: replaced `any` filter construction with typed Prisma filters and enum-safe class selection.

4. **Combat helper files still had dead state that obscured real issues**
   - Risk: warning noise makes it harder to spot live combat regressions when they do appear.
   - Fix: removed unused parameters/imports/locals while leaving runtime behavior unchanged.

## Verification

- targeted backend `eslint`:
  - `src/lib/game/feature-flags.ts`
  - `src/lib/game/progression.ts`
  - `src/lib/game/combat-simulator.ts`
  - `src/lib/game/combat.ts`
  - `src/lib/push/send.ts`
  - `tests/lib/feature-flags.test.ts`
  - `tests/lib/progression.test.ts`
- targeted backend `vitest`:
  - `tests/lib/feature-flags.test.ts`
  - `tests/lib/progression.test.ts`
- full backend `npx vitest run` (`39/39` files, `279/279` tests)
- `npm run build` in `backend/`
- `git diff --check`

## Follow-up

- `push/send.ts` still needs a real FCM implementation before Android push can be treated as production-ready
- the next warning-heavy backend slice is now clearly `dungeon.ts`, `item-balance.ts`, and `live-config.ts`
- combat core is cleaner, but deeper architectural changes to combat helpers should wait until the remaining runtime files in this layer are audited file by file
