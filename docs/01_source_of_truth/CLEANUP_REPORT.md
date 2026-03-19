# Hexbound — Documentation Cleanup Report

*Executed: 2026-03-19*

---

## A. Executive Summary

### What was messy
- 39 markdown files scattered across root, `/docs`, `/Hexbound`, `/admin`, `/backend` with no clear hierarchy
- Two versions of project rules (`CLAUDE.md` + `CLAUDE 2.md`) with no clear winner
- Two UX audit reports created 1 day apart with conflicting grades (B+ vs B−)
- Duplicate files: `ART_STYLE_GUIDE 2.md`, `mine-card-prompts 2.md`
- 13 prompt files scattered in root with no index

### What was outdated
- `PROJECT_KNOWLEDGE_v2.md` references Godot 4.3+ as mobile stack — actual is Swift/iOS
- Character origins in some docs: "elf, dwarf" — actual in backend: "skeleton, dogfolk"
- Some docs reference non-existent design tokens (`.accent`, `.primary` as color)

### What was missing
- No single API reference document
- No database schema reference (only Prisma files)
- No admin capabilities doc derived from actual admin panel code
- No consolidated game balance constants reference
- No economy system documentation
- No centralized prompt library index
- No design system token reference

### What was duplicated
- CLAUDE.md ↔ CLAUDE 2.md (rules)
- ART_STYLE_GUIDE.md ↔ ART_STYLE_GUIDE 2.md (identical)
- mine-card-prompts.md ↔ mine-card-prompts 2.md (identical)
- HEXBOUND_UI_UX_AUDIT_GUIDE.md ↔ HEXBOUND_UX_AUDIT_V2.md (v1 superseded by v2)
- PROJECT_KNOWLEDGE_v2.md ↔ multiple partial docs covering same topics

### Cleanup strategy
1. Analyzed all 4 codebases (backend, admin, iOS, database) as primary source of truth
2. Created canonical documentation from implementation, not from old docs
3. Consolidated duplicates, archived superseded files
4. Built clean 11-folder structure with one topic = one file

---

## B. Contradictions Found and Resolved

| Area | Old Docs Said | Implementation Says | Resolution |
|------|--------------|--------------------| -----------|
| Mobile Stack | Godot 4.3+ | Swift / SwiftUI / iOS | Updated all docs to Swift |
| Character Origins | human/elf/dwarf/orc/demon | human/orc/skeleton/demon/dogfolk | Updated to match backend enum |
| UX Grade | B+ (v1 audit) | B− (v2 audit, deeper analysis) | Kept v2 as canonical |
| Design Tokens | `.accent`, `.primary` (color) | `.gold`, `.bgPrimary` | Documented correct tokens |
| Button Styles | `.neutral` mentioned | `.primary`, `.secondary`, `.danger`, `.ghost` actual | Updated to match ButtonStyles.swift |
| Rarity Distribution | 40/30/20/8/2% (some docs) | Configurable via live config, various defaults | Documented actual defaults |
| Rules Language | CLAUDE 2.md in Russian | Project is international | Merged into English canonical rules |

---

## C. Final Documentation Structure

```
docs/
├── 01_source_of_truth/
│   ├── PROJECT_OVERVIEW.md          ← Project architecture & stack
│   ├── DOCUMENTATION_INDEX.md       ← Master index of all docs
│   └── CLEANUP_REPORT.md            ← This report
│
├── 02_product_and_features/
│   ├── GAME_SYSTEMS.md              ← All 17 game systems overview
│   └── ECONOMY.md                   ← Currencies, IAP, monetization
│
├── 03_backend_and_api/
│   └── API_REFERENCE.md             ← 142+ endpoints by category
│
├── 04_database/
│   ├── SCHEMA_REFERENCE.md          ← 40+ Prisma models
│   └── MIGRATIONS.md                ← Migration workflow
│
├── 05_admin_panel/
│   └── ADMIN_CAPABILITIES.md        ← 37 pages, 80+ configs, roles
│
├── 06_game_systems/
│   ├── COMBAT.md                    ← Damage formulas, ELO, stance
│   ├── BALANCE_CONSTANTS.md         ← All game constants with values
│   └── PROGRESSION.md               ← Leveling, prestige, skills, passives
│
├── 07_ui_ux/
│   ├── DESIGN_SYSTEM.md             ← DarkFantasyTheme tokens reference
│   ├── SCREEN_INVENTORY.md          ← 26+ screens with states
│   └── UX_AUDIT.md                  ← Current audit (v2, grade B−)
│
├── 08_prompts/
│   ├── ART_STYLE_GUIDE.md           ← Master art style for AI gen
│   └── ASSET_PROMPTS_INDEX.md       ← Index of 14 prompt collections
│
├── 09_rules_and_guidelines/
│   ├── DEVELOPMENT_RULES.md         ← Canonical rules (merged CLAUDE.md + 2)
│   └── UI_UX_PRINCIPLES.md          ← Design principles & audit format
│
├── 10_operations/
│   ├── FIGMA_HANDOFF.md             ← Figma structure spec
│   ├── FIGMA_SCREEN_INVENTORY.md    ← Screen-to-source mapping
│   ├── PROGRESS_LOG.md              ← Development changelog
│   ├── TESTFLIGHT_GUIDE.md          ← iOS testing procedures
│   └── UI_PR_CHECKLIST.md           ← PR review checklist
│
└── 11_archive/
    ├── ARCHIVE_INDEX.md             ← Why each file was archived
    ├── PROJECT_KNOWLEDGE_v2_LEGACY.md
    ├── CLAUDE_2_LEGACY.md
    ├── HEXBOUND_UI_UX_AUDIT_GUIDE_v1.md
    ├── UI_DESIGN_DOCUMENT_LEGACY.md
    ├── BALANCE_AUDIT_REPORT_2026-03-09.md
    ├── ADMIN_PANEL_AUDIT_REPORT_2026-03-16.md
    ├── ART_STYLE_GUIDE_DUPLICATE.md
    ├── mine-card-prompts_DUPLICATE.md
    ├── COMBAT_SPRITES_LIST.md
    └── PROMPT_HUB_CITY_IMPLEMENTATION.md
```

**Active docs**: 23 files across 10 categories
**Archived**: 11 files (duplicates, superseded, point-in-time snapshots)

---

## D. What Was Completed

| Action | Files |
|--------|-------|
| **Created from implementation** | PROJECT_OVERVIEW, API_REFERENCE, SCHEMA_REFERENCE, ADMIN_CAPABILITIES, COMBAT, BALANCE_CONSTANTS, PROGRESSION, ECONOMY, GAME_SYSTEMS, DESIGN_SYSTEM, SCREEN_INVENTORY |
| **Consolidated/merged** | DEVELOPMENT_RULES (from CLAUDE.md + CLAUDE 2.md), UI_UX_PRINCIPLES (from hexbound-game-design-SKILL.md + audits) |
| **Centralized** | ART_STYLE_GUIDE, ASSET_PROMPTS_INDEX (index of 14 prompt files) |
| **Organized** | FIGMA_HANDOFF, FIGMA_SCREEN_INVENTORY, TESTFLIGHT_GUIDE, UI_PR_CHECKLIST, PROGRESS_LOG, MIGRATIONS moved to proper locations |
| **Archived** | 11 files: duplicates, superseded versions, point-in-time audits |
| **Updated** | CLAUDE.md (added pointer to new docs structure) |
| **Created indices** | DOCUMENTATION_INDEX, ARCHIVE_INDEX, ASSET_PROMPTS_INDEX |

---

## E. Items Requiring Human Decision

1. **Root-level cleanup**: Old .md files still exist in project root (BALANCE_AUDIT_REPORT.md, HEXBOUND_UX_AUDIT_V2.md, etc.). They've been copied to `/docs/` structure but originals remain. Should originals be deleted or left for backward compatibility?

2. **Prompt files**: 14 prompt files remain in project root. They're indexed in `docs/08_prompts/ASSET_PROMPTS_INDEX.md`. Should they be moved into `docs/08_prompts/` or kept in place (some may be referenced by tools/scripts)?

3. **Image assets at root**: `hf_*.png` files (78MB each), `icon-fights-stray.png` in root. Are these temporary or should they be organized into an assets folder?

4. **`hexbound-game-design-SKILL.md`**: This is a skill definition file (used by AI agents). Content merged into UI_UX_PRINCIPLES. Keep the skill file active alongside the doc, or remove it?

5. **`daily-login-redesign.jsx`**: React artifact in root. Archive or keep as active reference?

6. **`CLAUDE 2.md`**: Content merged into DEVELOPMENT_RULES.md. Delete from root or keep as legacy?

---

## F. Maintenance Guidelines

- **When code changes**: Update the relevant doc in `docs/01-10_*/`
- **Never update archive**: Archive is frozen point-in-time
- **One topic = one file**: Don't create overlapping docs
- **Implementation wins**: If doc contradicts code, update the doc
- **Verify tokens**: Before referencing design system tokens, check source Swift files
