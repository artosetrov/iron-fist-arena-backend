---
title: File-By-File Project Audit
category: audit
tags: [audit, architecture, file-catalog, qa]
sources: [wiki/audit/project-file-inventory.md]
updated: 2026-04-29
---

# File-By-File Project Audit

This audit tracks every project-owned file in small logical blocks. Scope is Git-tracked files plus untracked project files. Vendor/build/cache artifacts are excluded unless committed to the repository.

## Inventory

- [[project-file-inventory]] — complete file list by top-level block
- In-scope files: 5184
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
| 008 | [[block-008-prisma-migrations-baseline-early-deltas]] — Prisma migration baseline, early delta chain, and audit-created migration fixes | Fixed; data-migration policy pending |
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
| 109 | [[block-109-operations-deploy-docs-reality-sync]] — operations/deploy docs sync for live CI, schema parity, explicit migration semantics, and current release risk inventory | Fixed |
| 110 | [[block-110-operations-git-workflow-and-ios-release-doc-parity]] — operations runbook sync for git workflow, CI-vs-deploy semantics, Fastlane setup truth, and iOS staging/release wording parity | Fixed |
| 111 | [[block-111-operations-database-migration-runbook-parity]] — operations migration runbook sync for explicit production apply semantics and parity with live deploy docs/build scripts | Fixed |
| 112 | [[block-112-ios-testflight-helper-identity-validation-parity]] — iOS TestFlight helper and docs sync for Appfile-vs-env Fastlane identity setup and stricter team validation | Fixed |
| 113 | [[block-113-wiki-generation-tooling-and-generated-indexes]] — wiki generation tooling audit, generated index parity, and preflight drift-check integration | Fixed |
| 114 | [[block-114-wiki-feature-maps-and-index-visibility]] — wiki feature-map indexing, navigation visibility, and wiki-link style parity for new feature pages | Fixed |
| 115 | [[block-115-operations-figma-and-historical-doc-boundaries]] — Figma handoff, screen inventory, historical progress/bug logs, and UI PR checklist source-of-truth boundaries | Fixed |
| 116 | [[block-116-source-of-truth-doc-index-parity]] — documentation index and cleanup-report parity for current source-of-truth boundaries | Fixed |
| 117 | [[block-117-source-of-truth-project-overview-parity]] — project overview parity for current stack, iOS minimum, and high-level operational semantics | Fixed |
| 118 | [[block-118-source-of-truth-admin-capabilities-and-screen-inventory-parity]] — admin capabilities and iOS screen inventory parity for stale counts, stack truth, and snapshot boundary wording | Fixed |
| 119 | [[block-119-design-system-source-of-truth-vs-audit-snapshot-boundaries]] — design system source-of-truth vs historical audit boundary cleanup for stale counts and milestone language | Fixed |
| 120 | [[block-120-ui-audit-artifacts-historical-boundary-cleanup]] — UI audit artifact boundary cleanup for historical dashboards, UX reviews, and asset/design-system forensic snapshots | Fixed |
| 121 | [[block-121-prototypes-link-parity-and-transition-state]] — prototype move link parity, combat-doc navigation repair, and prototype/legal transition-state capture | Fixed |
| 122 | [[block-122-wiki-feature-map-visibility-and-related-link-gaps]] — full feature-atlas visibility sync in the main index plus revalidation of remaining related-page dead-ends | Fixed |
| 123 | [[block-123-ui-review-and-plan-docs-historical-boundaries]] — historical-boundary cleanup for dated UI review, audit, redesign, and roadmap docs under `docs/07_ui_ux/` | Fixed |
| 124 | [[block-124-w1-w3-plan-docs-historical-boundaries]] — historical-boundary cleanup for dated W1/W2/W3 checkpoint, review, and design-plan docs under `docs/07_ui_ux/` | Fixed |
| 125 | [[block-125-ui-prototype-and-figma-workflow-boundaries]] — historical-boundary cleanup for residual UI prototype archives plus source-of-truth scoping for the strict Figma workflow playbook | Fixed |
| 126 | [[block-126-design-system-roadmap-and-screen-inventory-live-parity]] — live-vs-historical parity cleanup for the UI audit dashboard, design-system migration appendix, and screen inventory component naming | Fixed |
| 127 | [[block-127-dated-product-economy-and-architecture-doc-boundaries]] — historical-boundary cleanup for dated economy, architecture, migration, full-product, and interactive-combat plan docs | Fixed |
| 128 | [[block-128-retro-log-historical-boundaries]] — historical-boundary cleanup applied across the full dated engineering retrospective log set under `docs/retro/` | Fixed |
| 129 | [[block-129-archive-legacy-doc-boundaries]] — historical/legacy/duplicate boundary cleanup for residual archive docs under `docs/11_archive/` | Fixed |
| 130 | [[block-130-top-level-source-of-truth-and-orchestration-boundaries]] — top-level docs navigator/source-of-truth refresh plus historical-boundary cleanup for orchestration and studio operating-framework docs | Fixed |
| 131 | [[block-131-empty-doc-placeholders-and-deprecation-markers]] — empty placeholder-doc cleanup for silent zero-byte surfaces under `docs/` plus explicit deprecation markers | Fixed |
| 132 | [[block-132-obsidian-base-artifacts]] — root-level `.base` editor-artifact audit and deprecation assessment for likely Obsidian residue under `docs/` | Fixed |
| 133 | [[block-133-live-doc-tbd-and-url-cleanup]] — live-doc cleanup replacing residual `TBD`/placeholder wording in current progression and deploy docs | Fixed |
| 134 | [[block-134-delete-placeholder-and-editor-artifact-files]] — deletion of confirmed placeholder docs and `.base` editor artifacts plus repo-wide `.DS_Store` sweep | Fixed |
| 135 | [[block-135-delete-archive-duplicate-docs]] — deletion of pure duplicate archive docs plus archive-policy wording cleanup | Fixed |
| 136 | [[block-136-delete-root-orphan-prototype-artifacts]] — deletion of orphan root-level guest-gating/Gold Mine prototype artifacts with no live imports or source-of-truth role | Fixed |
| 137 | [[block-137-root-prototype-relocation-state-sync]] — inventory/root-audit sync for deleted root prototype/legal HTML paths now mirrored under `prototypes/` copies | Fixed |
| 138 | [[block-138-delete-deprecated-prototype-residue]] — deletion of deprecated hero-card and Special Offer prototype residue while keeping only the latest historical reference variant | Fixed |
| 139 | [[block-139-delete-superseded-combat-prototype-set]] — deletion of the superseded A/B/C combat prototype set plus the dead launcher and extra B2-v2 intermediate branch | Fixed |
| 140 | [[block-140-delete-orphan-feature-prototype-residue]] — deletion of ownerless feature prototype residue that no longer had a live reference role | Fixed |
| 141 | [[block-141-prototype-reference-doc-sync]] — docs sync removing live references to deleted prototype residue and closing one later-resolved retro cleanup task | Fixed |
| 142 | [[block-142-delete-wiki-obsidian-editor-residue]] — deletion of local Obsidian editor-state files from `wiki/` to restore wiki inventory count parity | Fixed |
| 143 | [[block-143-delete-final-special-offer-prototype-reference]] — deletion of the last retained Special Offer prototype after its remaining live-consumer role disappeared | Fixed |
| 144 | [[block-144-delete-victory-rewards-prototype-set]] — deletion of the standalone victory-rewards animation prototype and its duplicate local reward-art bundle | Fixed |
| 145 | [[block-145-delete-gold-mine-minigame-prototype-reference]] — deletion of the Gold Mine minigame HTML prototype after the historical plan stopped needing it as a live dependency | Fixed |
| 146 | [[block-146-delete-legal-transition-prototype-copies]] — deletion of the local legal transition HTML copies plus operations-doc wording cleanup for hosted legal ownership | Fixed |
| 147 | [[block-147-delete-final-combat-history-prototypes]] — deletion of the final B2/B2-v3 combat-history HTML artifacts after the implementation plans were converted to historical-reference mode | Fixed |
| 148 | [[block-148-root-dated-qa-and-ui-audit-relocation]] — relocation of the dated root QA report and responsiveness audit into `qa-reports/` and `docs/07_ui_ux/` | Fixed |
| 149 | [[block-149-root-combat-history-doc-relocation]] — relocation of the root combat audit/plan history into `docs/features/combat/` plus dead prototype-link cleanup | Fixed |
| 150 | [[block-150-root-gold-mine-doc-relocation]] — relocation of the root Gold Mine plan/balance docs into `docs/features/gold-mine/` plus code-reference path parity | Fixed |
| 151 | [[block-151-root-release-audit-relocation]] — relocation of the historical root pre-release audit into `docs/10_operations/` | Fixed |
| 152 | [[block-152-root-bootstrap-and-ignore-parity]] — root bootstrap compaction for `CLAUDE.md` plus closure of the old `.gitignore` parity warning after the root cleanup wave | Fixed |
| 153 | [[block-153-ios-talent-detail-sheet-slot-aware-picker-unification]] — slot-aware unification of detail-sheet equip flow with the active-skill picker plus replacement-target selection inside the picker itself | Fixed |
| 154 | [[block-154-backend-pvp-match-start-prisma-create-parity]] — removal of the stale Prisma `create as any` workaround in interactive PvP match-start plus narrowing of the remaining workaround tail | Fixed |
| 155 | [[block-155-backend-pvp-strike-complete-prisma-json-parity]] — removal of the remaining interactive PvP Prisma `findUnique/updateMany as any` workaround tail via explicit JSON-boundary typing | Fixed |
| 156 | [[block-156-stale-audit-tail-quests-and-interactive-pvp-sync]] — truth-sync cleanup for stale audit warnings around daily quests typing and interactive PvP strike recovery/parity | Fixed |
| 157 | [[block-157-stale-audit-tail-contraband-and-social-challenges-sync]] — truth-sync cleanup for stale audit warnings around contraband reward-path parity and social-challenges typing debt | Fixed |
| 158 | [[block-158-backend-item-stat-authority-rolled-stats-parity]] — backend stat-authority fix wiring rolled stats into inventory/stash snapshots, upgrade deltas, derived stats, and gear score | Fixed |
| 159 | [[block-159-ios-game-init-item-stat-preview-parity]] — game-init and iOS item-model parity fix so cold-start inventory carries authoritative stats and rolled gear no longer inflates upgrade preview deltas | Fixed |
| 160 | [[block-160-ios-strike-reveal-partial-implementation-boundary]] — strike-reveal truth-sync aligning live verdict UI, remaining proposal phases, and retained prototype references | Fixed |
| 161 | [[block-161-auth-reset-password-surface-parity]] — auth password-reset truth-sync aligning the repo-owned email template, hosted reset page, and public docs | Fixed |
| 162 | [[block-162-daily-login-reward-toast-tail-removal]] — removal of the leftover daily-login success toast so CLAIMED modal is the only reward surface on the happy path | Fixed |
| 163 | [[block-163-hub-tutorial-quest-reward-modal-parity]] — hub tutorial quest claim moved from success toast to the shared CLAIMED reward ceremony | Fixed |
| 164 | [[block-164-ios-gold-mine-bonus-reward-modal-parity]] — gold-mine slot-bonus and collect reward surfaces unified under the existing mine reward modal | Fixed |
| 165 | [[block-165-ios-upgrade-stat-bonus-config-fallback-parity]] — game-init config now exports upgrade-stat bonus so iOS local item fallback math stops assuming a hard-coded `+1` | Fixed |
| 166 | [[block-166-ios-referral-apply-reward-modal-parity]] — referral code apply bonus moved from success toast to the shared CLAIMED reward ceremony | Fixed |
| 167 | [[block-167-ios-mail-claim-reward-modal-parity]] — inbox mail attachment claim now uses the shared CLAIMED reward ceremony instead of a silent success path | Fixed |
| 168 | [[block-168-backend-character-progression-derived-stats-transaction-parity]] — allocate-stats, buy-stat-points, respec, and prestige now recalculate derived stats inside the write transaction | Fixed |
| 169 | [[block-169-stale-audit-tail-item-stat-preview-sync]] — stale inventory warning removed after later iOS item-stat parity fixes already closed the old `+1` fallback drift | Fixed |
| 170 | [[block-170-backend-appearance-wallet-response-boundary]] — appearance response now exposes canonical `wallet.gold` while the iOS client prefers the new field and legacy `character.gold` stays as a compatibility alias | Fixed |
| 171 | [[block-171-project-git-helper-tracked-only-staging]] — project git helpers now stage tracked changes by default and require explicit opt-in before sweeping untracked files into operator commits | Fixed |
| 172 | [[block-172-audio-and-asset-doc-boundary-parity]] — sound catalog and asset consistency docs now state their historical/planning role instead of pretending old `.mp3` and `512px` assumptions are live runtime truth | Fixed |
| 173 | [[block-173-admin-design-system-dead-preview-export-removal]] — deleted dead `HeroWidgetPreviews` and `StanceDisplayPreviews` exports from the legacy admin design-system preview surface after confirming the page already uses the Figma-derived variants | Fixed |
| 174 | [[block-174-stale-audit-tail-prototype-decision-sync]] — old `block-121` prototype/legal records now reflect that the final keep/delete decisions were already resolved by later cleanup blocks | Fixed |
| 175 | [[block-175-wiki-opponent-profile-and-onboarding-feature-pages]] — added the missing `opponent-profile` and `onboarding` feature pages so the last `block-122` dead-end links now resolve as first-class atlas pages | Fixed |
| 176 | [[block-176-stale-audit-tail-audio-bootstrap-boundary-sync]] — old `download_sounds.py` drift warning in `block-006` now reflects the later audio-doc boundary cleanup and no longer stays open as a stale false alarm | Fixed |
| 177 | [[block-177-stale-audit-tail-item-balance-cross-process-sync]] — old `block-047` cross-process freshness warning now reflects the later admin proxy cutover that moved item-balance profile writes onto the backend canonical route | Fixed |
| 178 | [[block-178-stale-audit-tail-tutorial-migration-sync]] — old tutorial-migration `Needs review` records in `block-009` now reflect the later replay-state backfill and route-guard repairs | Fixed |
| 179 | [[block-179-instant-retro-local-state-de-tracking]] — moved mutable instant-retro state out of tracked `.claude/skills` into ignored `.claude/tmp` storage and deleted the tracked JSON from the working tree | Fixed |
| 180 | [[block-180-backend-achievement-cosmetic-claim-runtime-parity]] — achievement claim runtime now grants cosmetic `title/frame` rewards end to end, returns stable cosmetic ids from both claim routes, and presents them in the iOS CLAIMED modal | Fixed |
| 181 | [[block-181-admin-achievement-cosmetic-authoring-parity]] — admin achievements authoring now exposes cosmetic `title/frame` rewards again, requires `rewardId` for them, and matches the widened live runtime contract | Fixed |
| 182 | [[block-182-backend-achievement-list-definition-text-parity]] — achievement list responses now prefer admin-authored definition `title/description` instead of stale route-local display text when live definitions provide it | Fixed |
| 183 | [[block-183-achievement-doc-count-and-reward-summary-parity]] — achievements summary docs now match the live `18`-entry catalog and the widened currency/cosmetic reward surface | Fixed |
| 184 | [[block-184-achievement-product-doc-runtime-parity]] — older product/system docs now describe the live `18`-achievement runtime, mixed reward surface, and non-resetting prestige semantics instead of the old concept model | Fixed |
| 185 | [[block-185-stale-operations-tail-env-and-landing-sync]] — closed stale deploy-audit warnings once landing/static deploy and current iOS environment targeting semantics were already documented elsewhere | Fixed |
| 186 | [[block-186-backend-guest-oauth-wallet-merge-parity]] — guest→OAuth upgrade now merges wallet state deterministically and keeps the longer-lived daily gem card instead of dropping or overwriting value | Fixed |
| 187 | [[block-187-backend-forgot-password-canonical-host-fallback]] — forgot-password now falls back to the canonical production backend host instead of the stale temporary Vercel domain when `NEXT_PUBLIC_APP_URL` is unset | Fixed |
| 188 | [[block-188-auth-link-account-surface-parity]] — auth docs now describe `/auth/link-account` as the narrower local profile-link compatibility route it actually is, instead of the live guest→social upgrade surface | Fixed |
| 189 | [[block-189-backend-link-account-duplicate-email-guard]] — `/auth/link-account` now guards duplicate-email collisions explicitly and returns `409` instead of leaking a generic database failure | Fixed |
| 190 | [[block-190-backend-sync-user-duplicate-email-guard]] — `/auth/sync-user` now guards duplicate-email collisions explicitly and returns `409` instead of falling through to a later upsert conflict | Fixed |
| 191 | [[block-191-backend-guest-login-device-race-recovery]] — `guest-login` now deletes the fresh Supabase guest and restores the already-linked guest on `deviceId` races instead of returning an orphan local-profile-less session | Fixed |
| 192 | [[block-192-backend-guest-login-signin-failure-cleanup]] — `guest-login` now also deletes the fresh local `User` row if sign-in fails after local guest creation, so fresh guest bootstrap rolls back both sides cleanly | Fixed |
| 193 | [[block-193-backend-upgrade-guest-full-supabase-rollback]] — `upgrade-guest` now restores the previous guest auth identity fully if local persistence fails after Supabase email/password upgrade | Fixed |
| 194 | [[block-194-backend-oauth-local-init-cleanup-and-collision-guards]] — Google/Apple auth now clean up fresh Supabase users on local init failure and return `409` on duplicate-email collisions instead of generic bootstrap failure | Fixed |
| 195 | [[block-195-backend-upgrade-guest-oauth-transaction-cleanup]] — `upgrade-guest-oauth` now deletes the fresh OAuth auth user if the guest→OAuth transfer transaction fails before any local OAuth row was attached | Fixed |
| 196 | [[block-196-backend-register-local-init-cleanup]] — `register` now deletes the fresh Supabase auth user if local `User` bootstrap fails after successful create/sign-in instead of returning success with an auth-only account | Fixed |
| 197 | [[block-197-backend-login-local-row-bootstrap-parity]] — `login` now explicitly recreates missing local user rows, returns `409` on email collisions, and fails cleanly instead of issuing tokens behind a broken local identity bootstrap | Fixed |
| 198 | [[block-198-backend-auth-guest-local-row-race-recovery]] — `/auth/guest` now validates Supabase auth directly, recreates the missing local guest row, and reloads the row if a concurrent create wins the race | Fixed |
| 199 | [[block-199-backend-me-local-row-bootstrap-parity]] — `/api/me` now bootstraps a missing local user row, reloads on create races, and returns `409` on duplicate-email collisions instead of drifting into `401/404` ambiguity | Fixed |
| 200 | [[block-200-backend-pvp-history-missing-opponent-guard]] — `/pvp/history` now skips rows whose opponent relation is missing instead of crashing the whole history response | Fixed |
| 201 | [[block-201-backend-interactive-pvp-opponent-null-contract-guard]] — interactive `/pvp/strike` and `/pvp/match/complete` now fail explicitly with `409` when a row has no real `player2Id` instead of relying on nullability drift | Fixed |
| 202 | [[block-202-backend-analytics-warning-cleanup-and-inventory-marker-sync]] — removed stale lint suppressions from `backend/src/lib/analytics.ts` and corrected the inventory marker that still claimed the file was untracked | Fixed |
| 203 | [[block-203-inventory-tracked-marker-parity-for-recent-runtime-wave]] — removed stale `_(untracked)_` markers from the recent backend/iOS/prototype/wiki wave after `git ls-files` confirmed those files are already tracked | Fixed |
| 204 | [[block-204-inventory-tracked-marker-parity-for-late-auth-and-feature-pages]] — removed the remaining stale `_(untracked)_` markers from late auth audit pages, feature pages, the reward-modal decision page, and the hosted reset-password page | Fixed |
| 205 | [[block-205-analytics-doc-split-and-event-count-parity]] — analytics docs now reflect the live split between the 7-event core contract and the 8-event tutorial funnel logger, and Gold Mine planning no longer points at a non-existent analytics file | Fixed |
| 206 | [[block-206-ios-analytics-auth-provider-enum-parity]] — the iOS analytics mirror now models `authProvider` as a fixed enum instead of a raw string, matching the backend analytics contract more closely | Fixed |
| 207 | [[block-207-admin-analytics-surface-parity-and-dead-helper-removal]] — deleted the unused admin analytics helper and rewrote admin/API docs to describe the narrower live stats/economy/IAP review surface instead of a standalone analytics dashboard | Fixed |
| 208 | [[block-208-project-overview-analytics-surface-parity]] — `PROJECT_OVERVIEW.md` now describes the narrower live analytics/review surface honestly and keeps retention/session dashboards in future-work territory | Fixed |
| 209 | [[block-209-ios-analytics-scaffold-boundary-sync]] — the iOS analytics layer is now documented as a dormant typed scaffold rather than an already-wired live instrumentation surface | Fixed |
| 210 | [[block-210-combat-telemetry-doc-proposal-boundary-sync]] — combat telemetry docs now describe interactive-combat events as a future analytics extension rather than a live event family already backed by the current analytics contract | Fixed |
| 211 | [[block-211-admin-settings-and-system-surface-parity]] — `ADMIN_CAPABILITIES.md` now reflects the actual live settings/system surface instead of promising standalone audit/performance/system-status pages and custom-role tooling that do not exist yet | Fixed |
| 212 | [[block-212-orchestrator-and-doc-index-admin-analytics-parity]] — `ORCHESTRATOR.md` and `DOCUMENTATION_INDEX.md` now use the same narrower admin analytics/settings language as the live admin capabilities doc | Fixed |
| 213 | [[block-213-backend-analytics-scaffold-boundary-sync]] — the generic backend analytics layer is now documented as a dormant typed scaffold; the live instrumentation path today is tutorial structured logging, not `track(...)` call-sites | Fixed |
| 214 | [[block-214-delete-orphan-admin-review-routes]] — deleted orphan backend admin review routes for `stats`, `economy`, and `iap`, while retaining the live `iap-products` catalog route and syncing docs/generated route maps to the narrower admin-owned review flow | Fixed |
| 215 | [[block-215-shop-feature-map-iap-products-admin-surface-parity]] — the shop feature map now names the dedicated `IAP Products` admin page and its proxy/backend chain instead of hiding it behind a generic admin-tuning note | Fixed |
| 216 | [[block-216-admin-monetization-wording-vs-live-iap-products-surface]] — admin monetization docs now describe `IAP Products` as a read-only catalog review surface instead of implying live SKU management in the dashboard | Fixed |
| 217 | [[block-217-admin-economy-review-vs-fantasy-analytics-dashboard]] — `ADMIN_CAPABILITIES.md` now describes the real economy review dashboard instead of a full retention/LTV/telemetry analytics suite, and `PROJECT_OVERVIEW.md` no longer implies a dedicated live Daily Gem Card config surface | Fixed |
| 218 | [[block-218-admin-push-surface-vs-live-campaign-sender]] — the admin push docs now describe the actual broadcast/segment/user campaign sender instead of a richer lifecycle-marketing suite with A/B tests, recurring sends, and open/click analytics | Fixed |
| 219 | [[block-219-admin-feature-flags-targeting-surface-parity]] — the feature-flags docs now match the live environment + level/class/userId targeting model instead of implying a richer beta-tester/platform/region cohort builder | Fixed |
| 220 | [[block-220-admin-balance-and-offers-surface-parity]] — the balance/loot/offers/config/item-balance sections now describe the actual live admin tools instead of broader scheduling, forecasting, A/B pricing, or experiment-profile surfaces that the dashboard does not ship | Fixed |
| 221 | [[block-221-admin-items-crud-surface-parity]] — the items docs now match the live form/upload/preview/delete surface instead of promising CSV tooling, change history, soft-delete warnings, or 3D preview | Fixed |
| 222 | [[block-222-admin-player-appearance-mail-and-footer-surface-parity]] — the remaining players/appearances/mail/footer sections now describe the actual live admin surfaces instead of promising soft delete, 3D preview, scheduled mail, or generic undo/CSV tooling | Fixed |
| 223 | [[block-223-admin-arena-dungeons-assets-surface-parity]] — the arena/matches, dungeons, and assets docs now match the real review/editor/browser surfaces instead of promising fraud ops, forecast tooling, template saves, or richer asset-pipeline features | Fixed |
| 224 | [[block-224-admin-gameplay-systems-surface-parity]] — the skills/passives/quests/events/seasons docs now match the real CRUD/editor surfaces instead of promising simulators, drag-tree tooling, seasonal planners, participation analytics, or battle-pass control flows that those screens do not ship | Fixed |
| 225 | [[block-225-admin-consumables-achievements-and-snapshots-surface-parity]] — the consumables/achievements/snapshots docs now match the real catalog/config, definition/stats, and create/rollback/delete surfaces instead of promising standalone CRUD, richer template builders, or snapshot diff tooling | Fixed |
| 226 | [[block-226-admin-dashboard-and-economy-overview-surface-parity]] — the dashboard/economy overview docs now match the real KPI/alerts/charts/review surfaces instead of promising broader real-time ops, inline leaderboard, faucet-sink, or exploit-alert features that those pages do not ship | Fixed |
| 227 | [[block-227-admin-role-settings-and-security-wording-parity]] — the roles/settings/security docs now match the real fixed-role auth model, admin-only settings flow, simulation-history surface, and narrower audit/rollback semantics instead of reading like a stricter enterprise permissions matrix | Fixed |
| 228 | [[block-228-admin-remaining-page-surface-inventory-parity]] — the remaining live admin sidebar routes now have first-class capability coverage, and the bottom page inventory finally includes the real battle-pass, daily-login, IAP, matchmaking, minigame, referrals, social, dungeon-map, and design-system surfaces | Fixed |
| 229 | [[block-229-admin-tech-stack-and-data-fetching-parity]] — the bottom admin implementation summary now reflects the actual Next.js 15 + Recharts + server-action/direct-fetch model instead of implying a repo-wide React Query, websocket, and debounced-autosave stack | Fixed |
| 230 | [[block-230-project-overview-liveops-and-admin-surface-parity]] — `PROJECT_OVERVIEW.md` now matches the cleaned admin/liveops truth instead of preserving older claims about a 30-day daily-login cycle, A/B-testing infrastructure, delivered push analytics, and broader admin tooling than the current repo ships | Fixed |
| 231 | [[block-231-auth-feature-map-admin-surface-parity]] — the auth feature map now points at the real admin login/players/settings surfaces instead of the deleted `admin/src/app/(dashboard)/users/` tree | Fixed |
| 232 | [[block-232-source-of-truth-documentation-index-admin-workflow-parity]] — `DOCUMENTATION_INDEX.md` now routes admin/balance/content workflows through the real mix of live admin surfaces and backend-owned sources instead of treating `ADMIN_CAPABILITIES.md` like a universal config-key registry | Fixed |
| 233 | [[block-233-feature-maps-daily-login-and-referral-admin-boundary-sync]] — the daily-login and referral feature maps now point at the real admin pages and current 7-day / read-only review surfaces instead of older “if present” wording | Fixed |
| 234 | [[block-234-feature-maps-leaderboard-and-dungeon-rush-admin-boundary-sync]] — the leaderboard and Dungeon Rush feature maps now point at the real adjacent admin review pages instead of phantom dedicated admin routes or room-catalog tooling | Fixed |
| 235 | [[block-235-feature-maps-minigames-and-social-runtime-boundary-sync]] — the minigames and social feature maps now point at the real view-model/admin/helper/test ownership instead of speculative shared services, broader guild helpers, or moderation-console wording | Fixed |
| 236 | [[block-236-inventory-summary-and-section-header-parity]] — the project inventory now matches current git-derived summary counts and no longer carries obviously stale section-header totals after the late cleanup wave | Fixed |
| 237 | [[block-237-feature-maps-liveops-test-fixture-boundary-sync]] — the quests, battle-pass, mail, and events feature maps now describe the actual checked-in backend test surface instead of older `__tests__/* (if present)` placeholders | Fixed |
| 238 | [[block-238-inventory-untracked-marker-parity-after-git-state-shift]] — the project inventory now reflects the current narrow untracked set after the git-state shift, removing stale `_(untracked)_` markers and adding the real untracked backend test file | Fixed |
| 239 | [[block-239-feature-maps-auth-character-tutorial-progression-boundary-sync]] — the auth, tutorial, characters, stamina, and prestige feature maps now point at the real backend test files and real adjacent admin surfaces instead of placeholder `__tests__/*` notes and phantom admin trees | Fixed |
| 240 | [[block-240-feature-maps-runtime-test-and-admin-surface-sync]] — the remaining runtime-heavy feature maps now point at the real backend test files and precise live admin pages instead of broad directory shorthand and leftover `__tests__/*` placeholders | Fixed |
| 241 | [[block-241-feature-map-pvp-combat-test-and-admin-boundary-sync]] — the PvP combat feature map now points at the real backend PvP tests and the precise live admin review surfaces instead of a generic `__tests__` placeholder and broad `admin/src/app/` wording | Fixed |
| 242 | [[block-242-source-of-truth-ownership-and-residual-surface-wording-sync]] — source-of-truth ownership and the last small feature-map wording tails now reflect the current repo instead of `[TBD]` owners, broad admin shorthand, and over-claimed prestige client parity | Fixed |
| 243 | [[block-243-api-reference-runtime-and-admin-surface-parity]] — `API_REFERENCE.md` now matches the live shop, Gold Mine, backend-admin, and admin-local route surfaces instead of carrying stale IAP wording, incomplete minigame coverage, and a misleading `NOT IMPLEMENTED` graveyard | Fixed |
| 244 | [[block-244-feature-map-and-ui-plan-residual-boundary-sync]] — the remaining stash/achievements shorthand and Strike Reveal “if present” QA wording now point at the current repo instead of broader directory notes and a nonexistent snapshot-test target | Fixed |
| 245 | [[block-245-project-overview-feature-flag-model-parity]] — `PROJECT_OVERVIEW.md` now describes `FeatureFlag` as the live rollout/targeting model instead of collapsing it back into A/B-testing shorthand | Fixed |
| 246 | [[block-246-admin-capabilities-freshness-metadata-sync]] — `ADMIN_CAPABILITIES.md` now carries the same 2026-04-19 freshness stamp as the audit wave that rewrote its live admin surface map | Fixed |
| 247 | [[block-247-active-doc-freshness-metadata-sync]] — the remaining active operations/UI docs now carry current freshness metadata instead of looking older than the audit wave that already revalidated their content | Fixed |
| 248 | [[block-248-inventory-marker-parity-after-tracked-state-rollforward]] — the inventory summary and `_untracked_` markers now match the latest git rollforward where blocks `237–246` became tracked and only the newest audit pages remain outside version control | Fixed |
| 249 | [[block-249-schema-reference-count-parity]] — `SCHEMA_REFERENCE.md` now reports the live Prisma schema counts instead of undercounting the current field surface in its header summary | Fixed |
| 250 | [[block-250-rules-doc-freshness-and-count-parity]] — the active rules docs now carry current freshness metadata, and `DEVELOPMENT_RULES.md` no longer hardcodes stale content-size counts in a structural design section | Fixed |
| 251 | [[block-251-economy-docs-v3-parity-and-monetization-transition-sync]] — the active economy docs now match live v3 gem sinks, monetization transition reality, and balance narrative constants instead of preserving older v2/v3 hybrid numbers and stale premium wording | Fixed |
| 252 | [[block-252-audio-runtime-boundary-and-lore-freshness-sync]] — the active audio/lore product docs now match the shipped audio runtime, current Settings controls, and already-live Guild Hall foundation instead of preserving a no-audio-yet snapshot and pre-guild wording | Fixed |
| 253 | [[block-253-game-systems-overview-runtime-parity-and-count-de-brittling]] — `GAME_SYSTEMS.md` is now a durable live overview again, with stale numeric tables removed and exact system constants delegated back to the narrower economy, balance, combat, and feature-map source-of-truth docs | Fixed |
| 254 | [[block-254-onboarding-spec-historical-boundary-sync]] — `ONBOARDING_SPEC.md` now reads as the historical planning snapshot it actually is, with live onboarding/tutorial authority handed back to the runtime feature maps and backend tutorial helpers | Fixed |
| 255 | [[block-255-guild-system-spec-historical-boundary-sync]] — `GUILD_SYSTEM_SPEC.md` now reads as the broader historical guild draft it actually is, while `wiki/features/social.md` points back to the real draft file and the narrower shipped social runtime surfaces | Fixed |
| 256 | [[block-256-active-skill-picker-spec-and-passive-tree-slot-parity]] — `ACTIVE_SKILL_PICKER_SPEC.md` now reads as picker rollout history instead of the live runtime spec, and the passive-tree feature map now reflects the shipped base-3 plus premium-fourth-slot model instead of older generic slot-count planning | Fixed |
| 257 | [[block-257-building-unlock-schedule-runtime-parity]] — the iOS building unlock mirror now matches the live backend tutorial/progression cadence again, and the adjacent building-gating docs/tutorial map no longer preserve conflicting unlock-truth metadata | Fixed |
| 258 | [[block-258-feature-map-game-systems-doc-reference-parity]] — the remaining feature maps no longer point at the deleted `docs/06_game_systems/GAME_SYSTEMS.md` path and now route readers back to the live overview or the correct historical docs | Fixed |
| 259 | [[block-259-inventory-marker-parity-after-late-tracked-rollforward]] — the project inventory now matches the latest git rollforward again, removing stale `_untracked_` markers from restored admin routes, retro notes, and audit blocks `247–256` so only the newest audit pages remain outside version control | Fixed |
| 260 | [[block-260-combat-feature-map-memory-boundary-sync]] — the combat feature maps now use checked-in rollout/deferred-work docs and plain runtime truth instead of depending on external memory-note references for Interactive Combat and PvP context | Fixed |
| 261 | [[block-261-feature-map-memory-note-repo-truth-sync]] — the remaining feature maps now preserve migration/response-shape/optimistic-UI lessons directly or through checked-in audit blocks instead of leaning on external memory-note names | Fixed |

## Status Legend

- **OK** — file has a clear role and no immediate action.
- **Fixed** — safe issue found and corrected.
- **Needs review** — issue or uncertainty needs product/architecture decision.
- **Deprecated** — candidate to remove after confirming it is not referenced.

## Rules

- Record role, dependencies, inbound usage, business rules, issues, fixes, unresolved decisions, and status for every audited file.
- Prefer safe mechanical fixes during audit.
- Do not delete prototypes/reports/assets without explicit confirmation; mark candidates first.
