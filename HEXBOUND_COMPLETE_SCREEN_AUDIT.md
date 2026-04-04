# HEXBOUND iOS — COMPLETE SCREEN & COMPONENT INVENTORY

**Audit Date:** 2026-04-03
**Total Files Analyzed:** 159 Swift view files + Theme/Components
**Total Screens:** 48 primary + 28 overlays/sheets/modals
**Total Reusable Components:** 85+
**Routes:** 37 (AppRoute enum)

---

## A. ALL SCREENS (by Category)

### AUTH FLOW (8 screens)

| Screen | File | States | Route | Purpose |
|--------|------|--------|-------|---------|
| Welcome | `WelcomeView.swift` | default, loading | — | Entry point: Play as Guest / Log In / Apple Sign-In |
| Login | `LoginView.swift` | default, loading, error | `.login` | Email/password authentication |
| Register | `RegisterDetailView.swift` | default, loading, error | `.register` | Account creation with email |
| Character Creation | `OnboardingDetailView.swift` | name, class, origin, gender, appearance | `.onboarding` | Multi-step: NameStepView → ClassSelectionStepView → AppearanceStepView |
| Character Selection | `CharacterSelectionView.swift` | loading, empty, list, delete hero | `.characterSelection` | Hero selection when user has 2+ characters |
| Email Confirmation | `EmailConfirmationView.swift` | waiting, confirmed, error | — | Email verification (part of auth flow) |
| Lore Intro | `LoreIntroView.swift` | default | `.loreIntro(heroName:)` | Story intro after character creation |
| Upgrade Guest | `UpgradeGuestView.swift` | default, loading, error | `.upgradeGuest` | Guest → full account conversion |

### HUB / HOME (11 screens)

| Screen | File | States | Route | Purpose |
|--------|------|--------|-------|---------|
| Hub | `HubView.swift` | default, loading, onboarding | `.hub` | Main home: stamina bar, character card, city map, floating buttons, parallax transitions |
| City Map | `CityMapView.swift` | default | — | Interactive hub map with 8 buildings (Shop, Arena, Dungeon, Tavern, Gold Mine, Shell Game, Minigame, etc.) |
| City Building | `CityBuildingView.swift` | default | — | Individual building on city map (with badge, label) |
| City Map Effects | `CityMapEffects.swift` | — | — | Ambient particle/glow effects on city map |
| Dungeon Map | `DungeonMapView.swift` | default | `.dungeonMap` | Dungeon room grid layout with boss rooms |
| Dungeon Map Editor | `DungeonMapEditorView.swift` | default (dev only) | `.dungeonMapEditor` | Edit dungeon layout (draggable buildings) |
| Hero Detail | `HeroDetailView.swift` | INVENTORY, STATUS tabs, stat points banner, repair | `.hero` | Character equipment, stats, stat allocation |
| Hub Editor | `HubEditorDetailView.swift` | default (dev only) | `.hubEditor` | Hub layout customization |
| Stance Selector | `StanceSelectorDetailView.swift` | default | `.stanceSelector` | Combat stance (HEAD/CHEST/LEGS zone) selection |
| Tutorial | `TutorialView.swift` | default | `.tutorial` | Onboarding guide with NPC dialogue |
| Character Profile | `CharacterProfileView.swift` | default, loading, error | `.characterProfile(...)` | Other player's profile (from leaderboard/PvP) |

### COMBAT (4 screens + VFX system)

| Screen | File | States | Route | Purpose |
|--------|------|--------|-------|---------|
| Combat | `CombatDetailView.swift` | intro, active, victory, defeat, forfeit | `.combat` | Real-time combat with log, abilities, stance selector |
| Combat Result | `CombatResultDetailView.swift` | win, loss | `.combatResult` | Victory/defeat summary with loot display |
| Loot | `LootDetailView.swift` | default, empty | `.loot` | Item rewards from combat |
| VFX Overlay | `CombatVFXOverlay.swift` | active | — | Particle effects during combat |

**VFX Sub-system** (`Views/Combat/VFX/`):
- `CombatVFXEffect.swift` — Effect type definitions
- `CombatVFXManager.swift` — Effect queue & orchestration
- `CombatFXAssetMap.swift` — Asset-to-effect mapping
- `CombatFXImageOverlay.swift` — Image-based FX layer
- `DamageHitEffects.swift` — Damage/hit animations
- `DodgeMissBlock.swift` — Dodge, miss, block animations
- `HealEffect.swift` — Heal animation
- `StatusVFXEffects.swift` — Status effect visuals

### ARENA / PvP (7 screens)

| Screen | File | States | Route | Purpose |
|--------|------|--------|-------|---------|
| Arena | `ArenaDetailView.swift` | opponents, revenge, history tabs; loading, empty, list | `.arena` | PvP opponent selection with swipeable carousel |
| Arena Carousel | `ArenaCarouselView.swift` | default | — | Swipeable opponent cards |
| Arena Comparison | `ArenaComparisonSheet.swift` | default | — | Stat comparison vs opponent (sheet) |
| Opponent Card | `OpponentCardView.swift` | default, pressed, fighting | — | Opponent card with fight button |
| Arena Opponent Card | `ArenaOpponentCard.swift` | default | — | Arena-specific opponent card variant |
| Rank Up Ceremony | `RankUpCeremonyView.swift` | default | — | Cinematic rank-up celebration |

### INVENTORY (2 screens)

| Screen | File | States | Route | Purpose |
|--------|------|--------|-------|---------|
| Inventory | `InventoryViewModel.swift` (+ tab in HeroDetailView) | equipment, consumables, search, sort, loading, empty | — | Item management by type/rarity |
| Item Detail | `ItemDetailSheet.swift` | default | — | Item stats, equip/sell actions (sheet modal) |

### SHOP (4 screens)

| Screen | File | States | Route | Purpose |
|--------|------|--------|-------|---------|
| Shop | `ShopDetailView.swift` | equipment, consumables, premium tabs; loading, empty | `.shop` | Purchase items/consumables/cosmetics |
| Shop Offer Banner | `ShopOfferBannerView.swift` | default, active, expired | — | Limited-time offer cards (daily deal, flash sale) |
| Currency Purchase | `CurrencyPurchaseView.swift` | default, loading, purchase states | `.currencyPurchase(initialTab:)` | Buy gold/gems via IAP |
| Premium Purchase | `PremiumPurchaseView.swift` | default, loading, purchase states | `.premiumPurchase` | Premium/cosmetic items (skins, etc.) |

### DUNGEONS (6 screens)

| Screen | File | States | Route | Purpose |
|--------|------|--------|-------|---------|
| Dungeon Select | `DungeonSelectDetailView.swift` | default, loading, difficulty selection | `.dungeonSelect` | Pick dungeon + difficulty |
| Dungeon Info | `DungeonInfoSheet.swift` | default | — | Dungeon details (lore, rewards, difficulty) |
| Dungeon Room | `DungeonRoomDetailView.swift` | room, boss, loot, defeat | `.dungeonRoom` | Room-by-room progression with enemy encounters |
| Dungeon Victory | `DungeonVictoryView.swift` | default | — | Victory with loot display |
| Dungeon Defeat | `DungeonDefeatView.swift` | default | — | Defeat summary (optional retry) |
| Loot Preview | `LootPreviewSheet.swift` | default | — | Pre-battle loot preview (sheet modal) |

### MINIGAMES (4 screens)

| Screen | File | States | Route | Purpose |
|--------|------|--------|-------|---------|
| Gold Mine | `GoldMineDetailView.swift` | idle, mining, ready, collecting | `.goldMine` | Passive gold generation (tap to claim) |
| Shell Game | `ShellGameDetailView.swift` | betting, playing, result | `.shellGame` | 3-cup guessing game |
| Dungeon Rush | `DungeonRushDetailView.swift` | fighting, shopping, result, defeat | `.dungeonRush` | Wave-based boss rush minigame |
| Fortune Wheel | `FortuneWheelDetailView.swift` | default, spinning, result | `.fortuneWheel` | Daily spin minigame |
| Tavern | `TavernDetailView.swift` | default | `.tavern` | Minigame hub with navigation |

### QUESTS & PROGRESSION (7 screens)

| Screen | File | States | Route | Purpose |
|--------|------|--------|-------|---------|
| Daily Quests | `DailyQuestsDetailView.swift` | loading, list, all-complete | `.dailyQuests` | Quest list + completion progress |
| Daily Login | `DailyLoginDetailView.swift` | default, claiming, streak display | `.dailyLogin` | Streak reward calendar |
| Daily Login Popup | `DailyLoginPopupView.swift` | default, claiming, claimed, celebration | — | Auto-popup on hub entry |
| Achievements | `AchievementsDetailView.swift` | loading, list, 3 tabs (PvP/Progress/Ranking) | `.achievements` | Achievement list with claim/progress |
| Achievement Card | `AchievementCardView.swift` | locked, in-progress, claimable, claimed | — | Individual achievement row |
| Battle Pass | `BattlePassDetailView.swift` | free track, premium track, season info | `.battlePass` | Seasonal reward tree with nodes |
| Battle Pass Nodes | `BPRewardNodeView.swift` | locked, claimed, claimable | — | Individual BP reward node |

### LEADERBOARD & SOCIAL (5 screens)

| Screen | File | States | Route | Purpose |
|--------|------|--------|-------|---------|
| Leaderboard | `LeaderboardDetailView.swift` | rating, level, gold tabs; loading, list | `.leaderboard` | Global rankings (searchable) |
| Leaderboard Row | `LeaderboardRowView.swift` | default | — | Individual leaderboard entry |
| Leaderboard Player Detail | `LeaderboardPlayerDetailSheet.swift` | default | — | Player profile from leaderboard (sheet modal) |
| Inbox | `InboxDetailView.swift` | loading, list, empty, detail | `.inbox` | Mail messages with threading |
| Inbox Row | `InboxRowView.swift` | default, unread | — | Individual message list item |

**Social:**
- `GuildHallDetailView.swift` — Guild chat/messaging hub (route: `.guildHall`, `.guildHallMessage(...)`)

### SETTINGS & PROFILE (3 screens)

| Screen | File | States | Route | Purpose |
|--------|------|--------|-------|---------|
| Settings | `SettingsDetailView.swift` | default | `.settings` | Audio toggle, language select, logout |
| Appearance Editor | `AppearanceEditorDetailView.swift` | default | `.appearanceEditor` | Character skin/appearance customization |

### SPECIAL / UTILITY (4 screens + 1 dev)

| Screen | File | States | Route | Purpose |
|--------|------|--------|-------|---------|
| Session Summary | `SessionSummaryView.swift` | default | `.sessionSummary(characterId:)` | End-of-session stats, rewards summary |
| Session Expired Modal | `SessionExpiredModalView.swift` | default | — | Session expired warning (re-login required) |
| Screen Catalog | `ScreenCatalogView.swift` | dev only | `.screenCatalog` | Navigation to all screens (dev) |
| Design System Preview | `DesignSystemPreview.swift` | dev only | `.designSystem` | Color + component showcase |

---

## B. SCREEN STATES (Universal + Specific)

### Universal States (All Screens)
- **Default** — Normal rendered state
- **Loading** — Data fetching, spinner overlay
- **Empty** — No data (quests, inbox, inventory, leaderboard)
- **Error** — Network/server error with retry button
- **Disabled** — User lacks permission/resources
- **Success** — Action completed (toast feedback)
- **Selected** — Interactive selection state

### Screen-Specific States

| Screen | Unique States |
|--------|---|
| **Combat** | intro (3s), active, victory, defeat, forfeit confirmation, round animation |
| **Arena** | opponents list, revenge list, history list, opponent carousel swipe |
| **Inventory** | equipment tab, consumables tab, rarity filter, sort, equipped marker, compare mode |
| **Shop** | equipment tab, consumables tab, premium cosmetics tab, limited offer state |
| **Dungeon Select** | difficulty selection overlay, locked difficulty, recommended level badge |
| **Dungeon Room** | room encounter, boss encounter, loot, defeat/retry |
| **Battle Pass** | free season, active premium, next season coming, season ended, node states |
| **Daily Quests** | in-progress, completed (unclaimed), claimed, all-complete |
| **Achievements** | locked (0%), in-progress (1-99%), claimable (100%), claimed |
| **Daily Login** | not yet claimed, claimed, streak maintained, streak broken |
| **Leaderboard** | loading, list (sorted by rating/level/gold), player selected, detail sheet |
| **Inbox** | list (unread/read), message expanded, reply input, loading |
| **Guild Hall** | chat list, compose message, message detail, typing indicator, online status |

---

## C. REUSABLE COMPONENTS (85+)

### Theme-Level Components

| Component | File | Purpose | Variants |
|-----------|------|---------|----------|
| **Buttons** | `ButtonStyles.swift` | Button system | `.primary`, `.secondary`, `.danger`, `.success`, `.compact`, `.fight` |
| **Cards** | `CardStyles.swift` | Card container | `.panel`, `.highlighted`, `.info`, `.modal`, + 5 rarity variants |
| **Ornamental** | `OrnamentalStyles.swift` | Decorative UI | Dividers, corner brackets, diamonds, borders |
| **Progress Bars** | HP/XP/Stamina | Health, exp, stamina | 3 sizes: compact/widget/large |
| **Typography** | `DarkFantasyTheme` | Font system | 9 text styles |
| **Spacing** | `LayoutConstants` | Layout grid | 8 tokens |
| **Radius** | `LayoutConstants` | Corner radius | 5 tokens |

### Reusable UI Components (44)

**Cards & Profiles:**
- `HeroIntegratedCard.swift` — Character card (avatar, name, level, rating)
- `OpponentIntegratedCard.swift` — Opponent card (avatar, name, level, class)
- `UnifiedHeroWidget.swift` — Character widget (hub context)
- `BattleResultCardView.swift` — Combat result summary
- `PvPStatsWidget.swift` — PvP stats card (wins, rating, streak)

**Item & Equipment:**
- `ItemCardView.swift` — Unified item cell (inventory/shop/loot/all contexts)
- `ItemImageView.swift` — Item icon with rarity-colored border
- `CachedAssetImage.swift` — Asset image with caching

**Progress & Feedback:**
- `HPBarView.swift` — Health bar (green→amber→red)
- `XPBarView.swift` — Experience bar with progress
- `StaminaBarView.swift` — Stamina bar with recovery timer
- `NumberTickUpView.swift` — Animating number counter
- `ToastOverlayView.swift` — Toast notification system (7 types)
- `LoadingOverlay.swift` — Fullscreen loading spinner

**Badges & Pills:**
- `CardLevelBadge.swift` — Level indicator badge
- `StatPointsBadge.swift` — Unallocated stat points badge
- `WidgetPill.swift` — Stat display pill (damage, armor, rating)
- `CurrencyDisplay.swift` — Gold/gems amount with icon

**Images & Avatars:**
- `AvatarImageView.swift` — Character avatar with async loading + caching
- `AssetPlaceholderView.swift` — Asset image placeholder

**Information & Feedback:**
- `EmptyStateView.swift` — No data placeholder
- `ErrorStateView.swift` — Network/server error state
- `SkeletonViews.swift` — Loading placeholders (10 variants)
- `VictoryParticlesView.swift` — Particle confetti animation
- `RewardBurstView.swift` — Reward reveal animation
- `CoinFlyAnimationView.swift` — Coin fly-in effect

**Navigation & Layout:**
- `ScreenLayout.swift` — Standard screen wrapper
- `TabSwitcher.swift` — Multi-tab segment selector
- `OrnamentalTitle.swift` — Screen title with ornamental borders
- `ActiveQuestBanner.swift` — Floating quest type badges

**Modals & Overlays:**
- `LevelUpModalView.swift` — Level-up celebration modal
- `GuestGateView.swift` — Full-screen guest upgrade prompt
- `GuestNudgeBanner.swift` — Inline banner for guest upgrade
- `SessionExpiredModalView.swift` — Session timeout warning
- `OfflineBannerView.swift` — Network status indicator
- `LowHPPotionBanner.swift` — Warning when HP < 25% in combat

**Specialized Components:**
- `CelebrationBannerView.swift` — Milestone celebration overlay
- `EventBannerView.swift` — Event/promotion banner
- `NPCGuideWidget.swift` — NPC character card with dialogue
- `NPCHintOverlay.swift` — Tutorial hint bubble from NPC
- `InboxRowView.swift` — Mail list item
- `LeaderboardRowView.swift` — Leaderboard list item
- `StanceDisplayView.swift` — Current combat stance indicator

### Inline Components (in View files)

| Component | Location | Purpose |
|-----------|----------|---------|
| **FirstWinBonusCard** | `HubView.swift` | First win today bonus prompt |
| **BattleInviteBanner** | `HubView.swift` | Pending PvP challenge notification |
| **QuestRewardWidget** | `HubView.swift` | Unclaimed quest rewards indicator |
| **FloatingActionIcon** | `HubView.swift` | Circular floating button with badge |
| **HubLogoButton** | `ScreenLayout.swift` | Custom logo back button |
| **FloatingSoundToggle** | `HubView.swift` | Audio on/off toggle |
| **ComparisonRow** | `ArenaComparisonSheet.swift` | Stat comparison row |
| **DungeonBossCard** | `DungeonSelectDetailView.swift` | Boss preview card |
| **MerchantStripView** | `ShopDetailView.swift` | Merchant character with dialogue |
| **ShopOfferBannerView** | `ShopDetailView.swift` | Limited-time deal card |
| **DailyQuestsCard** | `DailyQuestsDetailView.swift` | Quest card in list |
| **DailyLoginCard** | `DailyLoginDetailView.swift` | Reward day card |
| **NavTile** | `TavernDetailView.swift` | Minigame navigation tile |
| **ChatBubbleShape** | `GuildHallDetailView.swift` | Message bubble shape |
| **FortuneWheelView** | `FortuneWheelDetailView.swift` | Spinning wheel visual |
| **DungeonMapBuildingView** | `DungeonMapView.swift` | Building tile on dungeon map |
| **CityBuildingView** | `CityMapView.swift` | Building tile on city hub |
| **CityBuildingLabel** | `CityMapView.swift` | Building label/overlay |
| **BattlePassCard** | `BattlePassDetailView.swift` | Season card |

---

## D. USER FLOWS

### 1. ONBOARDING FLOW
Welcome → Login/Register → Email Confirmation → Character Creation (Name → Class → Appearance) → Lore Intro → Hub

### 2. CHARACTER SELECTION FLOW
Hub (when 2+ heroes) → Character Selection → Select Hero → Hub Main

### 3. PVP COMBAT FLOW (Main)
Hub → Arena → Opponent Selection (Carousel) → Arena Comparison (optional) → Combat → Combat Result → Loot → Back to Hub

### 4. PVP REVENGE FLOW
Hub → Arena (Revenge tab) → Past opponent list → Combat → Combat Result → Back

### 5. DUNGEON FLOW (PvE)
Hub → Dungeon Select → Difficulty Selection → Dungeon Room (1..N rooms) → Boss Room → Combat → Dungeon Victory → Loot → Back to Hub OR Dungeon Defeat → Optional Retry

### 6. INVENTORY MANAGEMENT FLOW
Hub → Hero tab → Inventory → View Item Detail → Equip/Sell → Back OR Hub → Hero tab → Status → View Character Stats → Allocate Stat Points

### 7. EQUIPMENT SHOP FLOW
Hub → City Map (Shop building) → Shop → Equipment Tab → Item Detail → Purchase → Back OR Currency Purchase → Buy Gold/Gems → Back

### 8. PROGRESSION FLOW
Hub → Daily Login → Claim Streak Rewards → Back OR Hub → Daily Quests → View Quests → Complete Quest → Claim Reward → Back OR Hub → Achievements → View Achievements → Claim Progress → Back

### 9. LEADERBOARD FLOW
Hub → Leaderboard → Select Tab (Rating/Level/Gold) → View Rank → Player Detail (optional) → Challenge Player → Combat

### 10. SOCIAL MESSAGING FLOW
Hub → Inbox → View Messages → Read/Reply → Back OR Hub → Guild Hall → Chat List → Start Conversation → Send Message → Back

### 11. MINIGAMES FLOW
Hub → City Map (Tavern) → Tavern Hub → Select Minigame:
- **Gold Mine:** Collect Gold → Back
- **Shell Game:** Bet Gold → Guess Cup → Result → Back
- **Dungeon Rush:** Wave Combat → Shopping (between waves) → Result → Back
- **Fortune Wheel:** Spin → Claim Reward → Back

### 12. SETTINGS FLOW
Hub → Settings → Toggle Audio → Select Language → View Account Info → Logout

### 13. CHARACTER CUSTOMIZATION FLOW
Hub → Appearance Editor → Select Skin → Apply → Back

### 14. SESSION SUMMARY FLOW
Combat → Result → (Session ends) → Session Summary (stats recap, streak info) → Back to Hub

---

## E. MODAL / SHEET / OVERLAY SYSTEM

### Sheet Modals (`.sheet()`)

| Modal | File | Trigger | Content |
|-------|------|---------|---------|
| Daily Login | `DailyLoginPopupView.swift` | Auto-triggered on hub entry (first time daily) | Streak display, claim button |
| Item Detail | `ItemDetailSheet.swift` | Tap item in inventory/shop | Item stats, equip/sell actions |
| Arena Comparison | `ArenaComparisonSheet.swift` | Tap "Compare" on opponent | Side-by-side stat comparison |
| Dungeon Info | `DungeonInfoSheet.swift` | Tap "Info" on dungeon select | Lore, rewards, difficulty info |
| Loot Preview | `LootPreviewSheet.swift` | Pre-dungeon entry | Potential rewards display |
| Boss Detail | `BossDetailSheet.swift` | Tap boss on dungeon map | Boss stats, abilities, lore |
| Leaderboard Player Detail | `LeaderboardPlayerDetailSheet.swift` | Tap player in leaderboard | Profile stats, challenge button |

### Full-Screen Overlays

| Overlay | File | Trigger | Content |
|---------|------|---------|---------|
| Loading Overlay | `LoadingOverlay.swift` | Data fetching, auth, combat start | Spinner with dark backdrop |
| Session Expired Modal | `SessionExpiredModalView.swift` | Session timeout | Re-login prompt |
| Level Up Modal | `LevelUpModalView.swift` | Character reaches new level | Cinematic celebration |
| Rank Up Ceremony | `RankUpCeremonyView.swift` | PvP rating increases (milestone) | Full-screen cinematic |
| Season Summary Modal | `SeasonSummaryModalView.swift` | Battle Pass season ends | Season recap, next season preview |
| Celebration Banner | `CelebrationBannerView.swift` | Milestone events | Toast-like top banner |
| VFX Overlay | `CombatVFXOverlay.swift` | Combat active | Particle effects |
| NPC Hint Overlay | `NPCHintOverlay.swift` | Tutorial trigger | NPC dialogue bubble |
| Toast Overlay | `ToastOverlayView.swift` | Action feedback | Small notification |
| Guest Gate | `GuestGateView.swift` | Guest tries restricted feature | Full-screen upgrade prompt |

### Inline Banners

| Banner | File | Trigger | Content |
|--------|------|---------|---------|
| Guest Nudge Banner | `GuestNudgeBanner.swift` | Guest in inventory | Small upgrade prompt |
| Offline Banner | `OfflineBannerView.swift` | Network offline | Connection status |
| Low HP Potion Banner | `LowHPPotionBanner.swift` | Combat HP < 25% | Use potion prompt |
| Battle Invite Banner | (HubView) | Pending PvP challenges | Challenge notification |
| Active Quest Banner | `ActiveQuestBanner.swift` | In-progress quest | Quest type indicator |
| First Win Bonus | (HubView) | First win available today | Bonus preview |
| Quest Reward Widget | (HubView) | Unclaimed quest rewards | Reward preview |
| Shop Offer Banner | `ShopOfferBannerView.swift` | Limited-time deal active | Deal countdown |
| Event Banner | `EventBannerView.swift` | Event active | Event details |

---

## F. NAVIGATION ARCHITECTURE

### Tab-Based Navigation (Bottom Tabs)

**HubTab Enum** (3 tabs, mutually exclusive):
- `.hub (0)` → HubView (main home with dungeon map access)
- `.arena (1)` → ArenaDetailView (PvP arena)
- `.hero (2)` → HeroDetailView (character equipment & stats)

### Route-Based Navigation (AppRoute)

**37 Routes** handled by MainRouterView + AuthRouterView:

**Auth Routes:**
`.login`, `.register`, `.onboarding`, `.characterSelection`, `.upgradeGuest`

**Main Routes:**
- Hub: `.hub`, `.hero`, `.stanceSelector`
- Combat: `.combat`, `.combatResult`, `.loot`
- Arena: `.arena`
- Shop: `.shop`, `.currencyPurchase`, `.premiumPurchase`
- Dungeon: `.dungeonMap`, `.dungeonSelect`, `.dungeonRoom`
- Social: `.guildHall`, `.guildHallMessage(...)`, `.characterProfile(...)`
- Minigames: `.tavern`, `.shellGame`, `.fortuneWheel`, `.goldMine`, `.dungeonRush`
- Progression: `.inbox`, `.dailyLogin`, `.dailyQuests`, `.achievements`, `.leaderboard`, `.battlePass`
- Misc: `.sessionSummary(...)`, `.settings`, `.appearanceEditor`, `.tutorial`
- Dev: `.screenCatalog`, `.designSystem`, `.hubEditor`, `.dungeonMapEditor` (DEBUG only)

### AppState Screen States

```
enum AppScreen {
    case auth                          → AuthRouterView
    case characterSelect               → CharacterSelectionView
    case loreIntro(heroName: String)  → LoreIntroView
    case game                          → MainRouterView (with 3 tabs)
}
```

---

## G. MISSING / EXTRACTABLE PATTERNS

### Inline Patterns Used 2+ Times (Candidates for Extraction)

| Pattern | Current Locations | Recommendation |
|---------|------------------|-----------------|
| **Stat comparison row** | ArenaComparisonSheet, ItemDetailSheet, CharacterProfileView | Extract → `StatComparisonRow.swift` |
| **Difficulty badge** | DungeonSelectDetailView, BossDetailSheet | Extract → `DifficultyBadge.swift` |
| **Message bubble** | GuildHallDetailView | Extract → `ChatMessageBubble.swift` |
| **Status effect indicator** | CombatDetailView, character stat sheet | Extract → `StatusEffectIndicator.swift` |
| **Reward box (gold/gems/item)** | CombatResult, Loot, Quest rewards | Extract → `RewardBox.swift` |
| **Rating badge** | Arena, Leaderboard, Character profiles | Extract → `RatingBadge.swift` |

---

## H. COMPONENT BREAKDOWN BY FUNCTION

### Cards (7 types)
- Item card (`ItemCardView`)
- Character card (`UnifiedHeroWidget`, `HeroIntegratedCard`)
- Opponent card (`OpponentCardView`, `ArenaOpponentCard`)
- Dungeon/Boss card (`DungeonBossCard`)
- Battle result card (`BattleResultCardView`)
- Achievement card (`AchievementCardView`)
- Quest card (inline in `DailyQuestsDetailView`)

### Progress Displays (5 types)
- HP bar (`HPBarView`)
- XP bar (`XPBarView`)
- Stamina bar (`StaminaBarView`)
- Battle Pass node progress (inline in `BPRewardNodeView`)
- Quest progress (inline)

### Buttons (6 styles)
- Primary (gold CTA)
- Secondary (neutral)
- Danger (destructive)
- Success (positive)
- Compact (small)
- Fight (orange combat CTA)

### Badges (8 types)
- Level badge (`CardLevelBadge`)
- Rarity border (on items)
- Stat points badge (`StatPointsBadge`)
- Difficulty badge (inline)
- Rating badge (inline)
- Class pill (`WidgetPill`)
- Status effect indicator (inline)
- Equipped indicator (inline)

### Animations (6 types)
- Number tick-up (`NumberTickUpView`)
- Particle confetti (`VictoryParticlesView`)
- Coin fly (`CoinFlyAnimationView`)
- Shimmer loading (`ShimmerModifier`)
- Reward burst (`RewardBurstView`)
- VFX effects (in `CombatVFXOverlay`)

### Informational (5 types)
- Empty state (`EmptyStateView`)
- Error state (`ErrorStateView`)
- Loading spinner (`LoadingOverlay`)
- Toast notification (`ToastOverlayView`)
- NPC hint overlay (`NPCHintOverlay`)

---

## I. SUMMARY STATISTICS

| Metric | Count |
|--------|-------|
| **Primary Screens** | 48 |
| **Modal/Sheet/Overlay Screens** | 28 |
| **Total Unique Screen States** | 150+ |
| **Reusable Components** | 85+ |
| **Navigation Routes** | 37 |
| **Button Styles** | 6 primary, 20+ variants in Figma |
| **Card Variants** | 14 (item, character, opponent, battle, achievement, etc.) |
| **Badge Types** | 8 (level, rarity, stat points, difficulty, rating, class, status, equipped) |
| **Progress Bar Types** | 3 (HP, XP, Stamina) × 3 sizes = 9 |
| **Toast Types** | 7 (success, error, info, warning, gold, gems, xp) |
| **Skeleton Variants** | 10 (rectangle, card, item cell, achievement, quest, etc.) |
| **Font Sizes** | 9 (11pt to 40pt across 2 families) |
| **Spacing Tokens** | 8 (2px to 48px) |
| **Color Tokens (Semantic)** | 158 |
| **Swift View Files** | 159 |
| **Component Pages in Figma** | 21 |

---

## J. IMPLEMENTATION PRIORITY FOR FIGMA

### Tier 1 (Highest Impact)
1. Complete all primary screens (48)
2. All modal/sheet states (28)
3. Button variants (6 styles × 18+ states each)
4. Card system (item, character, opponent with all rarity states)
5. Progress bars (HP, XP, Stamina × 3 sizes)

### Tier 2 (High Impact)
6. Badge system (level, rarity, stat points, class, rating)
7. Toast notification system (7 types with animations)
8. Skeleton loading placeholders (10 variants)
9. State overlays (loading, error, empty)
10. All hero/opponent profile cards

### Tier 3 (Medium Impact)
11. Minigame screens (4 games + tavern hub)
12. Social messaging UI (guild hall, inbox)
13. Settings/customization screens
14. Combat VFX system (design reference for animations)

### Tier 4 (Design Polish)
15. All banner variants (guest nudge, quest, event, shop offer)
16. NPC dialogue/hint overlays
17. Achievement/quest card variants
18. Battle Pass reward node states

---

END OF AUDIT
