---
title: Audit Block 281 — Pre-Release Audit Guild Hall Resolved Follow-Up
category: audit
tags: [audit, operations, ios, social, docs]
sources:
  - docs/10_operations/HEXBOUND_PRE_RELEASE_AUDIT.md
  - wiki/audit/block-279-ios-guild-hall-city-route-parity.md
  - Hexbound/Hexbound/Views/Hub/CityBuildingConfig.swift
updated: 2026-04-30
status: Fixed
---

# Audit Block 281 — Pre-Release Audit Guild Hall Resolved Follow-Up

## Scope

This block syncs the historical pre-release audit with the later Guild Hall route fix.

## Why this block

`HEXBOUND_PRE_RELEASE_AUDIT.md` is intentionally historical, but several tables still
read as if Guild Hall is currently a live dead-end in the checked-in repo. After
block 279, that was no longer true: Guild Hall became routable, while Black
Market was still the remaining checked-in placeholder surface at that point in
the audit wave.

## Changes shipped

- Added a short historical follow-up note to the "Coming Soon" section.
- Reworded the Guild Hall-specific rows so they preserve the snapshot truth
  without implying the dead-end still exists today.
- Narrowed the later action item from "Guild Hall + Black Market" to the
  remaining Black Market placeholder.

## Result

The release audit now keeps both truths at once:

- Guild Hall really was a release-time dead-end in the original snapshot.
- The checked-in repo later fixed Guild Hall routing; at the time of this
  follow-up, Black Market was still the remaining checked-in placeholder surface.

## Later follow-up

- `[[block-283-ios-city-map-route-less-building-filter-parity]]` later hid the
  route-less Black Market from the normal hub path too, so this block should be
  read as an intermediate historical cleanup step rather than the final hub
  state.
