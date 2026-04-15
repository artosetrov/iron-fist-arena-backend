# Hexbound Wiki — Index

## Systems

- [[combat]] — Turn-based 1v1, damage formulas, crit/dodge, stance, fatigue
- [[interactive-combat]] — v2 predict/reveal layer, telemetry gates, feature flag
- [[economy]] — Gold/gems, earning, sinks, monetization, IAP, sink ratios
- [[pvp-rating]] — ELO system, K-factors, rank ladder, revenge
- [[progression]] — Levels, stats, prestige, upgrades, skills, drop rates
- [[stamina]] — Energy gating, regen, refill costs, session design
- [[stance-system]] — Attack/defense zones, bonuses, matching, metagame
- [[passive-tree]] — Node-based talents, active abilities, staged unlock, respec
- [[achievements]] — 3 categories, 21 achievements, absolute tracking, gem rewards
- [[dungeons]] — Structured floors + Dungeon Rush endless mode
- [[gold-mine]] — Passive income, slot mechanics, shaft system, bonus minigame
- [[minigames]] — Gold Mine, Shell Game, Fortune Wheel, Tavern
- [[social]] — Guild Hall: friends, messaging, challenges/duels

## Decisions

- [[design-principles]] — 3-second rule, server-authoritative, guard patterns, root overlays
- [[bug-patterns]] — CodingKeys double-conversion, TOCTOU, silent try?, junk files, constant drift
- [[balance-audit-findings]] — Open issues: AGI overpowered, XP curve, poison, mine vs PvP income
- [[why-auto-generated-balance-docs]] — Balance docs SSoT, drift prevention, generated constants
- [[why-no-gem-to-gold]] — F2P integrity, no pay-to-win conversion
- [[why-exponential-upgrades]] — Primary gold sink, whale channel, aspirational goals
- [[why-battle-fatigue]] — Prevents tank stalling, escalating damage turn 11+
- [[why-k-factor-48]] — Calibration volatility, 10-game convergence, industry standard
- [[why-rogue-execute]] — Finisher mechanic, prevents kiting, thematic RPG pattern
- [[why-diminishing-refills]] — Whale spending cap, economy protection, industry precedent
- [[rebalance-w3d3]] — 2026-04-10 economy rebalance: CHA cap, streak cap, price increases

## Entities

- [[classes]] — Warrior, Rogue, Mage, Tank — stats, passives, origins
- [[screens]] — 70+ views, 46 Figma screens, navigation map
- [[design-system]] — DarkFantasyTheme tokens, colors, typography, spacing, ornamental system

## Audit

- [[audit-index]] — File-by-file project audit tracker
- [[project-file-inventory]] — Complete in-scope file inventory by block
- [[block-001-root-files]] — Root-level config, docs, legal pages, and prototypes
- [[block-002-repo-automation]] — GitHub CI, Cursor rules, local skills, and scanner scripts
- [[block-003-claude-operational-safety]] — Claude local settings and operational skill safety
- [[block-004-claude-product-governance-skills]] — Claude product, QA, release, and governance skill docs
- [[block-005-claude-figma-design-system-skills]] — Claude Figma, design-system, Code Connect, and helper scripts
- [[block-006-project-scripts]] — Project scripts for guards, asset pipelines, Git helpers, and Figma sync
- [[block-007-backend-root-prisma-foundation]] — Backend root config, Prisma schema foundation, seed and repair scripts, and passive-tree bootstrap SQL
- [[block-008-prisma-migrations-baseline-early-deltas]] — Prisma migration baseline, early delta chain, and audit-created migration fixes
- [[block-009-prisma-migrations-onboarding-gold-and-w3d5]] — Prisma migrations for onboarding, account-level gold, activity caps, guest restore, and W3.D5 premium/weekly changes
- [[block-010-prisma-migrations-hotfixes-stash-interactive-premium]] — Prisma migrations for Gold Mine hotfix cleanup, stash/contraband persistence, interactive combat, premium subscriptions, and stamina-cap changes
- [[block-011-backend-passives-interactive-combat-runtime]] — Backend passives APIs, active-slot runtime, and interactive PvP match start/strike flows
- [[block-012-backend-stash-contraband-premium-runtime]] — Backend stash APIs, contraband claim runtime, premium helpers, and daily-login premium claims
- [[block-013-backend-reward-premium-parity]] — Backend reward routes, premium-aware user surfaces, and guest-account entitlement transfer parity
- [[block-014-shared-reward-grants-shop-mail-rush-sync]] — Shared reward grants, shop/mail claim runtime, and Dungeon Rush reward sync across backend and iOS
- [[block-015-claim-progression-achievements-quests-battle-pass]] — Claim progression for achievements, daily quests/bonus, battle pass reward runtime, and iOS level-up/reward sync
- [[block-016-backend-daily-login-battle-pass-reward-contracts]] — Daily login claim contract, battle pass reward-label parity, and shared iOS reward/progression sync
- [[block-017-ios-claim-services-authoritative-reward-sync]] — Remaining iOS achievement/quest claim services and inline quest reward consumers
- [[block-018-ios-typed-achievements-quests-loaders]] — Typed achievement and daily-quest list loaders on iOS
- [[block-019-ios-contract-fixes-battle-pass-shop-leaderboard]] — Typed battle pass/shop/leaderboard loaders plus DTO contract fixes for live reward flows
- [[block-020-inventory-typed-snapshots-legacy-consumables]] — Typed inventory snapshots on iOS and legacy equipment-inventory consumable parity
- [[block-021-item-stat-authority-consumable-catalog]] — Item stat authority, typed stash snapshots, and shared consumable presentation metadata on iOS
- [[block-022-ios-active-skill-picker-passive-tree-contracts]] — iOS active-skill picker replacement semantics, passive-tree mutation contracts, and talent-slot UX alignment
- [[block-023-ios-interactive-combat-terminal-state-and-round-log]] — iOS interactive combat terminal-state correctness, round-log numbering, and active-HUD accessibility
- [[block-024-interactive-combat-consumable-recovery]] — interactive combat consumable snapshot validity and recoverable out-of-consumable reconcile path
- [[block-025-backend-active-slot-consumable-ownership-reconciliation]] — backend active-slot potion ownership validation, cache reconciliation, and zero-quantity cleanup
- [[block-026-backend-shop-consumable-pricing-parity]] — backend direct-sale consumable allowlist and pricing parity across shop listing, purchase, and active-slot picker metadata
- [[block-027-shop-legacy-client-surface-and-pricing-docs]] — dead iOS legacy potion-purchase client path cleanup plus explicit pricing-policy docs alignment

---

*59 in-scope wiki files | 57 wiki pages (13 systems, 11 decisions, 3 entities, 29 audit, 1 schema) + index/log | Last updated: 2026-04-15*
