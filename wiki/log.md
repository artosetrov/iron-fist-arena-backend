# Hexbound Wiki — Log

## [2026-04-19] feature | Interactive Combat unification — PvP + bot + dungeon_boss

Migrated PvP, NPC bot, and dungeon boss fights through the single `/pvp/match/{start,strike,complete}` lifecycle so one `AppRoute.interactiveBattle` screen drives three modes. Dungeon Rush and the Guild Hall challenge replay stay on classic combat until a dedicated follow-up session.
- **Schema:** `backend/prisma/migrations/20260418_interactive_combat_unified_opponent/migration.sql` — `pvp_matches.player2_id` becomes nullable; new nullable columns `opponent_type` (default `'pvp'`), `opponent_snapshot`, `dungeon_run_id`, `boss_key`, `bot_key`; new index `(opponent_type, status)`. Reconciled 17 pre-existing drift migrations via `prisma migrate resolve --applied` before `migrate deploy`.
- **Backend:** `/pvp/match/start` infers `opponent_type` from the `npc_*` prefix when the field is omitted (backward compat); synthesizes bot stats via `generateBotCombatStats`; loads dungeon bosses from `DungeonRun.state.enemies[0]` + an inline `dungeonEnemyToCharacterStats`; skips the PvP stamina gate for `dungeon_boss`. `/pvp/strike` reads opponent stats from `opponent_snapshot` when non-PvP. `/pvp/match/complete` forks rewards: PvP keeps ELO + revenge + defender update; `bot` uses ±K-factor (`+30%` win / `−10%` loss) and skips defender/revenge/pvp achievements; `dungeon_boss` uses floor gold/XP with Training XP DR, advances `DungeonRun.currentFloor` or deletes on completion, upserts `DungeonProgress`, routes daily quest to `dungeons_complete`, loot key `dungeon_<difficulty>` or `boss`.
- **iOS:** `AppRoute.interactiveBattle(opponentType:dungeonRunId:)` + `InteractiveOpponentType.{pvp,bot,dungeonBoss}`. `ArenaViewModel` auto-routes `npc_*` opponents with `.bot`; `DungeonRoomViewModel.fight()` routes through Interactive when `interactiveCombatEnabled == true`. Pre-wired VFX/SFX hooks: `InteractiveStrikeTurn.statusApplied`, `VFXEffectType.fire{Hit,Crit}`, `CombatFXAssetMap` `"fire"` case, `InteractiveBattleViewModel.speedMultiplier` (1x/2x).
- **Deferred:** `dungeon_rush` (separate state machine — artifacts, HP%, artifact choice UI), Guild Hall challenge replay (pre-resolved combat, not round-by-round), `CombatDetailView`/`CombatViewModel`/`AppRoute.combat` retirement, `INTERACTIVE_COMBAT_V1` flag removal. All blockers documented in `wiki/features/combat-unification-remaining.md`.
- **Decision:** new `wiki/decisions/why-interactive-combat-unification.md`.
- **Code touched:** `backend/prisma/schema.prisma` + `admin/prisma/schema.prisma`, `backend/src/app/api/pvp/match/{start,complete}/route.ts`, `backend/src/app/api/pvp/strike/route.ts`, `Hexbound/Hexbound/App/AppRouter.swift`, `Hexbound/Hexbound/Models/InteractiveCombatModels.swift`, `Hexbound/Hexbound/Views/Combat/{InteractiveBattleView,InteractiveBattleViewModel,VFX/CombatVFXEffect,VFX/CombatVFXManager,VFX/CombatFXAssetMap}.swift`, `Hexbound/Hexbound/Persistence/SFXCatalog.swift`, `Hexbound/Hexbound/Views/Arena/ArenaViewModel.swift`, `Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift`.

## [2026-04-19] feature | TALENTS screen redesign — prototype parity + premium 4th slot

Re-skinned the TALENTS tab to match the new HTML prototype and opened a gem-gated 4th active-skill slot:
- **iOS UI**: `TalentNodeView` rewritten to a square-tile language (44×44, keystone 54×54) with 3px gold left-bar on unlocked, cost/rank pill top-right, pulsing gold glow on unlockable. `TalentTreeCanvas` gains radial top glow, 24pt grid backdrop, corner brackets, and an animated dashed stroke onto unlockable neighbours. New `TalentsSummaryCard` merges the old SP banner + `ActiveSlotsBar` into one card with 4 tiles (3 regular + premium). `TalentsTabView` now hosts a rust-tinted inline reset row and the existing sticky Confirm bar.
- **Backend**: new `POST /api/passives/active-slots/unlock-premium` deducts `PASSIVES.PREMIUM_ACTIVE_SLOT_GEM_COST = 100` inside a `FOR UPDATE` tx and bumps `Character.activeSlotCount` (3 → 4, hard cap `MAX_ACTIVE_SLOTS`). Existing `active-slots` routes now read `activeSlotCount` off the character and drop the hard-coded `MAX_SLOTS = 3`.
- **Files touched**: `Hexbound/Views/Hero/Talents/{TalentNodeView,TalentTreeCanvas,TalentsTabView,TalentsSummaryCard,PassiveTreeViewModel}.swift`, `Services/PassiveTreeService.swift`, `Network/APIEndpoints.swift`, `Models/PassiveTree.swift`, `backend/src/app/api/passives/active-slots/{route,batch/route,unlock-premium/route}.ts`, `backend/src/lib/game/balance.ts`. `Hexbound/Views/Hero/Talents/ActiveSlotsBar.swift` deleted (all call sites replaced).
- **Prototype**: `prototypes/talents-screen.html` saved as the reference snapshot.

## [2026-04-19] schema | `characters.active_slot_count` history repair

Captured a pre-existing drift: `Character.activeSlotCount` (default 3) had been referenced by `passives/active-slots/*` route handlers for weeks, but the schema column was never recorded in the Prisma migration history. `scripts/check_schema_drift.py` flagged it on re-run. Added an idempotent `ALTER TABLE ADD COLUMN IF NOT EXISTS` migration so Prisma history matches `schema.prisma`; the column is already live in prod, so the migration resolves to a no-op everywhere and the drift guard stays quiet going forward.
- **Code touched:** `backend/prisma/migrations/20260419_character_active_slot_count/migration.sql` (new; `IF NOT EXISTS` keeps it safe on any environment).

## [2026-04-19] schema | `dungeon_bosses.tagline` for reveal subtitle

Follow-up to the boss reveal ceremony. Added a nullable `tagline String?` column to `DungeonBoss` so the reveal subtitle can be authored instead of derived from `extendedLore`. Client (`BossRevealData.fromDungeonBoss`) prefers `boss.tagline` when present, falls back to first-sentence trimming. Migration backfills `tagline = description` for existing rows (existing descriptions are already tagline-quality one-liners); seed auto-promotes `description` into `tagline` for new dungeons unless the author supplies an explicit `tagline` override. Schema drift check OK (65 models / 703 columns).
- **Updated:** `[[why-boss-reveal-ceremony]]` (Subtitle source section closed the open follow-up).
- **Code touched:** `backend/prisma/schema.prisma` (`DungeonBoss.tagline`), `backend/prisma/migrations/20260419_dungeon_boss_tagline/migration.sql` (new — additive `ALTER TABLE` + null-safe backfill `UPDATE`), `admin/prisma/schema.prisma` (mirrored), `backend/src/app/api/dungeons/list/route.ts` (select + response), `backend/prisma/seed-dungeons.ts` (`BossDef.tagline?` + auto-promote), iOS `DungeonInfo.swift` (`BossInfo.tagline`), `DungeonService.swift` (`DungeonCatalogBoss.tagline` + mapping), `BossRevealData.swift` (tagline-first subtitle).

## [2026-04-19] decision | Daily-quest dungeon entry routes through Hub HUD

`DailyQuestsDetailView` previously pushed `AppRoute.dungeonMap` for the `dungeons_complete` quest card, which rendered the bare standalone `DungeonMapView` — no hero widget, no floating icons, no ADVENTURES↔CASTLE button. Now the card pops to hub (`appState.mainPath = NavigationPath()`) and raises a new `AppState.pendingShowDungeonMap` flag; `HubView.onAppear` consumes the flag and runs `triggerMapTransition(toDungeon: true)` so the dungeon map appears inside the hub's embedded ZStack with the full HUD, matching the ADVENTURES button experience.
- **Code touched:** `Hexbound/Hexbound/App/AppState.swift` (new `pendingShowDungeonMap: Bool`), `Hexbound/Hexbound/Views/Quests/DailyQuestsDetailView.swift` (destination branch for `.dungeonMap`), `Hexbound/Hexbound/Views/Hub/HubView.swift` (`.onAppear` flag consumer). No new files, no pbxproj change, no schema/balance change.
- **Updated:** `wiki/features/quests.md` (added dungeon-navigation gotcha referencing the Hub ZStack pattern in `Hexbound/CLAUDE.md`).

## [2026-04-19] decision | Interactive Combat UX polish — round strip, micro-log, auto-submit, long-press skip, summary stars

Ported four UX beats from an HTML battle prototype into the iOS Interactive Combat screen. All client-only — server contract (`/pvp/strike`) untouched; crit/block/dodge still resolved server-side per root CLAUDE.md rule.
- **Round strip** (`InteractiveBattleView.roundStrip`) — `ROUND N · CHOOSE YOUR STRIKE / STRIKING… / REVEAL` label between duel header and predict panel. Derived from `vm.currentRoundNumber = battleLog.count + 1`.
- **Inline micro-log** (`InteractiveMicroLogView` + private `MicroLogRow`) — 2 entries per round (you + enemy) with 2.4s TTL, fade-out over last 0.6s, cap 3 entries. Uses a local 300ms ticker so the VM doesn't publish per-frame state. Colour-coded: gold crit, info-blue block, muted miss/dodge.
- **Auto-submit** — new `vm.pickAttack(_:)` / `vm.pickDefend(_:)` set `attackTouched` / `defendTouched` and arm a 350ms delayed `submitStrike()`. Re-picking restarts the task. Flags reset on round advance + match start.
- **Long-press own portrait = skip** — 0.5s hold on player `DuelFighterCard` calls `vm.skipAndSubmit()` + medium haptic. Existing SKIP button kept for discoverability.
- **Pre-result stars on `BattleSummaryView`** — three `BattleStarTile`s (Claim Victory / Stay Above 50% HP / Critical Hit) above stats header. Same criteria as canonical `CombatResultDetailView` stars but derived from `vm.battleLog` + final HP. Pre-result teaser before reward modal loads.
- **Code touched:** `Views/Combat/InteractiveBattleViewModel.swift` (new `MicroLogEntry`, auto-submit task, pick helpers, micro-log emit), `Views/Combat/InteractiveBattleView.swift` (round strip, micro-log view + row, long-press portrait gesture), `Views/Combat/BattleSummaryView.swift` (`BattleStar`, `BattleVictoryStars`, `BattleStarTile`). No new files, no pbxproj change. No schema change, no balance change. `xcodebuild` clean (iPhone 17 sim).
- **Updated:** `wiki/features/pvp-combat.md` (new "Interactive Combat UX polish" section, Victory Stars split into canonical + pre-result).

## [2026-04-19] decision | Boss reveal ceremony — Dungeons + Dungeon Rush

Added a root-level `BossRevealOverlayView` that fires from two surfaces with different cadence. Dungeons: once per real boss on first `.current` detail open (gated by `UserDefaults["bossRevealSeen_<name>_<id>"]`, skipped for Training Camp practice enemies). Dungeon Rush: every run when the `miniboss` room becomes current (compact 1.2s variant, CTA commits directly to `vm.fight()`). Generic DTO `BossRevealData` decouples the overlay from `BossInfo`/`RushRoom`. Mounted at `HexboundApp` root (`zIndex: 170`). Zero new DS tokens — reuses `RadialGlowBackground`, `FiligreeLine`, `.buttonStyle(.fight(accent:))`, `.dungeonBossAppear` SFX (3 variations, auto haptic `heavy`). Accent: `arenaRankGold` for Dungeons, `purple` for Rush (matches existing miniboss badge colour).
- **Created:** `[[why-boss-reveal-ceremony]]` (rationale — once-per-boss vs per-run cadence, CTA behaviour, DS mapping, alternatives rejected), `Views/Components/BossRevealData.swift`, `Views/Components/BossRevealOverlayView.swift`
- **Updated:** `[[dungeons]]` (added Boss Reveal Ceremony section), `wiki/features/dungeons.md` + `wiki/features/dungeon-rush.md` (notable gotcha entries), `wiki/index.md` (decisions list + page count 263→264)
- **Code touched:** `AppState.swift` (`pendingBossReveal`/`isBossRevealing`/`presentBossReveal`/`dismissBossReveal`, cleanup on logout), `HexboundApp.swift` (root overlay mount), `BossDetailSheet.swift` (onAppear trigger + UserDefaults gate), `DungeonRushDetailView.swift` (onChange trigger + per-run guard), `project.pbxproj` (2 files × 4 sections), graphify re-index. No schema change, no balance change.

## [2026-04-19] decision | Victory stars become labelled conditions on both arenas

Replaced the opaque `starRating: Int?` scalar on `BattleResultConfig` with `starConditions: [StarCondition]?` and extended the Victory screen to render both earned and missed slots with their labels. Dungeon and PvP screens now both surface a three-slot row; conditions are derived client-side (dungeon: HP fraction; PvP: HP fraction + crit landed via `combatLog`) and are purely visual — gold/XP/rating are unchanged.
- **Created:** `[[why-victory-star-conditions]]` (rationale, formulas, animation contract)
- **Updated:** `[[dungeons]]` (added Victory Stars section), `[[pvp-combat]]` (added Victory Stars section), `wiki/index.md` (decisions list + page count 262→263)
- **Code touched:** `BattleResultModels.swift`, `BattleResultSections.swift`, `BattleResultAnimations.swift`, `BattleResultCardView.swift`, `DungeonVictoryView.swift`, `CombatResultDetailView.swift`. No schema change, no balance change. `xcodebuild` clean.

## [2026-04-17] decision | Quest reward banners → CLAIMED modal

Replaced `showToast("Quest Complete!", subtitle: "+Xg +Y XP", .quest)` in two inline quest-claim sites (`HubBannerCards.swift:596`, `ActiveQuestBanner.swift:246`) with `ClaimRewardModalView` ceremony. Added root-level `AppState.claimRewardConfig` slot + overlay mount in `HexboundApp.swift` (zIndex 180) so inline banners without their own VM can surface the modal.
- **Created:** `[[why-reward-modal-over-toast]]` (rationale + scope: which earn-points use modal vs toast)
- **Updated:** `[[quests]]` feature map (notable gotcha added), `wiki/index.md` (decisions list + page count 207→208)
- **Code touched:** `AppState.swift`, `HexboundApp.swift`, `HubBannerCards.swift`, `ActiveQuestBanner.swift` (no schema change, no balance change)

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
- **Open decisions at the time:** revalidate March 25 QA findings, decide whether CDO belongs in this project repo, decide whether ignored agent-bus protocol files should be tracked or generated
- **Later follow-up:** mutable `last-retro.json` was moved to ignored local state in `[[block-179-instant-retro-local-state-de-tracking]]`

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

## [2026-04-16] audit | Block 109 operations deploy docs reality sync

Closed the next operations/documentation drift block:
- **Created:** `[[block-109-operations-deploy-docs-reality-sync]]`
- **Files audited:** 2 live operations docs plus 8 config/evidence sources (`ci.yml`, Next/Vercel configs, package scripts, Fastlane/AppConstants, and Herald run output)
- **Fixes:** removed stale claims about missing CI/CD, backend `ignoreBuildErrors`, standing backend/admin schema drift, and the old `136 files` local-chaos snapshot; clarified that `prisma migrate deploy` is still an explicit production step; added live CI validation gates to `DEPLOY.md`; and rewrote the deploy audit around the real current risk surface
- **Verification:** inspected `.github/workflows/ci.yml`, `backend/next.config.ts`, `admin/next.config.ts`, `backend/package.json`, `admin/vercel.json`, `Hexbound/fastlane/Appfile`, `Hexbound/Hexbound/App/AppConstants.swift`, `.claude/agent-bus/herald.md`, plus refreshed `git ls-files`, `git ls-files --others --exclude-standard`, and `find wiki -name '*.md'`
- **Inventory refresh:** updated current counts to 4914 in-scope files and `141 in-scope wiki files / 139 wiki pages`
- **Open decisions:** admin subtree deploy, explicit DB migration apply, incomplete Fastlane/Appfile setup, and iOS staging/prod URL parity remain real and are now documented as the honest residual operations debt

## [2026-04-16] audit | Block 110 operations git workflow and iOS release doc parity

Closed the next adjacent operations-doc block:
- **Created:** `[[block-110-operations-git-workflow-and-ios-release-doc-parity]]`
- **Files audited:** `docs/10_operations/GIT_WORKFLOW.md`, `docs/10_operations/RELEASE_IOS.md`, plus the live evidence files `.github/workflows/ci.yml`, `Hexbound/fastlane/Appfile`, `Hexbound/fastlane/Fastfile`, and `Hexbound/Hexbound/App/AppConstants.swift`
- **Fixes:** clarified that CI validates but does not deploy admin/iOS; reframed branch protection as recommendation instead of implied current fact; documented that Fastlane release is setup-required because repo `Appfile` values are still placeholders; and made the staging/prod API host parity explicit in the iOS release guide
- **Verification:** inspected the touched docs against the live workflow, Fastlane, and app environment files; then re-ran `git diff --check`, repo inventory counts, and wiki-link presence checks for `block-110`
- **Inventory refresh:** updated current counts to 4915 in-scope files and `142 in-scope wiki files / 140 wiki pages`
- **Open decisions:** the remaining operations tail is now narrower and concrete: admin subtree deploy remains manual, iOS release identity/team config still needs real values, and staging still shares the production API host

## [2026-04-16] audit | Block 111 operations database migration runbook parity

Closed the next operations-doc parity block:
- **Created:** `[[block-111-operations-database-migration-runbook-parity]]`
- **Files audited:** `docs/10_operations/DATABASE_MIGRATIONS.md` plus neighboring deploy docs and live build-config evidence in `backend/package.json` and `admin/vercel.json`
- **Fixes:** removed the semi-active framing of build-time migration auto-apply, made explicit `db:migrate:deploy` the primary documented production path, and aligned the migration runbook with the already-refreshed deploy guide and deploy audit
- **Verification:** inspected the migration doc against `DEPLOY.md`, `GIT_AND_DEPLOY_AUDIT.md`, `backend/package.json`, and `admin/vercel.json`; then re-ran `git diff --check`, repo inventory counts, and wiki-link presence checks for `block-111`
- **Inventory refresh:** updated current counts to 4916 in-scope files and `143 in-scope wiki files / 141 wiki pages`
- **Open decisions:** the remaining migration question is now purely policy: whether to keep explicit production apply as the long-term model or deliberately move to deploy-time auto-apply later

## [2026-04-16] audit | Block 112 iOS TestFlight helper identity validation parity

Closed the next small-but-real iOS release helper block:
- **Created:** `[[block-112-ios-testflight-helper-identity-validation-parity]]`
- **Files audited:** `Hexbound/scripts/deploy_testflight.sh`, `docs/10_operations/TESTFLIGHT_GUIDE.md`, `Hexbound/fastlane/Appfile`, and `Hexbound/Gemfile`
- **Fixes:** hardened the TestFlight helper so it now accepts both valid Fastlane identity setup modes (Appfile-based or env-based), requires team configuration in addition to Apple ID, and explains repair steps clearly; then synced the TestFlight guide with that behavior
- **Verification:** inspected the helper/docs against the live Fastlane/Appfile/Gemfile setup and re-ran `git diff --check`, repo inventory counts, and wiki-link presence checks for `block-112`
- **Inventory refresh:** updated current counts to 4917 in-scope files and `144 in-scope wiki files / 142 wiki pages`
- **Open decisions:** the remaining iOS release debt is now back to the real product/ops layer: placeholder Fastlane identity in repo, no distinct staging backend host, and manual App Store/TestFlight ownership work

## [2026-04-16] audit | Block 113 wiki generation tooling and generated indexes

Closed the next wiki tooling block:
- **Created:** `[[block-113-wiki-generation-tooling-and-generated-indexes]]`
- **Files audited:** `scripts/wiki/*`, `wiki/_generated/*`, `wiki/features/_template.md`, and both gatekeeper preflight scripts
- **Fixes:** documented the new machine-readable wiki indexes, regenerated them, and most importantly wired `scripts/wiki/check-drift.sh` into both preflight scripts so the generated README promise ("preflight will warn if stale") is now actually true
- **Verification:** `bash scripts/wiki/generate-all.sh`, `bash scripts/wiki/check-drift.sh`, `bash .skills/skills/gatekeeper/scripts/preflight_check.sh "$(pwd)"`, `git diff --check`, plus refreshed repo/wiki counts
- **Inventory refresh:** updated current counts to 4934 in-scope files and `153 in-scope wiki markdown files / 147 wiki pages`
- **Open decisions:** whether `scripts/wiki/*` and `wiki/_generated/*` stay intentionally untracked local tooling/indexes or get promoted to tracked repo artifacts later

## [2026-04-16] audit | Block 114 wiki feature maps and index visibility

Closed the next wiki navigation block:
- **Created:** `[[block-114-wiki-feature-maps-and-index-visibility]]`
- **Files audited:** `wiki/features/_template.md`, `wiki/features/gold-mine.md`, `wiki/features/interactive-combat.md`, `wiki/features/pvp-combat.md`, `wiki/features/referral.md`, `wiki/features/shop.md`, and `wiki/index.md`
- **Fixes:** added a dedicated `Features` section to the wiki index, surfaced all five live feature maps, and converted the new feature pages’ related links onto native wiki-link style
- **Verification:** inspected the feature pages/index, re-ran `git diff --check`, and refreshed wiki-count visibility in the footer
- **Inventory refresh:** updated current counts to 4934 in-scope files and `153 in-scope wiki markdown files / 147 wiki pages`
- **Open decisions:** whether the feature-map section stays a curated short list or grows into a broader feature atlas

## [2026-04-16] audit | Block 115 Figma handoff and historical doc boundaries

Closed the next operations/docs hygiene block:
- **Created:** `[[block-115-operations-figma-and-historical-doc-boundaries]]`
- **Files audited:** `docs/10_operations/FIGMA_HANDOFF.md`, `docs/10_operations/FIGMA_SCREEN_INVENTORY.md`, `docs/10_operations/PROGRESS_LOG.md`, `docs/10_operations/SIMULATOR_PLAYTEST_BUGS_2026-04-09.md`, and `docs/10_operations/UI_PR_CHECKLIST.md`
- **Fixes:** corrected the stale Figma screen-inventory path and wildcard-like admin UI source reference; added explicit source-of-truth or historical-snapshot boundaries to the Figma handoff, screen inventory, progress log, and simulator bug report; and replaced the ambiguous SwiftLint checklist step with the exact repo-safe command
- **Verification:** inspected all five docs against the live repo layout and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4935 in-scope files and `154 in-scope wiki markdown files / 148 wiki pages`
- **Open decisions:** continue the same truth-boundary cleanup into the remaining historical docs and documentation index layer

## [2026-04-16] audit | Block 116 source-of-truth doc index parity

Closed the next source-of-truth docs block:
- **Created:** `[[block-116-source-of-truth-doc-index-parity]]`
- **Files audited:** `docs/01_source_of_truth/DOCUMENTATION_INDEX.md` and `docs/01_source_of_truth/CLEANUP_REPORT.md`
- **Fixes:** refreshed the master documentation index away from stale March count language, reclassified `PROGRESS_LOG.md` correctly as historical notebook material, linked the master index back to the live wiki audit surfaces, and added a historical boundary banner to the cleanup report
- **Verification:** inspected both docs against the current repo/wiki state and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4936 in-scope files and `155 in-scope wiki markdown files / 149 wiki pages`
- **Open decisions:** `PROJECT_OVERVIEW.md` still deserves the next pass because it keeps several old count-based descriptions

## [2026-04-16] audit | Block 117 source-of-truth project overview parity

Closed the next source-of-truth docs block:
- **Created:** `[[block-117-source-of-truth-project-overview-parity]]`
- **Files audited:** `docs/01_source_of_truth/PROJECT_OVERVIEW.md` plus live version/deployment-target evidence in `backend/package.json`, `admin/package.json`, and `Hexbound/Hexbound.xcodeproj/project.pbxproj`
- **Fixes:** updated the overview freshness banner, corrected the iOS minimum version to `17.0`, replaced brittle count-heavy wording with lower-maintenance role-based descriptions, normalized framework wording to the current `Next.js 15.x / TypeScript 5.7.x / Prisma 6.x` package reality, and aligned the high-level deploy text with the already-audited operations docs
- **Verification:** inspected the overview against the live package/xcode evidence and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4937 in-scope files and `156 in-scope wiki markdown files / 150 wiki pages`
- **Open decisions:** the next adjacent cleanup should hit `ADMIN_CAPABILITIES.md` and `SCREEN_INVENTORY.md`, which still carry older freshness/count language

## [2026-04-16] audit | Block 118 admin capabilities and screen inventory parity

Closed the next source-of-truth docs block:
- **Created:** `[[block-118-source-of-truth-admin-capabilities-and-screen-inventory-parity]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `docs/07_ui_ux/SCREEN_INVENTORY.md`, plus live evidence in `admin/package.json`, `Hexbound/Hexbound/App/AppRouter.swift`, and `Hexbound/Hexbound/Views/Dev/ScreenCatalogView.swift`
- **Fixes:** refreshed both docs’ freshness banners, removed stale count-heavy headings and summary claims, corrected the admin stack wording to the live `Next.js 15` package reality, clarified that `ADMIN_CAPABILITIES.md` is not a formal permission matrix, and reframed the screen inventory’s Figma coverage section as a snapshot gap-analysis rather than guaranteed live parity
- **Verification:** inspected both docs against the current admin package and iOS routing/screen-catalog evidence, then re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4938 in-scope files and `157 in-scope wiki markdown files / 151 wiki pages`
- **Open decisions:** continue the same truth-boundary pass through the remaining historical or count-heavy docs under `docs/05_admin_panel/` and `docs/07_ui_ux/`

## [2026-04-16] audit | Block 119 design system source-of-truth vs audit snapshot boundaries

Closed the next design-system docs block:
- **Created:** `[[block-119-design-system-source-of-truth-vs-audit-snapshot-boundaries]]`
- **Files audited:** `docs/07_ui_ux/DESIGN_SYSTEM.md`, `docs/07_ui_ux/DESIGN_SYSTEM_AUDIT.md`, and live token evidence in `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
- **Fixes:** reframed `DESIGN_SYSTEM.md` as a living ruleset instead of a frozen count inventory, removed brittle screen/component/token count metadata and stale count-bearing section headers, converted the old “100% COMPLETE” claim into an explicit historical milestone note, and marked `DESIGN_SYSTEM_AUDIT.md` as a historical forensic snapshot whose success metrics require revalidation before reuse
- **Verification:** inspected both docs against the live theme file and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4939 in-scope files and `158 in-scope wiki markdown files / 152 wiki pages`
- **Open decisions:** continue through the remaining `docs/07_ui_ux/` audit-style artifacts that still read like live truth without explicit historical boundaries

## [2026-04-16] audit | Block 120 UI audit artifacts historical boundary cleanup

Closed the next UI audit artifact block:
- **Created:** `[[block-120-ui-audit-artifacts-historical-boundary-cleanup]]`
- **Files audited:** `docs/07_ui_ux/FULL_DESIGN_SYSTEM_AUDIT_2026_04_04.md`, `docs/07_ui_ux/UX_AUDIT.md`, `docs/07_ui_ux/ASSET_CONSISTENCY_AUDIT.md`, and `docs/07_ui_ux/UI_AUDIT_DASHBOARD.html`
- **Fixes:** added explicit historical-snapshot boundaries to the large forensic audit docs, clarified that their counts/scores/gap numbers require revalidation against live code/wiki, and changed the static HTML dashboard subtitle so it no longer reads like a live metric source
- **Verification:** inspected all four artifacts and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4951 in-scope files and `159 in-scope wiki markdown files / 153 wiki pages`
- **Open decisions:** keep moving through the remaining `docs/07_ui_ux/` review artifacts that still carry exact snapshot numbers without a clear time fence

## [2026-04-16] audit | Block 121 prototypes link parity and transition state

Closed the next prototype/history block:
- **Created:** `[[block-121-prototypes-link-parity-and-transition-state]]`
- **Files audited:** `COMBAT_UX_AUDIT.md`, `COMBAT_UX_IMPLEMENTATION_PLAN.md`, the git-visible `prototypes/*.html` combat/hero/legal surfaces, and `prototypes/victory-rewards/*`
- **Fixes:** repaired combat-doc links after the move into `prototypes/`, fixed the reverse link from `prototypes/combat-prototypes.html` back to the historical audit, changed `prototypes/terms.html` to use a local `privacy.html` cross-link, and documented the current transition state where tracked root prototype/legal HTML is being replaced by `prototypes/` copies in the working tree
- **Verification:** inspected all git-visible prototype HTML/assets, checked relative-link targets for the prototype set, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4954 in-scope files and `162 in-scope wiki markdown files / 156 wiki pages`
- **Open decisions:** finish the root → `prototypes/` move explicitly, decide which prototype artifacts should be kept as design history, and define the real legal/static deploy contract instead of leaving these files in a half-prototype / half-production state

## [2026-04-16] audit | Block 122 wiki feature-map visibility and related-link gaps

Closed the next wiki navigation/source-of-truth block:
- **Created:** `[[block-122-wiki-feature-map-visibility-and-related-link-gaps]]`
- **Files audited:** `wiki/index.md` plus the current feature-map layer under `wiki/features/` covering `auth`, `achievements`, `battle-pass`, `characters`, `daily-login`, `dungeons`, `dungeon-rush`, `events`, `inventory`, `leaderboard`, `mail`, `minigames`, `passive-tree`, `prestige`, `quests`, `session-summary`, `social`, `stamina`, `stash`, and `tutorial`
- **Fixes:** expanded the main wiki index from a stale curated feature subset to the full live feature-atlas, added first-class visibility for `passive-tree`, `prestige`, `quests`, `session-summary`, `social`, `minigames`, `stamina`, `stash`, and `tutorial`, corrected the main footer counts to the current wiki surface, and revalidated the remaining true related-page gaps down to `opponent-profile` and `onboarding`
- **Verification:** re-enumerated the current `wiki/features/*.md` set, rescanned related-link targets against the live wiki page set, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4973 in-scope files and `181 in-scope wiki markdown files / 175 wiki pages`
- **Open decisions:** create or remap the remaining related-page dead-ends (`opponent-profile`, `onboarding`) and keep the feature index synchronized as new `wiki/features/*.md` pages appear

## [2026-04-16] audit | Block 123 UI review and plan docs historical boundaries

Closed the next dated-UX-docs block:
- **Created:** `[[block-123-ui-review-and-plan-docs-historical-boundaries]]`
- **Files audited:** `docs/07_ui_ux/COMBAT_SCREEN_REDESIGN.md`, `COMIC_ONBOARDING_PLAN.md`, `DAILY_LOGIN_CAROUSEL_REVIEW.md`, `MOTION_AND_JUICE_AUDIT.md`, `PROTOTYPE_INSIGHTS.md`, `QA_FIX_PLAN_2026-04-10.md`, `QA_PLAYTHROUGH_2026-04-10.md`, and `SOCIAL_FLOWS_UX_SPEC.md`
- **Fixes:** added explicit historical/proposal boundaries to dated redesign, audit, and roadmap docs; redirected readers back to current `wiki/` and live code for operational truth; and downgraded `PROTOTYPE_INSIGHTS.md` from “canonical reference” wording to a historical archive role
- **Verification:** inspected all eight docs and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4978 in-scope files and `182 in-scope wiki markdown files / 176 wiki pages`
- **Open decisions:** continue the same cleanup through the remaining dated `docs/07_ui_ux/` design/review files that still read too close to live specification

## [2026-04-16] audit | Block 124 W1-W3 plan docs historical boundaries

Closed the next dated roadmap/checkpoint block:
- **Created:** `[[block-124-w1-w3-plan-docs-historical-boundaries]]`
- **Files audited:** `docs/07_ui_ux/W1_CHECKPOINT.md`, `W1_D3_GAMECONFIG_SSOT_REVIEW.md`, `W1_D4_BALANCE_DOCS_AUTOGEN.md`, `W1_D5_DRIFT_GUARD.md`, `W2_D1_REALITY_CHECK.md`, `W2_D1_REVIEW.md`, `W2_D2_LORE_AUDIT.md`, `W2_D2_REALITY_CHECK.md`, `W2_D3_SCRIPTED_FIGHT_DESIGN.md`, `W2_D4_BUILDING_GATING_DESIGN.md`, `W2_D5_BADGE_PRIORITY_DESIGN.md`, `W3_D1_REVIEW.md`, and `W3_D5_REVIEW_PLAN.md`
- **Fixes:** added explicit historical/review/proposal boundaries to dated W1/W2/W3 checkpoint and design docs, clarified that “awaiting approval” or “completed” states belong to the original planning moment, and reframed these files as rationale/evidence rather than live roadmap truth
- **Verification:** inspected all 13 docs and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4979 in-scope files and `183 in-scope wiki markdown files / 177 wiki pages`
- **Open decisions:** continue the same cleanup through the remaining dated `docs/07_ui_ux/` artifacts that still read like current roadmap material

## [2026-04-16] audit | Block 125 UI prototype and Figma workflow boundaries

Closed the next residual prototype/workflow-boundary block:
- **Created:** `[[block-125-ui-prototype-and-figma-workflow-boundaries]]`
- **Files audited:** `docs/07_ui_ux/FIGMA_SCREEN_RULES.md`, `INTEGRATED_CARD_UNIFICATION.md`, `UNIFIED_PRELOADER_CONCEPT.md`, `card-audit-prototype.html`, `card-audit-v2.html`, `card-audit-v3.html`, `card-audit-v4.html`, `combat-prototype.html`, `daily_login_carousel_prototype.html`, `comic-onboarding-prototype.jsx`, `skilltree-prototype.html`, and `docs/07_ui_ux/prototypes/auth-flow-redesign.html`
- **Fixes:** added explicit source-of-truth scoping to the strict Figma workflow playbook, reframed the integrated-card and preloader concept docs as historical proposal/concept artifacts, and added visible historical prototype framing to the remaining direct-open HTML/JSX UI prototype surfaces
- **Verification:** inspected the title/header/opening surfaces for all 12 files, verified the new boundary wording, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4980 in-scope files and `184 in-scope wiki markdown files / 178 wiki pages`
- **Open decisions:** continue through the remaining `docs/07_ui_ux/` direct-open prototype/archive files until every residual mock surface self-identifies as historical

## [2026-04-16] audit | Block 126 design system roadmap and screen inventory live parity

Closed the next live-vs-historical parity block:
- **Created:** `[[block-126-design-system-roadmap-and-screen-inventory-live-parity]]`
- **Files audited:** `docs/07_ui_ux/UI_AUDIT_DASHBOARD.html`, `DESIGN_SYSTEM.md`, and `SCREEN_INVENTORY.md`
- **Fixes:** turned the audit dashboard title/header into explicit historical framing, narrowed the migration roadmap inside `DESIGN_SYSTEM.md` to an archival appendix instead of an active rollout queue, and updated `SCREEN_INVENTORY.md` to the live shared `IntegratedCharacterCard` while removing the stale `LoreIntroView.swift` gap entry
- **Verification:** checked current iOS file presence for `IntegratedCharacterCard`, confirmed the old hero/opponent card files are gone, confirmed `LoreIntroView.swift` is absent, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4981 in-scope files and `185 in-scope wiki markdown files / 179 wiki pages`
- **Open decisions:** keep reviewing mixed live/historical source-of-truth docs so rollout appendices and current runtime truth do not silently collapse back together

## [2026-04-16] audit | Block 127 dated product, economy, and architecture doc boundaries

Closed the next cross-domain dated-docs block:
- **Created:** `[[block-127-dated-product-economy-and-architecture-doc-boundaries]]`
- **Files audited:** `docs/06_game_systems/ECONOMY_AUDIT_2026-04-13.md`, `docs/09_rules_and_guidelines/INLINE_API_AUDIT.md`, `docs/FULL_PRODUCT_AUDIT_2026-03-21.md`, `docs/MIGRATION_PLAN.md`, and `docs/features/combat/INTERACTIVE_COMBAT_PLAN.md`
- **Fixes:** added explicit historical boundaries to the dated economy, architecture, full-product, migration, and combat-plan docs so they no longer read like current repo/runtime truth without revalidation
- **Verification:** inspected the openings of all five docs and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4982 in-scope files and `186 in-scope wiki markdown files / 180 wiki pages`
- **Open decisions:** continue through the remaining dated docs under `docs/11_archive/` and similar archive-style folders

## [2026-04-16] audit | Block 128 retro log historical boundaries

Closed the next archive/journal block:
- **Created:** `[[block-128-retro-log-historical-boundaries]]`
- **Files audited:** all `25` dated retro logs under `docs/retro/RETRO_*.md`
- **Fixes:** applied the same explicit historical retrospective boundary to every retro file so the folder reads as a dated engineering journal, not as current project status
- **Verification:** spot-checked `RETRO_2026-04-15.md`, confirmed the boundary note exists in all `25` retro files, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4983 in-scope files and `187 in-scope wiki markdown files / 181 wiki pages`
- **Open decisions:** continue the same source-of-truth framing pass through `docs/11_archive/` and the remaining legacy audit/report docs

## [2026-04-16] audit | Block 129 archive legacy doc boundaries

Closed the next archive-doc block:
- **Created:** `[[block-129-archive-legacy-doc-boundaries]]`
- **Files audited:** `docs/11_archive/ADMIN_PANEL_AUDIT_REPORT_2026-03-16.md`, `ART_STYLE_GUIDE_DUPLICATE.md`, `BALANCE_AUDIT_REPORT_2026-03-09.md`, `CLAUDE_2_LEGACY.md`, `HEXBOUND_UI_UX_AUDIT_GUIDE_v1.md`, `PROJECT_KNOWLEDGE_v2_LEGACY.md`, `UI_DESIGN_DOCUMENT_LEGACY.md`, and `mine-card-prompts_DUPLICATE.md`
- **Fixes:** added explicit historical/legacy/duplicate boundaries so those archive files no longer open like living references or current source-of-truth docs
- **Verification:** inspected the opening sections of all eight archive files and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4984 in-scope files and `188 in-scope wiki markdown files / 182 wiki pages`
- **Open decisions:** continue through the remaining top-level legacy/old-process docs until all residual historical surfaces self-identify on open

## [2026-04-16] audit | Block 130 top-level source-of-truth and orchestration boundaries

Closed the next top-level docs reality-sync block:
- **Created:** `[[block-130-top-level-source-of-truth-and-orchestration-boundaries]]`
- **Files audited:** `docs/PROJECT_INDEX.md`, `SOURCE_OF_TRUTH.md`, `AGENT_LOADING_GUIDE.md`, `ORCHESTRATOR.md`, `00_studio/STUDIO_COMMAND_CENTER.md`, and `01_source_of_truth/DOCUMENTATION_INDEX.md`
- **Fixes:** removed stale March freshness/count-heavy claims from the top-level routing docs, corrected the iOS minimum target to 17.0 in the project navigator, added explicit `wiki/` pointers for current audit/file-ownership truth, and reframed the orchestrator/studio command-center docs as historical operating-framework snapshots instead of live repo contracts
- **Verification:** reviewed the edited headers/top sections, confirmed stale `2026-03-26` banners are gone from the three top-level routing docs, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4985 in-scope files and `189 in-scope wiki markdown files / 183 wiki pages`
- **Open decisions:** continue through the remaining residual top-level governance/archive-adjacent docs until every direct-open `docs/` entry point clearly signals whether it is live truth, navigation aid, or historical process narrative

## [2026-04-16] audit | Block 131 empty doc placeholders and deprecation markers

Closed the next residual root-doc block:
- **Created:** `[[block-131-empty-doc-placeholders-and-deprecation-markers]]`
- **Files audited:** `docs/06_game_systems/ECONOMY_MODEL_V2.md`, `docs/Untitled 2.base`, and `docs/_COMMUNITY_Community 284.md`
- **Fixes:** converted three silent zero-byte surfaces into explicit deprecated/placeholder docs so they no longer look like missing live source-of-truth material
- **Verification:** confirmed all three files were previously empty and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4986 in-scope files and `190 in-scope wiki markdown files / 184 wiki pages`
- **Open decisions:** continue through remaining root/legacy-adjacent residuals and decide which placeholders should be deleted versus replaced with real scoped docs

## [2026-04-16] audit | Block 132 Obsidian base artifacts

Closed the next editor-residue audit block:
- **Created:** `[[block-132-obsidian-base-artifacts]]`
- **Files audited:** `docs/Untitled.base`, `docs/Untitled 1.base`, and `docs/Untitled 2.base`
- **Findings:** confirmed the repo only contains three `.base` files; two still contain the same trivial table-view stanza and one had already been boundary-marked in the previous placeholder pass
- **Fixes:** no destructive file change yet; documented the whole `.base` group as likely editor residue and marked it as a deprecation/removal decision rather than pretending those files are meaningful live docs
- **Verification:** compared all `.base` files, confirmed no other `.base` surfaces exist in the repo, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4987 in-scope files and `191 in-scope wiki markdown files / 185 wiki pages`
- **Open decisions:** confirm whether any local Obsidian/editor workflow still requires `.base` files; if not, remove the entire group together

## [2026-04-16] audit | Block 133 live doc TBD and URL cleanup

Closed the next small live-doc consistency block:
- **Created:** `[[block-133-live-doc-tbd-and-url-cleanup]]`
- **Files audited:** `docs/06_game_systems/PROGRESSION.md` and `docs/10_operations/DEPLOY.md`
- **Fixes:** replaced the stale daily-quest reward `TBD` wording in `PROGRESSION.md` with the real quest-definition-driven behavior and replaced the landing-site `TBD` URL in `DEPLOY.md` with the documented production domain/deploy path
- **Verification:** reviewed the updated lines and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4988 in-scope files and `192 in-scope wiki markdown files / 186 wiki pages`
- **Open decisions:** keep scanning live docs for the remaining small placeholder/todo tails that still make maintained docs feel provisional

## [2026-04-16] audit | Block 134 delete placeholder and editor artifact files

Closed the next cleanup-by-deletion block:
- **Created:** `[[block-134-delete-placeholder-and-editor-artifact-files]]`
- **Files removed:** `docs/06_game_systems/ECONOMY_MODEL_V2.md`, `docs/_COMMUNITY_Community 284.md`, `docs/Untitled.base`, `docs/Untitled 1.base`, and `docs/Untitled 2.base`
- **Fixes:** converted the earlier placeholder/editor-residue findings into actual deletion and cleared repo-wide `.DS_Store` clutter during the same sweep
- **Verification:** confirmed no `.base` files remain in the repo and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4989 in-scope files and `193 in-scope wiki markdown files / 187 wiki pages`
- **Open decisions:** continue deleting similarly obvious non-product residue only when the role is already proven non-canonical

## [2026-04-16] audit | Block 135 delete archive duplicate docs

Closed the next archive-reduction block:
- **Created:** `[[block-135-delete-archive-duplicate-docs]]`
- **Files removed:** `docs/11_archive/ART_STYLE_GUIDE_DUPLICATE.md` and `docs/11_archive/mine-card-prompts_DUPLICATE.md`
- **Fixes:** deleted two pure duplicate archive docs and updated `docs/11_archive/ARCHIVE_INDEX.md` so archive policy now distinguishes unique historical docs from removable duplicates
- **Verification:** confirmed `ARCHIVE_INDEX.md` no longer lists the removed duplicate files and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4990 in-scope files and `194 in-scope wiki markdown files / 188 wiki pages`
- **Open decisions:** keep archive preservation for unique historical material, but continue removing archive entries that are only redundant copies

## [2026-04-16] audit | Block 136 delete root orphan prototype artifacts

Closed the next safe root-prototype deletion block:
- **Created:** `[[block-136-delete-root-orphan-prototype-artifacts]]`
- **Files removed:** `review-choose-hero-guest-gating-before-after.jsx`, `gold-mine-ux-prototype.jsx`, and `gold-mine-ux-prototype-ds.jsx`
- **Fixes:** deleted one tracked guest-gating review artifact and two local Gold Mine JSX prototype residues after confirming they had no live imports or maintained source-of-truth role; also updated `block-001` so root audit history now reflects the removal instead of leaving that file in `Needs review`
- **Verification:** confirmed all three files are gone from the working tree, rechecked references outside generated graph residue, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4991 in-scope files and `195 in-scope wiki markdown files / 189 wiki pages`
- **Open decisions:** continue the same high-confidence rule for root cleanup — remove only the prototype/history surfaces that are already proven orphaned, not the ones that still carry unique design rationale

## [2026-04-16] audit | Block 137 root prototype relocation state sync

Closed the next repo-map honesty block:
- **Created:** `[[block-137-root-prototype-relocation-state-sync]]`
- **Files audited:** deleted root prototype/legal HTML paths plus their `prototypes/` working-tree copies, along with `project-file-inventory.md` and `block-001-root-files.md`
- **Fixes:** marked the deleted root prototype/legal entries in the inventory as `_(deleted in working tree)_` and added an explicit relocation note to `block-001` so the old root-file audit no longer reads like those files still physically live at repo root
- **Verification:** confirmed the listed root HTML surfaces are absent from the working tree, confirmed corresponding `prototypes/` copies exist, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4992 in-scope files and `196 in-scope wiki markdown files / 190 wiki pages`
- **Open decisions:** the remaining decision is whether the moved `prototypes/` copies become fully tracked canonical history surfaces or stay as transition-state working-tree mirrors

## [2026-04-16] audit | Block 138 delete deprecated prototype residue

Closed the next prototype-reduction block:
- **Created:** `[[block-138-delete-deprecated-prototype-residue]]`
- **Files removed:** `prototypes/hero-card-delete-rings-layout.html`, `prototypes/hero-card-rings-deepdive.html`, `prototypes/special_offer_widget_prototype.html`, and `prototypes/special_offer_widget_v2_prototype.html`
- **Fixes:** removed two orphan hero-card explorations and two superseded Special Offer generations, while keeping `prototypes/special_offer_widget_v3_prototype.html` as the single retained historical offer reference; also updated `block-001` and `block-121` so audit history reflects the cleanup instead of leaving those files in deprecated limbo
- **Verification:** confirmed all four files are gone from the working tree, confirmed `special_offer_widget_v3_prototype.html` still remains, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4991 in-scope files and `197 in-scope wiki markdown files / 191 wiki pages`
- **Open decisions:** continue shrinking prototypes by keeping only latest or uniquely informative references; do not delete the remaining combat/legal/v3 surfaces until their retained-reference role is explicitly replaced

## [2026-04-16] audit | Block 139 delete superseded combat prototype set

Closed the next combat-history reduction block:
- **Created:** `[[block-139-delete-superseded-combat-prototype-set]]`
- **Files removed:** `prototypes/combat-proto-A.html`, `prototypes/combat-proto-B.html`, `prototypes/combat-proto-C.html`, `prototypes/combat-prototypes.html`, and `prototypes/combat-proto-B2-v2.html`
- **Fixes:** removed the fully superseded A/B/C combat comparison set plus the dead launcher and extra B2-v2 intermediate branch, while intentionally keeping `prototypes/combat-proto-B2.html` and `prototypes/combat-proto-B2-v3.html` as the retained combat history bridge; also updated `block-001` and `block-121` so those files no longer sit in deprecated limbo
- **Verification:** confirmed the five target files are gone from the working tree, confirmed `prototypes/combat-proto-B2.html` and `prototypes/combat-proto-B2-v3.html` still remain, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4988 in-scope files and `198 in-scope wiki markdown files / 192 wiki pages`
- **Open decisions:** keep the remaining B2/B2-v3 prototypes only until their design-history role is either archived elsewhere or intentionally collapsed further

## [2026-04-17] audit | Block 140 delete orphan feature prototype residue

Closed the next ownerless-prototype cleanup block:
- **Created:** `[[block-140-delete-orphan-feature-prototype-residue]]`
- **Files removed:** `prototypes/active-skills-picker-prototype.html`, `prototypes/boss-card-prototype.html`, `prototypes/contraband_widget_prototype.html`, `prototypes/daily-login-prototype.html`, `prototypes/gold-mine-prototype.html`, and `prototypes/hero-card-hp-energy-prototype.html`
- **Fixes:** removed six unowned feature prototype residues that no longer had any maintained source-of-truth role, shrinking `prototypes/` down to the intentionally retained legal/combat/Gold Mine/special-offer/victory set
- **Verification:** confirmed all six target files are gone from the working tree, rechecked repo references for live consumers, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4989 in-scope files and `199 in-scope wiki markdown files / 193 wiki pages`
- **Open decisions:** keep trimming `prototypes/` only where the retained-vs-orphan line is already clear from current docs and code

## [2026-04-17] audit | Block 141 prototype reference doc sync

Closed the follow-up doc-parity block:
- **Created:** `[[block-141-prototype-reference-doc-sync]]`
- **Files audited:** `docs/02_product_and_features/ACTIVE_SKILL_PICKER_SPEC.md` and `docs/retro/RETRO_2026-04-12.md`
- **Fixes:** removed the stale claim that the deleted active-skill picker prototype still exists as a live reference and converted one later-resolved retro cleanup checkbox into an explicitly closed historical note
- **Verification:** confirmed the active-skill-picker spec now points to the retained native implementation instead of a dead HTML artifact, confirmed the retro no longer carries the junk-file cleanup as an open present-tense task, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4990 in-scope files and `200 in-scope wiki markdown files / 194 wiki pages`
- **Open decisions:** continue the same cleanup pattern whenever a historical note still has open TODO wording that has already been resolved by later audit blocks

## [2026-04-17] audit | Block 142 delete wiki Obsidian editor residue

Closed the next repo-hygiene cleanup block:
- **Created:** `[[block-142-delete-wiki-obsidian-editor-residue]]`
- **Files removed:** `wiki/.obsidian/app.json`, `wiki/.obsidian/appearance.json`, `wiki/.obsidian/core-plugins.json`, `wiki/.obsidian/graph.json`, and `wiki/.obsidian/workspace.json`
- **Fixes:** removed local Obsidian editor-state residue from inside `wiki/`, which restored the difference between real wiki file count and maintained inventory count back to zero
- **Verification:** confirmed the five `wiki/.obsidian/*` files are gone, rechecked wiki file totals against the inventory map, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4991 in-scope files and `201 in-scope wiki markdown files / 195 wiki pages`
- **Open decisions:** keep deleting editor-state residue instead of normalizing it into the project wiki

## [2026-04-17] audit | Block 143 delete final Special Offer prototype reference

Closed the next retained-prototype reduction block:
- **Created:** `[[block-143-delete-final-special-offer-prototype-reference]]`
- **Files removed:** `prototypes/special_offer_widget_v3_prototype.html`
- **Fixes:** removed the final retained Special Offer prototype after confirming it no longer had any live docs/code consumer, and updated `block-001` so the root-audit follow-up no longer advertises it as an active retained reference
- **Verification:** confirmed `prototypes/special_offer_widget_v3_prototype.html` is gone from the working tree, rechecked remaining references for live consumers, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4992 in-scope files and `202 in-scope wiki markdown files / 196 wiki pages`
- **Open decisions:** keep reevaluating the remaining prototypes one-by-one, but only delete those that have lost all named current consumers

## [2026-04-17] audit | Block 144 delete victory-rewards prototype set

Closed the next retained-prototype reduction block:
- **Created:** `[[block-144-delete-victory-rewards-prototype-set]]`
- **Files removed:** `prototypes/victory-rewards/index.html`, `prototypes/victory-rewards/assets/reward-gold.png`, `prototypes/victory-rewards/assets/reward-xp.png`, and `prototypes/victory-rewards/assets/reward-rating-up.png`
- **Fixes:** removed the standalone victory-rewards prototype package after confirming it no longer had a named current consumer and duplicated reward art that already exists in tracked app and asset surfaces; also updated `block-121` to record that this prototype set was later removed
- **Verification:** confirmed the whole `prototypes/victory-rewards/` set is gone from the working tree, confirmed tracked reward PNG equivalents still exist elsewhere in the repo, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4993 in-scope files and `203 in-scope wiki markdown files / 197 wiki pages`
- **Open decisions:** only the combat, Gold Mine, and legal-transition prototype surfaces remain for explicit one-by-one review

## [2026-04-17] audit | Block 145 delete Gold Mine minigame prototype reference

Closed the next retained-prototype reduction block:
- **Created:** `[[block-145-delete-gold-mine-minigame-prototype-reference]]`
- **Files removed:** `prototypes/gold_mine_minigame_prototype.html`
- **Files audited:** `GOLD_MINE_MINIGAME_PLAN.md`, `wiki/audit/block-001-root-files.md`
- **Fixes:** removed the old Gold Mine minigame HTML prototype after converting the historical plan away from treating it as a live dependency; also updated `block-001` so Gold Mine no longer appears in the residual active-reference list
- **Verification:** confirmed `prototypes/gold_mine_minigame_prototype.html` is gone from the working tree, confirmed the plan now frames that prototype as removed historical context, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4994 in-scope files and `204 in-scope wiki markdown files / 198 wiki pages`
- **Open decisions:** only the combat-history pair plus the legal-transition copies remain in `prototypes/`, so further cleanup from here should be deliberate rather than bulk residue removal

## [2026-04-17] audit | Block 146 delete legal transition prototype copies

Closed the next retained-prototype reduction block:
- **Created:** `[[block-146-delete-legal-transition-prototype-copies]]`
- **Files removed:** `prototypes/privacy.html` and `prototypes/terms.html`
- **Files audited:** `docs/10_operations/GIT_AND_DEPLOY_AUDIT.md`, `wiki/audit/block-121-prototypes-link-parity-and-transition-state.md`
- **Fixes:** removed the last local legal transition HTML copies after confirming the app already opens hosted production URLs, and updated operations wording so it no longer implies a maintained repo-local legal/static page surface
- **Verification:** confirmed both legal prototype copies are gone from the working tree, confirmed iOS legal buttons still target hosted URLs, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4993 in-scope files and `205 in-scope wiki markdown files / 199 wiki pages`
- **Open decisions:** only the combat-history pair remains in `prototypes/`, so any further change there should be treated as a deliberate historical-source decision, not residue cleanup

## [2026-04-17] audit | Block 147 delete final combat-history prototypes

Closed the final prototype-reduction block:
- **Created:** `[[block-147-delete-final-combat-history-prototypes]]`
- **Files removed:** `prototypes/combat-proto-B2.html` and `prototypes/combat-proto-B2-v3.html`
- **Files audited:** `COMBAT_UX_IMPLEMENTATION_PLAN.md`, `COMBAT_V3_IMPLEMENTATION_PLAN.md`, `wiki/audit/block-001-root-files.md`, `wiki/audit/block-121-prototypes-link-parity-and-transition-state.md`
- **Fixes:** removed the final combat-history HTML artifacts after converting both implementation plans to historical-reference mode; updated root/prototype audit notes so they no longer imply an active retained combat HTML surface
- **Verification:** confirmed `prototypes/` is now empty, confirmed both combat plans now treat the deleted prototypes as historical context rather than live dependencies, and re-ran `git diff --check`
- **Inventory refresh:** updated current counts to 4992 in-scope files and `206 in-scope wiki markdown files / 200 wiki pages`
- **Open decisions:** no generic prototype cleanup remains; any future resurrection of prototype HTML should be a deliberate new artifact, not residual carry-over

## [2026-04-17] audit | Block 148 root dated QA and UI audit relocation

Closed the next root-doc cleanup block:
- **Created:** `[[block-148-root-dated-qa-and-ui-audit-relocation]]`
- **Files moved:** `QA_REPORT_2026-04-09.md` -> `qa-reports/QA_REPORT_2026-04-09.md`, `UI_RESPONSIVENESS_AUDIT.md` -> `docs/07_ui_ux/UI_RESPONSIVENESS_AUDIT.md`
- **Fixes:** removed two dated audit/history docs from root and relocated them into their canonical QA/UI doc families
- **Verification:** confirmed both files are gone from root, confirmed the new destination paths exist, and re-ran `git diff --check`

## [2026-04-17] audit | Block 149 root combat history doc relocation

Closed the next root-doc cleanup block:
- **Created:** `[[block-149-root-combat-history-doc-relocation]]`
- **Files moved:** `COMBAT_UX_AUDIT.md`, `COMBAT_UX_IMPLEMENTATION_PLAN.md`, and `COMBAT_V3_IMPLEMENTATION_PLAN.md` -> `docs/features/combat/`
- **Fixes:** removed the root combat-history doc trio from root, preserved their internal lineage under the combat feature docs, and removed the last live-looking deleted-prototype links from the moved history docs
- **Verification:** confirmed the three files are gone from root, confirmed the moved combat docs exist under `docs/features/combat/`, confirmed no deleted `prototypes/combat-*` links remain in the moved docs, and re-ran `git diff --check`

## [2026-04-17] audit | Block 150 root Gold Mine doc relocation

Closed the next root-doc cleanup block:
- **Created:** `[[block-150-root-gold-mine-doc-relocation]]`
- **Files moved:** `GOLD_MINE_MINIGAME_BALANCE_AUDIT.md` and `GOLD_MINE_MINIGAME_PLAN.md` -> `docs/features/gold-mine/`
- **Fixes:** removed the Gold Mine historical plan/audit pair from root, colocated them with the live Gold Mine overview, and updated the `shaft-catalog.ts` balance-doc reference to the new canonical path
- **Verification:** confirmed both files are gone from root, confirmed the moved docs exist under `docs/features/gold-mine/`, confirmed the code reference uses the new path, and re-ran `git diff --check`

## [2026-04-17] audit | Block 151 root release audit relocation

Closed the next root-doc cleanup block:
- **Created:** `[[block-151-root-release-audit-relocation]]`
- **Files moved:** `HEXBOUND_PRE_RELEASE_AUDIT.md` -> `docs/10_operations/HEXBOUND_PRE_RELEASE_AUDIT.md`
- **Fixes:** removed the dated pre-release audit from root and moved it into the operations doc family where historical release-audit snapshots belong
- **Verification:** confirmed the file is gone from root, confirmed the new operations path exists, and re-ran `git diff --check`

## [2026-04-17] audit | Block 152 root bootstrap and ignore parity

Closed the next root-policy cleanup block:
- **Created:** `[[block-152-root-bootstrap-and-ignore-parity]]`
- **Files audited:** `.gitignore`, `CLAUDE.md`, `wiki/audit/block-001-root-files.md`
- **Fixes:** compacted `CLAUDE.md` back into a root bootstrap entrypoint, removed the old count-heavy/orchestrator noise from that file, and closed the outdated `.gitignore` parity warning now that root prototype/doc residue is gone
- **Verification:** confirmed root now contains only `.gitignore`, `.mcp.json`, and `CLAUDE.md`; confirmed `CLAUDE.md` still points to canonical docs/domain rules; and re-ran `git diff --check`

## [2026-04-17] audit | Block 153 iOS talent detail sheet slot-aware picker unification

Closed the next iOS talents/runtime block:
- **Created:** `[[block-153-ios-talent-detail-sheet-slot-aware-picker-unification]]`
- **Files audited:** `Hexbound/Hexbound/Views/Hero/Talents/TalentsTabView.swift`, `Hexbound/Hexbound/Views/Hero/Talents/TalentDetailSheet.swift`, `Hexbound/Hexbound/Views/Hero/Talents/PassiveTreeViewModel.swift`, `Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerSheet.swift`, `Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerRow.swift`
- **Fixes:** routed detail-sheet equip through a new slot-aware VM entry point, opened the picker instead of dead-ending when the loadout is full, added in-picker slot targeting for replacement, and updated picker row copy so it matches the real replacement flow
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`, and `git diff --check` passed after the code/wiki updates

## [2026-04-17] audit | Block 154 backend PvP match-start Prisma create parity

Closed the next interactive PvP cleanup block:
- **Created:** `[[block-154-backend-pvp-match-start-prisma-create-parity]]`
- **Files audited:** `backend/src/app/api/pvp/match/start/route.ts`, `wiki/audit/block-011-backend-passives-interactive-combat-runtime.md`
- **Fixes:** removed the stale `tx.pvpMatch.create as any` workaround from `pvp/match/start`, replaced it with typed Prisma JSON-field casts for the interactive payload, and narrowed the old block-011 follow-up note so it now points only at the still-open `strike` / `match/complete` workaround tail
- **Verification:** `npx eslint src/app/api/pvp/match/start/route.ts`, `npm run build`, and `git diff --check` all passed

## [2026-04-17] audit | Block 155 backend PvP strike and complete Prisma JSON parity

Closed the next interactive PvP cleanup block:
- **Created:** `[[block-155-backend-pvp-strike-complete-prisma-json-parity]]`
- **Files audited:** `backend/src/app/api/pvp/strike/route.ts`, `backend/src/app/api/pvp/match/complete/route.ts`, `wiki/audit/block-011-backend-passives-interactive-combat-runtime.md`
- **Fixes:** removed the remaining `findUnique as any` / `updateMany as any` workaround tail from the live interactive PvP routes and replaced it with explicit JSON-boundary typing through `unknown` + `Prisma.InputJsonValue`
- **Verification:** `npx eslint src/app/api/pvp/match/complete/route.ts src/app/api/pvp/strike/route.ts`, `npm run build`, and targeted `git diff --check -- ...` all passed

## [2026-04-17] audit | Block 156 stale audit tail sync for quests and interactive PvP

Closed the next truth-sync block:
- **Created:** `[[block-156-stale-audit-tail-quests-and-interactive-pvp-sync]]`
- **Files audited:** `backend/src/app/api/quests/daily/route.ts`, `backend/src/app/api/pvp/strike/route.ts`, `wiki/audit/block-017-ios-claim-services-authoritative-reward-sync.md`, `wiki/audit/block-018-ios-typed-achievements-quests-loaders.md`, `wiki/audit/block-023-ios-interactive-combat-terminal-state-and-round-log.md`
- **Fixes:** removed stale audit warnings that still claimed `quests/daily` had live `any` debt and that `pvp/strike` still had an unresolved out-of-combat consumable recovery bug, even though those concerns were already closed by later code changes
- **Verification:** re-checked the live backend files, confirmed no remaining `any` usage in `quests/daily`, confirmed later PvP follow-up blocks already closed the old strike-path warnings, and re-ran targeted `git diff --check -- ...`

## [2026-04-17] audit | Block 157 stale audit tail sync for contraband and social challenges

Closed the next truth-sync block:
- **Created:** `[[block-157-stale-audit-tail-contraband-and-social-challenges-sync]]`
- **Files audited:** `backend/src/app/api/shop/contraband/route.ts`, `backend/src/app/api/shop/offers/route.ts`, `backend/src/app/api/social/challenges/route.ts`, `wiki/audit/block-012-backend-stash-contraband-premium-runtime.md`, `wiki/audit/block-013-backend-reward-premium-parity.md`
- **Fixes:** removed stale audit warnings that still claimed contraband/offers were bypassing shared reward grants and that `social/challenges` still carried route-local `any` debt
- **Verification:** re-checked live route usage of `grantRewardEntries(...)`, re-checked `social/challenges` for remaining `any` usage, ran targeted `eslint`, and re-ran targeted `git diff --check -- ...`

## [2026-04-17] audit | Block 158 backend item stat authority and rolled stats parity

Closed the next backend stat-authority block:
- **Created:** `[[block-158-backend-item-stat-authority-rolled-stats-parity]]`
- **Files audited:** `backend/src/lib/game/item-stats.ts`, `backend/tests/lib/item-stats.test.ts`, `backend/src/lib/game/inventory-response.ts`, `backend/src/app/api/inventory/route.ts`, `backend/src/app/api/stash/route.ts`, `backend/src/app/api/shop/upgrade/route.ts`, `backend/src/lib/game/equipment-stats.ts`, `backend/src/lib/game/build-stats.ts`, `wiki/audit/block-021-item-stat-authority-consumable-catalog.md`
- **Fixes:** added a shared backend helper for merged item stats, wired `rolledStats` into inventory/stash `effectiveStats`, upgrade before/after deltas, derived stat recomputation, and gear score, and removed the last raw `+ upgradeLevel` fallback from the full stat pipeline
- **Verification:** `cd backend && npx vitest run tests/lib/item-stats.test.ts`, targeted `eslint`, `cd backend && npm run build`, and targeted `git diff --check -- ...`

## [2026-04-17] audit | Block 159 iOS game init and item stat preview parity

Closed the next client stat-authority block:
- **Created:** `[[block-159-ios-game-init-item-stat-preview-parity]]`
- **Files audited:** `backend/src/app/api/game/init/route.ts`, `Hexbound/Hexbound/Models/Item.swift`, `Hexbound/Hexbound/Services/GameInitService.swift`, `wiki/audit/block-021-item-stat-authority-consumable-catalog.md`
- **Fixes:** added authoritative `effectiveStats` to the `game/init` equipment payload, threaded that snapshot into iOS cold-start inventory hydration, and fixed rolled-gear upgrade preview math so it subtracts merged `base + rolled` stats instead of `baseStats` only
- **Verification:** targeted backend `eslint`, `cd backend && npm run build`, `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, and targeted `git diff --check -- ...`

## [2026-04-17] audit | Block 160 iOS strike reveal partial-implementation boundary

Closed the next combat/docs truth-sync block:
- **Created:** `[[block-160-ios-strike-reveal-partial-implementation-boundary]]`
- **Files audited:** `Hexbound/Hexbound/Models/RoundVerdict.swift`, `Hexbound/Hexbound/Models/RoundExchange.swift`, `Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift`, `Hexbound/Hexbound/Views/Combat/InteractiveRoundLogCard.swift`, `Hexbound/Hexbound/Views/Combat/VFX/CombatVerdictFlash.swift`, `docs/07_ui_ux/STRIKE_REVEAL_SHAPE_B_PLAN.md`, `prototypes/strike-reveal-b.html`, `prototypes/strike-reveal-compact.html`, `prototypes/strike-reveal-integration.html`
- **Fixes:** removed the false pre-code framing from the Shape B plan, documented that verdict flash + verdict header are already live, and kept the three strike-reveal prototypes as intentional historical/design references instead of treating them like orphan residue
- **Inventory refresh:** updated current counts to `4992` in-scope files and `220 in-scope wiki markdown files / 216 wiki pages`
- **Verification:** re-checked live usages with `rg`, confirmed the reveal code is already wired in the shipped combat views/models, and re-ran `git diff --check`

## [2026-04-17] audit | Block 161 auth reset-password surface parity

Closed the next auth/docs truth-sync block:
- **Created:** `[[block-161-auth-reset-password-surface-parity]]`
- **Files audited:** `backend/src/app/api/auth/forgot-password/route.ts`, `backend/src/app/reset-password/page.tsx`, `backend/email-templates/reset-password.html`, `wiki/features/auth.md`, `docs/03_backend_and_api/API_REFERENCE.md`
- **Fixes:** updated auth docs so they no longer imply password reset lives only in Supabase dashboard state, documented the repo-owned reset email template and hosted `/reset-password` landing page, and clarified the public API reference wording for the reset flow
- **Inventory refresh:** updated current counts to `4993` in-scope files and `221 in-scope wiki markdown files / 217 wiki pages`
- **Verification:** re-checked the live forgot-password route, reset page, and template references with `rg`, and re-ran `git diff --check`

## [2026-04-17] audit | Block 162 daily-login reward toast tail removal

Closed the next iOS reward-surface cleanup block:
- **Created:** `[[block-162-daily-login-reward-toast-tail-removal]]`
- **Files audited:** `Hexbound/Hexbound/Services/DailyLoginService.swift`, `Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupViewModel.swift`, `Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift`, `Hexbound/Hexbound/App/AppState.swift`, `wiki/decisions/why-reward-modal-over-toast.md`, `wiki/audit/block-016-backend-daily-login-battle-pass-reward-contracts.md`
- **Fixes:** removed the leftover success toast from `DailyLoginService.claimReward()` so the CLAIMED modal remains the only reward surface on the happy path while error toasts stay intact
- **Inventory refresh:** updated current counts to `4994` in-scope files and `222 in-scope wiki markdown files / 218 wiki pages`
- **Verification:** confirmed the old success-toast string no longer exists in the daily-login service and re-ran `git diff --check`

## [2026-04-17] audit | Block 163 hub tutorial quest reward modal parity

Closed the next iOS reward-surface cleanup block:
- **Created:** `[[block-163-hub-tutorial-quest-reward-modal-parity]]`
- **Files audited:** `Hexbound/Hexbound/Views/Hub/HubView.swift`, `Hexbound/Hexbound/Tutorial/TutorialManager.swift`, `Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift`, `Hexbound/Hexbound/App/AppState.swift`, `wiki/decisions/why-reward-modal-over-toast.md`, `wiki/audit/block-078-ios-tutorial-manager-typed-contract-cleanup.md`
- **Fixes:** replaced the Hub tutorial quest success toast with the shared CLAIMED modal ceremony, built reward config from the typed tutorial quest claim payload, and expanded the reward-modal decision page so tutorial quest claim is explicitly inside the rule
- **Inventory refresh:** updated current counts to `4995` in-scope files and `223 in-scope wiki markdown files / 219 wiki pages`
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `BUILD SUCCEEDED`, and `git diff --check` passed

## [2026-04-17] audit | Block 164 iOS gold mine bonus reward modal parity

Closed the next iOS reward-surface cleanup block:
- **Created:** `[[block-164-ios-gold-mine-bonus-reward-modal-parity]]`
- **Files audited:** `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`, `Hexbound/Hexbound/Views/Minigames/GoldMineDetailView.swift`, `Hexbound/Hexbound/Views/Minigames/MineClaimRewardView.swift`, `wiki/features/gold-mine.md`, `wiki/decisions/why-reward-modal-over-toast.md`
- **Fixes:** replaced the remaining Gold Mine bonus payout reward toasts with the existing mine reward modal, clarified the modal's shared role for collect and bonus payouts, and updated the feature/decision docs so the reward surface matches runtime reality
- **Inventory refresh:** updated current counts to `4996` in-scope files and `224 in-scope wiki markdown files / 220 wiki pages`
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `BUILD SUCCEEDED`, and `git diff --check` passed

## [2026-04-17] audit | Block 165 iOS upgrade stat bonus config fallback parity

Closed the next item-stat parity block:
- **Created:** `[[block-165-ios-upgrade-stat-bonus-config-fallback-parity]]`
- **Files audited:** `backend/src/app/api/game/init/route.ts`, `Hexbound/Hexbound/Models/Item.swift`, `Hexbound/Hexbound/Services/GameInitService.swift`, `Hexbound/Hexbound/Services/GameDataCache.swift`, `wiki/audit/block-021-item-stat-authority-consumable-catalog.md`, `wiki/audit/block-159-ios-game-init-item-stat-preview-parity.md`
- **Fixes:** exported `upgradeStatBonusPerLevel` through `game/init`, seeded iOS local item fallback math from typed bootstrap config instead of a hard-coded `+1`, and reset the fallback bonus during cache invalidation so stale config does not leak across logout/reset boundaries
- **Inventory refresh:** updated current counts to `4997` in-scope files and `225 in-scope wiki markdown files / 221 wiki pages`
- **Verification:** `cd backend && npm run build`, `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, and `git diff --check` all passed

## [2026-04-17] audit | Block 166 iOS referral apply reward modal parity

Closed the next iOS reward-surface cleanup block:
- **Created:** `[[block-166-ios-referral-apply-reward-modal-parity]]`
- **Files audited:** `Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift`, `Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift`, `Hexbound/Hexbound/App/AppState.swift`, `wiki/features/referral.md`, `wiki/decisions/why-reward-modal-over-toast.md`
- **Fixes:** replaced the invitee-side referral apply gold toast with the shared CLAIMED modal, kept the inline status message for local confirmation, and expanded the feature/decision docs so referral apply is explicitly inside the modal-only reward rule
- **Inventory refresh:** updated current counts to `4998` in-scope files and `226 in-scope wiki markdown files / 222 wiki pages`
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` and `git diff --check` both passed

## [2026-04-17] audit | Block 167 iOS mail claim reward modal parity

Closed the next iOS reward-surface cleanup block:
- **Created:** `[[block-167-ios-mail-claim-reward-modal-parity]]`
- **Files audited:** `Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift`, `Hexbound/Hexbound/Models/MailMessage.swift`, `Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift`, `Hexbound/Hexbound/App/AppState.swift`, `wiki/features/mail.md`, `wiki/decisions/why-reward-modal-over-toast.md`
- **Fixes:** removed the premature reward haptic/sound from the optimistic inbox claim path, built a `CLAIMED!` modal from the authoritative mail claim payload plus attached loot, and updated the mail feature/decision docs so inbox reward claim is explicitly inside the shared reward-ceremony rule
- **Inventory refresh:** updated current counts to `4999` in-scope files and `227 in-scope wiki markdown files / 223 wiki pages`
- **Verification:** `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` and `git diff --check` both passed

## [2026-04-17] audit | Block 168 backend character progression derived-stats transaction parity

Closed the next backend progression-safety block:
- **Created:** `[[block-168-backend-character-progression-derived-stats-transaction-parity]]`
- **Files audited:** `backend/src/app/api/characters/[id]/allocate-stats/route.ts`, `backend/src/app/api/characters/[id]/buy-stat-points/route.ts`, `backend/src/app/api/characters/[id]/respec-stats/route.ts`, `backend/src/app/api/prestige/route.ts`, `backend/src/lib/game/equipment-stats.ts`, `backend/tests/api/character-progression-derived-stats.test.ts`, `wiki/audit/block-038-backend-utility-routes-and-character-warning-cleanup.md`
- **Fixes:** moved derived-stat recomputation for allocate-stats, bought stat points, respec, and prestige inside the same write transaction as the base progression mutation, added focused regression coverage for all four routes, and closed the old `respec-stats` audit tail that still described recomputation as post-commit risk
- **Inventory refresh:** updated current counts to `5001` in-scope files and `228 in-scope wiki markdown files / 224 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/character-progression-derived-stats.test.ts`, `cd backend && npx eslint 'src/app/api/characters/[id]/allocate-stats/route.ts' 'src/app/api/characters/[id]/buy-stat-points/route.ts' 'src/app/api/characters/[id]/respec-stats/route.ts' 'src/app/api/prestige/route.ts' tests/api/character-progression-derived-stats.test.ts`, `cd backend && npm run build`, and `git diff --check` all passed

## [2026-04-17] audit | Block 169 stale audit tail item stat preview sync

Closed the next truth-sync block:
- **Created:** `[[block-169-stale-audit-tail-item-stat-preview-sync]]`
- **Files audited:** `wiki/audit/block-020-inventory-typed-snapshots-legacy-consumables.md`, `wiki/audit/block-159-ios-game-init-item-stat-preview-parity.md`, `wiki/audit/block-165-ios-upgrade-stat-bonus-config-fallback-parity.md`
- **Fixes:** removed the stale `Needs review` warning from the old `Item.swift` record in `block-020`, linked it to the later `block-159` and `block-165` fixes, and narrowed the remaining question to intentional local-preview policy instead of broken upgrade-bonus math
- **Inventory refresh:** updated current counts to `5002` in-scope files and `229 in-scope wiki markdown files / 225 wiki pages`
- **Verification:** re-read the synced item-stat audit chain and re-ran `git diff --check`

## [2026-04-17] audit | Block 170 backend appearance wallet response boundary

Closed the next backend/API boundary block:
- **Created:** `[[block-170-backend-appearance-wallet-response-boundary]]`
- **Files audited:** `backend/src/app/api/characters/[id]/appearance/route.ts`, `Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift`, `wiki/audit/block-038-backend-utility-routes-and-character-warning-cleanup.md`
- **Fixes:** added canonical `wallet.gold` to the appearance response, kept the old `character.gold` and top-level `gold` only as compatibility aliases, taught the iOS appearance editor to prefer the typed wallet field, and closed the old mixed-boundary audit warning in `block-038`
- **Inventory refresh:** updated current counts to `5003` in-scope files and `230 in-scope wiki markdown files / 226 wiki pages`
- **Verification:** `cd backend && npx eslint 'src/app/api/characters/[id]/appearance/route.ts'`, `cd backend && npm run build`, `xcodebuild -project /Users/artosetrov/Documents/Cursor\ AI/PVP\ RPG/Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, and `git diff --check`

## [2026-04-17] audit | Block 171 project git helper tracked-only staging

Closed the next project-script safety block:
- **Created:** `[[block-171-project-git-helper-tracked-only-staging]]`
- **Files audited:** `scripts/git-commit-push.sh`, `scripts/git-watcher.sh`, `wiki/audit/block-006-project-scripts.md`
- **Fixes:** changed both Git helper scripts to stage tracked changes only by default via `git add -u`, left untracked files as an explicit opt-in via `--all` / `HEXBOUND_GIT_HELPER_STAGE_ALL=1`, and updated the old scripts audit so the Git-helper records no longer advertise whole-tree auto-stage as an unresolved risk
- **Inventory refresh:** updated current counts to `5004` in-scope files and `231 in-scope wiki markdown files / 227 wiki pages`
- **Verification:** `bash -n scripts/git-commit-push.sh scripts/git-watcher.sh` and `git diff --check`

## [2026-04-17] audit | Block 172 audio and asset doc boundary parity

Closed the next scripts/docs truth-sync block:
- **Created:** `[[block-172-audio-and-asset-doc-boundary-parity]]`
- **Files audited:** `docs/08_prompts/SOUND_CATALOG.md`, `docs/07_ui_ux/ASSET_CONSISTENCY_AUDIT.md`, `Hexbound/Hexbound/Persistence/SFXCatalog.swift`, `scripts/sync-assets.sh`, `wiki/audit/block-006-project-scripts.md`
- **Fixes:** added an explicit historical/planning boundary to `SOUND_CATALOG.md`, rewrote the old `512px` `sync-assets.sh` references in `ASSET_CONSISTENCY_AUDIT.md` so they read as audit-time findings rather than current script truth, and narrowed the old `block-006` docs tail to boundary wording instead of silent source-of-truth drift
- **Inventory refresh:** updated current counts to `5005` in-scope files and `232 in-scope wiki markdown files / 228 wiki pages`
- **Verification:** `git diff --check` plus targeted grep re-checks against `SFXCatalog.swift`, `scripts/sync-assets.sh`, and the updated docs

## [2026-04-17] audit | Block 173 admin design-system dead preview export removal

Closed the next admin design-system cleanup block:
- **Created:** `[[block-173-admin-design-system-dead-preview-export-removal]]`
- **Files audited:** `admin/src/app/(dashboard)/design-system/ds-components-2.tsx`, `admin/src/app/(dashboard)/design-system/design-system-client.tsx`, `wiki/audit/block-059-admin-design-system-residual-debt-and-warning-cleanup.md`
- **Fixes:** confirmed `HeroWidgetPreviews` and `StanceDisplayPreviews` had no live imports, deleted both dead exports from the legacy preview file, and closed the stale `Needs review` note in `block-059`
- **Inventory refresh:** updated current counts to `5006` in-scope files and `233 in-scope wiki markdown files / 229 wiki pages`
- **Verification:** `cd admin && npx eslint 'src/app/(dashboard)/design-system/ds-components-2.tsx'`, `cd admin && npx next build`, and `git diff --check`

## [2026-04-17] audit | Block 174 stale audit tail prototype decision sync

Closed the next truth-sync block:
- **Created:** `[[block-174-stale-audit-tail-prototype-decision-sync]]`
- **Files audited:** `wiki/audit/block-121-prototypes-link-parity-and-transition-state.md`, `wiki/audit/block-146-delete-legal-transition-prototype-copies.md`, `wiki/audit/block-147-delete-final-combat-history-prototypes.md`
- **Fixes:** updated the stale `Needs review` records for `combat-proto-B2.html`, `combat-proto-B2-v3.html`, and `privacy.html` so they now explicitly point at the later cleanup blocks that resolved those keep/delete decisions
- **Inventory refresh:** updated current counts to `5007` in-scope files and `234 in-scope wiki markdown files / 230 wiki pages`
- **Verification:** `git diff --check`

## [2026-04-17] audit | Block 175 wiki opponent-profile and onboarding feature pages

Closed the next wiki atlas gap block:
- **Created:** `[[block-175-wiki-opponent-profile-and-onboarding-feature-pages]]`
- **Files audited:** `wiki/features/opponent-profile.md`, `wiki/features/onboarding.md`, `wiki/features/social.md`, `wiki/audit/block-122-wiki-feature-map-visibility-and-related-link-gaps.md`, `wiki/index.md`
- **Fixes:** created the missing `opponent-profile` and `onboarding` feature pages, surfaced both in the main feature atlas, updated the stale “memory-only” wording in `social.md`, and closed the last remaining `block-122` dead-end link records as resolved follow-up work
- **Inventory refresh:** updated current counts to `5010` in-scope files and `237 in-scope wiki markdown files / 233 wiki pages`
- **Verification:** `git diff --check` and related-link rescans for `[[opponent-profile]]` / `[[onboarding]]`

## [2026-04-17] audit | Block 176 stale audit tail audio bootstrap boundary sync

Closed the next truth-sync block:
- **Created:** `[[block-176-stale-audit-tail-audio-bootstrap-boundary-sync]]`
- **Files audited:** `wiki/audit/block-006-project-scripts.md`, `scripts/download_sounds.py`, `docs/08_prompts/SOUND_CATALOG.md`
- **Fixes:** removed the stale open warning on `download_sounds.py` from `block-006` now that the script explicitly documents itself as a bootstrap helper and `SOUND_CATALOG.md` is explicitly framed as a historical planning snapshot rather than runtime truth
- **Inventory refresh:** updated current counts to `5011` in-scope files and `238 in-scope wiki markdown files / 234 wiki pages`
- **Verification:** `git diff --check` plus re-read of the updated script/docs boundary chain

## [2026-04-17] audit | Block 177 stale audit tail item-balance cross-process sync

Closed the next truth-sync block:
- **Created:** `[[block-177-stale-audit-tail-item-balance-cross-process-sync]]`
- **Files audited:** `wiki/audit/block-047-backend-dungeon-item-balance-live-config-hardening.md`, `wiki/audit/block-048-admin-item-balance-backend-proxy-alignment.md`, `admin/src/app/api/admin/item-balance/profiles/route.ts`, `admin/src/lib/backend-api.ts`, `backend/src/app/api/admin/item-balance/profiles/route.ts`
- **Fixes:** removed the stale `block-047` warning that still assumed the separate admin app wrote item-balance profiles through its own process; after the later proxy cutover, profile writes now go through the backend canonical route that also owns immediate cache invalidation
- **Inventory refresh:** updated current counts to `5012` in-scope files and `239 in-scope wiki markdown files / 235 wiki pages`
- **Verification:** `git diff --check` plus re-read of the current admin proxy path and backend invalidation route

## [2026-04-17] audit | Block 178 stale audit tail tutorial migration sync

Closed the next truth-sync block:
- **Created:** `[[block-178-stale-audit-tail-tutorial-migration-sync]]`
- **Files audited:** `wiki/audit/block-009-prisma-migrations-onboarding-gold-and-w3d5.md`, `backend/prisma/migrations/20260407_add_tutorial_onboarding/migration.sql`, `backend/prisma/migrations/20260410_add_tutorial_completed/migration.sql`, `backend/prisma/migrations/20260415_backfill_tutorial_completion_state/migration.sql`, `backend/src/app/api/tutorial/skip/route.ts`, `backend/src/app/api/tutorial/scripted-fight/preload/route.ts`, `backend/src/app/api/tutorial/scripted-fight/resolve/route.ts`
- **Fixes:** removed the stale open-status tail on the two tutorial-state migrations in `block-009` now that the later backfill migration and replay-guard fixes are already in place and documented in the same chain
- **Inventory refresh:** updated current counts to `5013` in-scope files and `240 in-scope wiki markdown files / 236 wiki pages`
- **Verification:** `git diff --check` plus re-read of the migration/repair chain inside `block-009`

## [2026-04-17] audit | Block 179 instant retro local state de-tracking

Closed the next cleanup block:
- **Created:** `[[block-179-instant-retro-local-state-de-tracking]]`
- **Files audited:** `.claude/skills/instant-retro/SKILL.md`, `.claude/skills/instant-retro/last-retro.json`, `.gitignore`, `wiki/audit/block-004-claude-product-governance-skills.md`
- **Fixes:** moved mutable `instant-retro` checkpoint state out of tracked `.claude/skills` into ignored `.claude/tmp/instant-retro-last.json`, seeded the new local JSON for continuity, deleted the tracked `last-retro.json` from the working tree, and closed the old `block-004` de-tracking decision
- **Inventory refresh:** updated current counts to `5014` in-scope files and `241 in-scope wiki markdown files / 235 wiki pages`
- **Verification:** `git diff --check` plus re-read of the updated skill path and seeded ignored local-state JSON

## [2026-04-17] audit | Block 180 backend achievement cosmetic claim runtime parity

Closed the next achievement/runtime parity block:
- **Created:** `[[block-180-backend-achievement-cosmetic-claim-runtime-parity]]`
- **Files audited:** `backend/src/lib/game/achievement-claims.ts`, `backend/src/app/api/achievements/claim/route.ts`, `backend/src/app/api/achievements/[key]/claim/route.ts`, `backend/tests/lib/achievement-claims.test.ts`, `backend/tests/api/achievement-claim.test.ts`, `Hexbound/Hexbound/Services/AchievementService.swift`, `Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift`, `docs/03_backend_and_api/API_REFERENCE.md`, `wiki/features/achievements.md`
- **Fixes:** extended achievement claim runtime to grant cosmetic `title/frame` rewards through the cosmetics table, returned stable cosmetic identifiers from both claim routes, taught the iOS achievements CLAIMED modal to present cosmetic rewards instead of dropping them, and closed the old open mismatch records in `block-045` and `block-057`
- **Inventory refresh:** updated current counts to `5016` in-scope files and `242 in-scope wiki markdown files / 236 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/lib/achievement-claims.test.ts tests/api/achievement-claim.test.ts`, `cd backend && npm run build`, `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, and `git diff --check`

## [2026-04-17] audit | Block 181 admin achievement cosmetic authoring parity

Closed the next admin/runtime parity block:
- **Created:** `[[block-181-admin-achievement-cosmetic-authoring-parity]]`
- **Files audited:** `admin/src/lib/achievement-definitions.ts`, `admin/src/actions/achievement-definitions.ts`, `admin/src/app/(dashboard)/achievements/achievements-client.tsx`, `wiki/features/achievements.md`
- **Fixes:** widened admin achievement authoring back to the live `gold/gems/xp/title/frame` reward surface, made `rewardId` required for cosmetic rewards, surfaced stored `rewardId` values in the definitions table, and synced the achievements feature page so the admin surface no longer lies about currency-only claims
- **Inventory refresh:** updated current counts to `5017` in-scope files and `243 in-scope wiki markdown files / 237 wiki pages`
- **Verification:** `cd admin && npx eslint src/lib/achievement-definitions.ts 'src/app/(dashboard)/achievements/achievements-client.tsx' src/actions/achievement-definitions.ts`, `cd admin && npx next build`, and `git diff --check`

## [2026-04-17] audit | Block 182 backend achievement list definition text parity

Closed the next achievement/runtime parity block:
- **Created:** `[[block-182-backend-achievement-list-definition-text-parity]]`
- **Files audited:** `backend/src/lib/game/achievement-catalog.ts`, `backend/src/app/api/achievements/route.ts`, `backend/tests/lib/achievement-catalog.test.ts`, `backend/tests/api/achievement-list.test.ts`, `wiki/features/achievements.md`
- **Fixes:** preserved admin-authored `title` / `description` in the normalized achievement catalog, made `GET /api/achievements` prefer live definition text over stale route-local display copy, and added route coverage proving the player-facing list now honors active definition text while still serializing cosmetic rewards
- **Inventory refresh:** updated current counts to `5018` in-scope files and `244 in-scope wiki markdown files / 238 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/lib/achievement-catalog.test.ts tests/api/achievement-list.test.ts`, `cd backend && npx eslint src/lib/game/achievement-catalog.ts src/app/api/achievements/route.ts tests/lib/achievement-catalog.test.ts tests/api/achievement-list.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-17] audit | Block 183 achievement doc count and reward summary parity

Closed the next truth-sync block:
- **Created:** `[[block-183-achievement-doc-count-and-reward-summary-parity]]`
- **Files audited:** `backend/src/lib/game/achievement-catalog.ts`, `wiki/index.md`, `wiki/features/achievements.md`, `wiki/systems/achievements.md`, `docs/features/achievements/ACHIEVEMENTS_OVERVIEW.md`, `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`
- **Fixes:** updated high-visibility achievement summaries from the stale `21`-entry / gem-only wording to the live `18`-entry catalog and the current currency/cosmetic reward surface, and clarified that list copy now comes from active definitions when present
- **Inventory refresh:** updated current counts to `5019` in-scope files and `245 in-scope wiki markdown files / 239 wiki pages`
- **Verification:** re-read `backend/src/lib/game/achievement-catalog.ts` against all touched docs plus `git diff --check`

## [2026-04-17] audit | Block 184 achievement product doc runtime parity

Closed the next product-doc truth-sync block:
- **Created:** `[[block-184-achievement-product-doc-runtime-parity]]`
- **Files audited:** `backend/src/lib/game/achievement-catalog.ts`, `docs/02_product_and_features/GAME_SYSTEMS.md`, `docs/06_game_systems/BALANCE_CONSTANTS.md`, `docs/06_game_systems/PROGRESSION.md`
- **Fixes:** replaced the stale `30+` / extra-category / prestige-reset achievement narrative in older product/system docs with the live `18`-achievement runtime, clarified that achievement rewards are a mixed currency/cosmetic surface, and removed the false impression that achievements are a gem-only or reset-per-prestige lane
- **Inventory refresh:** updated current counts to `5020` in-scope files and `246 in-scope wiki markdown files / 240 wiki pages`
- **Verification:** re-read `backend/src/lib/game/achievement-catalog.ts` against the touched docs plus `git diff --check`

## [2026-04-17] audit | Block 185 stale operations tail env and landing sync

Closed the next stale-doc tail:
- **Created:** `[[block-185-stale-operations-tail-env-and-landing-sync]]`
- **Files audited:** `docs/10_operations/GIT_AND_DEPLOY_AUDIT.md`, `docs/10_operations/DEPLOY.md`, `docs/10_operations/RELEASE_IOS.md`, `Hexbound/Hexbound/App/AppConstants.swift`, `wiki/audit/block-109-operations-deploy-docs-reality-sync.md`
- **Fixes:** removed the stale “landing/static deploy undocumented” warning now that `DEPLOY.md` already codifies the hosted landing/legal path, and reclassified iOS environment targeting from a docs-status unknown to a documented caveat because `RELEASE_IOS.md` already explains that `staging` currently aliases the production API host
- **Inventory refresh:** updated current counts to `5021` in-scope files and `247 in-scope wiki markdown files / 241 wiki pages`
- **Verification:** re-read `DEPLOY.md`, `RELEASE_IOS.md`, and `AppConstants.swift` against `GIT_AND_DEPLOY_AUDIT.md` plus `git diff --check`

## [2026-04-17] audit | Block 186 backend guest OAuth wallet merge parity

Closed the next auth/runtime parity block:
- **Created:** `[[block-186-backend-guest-oauth-wallet-merge-parity]]`
- **Files audited:** `backend/src/app/api/auth/upgrade-guest-oauth/route.ts`, `backend/tests/api/auth-upgrade-guest-oauth.test.ts`, `wiki/features/auth.md`, `wiki/audit/block-013-backend-reward-premium-parity.md`
- **Fixes:** made guest→OAuth upgrade merge `gold` and `gems` instead of dropping/overwriting wallet state, preserved the later `premiumGemClaimDate`, and taught the route to keep the longer-lived `dailyGemCard` when both guest and OAuth-side rows exist
- **Inventory refresh:** updated current counts to `5023` in-scope files and `248 in-scope wiki markdown files / 242 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/auth-upgrade-guest-oauth.test.ts`, `cd backend && npx eslint src/app/api/auth/upgrade-guest-oauth/route.ts tests/api/auth-upgrade-guest-oauth.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-17] audit | Block 187 backend forgot-password canonical host fallback

Closed the next auth/runtime parity block:
- **Created:** `[[block-187-backend-forgot-password-canonical-host-fallback]]`
- **Files audited:** `backend/src/app/api/auth/forgot-password/route.ts`, `backend/tests/api/auth-forgot-password.test.ts`, `wiki/features/auth.md`, `wiki/audit/block-161-auth-reset-password-surface-parity.md`, `docs/10_operations/DEPLOY.md`
- **Fixes:** replaced the stale `iron-fist-arena-backend.vercel.app` fallback in forgot-password with the canonical `api.hexboundapp.com` production backend origin, added regression coverage for both the default host and env override path, and synced the auth wiki/audit trail so the reset-flow host contract is explicit
- **Inventory refresh:** updated current counts to `5025` in-scope files and `249 in-scope wiki markdown files / 248 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/auth-forgot-password.test.ts`, `cd backend && npx eslint src/app/api/auth/forgot-password/route.ts tests/api/auth-forgot-password.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-17] audit | Block 188 auth link-account surface parity

Closed the next auth truth-sync block:
- **Created:** `[[block-188-auth-link-account-surface-parity]]`
- **Files audited:** `backend/src/app/api/auth/link-account/route.ts`, `Hexbound/Hexbound/Views/Settings/SettingsViewModel.swift`, `docs/03_backend_and_api/API_REFERENCE.md`, `wiki/features/auth.md`
- **Fixes:** reclassified `/auth/link-account` from the misleading “guest merge with social” wording to the narrower compatibility route it actually is, added an explicit legacy/compatibility note to the backend route, and documented that the live iOS settings flow sends guests through `upgradeGuest` instead of this endpoint
- **Inventory refresh:** updated current counts to `5026` in-scope files and `250 in-scope wiki markdown files / 249 wiki pages`
- **Verification:** `rg -n "link-account|upgradeGuest" Hexbound backend docs wiki -S` and `git diff --check`

## [2026-04-17] audit | Block 189 backend link-account duplicate email guard

Closed the next auth/runtime parity block:
- **Created:** `[[block-189-backend-link-account-duplicate-email-guard]]`
- **Files audited:** `backend/src/app/api/auth/link-account/route.ts`, `backend/tests/api/auth-link-account.test.ts`, `wiki/features/auth.md`, `wiki/audit/block-188-auth-link-account-surface-parity.md`
- **Fixes:** added an explicit duplicate-email guard to `/auth/link-account` so the compatibility route now returns `409` instead of falling through to a generic update failure, added route coverage for auth/conflict/success paths, and synced the auth feature page with the new collision behavior
- **Inventory refresh:** updated current counts to `5028` in-scope files and `251 in-scope wiki markdown files / 250 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/auth-link-account.test.ts`, `cd backend && npx eslint src/app/api/auth/link-account/route.ts tests/api/auth-link-account.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-17] audit | Block 190 backend sync-user duplicate email guard

Closed the next auth/runtime parity block:
- **Created:** `[[block-190-backend-sync-user-duplicate-email-guard]]`
- **Files audited:** `backend/src/app/api/auth/sync-user/route.ts`, `backend/tests/api/auth-sync-user.test.ts`, `wiki/features/auth.md`
- **Fixes:** added an explicit duplicate-email guard to `/auth/sync-user` so the route now returns `409` instead of relying on a later upsert conflict, added route coverage for auth/conflict/success paths, and synced the auth feature page with the new collision behavior
- **Inventory refresh:** updated current counts to `5030` in-scope files and `252 in-scope wiki markdown files / 251 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/auth-sync-user.test.ts`, `cd backend && npx eslint src/app/api/auth/sync-user/route.ts tests/api/auth-sync-user.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-18] audit | Block 191 backend guest-login device race recovery

Closed the next auth/runtime parity block:
- **Created:** `[[block-191-backend-guest-login-device-race-recovery]]`
- **Files audited:** `backend/src/app/api/auth/guest-login/route.ts`, `backend/tests/api/auth-guest-login.test.ts`, `wiki/features/auth.md`
- **Fixes:** extracted the guest restore path into a shared helper, moved fresh guest sign-in to after successful local `User` creation, and made the route delete the just-created Supabase guest then restore the existing device-linked guest when a `deviceId` race is detected instead of returning an orphan session with no local profile row
- **Inventory refresh:** updated current counts to `5033` in-scope files and `253 in-scope wiki markdown files / 252 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/auth-guest-login.test.ts`, `cd backend && npx eslint src/app/api/auth/guest-login/route.ts tests/api/auth-guest-login.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-18] audit | Block 192 backend guest-login sign-in failure cleanup

Closed the next auth/runtime parity block:
- **Created:** `[[block-192-backend-guest-login-signin-failure-cleanup]]`
- **Files audited:** `backend/src/app/api/auth/guest-login/route.ts`, `backend/tests/api/auth-guest-login.test.ts`, `wiki/features/auth.md`, `wiki/audit/block-191-backend-guest-login-device-race-recovery.md`
- **Fixes:** completed the fresh-guest rollback path so sign-in failure after successful local guest creation now deletes both the fresh Supabase guest and the fresh local `User` row instead of leaving a local orphan behind
- **Inventory refresh:** updated current counts to `5037` in-scope files and `254 in-scope wiki markdown files / 253 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/auth-guest-login.test.ts`, `cd backend && npx eslint src/app/api/auth/guest-login/route.ts tests/api/auth-guest-login.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-18] audit | Block 193 backend upgrade-guest full Supabase rollback

Closed the next auth/runtime parity block:
- **Created:** `[[block-193-backend-upgrade-guest-full-supabase-rollback]]`
- **Files audited:** `backend/src/app/api/auth/upgrade-guest/route.ts`, `backend/tests/api/auth-upgrade-guest.test.ts`, `wiki/features/auth.md`
- **Fixes:** completed the guest→email rollback path so repeated Prisma persistence failure now restores the previous guest auth identity materially in Supabase, including guest metadata and the prior guest email, instead of leaving auth upgraded while Prisma still says anonymous
- **Inventory refresh:** updated current counts to `5040` in-scope files and `256 in-scope wiki markdown files / 255 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/auth-upgrade-guest.test.ts`, `cd backend && npx eslint src/app/api/auth/upgrade-guest/route.ts tests/api/auth-upgrade-guest.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-18] audit | Block 194 backend OAuth local init cleanup and collision guards

Closed the next auth/runtime parity block:
- **Created:** `[[block-194-backend-oauth-local-init-cleanup-and-collision-guards]]`
- **Files audited:** `backend/src/app/api/auth/google/route.ts`, `backend/src/app/api/auth/apple/route.ts`, `backend/tests/api/auth-google-apple.test.ts`, `wiki/features/auth.md`
- **Fixes:** added duplicate-email guards and cleanup for first-time Google/Apple local bootstrap so OAuth sign-in now deletes the fresh Supabase user on local-init failure, returns `409` on duplicate-email collisions, and points the player at the explicit “log in and link from settings” path instead of a vague init error
- **Inventory refresh:** updated current counts to `5040` in-scope files and `256 in-scope wiki markdown files / 255 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/auth-upgrade-guest.test.ts tests/api/auth-google-apple.test.ts`, `cd backend && npx eslint src/app/api/auth/upgrade-guest/route.ts src/app/api/auth/google/route.ts src/app/api/auth/apple/route.ts tests/api/auth-upgrade-guest.test.ts tests/api/auth-google-apple.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-18] audit | Block 195 backend upgrade-guest-oauth transaction cleanup

Closed the next auth/runtime parity block:
- **Created:** `[[block-195-backend-upgrade-guest-oauth-transaction-cleanup]]`
- **Files audited:** `backend/src/app/api/auth/upgrade-guest-oauth/route.ts`, `backend/tests/api/auth-upgrade-guest-oauth.test.ts`, `wiki/features/auth.md`, `wiki/audit/block-186-backend-guest-oauth-wallet-merge-parity.md`
- **Fixes:** completed the guest→OAuth failure cleanup story so a transfer-transaction failure after successful OAuth sign-in now deletes the fresh OAuth auth user when no local OAuth row existed yet, instead of leaving an auth-only identity behind
- **Inventory refresh:** updated current counts to `5041` in-scope files and `257 in-scope wiki markdown files / 256 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/auth-upgrade-guest-oauth.test.ts tests/api/auth-upgrade-guest.test.ts tests/api/auth-google-apple.test.ts`, `cd backend && npx eslint src/app/api/auth/upgrade-guest-oauth/route.ts src/app/api/auth/upgrade-guest/route.ts src/app/api/auth/google/route.ts src/app/api/auth/apple/route.ts tests/api/auth-upgrade-guest-oauth.test.ts tests/api/auth-upgrade-guest.test.ts tests/api/auth-google-apple.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-18] audit | Block 196 backend register local-init cleanup

Closed the next auth/runtime parity block:
- **Created:** `[[block-196-backend-register-local-init-cleanup]]`
- **Files audited:** `backend/src/app/api/auth/register/route.ts`, `backend/tests/api/auth-register.test.ts`, `wiki/features/auth.md`
- **Fixes:** completed the email-register cleanup story so a local `User` bootstrap failure after successful Supabase create/sign-in now deletes the fresh auth user and returns `500 Failed to initialize account` instead of returning success with an auth-only email account
- **Inventory refresh:** updated current counts to `5042` in-scope files and `258 in-scope wiki markdown files / 257 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/auth-register.test.ts tests/api/auth-upgrade-guest-oauth.test.ts tests/api/auth-upgrade-guest.test.ts tests/api/auth-google-apple.test.ts`, `cd backend && npx eslint src/app/api/auth/register/route.ts src/app/api/auth/upgrade-guest-oauth/route.ts src/app/api/auth/upgrade-guest/route.ts src/app/api/auth/google/route.ts src/app/api/auth/apple/route.ts tests/api/auth-register.test.ts tests/api/auth-upgrade-guest-oauth.test.ts tests/api/auth-upgrade-guest.test.ts tests/api/auth-google-apple.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-18] audit | Block 197 backend login local-row bootstrap parity

Closed the next auth/runtime parity block:
- **Created:** `[[block-197-backend-login-local-row-bootstrap-parity]]`
- **Files audited:** `backend/src/app/api/auth/login/route.ts`, `backend/tests/api/auth-login.test.ts`, `wiki/features/auth.md`
- **Fixes:** split login’s local bootstrap into explicit update/create branches so missing local rows are recreated deliberately, duplicate-email collisions now return `409`, and login no longer silently issues tokens behind a failed local identity bootstrap
- **Inventory refresh:** updated current counts to `5045` in-scope files and `259 in-scope wiki markdown files / 258 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/auth-login.test.ts tests/api/auth-register.test.ts tests/api/auth-upgrade-guest-oauth.test.ts tests/api/auth-upgrade-guest.test.ts tests/api/auth-google-apple.test.ts`, `cd backend && npx eslint src/app/api/auth/login/route.ts src/app/api/auth/register/route.ts src/app/api/auth/upgrade-guest-oauth/route.ts src/app/api/auth/upgrade-guest/route.ts src/app/api/auth/google/route.ts src/app/api/auth/apple/route.ts tests/api/auth-login.test.ts tests/api/auth-register.test.ts tests/api/auth-upgrade-guest-oauth.test.ts tests/api/auth-upgrade-guest.test.ts tests/api/auth-google-apple.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-18] audit | Block 198 backend auth guest local-row race recovery

Closed the next auth/runtime parity block:
- **Created:** `[[block-198-backend-auth-guest-local-row-race-recovery]]`
- **Files audited:** `backend/src/lib/auth.ts`, `backend/src/app/api/auth/guest/route.ts`, `backend/tests/api/auth-guest.test.ts`, `wiki/features/auth.md`
- **Fixes:** split raw Supabase token validation into `getSupabaseAuthUser(req)`, let `/auth/guest` bootstrap the missing local row directly, and made the route reload the row when a concurrent create wins instead of dying behind the old helper-level missing-row `401`/generic `500`
- **Inventory refresh:** updated current counts to `5053` in-scope files and `263 in-scope wiki markdown files / 262 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/auth-guest.test.ts`, `cd backend && npx eslint src/lib/auth.ts src/app/api/auth/guest/route.ts tests/api/auth-guest.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-18] audit | Block 199 backend me local-row bootstrap parity

Closed the next auth/runtime parity block:
- **Created:** `[[block-199-backend-me-local-row-bootstrap-parity]]`
- **Files audited:** `backend/src/app/api/me/route.ts`, `backend/tests/api/me.test.ts`, `wiki/features/auth.md`, `docs/03_backend_and_api/API_REFERENCE.md`
- **Fixes:** moved `/api/me` onto raw Supabase auth validation, preserved banned-user `401`, added missing-row bootstrap plus create-race reload, and returned `409` on duplicate-email collisions instead of drifting into `401`/`404` ambiguity
- **Inventory refresh:** updated current counts to `5053` in-scope files and `263 in-scope wiki markdown files / 262 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/me.test.ts`, `cd backend && npx eslint src/app/api/me/route.ts tests/api/me.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-18] audit | Block 200 backend PvP history missing-opponent guard

Closed the next PvP/runtime parity block:
- **Created:** `[[block-200-backend-pvp-history-missing-opponent-guard]]`
- **Files audited:** `backend/src/app/api/pvp/history/route.ts`, `backend/tests/api/pvp-history.test.ts`, `wiki/features/pvp-combat.md`
- **Fixes:** converted `/pvp/history` response shaping to skip rows with no resolved opponent relation instead of crashing the whole history response on null `player2`
- **Inventory refresh:** updated current counts to `5053` in-scope files and `263 in-scope wiki markdown files / 262 wiki pages`
- **Verification:** `cd backend && npx vitest run tests/api/pvp-history.test.ts`, `cd backend && npx eslint src/app/api/pvp/history/route.ts tests/api/pvp-history.test.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-18] audit | Block 201 backend interactive PvP opponent-null contract guard

Closed the next PvP/runtime parity block:
- **Created:** `[[block-201-backend-interactive-pvp-opponent-null-contract-guard]]`
- **Files audited:** `backend/src/app/api/pvp/strike/route.ts`, `backend/src/app/api/pvp/match/complete/route.ts`, `wiki/features/pvp-combat.md`, `docs/03_backend_and_api/API_REFERENCE.md`
- **Fixes:** added explicit `409 Player-vs-player opponent missing` guards to `strike` and `match/complete`, narrowed the rest of the flow onto a non-null `player2Id`, and documented the contract instead of relying on nullability drift
- **Inventory refresh:** updated current counts to `5053` in-scope files and `263 in-scope wiki markdown files / 262 wiki pages`
- **Verification:** `cd backend && npx eslint src/app/api/pvp/strike/route.ts src/app/api/pvp/match/complete/route.ts`, `cd backend && npm run build`, and `git diff --check`

## [2026-04-19] audit | Block 202 backend analytics warning cleanup and inventory marker sync

Closed the next backend/runtime truth-sync block:
- **Created:** `[[block-202-backend-analytics-warning-cleanup-and-inventory-marker-sync]]`
- **Files audited:** `backend/src/lib/analytics.ts`, `wiki/audit/project-file-inventory.md`
- **Fixes:** removed stale lint suppressions from `backend/src/lib/analytics.ts`, left analytics runtime behavior unchanged, and corrected the inventory marker that still claimed the file was untracked even though it already lived in Git
- **Inventory refresh:** updated current counts to `5064` in-scope files and `266 in-scope wiki markdown files / 265 wiki pages`
- **Verification:** prior `cd backend && npm run build` runs had already isolated `backend/src/lib/analytics.ts` as the remaining warning tail in this slice, and `git diff --check` passes after the cleanup

## [2026-04-19] audit | Block 203 inventory tracked-marker parity for recent runtime wave

Closed the next inventory truth-sync block:
- **Created:** `[[block-203-inventory-tracked-marker-parity-for-recent-runtime-wave]]`
- **Files audited:** `wiki/audit/project-file-inventory.md` plus the recent backend/iOS/prototype/wiki wave it still mislabeled as `_(untracked)_`
- **Fixes:** removed stale `_(untracked)_` markers from already-tracked backend tests/helpers, iOS runtime files, retained strike-reveal prototype references, and recent audit pages after `git ls-files` confirmed the files already lived in Git
- **Inventory refresh:** updated current counts to `5065` in-scope files and `267 in-scope wiki markdown files / 266 wiki pages`
- **Verification:** `git ls-files -- <corrected file set>` and `git diff --check`

## [2026-04-19] audit | Block 204 inventory tracked-marker parity for late auth and feature pages

Closed the next inventory truth-sync block:
- **Created:** `[[block-204-inventory-tracked-marker-parity-for-late-auth-and-feature-pages]]`
- **Files audited:** `wiki/audit/project-file-inventory.md`, late auth audit pages, `wiki/features/onboarding.md`, `wiki/features/opponent-profile.md`, `wiki/decisions/why-reward-modal-over-toast.md`, and `backend/src/app/reset-password/page.tsx`
- **Fixes:** removed the remaining stale `_(untracked)_` markers from the later auth/audit wave plus the hosted reset-password page and late-added feature/decision pages after `git ls-files` confirmed they were already tracked
- **Inventory refresh:** updated current counts to `5066` in-scope files and `268 in-scope wiki markdown files / 267 wiki pages`
- **Verification:** `git ls-files -- <corrected file set>` and `git diff --check`

## [2026-04-19] audit | Block 205 analytics doc split and event-count parity

Closed the next analytics truth-sync block:
- **Created:** `[[block-205-analytics-doc-split-and-event-count-parity]]`
- **Files audited:** `backend/src/lib/analytics.ts`, `backend/src/lib/game/tutorial-analytics.ts`, `docs/02_product_and_features/ONBOARDING_SPEC.md`, `docs/features/gold-mine/GOLD_MINE_MINIGAME_PLAN.md`, `wiki/features/tutorial.md`
- **Fixes:** updated tutorial analytics docs from `7` to `8` events, clarified that tutorial funnel logging is separate from the 7-event provider-agnostic core analytics contract, and replaced the stale Gold Mine plan reference to the non-existent `backend/src/lib/analytics/events.ts` file
- **Inventory refresh:** updated current counts to `5067` in-scope files and `269 in-scope wiki markdown files / 268 wiki pages`
- **Verification:** live helper comparison (`backend/src/lib/analytics.ts` vs `backend/src/lib/game/tutorial-analytics.ts`) plus `git diff --check`

## [2026-04-19] audit | Block 206 iOS analytics auth-provider enum parity

Closed the next analytics/runtime typing block:
- **Created:** `[[block-206-ios-analytics-auth-provider-enum-parity]]`
- **Files audited:** `Hexbound/Hexbound/Services/AnalyticsService.swift`, `backend/src/lib/analytics.ts`
- **Fixes:** added a dedicated Swift `AnalyticsAuthProvider` enum, narrowed `AnalyticsEvent.signup` away from raw `String`, and kept the wire payload unchanged by serializing back through `rawValue`
- **Inventory refresh:** updated current counts to `5068` in-scope files and `270 in-scope wiki markdown files / 269 wiki pages`
- **Verification:** contract comparison against `backend/src/lib/analytics.ts` plus `git diff --check`

## [2026-04-19] audit | Block 207 admin analytics surface parity and dead helper removal

Closed the next admin/runtime truth-sync block:
- **Created:** `[[block-207-admin-analytics-surface-parity-and-dead-helper-removal]]`
- **Files audited:** `admin/src/actions/analytics.ts`, `backend/src/app/api/admin/stats/route.ts`, `backend/src/app/api/admin/economy/route.ts`, `backend/src/app/api/admin/iap/route.ts`, `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `docs/03_backend_and_api/API_REFERENCE.md`
- **Fixes:** deleted the dead `admin/src/actions/analytics.ts` helper after confirming it had no imports, rewrote admin capability docs to describe the narrower live stats/economy/IAP review surface, and corrected API docs so `/admin/iap` is described as IAP transaction review rather than generic analytics
- **Inventory refresh:** updated current counts to `5068` in-scope files and `271 in-scope wiki markdown files / 270 wiki pages`
- **Verification:** dead-helper import search across `admin/src`, live route inspection for `stats/economy/iap`, and `git diff --check`

## [2026-04-19] audit | Block 208 project overview analytics surface parity

Closed the next source-of-truth analytics block:
- **Created:** `[[block-208-project-overview-analytics-surface-parity]]`
- **Files audited:** `docs/01_source_of_truth/PROJECT_OVERVIEW.md`, `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `backend/src/app/api/admin/stats/route.ts`, `backend/src/app/api/admin/economy/route.ts`, `backend/src/app/api/admin/iap/route.ts`
- **Fixes:** rewrote the current analytics section in `PROJECT_OVERVIEW.md` to describe the live aggregate stats/economy/IAP review surface, moved retention/session-style analytics back into future-work wording, and renamed the roadmap item so it no longer reads like a half-live dashboard
- **Inventory refresh:** updated current counts to `5069` in-scope files and `272 in-scope wiki markdown files / 271 wiki pages`
- **Verification:** live source-of-truth comparison against admin docs/routes plus `git diff --check`

## [2026-04-19] audit | Block 209 iOS analytics scaffold boundary sync

Closed the next analytics truth-sync block:
- **Created:** `[[block-209-ios-analytics-scaffold-boundary-sync]]`
- **Files audited:** `Hexbound/Hexbound/Services/AnalyticsService.swift`, `docs/retro/RETRO_2026-04-18.md`
- **Fixes:** clarified in code comments and retrospective docs that `AnalyticsService.swift` is currently a dormant typed scaffold with no live call-sites yet, while backend analytics plus tutorial structured logs remain the active instrumentation paths
- **Inventory refresh:** updated current counts to `5070` in-scope files and `273 in-scope wiki markdown files / 272 wiki pages`
- **Verification:** `rg -n "AnalyticsService\\.shared|setBackend\\(|track\\(" Hexbound/Hexbound -g '*.swift'` plus `git diff --check`

## [2026-04-19] audit | Block 210 combat telemetry doc proposal boundary sync

Closed the next analytics/combat truth-sync block:
- **Created:** `[[block-210-combat-telemetry-doc-proposal-boundary-sync]]`
- **Files audited:** `docs/features/combat/COMBAT_MECHANIC_SPEC.md`, `docs/features/combat/INTERACTIVE_COMBAT_PLAN.md`, `backend/src/lib/analytics.ts`
- **Fixes:** reframed combat telemetry docs so interactive-combat events are treated as a future analytics extension instead of a live event family already backed by the current provider-agnostic analytics contract
- **Inventory refresh:** updated current counts to `5071` in-scope files and `274 in-scope wiki markdown files / 273 wiki pages`
- **Verification:** live contract comparison against `backend/src/lib/analytics.ts` plus `git diff --check`

## [2026-04-19] audit | Block 211 admin settings and system surface parity

Closed the next admin surface truth-sync block:
- **Created:** `[[block-211-admin-settings-and-system-surface-parity]]`
- **Files audited:** `admin/src/app/(dashboard)/settings/page.tsx`, `admin/src/app/(dashboard)/settings/settings-client.tsx`, `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- **Fixes:** rewrote the settings/system sections in `ADMIN_CAPABILITIES.md` so they describe the live Settings page (basic DB/config/admin-user info, fixed-role management, config seeding) instead of promising standalone User Activity Log, Performance Monitoring, System Status, Audit Trail, or custom-role builder pages that do not exist in the current dashboard
- **Inventory refresh:** updated current counts to `5072` in-scope files and `275 in-scope wiki markdown files / 274 wiki pages`
- **Verification:** live settings-page comparison plus `git diff --check`

## [2026-04-19] audit | Block 212 orchestrator and doc-index admin analytics parity

Closed the next navigation-layer truth-sync block:
- **Created:** `[[block-212-orchestrator-and-doc-index-admin-analytics-parity]]`
- **Files audited:** `docs/ORCHESTRATOR.md`, `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`, `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- **Fixes:** narrowed the Admin Panel Engineer zone wording in `ORCHESTRATOR.md` and rewrote the `DOCUMENTATION_INDEX.md` admin summary so both now describe the same live stats/economy/IAP review + settings/role-management surface as the current admin capabilities doc
- **Inventory refresh:** updated current counts to `5073` in-scope files and `276 in-scope wiki markdown files / 275 wiki pages`
- **Verification:** comparison against the updated admin capabilities doc plus `git diff --check`

## [2026-04-19] audit | Block 213 backend analytics scaffold boundary sync

Closed the next analytics truth-sync block:
- **Created:** `[[block-213-backend-analytics-scaffold-boundary-sync]]`
- **Files audited:** `backend/src/lib/analytics.ts`, `docs/retro/RETRO_2026-04-18.md`, `backend/src/lib/game/tutorial-analytics.ts`
- **Fixes:** clarified in code comments and retrospective docs that the generic backend analytics layer is currently a typed scaffold without live `track(...)` emitters, while `tutorial-analytics.ts` remains the active instrumentation path today
- **Inventory refresh:** updated current counts to `5074` in-scope files and `277 in-scope wiki markdown files / 276 wiki pages`
- **Verification:** `rg -n "\\btrack\\(" backend/src -g '*.ts'` plus `git diff --check`

## [2026-04-19] audit | Block 214 delete orphan admin review routes

Closed the next admin review/runtime cleanup block:
- **Created:** `[[block-214-delete-orphan-admin-review-routes]]`
- **Files audited:** `backend/src/app/api/admin/economy/route.ts`, `backend/src/app/api/admin/iap/route.ts`, `backend/src/app/api/admin/stats/route.ts`, `backend/src/app/api/admin/iap-products/route.ts`, `admin/src/app/(dashboard)/economy/page.tsx`, `admin/src/app/(dashboard)/iap-products/page.tsx`, `admin/src/app/api/admin/iap-products/route.ts`, `docs/03_backend_and_api/API_REFERENCE.md`, `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `wiki/_generated/api-routes.json`
- **Fixes:** deleted the orphan backend admin review routes for `stats`, `economy`, and `iap` after confirming the live admin review surface already runs through admin-owned server actions/direct read-side flow, retained the still-live `iap-products` backend route chain, and synced API/docs/generated route maps to that narrower reality
- **Inventory refresh:** updated current counts to `5072` in-scope files and `278 in-scope wiki markdown files / 277 wiki pages`
- **Verification:** repo-wide route-consumer search, live `economy`/`iap-products` page comparison, and `git diff --check`

## [2026-04-19] audit | Block 215 shop feature map IAP Products admin surface parity

Closed the next shop/admin truth-sync block:
- **Created:** `[[block-215-shop-feature-map-iap-products-admin-surface-parity]]`
- **Files audited:** `wiki/features/shop.md`, `admin/src/app/(dashboard)/iap-products/page.tsx`, `admin/src/app/(dashboard)/iap-products/iap-products-client.tsx`, `admin/src/app/api/admin/iap-products/route.ts`, `backend/src/app/api/admin/iap-products/route.ts`
- **Fixes:** updated the shop feature map so the dedicated `IAP Products` admin page is visible as a first-class surface, documented its proxy/backend route chain, and marked it as a read-only catalog review page instead of leaving it hidden behind a generic admin-tuning note
- **Inventory refresh:** updated current counts to `5073` in-scope files and `279 in-scope wiki markdown files / 278 wiki pages`
- **Verification:** live page/proxy/backend comparison plus `git diff --check`

## [2026-04-19] audit | Block 216 admin monetization wording vs live IAP Products surface

Closed the next monetization truth-sync block:
- **Created:** `[[block-216-admin-monetization-wording-vs-live-iap-products-surface]]`
- **Files audited:** `docs/01_source_of_truth/PROJECT_OVERVIEW.md`, `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/src/app/(dashboard)/iap-products/page.tsx`, `admin/src/app/(dashboard)/iap-products/iap-products-client.tsx`, `backend/src/app/api/admin/iap-products/route.ts`
- **Fixes:** rewrote monetization wording so docs now describe `IAP Products` as a read-only catalog review surface, not a live dashboard SKU-management tool
- **Inventory refresh:** updated current counts to `5074` in-scope files and `280 in-scope wiki markdown files / 279 wiki pages`
- **Verification:** live page/client/backend comparison plus `git diff --check`

## [2026-04-19] audit | Block 217 admin economy review vs fantasy analytics dashboard

Closed the next admin monetization truth-sync block:
- **Created:** `[[block-217-admin-economy-review-vs-fantasy-analytics-dashboard]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `docs/01_source_of_truth/PROJECT_OVERVIEW.md`, `admin/src/app/(dashboard)/economy/page.tsx`, `admin/src/app/(dashboard)/economy/economy-client.tsx`, `admin/src/actions/economy.ts`
- **Fixes:** replaced the fantasy analytics-dashboard wording with the actual live economy review surface, and rewrote the Daily Gem Card wording so it no longer implies a dedicated live config page
- **Inventory refresh:** updated current counts to `5075` in-scope files and `281 in-scope wiki markdown files / 280 wiki pages`
- **Verification:** live economy page/client/actions comparison plus `git diff --check`

## [2026-04-19] audit | Block 218 admin push surface vs live campaign sender

Closed the next admin comms truth-sync block:
- **Created:** `[[block-218-admin-push-surface-vs-live-campaign-sender]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/src/app/(dashboard)/push/page.tsx`, `admin/src/app/(dashboard)/push/push-client.tsx`, `admin/src/actions/push.ts`, `admin/src/lib/push-campaigns.ts`
- **Fixes:** rewrote the push section so it now describes the actual broadcast/segment/user campaign sender with class/level filters and sent/failed/token counters instead of promising richer cohort targeting, recurring sends, A/B tests, or open/click analytics
- **Inventory refresh:** updated current counts to `5076` in-scope files and `282 in-scope wiki markdown files / 281 wiki pages`
- **Verification:** live push page/client/actions/lib comparison plus `git diff --check`

## [2026-04-19] audit | Block 219 admin feature-flags targeting surface parity

Closed the next rollout-controls truth-sync block:
- **Created:** `[[block-219-admin-feature-flags-targeting-surface-parity]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/src/lib/feature-flags.ts`, `admin/src/actions/feature-flags.ts`, `admin/src/app/(dashboard)/flags/flags-client.tsx`
- **Fixes:** rewrote the feature-flags section so it now matches the live environment + level/class/userId targeting model, documents tags and seed-default-flags, and removes the implication that the dashboard already ships richer beta-tester/platform/region cohort builders or rollout analytics
- **Inventory refresh:** updated current counts to `5077` in-scope files and `283 in-scope wiki markdown files / 282 wiki pages`
- **Verification:** live flags client/actions/lib comparison plus `git diff --check`

## [2026-04-19] audit | Block 220 admin balance and offers surface parity

Closed the next admin balancing truth-sync block:
- **Created:** `[[block-220-admin-balance-and-offers-surface-parity]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/src/app/(dashboard)/loot/loot-client.tsx`, `admin/src/app/(dashboard)/offers/offers-client.tsx`, `admin/src/app/(dashboard)/balance/balance-client.tsx`, `admin/src/app/(dashboard)/config/config-client.tsx`, `admin/src/app/(dashboard)/item-balance/page.tsx`, `admin/src/app/(dashboard)/item-balance/dashboard-client.tsx`, `admin/src/app/(dashboard)/item-balance/simulation/simulation-client.tsx`, `admin/src/app/(dashboard)/item-balance/config/config-editor-client.tsx`
- **Fixes:** rewrote the loot/offers/upgrade-config/config-manager/item-balance sections so they now describe the actual live admin tools and removed stale claims about scheduled changes, player-impact forecasting, A/B pricing, or saved experiment-profile surfaces that the current dashboard does not ship
- **Inventory refresh:** updated current counts to `5078` in-scope files and `284 in-scope wiki markdown files / 283 wiki pages`
- **Verification:** live loot/offers/balance/config/item-balance comparison plus `git diff --check`

## [2026-04-19] audit | Block 221 admin items CRUD surface parity

Closed the next content-ops truth-sync block:
- **Created:** `[[block-221-admin-items-crud-surface-parity]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/src/app/(dashboard)/items/items-client.tsx`, `admin/src/app/(dashboard)/items/_components/item-editor-client.tsx`, `admin/src/app/(dashboard)/items/_components/item-preview-modal.tsx`, `admin/src/app/api/items/route.ts`
- **Fixes:** rewrote the items section so it now matches the live form/upload/preview/delete surface and removed stale claims about CSV tooling, soft-delete warnings, change history, duplicate-item flows, and 3D preview
- **Inventory refresh:** updated current counts to `5079` in-scope files and `285 in-scope wiki markdown files / 284 wiki pages`
- **Verification:** live items list/editor/modal/route comparison plus `git diff --check`

## [2026-04-19] audit | Block 222 admin player appearance mail and footer surface parity

Closed the next stale capability block inside `ADMIN_CAPABILITIES.md`:
- **Created:** `[[block-222-admin-player-appearance-mail-and-footer-surface-parity]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/src/app/(dashboard)/players/players-client.tsx`, `admin/src/app/(dashboard)/players/[id]/player-client.tsx`, `admin/src/app/(dashboard)/appearances/appearances-client.tsx`, `admin/src/app/(dashboard)/mail/mail-client.tsx`, `admin/src/actions/mail.ts`
- **Fixes:** rewrote the players, appearances, mail, and footer notes so they now describe the actual live admin surfaces and removed stale claims about soft delete, 3D preview, scheduled/repeating mail, richer attachments, generic undo, and CSV bulk tooling
- **Inventory refresh:** updated current counts to `5080` in-scope files and `286 in-scope wiki markdown files / 285 wiki pages`
- **Verification:** live players/appearance/mail comparison plus `git diff --check`

## [2026-04-19] audit | Block 223 admin arena dungeons assets surface parity

Closed the next stale capability block inside `ADMIN_CAPABILITIES.md`:
- **Created:** `[[block-223-admin-arena-dungeons-assets-surface-parity]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/src/app/(dashboard)/matches/page.tsx`, `admin/src/app/(dashboard)/dungeons/dungeons-client.tsx`, `admin/src/app/(dashboard)/dungeons/[id]/dungeon-editor.tsx`, `admin/src/app/(dashboard)/assets/assets-client.tsx`
- **Fixes:** rewrote the arena/matches, dungeons, and assets sections so they now describe the real review/editor/browser surfaces and removed stale claims about fraud invalidation, filters, forecasting, template saves, sprite generation, usage tracking, and guarded delete rules
- **Inventory refresh:** updated current counts to `5081` in-scope files and `287 in-scope wiki markdown files / 286 wiki pages`
- **Verification:** live matches/dungeons/assets comparison plus `git diff --check`

## [2026-04-19] audit | Block 224 admin gameplay systems surface parity

Closed the next stale gameplay-systems block inside `ADMIN_CAPABILITIES.md`:
- **Created:** `[[block-224-admin-gameplay-systems-surface-parity]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/src/app/(dashboard)/skills/skills-client.tsx`, `admin/src/app/(dashboard)/passives/passives-client.tsx`, `admin/src/app/(dashboard)/quests/quests-client.tsx`, `admin/src/app/(dashboard)/events/events-client.tsx`, `admin/src/app/(dashboard)/seasons/seasons-client.tsx`
- **Fixes:** rewrote the skills, passives, quests, events, and seasons sections so they now describe the real CRUD/editor surfaces and removed stale claims about combat simulators, drag-tree tooling, seasonal planners, participation analytics, and battle-pass control flows that those screens do not ship
- **Inventory refresh:** updated current counts to `5082` in-scope files and `288 in-scope wiki markdown files / 287 wiki pages`
- **Verification:** live skills/passives/quests/events/seasons comparison plus `git diff --check`

## [2026-04-19] audit | Block 225 admin consumables achievements and snapshots surface parity

Closed the next stale capability block inside `ADMIN_CAPABILITIES.md`:
- **Created:** `[[block-225-admin-consumables-achievements-and-snapshots-surface-parity]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/src/app/(dashboard)/consumables/consumables-client.tsx`, `admin/src/app/(dashboard)/achievements/achievements-client.tsx`, `admin/src/app/(dashboard)/snapshots/snapshots-client.tsx`, `admin/src/actions/snapshots.ts`
- **Fixes:** rewrote the consumables, achievements, and snapshots sections so they now describe the real catalog/config, definition/stats, and create/rollback/delete surfaces and removed stale claims about standalone consumable CRUD, broader template builders, and snapshot diff tooling
- **Inventory refresh:** updated current counts to `5083` in-scope files and `289 in-scope wiki markdown files / 288 wiki pages`
- **Verification:** live consumables/achievements/snapshots comparison plus `git diff --check`

## [2026-04-19] audit | Block 226 admin dashboard and economy overview surface parity

Closed the next stale overview block inside `ADMIN_CAPABILITIES.md`:
- **Created:** `[[block-226-admin-dashboard-and-economy-overview-surface-parity]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/src/app/(dashboard)/dashboard-client.tsx`, `admin/src/actions/dashboard.ts`, `admin/src/app/(dashboard)/economy/economy-client.tsx`
- **Fixes:** rewrote the dashboard and economy-overview sections so they now describe the real KPI/alerts/charts/review surfaces and removed stale claims about active-match KPIs, inline leaderboard, 30-day circulation charts, faucet/sink time series, and automated exploit alerts on those pages
- **Inventory refresh:** updated current counts to `5084` in-scope files and `290 in-scope wiki markdown files / 289 wiki pages`
- **Verification:** live dashboard/economy comparison plus `git diff --check`

## [2026-04-19] audit | Block 227 admin role settings and security wording parity

Closed the next stale access-model block inside `ADMIN_CAPABILITIES.md`:
- **Created:** `[[block-227-admin-role-settings-and-security-wording-parity]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/src/lib/auth.ts`, `admin/src/app/api/auth/login/route.ts`, `admin/src/app/(dashboard)/settings/page.tsx`, `admin/src/app/api/settings/role/route.ts`, `admin/src/actions/item-balance.ts`
- **Fixes:** rewrote the roles/settings/security section so it now matches the real fixed-role auth model, admin-only settings flow, simulation-history surface, and narrower audit/rollback semantics instead of implying a stricter enterprise permissions matrix than the repo currently ships
- **Inventory refresh:** updated current counts to `5085` in-scope files and `291 in-scope wiki markdown files / 290 wiki pages`
- **Verification:** live auth/settings/item-balance comparison plus `git diff --check`

## [2026-04-19] audit | Block 228 admin remaining page surface inventory parity

Closed the next stale page-map block inside `ADMIN_CAPABILITIES.md`:
- **Created:** `[[block-228-admin-remaining-page-surface-inventory-parity]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/src/components/layout/nav-items.ts`, `admin/src/app/(dashboard)/battle-pass/page.tsx`, `admin/src/app/(dashboard)/battle-pass/battle-pass-client.tsx`, `admin/src/app/(dashboard)/daily-login/page.tsx`, `admin/src/app/(dashboard)/daily-login/daily-login-client.tsx`, `admin/src/app/(dashboard)/iap-products/page.tsx`, `admin/src/app/(dashboard)/iap-products/iap-products-client.tsx`, `admin/src/app/(dashboard)/matchmaking/page.tsx`, `admin/src/app/(dashboard)/minigame-sessions/page.tsx`, `admin/src/app/(dashboard)/minigame-sessions/minigame-sessions-client.tsx`, `admin/src/app/(dashboard)/referrals/page.tsx`, `admin/src/app/(dashboard)/social/page.tsx`, `admin/src/app/(dashboard)/dungeon-map/page.tsx`, `admin/src/app/(dashboard)/dungeon-map/dungeon-map-client.tsx`, `admin/src/app/(dashboard)/design-system/page.tsx`, `admin/src/app/(dashboard)/design-system/design-system-client.tsx`
- **Fixes:** added first-class capability sections for the remaining live sidebar routes, rewrote the bottom page inventory so it now includes `Matchmaking`, `Referrals`, `IAP Products`, `Minigame Sessions`, and the real placement of `Social`, and narrowed each section to the actual live page behavior instead of implied analytics/moderation/storybook tooling
- **Inventory refresh:** updated current counts to `5127` in-scope files and `294 in-scope wiki markdown files / 293 wiki pages`
- **Verification:** live nav/page comparison plus `git diff --check`

## [2026-04-19] audit | Block 229 admin tech stack and data fetching parity

Closed the next stale implementation-summary block inside `ADMIN_CAPABILITIES.md`:
- **Created:** `[[block-229-admin-tech-stack-and-data-fetching-parity]]`
- **Files audited:** `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `admin/package.json`, `admin/src/lib/backend-api.ts`, `admin/src/lib/backend-admin.ts`, `admin/src/components/forms/dynamic-form.tsx`, `admin/src/app/(dashboard)/dungeon-map/dungeon-map-client.tsx`
- **Fixes:** rewrote the bottom tech-stack / backend-integration / data-fetching section so it now reflects the actual Next.js 15 + Recharts + server-action/direct-fetch model, and removed stale claims about a repo-wide React Query layer, websocket metrics, and generic debounced autosave
- **Inventory refresh:** updated current counts to `5128` in-scope files and `295 in-scope wiki markdown files / 294 wiki pages`
- **Verification:** package/runtime search plus `git diff --check`

## [2026-04-19] audit | Block 230 project overview liveops and admin surface parity

Closed the next source-of-truth drift block adjacent to the admin cleanup:
- **Created:** `[[block-230-project-overview-liveops-and-admin-surface-parity]]`
- **Files audited:** `docs/01_source_of_truth/PROJECT_OVERVIEW.md`, `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `wiki/features/daily-login.md`, `wiki/features/shop.md`, `wiki/features/auth.md`, `admin/src/lib/feature-flags.ts`, `admin/src/actions/feature-flags.ts`, `admin/src/app/(dashboard)/flags/flags-client.tsx`, `admin/src/actions/push.ts`, `admin/src/lib/push-campaigns.ts`, `admin/src/app/(dashboard)/push/push-client.tsx`
- **Fixes:** rewrote stale liveops/admin wording in `PROJECT_OVERVIEW.md` so it now matches the cleaned repo truth — daily login is back to the live 7-day cycle, feature flags are gradual-rollout/targeting tools instead of a full A/B suite, push now describes sent/failed + token-count review, IAP wording reflects backend receipt validation, and the admin summary no longer promises broader scheduling/audit/simulation tooling than the current dashboard ships
- **Inventory refresh:** updated current counts to `5129` in-scope files and `296 in-scope wiki markdown files / 295 wiki pages`
- **Verification:** source-of-truth comparison plus `git diff --check`

## [2026-04-19] audit | Block 231 auth feature map admin surface parity

Closed the next stale admin-path tail in the auth feature map:
- **Created:** `[[block-231-auth-feature-map-admin-surface-parity]]`
- **Files audited:** `wiki/features/auth.md`, `admin/src/app/login/page.tsx`, `admin/src/app/(dashboard)/players/page.tsx`, `admin/src/app/(dashboard)/players/[id]/page.tsx`, `admin/src/app/(dashboard)/settings/page.tsx`, `admin/src/app/api/settings/role/route.ts`
- **Fixes:** replaced the deleted `admin/src/app/(dashboard)/users/` path with the real auth-adjacent admin surfaces: login, players, settings, and role mutation
- **Inventory refresh:** updated current counts to `5131` in-scope files and `297 in-scope wiki markdown files / 296 wiki pages`
- **Verification:** path existence check plus `git diff --check`

## [2026-04-19] audit | Block 232 documentation index admin workflow parity

Closed the next master-index drift block adjacent to the admin cleanup:
- **Created:** `[[block-232-source-of-truth-documentation-index-admin-workflow-parity]]`
- **Files audited:** `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`, `docs/05_admin_panel/ADMIN_CAPABILITIES.md`, `docs/03_backend_and_api/API_REFERENCE.md`
- **Fixes:** refreshed the documentation-index freshness banner, rewrote the admin/operations quick-reference and workflow checklist language, and removed the stale assumption that `ADMIN_CAPABILITIES.md` is a universal config-key registry or default execution path for every balance/content workflow
- **Inventory refresh:** updated current counts to `5134` in-scope files and `298 in-scope wiki markdown files / 297 wiki pages`
- **Verification:** source-of-truth comparison plus `git diff --check`

## [2026-04-19] audit | Block 233 daily login and referral feature-map admin boundary sync

Closed the next feature-map boundary block after the admin capability cleanup:
- **Created:** `[[block-233-feature-maps-daily-login-and-referral-admin-boundary-sync]]`
- **Files audited:** `wiki/features/daily-login.md`, `wiki/features/referral.md`, `admin/src/app/(dashboard)/daily-login/page.tsx`, `admin/src/app/(dashboard)/daily-login/daily-login-client.tsx`, `admin/src/app/(dashboard)/referrals/page.tsx`, `Hexbound/Hexbound/Services/DailyLoginService.swift`
- **Fixes:** replaced older “if present” wording with the real daily-login and referrals admin pages, documented the current `DailyLoginService.swift` surface, locked daily-login wording back to the live 7-day cycle, and marked referrals as a read-only claims-review surface instead of a funnel analytics dashboard
- **Inventory refresh:** updated current counts to `5135` in-scope files and `299 in-scope wiki markdown files / 298 wiki pages`
- **Verification:** live page/service existence check plus `git diff --check`

## [2026-04-19] audit | Block 234 leaderboard and dungeon rush feature-map admin boundary sync

Closed the next pair of stale admin-boundary tails in the feature-map layer:
- **Created:** `[[block-234-feature-maps-leaderboard-and-dungeon-rush-admin-boundary-sync]]`
- **Files audited:** `wiki/features/leaderboard.md`, `wiki/features/dungeon-rush.md`, `admin/src/app/(dashboard)/matches/page.tsx`, `admin/src/app/(dashboard)/players/[id]/page.tsx`, `admin/src/app/(dashboard)/minigame-sessions/page.tsx`, `admin/src/app/(dashboard)/minigame-sessions/minigame-sessions-client.tsx`
- **Fixes:** replaced the phantom leaderboard admin page with the real matches/player-detail review surfaces, removed the implied manual rating-adjust tool, and replaced the vague Dungeon Rush admin note with the live minigame-sessions review surface plus an explicit “no rush-specific room-catalog editor today” boundary
- **Inventory refresh:** updated current counts to `5136` in-scope files and `300 in-scope wiki markdown files / 299 wiki pages`
- **Verification:** live page existence check plus `git diff --check`

## [2026-04-19] audit | Block 235 minigames and social runtime boundary sync

Closed the next speculative runtime-boundary block in the feature-map layer:
- **Created:** `[[block-235-feature-maps-minigames-and-social-runtime-boundary-sync]]`
- **Files audited:** `wiki/features/minigames.md`, `wiki/features/social.md`, `admin/src/app/(dashboard)/social/page.tsx`, `Hexbound/Hexbound/Views/Minigames/ShellGameViewModel.swift`, `Hexbound/Hexbound/Views/Minigames/FortuneWheelViewModel.swift`, `backend/src/lib/game/guild-challenge.ts`, `backend/tests/api/shell-game-start.test.ts`, `backend/tests/api/shell-game-guess.test.ts`, `backend/tests/api/shell-game-play-deprecated.test.ts`, `backend/tests/api/social-challenges.test.ts`, `backend/tests/api/social-messages.test.ts`
- **Fixes:** removed speculative shared minigame service/helper wording, rewrote social admin as a read-only review surface instead of a moderation console, replaced the speculative guild helper note with the real `guild-challenge.ts`, and swapped vague test placeholders for the current route-level test files
- **Inventory refresh:** updated current counts to `5137` in-scope files and `301 in-scope wiki markdown files / 300 wiki pages`
- **Verification:** live file existence checks plus `git diff --check`

## [2026-04-19] audit | Block 236 inventory summary and section header parity

Closed the next inventory consistency block after the feature-map wave:
- **Created:** `[[block-236-inventory-summary-and-section-header-parity]]`
- **Files audited:** `wiki/audit/project-file-inventory.md`, `git ls-files`, `git ls-files --others --exclude-standard`
- **Fixes:** refreshed the top tracked/untracked/in-scope counts, refreshed category totals, and updated stale section-header counts so the inventory no longer contradicts itself after the late admin/wiki cleanup wave
- **Inventory refresh:** updated current counts to `5140` in-scope files and `302 in-scope wiki markdown files / 301 wiki pages`
- **Verification:** git-derived count comparison plus `git diff --check`

## [2026-04-19] lesson | xcodebuild stale DerivedData masquerades as real compile errors

Mid-session `xcodebuild ... build` failed with linker `Undefined symbols: Hexbound.BossInfo.init(id:…isRealBoss:tagline:) + default argument 8` from `DungeonService.o`, and a separate pass reported `TalentsTabView.swift:100` cascade — `"no dynamic member 'unlockPremiumSlot' using key path from root type 'PassiveTreeViewModel'"` + `"referencing subscript 'subscript(dynamicMember:)' requires wrapper 'Bindable<PassiveTreeViewModel>'"` + `"cannot call value of non-function type 'Binding<Subject>'"`. Both methods/members were present in source — `BossInfo` had the expected memberwise init with `tagline: String? = nil`, and `PassiveTreeViewModel.unlockPremiumSlot()` existed at line 405 with backend route + service + model already wired. A clean-then-build (`xcodebuild ... clean build`) passed with zero code changes.

- **Takeaway:** when `xcodebuild` reports `Undefined symbols` for a memberwise init (usually just after a struct's field list changed), OR a `@Bindable`/`@Observable` VM method triggers the three-error "no dynamic member → Bindable wrapper → Binding<Subject>" cascade on code that clearly exists, **clean the module before editing the source**. Do not delete methods, retype call sites, or add `@_silgen_name` shims — the source is fine, DerivedData is the problem.
- **Recovery:** `cd Hexbound && xcodebuild -project Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' -configuration Debug clean build`. If the error recurs immediately after the clean build, only then is it a real source bug.
- **Why the cascade looks scary:** Swift's type-checker falls back to `@dynamicMemberLookup` via `Bindable`'s subscript when it can't resolve a direct method on the observable — so the actual root cause ("the .o file linked against an older struct layout") shows up as a type-inference failure three layers removed. Easy to misread as a real API mismatch.
- **Reference on the day:** first observed during the 90-file in-flight refactor that eventually became `5f28635` (interactive combat polish + boss reveal ceremony + analytics split + admin scaffolding + wiki audit 202-213). No code fix was merged for it — `clean build` alone was the fix.
