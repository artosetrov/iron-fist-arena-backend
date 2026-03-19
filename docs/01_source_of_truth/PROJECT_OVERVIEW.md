# Hexbound — Project Overview (Source of Truth)

*Last verified against codebase: 2026-03-19*

---

## Project Description

Hexbound is a **PvP-focused dark fantasy RPG** for iOS with a full backend admin platform. Players engage in ranked PvP combat, tackle procedural dungeons, manage character progression, and participate in seasonal battle passes. The game emphasizes skill-based combat, economic balance, and fairness.

---

## Technology Stack

### Backend
- **Framework**: Next.js 15.2.0 / TypeScript 5.7.0
- **Database**: PostgreSQL via Supabase
- **ORM**: Prisma 6.4.0
- **Caching**: Upstash Redis 1.37.0 with in-memory fallback
- **Rate Limiting**: Upstash Rate Limit 2.0.8
- **Testing**: Vitest 3.2.4
- **Auth**: Supabase Auth (JWT) with OAuth + password + guest modes
- **Hosting**: Vercel

### Admin Panel
- **Framework**: Next.js 15.2.0 / TypeScript 5.7.0
- **UI Kit**: Tailwind CSS 4.0.0 + Radix UI (tabs, dialogs, selects, switches, toasts, menus, etc.)
- **Forms**: React Hook Form 7.54.0 + Zod 3.24.0
- **Charts**: Recharts 2.15.0
- **Icons**: Lucide React 0.469.0
- **Hosting**: Vercel

### Mobile Client
- **Language**: Swift / SwiftUI
- **Minimum iOS**: iOS 16.4+
- **Runtime**: 38+ screens (24 primary + 14 overlays/sheets), feature-complete for core gameplay loop
- **Asset Pipeline**: Images hosted via Supabase Storage
- **Hosting**: App Store

### Database
- **Provider**: PostgreSQL (Supabase)
- **Models**: 40+ Prisma models (see Entity Reference below)
- **Migrations**: Version-controlled via `/backend/prisma/migrations/`

---

## Core Game Systems (Implemented)

### PvP Combat
- Server-authoritative Elo-based matchmaking (starting rating: 1000)
- Seeded RNG for client-side verification
- Combat log storage for replay/analysis
- Ranking calibration phase, win streaks, seasonal seasons
- First-win-of-day bonus
- Revenge match system (72-hour expiration)

### Dungeons
- 4 difficulty levels: Easy, Normal, Hard, Nightmare, plus Rush mode
- 4 types: Story, Side, Event, Endgame
- Procedurally-seeded floor progression
- Boss encounters with abilities and loot drops
- Dungeon progress tracking per character

### Skills & Abilities
- 5 ranks per skill, class-restricted learn options
- Damage types: Physical, Magical, True Damage, Poison
- Target types: Single Enemy, Self Buff, AOE
- Cooldown management, mana cost (framework ready)
- 80+ skills defined in database

### Passive Skill Tree
- 150+ passive nodes with tier progression
- Passive connection graph (unlock dependencies)
- Bonus types: flat/percent stat, flat/percent damage, crit, dodge, lifesteal, cooldown reduction, etc.
- Character-specific unlocks tracked in CharacterPassive

### Equipment & Inventory
- 11 equippable slots (weapon, offhand, helm, chest, gloves, legs, boots, accessory, amulet, belt, relic, necklace, ring×2)
- 7 item types: Weapon, Armor (5 slots), Accessory/Amulet/Belt/Relic/Necklace/Ring
- 5 rarity tiers: Common, Uncommon, Rare, Epic, Legendary
- Durability system, upgrade levels (6+)
- Rolled stats on drops, set bonuses planned
- 28 inventory slots (upgradeable to 40+)

### Economy (Currencies)
- **Gold** — soft currency, primary reward from PvP/dungeons, used for shop/upgrades
- **Gems** — premium currency, earned via achievements/IAP, used for cosmetics/accelerants
- **Arena Tokens** — planned, minimal implementation

### Gold Mine
- 1-6 active slots, stagger mining for 15min–8hrs
- Passive gold generation
- Per-slot: gold reward + optional gem bonus (booster)
- Collect before expiry to claim

### Minigames
- **Shell Game** — prediction-based, anti-cheat backend validation
- Bet amounts, secret data validation via seeded RNG
- Expandable system for future minigames

### Daily Systems
- **Daily Quests** (7 types): PvP wins, dungeon completions, gold spent, item upgrades, consumable use, shell game plays, gold mine collects
- **Daily Login Rewards** — 30-day cycle with streak tracking
- **Training Ground** — unlimited free practice PvE combat (1 stamina)

### Battle Pass
- **Free & Premium tiers** per season
- Per-tier rewards: Gold, Gems, Cosmetics, items, battle-pass XP
- Season-based progression (5-50 levels typical)
- Seasonal themes, live config

### Cosmetics & Appearance
- **Skins**: Per origin + gender, cosmetic frame/title/effect overlays
- **Purchase**: Gold or Gems at configurable prices
- **Apply**: Character-specific selection

### Achievements
- 40+ achievement definitions with unlock criteria
- Progress tracking per character
- Reward claims: Gold, Gems, Cosmetics
- Admin-definable (via AchievementDefinition model)

### Leaderboard
- Global PvP rankings by rating (top 100+)
- Seasonal leaderboards (Season-based)
- Win/loss/streak stats per character

### Mail/Inbox System
- Broadcast, segment, or character-targeted messages
- Attachments: Gold, Gems, XP, items
- Expiration, read/claimed status tracking
- Admin-composable via MailMessage model

### Live Configuration
- 80+ game config keys (GameConfig model)
- No redeployment needed for balance changes
- Admin console support for real-time updates
- Categories: Combat, Economy, Progression, UI/UX, Events

### Feature Flags
- Boolean, percentage, segment-based toggles
- Environment-scoped (production, staging, dev)
- A/B testing infrastructure
- Admin CRUD via FeatureFlag model

### Prestige System
- Character reset with bonus stats carry-over
- Prestige levels tracked independently
- Framework in place for milestone rewards

### Push Notifications
- Broadcast/segment/user-targeted campaigns
- Delivery logging (sent, delivered, failed)
- Data payloads for deep linking
- Per-user opt-in via PushToken

### In-App Purchases (IAP)
- Receipt validation via Supabase Auth
- Gem purchases with configurable tiers
- Transaction tracking + verification logs
- Daily Gem Card (30-day subscription)

---

## Character Creation & Progression

### Classes
- Warrior, Rogue, Mage, Tank

### Origins
- Human, Orc, Skeleton, Demon, Dogfolk

### Base Stats (8 attributes, default 10 each)
- Strength, Agility, Vitality, Endurance, Intelligence, Wisdom, Luck, Charisma
- Allocate via stat points unlocked per level
- Scale weapon damage, survivability, and crit chance

### Level Progression
- Max level: 120 (configurable)
- Level up via quest/training/dungeon XP
- Stat points + passive points awarded per level
- Gear score calculation (sum of equipped item levels)

### Stamina System
- Max 120 (upgradeable), regenerates 1/min
- PvP matches cost 20 stamina
- Trainings cost 5 stamina
- Potions restore (small 10, medium 30, large 50)

### Experience & Rewards
- PvP: 50–150 XP + 10–100 gold (Elo-scaled)
- Dungeons: 100–500 XP + 50–500 gold (difficulty-scaled)
- Training: 25–50 XP (opponent-scaled)

---

## Database Schema (40+ Models)

### User & Character
- `User` — Accounts, auth provider, premium status, gems, role (player/admin)
- `Character` — Class, origin, stats, level, prestige, gear, PvP rating

### Inventory & Equipment
- `EquipmentInventory` — Equipped/unequipped items, upgrade level, durability, rolled stats
- `ConsumableInventory` — Potions (6 types), quantities

### PvP Systems
- `PvpMatch` — Full combat log, ratings before/after, gold/XP rewards
- `RevengeQueue` — Revenge match requests (72-hour expiry)
- `PvpBattleTicket` — Pre-generated matchup seed, opponent, expiry

### Progression & Skills
- `Skill` — 80+ skills: damage base, scaling, cooldown, unlock level, max rank
- `CharacterSkill` — Character skill proficiency, equipped slot
- `PassiveNode` — 150+ passive nodes: position, cost, bonus type, tier
- `PassiveConnection` — Directed graph edges between passives
- `CharacterPassive` — Unlocked passive nodes per character

### Dungeons
- `Dungeon` — Config: difficulty, loot, level req, image/lore
- `DungeonBoss` — Boss stats (HP, damage, defense, speed, crit)
- `BossAbility` — Ability config per boss
- `DungeonRun` — Active run state, seed, difficulty, floor
- `DungeonProgress` — Completion tracking per character
- `DungeonDrop` — Item drop rates and pools

### Daily Systems & Rewards
- `DailyQuest` — Progress, target, rewards, daily reset
- `DailyLoginReward` — Day counter, streak, claim dates
- `TrainingSession` — PvE session logs
- `GoldMineSession` — Mining logs with collection status
- `MinigameSession` — Minigame bet/result tracking

### Battle Pass & Cosmetics
- `Season` — Season meta: theme, start/end dates
- `BattlePass` — Per-character, per-season premium/free status
- `BattlePassReward` — Tier configs, reward type/amount
- `BattlePassClaim` — Claimed rewards per character
- `Cosmetic` — Character cosmetic ownership
- `AppearanceSkin` — Skin definitions per origin+gender

### Economy & Monetization
- `IapTransaction` — IAP receipt, gems awarded, verification status
- `DailyGemCard` — 30-day subscription status
- `ShopOffer` — Rotating shop items (config-driven)
- `ShopOfferPurchase` — Purchase history

### Admin & Configuration
- `GameConfig` — Live config key-values (80+ keys)
- `FeatureFlag` — A/B test toggles, segments
- `AdminLog` — Audit trail for admin actions
- `ConfigSnapshot` — Config backup/restore
- `DesignToken` — Dynamic theme tokens

### Content & Meta
- `Item` — 200+ item definitions (base stats, special effects, class restrictions)
- `Achievement` — 40+ achievement definitions
- `AchievementDefinition` — Template definitions
- `QuestDefinition` — Quest type templates
- `Event` — Seasonal events, tournaments, rushes
- `LegendaryShard` — Legendary crafting currency

### Communication
- `MailMessage` — Messages (broadcast/segment/targeted)
- `MailRecipient` — Read/claimed status per character
- `PushToken` — Device push tokens (FCM/APNS)
- `PushCampaign` — Campaign metadata
- `PushLog` — Delivery logs

### Balance & Analytics
- `ItemBalanceProfile` — Per-item-type stat weight configs
- `BalanceSimulationRun` — Simulation results (impact analysis)

---

## iOS App (38+ Screens)

> Full screen inventory: `docs/07_ui_ux/SCREEN_INVENTORY.md`

### Authentication & Onboarding (6 screens)
- Welcome (login/register/guest entry)
- Login (Email/Password, Google OAuth, Apple OAuth)
- Register (account creation)
- Character Creation (multi-step: Name → Class → Appearance)
- Email Confirmation
- Upgrade Guest (guest → full account)

### Main Hub (8 screens)
- Hub (stamina bar, character card, city map, floating action buttons)
- Character Detail (stats, equipment, appearance, stat allocation/respec)
- Hero Detail (character profile)
- City Map (interactive hub with buildings, effects)
- City Building views + Hub Editor
- Stance Selector (attack/defense zone)

### Arena / PvP (5 screens)
- Arena (opponents, revenge, history tabs + carousel)
- Arena Comparison Sheet
- Opponent cards (OpponentCardView, ArenaOpponentCard)

### Combat (4 screens + VFX system)
- Combat (intro → active → victory/defeat, turn-based with combat log)
- Combat Result (rating change, rewards, loot)
- Loot Detail
- VFX system: CombatVFXOverlay, DamageHitEffects, DodgeMissBlock, HealEffect, StatusVFXEffects

### Dungeons (5 screens)
- Dungeon Select (difficulty/type)
- Dungeon Info Sheet (lore, rewards)
- Dungeon Room (floor-by-floor progression)
- Dungeon Victory (loot display)
- Loot Preview Sheet

### Minigames (4 screens)
- Gold Mine (slots, mining timer, collect)
- Shell Game (bet, play, result)
- Dungeon Rush (wave-based boss rush + shop between floors)
- Tavern (activity hub)

### Inventory (2 screens)
- Inventory (equipment/consumables tabs, search, 4-col grid)
- Item Detail Sheet (stats, equip/sell)

### Shop (4 screens)
- Shop (equipment/consumables/premium tabs)
- Shop Offer Banner (limited-time deals)
- Currency Purchase (IAP for gold/gems)
- Premium Purchase (cosmetics)

### Quests & Progression (6 screens)
- Daily Quests (list + completion)
- Daily Login (calendar + popup auto-show)
- Achievements (list + achievement cards)
- Battle Pass (free/premium tracks + reward nodes)

### Leaderboard & Social (2 screens)
- Leaderboard (rating/level/gold tabs)
- Inbox (messages + attachments)

### Profile & Settings (3 screens)
- Settings (audio, language, account)
- Appearance Editor (skin/avatar customization)
- Profile (character stats overlay)

### Dev Tools (2 screens)
- Screen Catalog (navigate all screens)
- Design System Preview (color + component showcase)

---

## Admin Panel (38 Pages)

### Dashboard
- KPI snapshot (DAU, revenue, active sessions)
- Recent admin logs
- Feature flag status

### Character Management
- Search/filter characters by name, level, class, rating
- View detailed stats, inventory, skills, passives
- Manual reward grants (gold/gems/items)
- Ban/unban users
- Prestige reset trigger
- Reset stats respecs

### Item Management
- CRUD all 200+ items
- Edit stats, rarity, class restrictions, drop rates
- Bulk upload via CSV
- Image management (Supabase Storage)

### Skills & Passives
- CRUD skill database (80+ skills)
- Test damage calculations
- CRUD passive nodes (150+ nodes)
- Visual tree editor (planned)

### Dungeon & Boss Configuration
- CRUD dungeons (difficulty, loot pools, image)
- CRUD bosses per dungeon
- CRUD boss abilities
- Test encounter difficulty

### Economy & Monetization
- Gem pricing tiers (manage IAP products)
- Gold balance adjustments (bulk grants)
- Shop offer rotation (create/schedule)
- Revenue charts (Recharts integration)
- Daily Gem Card config

### Achievements
- CRUD achievement definitions (40+)
- Set targets, rewards, icons
- View progress per character
- Trigger early unlock (testing)

### Battle Pass
- Create/configure seasons
- Define tier rewards (free + premium)
- Upload season artwork
- Season schedule (start/end dates)

### Push Notifications
- Compose campaigns (broadcast/segment)
- Schedule deployment
- View delivery logs
- A/B test variants

### Feature Flags
- Boolean, percentage, segment toggles
- A/B testing configuration
- Environment scoping
- View active flags per environment

### Live Configuration
- Key-value pair editor (80+ config keys)
- Syntax validation for JSON values
- Audit trail (who changed what, when)
- Instant apply (no redeployment)
- Config snapshots (export/restore)

### Analytics & Reporting
- PvP match analytics (win rates by class, rating)
- Economy tracking (gold sink/faucet)
- Player retention cohorts
- Session length distribution

### Admin Logs & Audit
- Searchable activity log (all admin actions)
- Timestamp, admin ID, action, target, details
- Export audit trail (CSV)

### Balance Simulation
- Run economy simulations
- Item balance impact analysis
- Combat formula testing sandbox
- Save/compare simulation results

### Content Management
- Event creation (tournaments, rushes, gold rushes)
- Mail message composition (broadcast/segment)
- Cosmetic/skin upload and configuration
- Seasonal content scheduling

---

## Key Architecture Decisions

### 1. Server-Authoritative Combat
- Client calculates preview only; server validates and executes
- Seeded RNG (seed stored in PvpBattleTicket) enables client verification
- Anti-cheat: no client-side modification of results

### 2. Cache-First Pattern
- Upstash Redis for hot data (leaderboards, config, user cache)
- In-memory fallback if Redis unavailable
- TTL-based expiry (typically 5–60 min per key)
- GameDataCache environment object in iOS

### 3. Transaction-Based Rewards
- Atomic transactions for multi-step rewards (gold + gems + items)
- Prevent duplicate claims, race conditions
- Log every transaction (audit trail)

### 4. Live Configuration
- GameConfig model holds all balance values (no code redeployment)
- Admin console updates instantly apply to next API call
- Feature flags allow gradual rollouts or A/B testing

### 5. Asynchronous Processing
- Rate limiting (Upstash) prevents abuse
- Mail/push notifications queued (async send)
- Leaderboard recalculation via background jobs (planned)

### 6. Role-Based Access Control (RBAC)
- User.role field (player/admin/moderator planned)
- Admin endpoints protected via middleware
- AdminLog tracks all privileged actions

---

## Deployment & Operations

### Backend & Admin
- Hosted on Vercel (automatic previews for PRs)
- Environment variables: DATABASE_URL, DIRECT_URL (pooled vs. direct), UPSTASH_REDIS_REST_URL, SUPABASE_URL, SUPABASE_ANON_KEY
- Build process: `prisma generate && next build`
- Migrations: `prisma migrate deploy` (production), `prisma migrate dev` (local)

### iOS App
- Xcode project at `/Hexbound/Hexbound.xcodeproj`
- Fastlane for TestFlight & App Store deployments
- Asset hosting via Supabase Storage
- App Store Connect for releases

### Database
- PostgreSQL via Supabase (managed)
- Automated backups
- Direct connection pooling (Supabase Connection Pooler)

---

## Roadmap & Future Work

### Planned (High Priority)
- Leaderboard background job optimization
- In-game tournament/event system UI
- Legendary item crafting system (via LegendaryShard)
- Advanced analytics dashboard
- Content moderation tools

### Planned (Medium Priority)
- Guild system (multi-player teams)
- Seasonal cosmetics tie-ins
- Advanced skill combos/synergy
- Trading/marketplace system
- PvE raid encounters (5+ player)

### Planned (Low Priority)
- Mobile web version
- Cross-platform progression (cloud save)
- Spectator mode (watch live matches)
- In-game streaming integration
- Voice chat via Agora/Twilio

---

## File Structure

```
PVP RPG/
├── backend/                          (Next.js 15 API + business logic)
│   ├── app/api/                      (API routes)
│   ├── lib/                          (Utilities, cache, auth, validators)
│   ├── prisma/
│   │   ├── schema.prisma             (40+ models)
│   │   └── migrations/               (Version-controlled migrations)
│   ├── package.json                  (Next.js 15, Prisma 6.4, Upstash)
│   └── README.md
│
├── admin/                            (Next.js 15 admin panel)
│   ├── src/app/                      (38 pages via App Router)
│   ├── src/components/               (Radix UI + Tailwind)
│   ├── src/lib/                      (Forms, API clients, validators)
│   ├── package.json                  (Next.js 15, Tailwind 4, Radix UI, Recharts)
│   └── README.md
│
├── Hexbound/                         (iOS Swift/SwiftUI app)
│   ├── Hexbound/
│   │   ├── Views/                    (20+ screens)
│   │   ├── Theme/                    (DarkFantasyTheme.swift, ButtonStyles.swift, LayoutConstants.swift)
│   │   ├── Models/                   (25 Codable structs + 8 enums: Character, CombatData,
│   │   │                              Item, ShopItem, ShopOffer, Opponent, MatchHistory,
│   │   │                              RevengeEntry, LeaderboardEntry, Quest, Achievement,
│   │   │                              BattlePassData, DailyLoginData, DungeonInfo, MailMessage,
│   │   │                              AppearanceSkin + enums: CharacterClass, Avatar, Gender,
│   │   │                              Origin, Difficulty, ItemRarity, ItemType, PvPRank)
│   │   ├── Services/                 (21 services: Auth, Character, Combat, CombatEngine,
│   │   │                              PvP, Dungeon, Inventory, Shop, Quest, Achievement,
│   │   │                              BattlePass, DailyLogin, Leaderboard, GoldMine,
│   │   │                              StoreKit/IAP, PushNotification, FeatureFlag,
│   │   │                              GameDataCache, GameInit, GoogleSignIn, BattlePreloader)
│   │   ├── Network/                  (APIClient, APIEndpoints, APIError, NetworkMonitor, SupabaseAuthClient)
│   │   ├── Persistence/              (Local persistence layer)
│   │   ├── Tutorial/                 (First-time user tutorial flow)
│   │   ├── Localization/             (Multi-language support)
│   │   └── App/                      (AppRouter, AppState, entry point)
│   ├── Hexbound.xcodeproj/           (Xcode project config)
│   ├── ART_STYLE_GUIDE.md            (AI art generation reference)
│   ├── TESTFLIGHT_GUIDE.md           (iOS build & deployment)
│   └── CLAUDE.md                     (Development rules: Xcode, design system, Swift concurrency)
│
├── docs/                             (Master documentation)
│   ├── 01_source_of_truth/           (Project overview, index)
│   ├── 02_product_and_features/      (Game systems, economy)
│   ├── 03_backend_and_api/           (API reference, business logic)
│   ├── 04_database/                  (Schema, migrations)
│   ├── 05_admin_panel/               (Capabilities, config reference)
│   ├── 06_game_systems/              (Combat, balance, progression)
│   ├── 07_ui_ux/                     (Design system, screens, audit)
│   ├── 08_prompts/                   (Art style, asset prompts)
│   ├── 09_rules_and_guidelines/      (Dev rules, UI/UX principles)
│   └── 10_operations/                (TestFlight, PR checklist, Figma handoff)
│
└── README.md                         (Quick start)
```

---

## Contact & Ownership

- **Project Lead**: [TBD]
- **Backend Owner**: [TBD]
- **Admin Panel Owner**: [TBD]
- **iOS Owner**: [TBD]

---

## License

Proprietary — Hexbound © 2026. All rights reserved.
