---
title: "Audit Block 001: Root Files"
category: audit
tags: [audit, root, prototypes, docs, legal, config]
sources: [project-file-inventory, git grep, root files]
updated: 2026-04-14
---

# Audit Block 001: Root Files

Scope: 27 repository-root files. This block covers repository policy/config, root-level reports/plans, legal static pages, and standalone prototypes.

## Folder / File Map

- Config / policy: `.gitignore`, `.mcp.json`, `CLAUDE.md`
- Planning / audit docs: `COMBAT_UX_AUDIT.md`, `COMBAT_UX_IMPLEMENTATION_PLAN.md`, `COMBAT_V3_IMPLEMENTATION_PLAN.md`, `GOLD_MINE_MINIGAME_BALANCE_AUDIT.md`, `GOLD_MINE_MINIGAME_PLAN.md`, `HEXBOUND_PRE_RELEASE_AUDIT.md`, `QA_REPORT_2026-04-09.md`, `UI_RESPONSIVENESS_AUDIT.md`
- Combat prototypes: `combat-proto-A.html`, `combat-proto-B.html`, `combat-proto-B2.html`, `combat-proto-B2-v2.html`, `combat-proto-B2-v3.html`, `combat-proto-C.html`, `combat-prototypes.html`
- Other prototypes: `gold_mine_minigame_prototype.html`, `hero-card-delete-rings-layout.html`, `hero-card-rings-deepdive.html`, `review-choose-hero-guest-gating-before-after.jsx`, `special_offer_widget_prototype.html`, `special_offer_widget_v2_prototype.html`, `special_offer_widget_v3_prototype.html`
- Legal static pages: `privacy.html`, `terms.html`

## File-by-File Results

| File | Purpose / What it does | Depends on | Used by | Main units | Business rules | Problems found | Fixed now | Separate decision | Status |
|------|-------------------------|------------|---------|------------|----------------|----------------|-----------|-------------------|--------|
| `.gitignore` | Defines ignored local/build/prototype artifacts. | Git ignore syntax. | Git tooling. | Ignore patterns. | Prevent re-adding generated/vendor files and deleted prototypes. | Root contains tracked files matching prototype patterns, so ignore policy and repository state disagree. | None. | Decide whether tracked root prototypes should move to `prototypes/` or `docs/features/*` and be untracked from root. | Needs review |
| `.mcp.json` | Local MCP config for Figma HTTP MCP. | Figma MCP URL. | Local assistant/editor tooling. | `mcpServers.figma`. | No secrets should live here. | No issue; JSON parses and contains no credential. | None. | Keep local-vs-shared ownership clear. | OK |
| `CLAUDE.md` | Root project rules and architecture guardrails for AI/collaboration. | `docs/`, `Hexbound/CLAUDE.md`, `backend/CLAUDE.md`, Figma DS. | Humans and AI agents. | Architecture rules, DS rules, Xcode pbxproj rules, scanner commands. | Server-authoritative game logic, DS tokens, pbxproj entries for new Swift files. | Very large and duplicates canonical docs; contains agent/orchestrator protocol that can conflict with local tool rules. | None. | Split long-lived rules into canonical docs and keep root file as compact entrypoint. | Needs review |
| `COMBAT_UX_AUDIT.md` | Historical combat screen UX audit and A/B/C prototype rationale. | Combat prototypes A/B/C. | `combat-prototypes.html`, later combat plans. | UX findings, recommendation, prototype links. | Interactive combat should reduce duplicate stance UI and clarify strike ownership. | Status was stale after B2/B2-v3 direction. | Marked as historical/superseded. | Move under `docs/features/combat/` or archive once design history is settled. | Fixed |
| `COMBAT_UX_IMPLEMENTATION_PLAN.md` | v2 implementation plan based on B2 prototype. | `COMBAT_UX_AUDIT.md`, `combat-proto-B2.html`. | Historical planning. | Phases, risks, file list. | Reuse existing combat resolver; avoid full rewrite. | Status said planning/not started though v3 superseded it. | Marked as superseded by v3/B2-v3. | Archive or fold still-valid pieces into current combat docs. | Fixed |
| `COMBAT_V3_IMPLEMENTATION_PLAN.md` | v3 combat implementation plan for B2-v3 round log UI. | `combat-proto-B2-v3.html`, Swift combat files. | New Swift files and pbxproj references. | `CombatLogEvent`, `RoundExchange`, `CombatLogRow`, `InteractiveRoundLogCard`, `LogDivider`, `YourChoiceButton`. | Client stays server-authoritative; UI only renders server reveal payload. | Status said not started even though workspace has implementation files and pbxproj entries. | Marked implemented-in-workspace / re-verify before active use. | Validate product acceptance and move to feature docs. | Fixed |
| `GOLD_MINE_MINIGAME_BALANCE_AUDIT.md` | Balance sign-off for Gold Mine minigame Variant D. | Balance docs, `shaft-catalog.ts`, Gold Mine VM. | Gold Mine plan and economy tuning. | EV tables, guardrails, phase gates. | Minigame must not inflate economy beyond monitored gem velocity. | No immediate issue; appears to be a historical/current rationale doc. | None. | Reconcile with current per-slot endpoints in a later Gold Mine block. | OK |
| `GOLD_MINE_MINIGAME_PLAN.md` | Gold Mine minigame implementation plan. | Balance audit, prototype, backend/iOS Gold Mine files. | Gold Mine implementation. | Backend routes, Prisma shape, Swift files, DS plan. | Server-authoritative minigame payout and anti-abuse caps. | Paths were stale: actual routes live under `/api/minigames/gold-mine/*`; several planned Swift components were consolidated. | Added status/path drift note. | Later Gold Mine block should update detailed sections or archive superseded file list. | Fixed |
| `HEXBOUND_PRE_RELEASE_AUDIT.md` | Historical App Store readiness audit. | Project code and docs as of 2026-04-09. | Release planning and risk tracking. | Risk tables, bug triage, go/no-go. | App Store readiness, account deletion, secret hygiene, DS compliance. | Contained literal historical DB password and presented old blockers as current. | Redacted password literal and added historical snapshot warning. | Current release audit needed; credentials must be confirmed rotated outside repo. | Fixed |
| `QA_REPORT_2026-04-09.md` | Historical QA report with 11 fixed bugs. | QA run from 2026-04-09. | QA history. | Bug list and CDO status. | Fixed bug record should remain immutable. | Root placement is inconsistent with `qa-reports/`. | None. | Move to `qa-reports/` after reference check. | Needs review |
| `UI_RESPONSIVENESS_AUDIT.md` | Performance/API behavior audit and action plan. | ViewModels, Services, backend routes. | Technical debt planning. | Top 15 issues, screen findings, quick wins. | Prefer instant UI, stale-while-revalidate, explicit task cancellation. | Root placement is noisy; some findings may be stale after later work. | None. | Refresh findings and move to `docs/07_ui_ux/` or `qa-reports/`. | Needs review |
| `combat-proto-A.html` | Standalone combat Variant A prototype. | Google Fonts, DiceBear avatars. | `combat-prototypes.html`, `COMBAT_UX_AUDIT.md`. | Static HTML/CSS/JS demo. | Design exploration only, not production. | Superseded by B2/B2-v3. | No change; images already had `alt`. | Archive or move under combat feature docs. | Deprecated |
| `combat-proto-B.html` | Standalone combat Variant B hotbar prototype. | Google Fonts, DiceBear avatars. | `combat-prototypes.html`, `COMBAT_UX_AUDIT.md`. | Static HTML/CSS/JS demo. | Design exploration only. | Decorative images lacked `alt`. Superseded by B2/B2-v3. | Added empty `alt=""`. | Archive or move under combat feature docs. | Fixed |
| `combat-proto-B2.html` | Revised combat B2 prototype, approved v2 direction. | Google Fonts, DiceBear avatars. | `COMBAT_UX_IMPLEMENTATION_PLAN.md`. | Static HTML/CSS/JS demo. | Design exploration only. | Decorative images lacked `alt`; superseded by B2-v3. | Added empty `alt=""`. | Keep only if B2-v3 history needs comparison. | Fixed |
| `combat-proto-B2-v2.html` | B2 iteration for stance bonuses and always-on talents. | Google Fonts, DiceBear avatars. | Design history. | Static HTML/CSS/JS demo. | Design exploration only. | Decorative images lacked `alt`; likely superseded by B2-v3. | Added empty `alt=""`. | Archive or delete after confirming no active design dependency. | Fixed |
| `combat-proto-B2-v3.html` | Latest combat B2-v3 round-result-log prototype. | Google Fonts, DiceBear avatars. | `COMBAT_V3_IMPLEMENTATION_PLAN.md`. | Static HTML/CSS/JS demo. | Source visual reference for native Swift implementation. | Decorative images lacked `alt`. | Added empty `alt=""`. | Move beside combat feature docs; keep until visual parity is accepted. | Fixed |
| `combat-proto-C.html` | Combat stance silhouette prototype. | Google Fonts, DiceBear avatars. | `combat-prototypes.html`, `COMBAT_UX_AUDIT.md`. | Static HTML/CSS/JS demo. | Design exploration only. | Decorative images lacked `alt`; superseded. | Added empty `alt=""`. | Archive or delete after design history decision. | Fixed |
| `combat-prototypes.html` | Side-by-side iframe launcher for combat A/B/C prototypes. | `combat-proto-A/B/C.html`, `COMBAT_UX_AUDIT.md`. | Manual design review. | Static HTML iframes. | Design comparison only. | Recommendation points to Variant A while later direction moved to B2/B2-v3. | None. | Archive with old audit or update historical note if kept. | Needs review |
| `gold_mine_minigame_prototype.html` | Standalone Gold Mine minigame prototype. | Google Fonts, inline JS. | `GOLD_MINE_MINIGAME_PLAN.md`. | Drop spawning, cap meter, local interaction simulation. | Design prototype only; server must own final rewards. | Root placement; not production code. | None. | Move to `docs/features/gold-mine/` or `prototypes/`. | Needs review |
| `hero-card-delete-rings-layout.html` | Hero card delete/rings layout comparison. | Inline HTML/CSS. | Manual design review. | Four layout variants. | Design exploration only. | Root placement; no inbound docs link found beyond graph inventory. | None. | Candidate for archive/delete after hero-card decision is captured. | Deprecated |
| `hero-card-rings-deepdive.html` | Hero card rings deep-dive prototype. | Inline HTML/CSS. | Manual design review. | Hero card variants. | Design exploration only. | Root placement; no clear active consumer. | None. | Candidate for archive/delete after decision is captured. | Deprecated |
| `privacy.html` | Static privacy policy page. | Google Fonts. | Public/legal site routing or static hosting. | Legal text + minimal styles. | Must accurately describe data collection and account deletion. | Duplicate Google Fonts load via `@import` plus `<link>`. | Removed duplicate `@import`. | Legal review needed before App Store submission. | Fixed |
| `review-choose-hero-guest-gating-before-after.jsx` | Standalone React visual review for Choose Hero guest gating. | React/Tailwind-like classes in artifact context. | Graph only; no app import found. | `ChooseHeroGuestGatingReview`, layout helpers. | Design review only. | Root artifact; not wired into app build; unclear owner. | None. | Move to prototypes or delete after screenshot/decision is archived. | Needs review |
| `special_offer_widget_prototype.html` | Special Offer widget prototype v1. | Google Fonts, inline JS. | Manual design review. | Static widget and claim button demo. | Design prototype only. | Root placement; superseded by v2/v3. | None. | Candidate delete/archive after v3 accepted. | Deprecated |
| `special_offer_widget_v2_prototype.html` | Special Offer horizontal banner prototype v2. | Google Fonts, inline JS. | Manual design review. | Static banner and claim demo. | Design prototype only. | Root placement; likely superseded by v3. | None. | Candidate delete/archive after v3 accepted. | Deprecated |
| `special_offer_widget_v3_prototype.html` | Special Offer widget v3 with shop item cards. | Inline HTML/CSS. | Manual design review. | Static V3 layout. | Design prototype only. | Root placement; no production wiring. | None. | Move to docs/prototypes if still source of truth. | Needs review |
| `terms.html` | Static Terms of Service page. | Google Fonts. | Public/legal site routing or static hosting. | Legal text + minimal styles. | Must accurately describe IAP, virtual economy, account deletion, conduct. | Duplicate Google Fonts load via `@import` plus `<link>`. | Removed duplicate `@import`. | Legal review needed before App Store submission. | Fixed |

## Duplicate / Unclear Role Findings

- Root contains many design prototypes even though `.gitignore` says deleted prototypes should not be re-added. This is the main root hygiene issue.
- Combat prototype chain has historical duplicates: A/B/C → B2 → B2-v2 → B2-v3. Keep B2-v3 as active reference; archive older variants with the audit.
- Special offer prototype chain has v1/v2/v3. Keep v3 only if it is still an active visual source.
- `QA_REPORT_2026-04-09.md` belongs in `qa-reports/`; current root location weakens folder semantics.

## Fixes Applied

- Redacted a literal DB password from `HEXBOUND_PRE_RELEASE_AUDIT.md`.
- Marked stale combat/Gold Mine plans as historical, superseded, or implemented-with-drift.
- Removed duplicate Google Fonts `@import` from `privacy.html` and `terms.html`.
- Added `alt=""` to decorative DiceBear images in combat prototypes.

## Files to Delete / Move Candidates

- Delete/archive after confirmation: `combat-proto-A.html`, `combat-proto-B.html`, `combat-proto-C.html`, `hero-card-delete-rings-layout.html`, `hero-card-rings-deepdive.html`, `special_offer_widget_prototype.html`, `special_offer_widget_v2_prototype.html`.
- Move/keep as active reference: `combat-proto-B2-v3.html`, `gold_mine_minigame_prototype.html`, `special_offer_widget_v3_prototype.html`.
- Move to docs/QA folder: `QA_REPORT_2026-04-09.md`, `UI_RESPONSIVENESS_AUDIT.md`, combat and Gold Mine planning docs.

## Block Status

Status: Fixed with follow-up review needed for root prototype cleanup.
