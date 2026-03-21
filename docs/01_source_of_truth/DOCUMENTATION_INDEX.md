# Hexbound — Documentation Index (Master Reference)

*Master index of all active project documentation. Last updated: 2026-03-21*

---

## About This Index

This file is the canonical entry point for finding documentation on the Hexbound project. All active docs are listed with brief descriptions and locations. Legacy docs are archived in `docs/11_archive/`.

---

## Category 1: Source of Truth

These files define the current project state and structure.

| Document | Location | Purpose |
|----------|----------|---------|
| **Project Overview** | `docs/01_source_of_truth/PROJECT_OVERVIEW.md` | Complete tech stack, all game systems, database schema, 40+ models, 20+ iOS screens, 38 admin pages, architecture decisions |
| **Documentation Index** | `docs/01_source_of_truth/DOCUMENTATION_INDEX.md` | This file — master reference guide |
| **Cleanup Report** | `docs/01_source_of_truth/CLEANUP_REPORT.md` | 2026-03-19 documentation audit: what was changed, contradictions found, decisions made |

---

## Category 2: Product & Features

Game design, systems overview, economy, and feature specs.

| Document | Location | Purpose |
|----------|----------|---------|
| **Game Systems** | `docs/02_product_and_features/GAME_SYSTEMS.md` | PvP combat, dungeons, skills, passives, equipment, daily systems, battle pass, achievements, leaderboards, mail, cosmetics |
| **Economy & Monetization** | `docs/02_product_and_features/ECONOMY.md` | Currency types (gold, gems, arena tokens), pricing, IAP tiers, shop rotation, gold sinks/faucets, daily gem card, prestige costs |
| **World & Lore** | `docs/02_product_and_features/WORLD_AND_LORE.md` | Setting (The Hex), origins/races lore, class archetypes, key locations, tone guide for writing, narrative approach |
| **Audio Design** | `docs/02_product_and_features/AUDIO_DESIGN.md` | Music vision, SFX list (combat/UI/dungeon), haptic feedback, technical requirements, asset sourcing strategy |

---

## Category 3: Backend & API

API endpoint reference, business logic, formulas, and server architecture.

| Document | Location | Purpose |
|----------|----------|---------|
| **API Reference** | `docs/03_backend_and_api/API_REFERENCE.md` | All REST endpoints (auth, characters, PvP, dungeons, economy, admin), request/response schemas |

---

## Category 4: Database

Schema, models, migrations, and data management.

| Document | Location | Purpose |
|----------|----------|---------|
| **Schema Reference** | `docs/04_database/SCHEMA_REFERENCE.md` | Complete Prisma schema: all 40+ models, enums, relationships, indexes, field descriptions |
| **Migrations** | `docs/04_database/MIGRATIONS.md` | Migration workflow, how to add/modify tables, rollback procedures, testing migrations locally |

---

## Category 5: Admin Panel

Admin capabilities, live configuration, and management tools.

| Document | Location | Purpose |
|----------|----------|---------|
| **Admin Capabilities** | `docs/05_admin_panel/ADMIN_CAPABILITIES.md` | Full list of 37+ admin pages: character management, item CRUD, economy controls, 80+ config params, feature flags, live config, analytics, audit logs |

---

## Category 6: Game Systems

Deep dives into specific game mechanics, formulas, and balance constants.

| Document | Location | Purpose |
|----------|----------|---------|
| **Combat System** | `docs/06_game_systems/COMBAT.md` | Turn-based PvP combat flow, attack/defense calculations, crit/dodge, status effects, seeded RNG for reproducibility |
| **Balance Constants** | `docs/06_game_systems/BALANCE_CONSTANTS.md` | All tunable game constants (damage base multipliers, XP thresholds, stat scaling, cooldown durations, stamina costs) |
| **Progression & Leveling** | `docs/06_game_systems/PROGRESSION.md` | Level progression curve (XP per level), stat point allocation, skill unlock levels, prestige system, passive tree tier costs |

---

## Category 7: UI/UX

Design system, screen inventory, and user experience audits.

| Document | Location | Purpose |
|----------|----------|---------|
| **Design System** | `docs/07_ui_ux/DESIGN_SYSTEM.md` | DarkFantasyTheme token reference (colors, fonts, spacing), ButtonStyles (all variants), LayoutConstants, component library overview |
| **Screen Inventory** | `docs/07_ui_ux/SCREEN_INVENTORY.md` | All 20+ iOS screens: name, purpose, states (empty/loading/error/success), wireframes, navigation flows |
| **UX Audit (v2)** | `docs/07_ui_ux/UX_AUDIT.md` | Current UX assessment: strengths, issues with impact/priority, recommendations per screen, 3-second rule compliance |

---

## Category 8: Prompts & Assets

Art style guides and AI generation prompts for consistent asset creation.

| Document | Location | Purpose |
|----------|----------|---------|
| **Art Style Guide** | `docs/08_prompts/ART_STYLE_GUIDE.md` | Canonical art reference: pen & ink illustration, muted earth tones + 1-2 saturated accents, D&D Monster Manual style, NOT digital painting |
| **Asset Prompts** | `docs/08_prompts/ASSET_PROMPTS_INDEX.md` | Consolidated AI image generation prompts for all assets: heroes, bosses, items, UI icons, backgrounds (follows art style guide) |

---

## Category 9: Rules & Guidelines

Development rules, design principles, and implementation standards.

| Document | Location | Purpose |
|----------|----------|---------|
| **Development Rules** | `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md` | Canonical rules for coding: Xcode project file management, design system token usage, Swift concurrency (@MainActor), admin panel strict null checks, TypeScript best practices |
| **UI/UX Design Principles** | `docs/09_rules_and_guidelines/UI_UX_PRINCIPLES.md` | Product design rules: 3-second rule, one goal per screen, no dead ends, short sessions, monetization as acceleration, mobile UX minimums, game systems checklist, server-authoritative rule |

---

## Category 10: Operations & DevOps

Deployment, testing, CI/CD, and handoff procedures.

| Document | Location | Purpose |
|----------|----------|---------|
| **Deploy Guide** | `docs/10_operations/DEPLOY.md` | Full deploy flow: backend (Vercel auto), admin (subtree), iOS (Fastlane), rollback |
| **Git Workflow** | `docs/10_operations/GIT_WORKFLOW.md` | Branch strategy, remotes, subtree push, tagging |
| **Database Migrations** | `docs/10_operations/DATABASE_MIGRATIONS.md` | Prisma migration flow, schema sync, production safety |
| **iOS Release** | `docs/10_operations/RELEASE_IOS.md` | Fastlane setup, TestFlight upload, versioning, env config |
| **Git & Deploy Audit** | `docs/10_operations/GIT_AND_DEPLOY_AUDIT.md` | 2026-03-19 audit: risks, source of truth map |
| **TestFlight Guide** | `docs/10_operations/TESTFLIGHT_GUIDE.md` | Detailed App Store Connect + TestFlight setup |
| **UI PR Checklist** | `docs/10_operations/UI_PR_CHECKLIST.md` | Code review checklist for UI/UX PRs |
| **Figma Handoff** | `docs/10_operations/FIGMA_HANDOFF.md` | Design → code workflow: Figma conventions |
| **Figma Screen Inventory** | `docs/10_operations/FIGMA_SCREEN_INVENTORY.md` | Figma screen-to-source mapping |
| **Progress Log** | `docs/10_operations/PROGRESS_LOG.md` | Development changelog |

---

## Category 11: Archive

Superseded, legacy, or reference-only documents.

| Document | Location | Purpose |
|----------|----------|---------|
| **(All legacy docs)** | `docs/11_archive/` | Old versions of live docs, deprecated APIs, removed features, historical decisions |

---

## Quick Reference by Role

### For Backend Developers
1. Start with: **PROJECT_OVERVIEW.md** (tech stack, Prisma models)
2. Then read: **API_REFERENCE.md** (endpoints, schemas)
3. Reference: **BALANCE_CONSTANTS.md** (formulas), **SCHEMA_REFERENCE.md** (models), **BALANCE_CONSTANTS.md** (tuning)
4. Implement: Follow **DEVELOPMENT_RULES.md** (strict null checks, TypeScript)

### For Admin Panel Developers
1. Start with: **PROJECT_OVERVIEW.md** (tech stack, 38 pages overview)
2. Then read: **ADMIN_CAPABILITIES.md** (what each page does)
3. Reference: **ADMIN_CAPABILITIES.md** (all config keys)
4. Implement: Follow **DEVELOPMENT_RULES.md** (strict null checks, TypeScript, form validation)

### For iOS/SwiftUI Developers
1. Start with: **PROJECT_OVERVIEW.md** (tech stack, 20+ screens overview)
2. Then read: **SCREEN_INVENTORY.md** (all screens, states, navigation)
3. Reference: **DESIGN_SYSTEM.md** (tokens, buttons, spacing)
4. Implement: Follow **DEVELOPMENT_RULES.md** (Xcode project file, @MainActor, design system usage)
5. Design: **ART_STYLE_GUIDE.md**, **ASSET_PROMPTS_INDEX.md** (for imagery)

### For Game Designers / PMs
1. Start with: **PROJECT_OVERVIEW.md** (game systems summary)
2. Then read: **GAME_SYSTEMS.md** (detailed system descriptions)
3. Reference: **ECONOMY.md** (pricing, monetization), **BALANCE_CONSTANTS.md** (tuning parameters)
4. Analyze: **UX_AUDIT.md** (current state, improvement areas)

### For QA / Testers
1. Start with: **PROJECT_OVERVIEW.md** (overview)
2. Then read: **GAME_SYSTEMS.md** (mechanics to test)
3. Reference: **BALANCE_CONSTANTS.md** (expected values), **TESTFLIGHT_GUIDE.md** (how to get builds)
4. Use: **UI_PR_CHECKLIST.md** (testing criteria)

### For Admins / Operations
1. Start with: **PROJECT_OVERVIEW.md** (deployment info)
2. Then read: **ADMIN_CAPABILITIES.md** (what you can do)
3. Reference: **ADMIN_CAPABILITIES.md** (config keys to edit)
4. Use: **TESTFLIGHT_GUIDE.md** (iOS deployment)

---

## Search by Topic

### PvP Combat
- **PROJECT_OVERVIEW.md** — PvP system overview
- **GAME_SYSTEMS.md** — Combat mechanics detail
- **COMBAT.md** — Turn-by-turn flow, formulas
- **BALANCE_CONSTANTS.md** — Damage multipliers, crit rates

### Dungeons
- **PROJECT_OVERVIEW.md** — Dungeon system overview
- **GAME_SYSTEMS.md** — Difficulty, boss encounters, loot
- **BALANCE_CONSTANTS.md** — Boss HP, drop rates

### Skills & Passives
- **GAME_SYSTEMS.md** — Skill system, passive tree
- **BALANCE_CONSTANTS.md** — Damage scaling, cooldowns
- **PROGRESSION.md** — Skill unlock levels

### Equipment & Inventory
- **GAME_SYSTEMS.md** — Equipment system
- **BALANCE_CONSTANTS.md** — Item stat ranges
- **API_REFERENCE.md** — Equipment endpoints

### Economy (Gold, Gems, IAP)
- **ECONOMY.md** — Currency types, pricing, monetization
- **GAME_SYSTEMS.md** — Gold sinks/faucets, daily gem card
- **ADMIN_CAPABILITIES.md** — Economy config keys
- **BALANCE_CONSTANTS.md** — Gold/gem reward formulas

### Cosmetics & Appearance
- **GAME_SYSTEMS.md** — Cosmetic types, pricing
- **ECONOMY.md** — Cosmetic pricing, IAP bundles

### Battle Pass & Seasons
- **GAME_SYSTEMS.md** — Battle pass mechanics
- **ECONOMY.md** — Pricing, premium tier benefits
- **ADMIN_CAPABILITIES.md** — Battle pass admin page

### Daily Systems (Quests, Login, Training)
- **GAME_SYSTEMS.md** — Daily quest types, daily login, training ground
- **BALANCE_CONSTANTS.md** — Quest XP/gold rewards

### Achievements
- **GAME_SYSTEMS.md** — Achievement system
- **ADMIN_CAPABILITIES.md** — Achievement admin page

### Admin Panel
- **PROJECT_OVERVIEW.md** — 38 admin pages listed
- **ADMIN_CAPABILITIES.md** — Detailed page descriptions
- **ADMIN_CAPABILITIES.md** — All 80+ config keys

### Design System (iOS)
- **DESIGN_SYSTEM.md** — DarkFantasyTheme, ButtonStyles, LayoutConstants
- **DEVELOPMENT_RULES.md** — Design system usage rules

### iOS Screens & Navigation
- **SCREEN_INVENTORY.md** — All 20+ screens, states
- **UX_AUDIT.md** — Current UX, issues, recommendations

### Push Notifications
- **GAME_SYSTEMS.md** — Push system overview
- **ADMIN_CAPABILITIES.md** — Push campaign creation page
- **API_REFERENCE.md** — Push endpoints

### Leaderboards
- **GAME_SYSTEMS.md** — Leaderboard system
- **API_REFERENCE.md** — Leaderboard endpoints

### Mail/Inbox
- **GAME_SYSTEMS.md** — Mail system
- **ADMIN_CAPABILITIES.md** — Mail composition page

### World, Lore & Audio
- **WORLD_AND_LORE.md** — Setting, origins, classes, tone, locations, narrative approach
- **AUDIO_DESIGN.md** — Music, SFX, haptics, technical requirements

### Art & Asset Generation
- **ART_STYLE_GUIDE.md** — Art style rules
- **ASSET_PROMPTS_INDEX.md** — AI generation prompts

### Development Standards
- **DEVELOPMENT_RULES.md** — All coding/project rules
- **UI_UX_PRINCIPLES.md** — Product design rules

---

## Common Workflow Checklist

### "I need to add a new feature"
1. [ ] Read **PROJECT_OVERVIEW.md** to understand architecture
2. [ ] Check **GAME_SYSTEMS.md** for related mechanics
3. [ ] Read **BALANCE_CONSTANTS.md** for relevant formulas
4. [ ] Design screens using **DESIGN_SYSTEM.md** tokens
5. [ ] Follow **DEVELOPMENT_RULES.md** for implementation
6. [ ] Test against **BALANCE_CONSTANTS.md** expected values
7. [ ] Run **UI_PR_CHECKLIST.md** before submission

### "I need to balance a game constant"
1. [ ] Read **BALANCE_CONSTANTS.md** to find the value
2. [ ] Use **ADMIN_CAPABILITIES.md** to find the config key
3. [ ] Check **BALANCE_CONSTANTS.md** for impact analysis
4. [ ] Edit via **ADMIN_CAPABILITIES.md** admin panel
5. [ ] Test impact in staging

### "I'm adding a new item/skill/boss"
1. [ ] Review **PROJECT_OVERVIEW.md** schema (Item, Skill, DungeonBoss models)
2. [ ] Check **BALANCE_CONSTANTS.md** for stat ranges
3. [ ] Use **ADMIN_CAPABILITIES.md** to add via admin panel
4. [ ] Update **ASSET_PROMPTS_INDEX.md** if adding art
5. [ ] Test in game

### "I need to design a new screen"
1. [ ] Read **UI_UX_PRINCIPLES.md** (3-second rule, one goal, no dead ends)
2. [ ] Check **SCREEN_INVENTORY.md** for similar screens
3. [ ] Use **DESIGN_SYSTEM.md** tokens (DarkFantasyTheme, ButtonStyles, LayoutConstants)
4. [ ] Follow **DEVELOPMENT_RULES.md** for iOS implementation
5. [ ] Run **UI_PR_CHECKLIST.md** before submission

### "I'm submitting an iOS build"
1. [ ] Follow **TESTFLIGHT_GUIDE.md** build process
2. [ ] Check **UI_PR_CHECKLIST.md** for quality gates
3. [ ] Verify design system compliance (**DESIGN_SYSTEM.md**)
4. [ ] Test all **SCREEN_INVENTORY.md** states

---

## Document Metadata

| Attribute | Value |
|-----------|-------|
| **Total Active Docs** | 25 |
| **Total Archive Docs** | [See `docs/11_archive/`] |
| **Last Full Sync** | 2026-03-19 |
| **Created By** | Engineering Team |
| **Maintained By** | [TBD] |

---

## How to Update This Index

1. **Add a new doc**: Create it in the appropriate numbered category folder
2. **Update this file**: Add row to the relevant category table with document name, location, purpose
3. **Archive old docs**: Move to `docs/11_archive/` with timestamp in filename
4. **Update "Last Updated"** at top of this file
5. **Commit** with message: "docs: add/update [doc name]"

---

## For Questions or Clarifications

If you can't find what you're looking for in this index, refer to:

- **PROJECT_OVERVIEW.md** for system-level questions
- **[Role-specific section above](#quick-reference-by-role)** for role-based guidance
- **GitHub Issues** with label `documentation` for doc bugs/gaps

---

*End of Index. Thank you for reading!*
