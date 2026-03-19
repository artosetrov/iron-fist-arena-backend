# Hexbound — Screen Inventory (Source of Truth)

*Derived from iOS app code. Updated: 2026-03-19*

## Summary

**Total screens**: 38+ (24 primary + 14 overlays/sheets/sub-views)
**Architecture**: NavigationStack + AppRouter enum routing (28 routes, 3 bottom tabs: Hub, Arena, Hero)
**Pattern**: @MainActor @Observable ViewModels

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
| Character Detail | `CharacterDetailView.swift` | default, editing | Stats, equipment, appearance, stat allocation/respec |
| Hero Detail | `HeroDetailView.swift` | default | Character profile info |
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
| `ShopItemCardView.swift` | Individual shop item card |

## Dungeons (5 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Dungeon Select | `DungeonSelectDetailView.swift` | default, loading | Pick dungeon + difficulty |
| Dungeon Info | `DungeonInfoSheet.swift` | default | Dungeon details sheet (lore, rewards, difficulty info) |
| Dungeon Room | `DungeonRoomDetailView.swift` | room, boss, loot | Room-by-room progression |
| Dungeon Victory | `DungeonVictoryView.swift` | default | Victory with loot display |
| Loot Preview | `LootPreviewSheet.swift` | default | Pre-battle loot preview sheet |

## Minigames (4 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Gold Mine | `GoldMineDetailView.swift` | idle, mining, ready, collecting | Passive gold generation |
| Shell Game | `ShellGameDetailView.swift` | betting, playing, result | 3-cup guessing game |
| Dungeon Rush | `DungeonRushDetailView.swift` | fighting, shopping, result | Wave-based boss rush |
| Tavern | `TavernDetailView.swift` | default | Tavern activity hub |

## Quests & Progression (6 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Daily Quests | `DailyQuestsDetailView.swift` | loading, list, all-complete | Quest list + completion |
| Daily Login | `DailyLoginDetailView.swift` | default, claiming | Streak reward calendar |
| Daily Login Popup | `DailyLoginPopupView.swift` | default, claiming, claimed | Auto-popup on login with streak animation |
| Achievements | `AchievementsDetailView.swift` | loading, list | Achievement list + claim |
| Achievement Card | `AchievementCardView.swift` | locked, in-progress, claimable, claimed | Individual achievement row |
| Battle Pass | `BattlePassDetailView.swift` | free, premium tracks | Seasonal reward tree (with `BPRewardNodeView` nodes) |

## Leaderboard & Social (2 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Leaderboard | `LeaderboardDetailView.swift` | rating, level, gold tabs | Global rankings (with `LeaderboardRowView` rows) |
| Inbox | `InboxDetailView.swift` | loading, list, empty, detail | Mail messages (with `InboxRowView` rows) |

## Settings & Profile (3 screens)

| Screen | View File | States | Purpose |
|--------|-----------|--------|---------|
| Settings | `SettingsDetailView.swift` | default | Audio, language, account |
| Appearance Editor | `AppearanceEditorDetailView.swift` | default | Skin/avatar customization |
| Profile | implicit via hub | — | Character stats overlay |

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
| `ItemCardView` | `ItemCardView.swift` | Inventory grid item card |
