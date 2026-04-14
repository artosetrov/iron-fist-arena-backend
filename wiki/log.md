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
