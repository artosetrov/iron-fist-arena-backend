# Hexbound — Screen Inventory (Source of Truth)

*Derived from iOS app code. Updated: 2026-04-04*

## Summary

**Total screens**: 70+ Swift views (46 in Figma Screens, 15 missing)
**Architecture**: NavigationStack + AppRouter enum routing (28 routes, 3 bottom tabs: Hub, Arena, Hero)
**Pattern**: @MainActor @Observable ViewModels
**Figma Screens file**: [Hexbound-Design](https://www.figma.com/design/PalemJ36B97ZdC0cd8jzv4/Hexbound-Design)

---

## Auth Flow (6 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Welcome | `WelcomeView.swift` | default, loading | Entry point: login/register/guest |
| Login | `LoginView.swift` | default, loading, error | Email/password authentication |
| Register | `RegisterDetailView.swift` | default, loading, error | Account creation |
| Character Creation | `OnboardingDetailView.swift` | name, class, origin, gender, appearance | New character setup (multi-step: NameStepView → ClassSelectionStepView → AppearanceStepView) |
| Email Confirmation | `EmailConfirmationView.swift` | waiting, confirmed, error | Email verification |
| Upgrade Guest | `UpgradeGuestView.swift` | default, loading, error | Guest → full account conversion |

## Hub / Home (8 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Hub | `HubView.swift` | default, loading | Main home: stamina bar, character card, city map, floating buttons |
| Hero Detail | `HeroDetailView.swift` | INVENTORY tab, STATUS tab, stat points banner | Character equipment (INVENTORY tab via HeroIntegratedCard), Repair Equipment widget (mass repair all damaged equipped items), stats & stat allocation (STATUS tab), stance display |
| City Map | `CityMapView.swift` | default | Interactive hub map with buildings |
| City Building | `CityBuildingView.swift` | default | Individual building on city map (with `CityBuildingConfig`, `CityBuildingLabel`) |
| City Map Effects | `CityMapEffects.swift` | — | Ambient particle/glow effects on city map |
| Hub Editor | `HubEditorDetailView.swift` | default | Hub layout customization |
| Stance Selector | `StanceSelectorDetailView.swift` | default | Combat stance (attack/defense zone) selection |

## Arena / PvP (5 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Arena | `ArenaDetailView.swift` | opponents, revenge, history tabs; loading, empty, list | PvP opponent selection |
| Arena Carousel | `ArenaCarouselView.swift` | default | Swipeable opponent carousel |
| Arena Comparison | `ArenaComparisonSheet.swift` | default | Stat comparison vs opponent |
| Opponent Card | `OpponentCardView.swift` | default, pressed, fighting | Opponent card with fight button |
| Arena Opponent Card | `ArenaOpponentCard.swift` | default | Arena-specific opponent card variant |

## Combat (4 screens + VFX system)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Combat | `CombatDetailView.swift` | intro, active, victory, defeat | Active combat with log and VFX |
| Combat Result | `CombatResultDetailView.swift` | win, loss | Victory/defeat summary with loot |
| Loot | `LootDetailView.swift` | default, empty | Item rewards display |
| VFX Overlay | `CombatVFXOverlay.swift` | — | Particle effects during combat |

### VFX Sub-system (`Views/Combat/VFX/`)
| File | Purpose |
|------|---------|
| `CombatVFXEffect.swift` | Effect type definitions |
| `CombatVFXManager.swift` | Effect queue & orchestration |
| `CombatVFXOverlay.swift` | Overlay rendering layer |
| `DamageHitEffects.swift` | Damage/hit visual effects |
| `DodgeMissBlock.swift` | Dodge, miss, block animations |
| `HealEffect.swift` | Heal animation |
| `StatusVFXEffects.swift` | Status effect visuals (poison, stun, etc.) |

## Inventory (2 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Inventory | `InventoryViewModel.swift` | equipment, consumables tabs; loading, empty, search | Item management |
| Item Detail | `ItemDetailSheet.swift` | default | Item stats, equip/sell actions |

## Shop (4 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Shop | `ShopDetailView.swift` | equipment, consumables, premium tabs | Purchase items/consumables |
| Shop Offer Banner | `ShopOfferBannerView.swift` | default, active, expired | Limited-time offer banners (daily deal, flash sale) |
| Currency Purchase | `CurrencyPurchaseView.swift` | default | Buy gold/gems via IAP |
| Premium Purchase | `PremiumPurchaseView.swift` | default | Premium/cosmetic items |

### Shop Sub-components
| File | Purpose |
|------|---------|
| `ItemCardView.swift` | Unified item card (shop/inventory/loot contexts) |

## Dungeons (7 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Dungeon Select | `DungeonSelectDetailView.swift` | default, loading | Pick dungeon + difficulty |
| Dungeon Info | `DungeonInfoSheet.swift` | default | Dungeon details sheet (lore, rewards, difficulty info) |
| Dungeon Room | `DungeonRoomDetailView.swift` | room, boss, loot | Room-by-room progression |
| Dungeon Map | `DungeonMapView.swift` | default | Visual dungeon map with room nodes |
| Boss Detail | `BossDetailSheet.swift` | default | Boss stats, abilities, lore |
| Dungeon Victory | `DungeonVictoryView.swift` | default | Victory with loot display |
| Dungeon Defeat | `DungeonDefeatView.swift` | default | Defeat screen with retry option |
| Loot Preview | `LootPreviewSheet.swift` | default | Pre-battle loot preview sheet |

## Minigames (5 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Gold Mine | `GoldMineDetailView.swift` | idle, mining, ready, collecting | Passive gold generation |
| Shell Game | `ShellGameDetailView.swift` | betting, playing, result | 3-cup guessing game |
| Dungeon Rush | `DungeonRushDetailView.swift` | fighting, shopping, result | Wave-based boss rush |
| Tavern | `TavernDetailView.swift` | default | Tavern activity hub |
| Fortune Wheel | `FortuneWheelDetailView.swift` | betting, spinning, result | Fortune wheel minigame |

## Quests & Progression (7 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Daily Quests | `DailyQuestsDetailView.swift` | loading, list, all-complete | Quest list + completion |
| Daily Login | `DailyLoginDetailView.swift` | default, claiming | Streak reward calendar |
| Daily Login Popup | `DailyLoginPopupView.swift` | default, claiming, claimed | Auto-popup on login with streak animation |
| Achievements | `AchievementsDetailView.swift` | loading, list | Achievement list + claim |
| Achievement Card | `AchievementCardView.swift` | locked, in-progress, claimable, claimed | Individual achievement row |
| Battle Pass | `BattlePassDetailView.swift` | free, premium tracks | Seasonal reward tree (with `BPRewardNodeView` nodes) |
| Season Summary | `SeasonSummaryModalView.swift` | default | End-of-season stats recap |

## Leaderboard & Social (3 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Leaderboard | `LeaderboardDetailView.swift` | rating, level, gold tabs | Global rankings (with `LeaderboardRowView` rows) |
| Leaderboard Player Detail | `LeaderboardPlayerDetailSheet.swift` | default | Player profile sheet from leaderboard |
| Inbox | `InboxDetailView.swift` | loading, list, empty, detail | Mail messages (with `InboxRowView` rows) |
| Guild Hall | `GuildHallDetailView.swift` | default, loading | Guild management & social |

## Settings & Profile (4 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Settings | `SettingsDetailView.swift` | default | Audio, language, account |
| Appearance Editor | `AppearanceEditorDetailView.swift` | default | Skin/avatar customization |
| Character Profile | `CharacterProfileView.swift` | default | Full character stats view |
| Session Summary | `SessionSummaryView.swift` | default | End-of-session stats recap |

## Tutorial (1 screen)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Tutorial | `TutorialView.swift` | step-by-step | Guided onboarding tutorial with NPC guide |

## Debug Only (2 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Screen Catalog | `ScreenCatalogView.swift` | — | Nav to all screens (dev) |
| Design System Preview | `DesignSystemPreview.swift` | — | Color + component showcase |

---

## Reusable Components (`Views/Components/`)

| Component | File | Purpose |
|-----------|------|---------|
| `ActiveQuestBanner` | `ActiveQuestBanner.swift` | Quest type indicators in Hub |
| `AvatarImageView` | `AvatarImageView.swift` | Character avatar with async loading + caching |
| `BattleResultCardView` | `BattleResultCardView.swift` | Combat result summary card (win/loss/rewards) |
| `CurrencyDisplay` | `CurrencyDisplay.swift` | Gold/gems amount display with icon |
| `GuestGateView` | `GuestGateView.swift` | Full-screen guest upgrade prompt |
| `GuestNudgeBanner` | `GuestNudgeBanner.swift` | Inline banner prompting guest → full account |
| `HPBarView` | `HPBarView.swift` | Health bar (green→amber→red gradient) |
| `ItemImageView` | `ItemImageView.swift` | Item icon with rarity-colored border |
| `LevelUpModalView` | `LevelUpModalView.swift` | Level-up celebration modal |
| `LoadingOverlay` | `LoadingOverlay.swift` | Fullscreen loading spinner |
| `OfflineBannerView` | `OfflineBannerView.swift` | Network status indicator banner |
| `ScreenLayout` | `ScreenLayout.swift` | Standard screen wrapper (also contains `HubLogoButton`) |
| `SkeletonViews` | `SkeletonViews.swift` | Loading placeholder cards |
| `StaminaBarView` | `StaminaBarView.swift` | Stamina bar with recovery timer |
| `TabSwitcher` | `TabSwitcher.swift` | Multi-tab segment selector |
| `ToastOverlayView` | `ToastOverlayView.swift` | Notification toasts (7 types: success, error, info, warning, gold, gems, xp) |
| `VictoryParticlesView` | `VictoryParticlesView.swift` | Particle confetti for victory screens |

### Theme-Level Components (`Theme/CardStyles.swift`)

| Component | Purpose |
|-----------|---------|
| `panelCard()` | View modifier — styled card with padding/border/shadow |
| `GoldDivider()` | Ornamental gold separator line |

### Embedded Components (not separate files)

| Component | Location | Purpose |
|-----------|----------|---------|
| `FloatingActionIcon` | `HubView.swift` | Round floating button with badge (shop, mail, etc.) |
| `HubLogoButton` | `ScreenLayout.swift` | Custom logo navigation button |
| `HubCharacterCard` | `HubCharacterCard.swift` | Hub character summary card |
| `ItemCardView` | `ItemCardView.swift` | Unified item card (inventory/shop/loot) |
| `NPCGuideWidget` | `NPCGuideWidget.swift` | Reusable NPC speech card + mini button |
| `HeroIntegratedCard` | `HeroIntegratedCard.swift` | Equipment grid with portrait |
| `OpponentIntegratedCard` | `OpponentIntegratedCard.swift` | Opponent equipment grid |
| `UnifiedHeroWidget` | `UnifiedHeroWidget.swift` | Compact hero HP/XP/Stamina widget |
| `PvPStatsWidget` | `PvPStatsWidget.swift` | Arena stats summary widget |
| `InlineFeedback` | `InlineFeedback.swift` | Floating text, flash border, checkmark feedback |
| `WidgetPill` | `WidgetPill.swift` | Hub navigation pills |
| `CardLevelBadge` | `CardLevelBadge.swift` | Level badge overlay on cards |
| `GlassStatPill` | `GlassStatPill.swift` | Glass morphism stat indicator |
| `ClassTagView` | `ClassTagView.swift` | Character class tag badge |
| `StatPointsBadge` | `StatPointsBadge.swift` | Available stat points indicator |
| `OrnamentalTitle` | `OrnamentalTitle.swift` | Screen/section title with ornaments |
| `EventBannerView` | `EventBannerView.swift` | Limited-time event banner |
| `CelebrationBannerView` | `CelebrationBannerView.swift` | Victory/achievement celebration |
| `LowHPPotionBanner` | `LowHPPotionBanner.swift` | Low HP warning with potion CTA |
| `SessionExpiredModalView` | `SessionExpiredModalView.swift` | Session timeout modal |

---

## Figma Screen Coverage (Gap Analysis)

*Updated: 2026-04-04*

**In Figma Screens (46):** Hub, Arena, Hero Detail, Dungeon Select, Dungeon Room, Dungeon Victory, Tavern, Gold Mine, Dungeon Rush, Combat Active, Combat Result Victory/Defeat, Shop, Inventory, Inventory Empty, Daily Quests, Daily Quests Empty, Daily Login, Achievements, Battle Pass, Leaderboard, Leaderboard Player Detail, Leaderboard Loading, Character Creation, Character Profile, Appearance Editor, Stance Selector, Fortune Wheel, Shell Game, Top Bar, Item Detail Sheet, Dungeon Info Sheet, Level Up Modal, Guest Gate, Session Expired, Arena Comparison, Currency Purchase, Rank Up Ceremony, Welcome, Login, Register, Email Confirmation, Upgrade Guest, Arena Loading, Shop Loading, Server Error.

**Missing from Figma (15 screens):**

| Priority | Screen | Swift File | Notes |
|----------|--------|-----------|-------|
| P0 | Guild Hall | `GuildHallDetailView.swift` | New feature, needs full design |
| P0 | Tutorial | `TutorialView.swift` | Onboarding flow, critical for new users |
| P0 | Settings | `SettingsDetailView.swift` | Standard screen, straightforward |
| P0 | Inbox Detail | `InboxDetailView.swift` | Mail system UI |
| P1 | Session Summary | `SessionSummaryView.swift` | End-of-session recap |
| P1 | Loot (Combat) | `LootDetailView.swift` | Post-combat reward display |
| P1 | Dungeon Map | `DungeonMapView.swift` | Visual room navigation |
| P1 | Dungeon Defeat | `DungeonDefeatView.swift` | Defeat + retry screen |
| P1 | Premium Purchase | `PremiumPurchaseView.swift` | IAP cosmetics store |
| P1 | Boss Detail | `BossDetailSheet.swift` | Boss info sheet |
| P1 | Loot Preview | `LootPreviewSheet.swift` | Pre-battle loot preview |
| P2 | City Map | `CityMapView.swift` | Hub building map (interactive) |
| P2 | Daily Login Popup | `DailyLoginPopupView.swift` | Auto-popup variant |
| P2 | Season Summary | `SeasonSummaryModalView.swift` | End-of-season modal |
| P2 | Lore Intro | `LoreIntroView.swift` | Auth flow narrative intro |
