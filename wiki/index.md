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
- [[block-028-backend-contraband-reward-contract-build-fix]] — backend contraband reward typing parity with shared reward grants after the production build break
- [[block-029-backend-ci-premium-mock-drift-tests]] — backend GitHub CI failure from stale premium test mocks and outdated shared reward transaction mocks
- [[block-030-backend-ci-contract-hardening-and-actions-upgrade]] — backend CI hardening with safer premium partial mocks and upgraded GitHub Actions workflow
- [[block-031-backend-route-tests-transaction-and-premium-fixtures]] — backend route-test cleanup for premium fixture parity and typed transaction mocks
- [[block-032-backend-api-tests-nextrequest-helper]] — backend API test cleanup via shared NextRequest helper and safer route-boundary fixtures
- [[block-033-backend-api-tests-request-cast-elimination]] — backend API test cleanup finishing the migration off remaining request casts in live route tests
- [[block-034-backend-auth-bot-minigame-guardrail-tests]] — backend test coverage for auth validation, bot-ticket happy path, shell-game guard rails, and stamina-refill diminishing returns
- [[block-035-backend-battle-pass-claim-test-contracts]] — backend battle-pass claim test coverage for current reward-grant, level-gate, and cache-invalidation contracts
- [[block-036-backend-dungeon-rush-resolve-test-contracts]] — backend dungeon-rush resolve test coverage for current reward-grant and leveled-up cache invalidation behavior
- [[block-037-backend-pvp-resolve-test-contracts]] — backend PvP resolve test coverage for anti-cheat mismatch handling, locked-stamina protection, and bot-ticket guards
- [[block-038-backend-utility-routes-and-character-warning-cleanup]] — backend utility/deprecated routes cleanup plus character appearance/respec warning and runtime notes
- [[block-039-backend-rush-start-shop-race-hardening]] — backend Dungeon Rush start/shop race hardening plus adjacent start/match/shop cleanup
- [[block-040-backend-iap-receipt-idempotency-and-webhook-contracts]] — backend Apple IAP receipt idempotency, webhook cleanup, and focused route tests
- [[block-041-iap-compatibility-aliases-restore-and-ios-endpoints]] — IAP restore/verify compatibility aliases, iOS endpoint-catalog cleanup, and API reference clarification
- [[block-042-backend-inventory-mail-quest-contract-hardening]] — backend inventory equip/unequip transaction hardening, mail rate-limit repair, daily quest typing cleanup, and focused route tests
- [[block-043-backend-shell-game-transaction-and-session-hardening]] — backend shell-game start/guess hardening for daily-limit locking, session-state validation, and focused route tests
- [[block-044-backend-social-contracts-and-runtime-hardening]] — backend social challenges/messages/friends/relationship contract typing, duel XP persistence, locked send guards, and focused route tests
- [[block-045-backend-tutorial-achievement-and-weekly-contracts]] — backend tutorial quest contract hardening, achievement catalog/runtime metadata fixes, and weekly-challenge helper typing/tests
- [[block-046-backend-feature-flags-progression-and-runtime-cleanup]] — backend feature-flag environment enforcement, progression helper typing, combat helper cleanup, and push broadcast typing hardening
- [[block-047-backend-dungeon-item-balance-live-config-hardening]] — backend DB-dungeon variety parity, item-balance config sanitization/cache hardening, and live-config cleanup
- [[block-048-admin-item-balance-backend-proxy-alignment]] — admin item-balance API proxy alignment, canonical backend saves/simulations, and dead duplicate runtime removal
- [[block-049-admin-config-canonical-route-and-consumables-live-sync]] — canonical backend admin config route, shared config-cache invalidation, admin action reroute, and atomic consumables live save
- [[block-050-admin-skills-passives-proxy-alignment]] — admin skills/passives same-origin proxy alignment and removal of browser-side token/base-URL shims
- [[block-051-admin-active-config-editors-consistency]] — admin balance/config/loot/daily-login editor consistency after the canonical admin-config write path migration
- [[block-052-admin-balance-schema-parity-and-auth-hardening]] — admin balance schema parity with seeded live config plus auth/read-side cleanup for generic config access
- [[block-053-admin-snapshots-restore-runtime-hardening]] — admin snapshot rollback migration onto canonical backend restore, cache invalidation hardening, and snapshots UI cleanup
- [[block-054-admin-settings-role-guards-and-feature-flag-contracts]] — admin role-change guard rails, typed feature-flag contracts, and adjacent dashboard/economy warning cleanup
- [[block-055-admin-push-and-shop-offer-contract-hardening]] — admin push auth/targeting hardening plus typed shop-offer contracts and client cleanup
- [[block-056-admin-quests-and-battle-pass-contract-alignment]] — admin quest-definition validation plus battle-pass reward contract parity, deletion fixes, and server-authoritative refresh cleanup
- [[block-057-admin-achievements-runtime-parity]] — admin achievement-definition validation, corrected ranking seed thresholds, and live claim-runtime parity cleanup
- [[block-058-admin-appearances-and-design-system-preview-consistency]] — admin appearance-skin contract enforcement plus design-system preview font-loading cleanup and dead-import removal

---

*90 in-scope wiki files | 88 wiki pages (13 systems, 11 decisions, 3 entities, 60 audit, 1 schema) + index/log | Last updated: 2026-04-15*
