---
title: Audit Block 204 — Inventory Tracked Marker Parity For Late Auth And Feature Pages
category: audit
tags: [audit, inventory, tracking, auth, wiki]
sources:
  - wiki/audit/project-file-inventory.md
  - wiki/audit/block-187-backend-forgot-password-canonical-host-fallback.md
  - wiki/features/onboarding.md
  - wiki/features/opponent-profile.md
  - wiki/decisions/why-reward-modal-over-toast.md
  - backend/src/app/reset-password/page.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 204 — Inventory Tracked Marker Parity For Late Auth And Feature Pages

## Scope

- `wiki/audit/project-file-inventory.md`
- later auth audit pages (`block-174` through `block-201`)
- late-added feature/decision pages already committed to Git
- `backend/src/app/reset-password/page.tsx`

## Why this block

After the first inventory marker cleanup, one more late wave was still mislabeled:

- newer auth/audit pages
- late-added feature atlas pages
- the reward-modal decision page
- the hosted reset-password page

All of them were already tracked in Git, but the inventory still showed them as `_(untracked)_`.

## Fix applied

Removed stale `_(untracked)_` markers for:

- `wiki/audit/block-174-stale-audit-tail-prototype-decision-sync.md`
- through `wiki/audit/block-201-backend-interactive-pvp-opponent-null-contract-guard.md`
- `wiki/decisions/why-reward-modal-over-toast.md`
- `wiki/features/onboarding.md`
- `wiki/features/opponent-profile.md`
- `backend/src/app/reset-password/page.tsx`

## Result

This closes the second half of the inventory drift:

- late auth/wiki pages no longer look half-committed
- feature-atlas additions are reflected as tracked first-class pages
- the inventory now matches Git for this entire recent cleanup corridor

## Verification

- `git ls-files -- <corrected file set>`
- `git diff --check`

Both passed.
