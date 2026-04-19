# Admin Panel Capabilities (Source of Truth)
*Derived from admin panel code. Updated: 2026-04-16*

This is a high-level capability map of the Next.js admin dashboard, organized by area of responsibility. Treat `wiki/` plus the audited route/action files as the live source of truth for current behavior and access control.

Admin-facing routes and actions are expected to run behind authenticated admin access, but permission boundaries are enforced in code per route and per action. This document should not be read as a formal security matrix.

---

## 1. Overview & Dashboard

### Dashboard (Home)
**Purpose:** KPI overview and live alerts
**Key Metrics:**
- Daily Active Users (DAU) — 24-hour player count
- New Users — Registrations last 24h
- Total Users — All-time accounts
- Active PvP Matches — Current fights
- Gold Circulation — Avg gold per player
- Gem Circulation — Avg gems per player
- Top 10 Leaderboard — Displayed inline

**Auto-Alerts:**
- Retention drop > 20% from 7-day average
- Win rate imbalance (class > 55% or < 45%)
- Economy inflation (gems issued > hard cap)
- Dungeon too hard (completion rate < 10%)
- Performance degradation (API latency > 2s)

**Real-time Graphs:**
- DAU 7-day trend
- PvP match volume
- Top classes by picks
- Economy health (gold/gem sink vs. faucet)

---

### Players (Search & Management)
**Purpose:** Find, view, and manage individual players
**Features:**
- Search by username or email
- View player list with gems, role, status, character count, and joined date
- Open the dedicated player detail page from the list
- Actions:
  - Ban user (reason field)
  - Unban user
  - From player detail: grant gold to the selected character
  - From player detail: grant gems to the account
  - From player detail: reset inventory for the selected character
  - From player detail: inspect characters, equipment, match history, and purchase history

**Pagination:** 20 players per page

---

### Arena (PvP Match Browser)
**Purpose:** Live monitor and inspect PvP matches
**Features:**
- Real-time match list (last 100)
- Filter by: class, rating range, duration, result
- Click to expand: full battle log, champion builds, moves executed
- Detect anomalies: impossible win (rating delta > 500), duplicate IP, instant win (<5s)
- Action: Invalidate match (refund both players if fraud detected)

---

## 2. Content Management

### Items (CRUD)
**Purpose:** Create, update, delete equipment
**Create Form:**
- catalogId (unique)
- itemName
- itemType (dropdown: weapon, helmet, chest, etc.)
- rarity (dropdown: common–legendary)
- Base stats (strength, dex, int, con, wis, cha)
- Level requirement
- Price (gold + optional gem)
- Sell value
- Restrictions (class whitelist)
- Rollable stats (which can roll higher)
- Description
- Image upload / image URL / image key
- Upgrade config (max level, scaling type, per-level stat growth)

**Edit:**
- Change all above fields
- Preview item in the live card-style modal

**Delete:**
- Direct delete from the admin item route

**Current repo note:** the live item editor does **not** currently expose CSV import/export, duplicate-item workflow, change-history tracking, in-circulation warnings, or 3D preview.

---

### Consumables (CRUD)
**Purpose:** Manage potions, buffs, scrolls
**Fields:**
- catalogId
- consumableName
- consumableType (health potion, stamina restore, buff attack 1h, etc.)
- Effect (JSON: {stat: "strength", duration: 3600, value: 10})
- Shop price (gold or gems)
- Stack limit
- Icon/sprite reference

---

### Skills (CRUD)
**Purpose:** Design character abilities
**Fields:**
- catalogId
- skillName
- skillClass (class-specific)
- Description
- cooldown (seconds)
- manaCost
- Scaling (JSON: {strength: 1.2, dex: 0.8})
- Unlock level
- Icon reference

**Special Actions:**
- Testable in combat simulator (AI vs. skill)
- Rank progression (how costs change 1→5)

---

### Passives (CRUD + Tree Editor)
**Purpose:** Manage passive tree nodes and connections
**Visual Editor:**
- Drag nodes in 2D space
- Draw connections between nodes
- Preview final tree layout
- Simulate pathing (highlight routes)

**Node Fields:**
- catalogId, nodeName
- Stats granted (JSON)
- Point cost to unlock
- Class restriction (optional)
- Position (X, Y)

**Connections:**
- Drag to connect nodes
- Validate pathing (no loops)
- Save tree layout

---

### Dungeons (Visual Builder)
**Purpose:** Create multi-floor dungeon runs
**Dungeon Setup:**
- dungeonName, minimum level, difficulty
- Floors (how many levels)
- Boss health per floor
- Loot table (drops by rarity)

**Floor Builder (per floor):**
- Enemy wave count
- Enemy type (dropdown: goblin, orc, skeleton, etc.)
- Boss type (dropdown: dragon, lich, etc.)
- Reward preview

**Difficulty Tuning:**
- Estimated completion rate (%)
- Recommended stats
- Est. time to clear
- Save as template

---

### Appearances/Cosmetics (CRUD)
**Purpose:** Manage character appearance skins
**Fields:**
- skinKey
- skinName
- origin
- gender
- Rarity
- Gold price
- Gem price
- imageUrl / imageKey
- default skin toggle
- sort order

**Current repo note:** the live screen manages 2D appearance-skin cards with upload/edit/delete flows. It does **not** currently expose a 3D model preview or a broader cosmetics catalog for effects, emotes, or titles.

---

### Assets (Upload & Manage)
**Purpose:** Image, animation, and icon library
**Features:**
- Upload PNG/SVG/MP4/WebP
- Auto-generate sprites (if multi-frame)
- Tag/search library
- Usage tracking (how many items use this asset)
- Delete only if unused

---

## 3. Gameplay Systems

### Quests (CRUD)
**Purpose:** Daily and seasonal quest templates
**Create Quest:**
- catalogId
- questName
- questType (PVP_WINS, DUNGEON_CLEARS, SKILL_USES, LEVEL_UP, EQUIP_ITEMS)
- Description
- Target value (e.g., "Win 3 PvP matches")
- Gold reward
- Gem reward (optional)
- Display order
- Active date range

**Edit:**
- Adjust rewards if needed
- Reorder quests
- Disable without deleting

---

### Achievements (CRUD)
**Purpose:** Long-term unlock goals
**Fields:**
- catalogId
- achievementName
- Description
- Reward (gold/gems/cosmetic)
- Unlock condition (complex JSON: {type: "pvp_wins", value: 100})

**Batch Create:**
- Template set (e.g., "Dungeon Master" — clear all dungeons, 5-tier progression)

---

### Events (CRUD)
**Purpose:** Time-limited gameplay events
**Create Event:**
- eventName
- Description
- Start date / end date
- Type (BONUS_REWARDS, SPECIAL_DUNGEON, PVP_TOURNAMENT)
- Bonus config (e.g., +50% gold during event)
- Associated dungeon/quest/achievement
- Broadcast message

**Manage:**
- Schedule new event
- End event early
- Extend deadline
- View player participation

---

### Seasons (CRUD + Battle Pass)
**Purpose:** Battle Pass and seasonal progression
**Create Season:**
- catalogId (e.g., "s1_dawn")
- seasonName, description
- Start date / end date
- seasonNumber (S1, S2, etc.)

**Battle Pass Configuration:**
- Levels (1-100)
- Free track rewards per level
- Premium track rewards per level
- XP to level up
- Free pass gem cost (if purchasable)

**Manage:**
- View all battle pass progress
- Adjust rewards mid-season
- Grant pass to specific player
- Track pass sales

---

## 4. Economy Management

### Economy Overview
**Purpose:** Monitor health and inflation
**Metrics:**
- Total gold in circulation
- Total gems issued (free + purchased)
- Avg gold per player
- Avg gems per player
- Top 10 gold holders
- Top 10 gem holders
- Gini coefficient (wealth inequality: 0–1)
- Daily gold faucet (quests, dungeons, pvp, etc.)
- Daily gold sink (shop, upgrades, repairs, respec)
- Net flow (faucet – sink)

**Charts:**
- 30-day gold circulation
- 30-day gem circulation
- Gold faucet vs. sink (stacked area)
- Economy health indicator (red/yellow/green)

**Alerts:**
- Net negative flow (more sinks than sources)
- Gem cap exceeded (hard limit)
- Top holder has > 50% of all gold (exploit?)

---

### Loot Tables (Edit Drop Rates)
**Purpose:** Control reward distribution
**Loot Table Editor:**
- Adjust drop chance by source:
  - PvP
  - Training
  - Dungeon (easy / normal / hard)
  - Boss fights
- Adjust rarity distribution weights:
  - common
  - uncommon
  - rare
  - epic
  - legendary
- Validate that rarity totals still sum to 100%

**Rarity Distribution:**
- Common: X%
- Uncommon: X%
- Rare: X%
- Epic: X%
- Legendary: X%

**Save Changes:**
- Apply immediately
- Seed defaults if the config keys are missing

**Current repo note:** the live loot screen is a config-weight editor, not a full loot-pool manager. It does **not** currently add/remove specific items from activity pools, edit gold/gem reward amounts, or schedule future loot changes from this page.

---

### Shop Offers (CRUD)
**Purpose:** Manage store bundles and flash sales
**Create Offer:**
- key
- title, description
- offer type (`bundle`, `daily_deal`, `flash_sale`, `starter_pack`, `level_up`)
- bundle contents (gold / gems / xp / consumable / item + quantity)
- original price
- sale price
- currency
- discount %
- max purchases
- min/max level window
- sort order
- image key
- tags
- active toggle
- start/end dates

**Manage:**
- Create / edit / delete offers
- Activate / deactivate offers
- Seed default offers
- View aggregate purchases and revenue totals

**Current repo note:** the live shop-offers surface does **not** currently ship A/B pricing experiments or a separate pause/schedule state machine beyond active toggle plus start/end windows.

---

### Upgrade & Repair Controls
**Purpose:** Tune upkeep and upgrade progression costs

**Live controls today:**
- Repair parameters on the main Balance page:
  - `repair.base_cost`
  - `repair.per_level`
- Upgrade success chances on the main Balance page:
  - `upgrade_chances` array for +1 through +10
- Item-balance config editor controls for item-upgrade economy:
  - `upgrade_stat_bonus_per_level`
  - `upgrade_cost_base`
  - `upgrade_cost_exponent`
  - `upgrade_failure_downgrade_threshold`
  - `upgrade_protection_gem_cost`

**Current repo note:** these are live config/editor controls, not a dedicated player-impact forecaster. The current admin UI does **not** expose a built-in “X fewer upgrades/day” simulator on this screen, and rollback lives in the separate snapshots flow rather than a local per-page undo stack.

---

## 5. Balance & Analytics

### Configuration Manager (live game config)
**Purpose:** Central control of all game systems
**Sections:**

#### Combat
- Base stamina
- Stamina per level
- Stamina refill interval (minutes)
- Stamina cost per match
- Damage variance (% random)
- Crit chance formula
- Crit multiplier
- Block chance formula

#### Rewards
- Base PvP gold reward
- Base PvP gem reward
- Win streak bonus (%)
- Rating bonus multiplier (ELO)
- Dungeon clear bonus (%)
- Quest gold multiplier
- Training match gold

#### Progression
- Base XP to level up
- XP curve (linear/exponential)
- Stat point per level
- Passive point per N levels

#### Economy
- Gem hard cap (max player can hold)
- Daily gem faucet limit
- Shop markup (% above raw cost)
- Upgrade cost base
- Upgrade cost curve

#### PvP
- ELO K-factor (rating volatility)
- Rating reset threshold (when to soft reset)
- Max opponent rating diff (for matchmaking)
- Revenge window (hours)

#### Passives
- Point cost multiplier
- Respec cost (gems)
- Connection validation (enforce pathing)

#### Dungeons
- Difficulty scalar per floor
- Boss health multiplier
- Wave scaling

**UI Actions:**
- Edit parameter
- See description and range validation where the page defines them
- Save per-key on the generic Config page
- Save per-section / per-tab on the main Balance page
- Seed default configs
- Use Snapshots page for rollback / restore

**Current repo note:** the live config surfaces do **not** currently expose automatic future scheduling or built-in impact calculators on these pages.

---

### Item Balance Simulator
**Purpose:** Test item stats before live
**Features:**
- Overview dashboard with:
  - total items
  - config count
  - profile count
  - recent simulation history
- Config editor for power / rarity / upgrades / economy / validation knobs
- Item profiles editor for stat weights per item type
- Validation run for flagged / overpowered / underpowered items
- Simulation tools for:
  - combat sim
  - class matchups
  - item impact

**Current repo note:** the live item-balance suite does **not** currently expose named experiment profiles like “Nerf Sword v2”, meta-usage analytics, or A/B comparison workflows between two saved simulation profiles.

---

### Economy Review Surface
**Purpose:** Live aggregate economy and monetization review
**Views:**

#### Summary cards
- Gold in circulation
- Gems in circulation
- Verified IAP transaction totals
- Offer sales totals

#### Wealth review
- Wealth distribution buckets (gold)
- Gini coefficient
- Character / user population counts

#### Segmentation
- Economy by class
- Gold by level
- Top gold holders
- Top gem holders

#### Monetization review
- IAP by product
- Recent verified transactions
- Offer purchase analytics

**Current repo note:** the live admin surface here is a review dashboard, not a full analytics suite. Retention, churn, sessions, LTV/cohort analysis, combat telemetry, and export tooling are not separate live dashboard views in the current repo.

---

## 6. Live Operations

### Mail System (Broadcast & Targeted)
**Purpose:** Send items, announcements, time-sensitive rewards
**Create Mail:**
- Choose recipient(s):
  - Broadcast (all players)
  - Segment (min level, max level, class)
  - Targeted (single character ID)
- Subject
- Body
- Attachments:
  - Gold (amount)
  - Gems (amount)
  - XP (amount)
- Optional expiration timestamp

**Track:**
- View total messages, recipients, read rate, and claimed rate
- Inspect per-message recipient counts, reads, and claims
- Delete sent mail messages from the admin list

**Current repo note:** the live mail screen sends immediately. It does **not** currently expose timezone-aware scheduling, resend flows, online-only targeting, repeating campaigns, or item/consumable/cosmetic attachments.

---

### Push Notifications (Campaigns)
**Purpose:** Re-engage lapsed players, announce events
**Create Campaign:**
- Campaign title
- Body text
- Target type:
  - Broadcast
  - Segment
  - User IDs
- Segment filters:
  - Min level
  - Max level
  - Class
- Optional deep link route

**Analytics:**
- Sent count
- Failed count
- Active token count

**Current repo note:** the live push surface is a basic campaign sender. The current dashboard does **not** expose timezone scheduling, recurring campaigns, A/B messaging, rich media, delivered/open/click analytics, or cohort targeting like VIP / inactive / region / beta-tester segments.

---

### Feature Flags (Gradual Rollout)
**Purpose:** Toggle features, test with % of players, rollback if broken
**Create Flag:**
- flagKey (e.g., "enable_new_dungeon")
- Type:
  - Boolean (on/off)
  - Percentage (0–100% of players)
  - Segment (targeted boolean rollout)
  - JSON (complex config)
- Value
- Description
- Environment:
  - all
  - production
  - staging
  - development
- Optional targeting:
  - Min level
  - Max level
  - Class
  - Explicit user IDs
- Tags

**Manage:**
- Enable/disable toggle
- Adjust percentage (1% → 10% → 100%)
- Edit environment / tags / targeting
- Rollback (turn off instantly)
- Seed default flags

**Examples:**
- "enable_new_dungeon": boolean (on/off)
- "new_ui_rollout": percentage (0–100%)
- "max_stamina_override": JSON (e.g., {value: 100, class: "warrior"})

**Current repo note:** the live targeting surface is narrower than a full experimentation platform. The current dashboard does **not** expose cohort builders like beta testers / platform / region, automated impact monitoring, or crash-log-linked rollout analytics.

---

### Config Snapshots (Save & Rollback)
**Purpose:** Backup game config, quickly revert if balance breaks
**Actions:**
- Take snapshot (save all config params + date)
- Name snapshot (e.g., "Balance Patch v2.1")
- Add notes (what changed)
- View snapshot history (all past snapshots with dates)
- Compare two snapshots (diff view)
- Rollback to snapshot (apply old config, all players affected)

**Automation:**
- Auto-snapshot before each config update
- Manual snapshot on demand
- Keep last 20 snapshots

---

## 7. Roles & Permissions

### Admin
- Full access to all pages
- Can ban/unban, grant items, modify config
- Can create/delete content (items, skills, dungeons)
- Can broadcast mail/push
- Can view stats, economy, IAP transaction review, and IAP Products catalog surfaces
- Can rollback config

### Moderator
- Player management only
- Can search, view player details
- Can ban/unban
- Can grant items/gold/gems to players
- Cannot modify game config
- Cannot access stats/economy/IAP review or IAP Products catalog surfaces
- Cannot broadcast mail
- View-only on shop/economy

### Developer
- Config modification only
- Can view/edit the live config categories exposed to this role
- Can create snapshots and rollback
- Can manage feature flags
- Can run balance sims
- Cannot access player data
- Cannot ban users
- View-only on the narrower stats/economy/IAP transaction/catalog review surface

### Custom Roles
- Future-facing concept, not a live admin builder in the current repo
- Current live roles are the fixed `admin` / `moderator` / `developer` set

---

## 8. Settings & System Surface

### Item Balance History
- View all item changes (created, modified, deleted)
- Change log with admin who made change
- Rollback to previous version

### Settings (live today)
- Basic database connectivity check
- Current game-config key count
- Admin-user roster
- Role changes across the fixed live roles
- Seed default config values

### Audit / performance / system ops (not standalone live pages today)
- Audit logging exists as part of the broader admin/backend model, but there is no separate dedicated Audit Trail dashboard page in the current repo
- Performance monitoring and rich system-status dashboards are not standalone live admin pages today
- Treat these as adjacent operational concerns rather than fully implemented dashboard surfaces

---

## 9. Access Control & Security

**Authentication:**
- OAuth via internal service or email + password
- 2FA optional (recommended for admins)
- Session timeout after 30 min inactivity

**Authorization:**
- Role-based access (admin/moderator/developer/custom)
- Page-level permissions
- Action-level permissions (can view but not edit)

**Audit:**
- All changes logged to AdminLog table
- IP address tracked
- Rollback capability on most actions
- Approval workflow for high-risk actions (mass ban, config rollback)

---

## 10. Page Surface Inventory

This list is intended as a capability-oriented snapshot of the live dashboard surface, not a permanent count. For the current repo surface, verify against `admin/src/app/(dashboard)` and the live wiki audit.

**Overview / review surfaces**
- Dashboard
- Players
- Matches
- Economy
- Settings (includes basic server info + role management, not a standalone system-ops suite)

**Content management surfaces**
- Items
- Consumables
- Skills
- Passives
- Dungeons
- Dungeon Map
- Appearances
- Assets

**Gameplay system surfaces**
- Quests
- Achievements
- Events
- Seasons
- Battle Pass
- Daily Login

**Economy / balance surfaces**
- Balance
- Loot
- Offers
- Config
- Item Balance
- Snapshots

**Live operations surfaces**
- Mail
- Push
- Feature Flags
- Social

**Reference / support surfaces**
- Design System
- Generic Tables shell

Current repo note: there is no standalone analytics dashboard route under `admin/src/app/(dashboard)` today. Analytics-adjacent behavior currently lives in the dashboard/economy surfaces and their admin-owned server-action/read-side flow, plus the dedicated `IAP Products` catalog page backed by `/api/admin/iap-products`. There is also no separate dedicated User Activity Log, Performance Monitoring, System Status, or Audit Trail page in the current dashboard surface.

---

## Tech Stack

**Frontend:**
- Next.js 15 (React)
- TypeScript
- TailwindCSS + shadcn/ui
- Chart.js or Recharts for graphs
- Zod for form validation

**Backend Integration:**
- API routes call backend endpoints
- All mutations require admin auth token
- Optimistic updates where safe
- Debounced auto-save (5s)

**Data Fetching:**
- Server-side rendering for initial load
- Client-side React Query for live data
- WebSocket for real-time metrics (optional)
- Polling fallback (5s interval)

---

## Notes

- **Security:** confirmation and audit behavior varies by route/action. High-risk flows like bans, deletes, and rollback-style operations commonly require confirmation, but this document should not be read as a formal security-control matrix.
- **Performance:** Pagination on all lists. Debounced search. Lazy-load economy graphs where present. Cache feature flags client-side.
- **UX:** Inline validation exists on many live forms. Some config-heavy screens include helper text/tooltips. Undo and CSV import/export are **not** general admin capabilities across the current dashboard.
