---
title: Audit Block 002 — Repo Automation, Cursor Rules, Local Skills
category: audit
tags: [audit, ci, cursor-rules, skills, automation]
sources:
  - .github/workflows/ci.yml
  - .cursor/rules/
  - .skills/skills/
updated: 2026-04-14
---

# Audit Block 002 — Repo Automation, Cursor Rules, Local Skills

## Scope

Block 002 covers repository automation and agent/operator guidance:

- `.github/workflows/ci.yml`
- `.cursor/rules/*.mdc`
- `.skills/skills/*/SKILL.md`
- `.skills/skills/*/scripts/*.sh`

Related audit pages: [[audit-index]], [[project-file-inventory]].

## Summary

- **Files audited:** 28
- **Status:** Fixed; several follow-up architecture decisions remain
- **Main risk found:** the repo's automation had drift from the current project layout. Some rules did not trigger for active Combat/PvP/Economy paths, CI did not run existing schema/docs drift checks, and local scanner scripts used GNU-only `grep -P` on a macOS workspace.
- **Safe fixes applied:** CI coverage improved, Cursor globs realigned, unsafe deploy/preflight wording softened, post-stage `.env` guard added, scanner portability fixed, preflight pbxproj threshold fixed, and retrospective git-log scans bounded.

## Project Map Impact

| Area | Role | Notes |
|------|------|-------|
| `.github/` | Hosted CI | Builds backend/admin and now checks balance docs plus Prisma migration drift. |
| `.cursor/rules/` | Editor/agent domain rules | Source-of-truth reminders for Swift, backend, DB, economy, combat, deploy, art, audio, admin, UI. |
| `.skills/skills/` | Local agent workflows and scanners | Manual/agent skills for review, deploy, preflight, build verification, retrospectives, wiki sync. |

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | CI only compared Prisma schemas, but did not run migration drift check. | Schema and migrations could diverge while CI stays green. | Added `python3 scripts/check_schema_drift.py` to CI. |
| P1 | CI did not check generated balance docs. | Docs could drift from live balance constants. | Added `npm run docs:balance:check` to backend CI. |
| P1 | Skills scanners used `grep -P`, which fails on macOS BSD grep. | Review/preflight scripts silently break or emit noisy errors on the project machine. | Replaced PCRE grep usage with portable `sed`/`perl`. |
| P1 | Preflight pbxproj check said Swift files need 4 refs but only blocked `<3`. | A partially registered Swift file could pass preflight and fail in Xcode. | Changed threshold to `<4`; skipped deleted Swift files. |
| P2 | Preflight ignored untracked files. | New junk files, new Swift files, or new risky files could be missed before commit. | Included `git ls-files --others --exclude-standard`. |
| P2 | Deploy instructions included a fallback `git add -A` command and stale lock removal in one line. | Easy to commit unresolved conflicts/secrets/local files. | Replaced with explicit reviewed-path staging guidance. |
| P2 | Deploy script checked staged `.env` before broad staging, not after. | A newly staged env file could slip through if not ignored. | Added post-stage `.env` guard before commit. |
| P2 | Cursor globs missed active Economy/Gold Mine/Battle Pass/Daily and Combat/Arena paths. | Cursor/agent rules would not load for files they explicitly describe. | Expanded relevant globs. |
| P2 | Retrospective scripts ran unbounded file-list `git log` scans. | Daily metrics could hang on large commit bursts/assets. | Added `max_commits` and `max_file_lines` limits. |
| P3 | `guardian` shorthand-token scanner only read one line after `extension Color`. | Extension-backed tokens were misclassified. | Increased scan window and made extraction portable. |
| P3 | `oracle` temp file cleanup only happened on normal exit. | Interrupted scans could leave temp files. | Added `trap` cleanup. |

## File Records

| Path | Name / Zone | Purpose / What It Does | Depends On | Used By | Main Jobs / Symbols | Business Rules | Problems Found | Fixed | Separate Decision | Status |
|------|-------------|------------------------|------------|---------|---------------------|----------------|----------------|-------|-------------------|--------|
| `.github/workflows/ci.yml` | CI | Runs backend tests/build, admin build, Prisma sync checks. | GitHub Actions, Node 20, npm lockfiles, Prisma, Vitest, `scripts/check_schema_drift.py`. | GitHub push/PR on `main`. | `backend-build`, `admin-build`, `prisma-schema-sync`. | Backend/admin schemas must match; balance generated docs must not drift; migrations must cover Prisma schema. | Paths were too narrow; migration drift and balance-doc drift were not checked. | Added `scripts/**`, workflow, and balance-doc paths; added docs balance and migration drift steps. | Add iOS build/design-system drift CI later; Ubuntu cannot cover Xcode build directly. | Fixed |
| `.cursor/rules/rules-admin.mdc` | Cursor rule / Admin | Defines admin panel safety rules: strict null checks, Prisma sync, subtree deploy, config/form validation. | `admin/**`, Prisma schemas, admin docs. | Cursor/agent when editing admin TS/TSX. | Admin source-of-truth and deploy reminders. | Admin schema must mirror backend; subtree push after admin changes. | No immediate issue. | None. | Keep synced with admin deploy docs. | OK |
| `.cursor/rules/rules-art.mdc` | Cursor rule / Art | Defines art prompt style, asset naming, emoji-to-assets policy. | `docs/08_prompts/**`, `.xcassets`. | Cursor/agent during art/asset work. | Prompt structure, naming rules. | Pen-and-ink visual style; no emoji as shipped UI assets except stated exceptions. | No immediate issue. | None. | Verify during asset audit whether all referenced prompt docs remain current. | OK |
| `.cursor/rules/rules-audio.mdc` | Cursor rule / Audio | Defines SFX enum and haptic rules. | Swift audio/haptic files. | Cursor/agent during audio work. | SFX prefix policy, haptic levels. | SFX cases use `ui` prefix. | No immediate issue. | None. | Asset filename coverage will be checked in audio/assets blocks. | OK |
| `.cursor/rules/rules-backend.mdc` | Cursor rule / Backend | Backend TypeScript/Next.js rules for async, errors, TOCTOU, N+1, Prisma JSON. | `backend/**/*.ts`, `backend/**/*.tsx`, live config/combat code. | Cursor/agent during backend edits. | Async config, route error handling, atomic increments. | API routes use try/catch; no PII logging; server-authoritative game logic. | No immediate issue in this file. | None. | Some rules require scanner enforcement in later backend audit. | OK |
| `.cursor/rules/rules-combat-pvp.mdc` | Cursor rule / Combat/PvP | Defines combat/PvP source of truth and Arena flow. | Combat views/models/services, backend combat/PvP routes. | Cursor/agent during Combat/Arena/PvP work. | Server-authoritative combat, matchmaking, stance, revenge, achievements. | Client does not calculate results/rewards/rating. | Globs missed current `Views/Arena`, `api/combat`, `api/pvp`, PvP service/model paths. | Expanded globs to current layout. | Add any new interactive combat folders if moved again. | Fixed |
| `.cursor/rules/rules-db.mdc` | Cursor rule / DB | Defines Prisma schema/migration rules. | `backend/prisma`, `admin/prisma`, DB docs. | Cursor/agent during DB changes. | Schema sync, migrate resolve warning, JSON casts. | Backend schema is the SSoT; admin schema copied from backend. | No immediate issue. | None. | Keep in sync with migration drift script behavior. | OK |
| `.cursor/rules/rules-deploy.mdc` | Cursor rule / Deploy | Defines git/deploy/two-remote workflow. | `scripts/**`, `.github/**`, now `.skills/**`. | Cursor/agent during workflow/deploy work. | Origin deploy, admin subtree, merge conflict scan. | Never broad-stage unresolved work; verify build before push. | Did not apply to `.skills/**`, although deploy/preflight skill files are operational workflow. | Added `.skills/**` glob. | Align with deploy docs after deploy-script redesign. | Fixed |
| `.cursor/rules/rules-economy.mdc` | Cursor rule / Economy | Defines currencies, shop, Gold Mine, Battle Pass and daily economy rules. | Backend shop/economy/minigames routes, Swift Shop/Minigames/BattlePass/Daily/Quests. | Cursor/agent during economy work. | TOCTOU prevention, server prices, Gold Mine badge/cache. | Purchases validated inside serializable transaction with row lock. | Globs missed current Gold Mine/Battle Pass/Daily paths. | Expanded globs to active backend and Swift economy folders. | Add IAP/subscription paths when audited. | Fixed |
| `.cursor/rules/rules-swift.mdc` | Cursor rule / Swift | Defines SwiftUI/Xcode/concurrency/design-system rules. | `Hexbound/**/*.swift`. | Cursor/agent during iOS edits. | pbxproj 4-section rule, `@MainActor`, `@Observable`, CodingKeys policy. | New Swift files must be in pbxproj; no force unwraps; APIClient uses `convertFromSnakeCase`. | No immediate issue. | None. | Later iOS audit must verify actual code compliance. | OK |
| `.cursor/rules/rules-ui-design.mdc` | Cursor rule / UI Design | Defines DarkFantasyTheme, tokens, ornamentals, radius, GPU, optimistic UI. | Swift views/theme files. | Cursor/agent during UI edits. | Token usage, shadows, toast, press state. | Use design-system components/tokens instead of duplicates. | No immediate issue. | None. | Later UI audit must reconcile scanner failures. | OK |
| `.skills/skills/blacksmith/SKILL.md` | Skill / Build verify docs | Documents build verification workflow. | `scripts/verify_build.sh`. | Manual/agent build checks. | Static-only and full build modes. | Build verification before risky/deploy work. | Script behavior changed for portability; docs still valid. | None needed. | Current project fails static design checks; code debt handled in Swift/UI audit. | OK |
| `.skills/skills/blacksmith/scripts/verify_build.sh` | Skill script / Build verify | Checks schema sync, pbxproj completeness, design-system violations, junk files, optional backend/admin builds. | Bash, git, Prisma/Next for full mode, Swift project files. | `blacksmith`, manual preflight. | Schema check, pbxproj scan, design-system counts. | No staged env files; no ignored build errors; all Swift files in pbxproj. | Used macOS-incompatible `grep -P`; current static scan reports 42 hardcoded colors and 7 small fonts. | Replaced PCRE grep with portable `sed`/`perl`. | Decide whether scanner should exit nonzero only for structural blockers or also design debt. | Fixed |
| `.skills/skills/chronicler/SKILL.md` | Skill / Retrospective parent | Defines retrospective process for learning from fixes/scanner gaps. | `chronicler/scripts/gather_metrics.sh`, scanner scripts. | Agents/manual retros. | Evidence gathering, pattern analysis, propagation. | Every repeated manual fix should become a rule/scanner/doc update. | Usage docs lacked new performance bounds. | Documented optional `max-commits` / `max-file-lines`. | Duplicates newer `hexbound-retro`; merge or deprecate one later. | Fixed |
| `.skills/skills/chronicler/scripts/gather_metrics.sh` | Skill script / Metrics | Collects recent git activity, violation counts, skill freshness, new patterns. | Bash, git, grep/sed/awk/perl, Swift project paths. | Chronicler retros. | Git activity, violation snapshot, scanner inventory. | Metrics should be fast and not hang on large repos. | Emoji grep was not portable/functional; unbounded git file-list scans could hang; only scanned `hexbound-*` skills. | Added perl emoji count and bounded git log scans. | Consider replacing with `hexbound-retro` or extracting shared metrics library. | Fixed |
| `.skills/skills/context-auditor/SKILL.md` | Skill / Context auditor | Audits chat/context rules and decides if new rules/skills are needed. | Project docs, `.cursor/rules`, `.skills`. | Manual/agent context audits. | Context scan phases, classification, updates. | Capture recurring context gaps into persistent rules. | No script; no immediate issue. | None. | Could share checklist with wiki-sync after full docs audit. | OK |
| `.skills/skills/gatekeeper/SKILL.md` | Skill / Preflight docs | Documents pre-commit/pre-push checks. | `gatekeeper/scripts/preflight_check.sh`. | Manual/agent before commit/push. | pbxproj, schema sync, subtree reminder, junk/env checks. | No unresolved conflict markers; no junk files; admin subtree reminder. | Suggested destructive/unsafe examples (`rm -f`, ours/theirs, `rm -rf`) without enough caution. | Reworded to require deliberate confirmation and exact duplicate removal. | Keep examples aligned with non-destructive repo policy. | Fixed |
| `.skills/skills/gatekeeper/scripts/preflight_check.sh` | Skill script / Preflight | Checks changed files for pbxproj, schema sync, admin deploy, design-system quick checks, junk/env, async config calls. | Bash, git, pbxproj, Prisma schemas, Swift/TS files. | Gatekeeper/manual preflight. | `CHANGED`, pbxproj refs, design quick check. | Swift files need 4 pbxproj refs; schema changes need migration; env must not be staged. | Ignored untracked files; accepted 3 pbxproj refs despite saying 4; failed on macOS `grep -P`; blocked deleted Swift files. | Added untracked files, `<4` threshold, deleted-file skip, portable font/emoji scans. | Extend to run schema drift script when Prisma changes. | Fixed |
| `.skills/skills/guardian/SKILL.md` | Skill / Swift review docs | Defines Swift/iOS review checklist. | `guardian/scripts/check_design_system.sh`, Swift views/models. | Swift reviewers/agents. | Design system, architecture, property safety, guard-before-await, accessibility. | No hardcoded UI tokens; guard before async awaits in ViewModels. | No immediate doc issue. | None. | Some current code issues are intentionally deferred to Swift/UI blocks. | OK |
| `.skills/skills/guardian/scripts/check_design_system.sh` | Skill script / Design scanner | Scans SwiftUI files for hardcoded colors, bare tokens, small fonts, emoji, inline buttons, spacing, ViewModel guard patterns, snake_case CodingKeys. | Bash, Swift files, DarkFantasyTheme, perl/sed/grep. | Guardian, mirror, manual UI review. | Token extraction, per-section scanners. | Theme shorthand tokens only safe if extension-backed; ViewModel async methods should guard before await. | Used `grep -P`; only saw one Color extension line; single-file scans still run a project-wide DTO check. | Replaced PCRE grep, added Swift file helper, widened extension token window. | Decide whether DTO check belongs in oracle/backend or accepts a target-aware mode. | Fixed |
| `.skills/skills/herald/SKILL.md` | Skill / Deploy docs | Documents deploy flow, preflight, build verification, commit/push, subtree deploy. | `herald/scripts/deploy.sh`, gatekeeper, Git remotes. | Deploy agent/manual deploy. | Preflight, build, commit, origin/admin deploy report. | Build before commit; no secrets/env; schemas identical before deploy. | Fallback text encouraged stale lock deletion plus `git add -A` in one command. | Replaced with explicit reviewed-path staging and lock caution. | Revisit auto-commit/push policy before production release. | Fixed |
| `.skills/skills/herald/scripts/deploy.sh` | Skill script / Deploy | Runs preflight-like checks, optional builds, stages product paths, commits, pushes origin/admin subtree. | Bash, git, npm, Prisma, Next, xcodebuild, remotes. | Herald deploy flow. | Preflight, build, commit message, origin push, admin subtree force fallback. | Do not deploy with env files, junk files, build failures, or schema drift. | `.env` check ran before broad staging only; broad staging/pushing remains operationally risky. | Added post-stage `.env` guard before commit. | Redesign deploy to require explicit reviewed file list or dry-run approval. | Fixed |
| `.skills/skills/hexbound-retro/SKILL.md` | Skill / Daily retro docs | Defines daily retrospective workflow. | `hexbound-retro/scripts/gather_metrics.sh`. | Daily retro agents/manual. | 4-phase metrics/pattern/rules/report flow. | Scanner improvements and repeated bugs become rules. | Usage docs lacked new performance bounds. | Documented optional limits. | Merge with or replace `chronicler` to remove duplicated retro logic. | Fixed |
| `.skills/skills/hexbound-retro/scripts/gather_metrics.sh` | Skill script / Daily metrics | Collects recent git activity, current violation snapshot, skills inventory, fix patterns. | Bash, git, Swift/theme files, sed/awk/perl. | Hexbound retro skill. | Git activity, bare-token awareness, conflict-marker count, churn. | Daily metrics must be fast and not report node_modules/build noise. | Used `grep -P`; unbounded git file-list scans could hang. | Replaced token extraction with sed; added bounded git log scans. | Extract shared logic with chronicler. | Fixed |
| `.skills/skills/mirror/SKILL.md` | Skill / UX audit docs | Defines UX audit checklist and output format. | Guardian scanner, Swift views, UX/product rules. | UX/manual/agent review. | Product principles, touch/layout, states, accessibility. | Screens must cover loading/empty/error/disabled and use existing components. | No immediate issue. | None. | Later UI audit should compare against actual screen inventory. | OK |
| `.skills/skills/oracle/SKILL.md` | Skill / Backend review docs | Defines backend TypeScript review checklist. | `oracle/scripts/check_async_await.sh`, backend schema/routes. | Backend reviewers/agents. | Async correctness, schema sync, server authority, enum checks. | Known async calls must be awaited or intentionally returned/composed. | No immediate doc issue. | None. | Scanner heuristics still need deeper backend validation. | OK |
| `.skills/skills/oracle/scripts/check_async_await.sh` | Skill script / Backend scanner | Grep-based scan for missing await, null-safety hints, JSON casts, junk TS files, shared wallet violations. | Bash, git, grep/sed, backend/admin TS. | Oracle/manual backend review. | Async patterns, JSON casts, wallet scan. | `character.gold/gems` should not be written directly; use shared user wallet. | Temp file cleanup only on normal exit; scanner is heuristic and can false-positive. | Added `trap` cleanup. | Consider AST-based TypeScript scanner later. | Fixed |
| `.skills/skills/wiki-sync/SKILL.md` | Skill / Wiki sync docs | Defines steps to sync wiki with code/docs changes. | `wiki/log.md`, git history, game docs/code. | Manual/agent wiki sync. | Detect changes since last wiki update, update pages, lint links. | Wiki must remain source of truth and link-clean. | Git log example was unbounded and could hang like retro scripts. | Added `--max-count=200` and `head -n 2000` to example. | Replace inline shell lint with a maintained script during docs audit. | Fixed |

## Files Without A Clear Long-Term Role

- `.skills/skills/chronicler/*` and `.skills/skills/hexbound-retro/*` overlap heavily. Current recommendation: keep both for now, but merge shared metrics logic and decide one canonical retrospective skill.

## Duplicate Logic Found

- Retrospective metrics logic duplicated between `chronicler/scripts/gather_metrics.sh` and `hexbound-retro/scripts/gather_metrics.sh`.
- Design-system checks are partially duplicated across `blacksmith/scripts/verify_build.sh`, `gatekeeper/scripts/preflight_check.sh`, and `guardian/scripts/check_design_system.sh`.
- Schema equality is checked in CI, blacksmith, gatekeeper, and deploy; this is good as defense-in-depth, but migration drift should become the canonical shared check where possible.

## Candidates For Removal / Merge

- **Merge candidate:** `chronicler` + `hexbound-retro` metrics scripts.
- **No immediate delete candidates** in this block. These files are operationally meaningful and should not be removed until replacement workflows exist.

## Documentation Missing Or Stale

- CI previously did not encode the local source-of-truth checks (`docs:balance:check`, schema drift). Fixed in workflow.
- Skill usage docs for retrospectives did not mention bounded scan arguments. Fixed.
- Wiki-sync still embeds a large shell lint snippet; later docs audit should move this to a script.

## Verification

- `bash -n` passes for all seven skill shell scripts.
- `rg` confirms no remaining `grep -P`/`grep -oP`/`grep -cP` usage under `.skills/skills`.
- CI YAML parses with Ruby YAML.
- `python3 scripts/check_schema_drift.py` passes.
- `npm run docs:balance:check` passes in `backend/`.
- `gatekeeper` preflight passes with one warning: admin subtree push needed because unrelated admin schema changes are present in the worktree.
- `blacksmith --static-only` now runs on macOS, but reports current Swift/UI debt: 42 hardcoded color hits and 7 small-font hits. These are deferred to the Swift/UI audit blocks.
