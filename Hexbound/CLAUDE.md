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
- STATUS tab: stat points → grouped stats → respec → derived stats → equipment bonuses
- Sticky tabs above ScrollView, gold capsule badge on STATUS tab when stat points available
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

### Public Profile Sheet
`.sheet(item:)` with `.large` detent. Model: `OpponentProfile`. Equipment grid uses `ItemCardView(.equipment())`.
- Challenge/Message/AddFriend buttons all fully functional

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

### Force Unwrap Policy
Zero force unwraps. Use `if let`/`guard let`/`?? default`. Only exception: hardcoded URL literals with `swiftlint:disable`.

### Optimistic UI Updates
All mutating actions MUST update UI immediately. Pattern: update local → toast + haptic → API in background → on error, revert.

### Glow Effects
Tap-only, not idle. Default `opacity: 0`, `shadowRadius: 0`. Only glow on `.isPressed`.

### Assets vs Emojis
Replace emojis with game assets when available. Add `assetIcon` computed property to models.

## File Hygiene

Never leave `.bak`/`.backup`/`.tmp` files in `.xcodeproj` bundle. Verify after pbxproj edits:
```bash
ls Hexbound/Hexbound.xcodeproj/ | grep -E '\.(bak|backup|tmp)$'
```

## Replacing / Refactoring Code

1. Delete old code first — no duplicate symbols
2. Search file for old name before finishing
3. Search all callers and update signatures

## UI/UX Design Rules

- **3-second rule** — player understands screen instantly
- **One goal per screen** — one primary CTA
- **No dead ends** — every state has a next action
- Min touch: 48pt, primary buttons 56pt+. Thumb zone bottom 60%. Max 4-6 visible actions.
- Loading: skeletons > spinners > blank
- Read design system files before any design work. Check existing components in `Views/Components/`.
