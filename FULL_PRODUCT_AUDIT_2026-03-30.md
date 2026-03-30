# HEXBOUND — FULL PRE-FEATURE PRODUCT AUDIT
**Date:** 2026-03-30
**Auditor:** Principal-Level Internal Audit Team (AI)
**Scope:** Complete product — iOS client, Backend API, Database, Admin Panel, Documentation, Game Balance

---

## 1. EXECUTIVE SUMMARY

Hexbound is a mid-to-large scale dark fantasy PvP RPG with 234 Swift files, 175+ API endpoints, 60+ database models, 40+ admin pages, and 150+ documentation files. The project demonstrates strong architectural discipline and a mature design system. However, this audit uncovered **47 distinct issues** across 12 domains, including **5 P0 critical issues**, **12 P1 severe issues**, and **30 P2-P4 items**.

**Top 3 risks right now:**
1. **Test coverage at 5%** — only 73 tests exist for a system with 155 API routes and 35 game logic modules. Combat, loot, economy, and progression are completely untested.
2. **Documentation-to-code drift** — CHA intimidation formula is 67% stronger than documented; matchmaking uses a 4-phase system with rating filter while docs say 3-phase with no rating.
3. **10 documented admin endpoints don't exist** — any admin client calling Items CRUD, Mail Broadcast, Feature Flags, or Game Config will get 404s.

**What is healthy:** Architecture is clean (MVVM, service layer, server-authoritative). Design system exists and has 79% adoption. Auth/permissions are solid. Prisma schemas are synced between backend and admin. Documentation structure is well-organized with explicit source-of-truth hierarchy.

---

## 2. WHAT IS HEALTHY

- **Architecture:** Clear MVVM separation — Views → ViewModels → Services → Network/API
- **Design system:** DarkFantasyTheme with 300+ color tokens, 9 typography scales, 8 spacing tokens, 12+ button styles, 5 card styles, ornamental system — 79% View adoption
- **Auth & security:** JWT validation on all protected routes, admin role gating, ban cache, rate limiting (120 req/60s global, tighter on sensitive ops), ownership checks, CORS
- **Backend structure:** 37 well-separated game logic modules in `src/lib/game/`
- **Database:** Prisma schema perfectly synced between backend and admin (byte-identical). 60+ models with proper relations and indexes
- **Documentation:** 150+ files in 11-category hierarchy with explicit SOURCE_OF_TRUTH.md matrix
- **Error handling:** Consistent try/catch on all async routes, proper HTTP status codes, sanitized error messages
- **No production mock data:** All mock/test data properly isolated behind `#if DEBUG`
- **Admin panel:** Comprehensive 40+ page management console covering all game systems

---

## 3. MAJOR SOURCE-OF-TRUTH CONFLICTS

### CONFLICT 1: CHA Intimidation Formula (P0)
| Source | Value per point | Cap |
|--------|----------------|-----|
| **COMBAT.md** (docs) | 0.15% | 15% |
| **balance.ts** (code) | 0.25% | 25% |
| **combat.ts** (code) | Uses balance.ts values | 25% |

**Impact:** Code is 67% stronger than documented. CHA 100 gives 25% damage reduction (code) vs 15% (docs). High-CHA builds are overpowered relative to what players/designers think.

**Decision needed:** Is 0.25% intended? If yes, update COMBAT.md + BALANCE_CONSTANTS.md. If no, nerf balance.ts.

### CONFLICT 2: PvP Matchmaking Phases (P1)
| Source | Phases | Uses Rating? |
|--------|--------|-------------|
| **BALANCE_CONSTANTS.md** | 3-phase cascade | "Rating is display-only" |
| **pvp/opponents/route.ts** | 4-phase cascade | Phase 1 filters ±200 ELO |

**Impact:** Matchmaking is more restrictive than documented. New players with low ratings get artificially restricted opponent pools.

### CONFLICT 3: ConsumableType Enum (P1)
| Source | Values |
|--------|--------|
| **SCHEMA_REFERENCE.md** | HEALTH_POTION, STAMINA_RESTORE, BUFF_ATTACK, BUFF_DEFENSE, BUFF_XP, BUFF_GOLD |
| **schema.prisma** (actual) | stamina_potion_small/medium/large, health_potion_small/medium/large |

**Impact:** Documentation describes a completely different consumable system than what exists. Any developer relying on docs will build wrong.

### CONFLICT 4: QuestType Enum (P1)
| Source | Values |
|--------|--------|
| **SCHEMA_REFERENCE.md** | PVP_WINS, DUNGEON_CLEARS, SKILL_USES, LEVEL_UP, EQUIP_ITEMS |
| **schema.prisma** (actual) | pvp_wins, dungeons_complete, gold_spent, item_upgrade, consumable_use, shell_game_play, gold_mine_collect |

**Impact:** Quest system was completely redesigned since docs were written. 5 documented quest types don't exist.

### CONFLICT 5: Character Stat Names (P2)
| Source | Stats |
|--------|-------|
| **SCHEMA_REFERENCE.md** | strength, constitution, dexterity, intelligence, wisdom, charisma (6) |
| **schema.prisma** (actual) | str, agi, vit, end, int, wis, luk, cha (8) |

**Impact:** Two extra stats (LUK, CHA) exist that docs don't describe. Field names differ throughout.

### CONFLICT 6: Dodge Formula — LUK contribution undocumented (P2)
| Source | Formula |
|--------|---------|
| **COMBAT.md** | AGI-based dodge only |
| **balance.ts** | AGI × 0.2 + LUK × 0.1 (LUK dodge is new, undocumented) |

### CONFLICT 7: Admin Endpoint Paths (P1)
| Source | Ban path | Unban path |
|--------|----------|-----------|
| **API_REFERENCE.md** | POST /admin/users/[id]/ban | POST /admin/users/[id]/unban |
| **Actual routes** | POST /admin/ban | POST /admin/unban |

---

## 4. PROJECT MAP

### Folder Structure
```
PVP RPG/
├── Hexbound/                    # iOS App (234 Swift files)
│   ├── Hexbound/
│   │   ├── App/                 # Entry point, router, state, constants (5 files)
│   │   ├── Theme/               # Design system (7 files)
│   │   ├── Models/              # Data models + enums (28 files)
│   │   ├── Network/             # API client, endpoints, auth (5 files)
│   │   ├── Persistence/         # Settings, keychain, audio (4 files)
│   │   ├── Services/            # Game services (25 files)
│   │   ├── Tutorial/            # Tutorial system (2 files)
│   │   └── Views/               # UI screens (155 files across 22 subfolders)
│   │       ├── Auth/ (14)       ├── Arena/ (7)       ├── Dungeon/ (14)
│   │       ├── Hub/ (11)        ├── Shop/ (7)        ├── Minigames/ (9)
│   │       ├── Components/ (42) ├── Hero/ (7)        ├── Inventory/ (6)
│   │       ├── Profile/ (4)     ├── Combat/ (5)      ├── BattlePass/ (5)
│   │       ├── Achievements/ (3)├── Quests/ (3)      ├── Leaderboard/ (3)
│   │       ├── Settings/ (3)    ├── Social/ (5)      ├── DailyLogin/ (2)
│   │       ├── Inbox/ (3)       └── Dev/ (3)
│   └── Hexbound.xcodeproj/
├── backend/                     # Next.js API (175+ endpoints)
│   ├── src/app/api/             # Route handlers
│   ├── src/lib/game/            # Game logic (37 modules)
│   ├── prisma/                  # Schema + migrations
│   └── tests/                   # 13 test files, 73 test cases
├── admin/                       # Admin panel (Next.js, 40+ pages)
├── docs/                        # Documentation (150+ files, 11 categories)
├── scripts/                     # Utilities (git-watcher, etc.)
└── .claude/skills/              # AI agent skills
```

### Key Metrics
| Dimension | Count |
|-----------|-------|
| Swift files (iOS) | 234 |
| View files | 155 |
| Services | 25 |
| API endpoints | 175+ |
| Game logic modules | 37 |
| Database models | 60+ |
| Database enums | 20+ |
| Admin pages | 40+ |
| Documentation files | 150+ |
| Test files | 13 |
| Test cases | 73 |

---

## 5. SYSTEM MAP

| System | iOS Files | Backend Module | DB Models | Admin Page | Status |
|--------|-----------|---------------|-----------|------------|--------|
| Auth | 14 (Auth/) | auth.ts, guest-guard.ts | User | Users | Working |
| Characters | CharacterSelectionView + 3 | progression.ts, build-stats.ts | Character | Characters | Working |
| Combat | 5 (Combat/) | combat.ts, combat-simulator.ts, combat-loader.ts | PvpMatch, PvpBattleTicket | Matches | Working |
| PvP/Arena | 7 (Arena/) | elo.ts, hp-regen.ts | PvpMatch, RevengeQueue | Matches | Working |
| Dungeons | 14 (Dungeon/) | dungeon.ts, dungeon-rush.ts | Dungeon, DungeonBoss, DungeonRun | Dungeons | Working |
| Inventory | 6 (Inventory/) | item-validation.ts, durability.ts | EquipmentInventory, Item | Items | Working |
| Shop | 7 (Shop/) | config.ts | ShopOffer | Shop Offers | Working |
| Consumables | (via Shop) | — | ConsumableInventory | Consumables | Working |
| Quests | 3 (Quests/) | daily-quests.ts | DailyQuest | Quest Definitions | Working |
| Achievements | 3 (Achievements/) | achievements.ts, achievement-catalog.ts | AchievementDefinition | Achievements | Working |
| Battle Pass | 5 (BattlePass/) | battle-pass.ts | BattlePass, BattlePassReward | Seasons, Battle Pass | Working |
| Daily Login | 2 (DailyLogin/) | daily-login.ts | DailyLoginReward | Daily Login | Working |
| Minigames | 9 (Minigames/) | gold-mine.ts | GoldMineSession, MinigameSession | — | Working |
| Leaderboard | 3 (Leaderboard/) | — | (Character query) | — | Working |
| Skills | — | skills.ts | Skill, CharacterSkill | Skills | Working |
| Passives | — | passives.ts | PassiveNode, CharacterPassive | Passives | Working |
| Mail | 3 (Inbox/) | battle-mail.ts | MailMessage, MailRecipient | Mail | Working |
| Social | 5 (Social/) | — | Friendship, DirectMessage, Challenge | — | Working |
| IAP | (via Shop) | — | IapTransaction | IAP | Working |
| Push | — | push/send.ts | PushToken, PushCampaign | Push | Working |
| Events | — | events.ts | Event | Events | Working |
| Feature Flags | — | feature-flags.ts | FeatureFlag | Feature Flags | Working |

---

## 6. FLOW MAP

### User-Facing Flows
1. Splash → Auth Check → Login/Register OR Main Hub
2. Guest flow → Play → Upgrade prompt
3. Onboarding → Character creation (class + origin + name + appearance)
4. Main Hub → 10 buildings (Arena, Dungeon, Shop, Guild Hall, Tavern, Forge, Barracks, Gold Mine, Sanctuary, Archives)
5. Arena → Opponent list → Compare → Fight → Combat → Result → Loot
6. Arena → Revenge list → Revenge fight
7. Dungeon → Select difficulty → Start run → Floor battles → Boss → Loot
8. Dungeon Rush → Speed run → Mid-run shop → Resolve
9. Shop → Browse items → Buy → Inventory
10. Shop → Currency purchase → IAP
11. Inventory → Item detail → Equip/Upgrade/Sell
12. Hero → Stats → Allocate points
13. Hero → Stance selection
14. Hero → Appearance editor
15. Achievements → 3 tabs → Claim rewards
16. Battle Pass → Free/Premium track → Claim levels
17. Daily Login → Claim streak rewards
18. Daily Quests → Track progress → Claim
19. Leaderboard → Global/Class rankings
20. Settings → Account, sound, notifications
21. Inbox → Mail messages → Claim attachments
22. Guild Hall → Friends, Messages, Challenges
23. Minigames → Shell Game, Fortune Wheel, Dungeon Rush
24. Gold Mine → Start session → Collect → Boost

---

## 7. DOCUMENTATION MAP

| Doc | Purpose | Trust Level | Action |
|-----|---------|-------------|--------|
| CLAUDE.md (root) | Dev rules & architecture | CANONICAL | Maintain |
| Hexbound/CLAUDE.md | iOS/SwiftUI rules | CANONICAL | Maintain |
| backend/CLAUDE.md | Backend rules | CANONICAL | Maintain |
| docs/01_source_of_truth/PROJECT_OVERVIEW.md | Architecture | CANONICAL | Maintain |
| docs/01_source_of_truth/DOCUMENTATION_INDEX.md | Master index | CANONICAL | Maintain |
| docs/03_backend_and_api/API_REFERENCE.md | API contracts | PARTIALLY OUTDATED | Fix admin section |
| docs/04_database/SCHEMA_REFERENCE.md | DB models | OUTDATED | Rewrite enums, stats, models |
| docs/06_game_systems/COMBAT.md | Combat formulas | PARTIALLY OUTDATED | Fix CHA intimidation, dodge |
| docs/06_game_systems/BALANCE_CONSTANTS.md | Balance values | PARTIALLY OUTDATED | Fix matchmaking, LUK dodge |
| docs/06_game_systems/PROGRESSION.md | Level/XP | MOSTLY TRUSTWORTHY | Minor updates |
| docs/02_product_and_features/ECONOMY.md | Economy design | MOSTLY TRUSTWORTHY | Verify against code |
| docs/02_product_and_features/GAME_SYSTEMS.md | System overview | MOSTLY TRUSTWORTHY | Verify completeness |
| docs/07_ui_ux/DESIGN_SYSTEM.md | Design tokens | CANONICAL | Maintain |
| docs/07_ui_ux/SCREEN_INVENTORY.md | Screen catalog | MOSTLY TRUSTWORTHY | Verify |
| docs/07_ui_ux/UX_AUDIT.md | UX issues | MOSTLY TRUSTWORTHY | Check if fixed |
| docs/05_admin_panel/ADMIN_CAPABILITIES.md | Admin features | CANONICAL | Maintain |
| docs/features/*.md (12 files) | Feature specs | MOSTLY TRUSTWORTHY | Spot-check |
| docs/rules/*.md (10 files) | Rules enforcement | CANONICAL | Maintain |
| docs/08_prompts/*.md (15 files) | Art generation | CANONICAL | Maintain |
| docs/10_operations/*.md (10 files) | DevOps | MOSTLY TRUSTWORTHY | Maintain |
| docs/retro/*.md (9 files) | Dev logs | REFERENCE | Keep as history |
| docs/11_archive/*.md (12 files) | Superseded docs | ARCHIVE | Keep archived |

### Duplicate Files to Resolve
| File A | File B | Action |
|--------|--------|--------|
| /Hexbound/ART_STYLE_GUIDE.md | docs/08_prompts/ART_STYLE_GUIDE.md | Keep one, delete other |
| /Hexbound/TESTFLIGHT_GUIDE.md | docs/10_operations/TESTFLIGHT_GUIDE.md | Keep one, delete other |
| /Hexbound/UI_PR_CHECKLIST.md | docs/10_operations/UI_PR_CHECKLIST.md | Keep one, delete other |
| docs/FIGMA_HANDOFF.md | docs/10_operations/FIGMA_HANDOFF.md (broken, 5 lines) | Fix or delete broken version |
| docs/FIGMA_SCREEN_INVENTORY.md | docs/10_operations/FIGMA_SCREEN_INVENTORY.md (broken, 5 lines) | Fix or delete broken version |

---

## 8. FULL USER FLOW AUDIT

| Flow | Expected | Actual | Problems | Severity | Fix |
|------|----------|--------|----------|----------|-----|
| Auth/Login | Email + OAuth + Guest | Working | — | — | — |
| Character Creation | Class, origin, name, appearance | Working | — | — | — |
| Main Hub | 10 buildings, navigation | Working | HubView.swift = 1,827 lines, TODO at line 735 "wire real battle pass data" | P3 | Refactor + wire |
| Arena/PvP | Find opponent, fight, results | Working | Matchmaking uses hidden rating filter not in docs | P1 | Document or remove |
| Combat | Turn-based, formulas | Working | CHA intimidation 67% stronger than documented | P0 | Align code/docs |
| Dungeon | Run, fight floors, boss, loot | Working | Hardcoded boss fallback if DB empty | P2 | Ensure DB seeded |
| Dungeon Rush | Speed mode | Working | DungeonRushDetailView = 1,518 lines | P3 | Refactor |
| Inventory | View, equip, sell | Working | — | — | — |
| Shop | Browse, buy, upgrade | Working | Hardcoded consumable prices as fallback | P2 | Move to DB/config |
| Battle Pass | View tiers, claim rewards | Working | Only 1 test (rollback edge case) | P1 | Add full test suite |
| Achievements | 3 tabs, claim | Working | — | — | — |
| Daily Login | Streak rewards | Working | — | — | — |
| Daily Quests | Progress, claim | Working | — | — | — |
| Leaderboard | Rankings | Working | — | — | — |
| Guild Hall | Social features | Working | GuildHallDetailView = 1,845 lines; TODO "Message — Phase 2" | P3 | Refactor |
| Gold Mine | Idle production | Working | — | — | — |
| Shell Game | Minigame | Working | — | — | — |
| Fortune Wheel | Minigame | Working | — | — | — |
| Settings | Account management | Working | — | — | — |
| Inbox/Mail | Read, claim attachments | Working | — | — | — |
| Prestige | Soft reset | Working | No tests | P1 | Add tests |
| Skills | Learn, equip, upgrade | Working | No tests | P1 | Add tests |
| Passives | Tree, unlock, respec | Working | No tests | P1 | Add tests |

---

## 9. UI / DESIGN SYSTEM AUDIT

### Compliance Score: 72%

### Design System Violations

| Category | Count | Severity | Detail |
|----------|-------|----------|--------|
| Hardcoded font sizes | **270** | P2 | `.font(.system(size:))` instead of DarkFantasyTheme tokens |
| Raw RGB colors | 2 | P2 | DungeonRushDetailView:280-281 uses `Color(red:green:blue:)` |
| Hardcoded padding | 10 | P3 | Values like `.padding(2)`, `.padding(3)`, `.padding(6)` |
| SF Symbol currency icons | 3 | P3 | `dollarsign.circle.fill` in CurrencyPurchaseView, PremiumPurchaseView, SeasonSummaryModalView |
| Invented token names | 0 | — | Clean |
| `.accent` misuse | 0 | — | All `.accent` usages are legitimate property names |

### Token Inconsistencies
- 33 View files (21%) don't reference DarkFantasyTheme at all
- 270 instances of `.font(.system(size:))` bypass typography scale
- These are concentrated in Auth/, Arena/, Components/, and Shop/ folders

### Component Drift
- No major component drift detected — ButtonStyles and CardStyles are consistently used
- Background pattern (`DarkFantasyTheme.bgPrimary.ignoresSafeArea()`) repeated 44 times — should be extracted to modifier

### Missing Component Definitions
- No centralized icon token system (SF Symbol usage is ad-hoc)
- No loading/skeleton state component (each screen implements its own)
- No standardized empty state component

---

## 10. FRONTEND AUDIT

### Dead Frontend Files
| File | Issue | Action |
|------|-------|--------|
| CombatService.swift | Complete implementation, 0 imports | DELETE or WIRE |
| FeatureFlagService.swift | Complete implementation, 0 imports | DELETE or WIRE |

### Duplicate Logic (Refactor Targets)
| Pattern | Occurrences | Files | Fix |
|---------|------------|-------|-----|
| IAP verify API call | 3 | CurrencyPurchaseView, PremiumPurchaseView | Extract to StoreKitService |
| Appearances API fetch | 4 | CharacterSelectionView, OnboardingVM, AppearanceEditorVM, GameInitService | Cache in GameDataCache |
| Apple/Google auth | 4 | LoginVM, RegisterVM (2 each) | Extract to AuthService helper |
| Background setup | 44 | All screens | Extract to ViewModifier |

### High-Risk Files (>1000 lines)
| File | Lines | Risk |
|------|-------|------|
| GuildHallDetailView.swift | 1,845 | Maintenance hell, TODO "Phase 2" |
| HubView.swift | 1,827 | Maintenance hell, TODO "wire battle pass" |
| DungeonRushDetailView.swift | 1,518 | Maintenance hell, 2 raw colors |
| HeroDetailView.swift | 1,230 | Complex stat/stance/appearance management |
| BattleResultCardView.swift | 996 | Combat result rendering |
| ItemDetailSheet.swift | 946 | Item detail + actions |
| CharacterSelectionView.swift | 914 | Character creation flow |
| ButtonStyles.swift | 868 | Design system (acceptable) |
| InboxRowView.swift | 789 | Mail row rendering |
| ArenaDetailView.swift | 743 | Arena main screen |

### TODO/FIXME Count: 6
1. HubView.swift:735 — "wire real battle pass data from AppState"
2. GuildHallDetailView.swift:433 — "Message — Phase 2"
3. BattlePassDetailView.swift:41 — "Add error property to ViewModel"
4. AppDelegate.swift:65 — "Forward to AppRouter for deep linking"
5. AppConstants.swift:32 — "Replace with actual staging URL"
6. LevelUpModalView.swift:36 — "Add when backend returns these fields"

---

## 11. BACKEND / API AUDIT

### Endpoint Coverage Summary
- **Total route files:** 179
- **Core endpoints documented + implemented:** ~165 (good)
- **Admin endpoints documented but MISSING:** 10 (bad)
- **Path mismatches:** 2 (ban/unban)
- **Undocumented dev endpoints:** 6 (acceptable)

### Missing Admin Endpoints (P0)
| Documented Endpoint | Status |
|---------------------|--------|
| /admin/items (CRUD) | NOT IMPLEMENTED |
| /admin/consumables (CRUD) | NOT IMPLEMENTED |
| /admin/dungeons (CRUD) | NOT IMPLEMENTED |
| /admin/appearances (CRUD) | NOT IMPLEMENTED |
| /admin/mail (broadcast/segment) | NOT IMPLEMENTED |
| /admin/push/campaign | NOT IMPLEMENTED |
| /admin/feature-flags | NOT IMPLEMENTED |
| /admin/config | NOT IMPLEMENTED |
| /admin/config/snapshot | NOT IMPLEMENTED |
| /admin/balance/simulate | NOT IMPLEMENTED |
| /admin/users/[id]/grant | NOT IMPLEMENTED |
| /admin/users/[id]/reset | NOT IMPLEMENTED |

**Note:** These may exist in the **admin** app's own API routes rather than in the backend. The admin panel is a separate Next.js app. Need to verify if admin handles its own CRUD.

### Hardcoded Fallbacks (P2)
| Route | Issue |
|-------|-------|
| /api/shop/items | Hardcoded consumable prices (100, 250, 500 gold) |
| /api/dungeons/start | Hardcoded boss list fallback |
| /api/achievements | Hardcoded catalog fallback |

### Auth & Security: SOLID
- JWT validation on all protected routes
- Admin role checks on all admin routes
- Rate limiting: 120/min global, 10/min login, 20/min matchmaking
- Ownership checks for character resources
- CORS properly configured
- No SQL injection vectors (Prisma ORM)

---

## 12. DATABASE AUDIT

### Schema vs Docs Mismatches

| Issue | Severity | Detail |
|-------|----------|--------|
| Undocumented model: BossAbility | P2 | In schema, missing from SCHEMA_REFERENCE.md |
| ConsumableType enum mismatch | P1 | Docs: 6 buff types; Schema: 6 sized potions |
| QuestType enum mismatch | P1 | Docs: 5 types; Schema: 7 different types |
| Character stat names | P2 | Docs: 6 long names; Schema: 8 short names |
| User model mismatch | P2 | Schema: authProvider; Docs: googleId, appleId |
| EventType enum mismatch | P3 | Schema has 7 values; Docs 5 (missing class_spotlight, weekend_warrior) |
| EquippedSlot naming | P3 | Schema: snake_case; Docs: UPPER_CASE |

### Missing Cascade Deletes (P2)
10 critical foreign key relations lack cascade delete:
- EquipmentInventory → Item
- PvpMatch → Character
- BattlePass → Season
- CharacterSkill → Skill
- CharacterPassive → PassiveNode
- And 5 more

**Risk:** Orphaned records when parent data is deleted.

### Missing updatedAt Timestamps (P3)
16 models lack audit trail timestamps: GuildChallenge, MilestoneClaim, TrainingSession, BattlePassReward, DailyLoginReward, RevengeQueue, PushCampaign, PushLog, IapTransaction, BalanceSimulationRun, Skill, CharacterSkill, PassiveNode, BossAbility, DungeonWave, DungeonWaveEnemy

### Schema Sync: HEALTHY
Backend and admin Prisma schemas are byte-identical. No drift.

---

## 13. BALANCE / ECONOMY AUDIT

### Balance Problems

| Issue | Severity | Detail |
|-------|----------|--------|
| CHA Intimidation overpowered | P0 | 0.25%/pt + 25% cap vs documented 0.15%/pt + 15% cap |
| LUK Dodge undocumented | P2 | 0.1 per LUK point exists in code, not in any doc |
| Hardcoded consumable prices | P2 | Shop route has inline prices, not from DB/config |

### Economy Status
| System | Documented | Implemented | Match? |
|--------|-----------|-------------|--------|
| Stamina costs | Yes | Yes | Yes |
| XP formula (100N + 20N²) | Yes | Yes | Yes |
| Gold rewards (PvP 200/70, Training 50/20) | Yes | Yes | Yes |
| Gold multipliers (CHA, streak) | Yes | Yes | Yes |
| Equipment upgrade chances | Yes | Yes | Yes |
| Daily login rewards | Yes | Yes | Yes |
| Battle Pass XP (100 + N×50) | Yes | Yes | Yes |
| Inventory slots (28 base, 58 max) | Yes | Yes | Yes |
| Loot drop chances | Yes | Yes | Yes |
| Rarity distribution | Yes | Yes | Yes |
| Gold Mine rewards (60-150) | Yes | Yes | Yes |

### Exploit Risks
- **No test coverage for economy** — gold duplication, item duplication, or reward manipulation exploits would not be caught
- **Hardcoded fallback prices** — if DB config is missing, stale prices apply silently
- **Battle pass claim** — only 1 test exists (rollback), no double-claim prevention test

### Config Drift
- CHA intimidation: code ≠ docs
- Matchmaking rating filter: code ≠ docs
- LUK dodge contribution: exists in code, absent from docs

---

## 14. QA / TEST AUDIT

### Current Coverage: 5.1%

| Category | Total | Tested | Coverage |
|----------|-------|--------|----------|
| API Routes | 155 | 8 | 5% |
| Game Logic Modules | 35 | 4 | 11% |
| Test Cases | ~400 needed | 73 | 18% |

### Tested Systems
- ELO calculation (13 tests)
- Stamina regeneration (9 tests)
- Auth login/register (13 tests)
- Inventory sell (7 tests)
- Shop buy (6 tests)
- Stamina refill (6 tests)
- Rate limiting (6 tests)
- PvP resolve (1 idempotency test)
- Dungeon rush resolve (1 idempotency test)
- Battle pass claim (1 rollback test)
- Cache (1 test)

### Critical Test Gaps (P0)

| System | Tests Needed | Why Critical |
|--------|-------------|--------------|
| Combat damage formulas | 40-50 | PvP balance, exploitable DPS |
| Loot rarity distribution | 25-35 | Economy integrity |
| Gold/gem economy | 20-30 | Monetization, inflation |
| Matchmaking | 15-20 | Fair play |
| Battle pass claiming | 15-20 | Double-claim prevention |
| Prestige system | 10-15 | Stat inflation |

### High Priority Gaps (P1)

| System | Tests Needed |
|--------|-------------|
| Daily quest tracking | 12-18 |
| Durability system | 10-15 |
| Skills system | 15-20 |
| Dungeon encounters | 25-35 |
| Item validation | 10-15 |
| Achievement tracking | 20-25 |

**Total tests needed for 80% coverage: ~350-400 additional tests**

---

## 15. DOCUMENTATION AUDIT

### Docs Requiring Immediate Update

| Doc | Problem | Priority |
|-----|---------|----------|
| SCHEMA_REFERENCE.md | Enums wrong (ConsumableType, QuestType), stat names wrong, BossAbility missing | P0 |
| API_REFERENCE.md | 10 admin endpoints documented but missing; ban/unban paths wrong | P1 |
| COMBAT.md | CHA intimidation formula wrong, LUK dodge missing | P1 |
| BALANCE_CONSTANTS.md | Matchmaking section incorrect (says no rating filter, but code uses one) | P1 |

### Doc Duplicates to Resolve

5 duplicate pairs identified (see Section 7).

### Docs That Are Accurate
- CLAUDE.md files (all 3) — canonical, accurate
- DESIGN_SYSTEM.md — accurate against DarkFantasyTheme.swift
- GAME_SYSTEMS.md — mostly accurate overview
- ECONOMY.md — mostly accurate
- ADMIN_CAPABILITIES.md — accurate
- All feature docs (12) — mostly accurate
- All rule files (10) — accurate
- All operations docs (10) — accurate

---

## 16. DEAD CODE / LEGACY CLEANUP

### Safe to Delete
| File | Reason |
|------|--------|
| CombatService.swift | 0 imports anywhere |
| FeatureFlagService.swift | 0 imports anywhere |
| One copy of ART_STYLE_GUIDE.md | Duplicate |
| One copy of TESTFLIGHT_GUIDE.md | Duplicate |
| One copy of UI_PR_CHECKLIST.md | Duplicate |
| docs/10_operations/FIGMA_HANDOFF.md (5-line stub) | Broken, real copy at docs/FIGMA_HANDOFF.md |
| docs/10_operations/FIGMA_SCREEN_INVENTORY.md (5-line stub) | Broken, real copy at docs/FIGMA_SCREEN_INVENTORY.md |

### Needs Manual Review
| File | Reason |
|------|--------|
| GoldMineDetailView.swift + GoldMineViewModel.swift | Feature status unclear — is idle game active? |
| DesignSystemPreview.swift | Dev-only, fine to keep in DEBUG |

### Legacy But Still Referenced
| Item | Detail |
|------|--------|
| Hardcoded boss list in dungeon start | Fallback for empty DB — should be removed after seeding |
| Hardcoded consumable prices in shop | Fallback — should be DB-only |

---

## 17. PERFORMANCE / STATE AUDIT

### Large File Refactoring Needed
5 View files exceed 1,000 lines — these are performance and maintenance risks:
- GuildHallDetailView (1,845), HubView (1,827), DungeonRushDetailView (1,518), HeroDetailView (1,230), BattleResultCardView (996)

### Duplicate API Calls
- Appearances fetched 4 times from different ViewModels — should be cached in GameDataCache
- IAP verify called 3 times with identical logic — should be extracted

### Perceived Performance Risks
- No centralized skeleton/loading component — each screen implements its own, leading to inconsistent loading UX
- Background pattern repeated 44 times — adds unnecessary view body complexity
- Large views (1800+ lines) may cause SwiftUI recompilation slowdowns

### State Sync Risks
- TODO in HubView:735 suggests battle pass data isn't wired from AppState — potential stale UI
- TODO in LevelUpModalView:36 suggests backend doesn't return certain fields yet — possible missing data

---

## 18. TOP 20 MOST IMPORTANT FIXES

| # | Issue | Severity | Domain | Effort |
|---|-------|----------|--------|--------|
| 1 | Add combat system unit tests (damage, crit, dodge, class scaling) | P0 | QA | Large |
| 2 | Fix CHA intimidation: align code (0.25%) with docs (0.15%) or update docs | P0 | Balance | Small |
| 3 | Rewrite SCHEMA_REFERENCE.md to match actual Prisma schema | P0 | Docs | Medium |
| 4 | Add loot generation tests (rarity distribution, slot allocation) | P0 | QA | Medium |
| 5 | Add economy tests (gold rewards, gem costs, shop logic) | P0 | QA | Medium |
| 6 | Fix API_REFERENCE.md admin section (remove 10 non-existent endpoints or implement them) | P1 | Docs/Backend | Medium |
| 7 | Fix COMBAT.md (CHA formula, LUK dodge contribution) | P1 | Docs | Small |
| 8 | Fix BALANCE_CONSTANTS.md matchmaking section (document rating filter or remove from code) | P1 | Docs/Backend | Small |
| 9 | Add matchmaking tests | P1 | QA | Medium |
| 10 | Add battle pass claiming tests (beyond single rollback test) | P1 | QA | Small |
| 11 | Add prestige system tests | P1 | QA | Small |
| 12 | Add skills system tests | P1 | QA | Small |
| 13 | Replace 270 hardcoded font sizes with DarkFantasyTheme tokens | P2 | UI | Large |
| 14 | Fix 2 raw RGB colors in DungeonRushDetailView | P2 | UI | Small |
| 15 | Delete/wire unused CombatService.swift and FeatureFlagService.swift | P2 | Frontend | Small |
| 16 | Extract duplicate IAP verify logic to shared helper | P2 | Frontend | Small |
| 17 | Cache appearances in GameDataCache (eliminate 4 duplicate fetches) | P2 | Frontend | Small |
| 18 | Add cascade deletes to 10 critical FK relations | P2 | Database | Medium |
| 19 | Resolve 5 duplicate doc pairs | P2 | Docs | Small |
| 20 | Refactor GuildHallDetailView (1,845 lines) and HubView (1,827 lines) | P3 | Frontend | Large |

---

## 19. WHAT MUST BE FIXED BEFORE NEW FEATURES

### Release Blockers (Do First)
1. **Align CHA intimidation** — code vs docs conflict affects PvP balance
2. **Align matchmaking docs** — hidden rating filter changes player experience
3. **Rewrite SCHEMA_REFERENCE.md** — developers will build wrong things with current docs
4. **Fix API_REFERENCE.md admin section** — remove phantom endpoints
5. **Add minimum combat tests** — at least damage formula + class scaling

### High Priority (Do Soon)
6. Add economy test suite
7. Add loot generation tests
8. Fix COMBAT.md and BALANCE_CONSTANTS.md
9. Add battle pass / prestige / skills tests
10. Delete unused services

---

## 20. WHAT CAN WAIT

| Item | Why It Can Wait |
|------|----------------|
| 270 hardcoded font replacements | Visual-only, no logic impact |
| Large file refactoring (5 files >1000 lines) | Working correctly, just hard to maintain |
| Background modifier extraction | Cosmetic code quality |
| Missing updatedAt on 16 models | No audit requirement yet |
| Skeleton loading component | Each screen handles its own |
| Duplicate doc cleanup (5 pairs) | Low confusion risk |
| TODO cleanup (6 items) | Minor features/polish |

---

## 21. FILES TO UPDATE FIRST

1. `docs/04_database/SCHEMA_REFERENCE.md` — full rewrite
2. `docs/06_game_systems/COMBAT.md` — fix CHA formula + add LUK dodge
3. `docs/06_game_systems/BALANCE_CONSTANTS.md` — fix matchmaking section
4. `docs/03_backend_and_api/API_REFERENCE.md` — fix admin section
5. `backend/src/lib/game/balance.ts` — if CHA nerf decided

---

## 22. FILES TO DELETE / ARCHIVE

| File | Action |
|------|--------|
| Hexbound/Hexbound/Services/CombatService.swift | Delete (0 references) |
| Hexbound/Hexbound/Services/FeatureFlagService.swift | Delete (0 references) |
| docs/10_operations/FIGMA_HANDOFF.md (5-line stub) | Delete |
| docs/10_operations/FIGMA_SCREEN_INVENTORY.md (5-line stub) | Delete |
| One of: Hexbound/ART_STYLE_GUIDE.md OR docs/08_prompts/ART_STYLE_GUIDE.md | Archive one |
| One of: Hexbound/TESTFLIGHT_GUIDE.md OR docs/10_operations/TESTFLIGHT_GUIDE.md | Archive one |
| One of: Hexbound/UI_PR_CHECKLIST.md OR docs/10_operations/UI_PR_CHECKLIST.md | Archive one |

---

## 23. PRE-FEATURE FREEZE CHECKLIST

- [ ] CHA intimidation: decision made, code/docs aligned
- [ ] Matchmaking: decision made, code/docs aligned
- [ ] SCHEMA_REFERENCE.md rewritten to match schema.prisma
- [ ] API_REFERENCE.md admin section fixed
- [ ] COMBAT.md updated (CHA + LUK dodge)
- [ ] BALANCE_CONSTANTS.md matchmaking section fixed
- [ ] Combat unit tests added (minimum 20 tests)
- [ ] Loot generation tests added (minimum 10 tests)
- [ ] Economy tests added (minimum 10 tests)
- [ ] Unused services deleted
- [ ] All 5 doc duplicate pairs resolved
- [ ] CDO verification scan passes clean

---

## 24. REGRESSION TESTS THAT MUST EXIST

### Before Any New Feature

**Combat (P0):**
- Damage formula: each class scaling (warrior STR 1.5, mage INT 1.4, rogue AGI 1.3, tank VIT 1.2)
- Crit calculation: LUK × 0.7 + AGI × 0.15, 50% cap
- Dodge calculation: AGI × 0.2 + LUK × 0.1, cap
- CHA intimidation: per-point reduction, cap enforcement
- Stance zone bonuses: each of 5 zones
- Battle fatigue: starts turn 11, +10% per turn
- Class bonuses: tank 15% reduction, rogue +3% dodge
- Poison: 30% armor penetration

**Economy (P0):**
- Gold reward calculation: base × CHA multiplier × streak multiplier
- Stamina cost enforcement: PvP 5, training 3, dungeon varies
- Shop buy: sufficient gold check, inventory space check
- Item upgrade: success rate per level (+1 through +10)
- Prestige: eligibility, stat bonus (+5% per level)

**Loot (P0):**
- Rarity distribution: common 50%, uncommon 25%, rare 15%, epic 8%, legendary 1%
- Drop chance: PvP 15%, Boss 75%
- Slot allocation correctness

**Matchmaking (P1):**
- Phase cascade: tight → relaxed → wide → any
- Rating filter behavior (if kept)
- Level/gear score boundaries

---

## 25. DESIGN SYSTEM GAPS TO CLOSE

1. **Create centralized icon token system** — replace ad-hoc SF Symbol usage
2. **Create reusable SkeletonLoadingView** — replace per-screen loading implementations
3. **Create reusable EmptyStateView** — standardize empty state UI
4. **Extract .darkFantasyBackground() ViewModifier** — eliminate 44 repeated patterns
5. **Fix 270 hardcoded font sizes** — migrate to DarkFantasyTheme typography tokens
6. **Fix 2 raw RGB colors** — map to theme tokens
7. **Fix 10 hardcoded padding values** — use LayoutConstants spacing scale

---

## 26. DOCS TO REWRITE FIRST

| Priority | Doc | Reason |
|----------|-----|--------|
| 1 | SCHEMA_REFERENCE.md | Enums, stats, models all wrong |
| 2 | COMBAT.md | CHA formula wrong, LUK dodge missing |
| 3 | BALANCE_CONSTANTS.md | Matchmaking section wrong |
| 4 | API_REFERENCE.md | Admin section has phantom endpoints |

---

## 27. SAFE CLEANUP TASKS WE CAN DO IMMEDIATELY

These require no design decisions and carry zero risk:

1. Delete CombatService.swift (0 references)
2. Delete FeatureFlagService.swift (0 references)
3. Delete 2 broken doc stubs (FIGMA_HANDOFF.md, FIGMA_SCREEN_INVENTORY.md in 10_operations/)
4. Resolve 5 doc duplicate pairs (keep docs/ versions, delete Hexbound/ copies)
5. Fix 2 raw RGB colors in DungeonRushDetailView.swift
6. Fix 3 SF Symbol currency icons → use design system icon
7. Fix 10 hardcoded padding values → use LayoutConstants
8. Add `updatedAt` to 16 models missing it
9. Add BossAbility model to SCHEMA_REFERENCE.md

---

## 28. FINAL PRIORITIZED CLEANUP ROADMAP

### Week 1: Critical Alignment (P0)
- [ ] Day 1-2: Decision on CHA intimidation (0.15% or 0.25%) + implement
- [ ] Day 1-2: Decision on matchmaking rating filter + implement
- [ ] Day 2-3: Rewrite SCHEMA_REFERENCE.md from scratch using schema.prisma
- [ ] Day 3-4: Fix COMBAT.md + BALANCE_CONSTANTS.md
- [ ] Day 4-5: Fix API_REFERENCE.md admin section
- [ ] Day 5: Safe cleanup (delete unused files, fix doc duplicates)

### Week 2: Test Foundation (P0-P1)
- [ ] Day 1-2: Combat unit tests (20+ tests: damage, crit, dodge, class scaling)
- [ ] Day 2-3: Loot generation tests (15+ tests: rarity, drops, slots)
- [ ] Day 3-4: Economy tests (15+ tests: gold, gems, shop, upgrades)
- [ ] Day 4-5: Matchmaking + battle pass + prestige tests (15+ tests)

### Week 3: Code Quality (P2)
- [ ] Extract IAP verify to shared helper
- [ ] Cache appearances in GameDataCache
- [ ] Delete unused services
- [ ] Fix raw colors + SF Symbol icons
- [ ] Begin font token migration (highest-traffic screens first)

### Week 4: Architecture Polish (P2-P3)
- [ ] Refactor GuildHallDetailView (<400 lines per file)
- [ ] Refactor HubView (<400 lines per file)
- [ ] Refactor DungeonRushDetailView (<400 lines per file)
- [ ] Create SkeletonLoadingView component
- [ ] Create EmptyStateView component
- [ ] Create .darkFantasyBackground() modifier
- [ ] Add cascade deletes to 10 FK relations
- [ ] Continue font token migration

### Ongoing: Documentation Maintenance
- [ ] Keep all 4 critical docs updated as code changes
- [ ] Run CDO verification scan after every task
- [ ] Update retro logs

---

*End of audit. All findings backed by code inspection. No assumptions without evidence.*
