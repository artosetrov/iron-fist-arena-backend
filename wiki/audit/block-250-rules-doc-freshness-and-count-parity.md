---
title: Audit Block 250 — Rules Doc Freshness and Count Parity
category: audit
tags: [audit, docs, rules, metadata]
sources:
  - docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md
  - docs/09_rules_and_guidelines/UI_UX_PRINCIPLES.md
updated: 2026-04-20
status: Fixed
---

# Audit Block 250 — Rules Doc Freshness and Count Parity

## Scope

- `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md`
- `docs/09_rules_and_guidelines/UI_UX_PRINCIPLES.md`

## Why this block

The active rules layer still had two small but real drift patterns:

- `DEVELOPMENT_RULES.md` still carried an old `2026-03-21` freshness stamp
- the “Hexbound mapping” section in `DEVELOPMENT_RULES.md` still used count-heavy content wording (`80+ skills`, `200+ items`, `150+ passive nodes`) that ages badly and adds no real rule value
- `UI_UX_PRINCIPLES.md` was also still stamped `2026-03-21` even though it remains an active helper doc in the current source-of-truth stack

## Fix applied

- updated `DEVELOPMENT_RULES.md` freshness metadata to `2026-04-20`
- updated `UI_UX_PRINCIPLES.md` freshness metadata to `2026-04-20`
- rewrote the count-heavy “Content” mapping line in `DEVELOPMENT_RULES.md` to a role-based description of the live content domains

## Result

The active rules docs now look as current as the audit wave they belong to, and `DEVELOPMENT_RULES.md` no longer bakes stale quantity claims into a section that is supposed to explain structure rather than inventory size.

## Verification

- header checks in both touched docs
- `git diff --check`
