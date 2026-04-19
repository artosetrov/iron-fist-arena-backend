---
title: Audit Block 210 — Combat Telemetry Doc Proposal Boundary Sync
category: audit
tags: [audit, docs, combat, analytics, telemetry]
sources:
  - docs/features/combat/COMBAT_MECHANIC_SPEC.md
  - docs/features/combat/INTERACTIVE_COMBAT_PLAN.md
  - backend/src/lib/analytics.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 210 — Combat Telemetry Doc Proposal Boundary Sync

## Scope

- `docs/features/combat/COMBAT_MECHANIC_SPEC.md`
- `docs/features/combat/INTERACTIVE_COMBAT_PLAN.md`
- `backend/src/lib/analytics.ts`

## Why this block

The combat docs still described telemetry as if it were already wired into an “existing analytics table” with live event names.

But the current project reality is narrower:

- `backend/src/lib/analytics.ts` exposes a small provider-agnostic core contract
- the proposed interactive-combat telemetry events are not yet part of that live contract

## Fix applied

### `docs/features/combat/COMBAT_MECHANIC_SPEC.md`

- reframed the telemetry section as a proposed extension to the analytics contract
- removed the claim that these events already reuse an existing analytics table

### `docs/features/combat/INTERACTIVE_COMBAT_PLAN.md`

- changed the balance-veto wording so `interactive_combat_outcome` is described as future instrumentation work, not a live event already emitted by the repo today

## Result

Combat telemetry docs now say the honest thing:

- the events are a proposal
- wiring them requires explicit analytics work
- the current backend analytics contract does not already provide them

## Verification

- compared both combat docs against `backend/src/lib/analytics.ts`
- `git diff --check`

The proposal boundary is now explicit instead of implied.
