# Admin Panel Capabilities (Source of Truth)
*Derived from admin panel code. Updated: 2026-04-30*

This is a high-level capability map of the Next.js admin dashboard, organized by area of responsibility. Treat `wiki/` plus the audited route/action files as the live source of truth for current behavior and access control.

Admin-facing routes and actions are expected to run behind authenticated admin access, but permission boundaries are enforced in code per route and per action. This document should not be read as a formal security matrix.

---

## 1. Overview & Dashboard

### Dashboard (Home)
**Purpose:** KPI overview, alert summary, and quick navigation
**Key Metrics:**
- Active Today
- New Users
- Total Users — All-time accounts
- PvP Today
- Gold Circulation — Avg gold per player
- Gem Circulation — Avg gems per player

**Auto-Alerts:**
- Class win-rate imbalance from recent PvP data
- DAU drop versus yesterday
- PvP volume drop versus yesterday

**Sections:**
- KPI grid
- Alerts list (only when alerts exist)
- Economy charts
- PvP & Balance charts, including a recent rating-gap-derived matchmaking fairness badge when PvP data exists
- Player acquisition/activity charts, with retention slots left pending until dedicated return-event tracking is available
- System Health badges
- Quick links to core admin areas

**Current repo note:** the live dashboard is a generated snapshot view with alert cards and chart sections. It does **not** currently expose an inline top-10 leaderboard, an “active PvP matches” KPI, or a real-time websocket-driven ops console.

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

### Arena Matches (History)
**Purpose:** Review recent PvP matches across all players
**Features:**
- Summary cards:
  - total matches
  - matches today
  - revenge matches
- Recent matches table (last 100)
- Player names with links back to player pages where a local user id exists
- Match type and revenge badges
- Winner/result badge
- Rating deltas for both players
- Gold / XP rewards
- Turn count and played-at timestamp

**Current repo note:** the live page is a read-only history/review surface. It does **not** currently expose fraud detection, advanced filters, battle-log expansion, or a match invalidation / refund workflow.

---

### Matchmaking
**Purpose:** Review rating-distribution health and the live ELO tuning baseline
**Features:**
- Summary cards:
  - active characters in the last 7 days
  - matches played in the last 7 days
  - calibration/default K-factor
  - calibration games
- Rating distribution buckets for active characters
- Read-only notes pointing back to the live `elo.*` config keys

**Current repo note:** the live matchmaking page is a read-only review screen. It does **not** currently expose queue inspection, live pair-debugging, forced rematch tools, or direct config mutation from this route.

---

### Referrals (Claims Review)
**Purpose:** Review referrer ↔ invitee qualification claims
**Features:**
- Summary cards:
  - total claims
  - last 7 days
  - shown rows
- Recent claims table:
  - referrer character
  - invitee character
  - qualified-at timestamp
- Read-only audit note pointing back to the backend qualification helper

**Current repo note:** the live referrals page is a Phase 1 audit surface. It does **not** currently expose dispute resolution, manual credit, or claim repair actions from the dashboard.

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

### Consumables (Catalog + Live Config)
**Purpose:** Review consumable catalog entries and tune live consumable config values
**Catalog View:**
- Consumable items from the main item catalog
- catalogId
- rarity
- effect string
- buy / sell prices

**Live Config Controls:**
- stamina potion prices
- stamina restore amounts
- health potion prices
- HP restore percentages
- save all overrides to live `GameConfig`

**Current repo note:** the live consumables page is **not** a standalone consumable CRUD editor. Item creation/editing still happens through the main Items section.

---

### Skills (CRUD)
**Purpose:** Design character abilities
**Fields:**
- skillKey
- skillName
- classRestriction
- Description
- damageBase
- damageType
- targetType
- cooldown (seconds)
- manaCost
- damageScaling (JSON)
- effectJson (JSON)
- Unlock level
- maxRank
- rankScaling
- icon
- sortOrder
- active toggle

**Current repo note:** the live skills page is a CRUD/filtering surface. It does **not** currently expose an embedded combat simulator or a separate rank-progression analysis workflow.

---

### Passives (CRUD + Connections)
**Purpose:** Manage passive nodes and their connections

**Node Fields:**
- nodeKey, nodeName
- description
- bonusType
- bonusStat
- bonusValue
- tier
- point cost to unlock
- Class restriction (optional)
- Position (X, Y)
- icon
- start-node toggle
- active toggle

**Connections:**
- Create connection by selecting From / To nodes
- Delete saved connections
- Maintain manual position data on nodes

**Current repo note:** the live passives page does **not** currently expose a drag-and-drop tree canvas, visual path preview, or path-simulation tooling.

---

### Dungeons (List + Editor)
**Purpose:** Create, edit, and delete dungeon definitions
**List Surface:**
- Search by dungeon name or slug
- Create new dungeon
- Open existing dungeon editor
- Delete dungeon
- Review summary columns:
  - level requirement
  - difficulty
  - dungeon type
  - boss count / last boss name
  - active/disabled status

**Editor Surface:**
- General fields:
  - name / slug
  - description / lore
  - level requirement
  - difficulty
  - dungeon type
  - energy cost
  - active toggle
  - sort order
  - gold reward
  - XP reward
- Image fields:
  - dungeon image
  - background image
  - image prompt
  - image style
- Boss editor:
  - boss stats
  - description / lore
  - floor number / sort order
  - boss abilities
- Wave editor:
  - wave number
  - enemy type / level / count
- Drop editor:
  - item
  - drop chance
  - min/max quantity

**Current repo note:** the live dungeon tooling does **not** currently expose completion-rate forecasting, recommended-stat estimates, clear-time modeling, or template saving.

---

### Dungeon Map
**Purpose:** Adjust the shared dungeon-overworld node layout
**Features:**
- Background-map editor with draggable dungeon nodes
- Per-node X / Y / size editing
- Reset to defaults
- Save layout back to the server

**Current repo note:** the live dungeon-map screen is a manual layout editor. It does **not** currently expose procedural path generation, pathing previews, route validation, or unlock-graph authoring.

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
- Choose storage bucket and optional path
- Browse files in that location
- Drag-and-drop or click-to-upload files
- Image-grid preview for image assets
- Resolve public asset URL and copy it
- Delete files directly from the browser

**Current repo note:** the live asset browser does **not** currently expose automatic sprite generation, tag/search metadata, usage tracking, or “delete only if unused” enforcement.

---

## 3. Gameplay Systems

### Quests (CRUD)
**Purpose:** Quest definition management
**Create Quest:**
- questType
- questName
- Description
- icon
- minTarget
- maxTarget
- Gold reward
- XP reward
- Gem reward

**Edit:**
- Update quest definition values
- Toggle active / inactive
- Seed default quest definitions

**Current repo note:** the live quest admin surface manages quest-definition records. It does **not** currently expose active date ranges, display-order editing, or a separate seasonal quest planner.

---

### Achievements (CRUD)
**Purpose:** Long-term unlock goals
**Fields:**
- achievementKey
- achievementName
- Description
- category
- target
- rewardType
- rewardAmount
- optional rewardId for cosmetic rewards
- icon
- sortOrder
- active toggle

**Manage:**
- Create / edit / delete achievement definitions
- Activate / deactivate definitions
- Seed default achievement set
- Review completion stats / rates in the stats tab

**Current repo note:** the live achievements page manages achievement definitions plus summary stats. It does **not** currently expose a free-form batch-template builder beyond the built-in seed action.

---

### Events (CRUD)
**Purpose:** Time-limited gameplay events
**Create Event:**
- eventKey
- eventName
- Description
- Start date / end date
- Type (`boss_rush`, `gold_rush`, `class_spotlight`, `tournament`)
- Config JSON

**Manage:**
- Create / edit / delete events
- Toggle active / inactive
- Review upcoming / active / expired state from the event cards

**Current repo note:** the live events screen does **not** currently expose association pickers for dungeon/quest/achievement targets, broadcast-message authoring, or participant analytics.

---

### Seasons (CRUD)
**Purpose:** Manage competitive season windows
**Create Season:**
- seasonNumber
- theme
- Start date / end date

**Manage:**
- Create / edit / delete seasons
- Review status (Upcoming / Active / Ended)

**Current repo note:** the live seasons page is separate from battle-pass reward authoring. It does **not** currently expose season-level battle-pass reward editing, pass grants, or pass-sales analytics from this screen.

---

### Battle Pass Rewards
**Purpose:** Manage reward rows per season and level
**Features:**
- Choose season
- Review rewards grouped by level
- Add free or premium reward rows
- Edit reward type, reward amount, and optional reward id
- Delete individual reward rows
- Bulk-generate default rewards up to a chosen max level

**Current repo note:** the live battle-pass page is a reward-authoring surface. It does **not** currently expose pass pricing, purchase analytics, grant/revoke flows, or season sales reporting from this page.

---

### Daily Login Rewards
**Purpose:** Configure the live 7-day login cycle
**Features:**
- Review all 7 day slots
- Edit reward type:
  - gold
  - gems
  - consumable
- Edit amount and consumable id
- Reset the whole cycle to defaults
- Preview the current 7-day reward order

**Current repo note:** the live daily-login page manages the reward cycle only. It does **not** currently expose calendar scheduling, alternate streak rules, or multiple named reward calendars.

---

## 4. Economy Management

### Economy Overview
**Purpose:** Review aggregate economy and monetization health
**Views:**
- Summary cards:
  - gold in circulation
  - gems in circulation
  - verified IAP totals
  - offer sales totals
- Wealth review:
  - wealth distribution buckets
  - gini coefficient
  - character / user population
- Segmentation:
  - economy by class
  - gold by level
  - top gold holders
  - top gem holders
- Monetization review:
  - IAP by product
  - recent transactions
  - offer purchase analytics

**Current repo note:** the live economy page is a review dashboard, not a forecasting/alerting engine. It does **not** currently expose 30-day circulation charts, faucet-vs-sink time series, or automatic exploit alerts on this page.

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

### IAP Products (Catalog Review)
**Purpose:** Review the live purchasable SKU catalog
**Views:**
- Summary cards:
  - total SKUs
  - enabled SKUs
  - disabled/grandfathered SKUs
- Filter by product id
- Optional hide-disabled toggle
- Table columns:
  - product id
  - USD price
  - gems
  - gold
  - premium / monthly-card / subscription flags
  - extra bundled items
  - enabled / disabled status

**Current repo note:** the live IAP Products page is read-only. Changes to price, enabled flags, and bundle contents still come from code/config (`IAP_PRODUCTS`) plus StoreKit/App Store sync, not admin CRUD mutations.

---

### Minigame Sessions
**Purpose:** Review recent minigame session outcomes and claims
**Views:**
- Per-game count cards
- Filter by game type
- Filter by player name / email / username
- Session table:
  - game type
  - character / user
  - status
  - bet amount
  - claimed gold
  - claimed gems
  - created / claimed timestamps

**Current repo note:** the live minigame-sessions page is a read-only audit surface. It does **not** currently expose manual claim repair, force-expire, replay, or per-session mutation tools.

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

**Current repo note:** this is the dedicated `/economy` review dashboard. It is not a full analytics suite; retention, churn, sessions, LTV/cohort analysis, combat telemetry, and export tooling are not separate live dashboard views in the current repo.

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

**Current repo note:** the live push surface is a basic APNS-backed iOS
campaign sender. Android tokens may exist in the database, but the repo does
not yet ship an active FCM delivery path. The current dashboard does **not**
expose timezone scheduling, recurring campaigns, A/B messaging, rich media,
delivered/open/click analytics, or cohort targeting like VIP / inactive /
region / beta-tester segments.
When a deep-link route is attached, the current iOS client supports only a
bounded subset of route strings that can open without extra typed payloads:
`inbox`, `shop`, `guild-hall`, `arena`, `battle-pass`, `daily-quests`,
`achievements`, `leaderboard`, `tavern`, `stash`, `shell-game`,
`fortune-wheel`, `gold-mine`, `dungeon-rush`, `settings`, `hero`, `hub`.

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
- Rollback to snapshot (apply old config, all players affected)
- Delete snapshot

**Automation:**
- Manual snapshot on demand
- Rollback creates an automatic backup snapshot before restore

**Current repo note:** the live snapshots page does **not** currently expose snapshot diff comparison or a general global auto-snapshot-before-every-config-change guarantee from that page. The page lists the newest snapshots and supports manual create / rollback / delete.

---

### Social Hub
**Purpose:** Review friendships, direct messages, and challenge activity
**Views:**
- Summary cards:
  - active friendships
  - total messages / messages today
  - total challenges / pending / completed
  - blocked relationships
- Recent messages table with sender / receiver player links
- Recent challenges table
- Recent friendships table

**Current repo note:** the live social page is a review surface. It does **not** currently expose moderator actions like delete message, unblock friendship, resend challenge, or export/search tooling beyond the built-in recent tables.

---

## 7. Roles & Permissions

### Admin
- Can sign into the admin dashboard
- Can access admin-only surfaces such as Settings and role mutation
- Can use config/content mutation routes protected by `canModifyConfig`
- Can access player-management, liveops, economy-review, and catalog-review surfaces
- Can create snapshots and trigger config restore / rollback flows

### Moderator
- Can sign into the admin dashboard
- Can access general review/ops surfaces that only require an authenticated admin session
- Can use player-management flows currently exposed through the live player pages
- Cannot use config/content mutation routes guarded by `canModifyConfig`
- Cannot access the admin-only Settings page
- Cannot change roles

### Developer
- Can sign into the admin dashboard
- Can use config/content mutation routes guarded by `canModifyConfig`
- Can manage feature flags, balance/config surfaces, seasons, items, dungeons, skills, passives, and similar admin/developer edit flows
- Can create snapshots and use config restore / rollback flows
- Cannot access the admin-only Settings page
- Cannot change roles

**Current repo note:** this section is a practical summary of the live role model, not a perfect page-by-page permission matrix. In the current repo:
- allowed dashboard roles are the fixed `admin` / `moderator` / `developer` set
- config/content mutation is commonly guarded through `canModifyConfig` (`admin` or `developer`)
- role mutation and the Settings page are `admin`-only
- several review/ops surfaces still allow any authenticated admin-session role unless a stricter guard is applied per route/action

### Custom Roles
- Future-facing concept, not a live admin builder in the current repo
- Current live roles are the fixed `admin` / `moderator` / `developer` set

---

## 8. Settings & System Surface

### Item Balance History
- View simulation history from the Item Balance simulation page
- Inspect recent run type, summary, config, and results payloads

**Current repo note:** the live repo exposes simulation-run history, not a full item edit/change-history log with per-item rollback.

### Settings (live today)
- Basic database connectivity check
- Current game-config key count
- Admin-user roster
- Role changes across the fixed live roles
- Seed default config values

**Current repo note:** the Settings page itself is admin-only.

### Audit / performance / system ops (not standalone live pages today)
- Audit logging exists as part of the broader admin/backend model, but there is no separate dedicated Audit Trail dashboard page in the current repo
- Performance monitoring and rich system-status dashboards are not standalone live admin pages today
- Treat these as adjacent operational concerns rather than fully implemented dashboard surfaces

---

## 9. Access Control & Security

**Authentication:**
- Email + password sign-in through Supabase-backed auth
- Admin access is limited to users whose role is one of `admin` / `moderator` / `developer`
- Admin session is stored in the `admin-token` cookie (currently up to 7 days)

**Authorization:**
- Fixed role set: `admin`, `moderator`, `developer`
- Page- and action-level permissions vary by route/action
- Many mutation routes use `canModifyConfig` (`admin` or `developer`)
- Some stricter operations are explicitly `admin`-only, such as role mutation
- Custom roles are not a live feature

**Audit:**
- Many high-risk or config/content mutations write admin log records or structured audit entries
- Coverage varies by route/action and should be verified in code for sensitive workflows
- Rollback is available for config through snapshots/restore paths and for some simulation/config surfaces, not as a universal capability on most actions

---

## 10. Page Surface Inventory

This list is intended as a capability-oriented snapshot of the live dashboard surface, not a permanent count. For the current repo surface, verify against `admin/src/app/(dashboard)` and the live wiki audit.

**Overview / review surfaces**
- Dashboard
- Players
- Matches
- Matchmaking
- Referrals
- Economy
- Social
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
- IAP Products
- Loot
- Offers
- Minigame Sessions
- Config
- Item Balance
- Snapshots

**Live operations surfaces**
- Mail
- Push
- Feature Flags

**Reference / support surfaces**
- Design System
- Generic Tables shell

Current repo note: there is no standalone analytics dashboard route under `admin/src/app/(dashboard)` today. Analytics-adjacent behavior currently lives in the dashboard/economy surfaces and a small set of read-only review pages such as `IAP Products`, `Matchmaking`, `Minigame Sessions`, and `Referrals`, rather than a unified telemetry suite. There is also no separate dedicated User Activity Log, Performance Monitoring, System Status, or Audit Trail page in the current dashboard surface.

---

## Tech Stack

**Frontend:**
- Next.js 15 (React 19)
- TypeScript
- TailwindCSS + shadcn/ui + Radix primitives
- Recharts for chart surfaces
- Zod and typed helpers on validation-heavy routes/forms
- `react-hook-form` on the dynamic form surface and selected admin forms

**Backend Integration:**
- Mixed model:
  - server actions
  - same-origin admin API routes
  - backend proxy/helpers for canonical backend-owned data
- Mutations require an authenticated admin session, with stricter guards depending on the route/action
- Many edit flows now refresh from the server after mutation instead of relying on broad optimistic state
- Save behavior is page-specific; there is no repo-wide debounced auto-save layer

**Data Fetching:**
- Server-side rendering for initial load
- Server actions plus direct `fetch(...)` calls to local API routes and backend proxy helpers
- `no-store` fetches on selected review pages that must reflect live state
- No repo-wide React Query layer today
- No websocket-driven real-time metrics layer today

---

## Notes

- **Security:** confirmation and audit behavior varies by route/action. High-risk flows like bans, deletes, and rollback-style operations commonly require confirmation, but this document should not be read as a formal security-control matrix.
- **Performance:** Pagination exists on many list/review surfaces. Some screens use simple client-side filtering or local debounce-like state, but there is no universal repo-wide debounced-search contract. Chart-heavy overview pages keep the heavier visualization work on the dedicated review screens.
- **UX:** Inline validation exists on many live forms. Some config-heavy screens include helper text/tooltips. Undo and CSV import/export are **not** general admin capabilities across the current dashboard.

---

## 11. Design Reference

### Design System
**Purpose:** Internal visual reference for shared tokens and component previews
**Views:**
- Colors
- Typography
- Spacing & radius
- Component previews
- Screen previews
- Figma-aligned component variants plus fallback domain preview groups

**Current repo note:** the live design-system page is a reference surface for the team. It is **not** currently a publishable Storybook replacement, token export pipeline, or component package registry.
