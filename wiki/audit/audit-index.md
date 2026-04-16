---
title: File-By-File Project Audit
category: audit
tags: [audit, architecture, file-catalog, qa]
sources: [wiki/audit/project-file-inventory.md]
updated: 2026-04-16
---

# File-By-File Project Audit

This audit tracks every project-owned file in small logical blocks. Scope is Git-tracked files plus untracked project files. Vendor/build/cache artifacts are excluded unless committed to the repository.

## Inventory

- [[project-file-inventory]] — complete file list by top-level block
- In-scope files: 4909
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
| 030 | [[block-030-backend-ci-contract-hardening-and-actions-upgrade]] — backend CI hardening via safer premium partial mocks and GitHub Actions upgrade off deprecated v4 actions | Fixed |
| 031 | [[block-031-backend-route-tests-transaction-and-premium-fixtures]] — backend route-test fixture cleanup for premium shape parity and typed transaction mocks | Fixed |
| 032 | [[block-032-backend-api-tests-nextrequest-helper]] — backend API test-boundary cleanup via shared NextRequest helper and adjacent fixture typing | Fixed |
| 033 | [[block-033-backend-api-tests-request-cast-elimination]] — backend API test cleanup finishing the migration off remaining `Request as any` casts in live route tests | Fixed |
| 034 | [[block-034-backend-auth-bot-minigame-guardrail-tests]] — backend auth, bot-ticket, shell-game, and stamina-refill test coverage for runtime guard rails introduced after earlier economy and bot-ticket changes | Fixed |
| 035 | [[block-035-backend-battle-pass-claim-test-contracts]] — backend battle-pass claim test alignment with current reward-grant, level-gate, and cache-invalidation runtime contracts | Fixed |
| 036 | [[block-036-backend-dungeon-rush-resolve-test-contracts]] — backend dungeon-rush resolve test alignment with current reward-grant and post-level-up cache-invalidation contracts | Fixed |
| 037 | [[block-037-backend-pvp-resolve-test-contracts]] — backend PvP resolve test alignment with current anti-cheat, battle-ticket, bot-ticket, and locked-stamina runtime contracts | Fixed |
| 038 | [[block-038-backend-utility-routes-and-character-warning-cleanup]] — backend utility/deprecated routes plus character appearance/respec warning cleanup and runtime notes | Fixed |
| 039 | [[block-039-backend-rush-start-shop-race-hardening]] — backend Dungeon Rush start/shop race hardening plus adjacent start/match/shop dead-code cleanup | Fixed |
| 040 | [[block-040-backend-iap-receipt-idempotency-and-webhook-contracts]] — backend Apple IAP receipt idempotency, webhook contract cleanup, and focused route tests | Fixed |
| 041 | [[block-041-iap-compatibility-aliases-restore-and-ios-endpoints]] — IAP restore/verify compatibility aliases, iOS endpoint-catalog drift cleanup, and API reference clarification | Fixed |
| 042 | [[block-042-backend-inventory-mail-quest-contract-hardening]] — backend inventory equip/unequip transaction hardening, mail rate-limit repair, daily quest typing cleanup, and focused route tests | Fixed |
| 043 | [[block-043-backend-shell-game-transaction-and-session-hardening]] — backend shell-game start/guess hardening for daily-limit locking, session-state validation, and focused route tests | Fixed |
| 044 | [[block-044-backend-social-contracts-and-runtime-hardening]] — backend social challenges/messages/friends/relationship contract typing, duel XP persistence, locked send guards, and focused route tests | Fixed |
| 045 | [[block-045-backend-tutorial-achievement-and-weekly-contracts]] — backend tutorial quest contract hardening, achievement catalog/runtime metadata fixes, and weekly-challenge helper typing/tests | Fixed |
| 046 | [[block-046-backend-feature-flags-progression-and-runtime-cleanup]] — backend feature-flag environment enforcement, progression helper typing, combat helper cleanup, and push broadcast typing hardening | Fixed |
| 047 | [[block-047-backend-dungeon-item-balance-live-config-hardening]] — backend DB-dungeon variety parity, item-balance config sanitization/cache hardening, and live-config cleanup | Fixed |
| 048 | [[block-048-admin-item-balance-backend-proxy-alignment]] — admin item-balance API proxy alignment, canonical backend saves/simulations, and dead duplicate runtime removal | Fixed |
| 049 | [[block-049-admin-config-canonical-route-and-consumables-live-sync]] — canonical backend admin config route, shared config-cache invalidation, admin action reroute, and atomic consumables live save | Fixed |
| 050 | [[block-050-admin-skills-passives-proxy-alignment]] — admin skills/passives same-origin proxy alignment and removal of browser-side token/base-URL shims | Fixed |
| 051 | [[block-051-admin-active-config-editors-consistency]] — admin balance/config/loot/daily-login editor consistency after the canonical admin-config write path migration | Fixed |
| 052 | [[block-052-admin-balance-schema-parity-and-auth-hardening]] — admin balance schema parity with seeded live config plus auth/read-side cleanup for generic config access | Fixed |
| 053 | [[block-053-admin-snapshots-restore-runtime-hardening]] — admin snapshot rollback migration onto canonical backend restore, cache invalidation hardening, and snapshots UI cleanup | Fixed |
| 054 | [[block-054-admin-settings-role-guards-and-feature-flag-contracts]] — admin role-change guard rails, typed feature-flag contracts, and adjacent dashboard/economy warning cleanup | Fixed |
| 055 | [[block-055-admin-push-and-shop-offer-contract-hardening]] — admin push auth/targeting hardening plus typed shop-offer contracts and client cleanup | Fixed |
| 056 | [[block-056-admin-quests-and-battle-pass-contract-alignment]] — admin quest-definition validation plus battle-pass reward contract parity, deletion fixes, and server-authoritative refresh cleanup | Fixed |
| 057 | [[block-057-admin-achievements-runtime-parity]] — admin achievement-definition validation, corrected ranking seed thresholds, and live claim-runtime parity cleanup | Fixed |
| 058 | [[block-058-admin-appearances-and-design-system-preview-consistency]] — admin appearance-skin contract enforcement plus design-system preview font-loading cleanup and dead-import removal | Fixed |
| 059 | [[block-059-admin-design-system-residual-debt-and-warning-cleanup]] — residual design-system/admin warning cleanup plus async-state hardening in the liveops mail editor | Fixed |
| 060 | [[block-060-admin-dungeon-map-and-editor-runtime-cleanup]] — dungeon map/editor cleanup for truthful save state, intentional preview image policy, and dead editor state removal | Fixed |
| 061 | [[block-061-admin-live-editors-async-state-hardening]] — admin seasons/events/assets/dungeons cleanup for truthful async state and safer destructive operator flows | Fixed |
| 062 | [[block-062-admin-players-items-async-state-hardening]] — admin players/items cleanup for truthful moderation, grant, delete, upload, and save lifecycles | Fixed |
| 063 | [[block-063-admin-feature-flags-operator-feedback-hardening]] — admin feature flags cleanup for explicit toggle/save/delete feedback and row-scoped pending state | Fixed |
| 064 | [[block-064-admin-config-and-balance-editor-async-state-hardening]] — admin settings/config/consumables/loot/balance cleanup for truthful live save state across row, bulk, and seed operations | Fixed |
| 065 | [[block-065-admin-snapshots-and-item-balance-editor-async-state-hardening]] — admin snapshots and item-balance editor cleanup for truthful create/rollback/delete/save lifecycles | Fixed |
| 066 | [[block-066-admin-skills-and-passives-editor-async-state-hardening]] — admin skills/passives cleanup for truthful create/update/delete editor state across nodes, connections, and skills | Fixed |
| 067 | [[block-067-admin-generic-table-shell-mutation-hardening]] — generic admin CRUD table shell cleanup for thrown-error safety and clearer navigation-vs-mutation state | Fixed |
| 068 | [[block-068-admin-achievements-and-item-balance-operator-feedback]] — admin achievements/item-balance cleanup for quieter failure paths and explicit quick-validation feedback | Fixed |
| 069 | [[block-069-admin-residual-transition-and-copy-cleanup]] — admin residual cleanup for a leftover feature-flag refresh helper and leaked internal dashboard TODO copy | Fixed |
| 070 | [[block-070-admin-events-api-auth-gap]] — admin events API cleanup for missing auth guards on list/create/update/delete handlers | Fixed |
| 071 | [[block-071-ios-hub-daily-login-and-levelup-contract-cleanup]] — iOS residual cleanup for mock battle-pass hub data, incorrect daily-login HP potion icons, and non-authoritative level-up ceremony rows | Fixed |
| 072 | [[block-072-progression-passive-points-contract-parity]] — backend-to-iOS progression contract parity for passive-point awards across reward claims, combat resolves, dungeon victories, and the level-up ceremony | Fixed |
| 073 | [[block-073-tutorial-scripted-fight-contract-and-victory-parity]] — tutorial scripted-fight contract normalization, onboarding victory reward truth, and regression coverage for the preload/resolve API boundary | Fixed |
| 074 | [[block-074-tutorial-referral-rate-limit-and-storage-parity]] — tutorial referral rate-limit repair, canonical referral storage, mixed legacy/canonical count parity, and focused route regression coverage | Fixed |
| 075 | [[block-075-referral-qualification-rewards-and-idempotency]] — referral qualification payout implementation, idempotent claim persistence, and shared progression-hook rollout | Fixed |
| 076 | [[block-076-referral-reward-backfill-tooling]] — referral reward backfill tooling, dry-run/apply repair safety, and mixed legacy/canonical historical payout reconciliation | Fixed |
| 077 | [[block-077-ios-referral-and-tavern-typed-contract-cleanup]] — iOS referral settings plus Fortune Wheel and Shell Game migration off raw JSON onto typed request/response contracts | Fixed |
| 078 | [[block-078-ios-tutorial-manager-typed-contract-cleanup]] — iOS tutorial manager migration off raw tutorial dictionaries plus hub/city-map tutorial quest consumer parity and reward-toast contract repair | Fixed |
| 079 | [[block-079-ios-dungeon-list-and-progress-typed-contracts]] — iOS dungeon catalog/progress migration off raw dictionaries plus typed active-run resume and hub prefetch parity | Fixed |
| 080 | [[block-080-ios-dungeon-combat-and-rush-entry-typed-contracts]] — iOS dungeon start/fight plus rush status/start/fight migration onto typed contracts and typed combat handoff | Fixed |
| 081 | [[block-081-ios-dungeon-rush-resolve-and-shop-typed-contracts]] — iOS dungeon rush resolve and shop-buy migration onto typed contracts plus authoritative shop gold sync | Fixed |
| 082 | [[block-082-ios-pending-loot-typed-presentation-contract]] — iOS shared pending-loot migration off raw dictionaries plus typed arena/dungeon/rush reward presentation parity | Fixed |
| 083 | [[block-083-ios-character-service-typed-contract-cleanup]] — iOS character service migration off raw JSON for live load/stat/stance flows plus explicit handling for the dead training route | Fixed |
| 084 | [[block-084-ios-character-list-typed-envelope-parity]] — iOS auth/bootstrap and character-select migration onto a shared typed character-list envelope with legacy fallback kept in one place | Fixed |
| 085 | [[block-085-ios-game-init-typed-bootstrap-and-cache-parity]] — iOS unified game bootstrap migration off raw JSON plus typed daily-login/user snapshots and startup inventory parity for consumables | Fixed; bootstrap-only event/achievement summary consumers still pending |
| 086 | [[block-086-ios-pvp-service-typed-list-contracts]] — iOS PvP opponents, revenge list, and match-history migration off raw JSON onto typed response envelopes | Fixed; PvP mutation/profile follow-up still pending |
| 087 | [[block-087-ios-tutorial-service-typed-scripted-fight-contracts]] — iOS scripted tutorial-fight preload/resolve migration off raw dictionaries onto typed onboarding DTOs | Fixed; replay/sanity-check visibility decision still pending |
| 088 | [[block-088-ios-social-and-challenge-action-typed-contracts]] — iOS social friend actions, friendship-status lookup, and challenge decline/cancel migration off raw post bodies onto typed contracts | Fixed |
| 089 | [[block-089-ios-stash-transfer-typed-contracts]] — iOS stash deposit/withdraw migration off raw transfer bodies onto typed request/response contracts | Fixed |
| 090 | [[block-090-ios-auth-service-and-account-delete-typed-contracts]] — iOS email auth, guest login, forgot-password, and settings account deletion migration off raw JSON onto typed envelopes | Fixed; Apple/Google/guest-upgrade follow-up still pending |
| 091 | [[block-091-ios-oauth-signin-and-guest-upgrade-typed-contracts]] — iOS Apple/Google sign-in plus guest email/OAuth upgrade migration onto the shared typed auth session envelope | Fixed |
| 092 | [[block-092-ios-onboarding-name-and-character-create-typed-contracts]] — iOS onboarding name availability and character creation migration off raw JSON onto typed request/response contracts | Fixed |
| 093 | [[block-093-ios-shop-service-typed-purchase-and-repair-contracts]] — iOS shop purchase, consumable buy, gems buy, repair, and upgrade migration off raw JSON onto typed contracts | Fixed |
| 094 | [[block-094-ios-inventory-service-sell-use-expand-typed-contracts]] — iOS inventory sell, consumable use, and bag expansion migration off raw mutation dictionaries onto typed contracts | Fixed |
| 095 | [[block-095-ios-battle-preloader-typed-pvp-contracts]] — iOS arena prepare/resolve migration onto typed PvP contracts plus typed durability degradation snapshots for post-fight UI | Fixed; `CombatEngine` still keeps an internal legacy dictionary bridge |
| 096 | [[block-096-ios-appearance-editor-typed-save-contract]] — iOS appearance editor migration off raw patch bodies and manual `Character` JSON re-decoding | Fixed |
| 097 | [[block-097-ios-dungeon-rush-abandon-and-gold-mine-status-typed-contracts]] — iOS dungeon rush abandon plus hub/gold-mine status reads migration onto typed contracts with one narrow cache bridge | Fixed; gold-mine mutation flows still keep the remaining raw tail |
| 098 | [[block-098-ios-gold-mine-action-typed-contracts]] — iOS Gold Mine action flows migration off raw mutations onto typed contracts across collect, collect-all, boosts, slot purchase, and shaft minigame actions | Fixed |
| 099 | [[block-099-ios-editor-layout-save-typed-contracts]] — iOS debug editor layout-save flows migration onto typed contracts for dungeon-map and hub editors | Fixed |
| 100 | [[block-100-ios-game-config-daily-login-parse-bridge-cleanup]] — iOS game-config cleanup removing the daily-login reward JSON round-trip from cache parsing | Fixed |
| 101 | [[block-101-ios-interactive-combat-reconcile-payload-bridge-cleanup]] — iOS interactive combat cleanup removing the recoverable reconcile JSON round-trip for `OUT_OF_CONSUMABLE` actives payloads | Fixed |
| 102 | [[block-102-ios-network-infrastructure-raw-surface-retirement]] — iOS networking/auth infrastructure cleanup retiring dead raw helper APIs and moving Supabase auth flows onto typed DTOs | Fixed |
| 103 | [[block-103-ios-gold-mine-typed-state-and-cache-parity]] — iOS Gold Mine state/cache migration off raw slot dictionaries onto typed slot models across cache, hub badges, hints, and the live Gold Mine screen | Fixed |
| 104 | [[block-104-ios-battle-preloader-combat-engine-typed-handoff]] — iOS arena combat cleanup removing the last internal typed-to-dictionary handoff between `BattlePreloader` and `CombatEngine` | Fixed |
| 105 | [[block-105-ios-typed-error-body-and-combat-model-bridge-cleanup]] — iOS typed error-body decoding for recoverable combat/minigame/referral flows plus removal of the dead raw pending-loot bridge | Fixed |
| 106 | [[block-106-ios-cache-raw-bridge-retirement-and-feature-flag-bool-parity]] — iOS cache cleanup removing dead raw quest/layout bridges and narrowing bootstrap feature flags to the live bool contract | Fixed |
| 107 | [[block-107-ios-dead-model-parse-bridge-cleanup]] — iOS dead Gold Mine/dungeon raw model parser cleanup plus validation of the last remaining daily-login cache compatibility edge | Fixed |
| 108 | [[block-108-ios-intentional-raw-boundaries-and-dead-apiresponse-removal]] — iOS cleanup removing the dead raw `GameConfig`/`APIResponse` tail and documenting the remaining intentional networking/keychain raw boundaries | Fixed |

## Status Legend

- **OK** — file has a clear role and no immediate action.
- **Fixed** — safe issue found and corrected.
- **Needs review** — issue or uncertainty needs product/architecture decision.
- **Deprecated** — candidate to remove after confirming it is not referenced.

## Rules

- Record role, dependencies, inbound usage, business rules, issues, fixes, unresolved decisions, and status for every audited file.
- Prefer safe mechanical fixes during audit.
- Do not delete prototypes/reports/assets without explicit confirmation; mark candidates first.
