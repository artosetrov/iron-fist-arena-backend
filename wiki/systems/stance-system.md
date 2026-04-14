---
title: Stance System
category: systems
tags: [combat, stance, zones, attack, defense]
sources: [Hexbound/Hexbound/Views/Hub/StanceSelectorViewModel.swift, docs/06_game_systems/COMBAT.md]
updated: 2026-04-14
---

# Stance System

Pre-battle zone selection. Each player picks an Attack Zone and a Defense Zone independently.

## Zones

Three zones: **head**, **chest**, **legs**. Icons: `icon-helmet`, `icon-chest`, `icon-legs`.

## Attack Zone Bonuses

| Zone | Offense | Crit |
|------|---------|------|
| Head | +10% | +5% |
| Chest | +5% | +0% |
| Legs | +2% | +0% |

Head is high-risk/high-reward. Legs was rebalanced in W3.D4 (from -3% crit to +0%).

## Defense Zone Bonuses

| Zone | Defense | Dodge |
|------|---------|-------|
| Head | +0% | +8% |
| Chest | +10% | +0% |
| Legs | +5% | +3% |

Chest is the safe pick (pure defense). Head is dodge-focused (synergizes with Rogue).

## Zone Matching

- **Match** (attacker's zone = defender's zone): defender gets +15% DEF
- **Mismatch** (zones differ): attacker gets +5% OFF

This creates a rock-paper-scissors metagame: if everyone defends chest, attack head. If everyone attacks head, defend head.

## UI Flow

- Two independent selectors: Attack Zone / Defense Zone
- 48pt horizontal buttons with inline bonus pills
- Color-coded: head = red, chest = blue, legs = green
- Optimistic save — stamp UI immediately, API in background. Revert on failure.
- Sticky "SAVE STANCE" button with fade gradient

## Zone Assets

Canonical mapping: `StanceSelectorViewModel.zoneAsset(for:)` and `.zoneColor(for:)`. **Never use emoji** for zone indicators — always asset images.

## See Also

- [[combat]]
- [[classes]] (Rogue dodge synergy with Head defense)
