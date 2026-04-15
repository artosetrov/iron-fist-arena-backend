# Hexbound Wiki — Log

## [2026-04-14] init | Wiki created

Initial population from existing documentation:
- **Sources processed:** `docs/06_game_systems/BALANCE_CONSTANTS.md`, `docs/06_game_systems/COMBAT.md`, `docs/02_product_and_features/ECONOMY.md`, `docs/02_product_and_features/GAME_SYSTEMS.md`, `docs/07_ui_ux/SCREEN_INVENTORY.md`, `docs/07_ui_ux/DESIGN_SYSTEM.md`
- **Pages created:** 14 (7 systems, 4 decisions, 2 entities, 1 schema)
- **Key wiki-links established:** 48 cross-references
- **Missing pages noted:** 7 (all resolved below)

## [2026-04-14] ingest | Fill missing pages

Resolved all 7 missing wiki-link targets:
- **Systems created:** `[[stance-system]]`, `[[passive-tree]]`, `[[gold-mine]]`
- **Decisions created:** `[[why-k-factor-48]]`, `[[why-rogue-execute]]`, `[[why-diminishing-refills]]`
- **Entities created:** `[[design-system]]`
- **Sources used:** StanceSelectorViewModel.swift, PassiveTree.swift, PassiveTreeViewModel.swift, GoldMineViewModel.swift, DarkFantasyTheme.swift, balance.ts, elo.ts, COMBAT.md, ECONOMY_RULES.md
- **Total pages:** 21 (10 systems, 7 decisions, 3 entities)
- **Zero broken wiki-links remaining**

## [2026-04-14] ingest | Retros + feature docs + archive

Processed 23 retros (2026-03-21 to 2026-04-13), 12 feature doc directories, balance audit archive.
- **Pages created:** `[[design-principles]]`, `[[bug-patterns]]`, `[[balance-audit-findings]]`, `[[interactive-combat]]`, `[[social]]`, `[[achievements]]`
- **Sources processed:** all `docs/retro/*.md`, `docs/features/*/`, `docs/11_archive/BALANCE_AUDIT_REPORT_2026-03-09.md`, `docs/09_rules_and_guidelines/UI_UX_PRINCIPLES.md`
- **Key findings:** 7 recurring bug patterns documented, 5 open balance issues flagged, interactive combat telemetry gates captured, social system limits quantified
- **Total pages:** 27 (13 systems, 10 decisions, 3 entities)

## [2026-04-14] lint | Index count clarified

Clarified `wiki/index.md` footer to distinguish tracked files from wiki pages:
- **30 files:** 28 wiki pages plus `index.md` and `log.md`
- **28 wiki pages:** 13 systems, 11 decisions, 3 entities, and `schema.md`
- **Indexed:** `[[why-auto-generated-balance-docs]]`, which was linked from `[[design-principles]]`

## [2026-04-14] audit | Project inventory started

Started file-by-file project audit:
- **Created:** `[[project-file-inventory]]` with 4754 in-scope files grouped by top-level block
- **Created:** `[[audit-index]]` to track audit blocks and statuses
- **Scope:** Git-tracked files plus untracked project files; vendor/build/cache artifacts excluded unless committed

## [2026-04-14] audit | Block 001 root files

Completed root-level file audit:
- **Created:** `[[block-001-root-files]]`
- **Files audited:** 27 root files
- **Fixes:** redacted secret literal in historical audit, removed duplicate legal-page font imports, added missing decorative image alt attributes in combat prototypes, marked stale plans as historical/superseded/implemented-with-drift
- **Open decisions:** move/archive root prototypes, move root QA reports into proper docs folders, refresh current release-readiness audit

## [2026-04-14] audit | Block 002 repo automation

Completed repository automation audit:
- **Created:** `[[block-002-repo-automation]]`
- **Files audited:** 28 files under `.github/`, `.cursor/`, and `.skills/`
- **Fixes:** added CI schema-drift and balance-doc checks, realigned Cursor globs to active Combat/Economy/Deploy paths, removed unsafe broad-staging deploy guidance, added post-stage `.env` deploy guard, made skill scanners macOS-compatible, fixed preflight pbxproj threshold/untracked coverage, bounded retrospective git-log scans
- **Open decisions:** merge duplicated retrospective metrics scripts, decide CI coverage for iOS/design-system drift, address Swift/UI debt reported by static scan

## [2026-04-14] audit | Block 003 Claude operational safety

Completed first `.claude/` safety sub-block:
- **Created:** `[[block-003-claude-operational-safety]]`
- **Files audited:** 21 files covering local Claude settings, duplicated operational skills/scripts, doc-keeper, and remove-background tooling
- **Fixes:** sanitized tracked `.claude/settings.local.json`, added it to `.gitignore`, synchronized duplicated runnable scripts from `.skills`, removed macOS-incompatible grep snippets from doc-keeper, softened unsafe gatekeeper examples, and removed automatic `pip --break-system-packages` dependency installation from `remove_bg.py`
- **Open decisions:** rotate credentials that appeared in git history, remove/de-track `.claude/settings.local.json`, choose canonical skill tree between `.claude/skills` and `.skills/skills`

## [2026-04-15] audit | Block 004 Claude product and governance skills

Completed second `.claude/` sub-block:
- **Created:** `[[block-004-claude-product-governance-skills]]`
- **Files audited:** 53 files covering product, QA, security, release, economy, design-review, and governance skill docs
- **Fixes:** made CDO optional and explicit-request only, replaced unsafe agent-bus cleanup examples, converted `qa-audit` from mandatory parallel agents to audit streams, converted `error-scanner` commands to `rg`, marked QA addenda as historical snapshots, reframed economy historical issues as regression checks, bounded instant-retro git-log guidance, and removed remaining auto-spawn wording from chronicler duplicates
- **Inventory refresh:** updated current counts to 4765 in-scope files and added new graph-move files/docs/wiki page to `[[project-file-inventory]]`
- **Open decisions:** revalidate March 25 QA findings, decide whether CDO belongs in this project repo, move mutable `last-retro.json` to local state, decide whether ignored agent-bus protocol files should be tracked or generated

## [2026-04-15] audit | Block 005 Claude Figma and design-system skills

Completed third `.claude/` sub-block:
- **Created:** `[[block-005-claude-figma-design-system-skills]]`
- **Files audited:** 62 files covering Figma workflows, Code Connect, design-system automation, and helper scripts
- **Fixes:** moved temporary Code Connect output into ignored `.claude/tmp/`, removed guidance to ignore the real project `scripts/` folder, tightened dynamic-code execution rules, replaced fragile `grep` audits with `rg`, corrected broken skill/reference links, converted Figma library helper scripts from private plugin-data keys to shared plugin-data keys, and marked stale DS/Figma counts and file-key assumptions as historical defaults requiring revalidation
- **Inventory refresh:** updated current counts to 4766 in-scope files and added the new audit page to `[[project-file-inventory]]`
- **Open decisions:** confirm current Figma file keys and `.component-contracts` source of truth, decide whether stale historical DS/Figma snapshots should be archived or regenerated from current assets

## [2026-04-15] audit | Block 006 project scripts

Completed shared tooling/script audit:
- **Created:** `[[block-006-project-scripts]]`
- **Files audited:** 10 files under `scripts/`
- **Fixes:** expanded `check_schema_drift.py` from `@map(...)`-only coverage to all scalar/enum Prisma fields, hardened Git helper scripts to use repo-relative roots/current branch/stale-lock checks, made watcher asset sync opt-in, taught `export-assets-for-figma.sh` to export `jpg/jpeg/pdf` assets atomically, fixed Python 3.7 compatibility plus skipped/downloaded accounting in `download_sounds.py`, and added clearer precondition checks to `sync-figma-tokens.*`
- **Verification:** shell syntax, Python compile, Node syntax, iOS/backend drift check, design-system drift check, and schema drift check all pass after changes
- **Open decisions:** decide whether Git auto-push helpers belong in the shared repo, refresh or archive the sound bootstrap flow against the current WAV-first catalog, and choose a canonical design-token drift workflow between `ds-drift-check.py` and `sync-figma-tokens.*`

## [2026-04-15] audit | Block 007 backend root and Prisma foundation

Completed backend config/Prisma foundation audit:
- **Created:** `[[block-007-backend-root-prisma-foundation]]`
- **Files audited:** 21 backend root + top-level Prisma files
- **Fixes:** filled missing runtime env variables in `backend/.env.example`, stopped `seed-battle-pass.ts` from rolling the live season window on re-run, typed battle-pass reward seed values to the supported literal set, documented that `db:seed` is only the core seed in `backend/prisma/MIGRATIONS.md`, removed a hardcoded Supabase asset origin from `seed.ts`, added stronger bootstrap/reset warnings to passive-tree SQL and feature seeds, and cleaned small dead/lint-only seed code
- **Verification:** targeted ESLint for audited backend files, `prisma validate`, battle-pass repair tests, schema drift check, design-system drift check, and iOS/backend drift check all pass
- **Open decisions:** decide whether battle-pass rewards and boss abilities should move from free-form strings to stronger schema-level typing, and whether backend bootstrap should gain a first-class "full feature data" orchestration entrypoint

## [2026-04-15] audit | Block 008 Prisma migrations baseline and early deltas

Completed first Prisma migration-history audit block:
- **Created:** `[[block-008-prisma-migrations-baseline-early-deltas]]`
- **Files audited:** 11 migration-history files
- **Fixes:** added missing `backend/prisma/migrations/migration_lock.toml`, added `20260415_add_missing_event_type_values/migration.sql` to repair missing `EventType` enum values in migration history, and extended `scripts/check_schema_drift.py` so it now validates enum values plus migration-lock presence in addition to columns/indexes
- **Verification:** enum-history parity now matches `schema.prisma`, `python3 scripts/check_schema_drift.py --verbose` passes with enum coverage, and `git diff --check` passes
- **Open decisions:** decide whether content bootstrap belongs in migration SQL or canonical seed scripts, and review raw `TIMESTAMPTZ` usage in `20260327_guild_challenges_milestones`

## [2026-04-15] audit | Block 009 Prisma migrations onboarding, gold, and W3.D5

Completed second Prisma migration-history audit block:
- **Created:** `[[block-009-prisma-migrations-onboarding-gold-and-w3d5]]`
- **Files audited:** 9 migration-history files
- **Fixes:** added `20260415_backfill_tutorial_completion_state/migration.sql` to reconcile legacy/skip tutorial rows with `tutorial_completed`, and patched tutorial skip + scripted-fight preload/resolve routes so replay guards now treat `tutorialCompleted`, `tutorialSkipped`, and `tutorialStep >= 3` consistently
- **Verification:** targeted ESLint for patched tutorial routes, `python3 scripts/check_schema_drift.py --verbose`, and `git diff --check` all pass
- **Open decisions:** reduce tutorial completion state duplication, decide whether `users.device_id` needs both unique and plain indexes, and avoid future multi-concern feature-bundle migrations like `20260410_w3d5_tiers_weekly_premium`

## [2026-04-15] audit | Block 010 Prisma migrations hotfixes, stash, interactive combat, and premium

Completed third Prisma migration-history audit block:
- **Created:** `[[block-010-prisma-migrations-hotfixes-stash-interactive-premium]]`
- **Files audited:** 13 migration-history files
- **Fixes:** removed the nested duplicate hotfix file `backend/prisma/migrations/20260411_hotfix_gold_mine_minigame_variant_d_phase2/_hidden_hotfix/migration.sql`, and extended `scripts/check_schema_drift.py` so it now fails on hidden/nested artifacts inside migration directories in addition to columns/indexes/enums
- **Verification:** `python3 scripts/check_schema_drift.py --verbose`, `python3 -m py_compile scripts/check_schema_drift.py`, and `git diff --check` all pass
- **Open decisions:** define a clean policy for manual-first parity migrations like `20260414_premium_subscription`, and avoid future catch-up monoliths like `20260413_fix_schema_drift`

## [2026-04-15] audit | Block 011 backend passives and interactive combat runtime

Completed first backend runtime block after migration history:
- **Created:** `[[block-011-backend-passives-interactive-combat-runtime]]`
- **Files audited:** 11 backend runtime/helper files
- **Fixes:** corrected passive cache invalidation so shared helper paths now clear the live `passives:char:v2:*` cache key, fixed interactive active cooldown handling so the just-fired slot is not decremented in the same round, and stopped opponent AI from selecting a currently no-op `stun_enemy` action
- **Verification:** targeted backend ESLint for passives/interactive-combat files and `git diff --check` both pass
- **Open decisions:** centralize active-slot consumable constants/metadata, document passive cache-key ownership, and clean up remaining Prisma stale-client workarounds in interactive PvP routes

## [2026-04-15] audit | Block 012 backend stash, contraband, and premium runtime

Completed second backend runtime block after migration history:
- **Created:** `[[block-012-backend-stash-contraband-premium-runtime]]`
- **Files audited:** 6 backend runtime/helper files
- **Fixes:** moved stash deposit/withdraw capacity checks into locked transactions to remove overfill races, taught `daily-login/claim` to honor active Premium Pass subscriptions in addition to `premiumUntil`, and cleaned touched routes of a few unnecessary `any` casts
- **Verification:** targeted backend ESLint for stash/contraband/premium files and `git diff --check` both pass
- **Open decisions:** audit the rest of premium reward/gold-bonus callers for subscription parity, and introduce a shared shop reward helper so contraband/offers XP grants can handle level-up consistently

## [2026-04-15] audit | Block 013 backend reward premium parity

Completed third backend runtime block after migration history:
- **Created:** `[[block-013-backend-reward-premium-parity]]`
- **Files audited:** 13 backend runtime/helper files
- **Fixes:** centralized premium-aware user selection in `premium.ts`, migrated PvP/dungeon/rush/challenge reward routes to the shared entitlement shape, taught `/me` and `/game/init` to serialize effective premium expiry for subscription users, fixed guest→OAuth upgrade to preserve `premiumSubscription`, and cleaned dead locals/imports in several touched routes
- **Verification:** targeted backend ESLint over the audited files reports 0 errors and only legacy `social/challenges` typing warnings; `python3 scripts/check_schema_drift.py --verbose` and `git diff --check` both pass
- **Open decisions:** define broader guest-account merge policy beyond premium entitlement, and replace the remaining `any` payload shaping in `social/challenges`

## [2026-04-15] audit | Block 014 shared reward grants, shop/mail claims, and rush sync

Completed fourth backend/runtime parity block:
- **Created:** `[[block-014-shared-reward-grants-shop-mail-rush-sync]]`
- **Files audited:** 12 backend/iOS runtime/model files
- **Fixes:** added shared `reward-grants.ts` for mixed reward payloads, moved shop offers / contraband / mail claim / Dungeon Rush reward paths onto authoritative level-up-aware grant flow, fixed silent `item`/attachment drops, made Dungeon Rush combat-room progression atomic with reward persistence, and synced iOS shop/inbox/rush state to returned gold/xp/level/stat-point data
- **Verification:** targeted backend ESLint passes, `python3 scripts/check_schema_drift.py --verbose` passes, `git diff --check` passes, and `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds
- **Inventory refresh:** updated current counts to 4779 in-scope files and added the new audit page/helper file to `[[project-file-inventory]]`
- **Open decisions:** add stricter DTO validation for reward JSON payloads and consider a shared iOS reward-sync helper for `AppState.currentCharacter`

## [2026-04-15] audit | Block 015 claim progression for achievements, quests, and battle pass

Completed the next claim/progression runtime block:
- **Created:** `[[block-015-claim-progression-achievements-quests-battle-pass]]`
- **Files audited:** 21 backend/iOS runtime/model files
- **Fixes:** added shared `achievement-claims.ts`, moved achievement + daily quest claim flows onto shared reward grants, closed the daily bonus double-claim race, unified battle pass currency/item reward grants with cache invalidation on level-up, taught battle pass iOS claim flow to honor full multi-reward responses, and fixed touched reward consumers to preserve `previousLevel` when opening the level-up modal
- **Verification:** targeted `next lint` over touched backend files passes with only pre-existing `quests/daily/route.ts` legacy `any` warnings; `python3 scripts/check_schema_drift.py --verbose` passes; `git diff --check` passes; `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds
- **Inventory refresh:** updated current counts to 4781 in-scope files and added the new audit page/helper file to `[[project-file-inventory]]`
- **Open decisions:** type `quests/daily/route.ts`, centralize battle pass reward-name formatting, and continue `previousLevel` rollout to the remaining non-claim level-up surfaces

## [2026-04-15] audit | Block 016 daily login, battle pass reward contracts, and client reward sync

Completed the next reward-contract/runtime block:
- **Created:** `[[block-016-backend-daily-login-battle-pass-reward-contracts]]`
- **Files audited:** 13 backend/iOS runtime/model files
- **Fixes:** extracted shared backend reward label formatting for battle pass GET/claim parity, upgraded `daily-login/claim` to return the full reward display + post-claim status contract plus authoritative `gold/gems`, switched iOS daily login claim flow to typed server-driven reward modal construction, added shared `AppState.applyAuthoritativeRewardState()` for local reward/progression sync, and moved touched shop/inbox/rush/battle-pass consumers onto that shared path with inventory-cache invalidation where rewards can add items/consumables
- **Verification:** targeted backend `next lint` passes with no warnings or errors; `python3 scripts/check_schema_drift.py --verbose` passes; `git diff --check` passes; `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds
- **Inventory refresh:** updated current counts to 4783 in-scope files and added the new audit page/helper file to `[[project-file-inventory]]`
- **Open decisions:** migrate remaining refresh-based claim services (`achievements`, `quests`) onto typed authoritative sync, and document system-wide reward response conventions for delta vs absolute totals

## [2026-04-15] audit | Block 017 iOS claim services and authoritative reward sync

Completed the next iOS reward-contract/runtime block:
- **Created:** `[[block-017-ios-claim-services-authoritative-reward-sync]]`
- **Files audited:** 10 backend/iOS runtime/view files
- **Fixes:** moved `AchievementService` and `QuestService` off raw claim parsing plus refresh-after-claim, added typed quest/achievement claim DTOs with authoritative totals, updated the achievements screen plus all touched quest claim consumers (`DailyQuestsViewModel`, hub reward widget, active quest banner) to use shared `AppState.applyAuthoritativeRewardState()`, and cleaned stale comments that still described the pre-fix refresh flow
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds, `git diff --check` passes, and wiki links remain valid after adding the new block page
- **Inventory refresh:** updated current counts to 4784 in-scope files and added the new audit page to `[[project-file-inventory]]`
- **Open decisions:** move remaining achievement/quest GET loaders to typed DTOs, extract a shared reward-ceremony builder, and document system-wide reward response conventions for iOS/backend consumers

## [2026-04-15] audit | Block 018 typed achievement and quest loaders

Completed the next typed-contract cleanup block:
- **Created:** `[[block-018-ios-typed-achievements-quests-loaders]]`
- **Files audited:** 6 backend/iOS service/model files
- **Fixes:** replaced achievement and daily-quest list `getRaw + JSONSerialization` loaders with typed `APIClient.get(...)` DTO wrappers, preserved backward compatibility for the legacy achievements `data` wrapper, and restored explicit `QuestServiceError.decoding` mapping so decode failures remain distinct from network failures
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4785 in-scope files and added the new audit page to `[[project-file-inventory]]`
- **Open decisions:** continue the typed-loader pass into other stable raw-JSON services and document which endpoints are contract-stable versus intentionally dynamic

## [2026-04-15] audit | Block 019 iOS contract fixes for battle pass, shop, and leaderboard

Completed the next typed-contract cleanup block:
- **Created:** `[[block-019-ios-contract-fixes-battle-pass-shop-leaderboard]]`
- **Files audited:** 14 backend/iOS route/model/service files
- **Fixes:** replaced raw iOS loaders for battle pass, shop items, and leaderboard with typed `APIClient.get(...)` DTO wrappers, removed conflicting snake_case `CodingKeys` from live reward DTOs used by contraband/mail/special offers, aligned battle-pass DTOs with the shared decoder contract, and patched `GameInitService` quest decoding to keep bootstrap compatible after the DTO cleanup
- **Verification:** `rg -n "leveled_up|new_level|stat_points_awarded" Hexbound/Hexbound/Models -g '*.swift'` no longer reports the active reward DTOs fixed in this block, `git diff --check` passes, and `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds
- **Inventory refresh:** updated current counts to 4786 in-scope files and added the new audit page to `[[project-file-inventory]]`
- **Open decisions:** continue into `InventoryService` and document system-wide iOS/backend contract authoring rules beyond the existing `[[bug-patterns]]` note

## [2026-04-15] audit | Block 020 inventory typed snapshots and legacy consumable parity

Completed the next inventory/runtime contract block:
- **Created:** `[[block-020-inventory-typed-snapshots-legacy-consumables]]`
- **Files audited:** 8 backend/iOS route/helper/service/model files
- **Fixes:** replaced inventory snapshot raw parsing on iOS with typed DTOs, removed the stale equipment-only merge workaround from `InventoryViewModel` now that equip/unequip consume the full authoritative snapshot, and updated the legacy `/api/inventory/use` path to resolve canonical `ConsumableType` values and shared stamina/health potion effects instead of relying on stamina-only `itemName` tables
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds, `npx eslint src/app/api/inventory/use/route.ts` passes from `/backend`, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4787 in-scope files and added the new audit page to `[[project-file-inventory]]`
- **Open decisions:** extract a shared consumable catalog helper for iOS display metadata and resolve the remaining drift between backend `effectiveStats` and client-side item stat recomputation

## [2026-04-15] audit | Block 021 item stat authority and shared consumable catalog

Completed the next inventory/stash stat-authority block:
- **Created:** `[[block-021-item-stat-authority-consumable-catalog]]`
- **Files audited:** 9 backend/iOS helper/model/service/view files
- **Fixes:** added shared `ConsumableCatalog.swift` for consumable names/rarity/icons/image-key remaps, threaded backend `effectiveStats` through inventory and stash item mapping via `Item.authoritativeEffectiveStats`, replaced stash raw flattening with typed DTO decoding, and removed hard-coded `+1` upgrade preview from the item-detail sheet in favor of a best-effort increment derived from authoritative stats when available
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds, `rg -n "consumableDisplayNames|consumableImageKeys|knownItemKeys|legacyKeyRemap|pot_stamina_small|pot_health_small" Hexbound/Hexbound -g '*.swift'` now points at the new shared helper instead of parallel client maps, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4789 in-scope files and added the new audit page plus `ConsumableCatalog.swift` to `[[project-file-inventory]]`
- **Open decisions:** backend inventory/stash snapshots still compute `effectiveStats` from `baseStats` only, so rolled-stat authority needs one explicit contract decision

## [2026-04-15] audit | Block 022 iOS active-skill picker and passive-tree contracts

Completed the next passive-tree/runtime block:
- **Created:** `[[block-022-ios-active-skill-picker-passive-tree-contracts]]`
- **Files audited:** 10 backend/iOS route/model/service/view files
- **Fixes:** made the active-skill picker honor the tapped slot as the explicit replacement target, added preview-strip focus highlighting plus replacement-aware room checks, blocked silent slot-0 overwrite when the detail sheet tries to equip into a full loadout, and removed the last raw request bodies from `PassiveTreeService` by converting single-slot and batch loadout mutations to typed DTOs
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds, `rg -n "postRaw|getRaw|JSONSerialization|NSNull" Hexbound/Hexbound/Services/PassiveTreeService.swift` returns no matches, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4790 in-scope files and added the new audit page to `[[project-file-inventory]]`
- **Open decisions:** unify detail-sheet equip/unequip with picker ownership, and normalize the currently untracked picker source files as tracked product code after the graph/file move

## [2026-04-15] audit | Block 023 interactive combat terminal state and round log

Completed the next interactive-combat runtime block:
- **Created:** `[[block-023-ios-interactive-combat-terminal-state-and-round-log]]`
- **Files audited:** 10 backend/iOS route/model/view-model/view files
- **Fixes:** corrected `RoundExchange` numbering on iOS (`strikeIndex + 1`), moved interactive combat terminal-state/winner derivation onto server-authoritative `match_finished` / `winner_id` semantics so max-round HP% wins no longer mis-route or mislabel the summary, reset stale per-match HUD/log state on fresh `/match/start`, and fixed the active HUD accessibility label for already-consumed potion slots
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds, `rg -n "max\\(1, response\\.strikeIndex\\)|serverFinished|serverWinnerId|winnerId == vm.state.attackerId" Hexbound/Hexbound/Models/InteractiveCombatModels.swift Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift Hexbound/Hexbound/Views/Combat/BattleSummaryView.swift` confirms the old round-number bug is gone and the server-terminal-state path is wired, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4791 in-scope files and added the new audit page to `[[project-file-inventory]]`
- **Open decisions:** define graceful reconciliation for the `OUT_OF_CONSUMABLE` mid-match edge case instead of dropping the duel into a generic error path

## [2026-04-15] audit | Block 024 interactive combat consumable recovery

Completed the next interactive-combat contract/recovery block:
- **Created:** `[[block-024-interactive-combat-consumable-recovery]]`
- **Files audited:** 6 backend/iOS route/model/view-model files
- **Fixes:** `/pvp/match/start` now excludes consumable slots whose inventory quantity is already zero, `/pvp/strike` now reconciles `OUT_OF_CONSUMABLE` into a recoverable 409 payload with updated actives instead of a dead-end 400, and `InteractiveBattleViewModel` now consumes that payload, clears the queued slot, restarts predict, and keeps the duel alive instead of dropping to terminal `.error`
- **Verification:** `npx eslint src/app/api/pvp/match/start/route.ts src/app/api/pvp/strike/route.ts` passes, `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4792 in-scope files and added the new audit page to `[[project-file-inventory]]`
- **Open decisions:** decide whether zero-quantity potion slots should also be auto-cleaned in the out-of-combat loadout editor, not only at match start / strike reconciliation

## [2026-04-15] audit | Block 025 backend active-slot consumable ownership reconciliation

Completed the next passive-tree/runtime consistency block:
- **Created:** `[[block-025-backend-active-slot-consumable-ownership-reconciliation]]`
- **Files audited:** 5 backend route/helper files
- **Fixes:** made active-slot consumables server-authoritative on real ownership by rejecting single-slot and batch saves for potions with zero quantity, added shared `lib/game/active-slots.ts` for the canonical active-slot allowlist plus cache invalidation, taught `/api/passives/active-slots` to reconcile cached/live slot payloads against fresh ownership and prune impossible zero-quantity potion rows, and invalidated or cleaned the same slot state from `/api/consumables/use` and `/api/pvp/strike`
- **Verification:** `npx eslint src/app/api/passives/active-slots/route.ts src/app/api/passives/active-slots/batch/route.ts src/app/api/consumables/use/route.ts src/app/api/pvp/strike/route.ts src/lib/game/active-slots.ts` passes and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4794 in-scope files and added the new audit page plus shared helper file to `[[project-file-inventory]]`
- **Open decisions:** decide whether repurchasing a potion should auto-restore a previously pruned active slot or continue requiring explicit re-equip

## [2026-04-15] audit | Block 026 backend shop consumable pricing parity

Completed the next shop/economy consistency block:
- **Created:** `[[block-026-backend-shop-consumable-pricing-parity]]`
- **Files audited:** 6 backend/iOS contract files
- **Fixes:** added shared `backend/src/lib/game/consumable-pricing.ts` as the canonical direct-sale consumable allowlist plus GameConfig-backed fallback pricing helper, aligned `/api/shop/items`, `/api/shop/buy-consumable`, `/api/shop/buy-potion`, and `/api/passives/active-slots` to the same pricing source, filtered reward-only consumables out of the regular shop listing, and closed the direct-API loophole that allowed `protection_scroll` / `legendary_shard` through `buy-consumable`
- **Verification:** `npx eslint src/lib/game/consumable-pricing.ts src/app/api/passives/active-slots/route.ts src/app/api/shop/buy-consumable/route.ts src/app/api/shop/buy-potion/route.ts src/app/api/shop/items/route.ts` passes and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4796 in-scope files and added the new audit page plus shared helper file to `[[project-file-inventory]]`
- **Open decisions:** if higher potion prices from later economy notes are still desired, roll them out explicitly through `GameConfig` and docs instead of route-local fallback drift

## [2026-04-15] audit | Block 027 shop legacy client surface and pricing docs

Completed the next shop/docs cleanup block:
- **Created:** `[[block-027-shop-legacy-client-surface-and-pricing-docs]]`
- **Files audited:** 6 iOS/backend/docs/wiki files
- **Fixes:** removed dead iOS references to the unused `shopBuyPotion` route from `APIEndpoints.swift` and `ShopService.swift`, documented `/api/shop/buy-consumable` as the canonical client-facing consumable purchase route while keeping `/api/shop/buy-potion` explicitly labeled legacy compatibility, and clarified in wiki economy/rebalance pages that current repo-visible potion fallback pricing still follows the seeded catalog unless `GameConfig` overrides are present
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4797 in-scope files and added the new audit page to `[[project-file-inventory]]`
- **Open decisions:** decide whether backend `/api/shop/buy-potion` should stay indefinitely as compatibility surface or be retired after a version cutoff

## [2026-04-15] audit | Block 028 backend contraband reward contract build fix

Completed a focused backend build-blocker fix:
- **Created:** `[[block-028-backend-contraband-reward-contract-build-fix]]`
- **Files audited:** 2 backend reward-contract files
- **Fixes:** aligned `shop/contraband` loot generation with the shared `RewardGrantEntry` contract, removed local type widening to `{ type: string }[]`, added explicit JSON serialization for persisted claim contents, and restored production-build compatibility for the contraband reward-grant path without weakening shared reward typing
- **Verification:** `npm run build` in `backend/` succeeds and `git diff --check` passes after the patch
- **Inventory refresh:** updated current counts to 4798 in-scope files and added the new audit page to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 029 backend CI premium mock drift tests

Completed a focused GitHub Actions failure fix:
- **Created:** `[[block-029-backend-ci-premium-mock-drift-tests]]`
- **Files audited:** 4 CI/test/runtime contract files
- **Fixes:** reproduced the GitHub-only failure locally, confirmed the workflow itself was fine, added the missing `PREMIUM_ENTITLEMENT_USER_SELECT` export to the `premium` mocks in `pvp-resolve` and `dungeon-rush-resolve` tests, and updated the rush test transaction mock to match the shared `grantRewardEntries(...)` contract
- **Verification:** `npx vitest run tests/api/pvp-resolve.test.ts tests/api/dungeon-rush-resolve.test.ts` passes, full `npx vitest run` passes in `backend/` (`26/26` files, `236/236` tests), `npm run docs:balance:check` passes, `npx next build` passes in `admin/`, `python3 scripts/check_schema_drift.py` passes, backend/admin Prisma schemas match, and `npm run build` passes in `backend/`
- **Inventory refresh:** updated current counts to 4799 in-scope files and added the new audit page to `[[project-file-inventory]]`
