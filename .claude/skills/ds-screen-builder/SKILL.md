---
name: ds-screen-builder
description: |
  DS Screen Builder — builds app screens in Figma Screens file using ONLY DS components, tokens, and styles. Reads Swift view code, maps UI to DS components, assembles frame-by-frame in Figma with correct auto-layout, variable bindings, and component instances. Use this skill for building ANY screen in Figma from Swift code. Trigger: "build screen", "собери экран", "screen builder", "экран в фигме", "figma screen", "добавь экран", "new screen figma", "собери все экраны".
---

# DS Screen Builder

You build Hexbound app screens in the **Figma Screens file** using ONLY components and tokens from the **Figma DS file**.

**Screens file:** `PalemJ36B97ZdC0cd8jzv4`
**DS file:** `uDjXIz7CdJxcEOI5jCBcjY`
**DS library key:** `lk-1e3d5b13e106c557d2ec56c3ac95231374bc21a6136997e732d7a804ec4d86c11297eee6bd376c1bc936574dd6ba4ddea2380be439e8701a5408d7daaff18fb4`

## Prerequisites

1. Load `figma-use` skill BEFORE any `use_figma` calls
2. Load `figma-generate-design` skill for screen assembly patterns
3. Read the Swift view source for the screen you're building
4. All operations on **Screens file only** — NEVER create components here

## Phase 1: Read the Swift View

For the target screen, read the full Swift source:

```bash
# Example: building Arena screen
cat Hexbound/Hexbound/Views/Arena/ArenaView.swift
```

**Map every visual element to a DS component or token:**

| Swift Element | Figma Equivalent |
|---|---|
| `ScreenLayout(title:)` | Navigation / ScreenHeader instance |
| `.panelCard()` | Card / Panel instance |
| `.highlightCard()` | Card / Highlight instance |
| `CurrencyDisplay(...)` | Currency Display instance |
| `TabSwitcher(...)` | Tab Switcher instance |
| `Button(...).buttonStyle(.primary)` | Button / Primary instance |
| `EtchedGroove()` | Divider / Etched Groove instance |
| `GoldDivider()` | Divider / Gold instance |
| `Text(...).font(DarkFantasyTheme.title)` | Text with Heading/Title style |
| `DarkFantasyTheme.bgPrimary` | color/bg/primary variable binding |
| `LayoutConstants.spaceMD` | spacing/md variable binding |

## Phase 2: Discover DS Components

Use `search_design_system` to find available components:

```
search_design_system(fileKey: "uDjXIz7CdJxcEOI5jCBcjY", query: "Button")
search_design_system(fileKey: "uDjXIz7CdJxcEOI5jCBcjY", query: "Card")
```

Then use `importComponentByKeyAsync` in `use_figma` to import instances into the Screens file.

## Phase 3: Screen Frame Setup

Every screen follows this structure:

```
FRAME "Screens / {Category} / {ScreenName} — {State}" (390×844)
├── fills: color/bg/primary (variable binding)
├── auto-layout: VERTICAL, padding: spacing/md (16)
├── INSTANCE: Navigation / ScreenHeader
├── FRAME "Content" (fill container)
│   ├── auto-layout: VERTICAL, gap: spacing/md (16)
│   ├── ... screen-specific content ...
│   └── ...
└── INSTANCE: Navigation / NavGrid (if applicable)
```

### Frame dimensions:
- iPhone 15 Pro: **390 × 844** (standard)
- Safe area: top 59px, bottom 34px (home indicator)
- All screens use this size for consistency

### Setup code template:

```js
// In use_figma — create screen frame
const page = figma.root.children.find(p => p.name === '{Category}');
// Create page if not exists
if (!page) {
  const newPage = figma.createPage();
  newPage.name = '{Category}';
}

const frame = figma.createFrame();
frame.name = 'Screens / {Category} / {ScreenName} — Default';
frame.resize(390, 844);
frame.layoutMode = 'VERTICAL';
frame.primaryAxisAlignItems = 'MIN';
frame.counterAxisAlignItems = 'MIN';
frame.paddingTop = 59; // safe area
frame.paddingBottom = 34; // home indicator
frame.paddingLeft = 0;
frame.paddingRight = 0;
frame.itemSpacing = 0;
frame.clipsContent = true;

// Bind background to color/bg/primary
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const colorCol = collections.find(c => c.name === 'Color');
// ... find bgPrimary variable and bind
```

## Phase 4: Import DS Components

Import each needed component from DS library:

```js
// Import component by key from DS library
const component = await figma.importComponentByKeyAsync('COMPONENT_KEY');
const instance = component.createInstance();
// Position in auto-layout frame
parentFrame.appendChild(instance);
```

**Finding component keys:**
1. Use `search_design_system` to find components
2. Or use `get_metadata` on DS file to get component keys
3. Cache keys for repeated use

## Phase 5: Bind ALL Values to Tokens

**MANDATORY — zero raw values allowed:**

```js
// Bind fill to color variable
const bgVar = await findVariable('color/bg/primary');
node.setBoundVariable('fills', 0, bgVar);

// Bind spacing to spacing variable
const spacingVar = await findVariable('spacing/md');
node.setBoundVariable('itemSpacing', spacingVar);
node.setBoundVariable('paddingTop', spacingVar);

// Link text style
const textStyle = figma.getLocalTextStyles().find(s => s.name === 'Heading/Title');
textNode.textStyleId = textStyle.id;
```

## Phase 6: Screen States

Each screen needs multiple states. Create as separate frames:

| State | Naming | Content |
|---|---|---|
| Default | `{ScreenName} — Default` | Normal populated view |
| Loading | `{ScreenName} — Loading` | Skeleton placeholders |
| Empty | `{ScreenName} — Empty` | EmptyStateView instance |
| Error | `{ScreenName} — Error` | ErrorStateView instance |
| Success | `{ScreenName} — Success` | If applicable (e.g., purchase confirm) |

**Minimum 3 states per screen:** Default + Loading + Empty/Error

## Phase 7: Quality Checklist

After building each screen, verify:

- [ ] Frame name follows convention: `Screens / {Category} / {Name} — {State}`
- [ ] Frame size: 390×844
- [ ] Background bound to `color/bg/primary` (or appropriate bg token)
- [ ] ALL text nodes have linked text styles (Heading/* or Body/*)
- [ ] ALL colored elements have variable bindings (fills, strokes)
- [ ] ALL spacing (gaps, padding) bound to spacing variables
- [ ] ALL buttons are DS Button instances (not custom frames)
- [ ] ALL dividers are DS Divider instances (not rectangles)
- [ ] ALL cards are DS Card instances
- [ ] No orphaned layers outside auto-layout
- [ ] Content scrollable area uses correct constraints
- [ ] Screen matches Swift view structure 1:1

## Screen Inventory (48 screens)

### Priority Order (build in this sequence):

**Tier 1 — Core Loop (build first):**
1. Hub/CityMap ✅ (exists)
2. ArenaView ✅ (exists)
3. HeroDetail ✅ (exists)
4. CombatView
5. CombatResult (BattleResultCard)
6. InventoryView
7. ItemDetailSheet

**Tier 2 — Monetization + Progression:**
8. ShopView
9. BattlePassView
10. DailyQuestsDetail
11. DailyLoginPopup
12. FortuneWheelDetail ✅ (exists)
13. ShellGameDetail ✅ (exists)
14. QuestBanner ✅ (exists)

**Tier 3 — Auth + Onboarding:**
15. Welcome
16. Login
17. Register
18. EmailConfirmation
19. CharacterCreation (4 steps)
20. CharacterSelection
21. LoreIntro

**Tier 4 — Secondary Systems:**
22-48. Remaining screens (Dungeon, Leaderboard, Social, Settings, etc.)

## Page Structure in Screens File

| Page Name | Screens |
|---|---|
| Auth | Welcome, Login, Register, EmailConfirm, CharacterCreation×4, CharacterSelect, LoreIntro, UpgradeGuest |
| Hub | Hub/CityMap, CityBuilding, StanceSelector |
| Character | CharacterProfile, HeroDetail, AppearanceEditor |
| Combat | CombatView, CombatDetail, CombatResult, LootDetail |
| Arena | ArenaView, ArenaCarousel, ArenaComparison, OpponentProfile, RankUpCeremony |
| Inventory | InventoryView, ItemDetailSheet |
| Shop | ShopView, CurrencyPurchase, PremiumPurchase |
| Dungeon | DungeonSelect, DungeonInfo, DungeonRoom, Victory, Defeat, LootPreview |
| BattlePass | BattlePassView, RewardNodes, SeasonSummary |
| Progression | DailyQuests, DailyLogin, Achievements |
| Social | Leaderboard, LeaderboardDetail, Inbox, InboxDetail, GuildHall |
| Minigames | GoldMine, ShellGame, DungeonRush, FortuneWheel, TavernHub |
| Settings | Settings |
| Modals & Overlays | LevelUp, SessionExpired, GuestGate, all sheets |

## Handling Missing Components

If a screen element has no matching DS component:

1. **STOP building the screen**
2. Note the missing component
3. Use `ds-extract-component` skill to create it in DS first
4. Then return and continue building the screen

**NEVER create components in the Screens file.** All components live in DS file only.

## Batch Building Strategy

When building multiple screens in one session:

1. **Discover phase:** List all needed DS components for the batch
2. **Import phase:** Import all component keys once, cache references
3. **Build phase:** Build screens sequentially, reusing cached imports
4. **Verify phase:** Run quality checklist on each screen
5. **Screenshot phase:** Take `get_screenshot` of each completed screen for visual verification
