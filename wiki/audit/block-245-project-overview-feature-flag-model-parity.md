---
title: Audit Block 245 — Project Overview Feature Flag Model Parity
category: audit
tags: [audit, docs, source-of-truth, feature-flags]
sources:
  - docs/01_source_of_truth/PROJECT_OVERVIEW.md
  - admin/src/lib/feature-flags.ts
  - admin/src/actions/feature-flags.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 245 — Project Overview Feature Flag Model Parity

## Scope

- `docs/01_source_of_truth/PROJECT_OVERVIEW.md`
- adjacent live feature-flag model files

## Why this block

Even after the bigger liveops/admin cleanup, `PROJECT_OVERVIEW.md` still reduced `FeatureFlag` to “A/B test toggles, segments”.

That was no longer a good summary of the live model:

- the current repo supports boolean, percentage, segment, and JSON flag types
- targeting includes environment, min/max level, class, explicit user IDs, and tags
- but it still should not read like a full experimentation platform either

## Fix applied

- rewrote the `FeatureFlag` model summary to the live, narrower truth:
  - environment-scoped rollout rules
  - percentage / segment support
  - targeted overrides

## Result

`PROJECT_OVERVIEW.md` no longer pulls the feature-flag model backward into “A/B testing” shorthand when the actual repo is a rollout/targeting system with broader flag types and narrower experimentation semantics.

## Verification

- live file review of `admin/src/lib/feature-flags.ts`
- live file review of `admin/src/actions/feature-flags.ts`
- `git diff --check`
