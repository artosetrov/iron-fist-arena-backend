---
title: Audit Block 284 — Pre-Release Audit Follow-Up Temporal Wording Sync
category: audit
tags: [audit, docs, operations, wiki]
sources:
  - wiki/log.md
  - wiki/audit/block-281-pre-release-audit-guild-hall-resolved-followup.md
  - wiki/audit/block-283-ios-city-map-route-less-building-filter-parity.md
updated: 2026-04-30
status: Fixed
---

# Audit Block 284 — Pre-Release Audit Follow-Up Temporal Wording Sync

## Scope

This block cleans up the audit trail wording around the pre-release follow-up sequence.

## Why this block

After block 283 hid the route-less Black Market from the normal hub, block 281
and its corresponding log entry still read a little too much like the Black
Market placeholder was current truth instead of an intermediate step in the
audit wave.

## Changes shipped

- Reworded the block-281 log entry to make the timeline explicit.
- Updated block 281 itself so its "Black Market remains" language is clearly
  temporal and now points at block 283 as the later follow-up.

## Result

The audit trail now reads in chronological order without accidentally sounding
like Black Market is still a player-facing dead-end after the route-less filter
fix landed.
