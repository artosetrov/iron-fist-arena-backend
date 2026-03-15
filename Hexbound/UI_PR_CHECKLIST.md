# UI Pull Request Checklist — Hexbound

Use this checklist for every PR that touches Views, Theme, or any user-facing code.

---

## Colors & Theme Tokens

- [ ] No `Color(hex:)` or `Color(red:green:blue:)` outside `Theme/` directory
- [ ] No `#colorLiteral` anywhere in the project
- [ ] All new colors added to `DarkFantasyTheme.swift` with semantic names
- [ ] Background colors use `bgAbyss / bgPrimary / bgSecondary / bgTertiary / bgElevated / bgDarkPanel / bgModal / bgBackdrop / bgBackdropLight / bgScrim`
- [ ] Text colors use `textPrimary / textSecondary / textTertiary / textDisabled / textGold / textDanger / textSuccess`
- [ ] Accent colors use `gold / goldBright / goldDim / danger / success / info / cyan / purple / stamina`

## Typography

- [ ] Titles use `DarkFantasyTheme.title()` / `.section()` / `.cardTitle()` / `.cinematicTitle`
- [ ] Body text uses `DarkFantasyTheme.body(size:)` with `LayoutConstants.text*` sizes
- [ ] No hardcoded `.font(.system(size:))` in Views — use theme fonts
- [ ] Font sizes reference `LayoutConstants`: `textBody (16)`, `textCaption (12)`, `textLabel (14)`, `textButton (18)`, `textBadge (11)`, `textSection (22)`, `textCard (18)`

## Spacing & Layout

- [ ] Padding uses `LayoutConstants.space*` tokens: `space2XS (2)`, `spaceXS (4)`, `spaceSM (8)`, `spaceMS (12)`, `spaceMD (16)`, `spaceLG (24)`, `spaceXL (32)`, `space2XL (48)`
- [ ] Screen edge padding uses `LayoutConstants.screenPadding`
- [ ] Card padding uses `LayoutConstants.cardPadding`
- [ ] Card corner radius uses `LayoutConstants.cardRadius`
- [ ] Button height uses `LayoutConstants.buttonHeightMD` or `buttonHeightSM`

## Components

- [ ] Buttons use one of the standardized styles from `ButtonStyles.swift`:
  - `.primary` / `.primary(enabled:)` — gold CTA (full-width, 56px)
  - `.secondary` — outlined gold (full-width, 48px)
  - `.danger` — crimson destructive action (full-width, 48px)
  - `.ghost` — text-only tertiary
  - `.navGrid` — Hub navigation tiles
  - `.combatToggle(isActive:)` — combat speed toggles (1X/2X)
  - `.combatControl` — combat neutral actions (SKIP)
  - `.combatForfeit` — combat forfeit (danger icon)
  - `.closeButton` — xmark dismiss for modals/sheets
  - `.socialAuth` — OAuth sign-in (Apple/Google)
  - `.fight` / `.fight(accent:)` — combat CTA (FIGHT BOSS, arena FIGHT)
  - `.compactPrimary` — inline gold CTA (fixed-size, e.g. purchase buttons)
  - `.dangerCompact` — inline danger action (e.g. REVENGE)
  - `.colorToggle(isActive:color:height:)` — generic toggle (bets, zone selectors)
  - `.scalePress` / `.scalePress(_:)` — pure press feedback for cards/tappable elements
- [ ] No manual `.background` + `.overlay` + `.stroke` on Button labels — use a `ButtonStyle`
- [ ] Cards follow `bgSecondary` background + `cardRadius` corner radius pattern, or use `.panelCard()` / `.rarityCard()` modifiers
- [ ] Equipped items show gold "E" badge (top-right)
- [ ] Rarity borders use `DarkFantasyTheme.rarityColor(for:)` and `.rarityGlow(for:)`
- [ ] Durability uses `DarkFantasyTheme.durabilityColor(fraction:)` via `DurabilityRingOverlay`

## Error Handling & Toasts

- [ ] All error toasts include actionable `subtitle` (e.g., "Check connection and try again")
- [ ] Toast types use correct `ToastType` enum case (`.error`, `.achievement`, `.levelUp`, etc.)
- [ ] Toast colors come from `DarkFantasyTheme.toast*` tokens — not inline colors

## Combat & Status

- [ ] Damage type labels use full words (Physical, Magic, Poison, True, Damage) with SF Symbol icons
- [ ] Status effects show icon + full name (not 3-letter abbreviations)
- [ ] Stat names display `StatType.fullName` — never raw API keys
- [ ] Stat tooltips available via `StatType.description`

## Navigation

- [ ] New screens added to `AppRoute` enum
- [ ] Route registered in `AppRouter.routeView(for:)`
- [ ] Screen added to `ScreenCatalogView` (DEBUG) for dev testing
- [ ] `navigationBarBackButtonHidden(true)` + custom toolbar back button if needed

## Accessibility

- [ ] Text contrasts meet minimum ratio against background
- [ ] Interactive elements have adequate tap targets (44pt minimum)
- [ ] Decorative images don't interfere with VoiceOver

## Before Merge

- [ ] SwiftLint passes with zero warnings (run `swiftlint` from project root)
- [ ] Preview in `DesignSystemPreview` if adding new tokens/components
- [ ] Test on iPhone SE (small screen) and iPhone 15 Pro Max (large screen)
