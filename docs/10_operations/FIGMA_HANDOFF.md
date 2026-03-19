# Hexbound Figma Handoff

Дата подготовки: 2026-03-12

## Что уже готово

В репозитории собран handoff для переноса экранов в Figma:

- полная структура Figma-файла;
- foundation tokens для mobile и admin;
- список базовых компонентов;
- очередность переноса;
- отдельный инвентарь экранов в `docs/FIGMA_SCREEN_INVENTORY.md`.

Важно: прямой перенос в живой Figma-файл из этой среды пока не выполнен, потому что для этого нужен доступ к Figma-файлу или Figma API token. Но вся подготовка для ручного или полуавтоматического импорта уже собрана.

## Источники истины

### Mobile

- `Hexbound/Hexbound/App/AppRouter.swift`
- `Hexbound/Hexbound/Views/Dev/ScreenCatalogView.swift`
- `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
- `Hexbound/Hexbound/Theme/LayoutConstants.swift`
- `Hexbound/Hexbound/Theme/ButtonStyles.swift`
- `Hexbound/Hexbound/Theme/CardStyles.swift`

### Admin

- `admin/src/app/(dashboard)/layout.tsx`
- `admin/src/components/layout/sidebar.tsx`
- `admin/src/components/layout/nav-items.ts`
- `admin/src/app/globals.css`
- `admin/src/components/ui/*`

## Рекомендуемая структура Figma-файла

### 00 Cover

- Название файла: `Hexbound - Product UI`
- Краткая карта продукта: `Mobile Client`, `Admin Dashboard`, `Shared Design Tokens`
- Версия handoff и дата

### 01 Mobile Foundations

- Color styles
- Type styles
- Spacing scale
- Radii
- Safe areas
- Grid rules

### 02 Mobile Components

- Buttons
- Inputs
- Cards
- Tabs / segmented controls
- Top bars / toolbars
- Resource widgets
- Item cells
- Opponent cards
- Quest / achievement cards
- Reward nodes
- Overlays / popups / toasts / skeletons

### 03 Mobile Flows

- Auth flow
- Hub navigation
- PvP flow
- Inventory and shop flow
- Dungeon flow
- Meta progression flow

### 04 Mobile Screens - Auth

- Login
- Register
- Onboarding

### 05 Mobile Screens - Hub and Hero

- Hub
- Hero
- Character
- Stance selector
- Appearance editor

### 06 Mobile Screens - Arena and Combat

- Arena
- Combat
- Combat result
- Loot

### 07 Mobile Screens - Inventory and Shop

- Inventory
- Equipment
- Shop
- Currency purchase

### 08 Mobile Screens - Dungeon and Minigames

- Dungeon select
- Dungeon room
- Dungeon victory
- Tavern
- Shell game
- Gold mine
- Dungeon rush

### 09 Mobile Screens - Progression and Meta

- Daily login
- Daily quests
- Achievements
- Leaderboard
- Battle pass
- Settings

### 10 Mobile Overlays

- Daily login popup
- Level up modal
- Toast stack
- Loading overlay

### 11 Admin Foundations

- Desktop grid
- Dark dashboard theme
- Form controls
- Data table patterns
- Dialogs
- Cards

### 12 Admin Screens

- Login
- Dashboard shell
- All dashboard pages

### 13 Prototype and QA

- Clickable prototype flows
- Edge states
- Review notes

## Mobile foundations

### Base frame

- Primary artboard: `iPhone 15 Pro / 393 x 852`
- Safe area top: `59`
- Safe area bottom: `34`
- Horizontal screen padding: `16`

### Spacing scale

- `2`, `4`, `8`, `16`, `24`, `32`, `48`

### Radii

- Buttons / inputs: `8`
- Cards: `12`
- Modals: `16`

### Button sizes

- Primary: `56`
- Secondary: `48`
- Tertiary / compact: `36`

### Typography

- Titles and section headers: `Oswald`
- Body and UI labels: `Inter`

Suggested text styles:

- `Mobile / Cinematic / 40`
- `Mobile / Screen / 28`
- `Mobile / Section / 22`
- `Mobile / Card / 18`
- `Mobile / Body / 16`
- `Mobile / Label / 14`
- `Mobile / Caption / 12`
- `Mobile / Badge / 11`

### Core colors

- Background primary: `#0D0D12`
- Background secondary: `#1A1A2E`
- Background tertiary: `#16213E`
- Gold: `#D4A537`
- Gold bright: `#FFD700`
- Danger: `#E63946`
- Success: `#2ECC71`
- Cyan: `#00D4FF`
- Text primary: `#F5F5F5`
- Text secondary: `#A0A0B0`
- Text tertiary: `#6B6B80`
- Border subtle: `#2A2A3E`

## Admin foundations

### Base desktop frame

- Primary artboard: `1440 x 1024`
- Sidebar width: `256`
- Header height: `56`
- Main content padding: `24`

### Core colors

- Background: `#09090B`
- Card: `#0A0A0F`
- Primary: `#A78BFA`
- Border: `#27272A`
- Muted foreground: `#A1A1AA`
- Success: `#22C55E`
- Warning: `#F59E0B`
- Destructive: `#EF4444`

### Admin component set

- Button
- Input
- Label
- Textarea
- Select
- Switch
- Tabs
- Card
- Table
- Badge
- Dialog
- Sidebar nav item
- Header identity block

## Mobile component library

Сначала стоит собрать эти компоненты как variants, а уже потом раскладывать экраны.

### Global shell

- `Top Bar / With Logo`
- `Top Bar / With Logo + Title`
- `Top Bar / With Title + Action`
- `Bottom Navigation / 3 tabs`

### Buttons

- `Button / Primary / Default Disabled Loading`
- `Button / Secondary / Default Pressed`
- `Button / Danger`
- `Button / Ghost`
- `Button / Nav Tile`

### Inputs

- `Input / Text / Default Focus Error`
- `Input / Password / Hidden Visible`
- `Search / Admin`
- `Select / Admin`

### Cards

- `Card / Panel / Default Highlight`
- `Card / Rarity / Common Uncommon Rare Epic Legendary`
- `Card / Info Panel`
- `Card / Stat`
- `Card / Resource`

### Game-specific cells

- `Currency Display`
- `Stamina Bar`
- `Avatar`
- `Item Card`
- `Item Detail Sheet`
- `Equipment Slot`
- `Opponent Card`
- `Leaderboard Row`
- `Quest Card`
- `Achievement Card`
- `Battle Pass Node`
- `Shop Item Card`
- `Dungeon Boss Card`
- `Gold Mine Slot`

### States and feedback

- `Toast / Achievement LevelUp RankUp Reward Error Info`
- `Modal / Daily Login`
- `Modal / Level Up`
- `Overlay / Loading`
- `Skeleton / Grid`
- `Skeleton / Card`
- `Skeleton / List Row`

## Порядок переноса

### Phase 1

- Mobile foundations
- Mobile components
- Auth screens
- Hub shell

### Phase 2

- Arena
- Combat
- Inventory
- Shop

### Phase 3

- Dungeon
- Minigames
- Meta progression
- Overlays

### Phase 4

- Admin foundations
- Admin dashboard shell
- Core CRUD pages
- Advanced live-ops pages

## Что обязательно сделать в Figma

- Разнести mobile и admin по разным page groups.
- Все повторы собрать в components, не рисовать вручную каждый раз.
- Сделать отдельные variants для loading, empty, error, success.
- Вынести colors and text styles до раскладки экранов.
- Учитывать safe areas и fixed header zones для mobile.
- Для admin использовать autolayout почти везде: sidebar, header, filters, tables, forms.

## Следующий шаг для реального импорта

Если будет Figma link или API token, можно перейти к следующему этапу:

- создать реальный Figma файл по этой структуре;
- начать с `01 Mobile Foundations` и `02 Mobile Components`;
- затем переносить экраны пакетами по `docs/FIGMA_SCREEN_INVENTORY.md`.
