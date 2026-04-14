---
title: Audit Block 003 — Claude Operational Safety
category: audit
tags: [audit, claude, skills, secrets, operational-safety]
sources:
  - .claude/settings.local.json
  - .claude/skills/blacksmith/
  - .claude/skills/chronicler/
  - .claude/skills/context-auditor/
  - .claude/skills/doc-keeper/
  - .claude/skills/gatekeeper/
  - .claude/skills/guardian/
  - .claude/skills/herald/
  - .claude/skills/mirror/
  - .claude/skills/oracle/
  - .claude/skills/remove-background/
updated: 2026-04-14
---

# Audit Block 003 — Claude Operational Safety

## Scope

This is the first `.claude/` sub-block. It covers the files most likely to affect real commands, commits, deploys, scanners, secrets, and local environment changes.

Full `.claude/` inventory remains 132 tracked files. The remaining product-design, Figma, reference, and specialist skill files are intentionally left for the next `.claude` audit blocks.

Related pages: [[audit-index]], [[project-file-inventory]], [[block-002-repo-automation]].

## Summary

- **Files audited in this sub-block:** 21
- **Status:** Fixed; secret rotation and de-tracking decision required
- **Critical finding:** `.claude/settings.local.json` was tracked and contained historical database URLs, Supabase JWTs/API keys, literal passwords, `PGPASSWORD=...`, and overly broad command permissions (`git add -A`, `rm:*`, `env`, direct Vercel/Supabase commands).
- **Safe fixes applied:** sanitized `.claude/settings.local.json`, added it to `.gitignore`, synchronized duplicate operational scripts from the already-fixed `.skills` versions, made docs examples macOS-compatible, removed unsafe gatekeeper examples, and stopped `remove_bg.py` from auto-installing packages with `--break-system-packages`.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P0 | Tracked `.claude/settings.local.json` contained literal secrets and service credentials. | Credential leakage from repository and git history; external service compromise if still valid. | Replaced with sanitized minimal allow-list and added `.claude/settings.local.json` to `.gitignore`. |
| P0 | Same settings file allowed dangerous broad commands, including `git add -A`, `rm:*`, `env`, direct env mutation, and credential-bearing curl/psql commands. | Agents could accidentally expose env, stage unrelated files, or run destructive shell actions. | Removed all dangerous historical permission entries. |
| P1 | `.claude/skills/*/scripts` duplicated older scanner/deploy scripts from `.skills`. | One agent path could run fixed scanners, another could run stale broken scanners. | Synchronized duplicated operational scripts from `.skills`. |
| P1 | `.claude` scanner scripts used macOS-incompatible `grep -P`. | Scripts fail on this macOS workspace despite passing shell syntax checks. | Synced fixed portable scripts. |
| P2 | `.claude/skills/gatekeeper/SKILL.md` still recommended unsafe conflict/junk cleanup examples. | Encourages blind ours/theirs conflict resolution or `rm -rf` deletion. | Reworded to require deliberate preview/confirmation and exact duplicate removal. |
| P2 | `.claude/skills/doc-keeper/SKILL.md` used `grep -oP` snippets. | Documentation workflow fails on macOS BSD grep. | Replaced examples with portable `sed -nE` extraction. |
| P2 | `.claude/skills/remove-background/remove_bg.py` auto-installed dependencies with `--break-system-packages`. | Mutates the global/system Python environment and can break local tooling. | Changed to fail with virtualenv installation instructions. |

## File Records

| Path | Name / Zone | Purpose / What It Does | Depends On | Used By | Main Functions / Components | Business Rules | Problems Found | Fixed | Separate Decision | Status |
|------|-------------|------------------------|------------|---------|-----------------------------|----------------|----------------|-------|-------------------|--------|
| `.claude/settings.local.json` | Claude local settings | Local Claude permission allow-list and enabled MCP server list. | Claude desktop/local runtime, Figma MCP. | Claude tooling in this workspace. | `permissions.allow`, `enabledMcpjsonServers`. | Local settings must not carry secrets or destructive broad permissions in source control. | Contained literal DB passwords, Supabase tokens/JWTs, service commands, broad `git add -A`, `rm:*`, and `env`. | Replaced with minimal safe allow-list; JSON validity verified. | Rotate every credential that appeared in history; remove/de-track this file from git in a cleanup commit. | Fixed |
| `.gitignore` | Repo ignore policy | Prevents local/dev artifacts from being re-added. | Git. | All contributors and agents. | Ignore patterns. | Local Claude settings must stay local. | Did not ignore `.claude/settings.local.json`. | Added `.claude/settings.local.json`. | Because the file is already tracked, a follow-up `git rm --cached` decision is still needed. | Fixed |
| `.claude/skills/blacksmith/SKILL.md` | Claude skill / build verify docs | Documents build verification workflow for Claude skill users. | Blacksmith script, backend/admin/iOS tooling. | Claude build verifier. | Build check instructions. | Verify build/schema/project structure before deploy. | Duplicate with `.skills/skills/blacksmith`; docs are older but role is clear. | No direct edit in this sub-block. | Choose canonical source between `.claude/skills` and `.skills/skills`. | Needs review |
| `.claude/skills/blacksmith/scripts/verify_build.sh` | Claude script / build verify | Static schema/pbxproj/design/file-hygiene checks plus optional builds. | Bash, git, Swift project, backend/admin. | Claude blacksmith skill. | `report`, schema check, pbxproj scan, design counts. | No schema drift, all Swift files in pbxproj, no staged env. | Older copy used GNU-only `grep -P`. | Synced from fixed `.skills` version; `bash -n` passes. | Current project still has Swift/UI static debt handled later. | Fixed |
| `.claude/skills/chronicler/SKILL.md` | Claude skill / retrospective | Documents process-improvement retrospectives. | Chronicler script, rules/docs. | Claude retrospective flow. | Retro phases and update targets. | Repeated fixes should become rules/scanners/docs. | Duplicate with `.skills`; may drift. | No direct edit in this sub-block. | Merge/deduplicate with `.skills` and `hexbound-retro`. | Needs review |
| `.claude/skills/chronicler/scripts/gather_metrics.sh` | Claude script / retro metrics | Collects git activity and scanner/violation metrics. | Bash, git, project docs/code. | Claude chronicler skill. | Git activity, violation snapshot, scanner inventory. | Metrics must not hang on large commit/file bursts. | Older copy had unbounded log scans and nonportable emoji grep. | Synced from fixed `.skills` version; `bash -n` passes. | Consolidate with daily retro metrics. | Fixed |
| `.claude/skills/context-auditor/SKILL.md` | Claude skill / context audit | Audits session context and updates persistent rules/skills when gaps are found. | `CLAUDE.md`, docs, skills/rules. | Claude context-auditor. | Context scan, rule update, reporting phases. | Important learned rules should persist outside chat. | Duplicate with `.skills`; role clear. | No direct edit. | Decide canonical location. | Needs review |
| `.claude/skills/doc-keeper/SKILL.md` | Claude skill / docs audit | Checks documentation freshness, missing docs, references, and index/source-of-truth integrity. | `docs/`, project files, shell commands. | Claude documentation audits. | Freshness sweep, gap analysis, link checks. | Docs should match current code paths and SSoT. | Used `grep -oP` examples that fail on macOS. | Replaced with portable `sed -nE` snippets. | Check whether referenced `docs/PROJECT_INDEX.md` and `docs/SOURCE_OF_TRUTH.md` still exist in docs audit. | Fixed |
| `.claude/skills/gatekeeper/SKILL.md` | Claude skill / preflight docs | Documents pre-commit/pre-push verification. | Gatekeeper script, git, schema/pbxproj. | Claude gatekeeper. | Preflight checklist. | Never commit conflict markers, junk files, or env leaks. | Unsafe examples recommended blind ours/theirs and `rm -rf` duplicate deletion. | Reworded to require preview/confirmation and exact duplicate removal. | Align all duplicate gatekeeper docs with one source. | Fixed |
| `.claude/skills/gatekeeper/scripts/preflight_check.sh` | Claude script / preflight | Checks changed files for pbxproj, schema sync, admin deploy, UI quick checks, junk/env, async config calls. | Bash, git, Swift/TS files. | Claude gatekeeper. | `CHANGED`, pbxproj refs, design quick check. | Swift files need 4 pbxproj refs; schema changes need migration. | Older copy missed untracked files, accepted 3 refs, and used `grep -P`. | Synced from fixed `.skills` version; `bash -n` passes. | Add schema drift script when Prisma changes. | Fixed |
| `.claude/skills/guardian/SKILL.md` | Claude skill / Swift review | Swift/iOS code review checklist. | Guardian script, Swift theme/views/models. | Claude guardian. | Design system, architecture, property safety, guard-before-await. | Use real tokens; avoid hardcoded UI and async double-tap races. | Duplicate with `.skills`; role clear. | No direct doc edit. | Decide canonical source. | Needs review |
| `.claude/skills/guardian/scripts/check_design_system.sh` | Claude script / design scanner | Scans SwiftUI design-system violations and ViewModel patterns. | Bash, Swift files, DarkFantasyTheme. | Claude guardian/mirror. | Token extraction, color/font/emoji scans, guard-before-await. | Extension-backed shorthand only; guard before await in async ViewModels. | Older copy used `grep -P` and stale extension-token logic. | Synced from fixed `.skills` version; `bash -n` passes. | DTO snake_case check should become target-aware. | Fixed |
| `.claude/skills/herald/SKILL.md` | Claude skill / deploy docs | Documents deploy/build/push flow. | Herald deploy script, Git remotes, Vercel. | Claude deploy flow. | Preflight/build/deploy/report phases. | Build before commit; no env/secrets; schemas match before deploy. | Older docs are shorter than `.skills` version but no immediate secret/unsafe command found after scan. | No direct edit. | Merge with `.skills/skills/herald/SKILL.md`. | Needs review |
| `.claude/skills/herald/scripts/deploy.sh` | Claude script / deploy | Runs preflight, builds, stages product paths, commits and pushes. | Bash, git, npm, Prisma, Next, xcodebuild. | Claude herald. | Deploy phases and admin subtree push. | Do not deploy env files or build failures. | Older copy lacked post-stage env guard. | Synced from fixed `.skills` version; `bash -n` passes. | Broad staging/push policy still needs redesign. | Fixed |
| `.claude/skills/mirror/SKILL.md` | Claude skill / UX audit | UX audit checklist for iOS screens. | Guardian scanner, screen inventory, design docs. | Claude UX auditor. | Product principles, layout, states, accessibility. | Screens need loading/empty/error/disabled coverage and DS reuse. | Duplicate with `.skills`; role clear. | No direct edit. | Decide canonical source. | Needs review |
| `.claude/skills/oracle/SKILL.md` | Claude skill / backend review | Backend TypeScript/Prisma review checklist. | Oracle script, backend schema/routes. | Claude backend reviewer. | Async correctness, schema sync, server authority. | Known async calls must be awaited/composed deliberately; shared wallet rules. | Duplicate with `.skills`; role clear. | No direct edit. | Decide canonical source. | Needs review |
| `.claude/skills/oracle/scripts/check_async_await.sh` | Claude script / backend scanner | Grep-based async/null/JSON/junk/wallet scanner. | Bash, backend/admin TS. | Claude oracle. | Async patterns, wallet scan, temp file. | `character.gold/gems` writes should move to user wallet. | Older copy lacked temp cleanup trap. | Synced from fixed `.skills` version; `bash -n` passes. | Replace with AST scanner later. | Fixed |
| `.claude/skills/remove-background/SKILL.md` | Claude skill / image background removal | Documents background-removal workflow via rembg/U²-Net. | `remove_bg.py`, local images, optional model files. | Claude image workflow. | CLI usage and model choices. | Image tooling should not mutate global environment unexpectedly. | Script behavior was too aggressive; doc role clear. | No doc edit. | Add virtualenv setup note if this skill is kept. | Needs review |
| `.claude/skills/remove-background/remove_bg.py` | Claude script / background removal | Removes image backgrounds with rembg, supports transparent/white/black output. | Python, rembg, Pillow, local ONNX model cache. | `remove-background` skill. | `ensure_deps`, `ensure_model`, `main`. | Missing dependencies should be explicit; no global/system package mutation. | Auto-installed packages with `--break-system-packages`. | Removed auto-install; now prints virtualenv install instructions and exits. `py_compile` passes. | Decide whether this script belongs in project repo or a personal tools repo. | Fixed |

## Duplicate Logic Found

- `.claude/skills/{blacksmith,chronicler,context-auditor,gatekeeper,guardian,herald,mirror,oracle}` duplicates `.skills/skills/` names.
- Six duplicated operational scripts are now content-synced from `.skills`; mode differs because `.claude` scripts are executable and `.skills` scripts are not.
- Keeping two live skill trees creates drift risk. Current recommendation: choose one canonical tree and generate/sync the other.

## Candidates For Removal / De-Tracking

- `.claude/settings.local.json` — should be removed from git tracking after confirmation (`.gitignore` now covers future local copies).
- `.claude/skills/remove-background/remove_bg.py` — candidate to move to personal tooling unless the project wants image-processing scripts in-repo.
- Duplicated `.claude/skills` operational docs/scripts — candidate for generated mirror or deletion after canonical skill source is chosen.

## Documentation Missing Or Stale

- `doc-keeper` references `docs/PROJECT_INDEX.md` and `docs/SOURCE_OF_TRUTH.md`; their existence/freshness must be checked in the docs block.
- The duplicate Claude skill docs do not consistently reflect the safer `.skills` operational guidance; this block fixed only the highest-risk examples.

## Verification

- `.claude/settings.local.json` parses as JSON.
- Secret scan of `.claude` no longer finds the removed password/JWT/DB URL patterns; remaining `git add -A` mention is historical warning text only.
- All `.claude` shell scripts pass `bash -n`.
- All `.claude/skills/figma-generate-library/scripts/*.js` pass `node --check`.
- `.claude/skills/remove-background/remove_bg.py` passes `python3 -m py_compile`.
- `.claude` agent YAML files parse with Ruby YAML.
