# Documentation Migration Plan

> **Date:** 2026-03-26
> **Status:** Phase 1 + Phase 2 Complete

---

## Current State → Target State

### What was done (Phase 1 — Complete)

| Action | Status |
|--------|--------|
| Created `docs/PROJECT_INDEX.md` — main navigator | Done |
| Created `docs/SOURCE_OF_TRUTH.md` — truth matrix | Done |
| Created `docs/AGENT_LOADING_GUIDE.md` — agent doc guide | Done |
| Created 10 rule files in `docs/rules/` | Done |
| Mirrored rules to `.cursor/rules/*.mdc` | Done |
| Created 4 templates in `docs/templates/` | Done |
| Created 12 feature folders in `docs/features/` | Done |
| Created `docs/features/arena/ARENA_OVERVIEW.md` (example) | Done |
| Created `docs/features/guild-hall/GUILD_HALL_OVERVIEW.md` (example) | Done |
| Created skill `doc-keeper` in `.claude/skills/` | Done |

### What stays unchanged

| File/Folder | Why |
|-------------|-----|
| `CLAUDE.md` (root) | Works, auto-loaded, critical rules. NOT splitting |
| `docs/01_source_of_truth/` | Existing structure works |
| `docs/02_product_and_features/` | Keep as-is (design docs) |
| `docs/03_backend_and_api/` | Keep (API reference) |
| `docs/04_database/` | Keep (schema docs) |
| `docs/05_admin_panel/` | Keep (admin docs) |
| `docs/06_game_systems/` | Keep (game system deep dives) |
| `docs/07_ui_ux/` | Keep (design system, screens) |
| `docs/08_prompts/` | Keep (art prompts) |
| `docs/09_rules_and_guidelines/` | Keep for backward compat |
| `docs/10_operations/` | Keep (ops docs) |
| `docs/11_archive/` | Keep (archive) |
| `docs/retro/` | Keep (retrospectives) |

---

## Phase 2 — Feature Docs (Complete)

Create feature overviews for remaining features. Priority order:

1. **Shop** — `docs/features/shop/SHOP_OVERVIEW.md`
2. **Dungeons** — `docs/features/dungeons/DUNGEONS_OVERVIEW.md`
3. **Battle Pass** — `docs/features/battle-pass/BATTLE_PASS_OVERVIEW.md`
4. **Daily Systems** — `docs/features/daily-systems/DAILY_SYSTEMS_OVERVIEW.md`
5. **Achievements** — `docs/features/achievements/ACHIEVEMENTS_OVERVIEW.md`
6. **Inventory** — `docs/features/inventory/INVENTORY_OVERVIEW.md`
7. **Gold Mine** — `docs/features/gold-mine/GOLD_MINE_OVERVIEW.md`
8. **Minigames** — `docs/features/minigames/MINIGAMES_OVERVIEW.md`
9. **Combat** — `docs/features/combat/COMBAT_OVERVIEW.md`

Use `docs/templates/TEMPLATE_FEATURE.md` for each.

## Phase 3 — Screen Docs (Optional)

Create per-screen docs for complex screens. Use `TEMPLATE_SCREEN.md`.

## Phase 4 — API Module Docs (Optional)

Create per-module API docs. Use `TEMPLATE_API_MODULE.md`.

---

## File Map (Where to find what)

| Need | Location |
|------|---------|
| Экраны iOS | `Hexbound/Hexbound/Views/` + `docs/07_ui_ux/SCREEN_INVENTORY.md` |
| API endpoints | `backend/src/app/api/` + `docs/03_backend_and_api/API_REFERENCE.md` |
| DB models | `backend/prisma/schema.prisma` + `docs/04_database/SCHEMA_REFERENCE.md` |
| Balance | `backend/src/lib/game/` + `docs/06_game_systems/BALANCE_CONSTANTS.md` |
| UI tokens | `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift` + `docs/07_ui_ux/DESIGN_SYSTEM.md` |
| Animations | `docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md` |
| Ассеты | `docs/08_prompts/` |
| Админка | `admin/src/` + `docs/05_admin_panel/ADMIN_CAPABILITIES.md` |
| Deploy | `docs/10_operations/DEPLOY.md` |
| Правила | `docs/rules/` (canonical) + `.cursor/rules/` (Cursor mirror) |
| Фичи | `docs/features/{feature-name}/` |
| Шаблоны | `docs/templates/` |

---

## Cleanup (Done in Phase 1)

| Item | Action |
|------|--------|
| Stray docs at `docs/` root | Keep: `ORCHESTRATOR.md`, `FULL_PRODUCT_AUDIT_2026-03-21.md` |
| Duplicate `FIGMA_HANDOFF.md` at root | Already has copies in `10_operations/` — root copies are stubs |
| `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md` | Keep for backward compat, rules are now modular in `docs/rules/` |

---

## Naming Convention

| Type | Pattern | Location |
|------|---------|---------|
| Feature doc | `{FEATURE}_OVERVIEW.md` | `docs/features/{feature}/` |
| Screen doc | `{SCREEN}_SCREEN.md` | `docs/features/{feature}/` |
| Rule file | `rules-{domain}.md` | `docs/rules/` |
| Cursor rule | `rules-{domain}.mdc` | `.cursor/rules/` |
| Template | `TEMPLATE_{TYPE}.md` | `docs/templates/` |
| Retro | `RETRO_{YYYY-MM-DD}.md` | `docs/retro/` |
| Archive | `*_LEGACY.md` or `*_{YYYY-MM-DD}.md` | `docs/11_archive/` |
