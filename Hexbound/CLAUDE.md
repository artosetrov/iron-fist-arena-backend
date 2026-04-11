# Hexbound iOS — SwiftUI Rules

> Parent rules: see root `CLAUDE.md` for architecture, enums, tokens, deploy, git.

## Ornamental Design System (CRITICAL)

All UI uses pure SwiftUI ornamental system — **no PNG assets for UI chrome**. Primitives in `OrnamentalStyles.swift`.

**Components:**
- `RadialGlowBackground` — replaces flat `bgSecondary` fill. Always use for panels.
- `BarFillHighlight` — top-edge shine. **All progress bars** (HP, XP, Stamina) via `.overlay(BarFillHighlight(cornerRadius:))`
- `DiamondDividerMotif` — center motif for dividers
- `CornerBracketOverlay`, `CornerDiamondOverlay`, `SideDiamondOverlay` — corner/edge accents
- `InnerBorderOverlay` — inset gradient stroke
- `SurfaceLightingOverlay` — top-bright/bottom-dark convex effect
- `DoubleBorderOverlay`, `ScrollworkDivider`, `FiligreeLine`, `EtchedGroove` — structural

**Convenience extensions (prefer these):**
- `.cornerBrackets()`, `.cornerDiamonds()`, `.sideDiamonds()`
- `.innerBorder()`, `.surfaceLighting()`
- `.doubleBorder()`, `.etchedGroove()`, `.premiumFrame()`
- `.ornamentalFrame()` — combo of all

**Standard panel pattern:**
- `RadialGlowBackground(baseColor: .bgSecondary, glowColor: .bgTertiary, glowIntensity: 0.4, cornerRadius: LayoutConstants.cardRadius)`
- `.surfaceLighting(cornerRadius: cardRadius, topHighlight: 0.08, bottomShadow: 0.12)`
- `.innerBorder(cornerRadius: cardRadius - 2, inset: 2, color: borderMedium.opacity(0.15))`
- `.cornerBrackets(color: accent.opacity(0.3), length: 14, thickness: 1.5)`
- `.shadow(color: bgAbyss.opacity(0.4), radius: 6, y: 3)`

**Standard modal pattern:** Same as panel but: `modalRadius`, topHighlight 0.10, bottomShadow 0.16, brackets length 18 + cornerDiamonds, dual shadow (accent glow + bgAbyss).

**Exceptions:**
- Circle shapes (XP rings, stat rings): use `RadialGradient` directly
- Flat `bgSecondary`: HubView background, ToastOverlayView, ScreenCatalogView (dev)
- `Color.white`/`.black`: ONLY in ornamental overlays at 0.06–0.08 opacity

**Press state:** `.brightness(-0.06)` not `.opacity(0.85)`.
**Shadows:** Always dual — type-colored glow + dark `bgAbyss`. Never single flat shadow.

## GPU Performance (CRITICAL)

- **`.compositingGroup()`** MANDATORY after 2+ ornamental overlays. `CardStyles` and `ornamentalFrame()`/`premiumFrame()` include it. Custom stacks — add it yourself.
- **`.drawingGroup()`** for heavy Path/Canvas views (CityMapView, FortuneWheelView).
- **`.repeatForever` animations** MUST stop on `.onDisappear` — NavigationStack keeps views in memory.
- **Damage popups** capped at 5 concurrent.
- **Cache-first pattern:** Show cached data → loading only if empty → fetch background → update UI. TTLs: quests 60s, achievements/battlepass 120s, shop 300s, opponents 30s.

## Radius Scale (CRITICAL)

All `cornerRadius` MUST use `LayoutConstants` tokens. Never hardcode.

- `radiusXS` (3), `radiusSM` (6), `radiusMD` (8), `radiusLG` (12), `radiusXL` (16), `radius2XL` (22)
- Aliases: `cardRadius` (12), `panelRadius` (8), `modalRadius` (16), `buttonRadius` (8), `heroCardRadius` (12), `widgetRadius` (12), `arenaCardRadius` (16)
- Exception: circle skeletons use `width/2`

## Shadow System

Always use dual shadows: accent glow + dark depth. Never single flat shadow.

**Presets** (in `OrnamentalStyles.swift`):
- `ShadowDepth.text` — radius 2, y 1 (stat rows, labels)
- `ShadowDepth.panel` — radius 4, y 2 (light panels)
- `ShadowDepth.card` — radius 6, y 3 (standard cards) ← **most common**
- `ShadowDepth.elevated` — radius 8, y 4 (elevated surfaces)
- `ShadowDepth.modal` — radius 32, y 8 (heavy modals)

**Convenience modifiers:**
- `.cardShadow()` — bgAbyss card depth (replaces inline `.shadow(color: bgAbyss.opacity(0.4), radius: 6, y: 3)`)
- `.subtleShadow()` — bgAbyss text depth
- `.dualShadow(glowColor:glowRadius:depth:)` — accent glow + depth in one call
- `.depthShadow(.card)` — depth-only (no glow)
- `.badgeCapsule(color:)` — padded capsule with tinted fill + stroke

## Icon Size Scale

| Token | Value | Use |
|-------|-------|-----|
| `iconXS` | 12 | Micro icons, status dots |
| `iconSM` | 16 | Pill icons, badge icons |
| `iconMD` | 20 | List row icons, nav icons |
| `iconLG` | 24 | Action icons, toolbar |
| `iconXL` | 32 | Empty state, fallback |
| `icon2XL` | 48 | Hero icons, celebration |

## Opacity Scale

| Token | Value | Use |
|-------|-------|-----|
| `opacityMicro` | 0.04 | Very subtle backgrounds |
| `opacitySoft` | 0.08 | Shimmer, highlights |
| `opacityLight` | 0.12 | Pill backgrounds |
| `opacityMild` | 0.15 | Border accents |
| `opacityMedium` | 0.25 | Rarity glows |
| `opacityStrong` | 0.40 | Glow shadows |
| `opacityHeavy` | 0.60 | Strong overlays |
| `opacityDense` | 0.75 | Modal backgrounds |
| `opacityOpaque` | 0.85 | Heavy backdrops |

## Motion System (CRITICAL)

**Always use the unified Motion System** for animations, haptics, and micro-interactions. Never hardcode animation durations or haptic calls.

- **Timing**: `MotionConstants` (`Theme/MotionConstants.swift`) — 5 speed tiers (instant/fast/normal/reward/epic), easing presets, shake/progress/reveal constants
- **Ceremony phases**: `navigationDelay` (0.15), `ceremonyPhase1` (0.3) → `ceremonyPhase5` (1.6), `ceremonyButton` (1.8), `ceremonySlow` (2.5)
- **Haptics**: `HapticManager` (`Theme/HapticManager.swift`) — `@MainActor enum`, static methods. Compound patterns: `.victory()`, `.defeat()`, `.legendaryReveal()`, `.rankUp()`, `.shake()`, `.coinCascade(count:)`
- **Modifiers**: `.staggeredAppear(index:)`, `.glowPulse(color:intensity:isActive:)`, `.breathing(scale:isActive:)`, `.shimmer(color:duration:)`
- **Components**: `NumberTickUpText` (animated counters), `RewardBurstView` (particle burst with `BurstStyle` enum), `SeasonSummaryModalView`, `EventBannerView`
- **Combat events**: `CombatViewModel.CombatEventType` enum → `CombatDetailView.handleCombatEvent()` for differentiated shake + haptics + crit flash
- **Modal queue**: `AppState.enqueueModal()` / `.presentNextModal()` / `.dismissXxxModal()` — prevents overlapping modals
- **Slam overlay pattern**: For dramatic text reveals (VS, BOSS FIGHT), use: `scaleEffect(from→to)` + opacity + dimmed background + `DispatchQueue.main.asyncAfter` phase chain. Always pair with `HapticManager.heavy()`.
- **Rules**: Haptic = special moments only (never on scroll/passive). No persistent particles. No shimmer on prices. Respect `MotionConstants` speed tiers.

## Animation Rules (CRITICAL)

### NO SCALE ANIMATIONS
Never use `.scaleEffect()` for press feedback, pulsing, breathing, bounce, or appear/reveal. Use `.opacity(isPressed ? 0.85 : 1)` instead. Static `.scaleEffect(0.8)` for sizing and `.scaleEffect(x: -1)` for mirroring are OK. Particle effects (RewardBurst, CoinFly, VFX) are exempt.

### SwiftUI Looping Animations
When using `.repeatForever()` on value-driven animations (offset, rotation, opacity, scale):
- **Back-and-forth effects** (shimmer sweep, breathing glow, pulsing scale): ALWAYS use `autoreverses: true`. With `autoreverses: false` the value snaps back causing a visible jump.
- **Continuous rotation** (spinning icons, border glow angle): use `autoreverses: false` — rotation 0→360 wraps naturally.
- **Rule of thumb**: if start ≠ end creates a visual discontinuity (e.g. offset -1.2 → 1.5), you MUST autoreverse.
- Never use `.delay()` with `.repeatForever(autoreverses: false)` on position/offset — the delay fires only once, then the snap repeats every cycle.

### Fight Button Style
`FightButtonStyle` — **no animation**. Only `opacity(isPressed ? 0.85 : 1)` for press feedback. No shine overlays, `scaleEffect`, breathing, or `.animation()` modifiers.

### Glow Effects
Tap-only, not idle. Default `opacity: 0`, `shadowRadius: 0`. Only glow on `.isPressed`.

## SFX Sound System (CRITICAL)

**Always use `SFXManager` for sound effects.** Never use `AVAudioPlayer` directly for SFX — only `AudioManager` handles BGM.

- **Manager**: `SFXManager.shared` (`Persistence/SFXManager.swift`) — `@MainActor` singleton, pooled `AVAudioPlayer` instances (polyphonic), auto-caching, respects `sfxVolume` and `isMuted` from `SettingsManager`
- **Catalog**: `SFX` enum (same file) — all available sound effect keys. If a WAV file is missing from bundle, playback is silently skipped (no crash)
- **Audio files**: `Resources/Audio/SFX/*.wav` — 16-bit 44.1kHz WAV, dark fantasy style
- **Combat mapping**: `SFX.from(vfxType:)` maps `VFXEffectType` → `SFX` enum case. Always call SFX alongside VFX triggers in `CombatViewModel.animateTurn()`
- **UI sounds**: Button styles (`PrimaryButtonStyle`, `SecondaryButtonStyle`, `DangerButtonStyle`, `NavGridButtonStyle`) already trigger SFX via `onChange(of: configuration.isPressed)`. `TabSwitcher` triggers on tap and swipe.
- **Adding new SFX**: (1) Add `.wav` to `Resources/Audio/SFX/`, (2) add case to `SFX` enum, (3) add to `project.pbxproj` (PBXBuildFile + PBXFileReference + PBXGroup + PBXResourcesBuildPhase), (4) call `SFXManager.shared.play(.newCase)` at trigger point
- **Preloading**: `SFXManager.shared.preload([...])` on screen appear for latency-critical sounds (combat preloads all hit/block/miss)
- **Rules**: SFX on meaningful interactions only (never scroll/passive). Pair with `HapticManager`, not replace. Keep files short (< 1s UI, < 0.7s hits). Respect `isMuted`.

## Stat Colors — Unified Gold Palette

All stat UI uses gold palette — never per-stat rainbow.
- `statBoosted` (goldBright), `statBase` (goldDim), `statBarFill` (gold)
- `statBarColor(value:base:)`, `statBarGradient(value:base:)`, `statColor(for:)`
- Legacy `statSTR`/`statAGI`/etc. are `@available(*, deprecated)`

## Art Style

- Style: pen and ink, bold outlines, muted earth tones, grimdark dark fantasy
- Start: `Pen and ink illustration of...`
- End: `isolated on white background, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text`
- Full guide: `Hexbound/ART_STYLE_GUIDE.md`

## Asset File Naming (CRITICAL)

**No spaces, colons, or special characters in asset filenames.** macOS silently allows them, but they cause issues with Xcode, git, and CI.

- **Images**: lowercase with hyphens: `hub-bg-3.png`, `boss-arena-warden.png`
- **Audio**: lowercase with hyphens: `stray-city.mp3`, `arena-pvp.mp3`
- **Never**: `Hub bg 3.png`, `Arena : PvP.mp3`, `image 12.png`
- After renaming, update ALL references: `project.pbxproj`, Swift string literals (`AudioManager.shared.playBGM("...")`)
- The icon `icon-gold-mine` is in a DIFFERENT casual/cartoon style — do NOT use as art style reference

## Asset Images: xcassets Imageset (CRITICAL)

When adding a new image to the iOS app:
1. Create an `.imageset` folder inside `Resources/Assets.xcassets/` (e.g. `shopkeeper.imageset/`)
2. Copy the image file into the imageset folder
3. Create a `Contents.json` with the correct `filename`, `idiom: "universal"`, and scale entries
4. Reference in code as `Image("shopkeeper")` — the name matches the folder name (without `.imageset`)
5. Use `UIImage(named:) != nil` guard for safe fallback

Do NOT place raw images in random project folders and reference them by path — they won't load at runtime.

## Swift Concurrency

- Types accessing `@MainActor`-isolated properties MUST be `@MainActor`
- `L10n` enum is `@MainActor`
- `[weak self]` ONLY in classes (ViewModels, Services). SwiftUI Views are structs — no capture list needed.

## UI Components

### UnifiedHeroWidget
Character summary display. Contexts: `.hub`, `.arena`, `.dungeon`, `.hero`. Never create inline character displays.
- Deprecated: `HubCharacterCard.swift`, `HubCharacterCardWrapper`

### HeroIntegratedCard
Equipment-first layout on Hero page (INVENTORY tab only). Portrait + bars + equipment grid + action pills.
- Component: `Views/Components/HeroIntegratedCard.swift`
- Combines: equipment grid + portrait + name/class overlay + Stamina/HP/XP bars + stance card + action pills
- STATUS tab: stat points → grouped stats → respec → derived stats → equipment bonuses
- Sticky tabs above ScrollView, gold capsule badge on STATUS tab when stat points available
- Universal slots: `amulet` accepts amulet OR necklace; `relic` accepts relic OR accessory OR weapon off-hand
- **Card layout order** (top to bottom): Stamina bar → equipment grid → divider → HP bar → XP bar → stance card → action pills
- **Stamina bar ON TOP** — orange bar above equipment grid, not below
- Portrait: 2×3 cell grid with name + CLASS overlay (gradient transparent→black, Oswald 16px), level badge "Lv. X" (gold capsule top-right), class icon badge (top-left), gradient fade on avatar bottom, low-HP red pulse overlay
- Portrait spacing: `LayoutConstants.heroPortraitSideGap` controls gap between side slots and portrait
- Bars: HP 24px tall with text centered inside; XP 20px tall with absolute values not percentage; Stamina 20px tall (orange gradient)
- **Stance preview** — full-width card with zone assets (NOT emoji pills). Shows attack zone left, "STANCE" label center, defense zone right. Uses `StanceSelectorViewModel.zoneAsset(for:)` and `.zoneColor(for:)`. Tappable → `onEditStance`.
- Action pills: repair all (conditional), stat points (conditional), heal (conditional)
- **Durability ring overlay** on equipment slots — `DurabilityRingOverlay` shows remaining durability as partial border ring when < 100%
- Layout tokens: `LayoutConstants.hero*` for card/slot sizing and bar heights
- Stance is separate `StanceDisplayView` below the card

### StanceDisplayView
Two-slot layout: Attack (red) | Divider | Defense (blue). Use `isInteractive: true` for tap-to-edit.
- Zone colors: `zoneHead` (red), `zoneChest` (blue), `zoneLegs` (green)
- Zone icons: `icon-helmet`, `icon-chest`, `icon-legs`

### ItemCardView
Single source of truth for item cells. Contexts: `.inventory()`, `.shop()`, `.equipment()`, `.loot`, `.preview`.
- Price: `CurrencyDisplay` with `.mini` (never SF Symbols)
- Deprecated: `ShopItemCardView.swift`

### CurrencyDisplay
Always use for gold/gems display. Sizes: `.standard` (36px), `.compact` (14px), `.mini` (12px).
- Types: `.both`, `.gold`, `.gems`. Never use SF Symbols for currency.

### Toast System
Signature: `appState.showToast(_ title:, subtitle:, type:, actionLabel:, action:)`. First arg positional. No `.success` type — use `.info` or `.reward`.
- Types: `.achievement`, `.levelUp`, `.rankUp`, `.quest`, `.reward`, `.info`, `.error`
- Error toasts: always include `actionLabel: "Retry"` + retry closure
- 401 → `SessionExpiredModalView` (blocking modal, NOT toast)

### NPC Guide Widget
`MerchantStripView` is a **reusable NPC guide widget** — not shop-specific. Can be used on any screen with any NPC.
- **Tokens**: `LayoutConstants.npc*` — `npcAvatarSize`, `npcBarHeight`, `npcBarRadius`, `npcBarPaddingH/V`, `npcOuterPadding`, `npcMiniSize`
- **Layout**: ZStack — NPC image (back layer) + speech card (front layer). Card has rounded corners (`npcBarRadius = 12`), equal outer padding on all sides (`npcOuterPadding = 16`)
- **Reuse**: Pass `npcImageName:` to change portrait. Title text should be parameterized.
- **Placement**: Wrap in `VStack { Spacer(); widget.padding(.horizontal, npcOuterPadding).padding(.bottom, npcOuterPadding) }` to pin to bottom.
- Legacy `merchant*` aliases exist in LayoutConstants — prefer `npc*` tokens for new code.
- **Tutorial tooltips** use the SAME NPC strip style. `TutorialTooltipView` follows the identical visual pattern. If you change the NPC strip style — update BOTH `MerchantStripView` AND `TutorialTooltipView`.

## Screen Layouts

### Arena
Sticky title + tabs (OPPONENTS / REVENGE / HISTORY) above ScrollView. Refresh button pinned bottom (opponents only).

### Guild Hall (Social Hub)
3 tabs: ALLIES / SCROLLS / DUELS. Route: `AppRoute.guildHall`.
- Models: `Social.swift`, `Challenge.swift`, `Message.swift`
- Services: `SocialService`, `ChallengeService`, `MessageService` (all singletons)
- Any player can message any player (not restricted to friends)
- Deep-link: `AppRoute.guildHallMessage(characterId:characterName:)`

### Hub Building System
Config: `CityBuildingConfig.swift` → `defaultCityBuildings`. Set `route: nil` for Coming Soon.
- Badges: gold capsule in `badgeFor()` — arena (FREE N), achievements (N), battlepass (N), gold-mine (READY), guild-hall (N)
- Badge color is always gold

### Hub ↔ Dungeon Map Transition
The dungeon map is **embedded inside HubView**, not presented as a fullScreenCover. Both maps live in a ZStack and crossfade via `showDungeonMap` state.
- **HubView** owns `@State showDungeonMap` and `@State dungeonPath = NavigationPath()`
- **CityMapView** — visible when `showDungeonMap == false`
- **DungeonMapView** — inside its own `NavigationStack(path: $dungeonPath)`, visible when `showDungeonMap == true`
- **Bottom button** — toggles between ADVENTURES ↔ CASTLE, triggers `withAnimation(.easeInOut(duration: 0.45))` crossfade
- **HUD stays in place** — hero widget, floating icons, and bottom button don't move during transition
- **Top fade gradient** — 40pt `LinearGradient` from `bgPrimary` to clear, overlaid on map area
- **Dungeon navigation** — tapping a building pushes `DungeonRoomDetailView` inside `dungeonPath` NavigationStack. Back from room returns to dungeon map.
- **`DungeonMapCoverView` is DELETED** — do NOT recreate or use fullScreenCover for the dungeon map
- **`MainRouterView.destination(for:)`** — static method for routing AppRoute → View. Used by both `mainPath` and `dungeonPath` NavigationStacks.

### Public Profile Sheet
`.sheet(item:)` with `.large` detent. Model: `OpponentProfile`. Equipment grid uses `ItemCardView(.equipment())`.
- Challenge/Message/AddFriend buttons all fully functional

## Asset & Icon Rules (CRITICAL)

### Combat Zone Icons — Assets, Not Emoji
**Never use emoji (⚔️, 🛡️, 🎯, 🦿) for attack/defense zone indicators.** Always use asset images:
- `head` → `Image("icon-helmet")`, `chest` → `Image("icon-chest")`, `legs` → `Image("icon-legs")`
- **Canonical mapping**: `StanceSelectorViewModel.zoneAsset(for:)` — use everywhere, never hardcode.
- **Sizes**: 32×32 in zone selector buttons, 18×18 in inline labels, 16×16 in compact rows.
- **WidgetPill**: Use `imageAsset:` parameter (not emoji `icon:`) for zone icons.

### Card Icons — Assets, Not Emoji
**Never use emoji (🎯, 🎁, ❓) as icons in HUD cards, banners, or WidgetPills.** Always use asset images from `Assets.xcassets`. For WidgetPill, use `imageAsset:` parameter.
- `FirstWinBonusCard` → `Image("reward-first-win")`
- `DailyLoginCard` → `Image("hud-gift")`

### HUD Cards Over Map — Opaque Backgrounds
Any card/banner/widget floating over the map **must use `DarkFantasyTheme.bgSecondary`** as background fill — NOT translucent tints like `color.opacity(0.08)`. Translucent cards become invisible against dark map artwork.
- Background: `RoundedRectangle(...).fill(DarkFantasyTheme.bgSecondary)`
- Stroke: at least `opacity(0.5)` and `lineWidth: 1.5` for visibility
- If interactive, wrap in `Button` with `.buttonStyle(.plain)`, add `chevron.right`, SFX + haptics on tap

### Enemy Avatar Mirroring
In combat, VS, and comparison views, **mirror the enemy avatar horizontally** with `.scaleEffect(x: -1, y: 1)`. Player faces right (default), enemy faces left (mirrored). Applies to: `CombatDetailView`, `ArenaComparisonSheet`.

### Assets vs Emojis
Replace emojis with game assets when available. Add `assetIcon` computed property to models.

## Sizing Rules

### Minimum Font Size (CRITICAL)
**Minimum font size is 16px.** No text in the app should be smaller than 16px — including SF Symbol icons, price labels, captions, badges.
- `LayoutConstants.textBadge`, `textCaption`, `textLabel` are all set to **16**. Do NOT lower them.
- Only exception: emoji glyphs where the size controls the glyph, not readable text.

### Section Spacing — `sectionGap` Token
**Use `LayoutConstants.sectionGap` (16pt)** for the main `ScrollView` → `VStack(spacing:)` on every content screen.
- **`sectionGap` (16pt)** — gap between major blocks. Use for main `VStack(spacing:)`.
- **`spaceLG` (24pt)** — reserved for dramatic separation inside modals, empty states, auth screens.
- **Do NOT use `spaceLG` for main screen content VStacks** — too much gap, especially with component padding.

### TabSwitcher Padding
Every `TabSwitcher` must use:
```swift
.padding(.horizontal, LayoutConstants.screenPadding)
.padding(.vertical, LayoutConstants.tabSwitcherPaddingV)
```
Token: `tabSwitcherPaddingV = 8`. Do NOT use raw `spaceSM` or skip vertical padding.

### Close/Dismiss Buttons
Always use `.buttonStyle(.closeButton)` (`CloseButtonStyle`). The label is just `Image(systemName: "xmark")`, the style handles everything (32×32 circle, `bgTertiary` fill, `textSecondary` 14pt bold icon, opacity press effect).

## CodingKeys vs convertFromSnakeCase (CRITICAL)

`APIClient` uses `.convertFromSnakeCase` globally. Rules:
1. Backend sends **camelCase** (default Next.js) → **do NOT add CodingKeys** — decoder handles it
2. Backend sends **snake_case** → CodingKeys raw values must be **camelCase** (what decoder produces)
3. **Only explicit mapping** for Swift keywords: `case characterClass = "class"`

Silent decode failures have caused: nil socialStatus (no Guild Hall badge), broken dungeon combat (no UI shown).

## SwiftUI Code Patterns (CRITICAL)

### Optional VM + NavigationStack
All `@State var vm: VM?` screens MUST add `.transaction { $0.animation = nil }` on root content inside `if let vm`. WARNING: this overrides `withAnimation()` — use `.animation(_, value:)` on specific views instead.

### Key Rules
- `stride(from:to:by:)` → wrap in `Array()` for `ForEach`
- `.stroke()` has no `dash:` — use `StrokeStyle(lineWidth:dash:)`
- Never ternary between different `ButtonStyle` types — use `if/else` with full `Button` in each branch
- `SFX` cases: `.uiTap`, `.uiConfirm`, `.uiSuccess`, `.uiError` (NOT `.tap`, `.confirm`)
- `APIError.serverError` has 2 values: `(statusCode: Int, message: String)` — always destructure both
- Complex `body` → break into sub-methods with `: some View` return type

### APIClient Signatures
- `getRaw(_:params:)` — positional first arg, `params:` (NOT `endpoint:`, NOT `queryItems:`)
- `postRaw(_:body:)` — body `[String: Any]`, returns `[String: Any]`
- `get(_:params:)` — generic, returns `T: Decodable`
- `post(_:body:)` — body is `Encodable?`. **Never pass `[String: Any]`** — use `postRaw()` or an Encodable struct

### Model Properties
- Character has `.avatar`, NOT `.skinKey`
- `PvPRank` has NO `.displayName` — use `.rawValue`
- `LeaderboardEntry`: `characterClass` is String, convert with `CharacterClass(rawValue:) ?? .warrior`

### Property Access
Before accessing a model property — **verify it exists** in the struct/class definition. Do NOT assume computed properties like `resolvedImageKey` exist. Different models (`Item`, `ShopItem`, `LootPreview`, `EquippedItem`) have **different property sets**. Always check the specific type definition.

### Manually Constructed Items
When creating `Item(...)` manually (not from JSON), **pass ALL display-relevant fields** — especially `imageKey`, `catalogId`, `consumableType`. The `ConsumableInventory` table does NOT store `imageKey` — must be mapped client-side via `InventoryService.consumableImageKeys`. If you add a new consumable type, add mapping to both `consumableDisplayNames` AND `consumableImageKeys` in `InventoryService.swift`.

### Force Unwrap Policy
Zero force unwraps. Use `if let`/`guard let`/`?? default`. Only exception: hardcoded URL literals with `swiftlint:disable`.

### Optimistic UI Updates
All mutating actions MUST update UI immediately. Pattern: update local → toast + haptic → API in background → on error, revert.

## Navigation Rules (CRITICAL)

### dismiss() vs mainPath
**Never use `@Environment(\.dismiss)`** for screens in the programmatic `NavigationStack(path: $appState.mainPath)`. It can desync the path binding and cause navigation loops.
- Use `appState.mainPath.removeLast()` instead.
- `HubLogoButton` already implements this pattern — always use it for back navigation (28×28 `ui-arrow-left`).
- `dismiss()` is only safe for sheets (`.sheet`, `.fullScreenCover`) and non-path-based navigation.
- **Do NOT use the hexbound-logo for back navigation.**

### dismiss() in Multi-Context Views
Views appearing in **multiple NavigationStack contexts** (e.g. `DungeonRoomDetailView` in both `mainPath` and `dungeonPath`) **must use `@Environment(\.dismiss)`** — NOT `appState.mainPath.removeLast()`. `dismiss()` works regardless of which NavigationStack the view is inside.
- **Exception**: `HubLogoButton` is only used in `mainPath` context, so it can keep using `appState.mainPath.removeLast()`

## Code Safety Rules (CRITICAL)

### Enum Switch Exhaustiveness
When adding a new case to ANY Swift enum with computed properties using `switch self`:
1. **Search all `switch` statements** on that enum — every one must handle the new case.
2. `BurstStyle` has **5 computed properties** with switches: `colors`, `defaultCount`, `duration`, `radiusRange`, `sizeRange`. Adding a case requires updating ALL 5.
3. Same for `VFXEffectType`, `ItemRarity`, `ModalType`, etc.
4. Don't just add `default:` to silence the compiler — give correct values.

### ViewModifier Parameter Changes
When adding a new parameter to a `ViewModifier` struct:
1. **Search ALL callers** — not just the `View` extension, but direct struct initializers too.
2. Direct initializers do NOT get default values from the extension function.
3. **Prefer using the extension** (`.shimmer(...)`) everywhere.
4. Always add default values to struct properties OR ensure the extension is the only entry point.

### Color Shorthand Extensions
When using DarkFantasyTheme colors as `.bgAbyss`, `.textPrimary` (shorthand without prefix), these must be registered as static properties on both `Color` and `ShapeStyle` in `DarkFantasyTheme.swift`.
- **Currently registered**: `bgAbyss`, `bgPrimary`, `bgBackdropLight`, `textPrimary`
- **Preferred**: Always use full `DarkFantasyTheme.xxx` prefix. Only use shorthand when already registered.

### Progress Bar Frame Guards
All GeometryReader-based progress bars MUST clamp width fraction to `[0, 1]`:
```swift
.frame(width: geo.size.width * max(0, min(1, fraction)))
```
Pattern: see `UnifiedHeroWidget` and `HPBarView` for correct `max(0.02, min(1, ...))`.

### Async Closures in Sync Parameters
`ErrorStateView` and similar components expect `() -> Void` closures. When calling async functions inside, ALWAYS wrap in `Task {}`:
```swift
// ✅ CORRECT
ErrorStateView.loadFailed { Task { await vm.loadData() } }
```

### pbxproj: Scan ALL .swift Files
After any build failure with "Cannot find X in scope", check if file exists on disk but is missing from `project.pbxproj`:
```bash
find Hexbound/Hexbound -name "*.swift" | while read f; do
  base=$(basename "$f")
  count=$(grep -c "$base" Hexbound/Hexbound.xcodeproj/project.pbxproj)
  [ "$count" -lt 3 ] && echo "MISSING: $f ($count refs)"
done
```

## File Hygiene

Never leave `.bak`/`.backup`/`.tmp` files in `.xcodeproj` bundle. Verify after pbxproj edits:
```bash
ls Hexbound/Hexbound.xcodeproj/ | grep -E '\.(bak|backup|tmp)$'
```

## Replacing / Refactoring Code

1. Delete old code first — no duplicate symbols
2. Search file for old name before finishing
3. Search all callers and update signatures

## Animated Overlays — Extract to Separate Files

When an overlay/modal needs local `@State` for animation (scale bounce, count-up, multi-phase choreography, skip logic):
- **Extract to a standalone View file** — `@ViewBuilder` methods cannot own `@State`
- Pass data + `onDismiss` closure, keep animation state internal
- Before writing custom animation — check existing toolkit: `RewardBurstView`, `NumberTickUpView`, `HapticManager.coinCascade`, `MotionConstants.springBouncy`

## Root-Level Overlays — Survive `currentScreen` Transitions

If an overlay must stay visible while `appState.currentScreen` changes (loading while destination view mounts, cross-fade between onboarding steps, daily login over any screen), it **must live at app root** in `HexboundApp.swift` and be driven by an `AppState` flag.

**Do NOT** mount a `.loading`/`.forging`/`.celebration` overlay inside a screen that is the *source* of a `currentScreen` transition. When `currentScreen` changes, `HexboundApp` cross-fades the old view out (with `.animation(.easeInOut(0.3), value: currentScreen)`) and the overlay goes with it — the destination view then synchronously decodes its backdrop assets on the main thread, leaving the user staring at near-black `bgAbyss` for 1–3 seconds with no loading UI.

**Pattern (BUG-53 Daily Login, BUG-08 Hero Forge):**
1. Add a `Bool` flag on `AppState` — e.g. `var isForgingHero = false`
2. Create a reusable `XxxOverlayView` under `Views/Auth/` or `Views/Components/` (never inline in `HexboundApp`)
3. Mount at root: `.overlay { if appState.isXxx { XxxOverlayView().transition(.opacity).zIndex(N) } }`
4. Add `.animation(.easeInOut(duration: 0.3), value: appState.isXxx)` next to the existing `currentScreen` animation
5. ViewModel raises the flag **before** the API call, lowers it **after** `Task.sleep(for: .milliseconds(~350))` so the destination screen gets time to paint its first frame under the overlay
6. Wrap the VM state with `defer { isCreating = false }` — never rely on view unmount to clean up `isLoading`/`isCreating`/`isSubmitting` flags, SwiftUI View structs have no deinit guarantee and the success path typically routes away from the View

zIndex layers currently in use (keep ordered): Loading 100, LevelUp 120, DailyLogin 150, HeroForge 200, SessionExpired 250.

**Reference root overlays** (`HexboundApp.swift`): `OfflineBanner`, `CelebrationBannerOverlay`, `ToastOverlayView`, `LoadingOverlay`, `LevelUpModalView`, Daily Login popup, `SessionExpiredModalView`, `HeroForgeOverlayView`. All follow this pattern.

## UI/UX Design Rules

- **3-second rule** — player understands screen instantly
- **One goal per screen** — one primary CTA
- **No dead ends** — every state has a next action
- Min touch: 48pt, primary buttons 56pt+. Thumb zone bottom 60%. Max 4-6 visible actions.
- Loading: skeletons > spinners > blank
- Read design system files before any design work. Check existing components in `Views/Components/`.
