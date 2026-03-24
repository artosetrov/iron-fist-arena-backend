# Hexbound — Project Rules

> **Full documentation**: See `docs/01_source_of_truth/DOCUMENTATION_INDEX.md` for the complete docs structure.
> **Canonical rules**: See `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md` for the extended version of these rules.

## Xcode Project File (CRITICAL)

When creating ANY new `.swift` file in the `Hexbound/` iOS app, you MUST also add it to `Hexbound/Hexbound.xcodeproj/project.pbxproj`.

Each new file requires entries in **4 sections** of `project.pbxproj`:

1. **PBXBuildFile** — `{ID1} /* FileName.swift in Sources */ = {isa = PBXBuildFile; fileRef = {ID2} /* FileName.swift */; };`
2. **PBXFileReference** — `{ID2} /* FileName.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileName.swift; sourceTree = "<group>"; };`
3. **PBXGroup** — Add `{ID2} /* FileName.swift */,` to the correct group's `children` array (match the folder the file lives in, e.g. Auth, Components, Network)
4. **Sources build phase** — Add `{ID1} /* FileName.swift in Sources */,` to the `PBXSourcesBuildPhase` `files` array

Generate unique 24-character hex IDs for `{ID1}` and `{ID2}`. Keep entries alphabetically sorted within each section.

**If you skip this step, the file will NOT compile in Xcode.**

## Design System

- Always use `DarkFantasyTheme` color/font tokens — never hardcode `Color(hex:)` or raw color values
- Always use `ButtonStyles.swift` styles (`.primary`, `.secondary`, `.neutral`, etc.) — never inline button styling. **Never manually build button chrome** (goldGradient + surfaceLighting + RoundedRectangle background) when a button style already exists.
- **Gold CTA styles** (`.primary`, `.compactPrimary`, `.fight`, `.premium`, `.danger`) MUST have full ornamental treatment: `SurfaceLightingOverlay` + `cornerBrackets` + `cornerDiamonds` + `innerBorder`. If adding a new gold CTA style, include all four.
- Always use `LayoutConstants` for spacing/sizing — minimum font size is `LayoutConstants.textBadge` (11px)
- The theme file is at `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
- Button styles are at `Hexbound/Hexbound/Theme/ButtonStyles.swift`
- Layout constants are at `Hexbound/Hexbound/Theme/LayoutConstants.swift`
- **Ornamental styles** are at `Hexbound/Hexbound/Theme/OrnamentalStyles.swift`
- Card/panel styles are at `Hexbound/Hexbound/Theme/CardStyles.swift`

## Ornamental Design System (CRITICAL)

All UI elements use a pure SwiftUI ornamental system — **no PNG assets for UI chrome**. Ornamental primitives are in `OrnamentalStyles.swift`. **Status: 100% complete across all production views** (completed 2026-03-22).

**Reusable components:**
- `RadialGlowBackground` — replaces flat `bgSecondary` fill on panels/cards. Always use instead of plain `.fill(DarkFantasyTheme.bgSecondary)` for panels.
- `BarFillHighlight` — top-edge shine on progress bar fills. **Must be applied to ALL progress bars** (HP, XP, Stamina) via `.overlay(BarFillHighlight(cornerRadius:))`.
- `DiamondDividerMotif` — ◆◇◆ center motif for dividers. Used in `GoldDivider` and `OrnamentalDivider`.
- `CornerBracketOverlay` — L-brackets at 4 corners (Path-based).
- `CornerDiamondOverlay` — rotated Rectangle diamonds at corners.
- `SideDiamondOverlay` — diamonds at left/right center edges.
- `InnerBorderOverlay` — inset gradient stroke (highlight top → shadow bottom).
- `SurfaceLightingOverlay` — top-bright/bottom-dark convex surface effect.

**Additional structural components (added 2026-03-22):**
- `DoubleBorderOverlay` — two concentric rounded-rect strokes with gap (frame-within-frame)
- `ScrollworkDivider` — curving end-caps with center diamond motif
- `FiligreeLine` — decorative line with diamond notches at intervals
- `EtchedGroove` — double-line groove (dark top + bright bottom hairline)

**Convenience extensions (prefer these over raw structs):**
- `.cornerBrackets(color:length:thickness:)`, `.cornerDiamonds(color:size:)`, `.sideDiamonds(color:size:)`
- `.innerBorder(cornerRadius:inset:color:)`, `.surfaceLighting(cornerRadius:)`
- `.doubleBorder()`, `.etchedGroove()`, `.premiumFrame()` — combo ornamentals
- `.ornamentalFrame(cornerRadius:bracketColor:bracketLength:diamondColor:)` — combo of all

**Standard panel pattern (MANDATORY):**
- Base: `RadialGlowBackground(baseColor: DarkFantasyTheme.bgSecondary, glowColor: DarkFantasyTheme.bgTertiary, glowIntensity: 0.4, cornerRadius: LayoutConstants.cardRadius)`
- Surface: `.surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)`
- Border: `.innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))` for neutral panels
- For accent-tinted panels: use `accentColor.opacity(0.08)` instead of `borderMedium.opacity(0.15)`
- Brackets: `.cornerBrackets(color: accentOrBorder.opacity(0.3), length: 14, thickness: 1.5)` on visible panels
- Shadow: `.shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)` — always add abyss shadow

**Standard modal/important panel pattern (MANDATORY):**
- Base: `RadialGlowBackground(baseColor: DarkFantasyTheme.bgSecondary, glowColor: DarkFantasyTheme.bgTertiary, glowIntensity: 0.4, cornerRadius: LayoutConstants.modalRadius)`
- Surface: `.surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)`
- Border: `.innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: rarityColor.opacity(0.1))` or `.gold.opacity(0.1)` for neutral
- Brackets: `.cornerBrackets(color: accentColor.opacity(0.5), length: 18, thickness: 2.0)` + `.cornerDiamonds(color: accentColor.opacity(0.4), size: 6)`
- Shadow: dual — `.shadow(color: accentColor.opacity(0.18), radius: 10)` + `.shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)`
- Used in: battle results, loot previews, item detail sheets, daily login popups, auth steps

**Circle exception:**
- Progress circles, stat rings, XP rings: use `RadialGradient` directly (NOT `RadialGlowBackground` which uses RoundedRectangle)
- Pattern: `RadialGradient(gradient: Gradient(...), center: .center, startRadius: 0, endRadius: radius)`

**Intentional flat bgSecondary fills (exceptions):**
- `HubView` background under `RadialGradient` sky overlay
- `ToastOverlayView` base before vignette effect
- `ScreenCatalogView` (dev tools)

**Press state rule:** Use `.brightness(-0.06)` instead of `.opacity(0.85)` for button press feedback — gives more natural "pressed plate" feel.

**Color.white / Color.black exception:** These are allowed ONLY in ornamental overlays (surface lighting, inner bevels) at very low opacity (0.06–0.08). Never use them for text, backgrounds, or borders.

**Shadow pattern:** Use dual shadows for depth: type-colored glow shadow + dark `bgAbyss` shadow. Never use a single flat shadow.

## Radius Scale (CRITICAL)

All `cornerRadius` values MUST use `LayoutConstants` tokens. Never hardcode raw numbers.

**Generic scale (prefer these for new code):**
- `radiusXS` (3) — progress bars, tiny indicators, particles
- `radiusSM` (6) — badges, stat bars, tag chips
- `radiusMD` (8) — buttons, panels, pills, inputs
- `radiusLG` (12) — cards, widgets
- `radiusXL` (16) — modals, featured cards
- `radius2XL` (22) — capsule-like auth inputs

**Component-specific aliases (use when context matches):**
- `cardRadius` (12), `panelRadius` (8), `modalRadius` (16), `buttonRadius` (8), `buttonRadiusLG` (14)
- `heroCardRadius` (12), `heroSlotRadius` (12), `heroBarRadius` (4)
- `widgetRadius` (12), `widgetBarRadius` (6), `pillRadius` (12)
- `arenaCardRadius` (16), `arenaAvatarRadius` (14)

**Exception:** Circle skeletons use `width/2` as `cornerRadius` (e.g., `cornerRadius: 26` for 52pt circle) — this is intentional and expected.

## Art Style (for AI image generation prompts)

- Full art style guide: `Hexbound/ART_STYLE_GUIDE.md`
- Style: pen and ink illustration, bold black ink outlines, muted earth tones + 1-2 saturated accent colors, grimdark dark fantasy, isolated on white/transparent background
- Reference: D&D Monster Manual / Pathfinder rulebook illustrations (NOT digital painting, NOT concept art, NOT anime)
- Always start prompts with `Pen and ink illustration of...`
- Always end with `isolated on white background, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text`
- The icon `icon-gold-mine` is in a DIFFERENT casual/cartoon style — do NOT use as art style reference

## Design System — Verification Rules (CRITICAL)

- **NEVER guess token names.** Before using any `DarkFantasyTheme.xxx`, open `DarkFantasyTheme.swift` and confirm the property exists. There is no `.accent` — the primary accent is `.gold`.
- **NEVER guess button style names.** Open `ButtonStyles.swift` and verify before using.
- Common mistake: inventing `.accent`, `.primary`, `.background`, `.text` — these DO NOT exist. Use actual tokens: `.gold`, `.bgPrimary`, `.textPrimary`, etc.

## Stat Colors — Unified Gold Palette (CRITICAL)

All stat bars and stat-related UI use a **unified gold palette** — never per-stat rainbow colors.

- `DarkFantasyTheme.statBoosted` (`#FFD700`, goldBright) — for stats above base value
- `DarkFantasyTheme.statBase` (`#8B6914`, goldDim) — for base-level stats
- `DarkFantasyTheme.statBarFill` (`#D4A537`, gold) — standard bar fill color
- `DarkFantasyTheme.statBarColor(value:base:)` — auto-selects bright/dim based on value
- `DarkFantasyTheme.statBarGradient(value:base:)` — gradient version for bar fills
- `DarkFantasyTheme.statColor(for:)` — returns unified `statBarFill` for any stat name

**Legacy per-stat colors** (`statSTR`, `statAGI`, `statVIT`, etc.) are `@available(*, deprecated)`. Do NOT use them in new code.

**Where this applies:** ClassSelectionStepView (onboarding), HeroDetailView (stats + derived stats), CombatResultDetailView, LootDetailView, ItemDetailSheet — all stat displays project-wide.

## Swift Concurrency Rules (CRITICAL)

- Any enum, struct, or class that accesses `@MainActor`-isolated properties (e.g. `String.localized`, `LocalizationManager.shared`) MUST itself be marked `@MainActor`.
- `L10n` enum is `@MainActor`. Any new type-safe key enums/extensions follow the same pattern.
- When `getAdminUser()` or any function returns `T?`, and you guard with `if (!result) throw` — always use a non-optional binding after the guard: `const safeResult = result!` or use `guard let` in Swift. TypeScript strict mode may not narrow after throw.

## Architecture

- State management: `@MainActor @Observable` classes
- Navigation: `NavigationStack` with `AppRouter`
- Cache: `GameDataCache` environment object, cache-first pattern
- Views pass `@Bindable var vm` to child components (not `@State`)

## Unified Hero Widget (CRITICAL)

**Always use `UnifiedHeroWidget` for character summary display.** Never create inline character displays, duplicate stamina bars, or ad-hoc currency rows on screens.

- Component: `Hexbound/Hexbound/Views/Components/UnifiedHeroWidget.swift`
- Pill system: `Hexbound/Hexbound/Views/Components/WidgetPill.swift`
- XP ring shape: `Hexbound/Hexbound/Views/Components/XPRingShape.swift`
- Contexts: `.hub` (full), `.arena` (PvP pills), `.dungeon` (minimal), `.hero` (with XP)
- **Deprecated:** `HubCharacterCard.swift`, `HubCharacterCardWrapper` — do NOT use, do NOT create new code referencing them
- Pill tokens: `LayoutConstants.pill*` for sizing, `DarkFantasyTheme.pill*` for colors
- Widget tokens: `LayoutConstants.widget*` for layout
- Accessibility: all pill text ≥ 12px, contrast ≥ 4.5:1 (use `textTertiaryAA` not `textTertiary` in widget)

## Hero Page Integration (CRITICAL)

**Hero page uses `HeroIntegratedCard`** (NOT UnifiedHeroWidget) — equipment-first layout with portrait, bars inside, universal slots.

- Component: `Hexbound/Hexbound/Views/Components/HeroIntegratedCard.swift`
- Combines: equipment grid + portrait + name overlay + HP/XP/Stamina bars + repair/heal action pills
- Replaces: `equipmentSection()` + `stanceSummaryCard()` + `UnifiedHeroWidget` on Hero tab
- Universal slots: `amulet` accepts amulet OR necklace; `relic` accepts relic OR accessory OR weapon off-hand
- Portrait: 2×3 cell grid with name overlay (gradient transparent→black, Oswald 16px), level badge (gold circle top-right), class badge (top-left)
- Bars: HP 24px tall with text centered inside; XP 20px tall with absolute values not percentage
- Bottom action pills: repair all (conditional on broken items), heal (conditional on HP < 50% + potion)
- **Stance is NOT inside HeroIntegratedCard** — it is a separate `StanceDisplayView` widget below the card (updated 2026-03-23)
- Layout tokens: `LayoutConstants.hero*` for card/slot sizing and bar heights
- Integration: see `HeroDetailView.tabContent()` for callback pattern (onTapPortrait, onTapSlot, onRepairAll, etc.) — `onEditStance` was removed

**Tab layout (updated 2026-03-22):**
- `HeroDetailView` has **sticky tabs** (INVENTORY / STATUS) pinned above `ScrollView` — they do NOT scroll with content
- Structure: `VStack(spacing: 0) { tabSelector() → ScrollView { ... } }`
- `HeroIntegratedCard` is **INVENTORY tab only** — it does NOT appear on STATUS tab
- STATUS tab shows: stat points banner → grouped stats → **respec** → derived stats → equipment bonuses (PvP section removed — 2026-03-23)
- Tab badge: STATUS tab shows **gold capsule badge** ("+N", `goldBright` fill, `bgAbyss` stroke, pulsing gold shadow) — identical to avatar stat points badge in `UnifiedHeroWidget`. No star icon — text only.
- Shimmer: purple shimmer on STATUS tab when stat points available and tab is not selected
- `onAllocateStats` callback switches to STATUS tab (`selectedTab = .stats`), not navigates away

## Stance Display (CRITICAL)

**Always use `StanceDisplayView` for combat stance display.** Never create inline stance displays or duplicate the two-column layout.

- Component: `Hexbound/Hexbound/Views/Components/StanceDisplayView.swift`
- Two-slot layout: Attack (red tint) | Ornamental Divider | Defense (blue tint)
- Role-specific coloring: Attack uses `DarkFantasyTheme.danger` tint, Defense uses `DarkFantasyTheme.info` tint (6% opacity background per slot)
- Role icons: `bolt.fill` (attack), `shield.fill` (defense) — visually distinguish roles even without reading text
- Zone icons: `icon-helmet`, `icon-chest`, `icon-legs` — from `StanceSelectorViewModel.zoneAsset(for:)`
- Zone colors: `DarkFantasyTheme.zoneHead` (red), `.zoneChest` (blue), `.zoneLegs` (green)
- Ornamental vertical divider: gradient line (borderSubtle → borderMedium → goldDim → borderMedium → borderSubtle) with center diamond motif
- Interactive mode: `isInteractive: true` shows `chevron.right` indicator + uses `StancePressStyle` (brightness(-0.06), not scalePress)
- **On Hero page**: standalone widget between `HeroIntegratedCard` and `lowResourcesWidget`, NOT inside the card
- **On StanceSelectorDetailView**: non-interactive preview at bottom (`stanceConfirmation`)
- Init from model: `StanceDisplayView(stance: CombatStance, ...)` or direct: `StanceDisplayView(attack: "head", defense: "chest", ...)`

**Stance Selector screen** (`StanceSelectorDetailView`):
- Compact zone sections with inline bonus pills (OFF%, CRIT%, DEF%, DODGE%)
- Zone matching info panel (match +15% DEF, miss +5% OFF)
- Sticky save button via `.safeAreaInset(edge: .bottom)` with fade gradient
- Bonus data in `StanceSelectorViewModel`: `attackBonuses(for:)`, `defenseBonuses(for:)` — from `balance.ts STANCE_ZONES`

## Arena Screen Layout (updated 2026-03-23)

`ArenaDetailView` has **sticky title + tabs** pinned above `ScrollView` — they do NOT scroll with content.

- Structure: `VStack(spacing: 0) { OrnamentalTitle → TabSwitcher → ScrollView { content } → refreshButton }`
- Tabs: OPPONENTS / REVENGE / HISTORY
- Scrollable content: ActiveQuestBanner → UnifiedHeroWidget → PvP Stats Bar → LowHPBanner → StancePreview → Tab content
- Refresh button: pinned to bottom (opponents tab only)

## Guild Hall (Social Hub) — added 2026-03-23

The Guild Hall building is the social hub with 3 tabs: **ALLIES** (friends), **SCROLLS** (messages), **DUELS** (challenges). Allies and Duels are implemented; Scrolls shows Coming Soon placeholder.

- Route: `AppRoute.guildHall` → `GuildHallDetailView`
- ViewModel: `GuildHallViewModel` — `@MainActor @Observable`, manages friends list, requests, online status, challenge lists
- Models: `Social.swift` — `FriendEntry`, `FriendRequest`, `OnlineStatus`, `FriendshipButtonState`, `SocialStatus`, `FriendsListResponse`
- Models: `Challenge.swift` — `IncomingChallenge`, `OutgoingChallenge`, `CompletedChallenge`, `ChallengesResponse`, `SendChallengeResponse`, `SentChallengeInfo`, `DuelResult`, `DuelResultResponse`
- Service: `SocialService.swift` — singleton, all friend actions (request/accept/decline/remove/block/unblock), status queries
- Service: `ChallengeService.swift` — singleton, challenge actions (send/accept/decline/cancel), challenge list fetching
- Backend: `POST /api/social/friends` (actions), `GET /api/social/friends` (list), `GET /api/social/status` (badge counts), `POST /api/social/status` (friendship status)
- Backend: `POST /api/social/challenges` (send/accept/decline), `GET /api/social/challenges` (incoming/outgoing/completed)
- DB: `Friendship` model (pending/accepted/blocked), `DirectMessage` model (Phase 2), `Challenge` model (pending/accepted/declined/expired/completed), `lastActiveAt` on Character
- Online status: computed from `lastActiveAt` — online (<5min), away (<30min), offline (>30min)
- Anti-abuse (friends): 20 requests/day, 24h cooldown after decline, 7-day request expiry, max 50 friends
- Anti-abuse (challenges): max 5 pending per player, max 10 challenges/day, 24h expiry, 1 stamina per send
- Challenge flow: send → pending → accept (runs combat, ELO, 1.2x gold multiplier) / decline / expire
- Badge: Guild Hall building shows `totalBadge` from `cache.socialStatus` (sum of pending requests + challenges + messages + revenges)
- **LeaderboardPlayerDetailSheet**: Challenge button sends real challenge via `ChallengeService.sendChallenge()` — no more stub closure. Add Friend button is a 6-state machine (`FriendshipButtonState`).
- **Duel result sheet**: shown in GuildHallDetailView after accepting an incoming challenge — displays victory/defeat, rating change, gold/XP rewards
- **Friend context menu**: Challenge option in Allies tab sends challenge via `GuildHallViewModel.sendChallenge()`
- **Thematic naming**: Friends→Allies, Messages→Scrolls, Challenges→Duels (in-game lore)

## Hub Building System

### Adding New Buildings

- Config: `Hexbound/Hexbound/Views/Hub/CityBuildingConfig.swift` → `defaultCityBuildings` array
- Model: `CityBuilding` — `route: AppRoute?` is **optional**. Set `nil` for Coming Soon placeholder buildings.
- When `route == nil`: `CityMapView` shows info toast `"\(label) — Coming Soon"` instead of navigating.
- Asset naming: `building-{id}.imageset` in `Assets.xcassets/` with `Contents.json` + PNG
- Position: `relativeX`/`relativeY` (0.0...1.0) on terrain. Adjustable via Hub Editor (DEBUG).
- Current buildings (10): shop, battlepass, achievements, gold-mine, tavern, arena, dungeon, ranks, **guild-hall** (social hub), **black-market** (Coming Soon)
- **When adding a new building**: add entry to `defaultCityBuildings`, create `.imageset`, optionally add badge in `badgeFor()`. No new Swift files or pbxproj changes needed.

### Badge System

Buildings on the hub map show **gold capsule badges** when actions are available inside.

- Badge rendering: `CityBuildingLabel` → gold `Capsule` with `DarkFantasyTheme.gold` fill, `textOnGold` text
- Badge data: `CityMapView.badgeFor(_ building:)` — switch on `building.id`
- Current badges:
  - `arena` → `"FREE N"` — free PvP fights remaining (`AppConstants.freePvpPerDay - character.freePvpToday`)
  - `achievements` → `"N"` — unclaimed achievement rewards (`cache.achievements.filter(\.canClaim).count`)
  - `battlepass` → `"N"` — claimable tier rewards (free + premium if owned, level ≤ current)
  - `gold-mine` → `"READY"` — slots with status `"ready"` in `cache.goldMineSlots`
  - `guild-hall` → `"N"` — total social badge count (`cache.socialStatus?.totalBadge` — includes pending friend requests + challenges + messages + revenges)
- **When adding a new building badge**: add a case to `badgeFor()` in `CityMapView.swift`, use data from `appState` or `cache`
- **Badge color is gold** — never green, never red. Consistent across all buildings.

## Unified Item Card (CRITICAL)

**Always use `ItemCardView` as the single source of truth for item cell rendering.** Never create inline item displays, duplicate card styles, or context-specific card views in other files.

- Component: `Hexbound/Hexbound/Views/Components/ItemCardView.swift`
- Contexts via `ItemCardContext` enum:
  - `.inventory(equippedItem:)` — comparison arrows, equipped badge, quantity, durability
  - `.shop(price:isGem:canAfford:meetsLevel:isBuying:)` — price bar with `CurrencyDisplay`, affordability dimming
  - `.equipment(slotAsset:)` — empty slot placeholder, broken indicator
  - `.loot` — minimal card for battle result reveal
  - `.preview` — full detail for sheet views
- Visual style: gradient background (rarity → abyss), RadialGradient for epic/legendary, bottom vignette (28pt), double border (inner bevel via `.innerBorder()` + outer rarity 2.5px), corner L-bracket accents (`CornerAccentsOverlay`), corner diamonds (`.cornerDiamonds()`), rarity stars (1-5)
- **Deprecated:** `ShopItemCardView.swift` — dead code, all shop items now use `ItemCardView` with `.shop` context
- Price display: use `CurrencyDisplay` component with `.mini` size (not SF Symbol icons like `dollarsign.circle`)
- Loot bridge: `LootItemDisplay` has computed `rarity: ItemRarity` property derived from `rarityTier` for ItemCardView compatibility
- **Opponent profile equipment grid:** Each `.equipment()` slot automatically applies `ItemRarity.color` border tint (from `ItemRarity.color` computed property) — no manual color passing needed. The rarity-colored 2.5px border is dynamic per item.

## Admin Panel (Next.js / TypeScript)

- **Strict null checks:** When a function returns `T | null`, always narrow the type before use. Prefer `if (!x) throw` followed by explicit non-null assertion or destructuring, not bare `x.property` access.
- **Build before push:** Run `npx next build` locally or check Vercel preview before merging to `main`.

## Prisma Schema Sync (CRITICAL)

`backend/prisma/schema.prisma` is the **single source of truth** for the database schema. Admin has its own copy that **must stay identical**.

After ANY change to `backend/prisma/schema.prisma`:
1. Run the migration: `cd backend && npm run db:migrate:dev -- --name your_change`
2. **Copy to admin**: `cp backend/prisma/schema.prisma admin/prisma/schema.prisma`
3. Commit both files together

**If you skip step 2, CI will fail** (prisma-schema-sync check) and admin panel may crash on deploy.

## Git & Deploy (CRITICAL)

The project has **2 git remotes**. Pushing to `origin` does NOT deploy admin.

- `origin` → full monorepo → **backend auto-deploys** to Vercel
- `admin-deploy` → admin subtree → **admin auto-deploys** to Vercel

After `git push origin main`, if admin/ was changed, you MUST also run:
```
git subtree push --prefix=admin admin-deploy main
```

**If you skip this, admin panel will NOT update.**

## UI/UX Design & Review Rules

When designing new screens, auditing existing screens, or reviewing SwiftUI code for UX quality:

### Before Any Design Work
1. **Read the design system files** — don't guess which tokens exist. Open `DarkFantasyTheme.swift`, `ButtonStyles.swift`, `LayoutConstants.swift` and check.
2. **Check existing components** — look in `Hexbound/Hexbound/Views/Components/` before proposing new ones. We already have `panelCard()`, `GoldDivider()`, `TabSwitcher`, `HubLogoButton`, `ActiveQuestBanner`, skeleton cards, etc.

### Product Principles (Hard Requirements)
- **3-second rule** — player understands the screen in under 3 seconds
- **One goal per screen** — one primary CTA, everything else is secondary
- **No dead ends** — every state (empty, error, loading) has a clear next action
- **Short sessions** — 2-5 minutes per session, respect the player's time
- **Monetization = acceleration** — never hard-block fair play

### Mobile UX Rules
- Minimum touch target: 48×48pt, primary buttons 56pt+
- Key actions in bottom 60% (thumb zone)
- Max 4-6 actions visible at once
- Minimum font: 11px (`LayoutConstants.textBadge`)
- Every interactive element: define default, pressed, selected, disabled, loading, error, success states
- Every list: define empty state with CTA
- Loading: skeletons > spinners > blank screens

### UX Audit Format
When reviewing a screen, always:
1. **Start with strengths** — what's working well (3-5 items)
2. **Then issues** — each with: What → Problem → Impact → Fix → Priority (Critical/High/Medium/Low)
3. **Reference real tokens** from the design system files
4. **Check existing components** before suggesting new ones

### Game Systems Checklist
Every UX decision must account for: retention hooks, fairness (anti-exploit), progression clarity, reward anticipation, economy health, anti-frustration after losses, first-session friendliness, live ops extensibility.

### Server-Authoritative Rule
Client must NOT calculate: combat results, reward amounts, rating changes, economy values, or balance formulas. Display what the server returns.

## Documentation Quick Lookup

When you need project context, read the specific doc — don't guess or invent facts.

| Need to know | Read this file |
|---|---|
| DB models, fields, enums | `docs/04_database/SCHEMA_REFERENCE.md` |
| API endpoints | `docs/03_backend_and_api/API_REFERENCE.md` |
| Game balance constants, formulas | `docs/06_game_systems/BALANCE_CONSTANTS.md` |
| Combat system, damage, ELO | `docs/06_game_systems/COMBAT.md` |
| Economy, currencies, IAP, prices | `docs/02_product_and_features/ECONOMY.md` |
| All game systems overview | `docs/02_product_and_features/GAME_SYSTEMS.md` |
| Admin panel pages, capabilities | `docs/05_admin_panel/ADMIN_CAPABILITIES.md` |
| iOS screens, states, components | `docs/07_ui_ux/SCREEN_INVENTORY.md` |
| Design tokens, colors, fonts | `docs/07_ui_ux/DESIGN_SYSTEM.md` |
| Art prompts for image gen | `docs/08_prompts/ASSET_PROMPTS_INDEX.md` |
| Deploy flow, Vercel, rollback | `docs/10_operations/DEPLOY.md` |
| Git workflow, branches, subtree | `docs/10_operations/GIT_WORKFLOW.md` |
| DB migrations, Prisma flow | `docs/10_operations/DATABASE_MIGRATIONS.md` |
| iOS release, Fastlane, TestFlight | `docs/10_operations/RELEASE_IOS.md` |
| Full doc index | `docs/01_source_of_truth/DOCUMENTATION_INDEX.md` |

## Deleted / Renamed Files (DO NOT REFERENCE)

These files no longer exist in root. If you see old references, use the replacement:

| Old name (DELETED) | Replacement |
|---|---|
| `PROJECT_KNOWLEDGE_v2.md` | `docs/04_database/SCHEMA_REFERENCE.md` + `docs/03_backend_and_api/API_REFERENCE.md` |
| `UI_DESIGN_DOCUMENT.md` | `docs/07_ui_ux/SCREEN_INVENTORY.md` + `docs/07_ui_ux/DESIGN_SYSTEM.md` |
| `CLAUDE 2.md` | This file (`CLAUDE.md`) |
| `HEXBOUND_UI_UX_AUDIT_GUIDE.md` | `docs/07_ui_ux/UX_AUDIT.md` |
| `HEXBOUND_UX_AUDIT_V2.md` | `docs/07_ui_ux/UX_AUDIT.md` |
| `BALANCE_AUDIT_REPORT.md` | `docs/06_game_systems/BALANCE_CONSTANTS.md` |
| Prompt files in root | Moved to `docs/08_prompts/` |
| `ShopItemCardView.swift` (DEPRECATED) | Use `ItemCardView` with `.shop` context instead |

## Game Enums (VERIFY BEFORE USE)

These are the **actual** backend enums. Do not invent values.

- **CharacterClass**: `warrior`, `rogue`, `mage`, `tank`
- **CharacterOrigin**: `human`, `orc`, `skeleton`, `demon`, `dogfolk` (NOT elf, NOT dwarf)
- **CharacterGender**: `male`, `female`
- **ItemType**: `weapon`, `helmet`, `chest`, `gloves`, `legs`, `boots`, `accessory`, `amulet`, `belt`, `relic`, `necklace`, `ring`, `consumable`
- **ItemRarity**: `common`, `uncommon`, `rare`, `epic`, `legendary`
- **DamageType**: `physical`, `magical`, `true_damage`, `poison`
- **QuestType**: `pvp_wins`, `dungeons_complete`, `gold_spent`, `item_upgrade`, `consumable_use`, `shell_game_play`, `gold_mine_collect` (NOT `pvp_win`, NOT `pvp_fight` — these don't exist)

## Property Access (CRITICAL)

- Before accessing a model property — **verify it exists** in the struct/class definition. Do NOT assume computed properties like `resolvedImageKey` exist — they may only be on some types.
- Different models (`Item`, `ShopItem`, `LootPreview`, `EquippedItem`, etc.) have **different property sets**, even if conceptually similar. Always check the specific type definition.
- If a needed property is **missing** — use the existing field directly (e.g. `imageKey` instead of `resolvedImageKey`) or **add** a computed property to the model.

## CodingKeys vs convertFromSnakeCase (CRITICAL)

`APIClient.shared` uses `.convertFromSnakeCase` key decoding strategy globally. When explicit `CodingKeys` are defined on a Codable struct, **the decoder ignores `.convertFromSnakeCase` and uses raw CodingKey values directly**.

**Problem:** Backend sends camelCase JSON (`pendingRequests`, `goldWager`). If your struct has `CodingKeys` mapping to snake_case (`case pendingRequests = "pending_requests"`), the decoder looks for literal `pending_requests` in JSON but finds `pendingRequests` — **decode silently fails**.

**Rules:**
1. If the backend sends **camelCase** keys (which is the default for Next.js `NextResponse.json()`), **do NOT add explicit CodingKeys** — let `.convertFromSnakeCase` pass camelCase through unchanged and match Swift property names directly.
2. Only use explicit CodingKeys when the backend sends **actual snake_case** keys (e.g., Prisma raw query results, or endpoints with manual snake_case formatting).
3. When in doubt, check the backend endpoint's `NextResponse.json({...})` — if it uses JS object shorthand with camelCase variable names, omit CodingKeys.

**Past incident:** `SocialStatus` had explicit CodingKeys (`pending_requests`, `unread_messages`), but backend sent camelCase. Decode silently failed, `cache.socialStatus` was always nil, Guild Hall badge never showed. Fixed by removing CodingKeys.

**Affected models (fixed):** `SocialStatus` (Social.swift)
**Models that still use CodingKeys correctly:** `FriendEntry`, `FriendRequest`, `FriendsListResponse` — verify these work; if backend sends camelCase for these too, remove their CodingKeys.

## Backend TypeScript Rules (CRITICAL)

- **All `get*Config()` functions in `src/lib/game/live-config.ts` are async.** Always `await` them. Missing `await` produces `Promise<number>` instead of `number` — the build will fail.
- **Never create files with spaces or " 2" in the name.** macOS sometimes creates `file 2.ts` copies. If you see them — delete them, they are junk.
- **`prisma generate` must run before `tsc`/`next build`.** Without it, TS reports false errors for all Prisma models (`mailRecipient`, `shopOffer`, etc. "not found on PrismaClient"). On Vercel this runs automatically via build command. Locally: `cd backend && npx prisma generate` first.
- **`ignoreBuildErrors` is REMOVED.** TypeScript errors now block the Vercel deploy. Do not reintroduce this flag. Fix TS errors properly.
- **Prisma `Json` fields need double cast.** When casting Prisma `Json` type to a concrete interface (e.g. `OfferContent[]`), use `as unknown as OfferContent[]` — direct cast fails in strict mode. For `InputJsonValue` fields (creating/updating records): use `(value ?? Prisma.JsonNull) as unknown as Prisma.InputJsonValue` to handle null fallback.
- **`runCombat()` is async.** Always `await runCombat(attacker, defender)`. Missing `await` produces `Promise<CombatResult>` — TS shows "property 'winnerId' does not exist on type 'Promise<CombatResult>'". Same applies to `calculateCurrentStamina()`.
- **`calculateCurrentStamina()` takes 3 args** — `(currentStamina, maxStamina, lastUpdate)`. It internally calls `getStaminaConfig()` for regen rate. Do NOT pass `REGEN_INTERVAL_MS` as 4th argument — "Expected 3 arguments, but got 4".
- **`StaminaResult` interface** — `{ stamina: number; updated: boolean }`. Use `.stamina` to get the computed value, NOT `.current` (does not exist).
- **Most game lib functions take `prisma` as first arg.** `applyLevelUp(prisma, characterId)`, `updateDailyQuestProgress(prisma, charId, questType, increment)`, `degradeEquipment(prisma, charId)`, `getKFactor(calibrationGames)` (async). When writing new API routes, **copy the exact call patterns from `pvp/fight/route.ts`** — it's the reference implementation.
- **`CombatResult` fields:** `{ winnerId, loserId, turns: Turn[], totalTurns: number, finalHp: Record<string, number> }`. Use `combatResult.finalHp[characterId]` for HP, `combatResult.totalTurns` for turn count, `combatResult.turns` for combat log. There is NO `.log`, `.duration`, `.player1FinalHp`, `.player2FinalHp`.
- **Before using any function — check its signature.** Open the source file (`combat.ts`, `stamina.ts`, `live-config.ts`, `progression.ts`, `balance.ts`) and verify: is it async? How many args? What does it return? **Or copy from `pvp/fight/route.ts`** which is known to work. Guessing signatures causes repeated Vercel build failures.

## Git Watcher (Auto-Commit from VM)

The project has a **git watcher script** at `scripts/git-watcher.sh` that enables auto-commit from Claude VM sessions.

**How it works:**
1. User runs `./scripts/git-watcher.sh` in a terminal tab on their Mac
2. Claude creates `.git-trigger` file with commit message as content
3. Watcher detects the file, runs `git add -A && git commit && git push origin main`
4. If `admin/` changed, watcher also runs `git subtree push`

**To trigger a commit from VM:** `echo "commit message" > .git-trigger`

**Why needed:** Git operations on mounted filesystem frequently fail with `Unable to create .git/index.lock: File exists` — the VM cannot delete lock files (`Operation not permitted`). The watcher runs natively on macOS where locks work normally.

**IMPORTANT:** Always use the watcher for commits when available. Direct `git commit` from VM will likely fail due to lock files.

## Merge Conflict Resolution (CRITICAL)

After ANY `git merge` or `git pull --no-rebase`, **NEVER** blindly `git add -A && git commit`. This stages unresolved conflict markers (`<<<<<<<`) which break builds.

**Mandatory steps after merge with conflicts:**
1. **Grep for markers first:** `grep -rn "^<<<<<<<" backend/ admin/` — if any hits, fix them before committing.
2. **For `add/add` conflicts** (both sides added the same file) — one version overwrites the other. Pick the correct version explicitly.
3. **For auto-generated files** (`tsconfig.tsbuildinfo`, `*.lock`) — delete the conflicted file; it will regenerate on next build.
4. **Never trust `git checkout --theirs`/`--ours` during rebase** — "theirs" and "ours" are swapped compared to merge. Verify the file content after.
5. **Seed scripts / Prisma files** — particularly prone to conflicts since both local and remote may have edited the same `.finally()` block.

**Grep must scan ALL files, not just backend/admin:**
```bash
grep -rn "^<<<<<<<\|^=======\$\|^>>>>>>>" . --include="*.swift" --include="*.md" --include="*.ts" --include="*.tsx" --include="*.prisma" | grep -v node_modules | grep -v ".git/"
```
An orphaned `<<<<<<< HEAD` without a matching `=======`/`>>>>>>>` can survive partial conflict resolution. Always grep after resolving.

**Past incidents:**
- Merge with ~25 conflicts was committed with `git add -A` without resolving. `seed-dungeon-drops.ts` had `<<<<<<< HEAD` at line 330, broke Vercel build.
- CLAUDE.md had orphaned `<<<<<<< HEAD` marker (without `=======`/`>>>>>>>`) after partial conflict resolution — persisted until next audit.

## Prisma Migrate Resolve Gotcha (CRITICAL)

`prisma migrate resolve --applied <name>` marks a migration as applied in `_prisma_migrations` table **WITHOUT executing the SQL**. It only updates the migration history — the actual DDL is NOT run.

**When to use:** Only when the SQL was already applied manually (e.g., via Supabase SQL editor) and you need Prisma to acknowledge it.

**When NOT to use:** When the migration SQL has not been run yet. In that case, either run `prisma migrate dev` (local) or `prisma migrate deploy` (production), or apply the SQL manually first via `execute_sql` / Supabase dashboard, THEN `resolve --applied`.

**Past incident:** Social system migration was marked as applied via `resolve`, but tables `friendships`, `direct_messages` and column `last_active_at` never existed in the database. All API endpoints returned 500 because Prisma client expected these tables. Fixed by manually executing the migration SQL via Supabase MCP.

**Verification after any migration:**
```sql
SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'characters' ORDER BY ordinal_position;
```
Always verify the expected tables/columns actually exist after migration.

## Color Token Shorthand in SwiftUI (CRITICAL)

When using DarkFantasyTheme colors in SwiftUI views, **always use the full prefix**: `DarkFantasyTheme.textPrimary`, NOT `.textPrimary`.

Bare shorthand like `.textPrimary` only works if a `Color` extension exists in `DarkFantasyTheme.swift`. If it doesn't, the build fails silently or picks a wrong type. **Always use the full form to be safe.**

Common violations caught post-merge:
- `.foregroundStyle(.textPrimary)` → `.foregroundStyle(DarkFantasyTheme.textPrimary)`
- `color: .bgAbyss` → `color: DarkFantasyTheme.bgAbyss`
- `CircularProgressViewStyle(tint: .textPrimary)` → `CircularProgressViewStyle(tint: DarkFantasyTheme.textPrimary)`

## Replacing / Refactoring Code (CRITICAL)

When replacing a struct, class, function, or view with a new version:
1. **Delete the old code first** — do not leave both old and new versions in the file. Duplicate symbols cause "Invalid redeclaration" and argument-mismatch build errors.
2. **Search the file for the old name** before finishing — if the old struct/function still exists anywhere, remove it.
3. **Search all callers** — if the old type was used in other files, update those call sites to match the new signature.
4. Common mistake: replacing `CloudLayer` → `SkyCloudsFrontLayer` but leaving the old `CloudLayer` + `DriftingCloud` in the same file → redeclaration error.

## SwiftUI Code Patterns (CRITICAL)

### Optional ViewModel & NavigationStack Animation Fix (CRITICAL)
- All screens using `@State private var vm: SomeViewModel?` with `if let vm { ... }` MUST add `.transaction { $0.animation = nil }` on the root content inside the conditional.
- **Why:** NavigationStack applies a push/pop transition. When `.task` creates the VM (nil → non-nil), the content appearance gets caught in that transition, causing a visible "stretch from left/right" layout animation.
- **Single-view pattern:** `if let vm { VStack { ... }.transaction { $0.animation = nil } }`
- **Multi-branch pattern:** `if let vm { Group { if ... else ... }.transaction { $0.animation = nil } }`
- This does NOT disable explicit `withAnimation` calls inside the view — only the implicit transition animation.
- **Applied to (14 screens):** ArenaDetailView, ShopDetailView, SettingsDetailView, LeaderboardDetailView, DailyQuestsDetailView, AchievementsDetailView, ShellGameDetailView, GoldMineDetailView, DungeonRushDetailView, DailyLoginDetailView, AppearanceEditorDetailView, DungeonSelectDetailView, DungeonRoomDetailView, BattlePassDetailView.
- **Any new screen** with optional VM MUST follow this pattern.

### Extension Closures & Compilation
- `extension ButtonStyle where Self == X { ... }` MUST have matching closing `}`. Missing braces cause "Declaration only valid at file scope" errors on unrelated files.
- When adding closures (`.onChange`, etc.) to multiple extensions, verify each extension's closing brace is present. Common mistake: last extension is missing its `}`.

### Collection Types in SwiftUI
- `stride(from:to:by:)` returns `StrideTo<Int>`, which does NOT conform to `RandomAccessCollection`. SwiftUI `ForEach` requires a collection. Must wrap: `ForEach(Array(stride(...)))`.
- Other similar iterators (e.g., `sequence(first:next:)`) have the same constraint.

### Graphics & Strokes
- `.stroke()` has NO `dash:` parameter. Must use `StrokeStyle`: `.stroke(color, style: StrokeStyle(lineWidth: 1, dash: [4]))`.
- This applies to all `Shape` stroke calls.

### Character Model Properties
- Character has `.avatar` (the appearance key), NOT `.skinKey`. The skin key is on `AppearanceSkin` model.
- Before accessing model properties — **verify in the struct definition**, especially for appearance/equipment data.

### PvP & Rating Data Models
- `PvPRank` has NO `.displayName` computed property. Use `.rawValue` instead ("Bronze", "Silver", etc.).
- `LeaderboardEntry` contains ONLY: `characterId`, `characterName`, `characterClass` (String, not enum), `value` (rating), `rank`. No avatar, no equipment, no stats.
- `OpponentProfile` is the model for full public character profiles (via `GET /api/characters/:id/profile`). Contains: stats, equipment, avatar, HP with regen, stance, rating, record, win rate. Use this when displaying opponent details in PvP sheet.
- Convert `characterClass` String to enum: `CharacterClass(rawValue: entry.characterClass) ?? .warrior`.
- **ItemRarity.color** is now a computed property — use it for rarity-colored borders, badges, and UI elements in opponent profile grids.

### UI Effects & Interaction Feedback
- **Glow effects must be tap-only, not idle.** Both Hub buildings and Dungeon map buildings had permanent idle glow. Remove `.startIdleAnimation()` from map buildings. Set `opacity: 0` and `shadowRadius: 0` in default state; only apply glow on `.isPressed`.
- This prevents visual clutter and respects the no-scale-animations rule (glow is opacity/shadow, not scale).

### Assets vs. Emojis
- When an emoji system is in place (e.g., Daily Login rewards, Battle Pass rewards), replace ALL emojis with game assets.
- Pattern: add `assetIcon` computed property to the model, create a helper view (`rewardIcon()`) with asset-first fallback to emoji.
- Applies to any screen with reward pills, badges, or status indicators.

### Currency Display (CRITICAL)
- **Never use SF Symbols for currency** (e.g., `dollarsign.circle`, `diamond`). Use `CurrencyDisplay` component instead.
- **Never create inline currency HStacks** (icon + Text). Always use `CurrencyDisplay`.
- Component: `Hexbound/Hexbound/Views/Components/CurrencyDisplay.swift`
- **Sizes:** `.standard` (36px icons, 28px text — shop header, GET CURRENCY balance), `.compact` (14px — UnifiedHeroWidget, inventory header), `.mini` (12px — price tags on cards, item detail prices)
- **Currency type:** `.both` (default — gold + gems), `.gold` (only gold), `.gems` (only gems) — use for single-currency displays like price tags
- **Animated:** `animated: true` (default — tick-up animation) or `animated: false` (static text — for inline headers, price tags)
- Uses game assets `icon-gold` and `icon-gems` — consistent across all screens
- **Where used:** ShopDetailView (.standard), UnifiedHeroWidget (.compact), HeroDetailView inventory header (.compact), CurrencyPurchaseView balance (.standard), ShopItemCardView price (.mini), ItemDetailSheet buy/sell (.mini), all future currency displays

### Public Profile & Sheet Presentation
- **Opponent profile sheet** uses `.sheet(item:onDismiss:content:)` with `.large` detent (NOT ZStack overlay).
- Model: `OpponentProfile.swift` — public character data returned by `GET /api/characters/:id/profile`.
- Profile card layout: portrait + level/rank badges → HP bar → PvP stats grid → equipment grid → base stats (8 cols in 2-col grid) → derived stats → action buttons.
- Equipment grid: use `ItemCardView(.equipment(...))` — each slot automatically tints border with `ItemRarity.color`.
- **Challenge button** sends a real challenge via `ChallengeService.shared.sendChallenge()` — shows loading spinner, then "Challenge Sent" state with toast. No closure needed — handled internally.
- **Message button** is still a stub TODO (Phase 2).
- **Add Friend button** is a 6-state machine (`FriendshipButtonState`) — fully functional.
- When extending opponent profile, verify endpoint returns the needed fields (check `OpponentProfileResponse` wrapper in backend).
- HP bar on opponent profile: shows current HP + max HP, no regen indicator in sheet view (regen is only in detailed stats).

## Toast & Notification System (CRITICAL)

**Toast deduplication is mandatory.** `AppState.showToast()` deduplicates by title — if a toast with the same title is already visible, it resets the timer instead of stacking a second one.

**Max 1 visible toast at a time.** New toasts replace old ones. Queue managed by `showToast()` — never show a wall of errors.

**Session expired = blocking modal, NOT a toast.** The 401 handler calls `appState.triggerSessionExpired()` which shows `SessionExpiredModalView` — a non-dismissable modal with a single "Log In" CTA. Never show session expiry as a toast.

**Error toasts should have Retry buttons.** For "Failed to load X" errors, always pass `actionLabel: "Retry"` with a closure that retries the failed operation. Actionable toasts auto-dismiss in 5 seconds (vs 3 for passive).

**Toast icons (not dots).** Each `ToastType` has an `icon` SF Symbol property (e.g., `exclamationmark.triangle.fill` for error). The UI shows a 28×28 tinted icon container instead of an 8px colored dot — for WCAG compliance (color + icon + text).

**Swipe to dismiss.** All toasts support swipe-up gesture to dismiss immediately. The swipe handle hint (24×3pt capsule) is visible at the top of the toast.

**Component:** `SessionExpiredModalView.swift` — blocking modal for 401 errors, follows standard ornamental modal pattern.

## File Hygiene (CRITICAL)

**Never leave temp/backup files inside `.xcodeproj` bundle.** Files like `.bak`, `.backup`, `.tmp1`–`.tmp5` inside `Hexbound.xcodeproj/` will cause Xcode to fail loading the project with "Couldn't load project" error.

**Why:** Xcode scans the bundle for project metadata. Stray files break parsing, even if they're not referenced in `project.pbxproj`.

**After ANY pbxproj editing or scripted changes:**
1. Verify the bundle is clean:
   ```bash
   ls Hexbound/Hexbound.xcodeproj/ | grep -E '\.(bak|backup|tmp)$'
   ```
   Should return nothing. Only these directories/files should exist: `project.pbxproj`, `project.xcworkspace/`, `xcshareddata/`, `xcuserdata/`

2. Delete any junk files:
   ```bash
   rm -f Hexbound/Hexbound.xcodeproj/*.bak Hexbound/Hexbound.xcodeproj/*.backup Hexbound/Hexbound.xcodeproj/*.tmp*
   ```

3. Verify Xcode loads: `open Hexbound/Hexbound.xcodeproj` should not produce "Couldn't load project" error.

**Common culprits:** Agents running scripts that create backups with `cp file.pbxproj file.pbxproj.backup` directly in the bundle, or shell loops that generate `file.tmp1`, `file.tmp2`, etc.

## Self-Documenting Rules (META — MANDATORY)

After completing ANY task (feature, bugfix, cleanup, docs, UI, balance, deploy), do a **post-task review**:

1. **Re-read this `CLAUDE.md`** and check: did I follow all rules? Did I miss a step (Prisma sync? admin subtree push? Xcode pbxproj? design tokens verification?)?
2. **Check if a new rule is needed.** If during work you discovered a pattern, bug, gotcha, or practice that:
   - **repeats** across sessions (same mistake / same manual step),
   - **breaks the build** or causes a runtime crash,
   - requires **non-obvious project knowledge** (API quirks, model specifics, dependencies),
   - would **save time** for the next agent or human working on this project,
   then **automatically add a new rule** to this `CLAUDE.md` without asking. Format: brief problem description + what to do / what not to do. Choose the section by topic or create a new one.
3. **Check if docs need updating.** If the task changed behavior, schema, API, screens, balance, or config — update the relevant canonical doc in `/docs/`. Refer to the Documentation Quick Lookup table above.
4. **Commit the rule/doc update** together with the task commit or as a separate `docs(claude):` commit.

This is not optional. Every task ends with this review. The goal: `CLAUDE.md` and `/docs/` stay current automatically, without the user having to ask.
