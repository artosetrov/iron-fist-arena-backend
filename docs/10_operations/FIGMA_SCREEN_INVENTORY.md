# Hexbound Screen Inventory For Figma

Дата подготовки: 2026-03-12

## Обозначения

- `Primary`: основной экран или page template
- `Variant`: состояние того же экрана
- `Overlay`: popup, modal, toast, loading state
- `Embedded`: вложенный экраноподобный блок внутри основного flow

## Mobile app

### Auth

| Screen | Type | States for Figma | Source |
| --- | --- | --- | --- |
| Login | Primary | default, loading, error, reset-password alert | `Hexbound/Hexbound/Views/Auth/LoginView.swift` |
| Register | Primary | default, loading, error, success, email-confirmation | `Hexbound/Hexbound/Views/Auth/RegisterDetailView.swift` |
| Onboarding / Class | Variant | default, selected class, previous-complete state | `Hexbound/Hexbound/Views/Auth/OnboardingDetailView.swift` |
| Onboarding / Appearance | Variant | loading skins, avatar selection, gender switch | `Hexbound/Hexbound/Views/Auth/OnboardingDetailView.swift` |
| Onboarding / Name | Variant | default, validation error, save/loading | `Hexbound/Hexbound/Views/Auth/OnboardingDetailView.swift` |

### Hub and hero

| Screen | Type | States for Figma | Source |
| --- | --- | --- | --- |
| Hub | Primary | default, first-win bonus visible, daily-login badge active | `Hexbound/Hexbound/Views/Hub/HubView.swift` |
| Hero / Inventory tab | Primary | equipped state, item detail open | `Hexbound/Hexbound/Views/Hero/HeroDetailView.swift` |
| Hero / Status tab | Variant | no points, stat-points available, respec confirm | `Hexbound/Hexbound/Views/Hero/HeroDetailView.swift` |
| Hero / Stat allocation | Variant | no changes, stat-points banner, dirty state with save/reset | `Hexbound/Hexbound/Views/Hero/HeroDetailView.swift` |
| Stance selector | Primary | attack selected, defense selected, dirty save state | `Hexbound/Hexbound/Views/Hub/StanceSelectorDetailView.swift` |
| Appearance editor | Primary | loading skins, normal editing, race-change warning, save disabled, save loading | `Hexbound/Hexbound/Views/Profile/AppearanceEditorDetailView.swift` |

### Arena and combat

| Screen | Type | States for Figma | Source |
| --- | --- | --- | --- |
| Arena / Opponents | Primary | loading skeleton, empty, list, fighting button state | `Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift` |
| Arena / Revenge | Variant | loading skeleton, empty, list | `Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift` |
| Arena / History | Variant | loading, empty, populated list | `Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift` |
| Combat | Primary | intro/preparation, active turn, damage popups, victory, defeat | `Hexbound/Hexbound/Views/Combat/CombatDetailView.swift` |
| Combat result | Primary | win, loss, level-up triggered | `Hexbound/Hexbound/Views/Combat/CombatResultDetailView.swift` |
| Loot | Primary | single reward, multiple rewards, continue CTA | `Hexbound/Hexbound/Views/Combat/LootDetailView.swift` |

### Inventory and shop

| Screen | Type | States for Figma | Source |
| --- | --- | --- | --- |
| Inventory (Hero INVENTORY tab) | Primary | loading skeleton, filled grid, empty slots, item detail open, expand inventory CTA | `Hexbound/Hexbound/Views/Hero/HeroDetailView.swift` |
| Item Detail Sheet | Primary | item stats, equip/sell/repair actions, comparison | `Hexbound/Hexbound/Views/Inventory/ItemDetailSheet.swift` |
| Shop / All | Primary | loading skeleton, sectioned content, item detail open | `Hexbound/Hexbound/Views/Shop/ShopDetailView.swift` |
| Shop / Weapons | Variant | filtered grid, buying state | `Hexbound/Hexbound/Views/Shop/ShopDetailView.swift` |
| Shop / Equipment | Variant | filtered grid, level locked, cannot afford | `Hexbound/Hexbound/Views/Shop/ShopDetailView.swift` |
| Shop / Potions | Variant | consumables grid, item detail open | `Hexbound/Hexbound/Views/Shop/ShopDetailView.swift` |
| Currency purchase / Gold | Primary | package list, purchasing, success overlay, error toast | `Hexbound/Hexbound/Views/Shop/CurrencyPurchaseView.swift` |
| Currency purchase / Gems | Variant | package list, best value, popular, success overlay | `Hexbound/Hexbound/Views/Shop/CurrencyPurchaseView.swift` |

Note: `CurrencyPurchaseView.swift` already exists in code, even though current router path for `currencyPurchase` is not yet wired as a separate screen.

### Dungeon and minigames

| Screen | Type | States for Figma | Source |
| --- | --- | --- | --- |
| Dungeon select | Primary | loading skeleton, dungeon list, locked progress | `Hexbound/Hexbound/Views/Dungeon/DungeonSelectDetailView.swift` |
| Dungeon room | Primary | loading, active run, locked boss, fight in progress | `Hexbound/Hexbound/Views/Dungeon/DungeonRoomDetailView.swift` |
| Dungeon victory | Embedded | animated reveal: title, rewards, progress, buttons | `Hexbound/Hexbound/Views/Dungeon/DungeonVictoryView.swift` |
| Tavern | Primary | game hub cards for Shell Game, Gold Mine, Dungeon Rush | `Hexbound/Hexbound/Views/Minigames/TavernDetailView.swift` |
| Shell game | Primary | pre-bet, playing, cup selected, reveal win, reveal loss | `Hexbound/Hexbound/Views/Minigames/ShellGameDetailView.swift` |
| Gold mine | Primary | loading, active slots, ready-to-collect, idle, locked slot for purchase | `Hexbound/Hexbound/Views/Minigames/GoldMineDetailView.swift` |
| Dungeon rush / Start | Primary | idle start screen, loading start | `Hexbound/Hexbound/Views/Minigames/DungeonRushDetailView.swift` |
| Dungeon rush / Active | Variant | room progress, HP low/high, buffs, room events | `Hexbound/Hexbound/Views/Minigames/DungeonRushDetailView.swift` |
| Dungeon rush / Overlay shop | Overlay | shop between rooms | `Hexbound/Hexbound/Views/Minigames/DungeonRushDetailView.swift` |
| Dungeon rush / Event result | Overlay | event resolution, treasure result | `Hexbound/Hexbound/Views/Minigames/DungeonRushDetailView.swift` |
| Dungeon rush / Game over | Variant | failure, summary, exit CTA | `Hexbound/Hexbound/Views/Minigames/DungeonRushDetailView.swift` |

### Progression and meta

| Screen | Type | States for Figma | Source |
| --- | --- | --- | --- |
| Daily login | Primary | loading, can claim, already claimed | `Hexbound/Hexbound/Views/DailyLogin/DailyLoginDetailView.swift` |
| Daily quests | Primary | loading skeleton, bonus locked, bonus claimable, bonus claimed | `Hexbound/Hexbound/Views/Quests/DailyQuestsDetailView.swift` |
| Achievements / Combat | Primary | loading skeleton, list, empty, claimable state | `Hexbound/Hexbound/Views/Achievements/AchievementsDetailView.swift` |
| Achievements / Other tabs | Variant | Progress, Collect, Dungeon, Economy, Rank | `Hexbound/Hexbound/Views/Achievements/AchievementsDetailView.swift` |
| Leaderboard / Rating | Primary | loading, populated list, self highlighted | `Hexbound/Hexbound/Views/Leaderboard/LeaderboardDetailView.swift` |
| Leaderboard / Level | Variant | same shell, alternate metric | `Hexbound/Hexbound/Views/Leaderboard/LeaderboardDetailView.swift` |
| Leaderboard / Gold | Variant | same shell, alternate metric | `Hexbound/Hexbound/Views/Leaderboard/LeaderboardDetailView.swift` |
| Battle pass | Primary | loading skeleton, free track, premium upsell, claim state | `Hexbound/Hexbound/Views/BattlePass/BattlePassDetailView.swift` |
| Settings | Primary | audio, notifications, language, account actions | `Hexbound/Hexbound/Views/Settings/SettingsDetailView.swift` |
| Settings / Logout alert | Overlay | confirm logout | `Hexbound/Hexbound/Views/Settings/SettingsDetailView.swift` |
| Settings / Delete account alert | Overlay | destructive confirmation with input | `Hexbound/Hexbound/Views/Settings/SettingsDetailView.swift` |

### Global overlays and debug

| Screen | Type | States for Figma | Source |
| --- | --- | --- | --- |
| Daily login popup | Overlay | appear, can claim, already claimed | `Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupView.swift` |
| Level up modal | Overlay | intro animation, details revealed | `Hexbound/Hexbound/Views/Components/LevelUpModalView.swift` |
| Toast stack | Overlay | achievement, level-up, reward, info, error | `Hexbound/Hexbound/Views/Components/ToastOverlayView.swift` |
| Loading overlay | Overlay | global blocking loader | `Hexbound/Hexbound/Views/Components/LoadingOverlay.swift` |
| Screen catalog | Debug | internal QA index of all routes | `Hexbound/Hexbound/Views/Dev/ScreenCatalogView.swift` |

## Admin dashboard

### Shared shell

| Screen | Type | States for Figma | Source |
| --- | --- | --- | --- |
| Admin login | Primary | default, loading, error | `admin/src/app/login/page.tsx` |
| Dashboard shell | Primary | sidebar, header, content frame | `admin/src/app/(dashboard)/layout.tsx` |

### Dashboard pages

| Screen | Type | States for Figma | Source |
| --- | --- | --- | --- |
| Dashboard home | Primary | KPI cards, chart | `admin/src/app/(dashboard)/page.tsx` |
| Tables | Primary | table list, search/filter | `admin/src/app/(dashboard)/tables/page.tsx` |
| Table detail | Variant | dynamic CRUD form/table | `admin/src/app/(dashboard)/tables/[tableName]/page.tsx` |
| Players | Primary | list, filters | `admin/src/app/(dashboard)/players/page.tsx` |
| Player detail | Primary | profile, grants, ban/unban, reset actions | `admin/src/app/(dashboard)/players/[id]/page.tsx` |
| Matches | Primary | arena history, filters | `admin/src/app/(dashboard)/matches/page.tsx` |
| Dungeons | Primary | dungeon list | `admin/src/app/(dashboard)/dungeons/page.tsx` |
| Dungeon editor | Primary | boss/wave/drop editor, save error state | `admin/src/app/(dashboard)/dungeons/[id]/page.tsx` |
| Economy | Primary | economy analytics | `admin/src/app/(dashboard)/economy/page.tsx` |
| Items | Primary | list/table, preview modal | `admin/src/app/(dashboard)/items/page.tsx` |
| Item create | Variant | form create mode | `admin/src/app/(dashboard)/items/new/page.tsx` |
| Item edit | Variant | form edit mode | `admin/src/app/(dashboard)/items/[id]/edit/page.tsx` |
| Loot | Primary | loot config, validation messages | `admin/src/app/(dashboard)/loot/page.tsx` |
| Skills | Primary | list plus create/edit/delete form | `admin/src/app/(dashboard)/skills/page.tsx` |
| Passives | Primary | graph/config CRUD | `admin/src/app/(dashboard)/passives/page.tsx` |
| Balance | Primary | global balance config editor | `admin/src/app/(dashboard)/balance/page.tsx` |
| Item balance / Overview | Primary | summary cards, simulation history | `admin/src/app/(dashboard)/item-balance/page.tsx` |
| Item balance / Config | Variant | config form | `admin/src/app/(dashboard)/item-balance/config/page.tsx` |
| Item balance / Profiles | Variant | profile tuning | `admin/src/app/(dashboard)/item-balance/profiles/page.tsx` |
| Item balance / Simulation | Variant | simulation controls and outputs | `admin/src/app/(dashboard)/item-balance/simulation/page.tsx` |
| Item balance / Validation | Variant | validation report | `admin/src/app/(dashboard)/item-balance/validation/page.tsx` |
| Events | Primary | event list/editor | `admin/src/app/(dashboard)/events/page.tsx` |
| Seasons | Primary | list, create, delete, error states | `admin/src/app/(dashboard)/seasons/page.tsx` |
| Achievements | Primary | achievements management | `admin/src/app/(dashboard)/achievements/page.tsx` |
| Config | Primary | live config editor | `admin/src/app/(dashboard)/config/page.tsx` |
| Appearances | Primary | skin/appearance CRUD with error states | `admin/src/app/(dashboard)/appearances/page.tsx` |
| Assets | Primary | storage browser, upload, delete, error states | `admin/src/app/(dashboard)/assets/page.tsx` |
| Settings | Primary | admin settings and permissions | `admin/src/app/(dashboard)/settings/page.tsx` |

## Figma batching recommendation

### Batch 1

- Mobile foundations
- Mobile components
- Login
- Register
- Onboarding
- Hub

### Batch 2

- Hero
- Character
- Stance selector
- Arena
- Combat
- Combat result
- Loot

### Batch 3

- Inventory
- Equipment
- Shop
- Currency purchase

### Batch 4

- Dungeon select
- Dungeon room
- Dungeon victory
- Tavern
- Shell game
- Gold mine
- Dungeon rush

### Batch 5

- Daily login
- Daily quests
- Achievements
- Leaderboard
- Battle pass
- Settings
- Global overlays

### Batch 6

- Admin foundations
- Admin shell
- Admin login
- Dashboard home
- Core CRUD pages
- Advanced live-ops pages
