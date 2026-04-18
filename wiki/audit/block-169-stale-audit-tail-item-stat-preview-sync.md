---
title: Audit Block 169 — Stale Audit Tail Item Stat Preview Sync
category: audit
tags: [audit, ios, items, stats, truth-sync]
sources:
  - wiki/audit/block-020-inventory-typed-snapshots-legacy-consumables.md
  - wiki/audit/block-159-ios-game-init-item-stat-preview-parity.md
  - wiki/audit/block-165-ios-upgrade-stat-bonus-config-fallback-parity.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 169 — Stale Audit Tail Item Stat Preview Sync

## Scope

- `wiki/audit/block-020-inventory-typed-snapshots-legacy-consumables.md`
- `wiki/audit/block-159-ios-game-init-item-stat-preview-parity.md`
- `wiki/audit/block-165-ios-upgrade-stat-bonus-config-fallback-parity.md`

## Why this block

[[block-159-ios-game-init-item-stat-preview-parity]] and [[block-165-ios-upgrade-stat-bonus-config-fallback-parity]] already closed the last real iOS item-stat preview drift:

- cold-start inventory now hydrates authoritative `effectiveStats`
- rolled gear no longer inflates upgrade preview deltas
- local fallback math no longer assumes a hard-coded `+1` upgrade bonus

But the older inventory audit in [[block-020-inventory-typed-snapshots-legacy-consumables]] still marked `Hexbound/Hexbound/Models/Item.swift` as `Needs review` for exactly that old `+1` fallback risk.

That left the wiki telling two different stories about the same file.

## What changed

### `wiki/audit/block-020-inventory-typed-snapshots-legacy-consumables.md`

- updated the `Item.swift` record from `Needs review` to `Fixed`
- replaced the stale warning with explicit cross-links to:
  - [[block-159-ios-game-init-item-stat-preview-parity]]
  - [[block-165-ios-upgrade-stat-bonus-config-fallback-parity]]
- narrowed the remaining follow-up to the real open question:
  - not whether upgrade-bonus math is wrong,
  - but whether best-effort local preview should exist at all in partial/offline contexts

## Problems resolved

1. **Old audit block still claimed `Item.swift` had unresolved `+1` upgrade drift**
   - Resolution: the stale warning was replaced with the later-fixed truth.

2. **The wiki had split truth across three item-stat audit blocks**
   - Resolution: the older block now points to the later parity fixes instead of contradicting them.

## Verification

- re-read [[block-159-ios-game-init-item-stat-preview-parity]] and [[block-165-ios-upgrade-stat-bonus-config-fallback-parity]]
- re-read the updated `Item.swift` record in [[block-020-inventory-typed-snapshots-legacy-consumables]]

## Follow-up

- The remaining item-stat question is now product-facing:
  - should partial/offline item surfaces keep showing best-effort local preview,
  - or should they suppress upgrade deltas until authoritative backend stats exist?
