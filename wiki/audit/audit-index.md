---
title: File-By-File Project Audit
category: audit
tags: [audit, architecture, file-catalog, qa]
sources: [wiki/audit/project-file-inventory.md]
updated: 2026-04-15
---

# File-By-File Project Audit

This audit tracks every project-owned file in small logical blocks. Scope is Git-tracked files plus untracked project files. Vendor/build/cache artifacts are excluded unless committed to the repository.

## Inventory

- [[project-file-inventory]] — complete file list by top-level block
- In-scope files: 4799
- Excluded: `node_modules/`, `.next/`, `.git/`, generated local caches, ignored dev artifacts

## Audit Blocks

| Block | Scope | Status |
|-------|-------|--------|
| 001 | [[block-001-root-files]] — Root files: repository policy, root reports, root prototypes/legal HTML | Fixed; cleanup decisions pending |
| 002 | [[block-002-repo-automation]] — GitHub CI, Cursor rules, local skills and scanner scripts | Fixed; follow-up consolidation pending |
| 003 | [[block-003-claude-operational-safety]] — `.claude` settings, duplicated operational skills, and runnable safety scripts | Fixed; de-tracking/credential rotation pending |
| 004 | [[block-004-claude-product-governance-skills]] — `.claude` product, QA, security, release, and governance skill docs | Fixed; stale QA data and local-state decisions pending |
| 005 | [[block-005-claude-figma-design-system-skills]] — `.claude` Figma, design-system, Code Connect, and helper-script files | Fixed; Figma state/config revalidation pending |
| 006 | [[block-006-project-scripts]] — project scripts for guards, asset pipelines, Git helpers, and Figma token sync | Fixed; audio/Git/generated-artifact policy decisions pending |
| 007 | [[block-007-backend-root-prisma-foundation]] — backend root config, Prisma schema foundation, seed/repair scripts, and passive-tree bootstrap SQL | Fixed; schema typing and seed orchestration follow-up pending |
| 008 | [[block-008-prisma-migrations-baseline-early-deltas]] — Prisma migration baseline, early delta chain, and audit-created migration fixes | Fixed; data-migration policy and native-type review pending |
| 009 | [[block-009-prisma-migrations-onboarding-gold-and-w3d5]] — Prisma migrations for onboarding, account-level gold, activity caps, guest restore, and W3.D5 premium/weekly changes | Fixed; tutorial-state simplification and migration-scope cleanup pending |
| 010 | [[block-010-prisma-migrations-hotfixes-stash-interactive-premium]] — Prisma migrations for Gold Mine hotfix cleanup, stash/contraband persistence, interactive combat, premium subscriptions, and stamina-cap changes | Fixed; manual-first migration policy and drift-repair scope cleanup pending |
| 011 | [[block-011-backend-passives-interactive-combat-runtime]] — Backend passives APIs, active-slot runtime, and interactive PvP match start/strike flows | Fixed; Prisma stale-client cleanup and pricing-policy docs still pending |
| 012 | [[block-012-backend-stash-contraband-premium-runtime]] — Backend stash APIs, contraband claim runtime, premium helpers, and daily-login premium claims | Fixed; premium rollout parity and shop reward helper consolidation pending |
| 013 | [[block-013-backend-reward-premium-parity]] — Backend reward routes, premium-aware user surfaces, and guest-account entitlement transfer parity | Fixed; challenge typing and account-merge policy follow-up pending |
| 014 | [[block-014-shared-reward-grants-shop-mail-rush-sync]] — Shared reward grants, shop/mail claim runtime, and Dungeon Rush reward sync across backend and iOS | Fixed; reward-payload DTO validation and shared client reward-sync helper still pending |
| 015 | [[block-015-claim-progression-achievements-quests-battle-pass]] — Claim progression for achievements, daily quests/bonus, battle pass reward runtime, and iOS level-up/reward sync | Fixed; remaining typing debt and global `previousLevel` rollout still pending |
| 016 | [[block-016-backend-daily-login-battle-pass-reward-contracts]] — Daily login claim contract, battle pass reward-label parity, and shared iOS reward/progression sync | Fixed; wider reward DTO normalization and remaining refresh-based claim services still pending |
| 017 | [[block-017-ios-claim-services-authoritative-reward-sync]] — Remaining iOS achievement/quest claim services and inline quest reward consumers | Fixed; typed GET loaders and shared reward-ceremony builder still pending |
| 018 | [[block-018-ios-typed-achievements-quests-loaders]] — Typed achievement and daily-quest list loaders on iOS | Fixed; wider raw-JSON service cleanup still pending |
| 019 | [[block-019-ios-contract-fixes-battle-pass-shop-leaderboard]] — Typed battle pass/shop/leaderboard loaders plus DTO contract fixes for live reward flows | Fixed; inventory/raw-contract cleanup and shared contract conventions still pending |
| 020 | [[block-020-inventory-typed-snapshots-legacy-consumables]] — Typed inventory snapshots on iOS and legacy equipment-inventory consumable parity | Fixed; shared consumable catalog metadata and stat-authority cleanup still pending |
| 021 | [[block-021-item-stat-authority-consumable-catalog]] — Item stat authority, typed stash snapshots, and shared consumable presentation metadata on iOS | Fixed; rolled-stat authority and config-exposed upgrade preview still pending |
| 022 | [[block-022-ios-active-skill-picker-passive-tree-contracts]] — iOS active-skill picker replacement semantics, passive-tree mutation contracts, and talent-slot UX alignment | Fixed; detail-sheet vs picker ownership and git-tracking normalization still pending |
| 023 | [[block-023-ios-interactive-combat-terminal-state-and-round-log]] — iOS interactive combat terminal-state correctness, round-log numbering, and active-HUD accessibility | Fixed; broader terminal-state docs still pending |
| 024 | [[block-024-interactive-combat-consumable-recovery]] — interactive combat consumable snapshot validity and recoverable out-of-consumable reconcile path | Fixed |
| 025 | [[block-025-backend-active-slot-consumable-ownership-reconciliation]] — backend active-slot potion ownership validation, cache reconciliation, and zero-quantity cleanup | Fixed; repurchase auto-restore policy still pending |
| 026 | [[block-026-backend-shop-consumable-pricing-parity]] — backend direct-sale consumable allowlist and pricing parity across shop listing, purchase, and active-slot picker metadata | Fixed; explicit GameConfig rollout still pending |
| 027 | [[block-027-shop-legacy-client-surface-and-pricing-docs]] — dead iOS legacy potion-purchase client path cleanup plus explicit pricing-policy docs alignment | Fixed; backend legacy route retirement decision still pending |
| 028 | [[block-028-backend-contraband-reward-contract-build-fix]] — backend contraband reward typing parity with shared reward grants after production build failure | Fixed |
| 029 | [[block-029-backend-ci-premium-mock-drift-tests]] — backend GitHub CI failure caused by stale premium mocks and outdated reward-transaction test shape | Fixed |

## Status Legend

- **OK** — file has a clear role and no immediate action.
- **Fixed** — safe issue found and corrected.
- **Needs review** — issue or uncertainty needs product/architecture decision.
- **Deprecated** — candidate to remove after confirming it is not referenced.

## Rules

- Record role, dependencies, inbound usage, business rules, issues, fixes, unresolved decisions, and status for every audited file.
- Prefer safe mechanical fixes during audit.
- Do not delete prototypes/reports/assets without explicit confirmation; mark candidates first.
