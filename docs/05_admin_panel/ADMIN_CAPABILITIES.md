# Admin Panel Capabilities (Source of Truth)
*Derived from admin panel code. Updated: 2026-03-19*

Complete reference of all 37+ pages in the Next.js admin dashboard, organized by section. All endpoints require `admin` role unless otherwise noted.

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
- Search by username, email, userId
- Filter by level range, class, role (player/admin/banned)
- View player card: profile, stats, inventory, achievements
- Actions:
  - Ban user (reason field, soft delete)
  - Unban user
  - Grant gold/gems (bulk add to wallet)
  - Grant items (select from catalog, assign to inventory)
  - Reset inventory (clear all gear, keep cosmetics)
  - View detailed statistics: wins/losses, dungeons cleared, time played
  - View battle history (last 20 PvP matches)
  - Email player (admin broadcast)

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

**Edit:**
- Change all above fields
- Track change history
- Preview item in 3D (if available)

**Delete:**
- Soft delete (keep in DB, hide from shop)
- Warn if in-circulation (held by X players)

**Batch Actions:**
- Export items (CSV)
- Import items (CSV)
- Duplicate item

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
**Purpose:** Manage character skins and cosmetics
**Fields:**
- catalogId
- cosmeticName
- cosmeticType (appearance skin, effect, emote, title)
- Rarity
- Gem price
- Icon/image reference
- Preview (show on 3D model)

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
- Select activity (PvP match, dungeon floor, minigame)
- View/edit drop weights by rarity
- Preview drop rates (e.g., "5% legendary")
- Adjust gold/gem amounts
- Add new items to pool
- Remove items from pool

**Rarity Distribution:**
- Common: X%
- Uncommon: X%
- Rare: X%
- Epic: X%
- Legendary: X%

**Save Changes:**
- Apply immediately
- Schedule future change (e.g., "increase legendary rate tomorrow")

---

### Shop Offers (CRUD)
**Purpose:** Manage store bundles and flash sales
**Create Offer:**
- catalogId
- offerName, description
- Items in bundle (multi-select from item catalog + quantities)
- Gold price
- Gem price (optional)
- Is bundle? (cosmetic grouping)
- Is flash sale? (limited-time)
- Start/end dates
- Max purchases per player (optional)

**Manage:**
- Schedule sale (start/end)
- Pause sale temporarily
- View sales metrics (revenue, units sold)
- A/B test pricing (run two variants, compare)

---

### Upgrade & Repair Pricing
**Purpose:** Balance equipment progression costs
**Upgrade Costs:**
- Level 1 → 2: X gold
- Level 2 → 3: Y gold (scales)
- ...
- Level 9 → 10: Z gold (max)

**Success Rate:**
- Level 1-3: 100% success
- Level 4-6: 90% success (risk of fail)
- Level 7-10: 50% success (high risk)

**Repair Costs:**
- Per equipment: X% of item value per durability point
- Example: 1000-gold sword, full repair = 100 gold

**Edit:**
- Adjust all costs
- Simulate player impact ("cost increase 20% → X fewer upgrades/day")
- Rollback to previous

---

## 5. Balance & Analytics

### Configuration Manager (80+ Params)
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
- See description and range validation
- Preview impact (calc: "if stamina +20%, Y fewer matches/day")
- Save all changes (creates snapshot)
- Rollback to previous snapshot
- Schedule change (auto-apply at future time)

---

### Item Balance Simulator
**Purpose:** Test item stats before live
**Features:**
- Create simulation profile (e.g., "Nerf Sword v2")
- Adjust item base stats (up/down %)
- Run matchup simulations (Item A vs. Item B, 100 fights each)
- Generate report:
  - Win rates per matchup
  - Outlier detection (item too strong/weak)
  - Recommendation (balanced, OP, UP)

**Advanced:**
- Simulate full loadout (multiple items equipped)
- Class-specific sims (warrior with sword vs. mage with staff)
- Meta analysis (most-used builds, win rates)
- A/B test (run two profiles, compare results)

---

### Analytics Dashboard
**Purpose:** Game-wide performance metrics
**Views:**

#### Retention
- 1-day retention (%)
- 7-day retention (%)
- 30-day retention (%)
- Churn rate (%)
- Trending (up/down)

#### Engagement
- Avg session length
- Sessions per DAU
- Most-played features (% time in PvP, dungeons, etc.)
- Feature adoption (% players who tried X)

#### Monetization
- ARPPU (avg revenue per paying user)
- Gem purchase rate (% who bought)
- First purchase conversion
- Lifetime value (LTV) by cohort
- Revenue breakdown (shop, IAP, battle pass)

#### Economy Health
- Total gold/gems (sanity check)
- Velocity (trades per day)
- Price inflation (gold cost of items over time)
- Top holder concentration (% held by top 1%)

#### Combat Balance
- Win rates by class (% should be ≈25% each)
- Pick rates by class
- Skill usage (most/least used)
- Item usage (which items are equipped)

**Export:** All reports → CSV/JSON for external analysis

---

## 6. Live Operations

### Mail System (Broadcast & Targeted)
**Purpose:** Send items, announcements, time-sensitive rewards
**Create Mail:**
- Choose recipient(s):
  - Broadcast (all players)
  - Segment (level range, class, last-login within X days)
  - Targeted (specific player IDs)
- Subject
- Body (markdown support)
- Attachments:
  - Gold (amount)
  - Gems (amount)
  - Items (select from catalog, quantity)
  - Consumables (stack count)
  - Cosmetics (award skin)

**Schedule:**
- Send immediately
- Schedule for future (timezone-aware)
- Send to online players only
- Repeat daily/weekly

**Track:**
- View sent count, delivered, claimed
- Resend if failed
- Monitor attachment claims (track redemption)

---

### Push Notifications (Campaigns)
**Purpose:** Re-engage lapsed players, announce events
**Create Campaign:**
- Campaign name
- Target audience:
  - All players
  - New players (joined < 7 days)
  - VIP players (spent > $X)
  - At-risk players (7+ days inactive)
  - Class-specific (all warriors, etc.)
- Title (short)
- Body (short text)
- Deep link (e.g., /dungeons for dungeon button)
- Icon/image (optional)

**Schedule:**
- Send immediately
- Send at local time (respects timezones)
- A/B test (randomize 50/50 different messages)
- Recurring (daily check-in reminder)

**Analytics:**
- Sent count
- Delivered count
- Open rate (%)
- Click-through rate (%)
- Cohort comparison (A vs. B performance)

---

### Feature Flags (Gradual Rollout)
**Purpose:** Toggle features, test with % of players, rollback if broken
**Create Flag:**
- flagKey (e.g., "enable_new_dungeon")
- Type:
  - Boolean (on/off)
  - Percentage (0–100% of players)
  - Segment (specific cohorts: beta testers, etc.)
  - JSON (complex config)
- Value
- Description

**Manage:**
- Enable/disable toggle
- Adjust percentage (1% → 10% → 100%)
- Segment by cohort (beta testers, platform, region)
- Monitor impact (user reports, crash logs)
- Rollback (turn off instantly)

**Examples:**
- "enable_new_dungeon": boolean (on/off)
- "new_ui_rollout": percentage (0–100%)
- "max_stamina_override": JSON (e.g., {value: 100, class: "warrior"})

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
- Can view all analytics
- Can rollback config

### Moderator
- Player management only
- Can search, view player details
- Can ban/unban
- Can grant items/gold/gems to players
- Cannot modify game config
- Cannot access analytics
- Cannot broadcast mail
- View-only on shop/economy

### Developer
- Config modification only
- Can view/edit all 80+ config params
- Can create snapshots and rollback
- Can manage feature flags
- Can run balance sims
- Cannot access player data
- Cannot ban users
- View-only on analytics

### Custom Roles
- Define role with specific page permissions
- Assign to users (e.g., "economy_manager", "content_designer")

---

## 8. Miscellaneous Pages

### Item Balance History
- View all item changes (created, modified, deleted)
- Change log with admin who made change
- Rollback to previous version

### User Activity Log
- Who accessed admin panel and when
- Actions taken (ban, mail, grant)
- Timestamp, admin ID, action details
- Searchable, exportable

### Performance Monitoring
- API latency (p50, p95, p99)
- Error rate
- Database query performance
- Cache hit rate
- Alert if degraded

### System Status
- Database connection status
- API server health
- CDN/asset delivery status
- Push notification service status
- Third-party integrations (Apple IAP, Google Play)

### Audit Trail
- All admin actions logged
- Who made what change when
- Data integrity check (inconsistencies flagged)
- Compliance export (for legal review)

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

## 10. Page List (37+ Total)

**Overview (4 pages):**
1. Dashboard (KPI, alerts, graphs)
2. Players (search, manage)
3. Arena (PvP matches)
4. User Activity Log

**Content Management (6 pages):**
5. Items (CRUD)
6. Consumables (CRUD)
7. Skills (CRUD)
8. Passives (tree editor)
9. Dungeons (visual builder)
10. Appearances/Cosmetics (CRUD)
11. Assets (upload, library)

**Gameplay Systems (4 pages):**
12. Quests (CRUD)
13. Achievements (CRUD)
14. Events (CRUD)
15. Seasons & Battle Pass (CRUD)

**Economy (5 pages):**
16. Economy Overview
17. Loot Tables
18. Shop Offers (CRUD + A/B test)
19. Upgrade/Repair Pricing
20. Item Balance History

**Balance & Analytics (4 pages):**
21. Configuration Manager (80+ params)
22. Item Balance Simulator
23. Analytics Dashboard (retention, engagement, economy)
24. Performance Monitoring

**Live Operations (4 pages):**
25. Mail System (broadcast, segment, targeted)
26. Push Notifications (campaigns, A/B test)
27. Feature Flags (manage toggles)
28. Config Snapshots (save/rollback)

**System (3 pages):**
29. System Status
30. Audit Trail
31. Roles & Permissions

**Total: 37+ pages**

---

## Tech Stack

**Frontend:**
- Next.js 14 (React)
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

- **Security:** All config changes create audit log. High-risk actions (ban, rollback) require confirmation. IP whitelist optional.
- **Performance:** Pagination on all lists. Debounced search. Lazy-load analytics graphs. Cache feature flags client-side.
- **UX:** Undo available on most destructive actions. Tooltips on all config params. Inline validation. Bulk actions for CSV import/export.
