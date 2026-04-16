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

## [2026-04-15] audit | Block 030 backend CI contract hardening and actions upgrade

Completed the follow-up hardening pass on the same CI surface:
- **Created:** `[[block-030-backend-ci-contract-hardening-and-actions-upgrade]]`
- **Files audited:** 4 CI/test/runtime contract files
- **Fixes:** converted the premium mocks in `pvp-resolve` and `dungeon-rush-resolve` tests from fragile full mocks to partial `importOriginal` mocks so future `premium.ts` exports do not break CI again, aligned the rush test fixture shape with the shared premium selector, and upgraded GitHub workflow actions from `actions/checkout@v4` / `actions/setup-node@v4` to `@v5` to remove current deprecation warnings
- **Verification:** full local CI-equivalent passes after the hardening: backend `vitest`, backend `docs:balance:check`, backend `npm run build`, admin `next build`, backend/admin Prisma schema diff, and schema drift check all succeed
- **Inventory refresh:** updated current counts to 4800 in-scope files and added the new audit page to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 031 backend route tests transaction and premium fixtures

Completed the next backend test-fixture cleanup block:
- **Created:** `[[block-031-backend-route-tests-transaction-and-premium-fixtures]]`
- **Files audited:** 5 backend API route tests
- **Fixes:** aligned `pvp-resolve` premium fixture data with the shared entitlement selector, replaced several route transaction callback mocks typed as `any` with concrete local transaction types, and tightened the `shop-buy` inventory fixture shape so the helper no longer hides returned inventory data behind `any`
- **Verification:** `npx vitest run` passes in `backend/` (`26/26` files, `236/236` tests) and `git diff --check` passes after the cleanup
- **Inventory refresh:** updated current counts to 4801 in-scope files and added the new audit page to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 032 backend API tests NextRequest helper

Completed the next route-boundary test cleanup block:
- **Created:** `[[block-032-backend-api-tests-nextrequest-helper]]`
- **Files audited:** 7 backend API tests plus 1 shared test helper
- **Fixes:** added `backend/tests/helpers/next-request.ts` to build real `NextRequest` objects for route tests, moved touched auth/stamina/minigame/battle-pass tests off repeated `Request as any` casts, and typed the adjacent `stamina-refill` / `shell-game-start` transaction callback fixtures while touching those files
- **Verification:** targeted backend Vitest for the touched files passes, full backend `npx vitest run` passes (`26/26` files, `236/236` tests), and `git diff --check` passes after the helper/test cleanup
- **Inventory refresh:** updated current counts to 4803 in-scope files and added the new helper plus audit page to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 033 backend API tests request cast elimination

Completed the next route-boundary cleanup follow-up:
- **Created:** `[[block-033-backend-api-tests-request-cast-elimination]]`
- **Files audited:** 5 backend API route tests
- **Fixes:** moved the remaining touched live API tests (`shop-buy`, `inventory-sell`, `pvp-resolve`, `dungeon-rush-resolve`, `pvp-prepare-bot-ticket`) onto the shared `makeNextRequest(...)` helper so they no longer rely on `Request as any` or `as never` at the handler boundary
- **Verification:** `rg` no longer finds the old request-cast pattern in this API test slice, targeted backend Vitest passes for the touched files, full backend `npx vitest run` passes (`26/26` files, `236/236` tests), and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4804 in-scope files and added the new audit page to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 034 backend auth bot minigame guardrail tests

Completed the next backend API test-quality block:
- **Created:** `[[block-034-backend-auth-bot-minigame-guardrail-tests]]`
- **Files audited:** 5 backend API route tests plus the adjacent auth/PvP/minigame/stamina runtime routes
- **Fixes:** removed the odd inline `vi.hoisted(...)` fixture access from `auth-login`, added direct invalid-email coverage to `auth-register`, added the missing bot-ticket happy-path assertion to `pvp-prepare-bot-ticket`, added shell-game daily-limit and insufficient-gold guard-rail tests, and added stamina-refill diminishing-returns plus daily-cap coverage
- **Verification:** targeted backend Vitest for the touched files passes, full backend `npx vitest run` passes, and `git diff --check` passes
- **Inventory refresh:** refreshed the current inventory from `git ls-files`, landing at 4797 in-scope files, and added the new audit page to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 035 backend battle pass claim test contracts

Completed the next battle-pass contract test block:
- **Created:** `[[block-035-backend-battle-pass-claim-test-contracts]]`
- **Files audited:** 1 backend API route test plus the adjacent battle-pass claim route
- **Fixes:** removed the stale `applyLevelUp` mock from the test, aligned the file with the real shared `grantRewardEntries(...)` and cache invalidator collaborators, and added focused coverage for the level gate, no-claimable state, invalid reward-config rollback, and leveled-up success path
- **Verification:** targeted Vitest for `battle-pass-claim.test.ts` passes, full backend `npx vitest run` passes, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4798 in-scope files and added the new audit page to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 036 backend dungeon rush resolve test contracts

Completed the next resolve-route contract cleanup block:
- **Created:** `[[block-036-backend-dungeon-rush-resolve-test-contracts]]`
- **Files audited:** 1 backend API route test plus the adjacent dungeon-rush resolve route
- **Fixes:** removed the stale `getBattlePassConfig` test mock, aligned the file with the current shared `grantRewardEntries(...)` boundary, updated the replay test to assert no double-grant through the shared reward helper, and added a success-path test for leveled-up reward resolution plus combat-cache invalidation
- **Verification:** targeted Vitest for `dungeon-rush-resolve.test.ts` passes, full backend `npx vitest run` passes, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4799 in-scope files and added the new audit page to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 037 backend pvp resolve test contracts

Completed the next PvP resolve contract test block:
- **Created:** `[[block-037-backend-pvp-resolve-test-contracts]]`
- **Files audited:** 1 backend API route test plus the adjacent PvP resolve route
- **Fixes:** expanded the file beyond replay protection to cover authoritative client/server winner mismatch handling, locked-row stamina TOCTOU rejection, battle-ticket mismatch rejection, and invalid bot-ticket guarding, while keeping the transaction helper local to this file per the current audit rule
- **Verification:** targeted Vitest for `pvp-resolve.test.ts` passes, full backend `npx vitest run` passes, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4800 in-scope files and added the new audit page to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 038 backend utility routes and character warning cleanup

Completed the next backend runtime warning-cleanup block:
- **Created:** `[[block-038-backend-utility-routes-and-character-warning-cleanup]]`
- **Files audited:** 7 backend runtime routes
- **Fixes:** removed dead locals and unused request parameters from the touched utility/deprecated routes, aligned the appearance change error text from “race” to “origin”, and documented the two remaining runtime concerns discovered in `appearance` and `respec-stats`
- **Verification:** targeted backend `eslint` on the touched files passes and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4801 in-scope files and added the new audit page to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 039 backend rush start shop race hardening

Completed the next backend runtime hardening block:
- **Created:** `[[block-039-backend-rush-start-shop-race-hardening]]`
- **Files audited:** 6 backend runtime routes plus the shared dungeon-run lock helper
- **Fixes:** moved active-rush detection in `dungeon-rush/start` under the character-row lock to prevent duplicate parallel run creation, moved `dungeon-rush/shop-buy` room/slot validation and state update under a locked run transaction to prevent double-charging stale slot purchases, and removed adjacent dead imports/mutable locals in `dungeons/start`, `pvp/find-match`, `pvp/prepare`, and `shop/buy-gems`
- **Verification:** targeted backend `eslint` on the touched files passes and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4802 in-scope files and added the new audit page to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 040 backend IAP receipt idempotency and webhook contracts

Completed the next backend IAP block:
- **Created:** `[[block-040-backend-iap-receipt-idempotency-and-webhook-contracts]]`
- **Files audited:** 2 live backend IAP routes plus 2 new focused API test files
- **Fixes:** hardened `verify-receipt` so a concurrent duplicate `transactionId` collision now returns the same `409 Transaction already processed` response as the pre-check path instead of a generic `500`, replaced the route’s `any[]` transaction list with typed Prisma promises, cleaned the mutable `updates` warning in `apple-notifications`, and added focused route tests for receipt idempotency, subscription seeding, webhook renewal, and safe no-op handling when the local subscription row does not exist yet
- **Verification:** targeted IAP Vitest passes, full backend `npx vitest run` passes (`28/28` files, `255/255` tests), backend `npm run build` passes, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4805 in-scope files and added the new audit page plus two IAP API tests to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 041 IAP compatibility aliases restore and iOS endpoints

Completed the next IAP compatibility/documentation block:
- **Created:** `[[block-041-iap-compatibility-aliases-restore-and-ios-endpoints]]`
- **Files audited:** 3 backend IAP compatibility routes/tests, 3 iOS storefront endpoint files, and the backend API reference page
- **Fixes:** added restore-route coverage including the legacy `/api/iap/restore` alias, added a live alias regression test for `/api/iap/verify`, switched current iOS purchase flows off raw `"/api/iap/verify"` strings onto `APIEndpoints.iapVerify`, removed dead `APIEndpoints.iapRestore`, and clarified canonical vs compatibility IAP routes in `API_REFERENCE.md`
- **Verification:** targeted backend IAP Vitest passes (`9/9` tests across the touched suites), `xcodebuild` for `Hexbound` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4807 in-scope files and added the new audit page plus the restore-route API test to `[[project-file-inventory]]`

## [2026-04-15] audit | Block 042 inventory mail and quest contract hardening

Completed the next backend runtime cleanup block:
- **Created:** `[[block-042-backend-inventory-mail-quest-contract-hardening]]`
- **Files audited:** 9 backend/runtime/test files
- **Fixes:** moved derived-stat recomputation inside the live `inventory/equip` and `inventory/unequip` transactions so committed equipment mutations no longer bubble false `500`s afterward, corrected `mail:list` to use the documented 60-second rate-limit window instead of 60 ms, replaced explicit `any` casts in the mail route, typed the remaining live quest-definition and locked-row shapes in `quests/daily/route.ts`, and added focused route tests for the new transaction and rate-limit invariants
- **Verification:** targeted backend ESLint passes, targeted inventory/mail `vitest` passes, full backend `npx vitest run` passes (`32/32` files, `262/262` tests), `npm run build` in `backend` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4811 in-scope files and `73 in-scope wiki files / 71 wiki pages`
- **Open decisions:** continue into the remaining warning-heavy backend routes (`social/*`, `shell-game/*`, helper debt) and add deeper concurrency tests if the inventory mutation layer is refactored again

## [2026-04-15] audit | Block 043 shell game transaction and session hardening

Completed the next backend minigame block:
- **Created:** `[[block-043-backend-shell-game-transaction-and-session-hardening]]`
- **Files audited:** 5 backend/runtime/test files
- **Fixes:** moved the shell-game daily play-limit check inside the locked serializable `/start` transaction so parallel starts cannot overshoot the 20/day cap, tightened `guess` session-state parsing instead of trusting blind JSON casts, replaced the remaining shell-game `any` error branch, and added focused route tests for the live guess path plus the new transaction-local limit guard
- **Verification:** targeted shell-game ESLint passes, targeted shell-game `vitest` passes, full backend `npx vitest run` passes (`33/33` files, `265/265` tests), `npm run build` in `backend` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4813 in-scope files and `74 in-scope wiki files / 72 wiki pages`
- **Open decisions:** proceed into `social/*` next, and only consider extracting shared minigame lock/session helpers after the remaining minigame routes are audited file by file

## [2026-04-15] audit | Block 044 backend social contracts and runtime hardening

Completed the next backend social block:
- **Created:** `[[block-044-backend-social-contracts-and-runtime-hardening]]`
- **Files audited:** 4 live backend social routes plus 2 focused API test files
- **Fixes:** moved direct-message send guard checks under a sender-row lock so daily-cap and anti-spam validation cannot drift under concurrency, finished the challenge accept contract by persisting duel XP inside the final locked transaction and mapping stale-state lock errors to stable `404/403/409/410` responses instead of generic `500`s, and removed the remaining loose typing in the adjacent friends/relationship route surfaces
- **Verification:** targeted backend ESLint passes, targeted social `vitest` passes, full backend `npx vitest run` passes (`35/35` files, `269/269` tests), backend `npm run build` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4816 in-scope files and `75 in-scope wiki files / 73 wiki pages`
- **Open decisions:** keep transaction helpers local until the file-by-file audit is complete, then reassess whether the social routes should be split into smaller runtime modules

## [2026-04-15] audit | Block 045 tutorial achievement and weekly contracts

Completed the next backend contract-cleanup block:
- **Created:** `[[block-045-backend-tutorial-achievement-and-weekly-contracts]]`
- **Files audited:** 5 backend/runtime files plus 3 focused test files
- **Fixes:** mapped tutorial quest sentinel errors to stable HTTP responses instead of generic `500`s, rejected invalid tutorial progress amounts before opening a transaction, typed tutorial reward definitions with canonical consumable types, prevented silent item-reward drops when a configured catalog item is missing, filtered unsupported DB achievement reward types out of the runtime catalog, corrected the live Diamond/Grandmaster achievement descriptions to the current thresholds, and tightened the weekly-challenge raw SQL helper typing with direct regression coverage
- **Verification:** targeted backend ESLint passes, targeted `vitest` passes, full backend `npx vitest run` passes (`37/37` files, `275/275` tests), backend `npm run build` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4819 in-scope files and `76 in-scope wiki files / 74 wiki pages`
- **Open decisions:** tutorial quest reward types `instant_mine` and `bp_levels` are still declared but not granted by the live claim runtime, and achievement cosmetic reward support (`title/frame`) still needs a runtime policy decision before more DB-defined rewards ship

## [2026-04-15] audit | Block 046 feature flags progression and runtime cleanup

Completed the next backend helper/runtime block:
- **Created:** `[[block-046-backend-feature-flags-progression-and-runtime-cleanup]]`
- **Files audited:** 5 backend helper/runtime files plus 2 focused lib test files
- **Fixes:** enforced feature-flag `environment` at runtime for the first time (including Vercel preview → `staging` mapping), replaced weak feature-flag targeting/value typing, narrowed the `applyLevelUp` transaction contract, removed dead combat helper state that was only creating warning noise, and hardened push broadcast filtering/error handling so Prisma-typed build paths stop failing on `any`/union misuse
- **Verification:** targeted backend ESLint passes, targeted `vitest` passes, full backend `npx vitest run` passes (`39/39` files, `279/279` tests), backend `npm run build` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4822 in-scope files and `77 in-scope wiki files / 75 wiki pages`
- **Open decisions:** Android push still has no real FCM send path, so `push/send.ts` remains only partially product-ready outside iOS

## [2026-04-15] audit | Block 047 dungeon item balance and live config hardening

Completed the next backend helper/runtime block:
- **Created:** `[[block-047-backend-dungeon-item-balance-live-config-hardening]]`
- **Files audited:** 4 backend helper/runtime files plus 2 focused lib test files
- **Fixes:** restored DB-dungeon parity by applying scheduled variety-room generation before any Prisma boss lookup, sanitized `ItemBalanceProfile.statWeights` and `item_balance.class_damage_scaling` before runtime use, added bounded TTL plus in-process invalidation to the item-balance profile cache, removed the stale `STANCE_ZONES` import from `live-config`, and added focused lib tests to lock these contracts down
- **Verification:** targeted backend ESLint passes, targeted `vitest` passes, full backend `npx vitest run` passes (`41/41` files, `284/284` tests), backend `npm run build` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4825 in-scope files and `78 in-scope wiki files / 76 wiki pages`
- **Open decisions:** the separate admin app still updates item-balance profiles from another process, so profile freshness is now bounded by TTL unless we later add cross-process cache invalidation

## [2026-04-15] audit | Block 048 admin item balance backend proxy alignment

Completed the next admin/runtime alignment block:
- **Created:** `[[block-048-admin-item-balance-backend-proxy-alignment]]`
- **Files audited:** 9 admin item-balance API routes, 5 dashboard/page/client files, 1 shared backend-proxy helper, and the surviving item-balance read-side action file
- **Fixes:** moved the live admin item-balance API surface onto thin authenticated proxies to the canonical backend admin routes, switched config/profile saves off local mutation actions and onto those proxy routes, surfaced real save errors in the profile editor instead of swallowing them, removed stale `adminId` plumbing from touched item-balance UI shells, deleted the dead duplicate `admin` runtimes (`item-validator.ts`, `combat-sim.ts`), and removed now-unused mutation actions from `admin/src/actions/item-balance.ts`
- **Verification:** targeted admin ESLint passes, `npx next build` in `admin` succeeds, `rg` confirms there are no remaining live callers of `updateBalanceConfig()` / `updateBalanceProfile()`, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4829 in-scope files and `79 in-scope wiki files / 77 wiki pages`
- **Open decisions:** read-side item-balance pages still query Prisma directly through admin actions; that is acceptable today, but strict backend-read parity may still be worth considering later if these views become contract-sensitive

## [2026-04-15] audit | Block 049 admin config canonical route and consumables live sync

Completed the next admin/config runtime block:
- **Created:** `[[block-049-admin-config-canonical-route-and-consumables-live-sync]]`
- **Files audited:** 4 backend config/runtime files, 1 focused backend route test, 2 admin config helper/action files, and the consumables admin UI
- **Fixes:** added a canonical backend `/api/admin/config` write surface with batch seeding and shared config-cache invalidation, moved admin `updateConfig()` and `seedDefaultConfigs()` writes off direct Prisma mutation and onto that backend route, added atomic `updateConfigsBatch()` for grouped saves, corrected the consumables screen so it no longer lies about runtime `GameConfig` support, and converted consumables “Save All” to a single live batch write instead of 12 sequential partial writes
- **Verification:** targeted backend and admin ESLint pass, focused backend `vitest` for `admin-config` passes, full backend `npx vitest run` passes (`42/42` files, `286/286` tests), backend `npm run build` succeeds, admin `npx next build` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4833 in-scope files and `80 in-scope wiki files / 78 wiki pages`
- **Open decisions:** `skills` and `passives` admin editors are still on direct browser→backend fetches with manual token parsing, so they remain the next proxy-alignment block

## [2026-04-15] audit | Block 050 admin skills and passives proxy alignment

Completed the next admin/runtime alignment block:
- **Created:** `[[block-050-admin-skills-passives-proxy-alignment]]`
- **Files audited:** 3 new admin proxy API routes, 2 existing dashboard editor clients, and the adjacent read-side page shells
- **Fixes:** added same-origin admin proxy routes for `skills`, `passives`, and passive `connections`, moved both editors off direct browser→backend mutation calls, removed manual browser `admin-token` parsing and duplicated backend base-URL helpers from the clients, and deleted the dead `skills-client` URL branch that built the same endpoint both ways
- **Verification:** targeted admin ESLint passes, `npx next build` in `admin` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4837 in-scope files and `81 in-scope wiki files / 79 wiki pages`
- **Open decisions:** read-side page hydration for `skills` and `passives` still goes straight to Prisma on the admin side, which is acceptable today but may be worth proxy-aligning later if those views become contract-sensitive too

## [2026-04-15] audit | Block 051 admin active config editors consistency

Completed the next admin/config consistency block:
- **Created:** `[[block-051-admin-active-config-editors-consistency]]`
- **Files audited:** 9 admin action/page/client files across `balance`, `loot`, `config`, and `daily-login`
- **Fixes:** rerouted balance batch writes and resets through the canonical backend admin-config route while keeping local snapshots/logs, converted loot save flows from sequential per-key writes to atomic batch config writes, removed stale `adminId` prop plumbing from the touched editors, stabilized the shared daily-login defaults, tightened local client typing in the daily-login editor, and corrected stale balance-screen copy that still described the pre-migration backend contract
- **Verification:** targeted admin ESLint passes, `npx next build` in `admin` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4838 in-scope files and `82 in-scope wiki files / 80 wiki pages`
- **Open decisions:** the curated balance screen still needed a parity pass against canonical seeded defaults and live category coverage, which becomes the next block

## [2026-04-15] audit | Block 052 admin balance schema parity and auth hardening

Completed the next admin balance-alignment block:
- **Created:** `[[block-052-admin-balance-schema-parity-and-auth-hardening]]`
- **Files audited:** 4 admin action/page/client files covering generic config reads plus the curated balance dashboard
- **Fixes:** added the missing admin auth guard to `getConfig()`, removed the dead `updateConfig(..., adminId)` parameter, expanded the balance read allowlist to include live `pvp_ranks`, `training_xp_dr`, `stamina_refill_dr`, `loss_streak`, `charisma`, and `repair` categories, corrected stale hardcoded balance defaults, added a dedicated editor for `stamina_refill_dr.cost_multipliers`, and rewrote balance-page copy so it no longer overclaims ownership of specialized consumable config
- **Verification:** targeted admin ESLint passes, `npx next build` in `admin` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4839 in-scope files and `83 in-scope wiki files / 81 wiki pages`
- **Open decisions:** `snapshots` and a few other admin read-side surfaces still query Prisma directly; that remains acceptable today, but they are the next likely consistency pass

## [2026-04-15] audit | Block 053 admin snapshots restore runtime hardening

Completed the next admin/runtime safety block:
- **Created:** `[[block-053-admin-snapshots-restore-runtime-hardening]]`
- **Files audited:** 1 new backend restore route, 1 focused backend route test, 1 admin snapshot action file, and the 2 dashboard snapshot page/client files
- **Fixes:** moved snapshot rollback off direct admin-side Prisma mutation and onto a canonical backend restore route with transaction-backed full replace, pre-restore auto-backup, duplicate-key validation, and live config cache invalidation; wrapped snapshot create/delete with their admin-log writes in transactions; removed weak `any` mapping, dead `adminId` plumbing, and abandoned expand/details state from the snapshots UI
- **Verification:** targeted backend ESLint passes, targeted backend `vitest` for `admin-config` and `admin-config-restore` passes (`4/4` tests), backend `npm run build` succeeds, targeted admin ESLint passes, admin `npx next build` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4842 in-scope files and `84 in-scope wiki files / 82 wiki pages`
- **Open decisions:** snapshot list/read hydration still uses direct Prisma on the admin side, which is acceptable today; the next likely admin pass is `settings` / `dashboard` / other read-heavy pages with older direct Prisma shapes and warning-heavy UI debt

## [2026-04-15] audit | Block 054 admin settings role guards and feature-flag contracts

Completed the next admin integrity block:
- **Created:** `[[block-054-admin-settings-role-guards-and-feature-flag-contracts]]`
- **Files audited:** 1 admin role-mutation route, 1 settings client, 1 new shared feature-flag helper, 1 feature-flag action file, 1 feature-flag editor client, and 3 adjacent dashboard/economy cleanup files
- **Fixes:** hardened the admin role-change API against self-demotion and last-admin lockout under transaction, added audit logging for successful role changes, introduced a shared feature-flag parsing/normalization helper for `flagType`, `environment`, `targeting`, tags, and JSON value handling, moved both the feature-flag UI and server actions onto that single contract, restored explicit support for legacy `segment` flags as targeted booleans, and removed touched warning noise from `settings`, `dashboard`, and `economy`
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4844 in-scope files and `85 in-scope wiki files / 83 wiki pages`
- **Open decisions:** admin read-shells still hydrate directly from Prisma-backed actions, which is acceptable for now; the larger remaining admin warning backlog is now concentrated in `push`, `shop-offers`, `quests`, `battle-pass`, and design-system/demo files

## [2026-04-15] audit | Block 055 admin push and shop-offer contract hardening

Completed the next admin contract block:
- **Created:** `[[block-055-admin-push-and-shop-offer-contract-hardening]]`
- **Files audited:** 2 new shared admin helper files, 2 admin action files, and the 2 corresponding dashboard editor clients for `push` and `offers`
- **Fixes:** closed an auth hole in `push` actions by requiring an authenticated admin for every read/write path, prevented malformed `user` push campaigns from falling through to the broadcast send path, normalized push targeting/data/schedule parsing through a shared helper, added typed offer/content validation for live shop bundles, blocked malformed price windows/level windows/schedule windows in `shop-offers`, and removed the touched `any`/dead-import noise from both editor clients
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4847 in-scope files and `86 in-scope wiki files / 84 wiki pages`
- **Open decisions:** the next admin warning backlog is now concentrated in `quests`, `battle-pass`, `design-system`, and a few demo/media-heavy surfaces rather than the higher-risk push/shop mutation paths

## [2026-04-15] audit | Block 057 admin achievements runtime parity

Completed the next admin content/runtime-alignment block:
- **Created:** `[[block-057-admin-achievements-runtime-parity]]`
- **Files audited:** 1 new shared admin helper, 1 achievement-definition action file, 1 achievements dashboard client, and 2 backend achievement runtime reference files
- **Fixes:** added shared validation/normalization for achievement definitions, removed weak `data as never` audit payloads, corrected stale admin seed thresholds for `rank_diamond` and `rank_grandmaster`, aligned the admin achievements editor to the live reward-claim-safe reward set (`gold/gems/xp`), removed the dead `rewardId` editor path from the UI, and replaced `alert()`-style operator feedback with toast-based success/error handling
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4854 in-scope files and `89 in-scope wiki files / 87 wiki pages`
- **Open decisions:** backend achievement catalog metadata can still represent `title/frame` while the live claim helper grants only `gold/gems/xp`; this block contained the drift at the admin authoring layer, but the deeper runtime/catalog decision still remains

## [2026-04-15] audit | Block 058 admin appearances and design-system preview consistency

Completed the next admin editor/design-system block:
- **Created:** `[[block-058-admin-appearances-and-design-system-preview-consistency]]`
- **Files audited:** 1 new shared admin helper, 2 appearances admin files, 2 runtime-reference files from backend/iOS, the admin root layout, the design-system dashboard client, and 12 Figma preview wrapper components
- **Fixes:** added shared normalization/validation for appearance-skin writes, enforced transactional single-default behavior per `origin + gender`, forced default skins to stay free, blocked deletion of default skins that would break fallback avatar behavior, replaced stale `useTransition` remnants with explicit submit/delete state in the appearances UI, moved operator feedback onto toasts, loaded `Oswald` once in the admin root via `next/font/google`, and removed component-level Google font `<link>` tags plus dead preview imports from the design-system page
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4856 in-scope files and `90 in-scope wiki files / 88 wiki pages`
- **Open decisions:** `design-system/ds-components-2.tsx` still contains likely-deprecated preview exports and `figma-components/divider.tsx` still carries its own small warning cleanup tail for a later block

## [2026-04-15] audit | Block 059 admin design-system residual debt and warning cleanup

Completed the next admin warning-cleanup block:
- **Created:** `[[block-059-admin-design-system-residual-debt-and-warning-cleanup]]`
- **Files audited:** 10 admin files across design-system, item preview, mail, social, dashboard charts, navigation, and auth helpers
- **Fixes:** removed residual dead locals/imports from `divider`, `social`, `economy-charts`, `nav-items`, and `auth`; made the design-system page copy more honest about preview fidelity; used `fallbackImageKey` in the item preview’s borrowed-art hint; and, most importantly, replaced stale transition-based async handling in `mail-client` with explicit awaited send/delete flows plus dedicated `isDeleting` state so the operator UI no longer clears loading state too early
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, `git diff --check` passes, and `rg` confirms `HeroWidgetPreviews` / `StanceDisplayPreviews` are no longer live-imported by the design-system page
- **Inventory refresh:** updated current counts to 4855 in-scope files and `91 in-scope wiki files / 89 wiki pages`
- **Open decisions:** `design-system/ds-components-2.tsx` now clearly mixes still-used previews with likely-dead exports and should get its own keep/delete pass rather than ad hoc edits

## [2026-04-15] audit | Block 060 admin dungeon map and editor runtime cleanup

Completed the next admin editor/runtime block:
- **Created:** `[[block-060-admin-dungeon-map-and-editor-runtime-cleanup]]`
- **Files audited:** 2 admin dungeon editor files
- **Fixes:** removed dead map-editor ref state, documented intentional plain `<img>` usage on the map/editor preview surfaces, and replaced the dungeon editor’s false `useTransition(async ...)` save lifecycle with a real awaited save path driven by `isSaving`
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, `git diff --check` passes, and `rg` confirms the old `useTransition/isPending` save path is gone from this slice
- **Inventory refresh:** updated current counts to 4856 in-scope files and `92 in-scope wiki files / 90 wiki pages`
- **Open decisions:** the broad admin image/editor policy is now much cleaner, but there is still more remaining UI surface outside dungeons if we want the whole admin layer equally disciplined

## [2026-04-15] audit | Block 061 admin live editors async-state hardening

Completed the next admin mutation-safety block:
- **Created:** `[[block-061-admin-live-editors-async-state-hardening]]`
- **Files audited:** 4 admin live-editor clients across seasons, events, assets, and the dungeon index
- **Fixes:** replaced false `useTransition(async ...)` loading semantics with explicit awaited `isSaving` / `isDeleting` / `isCreating` / storage-operation states, added per-row event toggle pending/error handling, made asset upload/delete await list refresh before clearing busy state, and disabled conflicting destructive controls while admin operations are in flight
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, `git diff --check` passes, and `rg` confirms the old `useTransition/isPending` pattern is gone from this slice
- **Inventory refresh:** updated current counts to 4857 in-scope files and `93 in-scope wiki files / 91 wiki pages`
- **Open decisions:** the remaining admin async-state cleanup is now more contained and mostly lives in players/items/tables and a few older editor shells rather than the higher-risk live mutation surfaces

## [2026-04-15] audit | Block 062 admin players and items async-state hardening

Completed the next admin operator-safety block:
- **Created:** `[[block-062-admin-players-items-async-state-hardening]]`
- **Files audited:** 4 admin player/item operator screens
- **Fixes:** replaced false transition-based loading semantics in player search/moderation, player grants/ban/reset actions, item deletion, and item image-upload/save flows; added explicit error rendering for player search failures; split item upload/save state; and aligned destructive/admin action labels with the actual request lifecycle
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, `git diff --check` passes, and `rg` confirms the old `useTransition/isPending` pattern is gone from this slice
- **Inventory refresh:** updated current counts to 4858 in-scope files and `94 in-scope wiki files / 92 wiki pages`
- **Open decisions:** the remaining admin async-state debt is now concentrated in fewer legacy shells and should be finished as a focused consistency pass rather than scattered single-file fixes

## [2026-04-15] audit | Block 063 admin feature flags operator feedback hardening

Completed the next admin liveops feedback block:
- **Created:** `[[block-063-admin-feature-flags-operator-feedback-hardening]]`
- **Files audited:** 1 admin feature-flag editor client
- **Fixes:** replaced `alert(...)` and console-only failure paths with inline operator feedback, added row-scoped pending state for flag toggles, separated delete-state from save-state, and made save/toggle/delete/seed actions all report outcomes through the same visible UI channel
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4859 in-scope files and `95 in-scope wiki files / 93 wiki pages`
- **Open decisions:** most high-risk admin mutation surfaces now have truthful feedback; the remaining cleanup is increasingly about finishing consistency across older utility shells rather than plugging major operator blind spots

## [2026-04-15] audit | Block 064 admin config and balance editor async-state hardening

Completed the next admin live-config integrity block:
- **Created:** `[[block-064-admin-config-and-balance-editor-async-state-hardening]]`
- **Files audited:** 5 admin config/balance editor clients across settings, generic config, consumables, loot, and curated balance
- **Fixes:** replaced false `useTransition(async ...)` loading semantics with explicit awaited save/seed state, added row-scoped role-update pending in `settings`, split row/bulk/seed state in `config` and `balance`, added dedicated bulk-save state to `consumables`, and introduced section-scoped pending state in `loot` so drop and rarity writes no longer borrow one ambiguous loading flag
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, `git diff --check` passes, and `rg` confirms the old `useTransition/isPending` pattern is gone from this slice
- **Inventory refresh:** updated current counts to 4860 in-scope files and `96 in-scope wiki files / 94 wiki pages`
- **Open decisions:** the remaining admin async-state debt is now concentrated in older shells such as `snapshots`, `skills`, `passives`, and `tables`, rather than the core live config/balance screens

## [2026-04-15] audit | Block 065 admin snapshots and item-balance editor async-state hardening

Completed the next admin operator-trust block:
- **Created:** `[[block-065-admin-snapshots-and-item-balance-editor-async-state-hardening]]`
- **Files audited:** 3 admin clients across snapshots, item-balance config, and item-balance profiles
- **Fixes:** replaced the generic snapshot pending state with explicit create/rollback/delete tracking, removed leftover transition-based refresh state from both item-balance editor screens, kept item-balance saves on their existing row-scoped identifiers, and aligned action labels/disabled states with the actual mutation in flight
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, `git diff --check` passes, and `rg` confirms the old `useTransition/isPending` pattern is gone from this slice
- **Inventory refresh:** updated current counts to 4861 in-scope files and `97 in-scope wiki files / 95 wiki pages`
- **Open decisions:** the next obvious admin async-state pass is now `skills`, `passives`, and then the remaining generic `tables` shell

## [2026-04-15] audit | Block 066 admin skills and passives editor async-state hardening

Completed the next admin editor-consistency block:
- **Created:** `[[block-066-admin-skills-and-passives-editor-async-state-hardening]]`
- **Files audited:** 2 admin combat-content editor clients
- **Fixes:** removed leftover transition-based pending state from both the skills editor and the passive-tree editor, split skill save/delete into explicit editor states, split passive-tree mutations into separate node-save, node-delete, connection-create, and connection-delete states, and aligned row/dialog controls with the real mutation currently running
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, `git diff --check` passes, and `rg` confirms the old `useTransition/isPending` pattern is gone from this slice
- **Inventory refresh:** updated current counts to 4862 in-scope files and `98 in-scope wiki files / 96 wiki pages`
- **Open decisions:** the remaining obvious admin async-state shell is now `tables/[tableName]`; after that the backlog becomes much more incremental

## [2026-04-15] audit | Block 067 admin generic table shell mutation hardening

Completed the next admin shell-safety block:
- **Created:** `[[block-067-admin-generic-table-shell-mutation-hardening]]`
- **Files audited:** the generic table shell plus its shared data-table and dynamic-form dependencies
- **Fixes:** wrapped create/update/delete handlers in `try/catch/finally` so thrown server-action errors cannot strand the shell in `isMutating`, separated navigation pending from mutation pending conceptually by keeping transition state only for routing/refresh, and restricted table dimming to navigation state instead of mixing it with mutation state
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, `git diff --check` passes, and `rg` confirms remaining transition usage in the shell is navigation-only
- **Inventory refresh:** updated current counts to 4863 in-scope files and `99 in-scope wiki files / 97 wiki pages`
- **Open decisions:** only a few small transition-wrapped refresh helpers remain in specialized admin screens; the large admin async-state cleanup is effectively down to residual polish rather than broad structural debt

## [2026-04-15] audit | Block 068 admin achievements and item-balance operator feedback

Completed the next residual admin polish block:
- **Created:** `[[block-068-admin-achievements-and-item-balance-operator-feedback]]`
- **Files audited:** 2 admin dashboard/editor clients
- **Fixes:** removed routine `console.error(...)` noise from the achievements admin error path, added explicit validation-error rendering to the item-balance dashboard quick-validation card, and removed the extra transition-wrapped refresh helper from that dashboard screen
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, `git diff --check` passes, and `rg` confirms the touched files no longer carry the old console/transition leftovers
- **Inventory refresh:** updated current counts to 4864 in-scope files and `100 in-scope wiki files / 98 wiki pages`
- **Open decisions:** remaining admin work is now mostly localized TODOs, a handful of intentionally kept console logs on server-side/API paths, and broader whole-project file-by-file completion outside this admin slice

## [2026-04-15] audit | Block 071 iOS hub, daily login, and level-up contract cleanup

Completed the next iOS runtime-truth block:
- **Created:** `[[block-071-ios-hub-daily-login-and-levelup-contract-cleanup]]`
- **Files audited:** 4 live/residual iOS files plus cache/catalog/progression reference files
- **Fixes:** removed mock battle-pass values from `HubInfoCards`, wired the residual battle-pass card to cached live data, corrected daily-login HP potion icon mapping to real health-potion assets, routed consumable icon fallback through `ConsumableCatalog`, removed a stale battle-pass TODO comment, and simplified `LevelUpModalView` so it no longer shows invented passive-point and stamina-refill rewards
- **Verification:** targeted grep over touched iOS files, `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, and `git diff --check`
- **Inventory refresh:** updated current counts to 4867 in-scope files and `103 in-scope wiki files / 101 wiki pages`
- **Open decisions:** `HubInfoCards.swift` still looks like a residual surface and deserves a later keep/delete pass; backend progression already computes `passivePointsAwarded`, but the iOS-facing level-up contract still needs an explicit end-to-end decision before that reward is shown again

## [2026-04-15] audit | Block 069 admin residual transition and copy cleanup

Completed the next tiny admin polish block:
- **Created:** `[[block-069-admin-residual-transition-and-copy-cleanup]]`
- **Files audited:** 1 admin feature-flag client and 1 dashboard chart component
- **Fixes:** removed the last unnecessary transition-wrapped refresh helper from the feature-flag editor and replaced leaked `TODO` copy in the retention card with honest operator-facing wording
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, `git diff --check` passes, and `rg` confirms the touched files no longer contain the old transition/TODO leftovers
- **Inventory refresh:** updated current counts to 4865 in-scope files and `101 in-scope wiki files / 99 wiki pages`
- **Open decisions:** the broad admin slice is now mostly in residual-polish territory; the next large value likely comes from returning to remaining non-admin project areas rather than squeezing more tiny admin cleanups

## [2026-04-15] audit | Block 070 admin events API auth gap

Completed the next admin security block:
- **Created:** `[[block-070-admin-events-api-auth-gap]]`
- **Files audited:** 1 admin API route
- **Fixes:** added missing `getAdminUser()` guards to `GET`, `POST`, `PATCH`, and `DELETE` in the admin events route so unauthenticated callers now receive `401 Unauthorized` instead of reaching live event reads/writes
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, `git diff --check` passes, and a route-parity grep confirms the events route now matches the surrounding admin API auth pattern
- **Inventory refresh:** updated current counts to 4866 in-scope files and `102 in-scope wiki files / 100 wiki pages`
- **Open decisions:** the next security/contract value is likely in the remaining non-admin project slices; the admin API surface is now much more uniformly guarded

## [2026-04-15] audit | Block 056 admin quests and battle-pass alignment

Completed the next live admin content block:
- **Created:** `[[block-056-admin-quests-and-battle-pass-contract-alignment]]`
- **Restored:** missing on-disk `[[block-032-backend-api-tests-nextrequest-helper]]` page so the wiki matches the audit index again
- **Files audited:** 6 admin quest/battle-pass files plus 1 backend claim-route reference file
- **Fixes:** routed quest-definition create/update/seed through shared normalization and range/reward validation, replaced weak quest client error/numeric handling, added a safe activate/deactivate control, aligned admin battle-pass reward types to the live backend-supported set, added `rewardId` create/edit support, narrowed bulk generation error swallowing to duplicate-only cases, replaced `window.location.reload()` with authoritative reward refetch, and fixed the table so both free and premium rewards are deletable
- **Verification:** targeted admin ESLint passes, full `npx next build` in `admin` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4851 in-scope files and `88 in-scope wiki files / 86 wiki pages`
- **Open decisions:** battle-pass inline editing is now contract-safe, but a more guided `rewardType -> rewardId` transition UX would still be a nice operator upgrade later

## [2026-04-15] audit | Block 072 progression passive-points contract parity

Completed the next cross-system progression block:
- **Created:** `[[block-072-progression-passive-points-contract-parity]]`
- **Files audited:** 15 backend reward/resolve routes, 5 core iOS progression/result files, 14 iOS DTO/consumer files, plus progression/tutorial reference files
- **Fixes:** exposed `passive_points_awarded` from the touched backend claim, purchase, PvP, dungeon, and Dungeon Rush level-up surfaces; added `passivePointsAwarded` to the corresponding iOS DTOs; extended `AppState.applyAuthoritativeRewardState(...)` so character state now increments `passivePointsAvailable`; re-enabled passive-point display in `LevelUpModalView` only when the value is actually server-backed; and repaired direct combat/dungeon victory flows so passive-point awards are no longer dropped before the ceremony
- **Verification:** `npm run build` in `backend`, full `npx vitest run` in `backend` (`43/43` files, `288/288` tests), `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `rg -n 'passive_points_awarded|passivePointsAwarded' backend/src/app/api Hexbound/Hexbound -g'*.ts' -g'*.swift'`, and `git diff --check`
- **Inventory refresh:** updated current counts to 4868 in-scope files and `104 in-scope wiki files / 102 wiki pages`
- **Open decisions:** tutorial progression payloads still use a camelCase nested level-up shape while the main API uses snake_case, and backend level-up response assembly is still duplicated across many routes instead of living behind a shared helper

## [2026-04-15] audit | Block 073 tutorial scripted-fight contract and victory parity

Completed the next onboarding-contract block:
- **Created:** `[[block-073-tutorial-scripted-fight-contract-and-victory-parity]]`
- **Files audited:** 2 backend tutorial routes, 1 new backend route-test file, 3 live iOS onboarding files, plus progression/app-state references
- **Fixes:** added canonical snake_case tutorial route fields (`forced_stance`, `level_up`, `item_catalog_key`, `sanity_check_passed`) while preserving legacy camelCase aliases for compatibility; updated `TutorialService` to prefer canonical keys but still accept the older aliases; removed dead local tutorial resolve fields that onboarding never used; and carried real `statPointsAwarded` / `passivePointsAwarded` through `TutorialRewardsPayload` so the first-fight victory overlay now shows the full truthful level-up reward instead of only `LEVEL N REACHED`
- **Verification:** targeted `npx vitest run tests/api/tutorial-scripted-fight-contracts.test.ts tests/api/tutorial-quest.test.ts` in `backend`, `npm run build` in `backend`, `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, and `git diff --check`
- **Inventory refresh:** updated current counts to 4870 in-scope files and `105 in-scope wiki files / 103 wiki pages`
- **Open decisions:** tutorial progression still uses a nested progression object while most live reward routes use top-level progression fields, and `TutorialService` would still benefit from a future move off raw dictionary parsing entirely

## [2026-04-15] audit | Block 074 tutorial referral rate-limit and storage parity

Completed the next tutorial/referral runtime block:
- **Created:** `[[block-074-tutorial-referral-rate-limit-and-storage-parity]]`
- **Files audited:** 3 backend tutorial/referral routes, 1 backend helper file, 1 new backend route-test file, plus the iOS referral consumer reference
- **Fixes:** repaired inverted referral rate-limit semantics and the broken `60ms` window, normalized referral codes before lookup, canonicalized new `referredBy` writes to the referrer's `character_id`, made referral stats/counts compatible with both legacy code-based links and canonical character-id links, aligned tutorial start/skip with the same max-referral policy, and added transaction-backed regression coverage for mixed-storage counting plus canonical referral writes
- **Verification:** targeted backend ESLint, targeted tutorial/referral `vitest`, full backend `npx vitest run` (`45/45` files, `293/293` tests), `npm run build` in `backend`, and `git diff --check`
- **Inventory refresh:** updated current counts to 4872 in-scope files and `106 in-scope wiki files / 104 wiki pages`
- **Open decisions:** referrer rewards at the invitee level threshold are still not granted anywhere in live runtime even though the constants and stats surface already imply that behavior

## [2026-04-15] audit | Block 075 referral qualification rewards and idempotency

Completed the next referral/runtime block:
- **Created:** `[[block-075-referral-qualification-rewards-and-idempotency]]`
- **Files audited:** 2 backend runtime files, 1 Prisma schema file, 1 new migration, and 2 backend test files
- **Fixes:** added `ReferralRewardClaim` as the idempotent persistence layer for referral qualification payouts, created the matching Prisma migration, implemented `awardReferralQualificationIfEligible(...)` in tutorial helpers, wired the payout into shared `applyLevelUp(...)` so it works across all common progression flows, and added direct regression coverage for one-time referral qualification rewards plus duplicate-claim handling
- **Verification:** targeted backend ESLint, targeted referral reward `vitest`, full backend `npx vitest run` (`46/46` files, `295/295` tests), `npm run build` in `backend`, `python3 scripts/check_schema_drift.py --verbose`, and `git diff --check`
- **Inventory refresh:** updated current counts to 4875 in-scope files and `107 in-scope wiki files / 105 wiki pages`
- **Open decisions:** future payouts are now correct, but a separate product decision is still needed on whether to backfill already-qualified invitees from before this block

## [2026-04-16] audit | Block 076 referral reward backfill tooling

Completed the referral repair-safety block:
- **Created:** `[[block-076-referral-reward-backfill-tooling]]`
- **Files audited:** 2 backend Prisma repair files, 1 new backend Prisma test file, and 2 backend operator-surface files
- **Fixes:** added `backfillReferralRewardClaims(...)` for historical referral payout reconciliation, added CLI wrapper `fix-referral-rewards.ts` with dry-run default and explicit `--apply`, covered mixed legacy/canonical referral resolution plus aggregated apply-mode currency updates in focused Prisma tests, and documented the repair commands in `backend/prisma/MIGRATIONS.md`
- **Verification:** targeted backend ESLint, targeted referral repair `vitest`, full backend `npx vitest run` (`47/47` files, `297/297` tests), `npm run build` in `backend`, `python3 scripts/check_schema_drift.py --verbose`, and `git diff --check`
- **Inventory refresh:** updated current counts to 4879 in-scope files and `108 in-scope wiki files / 106 wiki pages`
- **Open decisions:** decide when to run the live `--apply` repair and where to archive the dry-run/apply summaries for future economy auditability

## [2026-04-16] audit | Block 077 iOS referral and tavern typed contract cleanup

Completed the next iOS contract-cleanup block:
- **Created:** `[[block-077-ios-referral-and-tavern-typed-contract-cleanup]]`
- **Files audited:** 1 shared iOS model file and 3 live iOS referral/minigame view-model or view files
- **Fixes:** added typed request/response DTOs for Fortune Wheel and Shell Game, moved those live tavern flows off raw `getRaw/postRaw` dictionaries, switched Fortune Wheel status to canonical `params:`-based GET instead of manual query-string concatenation, and upgraded `ReferralSectionView` to typed request/response contracts plus payload-based error handling for `alreadyReferred` and `invalidCode`
- **Verification:** `rg -n "getRaw\\(|postRaw\\(|JSONSerialization" ...` over the touched files returns clean, `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds, and `git diff --check` passes
- **Inventory refresh:** updated current counts to 4880 in-scope files and `109 in-scope wiki files / 107 wiki pages`
- **Open decisions:** `DungeonService`, `DungeonSelectViewModel`, `DungeonRushViewModel`, and `TutorialManager` are the next obvious iOS typed-contract cleanup slice

## [2026-04-16] audit | Block 078 iOS tutorial manager typed contract cleanup

Completed the next iOS onboarding-contract block:
- **Created:** `[[block-078-ios-tutorial-manager-typed-contract-cleanup]]`
- **Files audited:** 1 iOS onboarding state manager and 2 live hub tutorial-quest consumers
- **Fixes:** migrated `TutorialManager` off `getRaw/postRaw` and `[[String: Any]]` tutorial state onto typed tutorial DTOs and request bodies; converted hub and city-map tutorial quest consumers to `TutorialQuestState`; limited tutorial failure logging to `#if DEBUG`; and fixed the quest-claim toast path so it now reads the real backend `goldDelta` contract instead of the stale `goldAwarded` field
- **Verification:** `rg -n "getRaw\\(|postRaw\\(|\\[String: Any\\]" Hexbound/Hexbound/Tutorial/TutorialManager.swift`, `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, and `git diff --check`
- **Inventory refresh:** updated current counts to 4881 in-scope files and `110 in-scope wiki files / 108 wiki pages`
- **Open decisions:** `DungeonService`, `DungeonSelectViewModel`, and `DungeonRushViewModel` remain the next typed-contract cleanup slice on iOS once the tutorial layer is fully settled

## [2026-04-16] audit | Block 079 iOS dungeon list and progress typed contracts

Completed the next iOS dungeon-contract block:
- **Created:** `[[block-079-ios-dungeon-list-and-progress-typed-contracts]]`
- **Files audited:** 1 iOS dungeon service, 2 live dungeon view models, and 1 hub prefetch consumer
- **Fixes:** added typed dungeon catalog/progress DTOs in `DungeonService`, moved dungeon list loading and progress snapshots off raw dictionaries, converted `DungeonSelectViewModel` to typed active-run and progress state, converted `DungeonRoomViewModel` resume logic to typed `activeRun/progress`, and aligned hub dungeon prefetch with the same typed progress contract
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` and `git diff --check`
- **Inventory refresh:** updated current counts to 4882 in-scope files and `111 in-scope wiki files / 109 wiki pages`
- **Open decisions:** `DungeonService.start(...)`, `DungeonService.fight(...)`, and `DungeonRushViewModel` still live on raw result contracts and remain the next obvious iOS cleanup slice

## [2026-04-16] audit | Block 080 iOS dungeon combat and rush entry typed contracts

Completed the next iOS dungeon runtime-contract block:
- **Created:** `[[block-080-ios-dungeon-combat-and-rush-entry-typed-contracts]]`
- **Files audited:** 1 iOS dungeon service, 2 normal-dungeon runtime/view files, and 1 Dungeon Rush runtime file
- **Fixes:** added typed DTOs for dungeon start/fight and rush status/start/fight in `DungeonService`, moved those mutation/status calls off raw dictionaries and onto typed `APIClient.get/post(...)`, replaced ad hoc combat JSON bridging with typed `combatData` helpers, converted `DungeonRoomViewModel` pending fight/victory handling onto typed responses, converted `DungeonVictoryView` loot rendering onto `CombatLootItem`, and moved the live Dungeon Rush start/status/fight path onto typed rooms/buffs/enemy/reward state while leaving resolve/shop raw for a later scoped block
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'func start\\(|func fight\\(|func rushStatus\\(|func rushStart\\(|func rushFight\\(' Hexbound/Hexbound/Services/DungeonService.swift`
- **Inventory refresh:** updated current counts to 4883 in-scope files and `112 in-scope wiki files / 110 wiki pages`
- **Open decisions:** `DungeonService.rushResolve(...)` and `DungeonService.rushShopBuy(...)` still return raw dictionaries, so the remaining rush event/treasure/shop surface should be cleaned up as its own follow-up block instead of widening this one further

## [2026-04-16] audit | Block 081 iOS dungeon rush resolve and shop typed contracts

Completed the follow-up rush mutation-contract block:
- **Created:** `[[block-081-ios-dungeon-rush-resolve-and-shop-typed-contracts]]`
- **Files audited:** 1 iOS dungeon service and 1 Dungeon Rush runtime view model
- **Fixes:** added typed resolve/shop DTOs and request bodies in `DungeonService`, moved `rushResolve(...)` and `rushShopBuy(...)` off raw dictionaries and onto typed `APIClient.post(...)`, converted open-shop/leave-shop/resolve-room/shop-buy handling in `DungeonRushViewModel` onto typed responses, moved reward application and next-room advancement for non-combat rooms onto typed contracts, removed the now-unused raw buff parser, and fixed the real field-drift bug where the client looked for `gold` while the backend returned authoritative `playerGold`
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'rushResolve\\(|rushShopBuy\\(' Hexbound/Hexbound/Services/DungeonService.swift`
- **Inventory refresh:** updated current counts to 4884 in-scope files and `113 in-scope wiki files / 111 wiki pages`
- **Open decisions:** the main remaining raw compatibility surface around rush is now the shared app-level `pendingLoot` dictionary path rather than the rush service boundary itself

## [2026-04-16] audit | Block 082 iOS pending loot typed presentation contract

Closed the shared loot-presentation seam after the dungeon and rush contract cleanup:
- **Created:** `[[block-082-ios-pending-loot-typed-presentation-contract]]`
- **Files audited:** 1 shared loot model file, 1 app-state file, 1 arena resolve service, 2 loot-producing view models, and 2 loot-consuming combat screens
- **Fixes:** added typed `PendingLootItem` and `PendingLootShard`, moved `AppState.pendingLoot` off `[[String: Any]]`, typed `ResolveResult.loot` in `BattlePreloader`, replaced raw loot bridges in `DungeonRoomViewModel` and `DungeonRushViewModel`, and moved both `LootDetailView` and `CombatResultDetailView` onto typed loot properties with shard-aware icon fallback
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'pendingLoot: \\[\\[String: Any\\]\\]|lootDetailModal\\(_ item: \\[String: Any\\]\\)' Hexbound/Hexbound`
- **Inventory refresh:** updated current counts to 4885 in-scope files and `114 in-scope wiki files / 112 wiki pages`
- **Open decisions:** the reward contract is now typed end-to-end for the shared loot bucket, but `LootDetailView` and `CombatResultDetailView` still duplicate the same modal layout and should get a later keep/simplify pass

## [2026-04-16] audit | Block 083 iOS character service typed contract cleanup

Closed the next central iOS service boundary after the loot cleanup:
- **Created:** `[[block-083-ios-character-service-typed-contract-cleanup]]`
- **Files audited:** 1 live iOS character service
- **Fixes:** moved character load, stat allocation, stat respec, buy-stat-points, purchase-status, and stance updates off `getRaw/postRaw + JSONSerialization` and onto typed `APIClient.get/post(...)`; changed stance save to trust the authoritative backend character snapshot; and replaced the dead `train()` call to a deprecated route with an explicit unavailable path instead of a hidden runtime failure
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'getRaw\\(|postRaw\\(|JSONSerialization' Hexbound/Hexbound/Services/CharacterService.swift`
- **Inventory refresh:** updated current counts to 4886 in-scope files and `115 in-scope wiki files / 113 wiki pages`
- **Open decisions:** neighboring services (`GameInitService`, `AuthService`, `CharacterSelectionViewModel`) still have older raw-decode paths, and `train()` should only come back if product wants a new live training contract instead of the deprecated simulate route

## [2026-04-16] audit | Block 084 iOS character list typed envelope parity

Closed the next shared hero-lifecycle contract slice:
- **Created:** `[[block-084-ios-character-list-typed-envelope-parity]]`
- **Files audited:** 1 shared character model file, 1 auth bootstrap service, and 1 character selection view model
- **Fixes:** added a shared typed `CharactersListResponse` with compatibility fallback for canonical `characters`, legacy `data`, and single-character direct payloads; moved `AuthService.loadCharacters()` and `CharacterSelectionViewModel.loadCharacters()` off `getRaw + JSONSerialization`; and kept level sorting plus just-created hero auto-selection behavior intact
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'getRaw\\(|JSONSerialization' Hexbound/Hexbound/Services/AuthService.swift Hexbound/Hexbound/Views/Auth/CharacterSelectionViewModel.swift`
- **Inventory refresh:** updated current counts to 4887 in-scope files and `116 in-scope wiki files / 114 wiki pages`
- **Open decisions:** the shared roster loader is clean now, but `GameInitService` remains the next obvious raw bootstrap surface on the iOS side

## [2026-04-16] audit | Block 085 iOS game/init typed bootstrap and cache parity

Completed the next iOS bootstrap-contract block:
- **Created:** `[[block-085-ios-game-init-typed-bootstrap-and-cache-parity]]`
- **Files audited:** 1 iOS bootstrap service and 1 shared app-state file
- **Fixes:** migrated `GameInitService` off `getRaw + JSONSerialization` onto a typed `GameInitResponse`; moved `currentUser` and `cachedDailyLogin` to typed snapshots; preserved fallback to `CharacterService.loadCharacter()`; localized arbitrary feature-flag JSON decoding to a small `JSONValue` bridge; and fixed startup inventory parity so `/api/game/init` consumables are now merged into `cachedInventory` instead of being dropped during bootstrap
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` and `rg -n 'getRaw\\(|JSONSerialization' Hexbound/Hexbound/Services/GameInitService.swift`
- **Inventory refresh:** updated current counts to 4890 in-scope files and `117 in-scope wiki files / 115 wiki pages`
- **Open decisions:** `activeEvents` and `achievementsSummary` are still shipped in `/api/game/init` but not yet consumed as authoritative client bootstrap state, and `cachedQuests` remains a legacy raw cache slot pending a later keep/delete pass

## [2026-04-16] audit | Block 086 iOS PvP service typed list contracts

Completed the next live iOS PvP-contract block:
- **Created:** `[[block-086-ios-pvp-service-typed-list-contracts]]`
- **Files audited:** 1 iOS PvP service and 1 shared PvP model file
- **Fixes:** migrated opponents, revenge list, and match history loading in `PvPService` off `getRaw + JSONSerialization` onto typed response envelopes; preserved the existing retry/toast behavior for opponent loading; and removed stale snake_case coding keys from `RevengeEntry` so it cleanly decodes through the shared `APIClient` contract
- **Verification:** `rg -n 'getRaw\\(|JSONSerialization|\\[String: Any\\]' Hexbound/Hexbound/Services/PvPService.swift Hexbound/Hexbound/Models/RevengeEntry.swift` and `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- **Inventory refresh:** updated current counts to 4891 in-scope files and `118 in-scope wiki files / 116 wiki pages`
- **Open decisions:** the remaining nearby follow-up is PvP mutation/profile parity, not the list-loading boundary itself

## [2026-04-16] audit | Block 087 iOS tutorial service typed scripted-fight contracts

Completed the next onboarding-contract cleanup block:
- **Created:** `[[block-087-ios-tutorial-service-typed-scripted-fight-contracts]]`
- **Files audited:** 1 iOS tutorial service and 1 onboarding view model
- **Fixes:** migrated scripted-fight preload/resolve in `TutorialService` off `postRaw + [String: Any]` onto typed DTOs; replaced raw hero/opponent preview dictionaries with typed onboarding preview models; updated `TutorialFightViewModel` to read hero class and HP plus opponent name and HP from typed payloads; and let the shared `APIClient` decoder own snake_case/camelCase rollout compatibility instead of duplicating alias handling in client code
- **Verification:** `rg -n 'getRaw\\(|postRaw\\(|JSONSerialization|\\[String: Any\\]' Hexbound/Hexbound/Services/TutorialService.swift Hexbound/Hexbound/Views/Onboarding/TutorialFightViewModel.swift` and `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- **Inventory refresh:** updated current counts to 4892 in-scope files and `119 in-scope wiki files / 117 wiki pages`
- **Open decisions:** the backend still ships `combat` and `sanity_check_passed` for the scripted fight, but the current iOS onboarding flow intentionally ignores them because it skips full replay and only shows the victory/result path

## [2026-04-16] audit | Blocks 088-090 social, stash, and auth/account typed contracts

Closed the next three iOS contract tails in one pass:
- **Created:** `[[block-088-ios-social-and-challenge-action-typed-contracts]]`, `[[block-089-ios-stash-transfer-typed-contracts]]`, `[[block-090-ios-auth-service-and-account-delete-typed-contracts]]`
- **Files audited:** 4 iOS services, 1 settings view model, and 1 shared social model file
- **Fixes:** migrated social friend actions plus friendship-status lookup and challenge decline/cancel off raw `postRaw` bodies onto typed request/response DTOs; removed the duplicate local `FriendshipStatusResponse` that had started conflicting with the canonical shared social model; migrated stash deposit/withdraw onto typed transfer contracts; moved `AuthService` email login/register/guest-login/forgot-password off raw dictionaries onto a shared typed auth session envelope; and moved settings account deletion onto a typed delete-account response
- **Verification:** `rg -n 'getRaw\\(|postRaw\\(|patchRaw\\(|JSONSerialization|\\[String: Any\\]'` over the touched files, `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, and `git diff --check`
- **Inventory refresh:** updated current counts to 4895 in-scope files and `122 in-scope wiki files / 120 wiki pages`
- **Open decisions:** Apple/Google sign-in and guest-upgrade view models still carry their own raw auth payload handling, and `InventoryService`/`ShopService` remain the next larger live raw-contract slice

## [2026-04-16] audit | Blocks 091-092 auth provider flows and onboarding typed contracts

Closed the next auth-adjacent onboarding slice:
- **Created:** `[[block-091-ios-oauth-signin-and-guest-upgrade-typed-contracts]]`, `[[block-092-ios-onboarding-name-and-character-create-typed-contracts]]`
- **Files audited:** 1 shared auth service, 3 auth/onboarding view models, and 2 adjacent backend route contracts
- **Fixes:** moved Apple/Google sign-in and guest email/OAuth upgrade off raw auth bodies onto typed request/response DTOs built around `AuthSessionEnvelope`; widened the shared auth envelopes so provider flows reuse the same contract instead of duplicating shapes; migrated onboarding name availability to typed query params; and replaced raw character-creation + manual `JSONSerialization` with a compatibility-aware typed `CharacterCreateResponse`
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization|\\[String: Any\\]'` over the touched auth/onboarding files
- **Inventory refresh:** updated current counts to 4897 in-scope files and `124 in-scope wiki files / 122 wiki pages`
- **Open decisions:** the next obvious live raw-contract slice is now `ShopService`, not auth/onboarding

## [2026-04-16] audit | Blocks 093-095 shop, inventory, and arena PvP typed contracts

Closed the next central iOS live-contract slice:
- **Created:** `[[block-093-ios-shop-service-typed-purchase-and-repair-contracts]]`, `[[block-094-ios-inventory-service-sell-use-expand-typed-contracts]]`, `[[block-095-ios-battle-preloader-typed-pvp-contracts]]`
- **Files audited:** 3 core iOS runtime services, 1 arena resolve consumer, and 7 adjacent backend route contracts
- **Fixes:** moved `ShopService` purchase/consumable/gems/repair/upgrade flows off raw dictionaries onto typed DTOs; moved `InventoryService` sell/use/expand flows onto typed DTOs with typed HP/stamina reconciliation; migrated `BattlePreloader` PvP prepare/resolve off `postRaw(...)` onto typed request/response contracts; and typed `durability_changes` all the way into `ArenaViewModel`
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization|rawDictionary:'` over the touched files
- **Inventory refresh:** updated current counts to 4900 in-scope files and `127 in-scope wiki files / 125 wiki pages`
- **Open decisions:** `BattlePreloader` no longer owns a raw network boundary, but `CombatEngine` still keeps a local legacy dictionary bridge for stance and skill payloads, which should be treated as its own future simplify pass

## [2026-04-16] audit | Block 096 iOS appearance editor typed save contract

Closed the next player-facing profile contract tail:
- **Created:** `[[block-096-ios-appearance-editor-typed-save-contract]]`
- **Files audited:** 1 iOS profile view model and 1 adjacent backend route contract
- **Fixes:** moved appearance save off raw `PATCH` bodies and manual `Character` re-decoding; added typed request/response DTOs in `AppearanceEditorViewModel`; and kept the existing optimistic-update plus revert-on-failure behavior intact while removing the raw transport layer
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization' Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift`
- **Inventory refresh:** updated current counts to 4901 in-scope files and `128 in-scope wiki files / 126 wiki pages`
- **Open decisions:** the appearance save boundary is clean now; the remaining residual iOS raw-contract list is smaller and is drifting toward `DungeonService.rushAbandon`, `HubView` active-slot loading, and the larger Gold Mine/editor-only utility surfaces

## [2026-04-16] audit | Block 097 iOS dungeon rush abandon and gold mine status typed contracts

Closed the next live iOS contract tails around dungeons and hub prefetch:
- **Created:** `[[block-097-ios-dungeon-rush-abandon-and-gold-mine-status-typed-contracts]]`
- **Files audited:** 5 iOS files and 2 adjacent backend route contracts
- **Fixes:** moved `DungeonService.rushAbandon()` off a raw mutation body; added shared typed gold mine status DTOs in `MinigameSession.swift`; routed both `HubView.prefetchGoldMine()` and `GoldMineViewModel.loadStatus()` through typed `GoldMineStatusResponse`; and centralized the narrow old-slot bridge in `GameDataCache.cacheGoldMine(status:)`
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization'` over the touched dungeon/hub files
- **Inventory refresh:** updated current counts to 4902 in-scope files and `129 in-scope wiki files / 127 wiki pages`
- **Open decisions:** gold mine status is typed now, but the remaining mutation-heavy Gold Mine flows still keep the next honest raw-contract tail

## [2026-04-16] audit | Blocks 098-099 Gold Mine actions and editor layout-save typed contracts

Closed the next two residual iOS raw-mutation tails:
- **Created:** `[[block-098-ios-gold-mine-action-typed-contracts]]`, `[[block-099-ios-editor-layout-save-typed-contracts]]`
- **Files audited:** 3 Gold Mine runtime files, 2 debug/editor view files, and 2 adjacent admin layout-save routes
- **Fixes:** moved Gold Mine collect, collect-all, boost, buy-slot, shaft-minigame start, and shaft-minigame submit flows off `postRaw(...)` onto typed request/response DTOs; removed the local Gold Mine minigame `JSONSerialization` bridge; and moved hub/dungeon-map debug layout saves onto typed `AdminLayoutSaveRequest/Response` contracts with the DTOs co-located in `HubEditorDetailView.swift` so the Xcode target stays self-consistent
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization'` over the touched Gold Mine and editor files
- **Inventory refresh:** updated current counts to 4904 in-scope files and `131 in-scope wiki files / 129 wiki pages`
- **Open decisions:** Gold Mine live action flows are typed now; the remaining residual work has shifted from product actions to smaller cache/infrastructure bridges

## [2026-04-16] audit | Blocks 100-102 config parse bridge, combat reconcile bridge, and network infrastructure cleanup

Closed the next infrastructure-focused iOS contract slice:
- **Created:** `[[block-100-ios-game-config-daily-login-parse-bridge-cleanup]]`, `[[block-101-ios-interactive-combat-reconcile-payload-bridge-cleanup]]`, `[[block-102-ios-network-infrastructure-raw-surface-retirement]]`
- **Files audited:** 2 shared iOS model/cache files, 2 interactive-combat files, and 2 network/auth infrastructure files
- **Fixes:** replaced the game-config daily-login reward JSON round-trip with direct dictionary parsing; removed the recoverable `OUT_OF_CONSUMABLE` actives JSON round-trip from interactive combat by adding a narrow typed payload bridge; deleted dead `APIClient` raw helpers plus their `rawBody` plumbing; and moved `SupabaseAuthClient` refresh/user/resend flows onto typed DTOs while removing the dead anonymous sign-in helper
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, `rg -n '\\.getRaw\\(|\\.postRaw\\(|\\.patchRaw\\(' Hexbound/Hexbound -g'*.swift'`, and `rg -n 'JSONSerialization' Hexbound/Hexbound/Network/APIClient.swift Hexbound/Hexbound/Network/SupabaseAuthClient.swift`
- **Inventory refresh:** updated current counts to 4907 in-scope files and `134 in-scope wiki files / 132 wiki pages`
- **Open decisions:** residual `JSONSerialization` in `Hexbound` is now intentionally limited to generic error-payload extraction, and the remaining iOS tail is smaller contract-shape cleanup rather than a broad raw-network surface

## [2026-04-16] audit | Block 103 iOS Gold Mine typed state and cache parity

Closed the next Gold Mine state-layer cleanup:
- **Created:** `[[block-103-ios-gold-mine-typed-state-and-cache-parity]]`
- **Files audited:** 7 iOS model/cache/view files around Gold Mine state, hub badges, and contextual hints
- **Fixes:** moved Gold Mine slot state and cache storage off `[[String: Any]]` onto `GoldMineSlotResponse`; added typed payload bridges plus resolved-status helpers for slot reconciliation; updated `GoldMineViewModel`, `GoldMineCards`, `GoldMineDetailView`, `HubView`, and `CityMapView` to consume typed slot state instead of raw dictionary keys; and kept the remaining generic `GameDataCache` dictionary bridges limited to feature flags and layout hydration, not Gold Mine runtime state
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n '\\[String: Any\\]|legacySlots|gold_accumulated|gold_mined|slot\\[\"'` over the touched Gold Mine files
- **Inventory refresh:** updated current counts to 4908 in-scope files and `135 in-scope wiki files / 133 wiki pages`
- **Open decisions:** the next honest iOS tail is no longer Gold Mine state, but the smaller internal bridge layer around `CombatEngine` and other typed-vs-foundation conversion helpers

## [2026-04-16] audit | Block 104 iOS battle preloader and combat engine typed handoff

Closed the next internal combat bridge:
- **Created:** `[[block-104-ios-battle-preloader-combat-engine-typed-handoff]]`
- **Files audited:** 2 iOS combat runtime files on the arena prepare/simulate hot path
- **Fixes:** removed the last typed-to-dictionary handoff between `BattlePreloader` and `CombatEngine`; deleted `BattleJSONValue` plus `foundationObject` helpers; converted combat config, stance, passives, and equipped skills to direct typed engine models; corrected local `rank_scaling` decoding to match backend’s scalar payload; and updated the combat engine to operate on `CombatSkill`, typed `ParsedZoneStance`, and typed `PassiveBonus` instead of parsing `[String: Any]`
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'BattleJSONValue|foundationObject|init\\(from dict: \\[String: Any\\]\\)'` over the touched combat files
- **Inventory refresh:** updated current counts to 4909 in-scope files and `136 in-scope wiki files / 134 wiki pages`
- **Open decisions:** the arena combat handoff is typed now, so the next remaining iOS tails are smaller residual model-sharing and contract-reuse questions rather than any live raw battle bridge

## [2026-04-16] audit | Blocks 105-107 typed error bodies, cache bridge retirement, and dead model parser cleanup

Closed the next three narrow iOS residual blocks:
- **Created:** `[[block-105-ios-typed-error-body-and-combat-model-bridge-cleanup]]`, `[[block-106-ios-cache-raw-bridge-retirement-and-feature-flag-bool-parity]]`, `[[block-107-ios-dead-model-parse-bridge-cleanup]]`
- **Files audited:** 6 recoverable flow/runtime files, 3 cache/bootstrap files, and 3 residual model files
- **Fixes:**
  - added typed recoverable error-body decoding on top of `APIError` and moved interactive combat, Gold Mine, and referral validation flows off local raw dictionaries;
  - removed the dead `PendingLootItem(rawDictionary:)` escape hatch;
  - removed dead raw quest/achievement cache fields plus dead raw layout cache entry points;
  - narrowed feature flag caching to the boolean contract the iOS client actually uses;
  - deleted dead Gold Mine slot payload constructors / legacy dictionary exports and removed the dead `DungeonInfo.from(serverData:)` parser;
  - preserved `DailyLoginRewardDef.init(dictionary:)` because `GameConfig` fallback parsing still genuinely depends on it.
- **Verification:** repeated `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'legacyDictionary|legacySlots|init\\(payload: \\[String: Any\\]\\)|GoldMinePayload\\.|DungeonInfo\\.from\\(serverData|cachedQuests|cachedAchievements|featureFlagValue\\(|cacheHubLayout\\(from|cacheDungeonMapLayout\\(from|foundationValue'`
- **Inventory refresh:** updated current counts to 4912 in-scope files and `139 in-scope wiki files / 137 wiki pages`
- **Open decisions:** feature flags are now cached as booleans only on iOS; if the app later needs structured flag payloads, it should add a typed flag model instead of reopening `[String: Any]`

## [2026-04-16] audit | Block 108 intentional raw boundaries and dead APIResponse removal

Closed the next narrow iOS infrastructure block:
- **Created:** `[[block-108-ios-intentional-raw-boundaries-and-dead-apiresponse-removal]]`
- **Files audited:** 3 intentional infrastructure-boundary files plus 2 adjacent cleanup files whose dead raw fallback paths were still keeping the grep noisy
- **Fixes:** removed dead `APIResponse`; retired the dead raw `GameConfig` initializer and the now-unneeded `DailyLoginRewardDef.init(dictionary:)`; and explicitly classified the remaining raw grep hits in `APIClient`/`APIError` and `KeychainManager` as intentional infrastructure boundaries rather than unfinished feature migration work
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `git diff --check`, and `rg -n 'APIResponse\\b|getRaw\\(|postRaw\\(|patchRaw\\(|JSONSerialization|\\[String: Any\\]|responsePayload' Hexbound/Hexbound -g'*.swift'`
- **Inventory refresh:** updated current counts to 4913 in-scope files and `140 in-scope wiki files / 138 wiki pages`
- **Open decisions:** no active feature-level raw JSON tail remains in `Hexbound`; remaining raw usage is intentionally centralized in networking or required by the system `Security` API
