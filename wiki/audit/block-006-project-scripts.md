---
title: Audit Block 006 — Project Scripts
category: audit
tags: [audit, scripts, tooling, automation, asset-pipeline]
sources:
  - scripts/
  - CLAUDE.md
  - docs/07_ui_ux/ASSET_CONSISTENCY_AUDIT.md
  - docs/08_prompts/SOUND_CATALOG.md
updated: 2026-04-15
---

# Audit Block 006 — Project Scripts

## Scope

This block covers the 10 project-owned files in `scripts/`. These scripts sit on critical operational paths: schema drift, design-system drift, asset export/sync, Git automation, sound bootstrap, and Figma token checks.

- **Files audited in this block:** 10
- **Primary file types:** shell, Python, Node.js
- **Status:** High-risk tooling hazards reduced; a few scripts remain architectural review candidates
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-002-repo-automation]], [[design-system]], [[bug-patterns]]

## Summary

- The block has three clear clusters: quality guards (`check_*`, `ds-drift-check.py`), asset/design tooling (`export-assets-for-figma.sh`, `sync-assets.sh`, `sync-figma-tokens.*`), and Git automation (`git-commit-push.sh`, `git-watcher.sh`).
- The most serious defect was in `check_schema_drift.py`: it originally validated only `@map(...)` columns, so unmapped scalar/enum Prisma fields were invisible to the guard. During continued audit work this guard was further extended to cover Prisma enum values, require `migration_lock.toml`, and reject hidden/nested artifacts inside migration directories, because migration history had already drifted on `EventType` and later accumulated a duplicate hotfix file.
- The Git automation scripts were workstation-bound and too aggressive: hardcoded path, blind lock deletion, and hardcoded push to `main`.
- The asset export script was incomplete against the real xcassets tree: the repo contains `jpg/jpeg` backgrounds, but the exporter only handled `png`.
- The sound bootstrap script is not the current audio source of truth. It still has value as a one-time downloader, but it is drifted from the production SFX catalog and should not be treated as canonical.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | `check_schema_drift.py` only validated `@map(...)` columns and did not inspect enum values or migration-directory hygiene. | New unmapped Prisma fields, missing enum migrations, or hidden junk inside migration folders could ship while the guard still reports green. | Extended schema parsing to include all scalar/enum fields, added enum-value coverage, now require `migration_lock.toml`, and fail on unexpected nested migration artifacts. Coverage rose to 692 checked columns and 114 checked enum values. |
| P1 | `git-commit-push.sh` and `git-watcher.sh` hardcoded one workstation path, blindly removed Git locks, and pushed `main`. | Wrong-repo execution, interference with active Git processes, and accidental push to the wrong branch. | Switched to repo-relative root detection, stale-lock checks, current-branch pushes, and subtree-remote guards. |
| P2 | `git-watcher.sh` auto-ran `sync-assets.sh` before every commit. | Unrelated network/file churn could get staged and committed implicitly. | Made asset sync opt-in via `HEXBOUND_AUTO_SYNC_ASSETS=1`. |
| P2 | `export-assets-for-figma.sh` only exported `png`. | Real `jpg/jpeg` backgrounds in xcassets never reached `figma-assets/`, creating DS/import drift. | Added support for `png/jpg/jpeg/pdf`, repo-relative paths, and atomic output replacement. |
| P2 | `download_sounds.py` claimed Python 3.7+ but used Python 3.10 union syntax and counted existing files as fresh downloads. | Bootstrap breaks on older Python; summary lies about actual work done. | Replaced `str | None` with `Optional[str]`, separated `downloaded/skipped/failed` states, and re-downloads corrupted tiny files. |
| P3 | `sync-figma-tokens.*` failed unclearly when `figma-tokens.json` or Swift token files were missing or malformed. | Manual DS sync flow fails with low-signal errors. | Added strict shell wrapper setup and explicit JSON/file-shape checks in the Node script. |

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `scripts/check_ios_backend_drift.sh` | iOS/backend guard | Scans iOS source for forbidden locally-owned balance constants that must come from backend `GameConfig`. | Depends on `Hexbound/Hexbound/App/AppConstants.swift`, Swift source tree. Used by preflight docs/rules and architecture docs. | `freePvpPerDay`, `maxStamina`, `pvpStaminaCost`, `xpPerLevel` may exist only as deprecated fallbacks in `AppConstants.swift`; loose declarations elsewhere are forbidden. | Script works and passes. No safe code fix needed in this block. | OK |
| `scripts/check_schema_drift.py` | Prisma migration guard | Compares Prisma schema columns/indexes/enum values with committed `migration.sql` files. | Depends on `backend/prisma/schema.prisma`, `backend/prisma/migrations/`, `backend/prisma/migrations/migration_lock.toml`. Used by CI, feature specs, release rules. | Every scalar/enum Prisma field, every enum value, and every `@@index`/`@@unique` must be backed by migrations, and migration directories must stay artifact-clean. | Major coverage bug found: only `@map(...)` fields were checked. Fixed parser to include all scalar/enum fields, added enum-value coverage, now fail clearly when Prisma migration history is missing `migration_lock.toml`, and now reject unexpected nested migration artifacts. Still one-way only: it does not flag extra DB columns. | Fixed |
| `scripts/download_sounds.py` | Audio bootstrap | Downloads a curated Pixabay seed set into `sounds/` without external Python deps. | Depends on Pixabay pages/search, local `sounds/`. Used manually only; no production pipeline calls it. | Curated URLs/search terms bootstrap a P0 audio set. This is not the production SFX source of truth. | Fixed Python 3.7 compatibility and skipped/downloaded accounting. Still drifted from current audio catalog (`docs/08_prompts/SOUND_CATALOG.md` expects mp3 names; app bundle/SFX code is wav-first and broader). | Needs review |
| `scripts/ds-drift-check.py` | Design-system parity guard | Compares iOS token source (`DarkFantasyTheme.swift`, `LayoutConstants.swift`) against admin `design-tokens.json`; optional `--fix` regenerates admin tokens from iOS. | Depends on iOS theme/layout files and `admin/src/lib/design-tokens.json`. Used manually; implied by DS audit workflows. | iOS remains token source of truth; admin tokens must match names/values. | Guard passes. Removed dead `os` import. Main remaining risk is heuristic parsing plus overlap with `sync-figma-tokens.js`. | Fixed |
| `scripts/export-assets-for-figma.sh` | XCAssets export | Exports categorized visual assets from xcassets into tracked `figma-assets/` for design import/reference. | Depends on `Hexbound/Hexbound/Resources/Assets.xcassets`. Used by `CLAUDE.md`, asset/design docs, manual Figma workflows. | Export should faithfully mirror importable xcasset visuals for design use. | Fixed format gap (`jpg/jpeg/pdf`), cwd dependence, and partial-output risk by using repo-relative paths and atomic swap. Open policy question: whether tracked `figma-assets/` should remain generated-in-repo. | Fixed |
| `scripts/git-commit-push.sh` | Auto Git helper | Stages all changes, commits, pushes current branch, optionally pushes admin subtree. | Depends on Git repo and optional `admin-deploy` remote. Used manually only. | Intended as a convenience helper when operating locally against the project repo. | Hardened repo detection, stale-lock handling, current-branch push, and subtree remote checks. Still auto-stages the whole repo and remains risky for shared/project-owned automation. | Needs review |
| `scripts/git-watcher.sh` | Trigger-based Git helper | Watches `.git-trigger`, then stages, commits, pushes current branch, and optionally pushes admin subtree. | Depends on Git repo, `.git-trigger`, optional `sync-assets.sh`, optional `admin-deploy` remote. Used by `CLAUDE.md`, herald docs, and older retros. | Watcher should be local/operator-controlled and should not silently introduce unrelated file churn. | Hardened path/branch/lock handling and made asset sync opt-in. It still auto-stages the whole repo and is a local workflow tool, not a safe shared project default. | Needs review |
| `scripts/sync-assets.sh` | Supabase → xcassets sync | Pulls selected Storage assets into xcassets, creates `.imageset`s, and writes bundled `asset-manifest.json`. | Depends on `backend/.env` or `.env.local`, Supabase Storage, `curl`, `python3`, optional `sips`. Used by `git-watcher.sh` when opt-in and by the runtime asset pipeline via `AssetManager.swift`. | Manifest and xcassets should reflect Storage content; resize must stay within display-quality rules. | No direct safe code change in this block. Risks remain: compares only by file size, produces manifest without dimensions/hashes, and performs networked file mutation from a script that may be run pre-commit. | Needs review |
| `scripts/sync-figma-tokens.js` | Figma token diff | Compares exported Figma tokens JSON to Swift tokens using hardcoded mapping tables. | Depends on `figma-tokens.json`, theme/layout Swift files. Used by `scripts/sync-figma-tokens.sh` and manual DS sync flow. | Manual Figma export must match expected `{primitives, spacing}` shape. | Added explicit file/JSON validation. Larger issue remains: it overlaps with `ds-drift-check.py` and uses a separate mapping contract. | Fixed |
| `scripts/sync-figma-tokens.sh` | Figma token diff wrapper | Thin shell wrapper that checks for `figma-tokens.json` and runs the Node diff. | Depends on repo root and Node.js. Used manually only. | Wrapper should fail clearly when export preconditions are missing. | Added strict mode and repo-relative execution. Canonical role still depends on whether the team keeps this flow alongside `ds-drift-check.py`. | Fixed |

## Duplicate Logic Found

- `scripts/ds-drift-check.py` and `scripts/sync-figma-tokens.js` both audit design-token parity, but from different source-of-truth assumptions and with different token maps.
- `scripts/git-commit-push.sh` and `scripts/git-watcher.sh` both automate whole-repo stage/commit/push flows.
- `scripts/export-assets-for-figma.sh` and `scripts/sync-assets.sh` both generate downstream asset artifacts, but from different upstreams (`xcassets` vs Supabase Storage).

## Files Without Clear Current Role

- `scripts/download_sounds.py` is bootstrap tooling, but current production audio naming/format lives elsewhere (`SFXCatalog.swift`, bundle resources, sound catalog docs). Its role is historical unless audio sourcing is refreshed.
- `scripts/git-commit-push.sh` and `scripts/git-watcher.sh` are local operator tools, not clean project-wide automation. They live in-repo but encode personal workflow behavior.
- `scripts/sync-figma-tokens.js` / `scripts/sync-figma-tokens.sh` are secondary to `ds-drift-check.py` unless the team explicitly treats Figma export as a first-class source in addition to iOS/admin.

## Candidates For Removal / De-Tracking

- `scripts/download_sounds.py` — candidate to archive/deprecate unless the team refreshes it against the current WAV-first catalog and actual bundle usage.
- `scripts/git-commit-push.sh` — candidate to move to a local/operator toolbox if whole-repo autopush should not live inside the shared repo.
- `scripts/git-watcher.sh` — same as above; useful locally, risky as a default project artifact.

## Documentation Missing Or Stale

- `docs/08_prompts/SOUND_CATALOG.md` describes many files as `.mp3`, while `Hexbound/Hexbound/Persistence/SFXCatalog.swift` and bundle resources are WAV-first. This is a real cross-file documentation drift and needs a canonical audio source-of-truth decision.
- `docs/07_ui_ux/ASSET_CONSISTENCY_AUDIT.md` contains historical findings that were already fixed (`sync-assets.sh` 512px cap) plus now-resolved export-format gaps; it should be clearly marked as partially historical or refreshed.
- No current page defines whether `figma-assets/` is authoritative generated output or disposable design cache.
- No current page defines whether `sync-figma-tokens.*` or `ds-drift-check.py` is the canonical DS drift workflow.

## Verification

- `bash -n` passes for all shell scripts in `scripts/`.
- `python3 -m py_compile` passes for all Python scripts in `scripts/`.
- `node --check scripts/sync-figma-tokens.js` passes.
- `python3 scripts/check_schema_drift.py --verbose` now reports `64 models, 692 scalar/enum columns, 102 @@index/@@unique decls, 19 enums / 114 enum values` and passes, while also rejecting hidden/nested files inside migration directories.
- `python3 scripts/ds-drift-check.py` passes.
- `bash scripts/check_ios_backend_drift.sh` passes.
- `bash scripts/sync-figma-tokens.sh` now fails clearly and intentionally when `figma-tokens.json` is absent.
