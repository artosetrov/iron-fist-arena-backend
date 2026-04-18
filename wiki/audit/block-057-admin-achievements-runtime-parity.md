---
title: Block 057 — admin achievements runtime parity
category: audit
tags: [audit, admin, achievements, contracts, progression]
sources:
  - admin/src/lib/achievement-definitions.ts
  - admin/src/actions/achievement-definitions.ts
  - admin/src/app/(dashboard)/achievements/achievements-client.tsx
  - backend/src/lib/game/achievement-catalog.ts
  - backend/src/lib/game/achievement-claims.ts
updated: 2026-04-17
status: Fixed
---

# Block 057 — admin achievements runtime parity

## Scope

- `admin/src/lib/achievement-definitions.ts`
- `admin/src/actions/achievement-definitions.ts`
- `admin/src/app/(dashboard)/achievements/achievements-client.tsx`
- `backend/src/lib/game/achievement-catalog.ts`
- `backend/src/lib/game/achievement-claims.ts`

## Why this block

The admin achievements surface had drifted in two directions at once: its server actions accepted much weaker payloads than the live runtime should trust, and its seed still used the pre-fix `rank_diamond` / `rank_grandmaster` thresholds even though the backend catalog had already been corrected to `3000 / 4250`.

On top of that, the admin editor still exposed reward editing through a generic form flow even though the live achievement claim path at the time only granted `gold`, `gems`, and `xp`.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[achievements]]
- [[bug-patterns]]
- [[block-045-backend-tutorial-achievement-and-weekly-contracts]]

## File notes

### `admin/src/lib/achievement-definitions.ts`

- **Zone:** admin / shared achievement helpers
- **Purpose:** canonical validation and normalization for achievement-definition writes
- **What was added:**
  - normalized `key` handling
  - strict category parsing
  - originally introduced a live-safe reward type gate while runtime was still currency-only
  - later widened again in [[block-181-admin-achievement-cosmetic-authoring-parity]] to support live `title/frame` authoring with required `rewardId`
  - positive target/reward validation and non-negative sort-order validation
- **Status:** Fixed

### `admin/src/actions/achievement-definitions.ts`

- **Zone:** admin / achievement-definition actions
- **Purpose:** list, create, update, delete, and seed achievement definitions
- **Problems found:**
  - accepted raw payloads without validating key/category/target/reward ranges
  - wrote weak `details: data as never` audit payloads
  - seeded stale ranking thresholds for Diamond and Grandmaster
- **What was fixed:**
  - routed create/update/seed through the shared sanitizer
  - added duplicate-key validation on create
  - replaced weak audit payloads with structured JSON details
  - corrected seed thresholds to `3000` and `4250`
  - added seed audit logging
- **Status:** Fixed

### `admin/src/app/(dashboard)/achievements/achievements-client.tsx`

- **Zone:** admin / achievements UI
- **Purpose:** manage achievement definitions and inspect aggregate completion stats
- **Problems found:**
  - lived on `alert()` + console logging for operator feedback
  - carried warning noise from unused imports / transition state
  - still exposed form fields and reward semantics that were wider than the live claim runtime
- **What was fixed:**
  - moved feedback onto toast-based success/error reporting
  - removed dead imports and unused transition state
  - originally aligned reward type choices to the then-live-safe set while runtime was still currency-only
  - later widened again in [[block-181-admin-achievement-cosmetic-authoring-parity]] so cosmetic `title/frame` rewards and `rewardId` authoring match the live runtime
- **Status:** Fixed

### `backend/src/lib/game/achievement-catalog.ts`

- **Zone:** backend / runtime reference
- **Purpose:** source of truth for achievement targets and catalog reward metadata
- **Why it mattered here:**
  - it already contained the corrected `rank_diamond` and `rank_grandmaster` thresholds, which the admin seed had fallen behind
- **Status:** OK

### `backend/src/lib/game/achievement-claims.ts`

- **Zone:** backend / runtime reference
- **Purpose:** live claim-time reward grant logic for achievements
- **Why it mattered here:**
  - this block originally aligned admin authoring to the then-live-safe currency-only claim path
  - cosmetic achievement runtime support was added later in [[block-180-backend-achievement-cosmetic-claim-runtime-parity]]
- **Status:** Fixed

## Problems found

1. **Admin achievement writes were weaker than the live contract**
   - Risk: invalid keys, categories, targets, or reward values could be persisted from the admin surface.
   - Fix: introduced one shared sanitizer and routed create/update/seed through it.

2. **Achievement seed data had stale ranking thresholds**
   - Risk: reseeding definitions could silently reintroduce the exact Diamond/Grandmaster threshold bug that the backend catalog had already fixed.
   - Fix: updated the admin seed to `3000` and `4250`.

3. **Admin UI exposed reward semantics wider than live claims**
   - Risk: operators could configure definitions that the runtime would later reject as misconfigured.
   - Fix: aligned the UI to the currently supported live claim reward types and removed the unused `rewardId` path.

4. **Legacy catalog/runtime mismatch existed for `title/frame`**
   - Risk: the broader catalog could still represent reward types that the live claim helper did not grant.
   - Fix in this block: contained the problem at the admin authoring layer and preserved compatibility for already-stored legacy rows during updates.
   - Later follow-up: resolved end to end in [[block-180-backend-achievement-cosmetic-claim-runtime-parity]].

## Verification

- targeted admin `eslint`:
  - `src/lib/achievement-definitions.ts`
  - `src/actions/achievement-definitions.ts`
  - `src/app/(dashboard)/achievements/achievements-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`

## Follow-up

- cosmetic achievement runtime support was later implemented in [[block-180-backend-achievement-cosmetic-claim-runtime-parity]]
- admin authoring was later widened back to the full live reward surface in [[block-181-admin-achievement-cosmetic-authoring-parity]]
- the broader remaining admin warning-heavy slice is now concentrated in `design-system`, `appearances`, and a few media-heavy editor surfaces
