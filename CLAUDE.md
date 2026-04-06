# Hexbound — Project Rules

> **Full documentation**: See `docs/01_source_of_truth/DOCUMENTATION_INDEX.md` for the complete docs structure.
> **Canonical rules**: See `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md` for the extended version.
> **iOS/SwiftUI rules**: See `Hexbound/CLAUDE.md`
> **Backend/TypeScript rules**: See `backend/CLAUDE.md`
> **Figma Design System**: [Hexbound-DS](https://www.figma.com/design/uDjXIz7CdJxcEOI5jCBcjY/Hexbound-DS) — 359 tokens, 47 component sets, 235 variants, 164 instances, 22 pages
> **DS Audit**: See `docs/07_ui_ux/DESIGN_SYSTEM_AUDIT.md` for compliance status

## Architecture

- State management: `@MainActor @Observable` classes
- Navigation: `NavigationStack` with `AppRouter`
- Cache: `GameDataCache` environment object, cache-first pattern
- Views pass `@Bindable var vm` to child components (not `@State`)
- Server-authoritative: client must NOT calculate combat results, rewards, ratings, economy values, or balance formulas

## Xcode Project File (CRITICAL)

When creating ANY new `.swift` file in `Hexbound/`, you MUST add it to `Hexbound/Hexbound.xcodeproj/project.pbxproj`.

Each new file requires entries in **4 sections**:
1. **PBXBuildFile** — `{ID1} /* FileName.swift in Sources */ = {isa = PBXBuildFile; fileRef = {ID2}; };`
2. **PBXFileReference** — `{ID2} /* FileName.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileName.swift; sourceTree = "<group>"; };`
3. **PBXGroup** — Add `{ID2}` to the correct group's `children` array
4. **Sources build phase** — Add `{ID1}` to `PBXSourcesBuildPhase` `files` array

Generate unique 24-character hex IDs. Keep entries alphabetically sorted. **If you skip this, the file will NOT compile.**

## Design System (Summary)

> Full design system details (ornamental patterns, radius scale, stat colors, GPU rules): see `Hexbound/CLAUDE.md`

- Always use `DarkFantasyTheme` tokens — never `Color(hex:)` or raw values
- Always use `ButtonStyles.swift` styles — never inline button styling
- Always use `LayoutConstants` for spacing/sizing — minimum font 11px
- **Gold CTA styles** (`.primary`, `.fight`, `.premium`, `.danger`) MUST have: `SurfaceLightingOverlay` + `cornerBrackets` + `cornerDiamonds` + `innerBorder`
- Theme: `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
- Buttons: `Hexbound/Hexbound/Theme/ButtonStyles.swift`
- Layout: `Hexbound/Hexbound/Theme/LayoutConstants.swift`
- Ornamental: `Hexbound/Hexbound/Theme/OrnamentalStyles.swift`
- Cards: `Hexbound/Hexbound/Theme/CardStyles.swift`

### Token Verification (CRITICAL)

- **NEVER guess token names.** Open the source file and confirm before using.
- No `.accent` — primary accent is `.gold`. No `.primary`/`.background`/`.text` color tokens.
- Always use full prefix: `DarkFantasyTheme.textPrimary`, NOT bare `.textPrimary`

### Font Tokens — Exhaustive List

| Token | Font | Size | Use for |
|---|---|---|---|
| `.cinematicTitle` | Oswald | 40 | Full-screen ceremonies |
| `.title` | Oswald | 28 | Screen titles |
| `.section` | Oswald | 22 | Sub-section headers |
| `.cardTitle` | Oswald | 18 | Card headers |
| `.buttonLabel` | Oswald | 18 | Button text |
| `.buttonLabelCompact` | Oswald | 16 | Compact/small button text |
| `.body` | Inter | 16 | Body text |
| `.uiLabel` | Inter | 14 | Labels |
| `.caption` | Inter | 12 | Captions |
| `.badge` | Inter | 11 bold | Badges |

**DO NOT exist:** `.largeTitleFont`, `.titleFont`, `.bodyFont`, `.headlineFont`, `.subtitleFont`, `.captionFont`. Bold: `.body.bold()`, `.uiLabel.bold()`.

**NEVER use `font(size:)` functions** (e.g. `.title(size: 20)`, `.section(size: 14)`, `.body(size: 13)`). These bypass the design system and cause Swift compilation errors (static let/func name collision → "Cannot call value of non-function type 'Font'"). Always use the static token properties above. If no token fits — adapt the design, don't invent custom sizes.

### Spacing Tokens — Exhaustive List

| Token | Value | Use for |
|---|---|---|
| `.space2XS` | 2 | Micro gaps |
| `.spaceXS` | 4 | Badge padding |
| `.spaceSM` | 8 | Card internal |
| `.spaceMS` | 12 | Compact padding |
| `.spaceMD` | 16 | Standard padding |
| `.spaceLG` | 24 | Section separation |
| `.spaceXL` | 32 | Section breaks |
| `.space2XL` | 48 | Hero areas |

**DO NOT exist:** `.spacingXL`, `.paddingLG`, `.marginLG`. Prefix is `space`, NOT `spacing`/`padding`/`margin`.

## Figma Design System (CRITICAL)

**Two-file system:**
- **DS:** [Hexbound-DS](https://www.figma.com/design/uDjXIz7CdJxcEOI5jCBcjY/Hexbound-DS) — fileKey: `uDjXIz7CdJxcEOI5jCBcjY` — tokens, components, assets ONLY
- **Screens:** [Hexbound-Design](https://www.figma.com/design/PalemJ36B97ZdC0cd8jzv4/Hexbound-Design) — fileKey: `PalemJ36B97ZdC0cd8jzv4` — ALL app screens
- **DS library key:** `lk-1e3d5b13e106c557d2ec56c3ac95231374bc21a6136997e732d7a804ec4d86c11297eee6bd376c1bc936574dd6ba4ddea2380be439e8701a5408d7daaff18fb4`

**NEVER put screens in DS file. NEVER put components in Screens file.**

Figma DS is the **visual single source of truth** for all Hexbound UI. It mirrors Swift code tokens 1:1.

> **Screen creation rules**: See `docs/07_ui_ux/FIGMA_SCREEN_RULES.md` — MANDATORY for every `use_figma` call that creates/modifies screens.
> **Zero tolerance**: 0 hardcoded colors, 0 unstyled text, 0 fake-component frames, 0 default placeholder text.
> **Post-creation audit REQUIRED**: Run the audit script from FIGMA_SCREEN_RULES.md Rule 7 after EVERY screen. Must pass before proceeding.

### Token Collections (359 total)

| Collection | Variables | Modes | Scopes |
|---|---|---|---|
| **Primitives** | 187 raw hex colors | Value | Hidden (`[]`) — never use directly in components |
| **Color** (semantic) | 158 aliased to Primitives | Dark | FILL / TEXT / STROKE per role |
| **Spacing** | 14 (8 spacing + 6 radius) | Value | GAP / CORNER_RADIUS |

All 377 variables have **iOS code syntax** set (`DarkFantasyTheme.*`, `LayoutConstants.*`).

### Styles

- **9 Text Styles:** Heading/ (Cinematic Title 40, Title 28, Section 22, Card Title 18, Button Label 18) + Body/ (Body 16, UI Label 14, Caption 12, Badge 11)
- **4 Effect Styles:** Shadow/Card, Shadow/Modal, Shadow/Gold Glow, Shadow/Danger Glow

### Component Pages (22 pages, 47 sets, 235 variants, 164 instances)

**Foundational (standalone pages):**

| Page | Components | Swift Source |
|---|---|---|
| **Buttons** | Button (18v), Compact Button (15v), Combat Button (12v), Special Button (15v), Navigation Button (6v), Wager Button (3v) — 69 total variants | ButtonStyles.swift |
| **Cards** | Card — 9 variants (Panel/Highlight/Info/Modal + 5 Rarities) | CardStyles.swift |
| **Ornamental** | Ornamental system showcase | OrnamentalStyles.swift |
| **Dividers** | Divider — 3 (Gold/Ornamental/EtchedGroove) | OrnamentalStyles.swift |
| **Tab Switcher** | Tab Switcher — 2 (2-tab/3-tab) | TabSwitcher.swift |
| **Progress Bars** | Progress Bar — 15 (HP/XP/Stamina × compact/widget/large) | HPBarView, XPBarView, StaminaBarView |
| **Badges & Pills** | Widget Pill (10), Card Level Badge (2), Payout Pill (4), Stat Points Badge (3), Class Tag (4), Difficulty Tag (3), Stat Box (2), Icon Box (3), Comparison Indicator (2), Reward Box (4), Level Circle (1), Equipped Badge (1), Glass Stat Pill (3) | WidgetPill.swift, CardLevelBadge.swift, StatPointsBadge.swift, GlassStatPill.swift, ClassTagView.swift |
| **Currency Display** | Currency Display — 4 (Standard/Compact/Mini/Animated) | CurrencyDisplay.swift |
| **Empty & Error States** | State View — 4 (EmptyInventory/NoQuests/NetworkError/ServerError), Asset Placeholder (1) | EmptyStateView, ErrorStateView, AssetPlaceholderView.swift |
| **Loading** | Loading Overlay — 1 | LoadingOverlay.swift |
| **Navigation** | Navigation — 3 (NavGrid/BackButton/ScreenHeader) | ScreenLayout.swift |
| **Ornamental Title** | Ornamental Title — 2 (ScreenTitle/SectionHeader) | OrnamentalTitle.swift |
| **Item Card** | Item Card — 9 (Common→Legendary × contexts) | ItemCardView.swift |
| **Skeleton** | Skeleton — 3 (Rectangle/Card/ItemCell) | SkeletonViews.swift |
| **Input** | Input Field — 3 (Default/Focused/Error) | Auth screens |

**Domain-grouped pages:**

| Page | Components | Swift Source |
|---|---|---|
| **Hero & Character** | Unified Hero Widget (2), Avatar (3) | UnifiedHeroWidget, AvatarImageView |
| **Arena & PvP** | Arena Card (3), Battle Result Card (2), Leaderboard Row (2), PvP Stats Widget (2) | ArenaOpponentCard, BattleResultCardView, LeaderboardRowView, PvPStatsWidget |
| **Dungeon & Progression** | Dungeon Boss Card (3), Achievement Card (4), Active Quest Banner (2), BP Reward Node (4) | DungeonBossCard, AchievementCardView, ActiveQuestBanner, BPRewardNodeView |
| **Social & Messaging** | Inbox Row (2), NPC Guide Widget (2) | InboxRowView, NPCGuideWidget |
| **Toast & Banners** | Toast (7), Event Banner (2), Celebration Banner (5), Low HP Potion Banner (2) | ToastOverlayView, EventBannerView, CelebrationBannerView, LowHPPotionBanner |
| **Modals & Sheets** | Guest Gate (1), Session Expired Modal (1), Item Detail Sheet (3: Inventory/Shop/Loot), Level Up Modal (1) | GuestGateView, SessionExpiredModalView, ItemDetailSheet, LevelUpModalView |
| **Minigames** | Mine Slot Card (3: Idle/Mining/Ready), Locked Mine Card (1), Mining Output Card (1) | GoldMineDetailView.swift (MineSlotCard, LockedMineCard, miningOutputCard) |

### Figma DS Component Quality Rules (CRITICAL)

**Every component in Figma DS MUST be built from tokens, molecules, and existing components — NEVER raw values.**

| Layer | Rule | Example |
|---|---|---|
| **Colors** | ALL fills/strokes bound to Color collection variables | `color/text/secondary`, NOT hardcoded `#9B95A0` |
| **Typography** | ALL text nodes linked to Text Styles | `Heading/Section`, NOT manual Oswald 22 |
| **Spacing** | ALL gap/padding bound to Spacing collection variables | `spacing/md`, NOT raw `16` |
| **Radius** | ALL cornerRadius bound to Spacing collection radius variables | `radius/xl`, NOT raw `16` |
| **Effects** | ALL shadows linked to Effect Styles | `Shadow/Modal`, NOT manual drop shadow |
| **Buttons** | Use Button component instances | Import from Buttons page, NOT custom frames |
| **Dividers** | Use Divider component instances | Import from Dividers page, NOT rectangles |
| **Cards/Badges** | Use existing component instances where available | Import from respective foundational pages |

**Audit checklist after creating/editing ANY Figma component:**
1. `textStyleId !== ''` on every TEXT node (0 unlinked allowed)
2. `boundVariables.fills` on every colored node (except internal component sub-layers)
3. `boundVariables.itemSpacing/padding*` on every auto-layout frame
4. `boundVariables.topLeftRadius` on every rounded frame
5. Zero FRAME nodes pretending to be buttons — use Button instances
6. Zero RECTANGLE nodes pretending to be dividers — use Divider instances
7. Effect style applied to root component (Shadow/Card or Shadow/Modal)

**Violation = rebuild.** No exceptions.

### Figma ↔ Code Sync Rules

- When adding a new **color token** to `DarkFantasyTheme.swift` → add to Primitives + Color collections in Figma
- When adding a new **component** to `Views/Components/` → create Figma component on the matching domain page (Hero & Character, Arena & PvP, Dungeon & Progression, Social & Messaging, Toast & Banners, Modals & Sheets) or a foundational page
- When changing a **token value** → update Figma variable (semantic alias stays, only primitive changes)
- Use `figma-use` skill with fileKey `uDjXIz7CdJxcEOI5jCBcjY` for all Figma operations

### Figma ↔ Swift 1:1 Parity Protocol (CRITICAL — ALL COMPONENTS)

**Every Figma component MUST be a pixel-perfect mirror of its Swift implementation.** This applies to buttons, cards, badges, progress bars, modals, toasts — everything.

#### Step 0: Before creating/editing ANY Figma component

1. **Open the Swift source file.** Find the exact View/Style struct. Read every modifier.
2. **Extract the truth table:** fill, foregroundStyle, font, padding, cornerRadius, stroke, opacity, shadow, overlay — per state (Default, Pressed, Disabled, Active, Inactive, etc.)
3. **Only then build in Figma.** Never eyeball or guess values.

#### Step 1: Fills (backgrounds)

| Swift pattern | Figma fill |
|---|---|
| `.fill(LinearGradient(colors: [A, B], startPoint, endPoint))` | Gradient fill matching exact colors + direction |
| `.fill(SomeColor)` | Solid fill with exact hex from `DarkFantasyTheme` |
| `.fill(color.opacity(X))` | Solid fill with opacity X |
| No `.background` / `.fill(.clear)` | NO fill — leave empty |
| `.fill(bgDisabled)` | Solid `#333340` |

**NEVER leave a fill as `visible: false`.** Either the fill is there (visible: true) or not there at all.

#### Step 2: Interactive states

| Swift pattern | Figma variant |
|---|---|
| `.brightness(pressed ? -0.06 : 0)` | Darkened fill (RGB × 0.94), `opacity = 1.0` |
| `.brightness(pressed ? -0.08 : 0)` | Darkened fill (RGB × 0.92), `opacity = 1.0` |
| `.opacity(pressed ? 0.85 : 1)` | Same fill as Default, root `opacity = 0.85` |
| `.opacity(pressed ? 0.6 : 1)` | Same fill as Default, root `opacity = 0.6` |
| `.opacity(isActive ? 1.0 : 0.6)` | Inactive variant root `opacity = 0.6` |
| Compound: `.opacity(0.6).opacity(pressed ? 0.85 : 1)` | Multiply: root `opacity = 0.51` |

**NEVER mix brightness and opacity.** Read the Swift code — use exactly what it says.

#### Step 3: Text and foreground

| Swift `foregroundStyle` | Figma text fill |
|---|---|
| `DarkFantasyTheme.textOnGold` | `#1A1A2E` — ONLY on gold/colored fills |
| `DarkFantasyTheme.textPrimary` | `#F5F5F5` — on dark fills |
| `DarkFantasyTheme.textSecondary` | `#A0A0B0` — secondary on dark |
| `DarkFantasyTheme.textDisabled` | `#555566` — all disabled states |
| `.white` | `#FFFFFF` — on danger/fight fills |
| `DarkFantasyTheme.gold` | `#D4A537` — on transparent (outline styles) |
| `DarkFantasyTheme.danger` | `#E63946` — on transparent (danger outline) |

**Contrast check:** dark text requires light fill, light text requires dark fill. If text is invisible → fill is wrong.

#### Step 4: Typography

| Swift modifier | Figma |
|---|---|
| `.font(DarkFantasyTheme.buttonLabel)` | Text Style `Heading/Button Label` |
| `.font(DarkFantasyTheme.buttonLabelCompact)` | Text Style `Heading/Button Label` (size 16) |
| `.font(DarkFantasyTheme.body)` | Text Style `Body/Body` |
| `.textCase(.uppercase)` | Text transform: UPPERCASE |
| `.tracking(2)` | Letter spacing: 2 |

#### Step 5: Spacing, radius, stroke

| Swift | Figma |
|---|---|
| `.padding(.horizontal, LayoutConstants.spaceMD)` | Auto-layout horizontal padding = 16 (bound to `spacing/md`) |
| `.cornerRadius(LayoutConstants.buttonRadius)` | Corner radius bound to `radius/button` variable |
| `.stroke(color, lineWidth: X)` | Stroke fill = color, weight = X |
| `.shadow(color:, radius:, y:)` | Effect style or manual shadow matching values |

#### Step 6: Ornamental layers (buttons with gold CTA)

For `.primary`, `.fight`, `.premium`, `.danger` button families:
- `SurfaceLightingOverlay` → gradient rectangle (white 8% top → black 12% bottom)
- `.innerBorder()` → inner stroke rectangle
- `.cornerBrackets()` → 8 bracket rectangles at corners
- `.cornerDiamonds()` → 4 diamond rectangles at corners
- `.sideDiamonds()` (if present) → 2 side diamond rectangles

#### Step 7: Mandatory audit after ANY component change

```
1. get_screenshot of the full component set
2. Verify: text readable in ALL state variants
3. Verify: each state visually distinct (Default ≠ Pressed ≠ Disabled)
4. Verify: no hidden fills (visible: false) — run audit script
5. Cross-check: open Swift source → compare every property
```

**Audit script (run via use_figma after changes):**
```js
// Find hidden fills in a component set
const cs = await figma.getNodeByIdAsync('COMPONENT_SET_ID');
for (const v of cs.children) {
  const hiddenFills = v.fills?.filter(f => f.visible === false) || [];
  if (hiddenFills.length > 0) return `FAIL: ${v.name} has hidden fills`;
}
return 'PASS';
```

**Violation = fix immediately. Never leave for later.**

### Asset Import (xcassets → Figma)

Script: `bash scripts/export-assets-for-figma.sh` — exports all PNG from `Assets.xcassets` into `figma-assets/` by category:

| Folder | Content | Count |
|---|---|---|
| `02_Enemies` | Dungeon Rush mobs & bosses | 100 |
| `03_Items` | Equipment items | 68 |
| `04_Icons` | UI/race/HUD/reward/shop icons | 82 |
| `05_UI_Backgrounds` | Backgrounds, minigame, logo, NPCs | 27 |
| `06_FX` | Battle effects, buffs, events | 39 |
| `07_Buildings` | City hub buildings | 20 |

Figma DS has matching `Assets / *` pages with **350 named placeholder components** (matching code asset names). Design skills (`search_design_system`, `importComponentByKeyAsync`) can find and use them automatically.

**To fill placeholders with actual images:**
1. Open the `Assets / *` page in Figma
2. Select a placeholder component
3. Cmd+Shift+K → choose PNG from `figma-assets/<folder>/` → place as fill
4. Or: drag PNG from Finder onto the component

**When adding new art to `Assets.xcassets`:**
1. Re-run `bash scripts/export-assets-for-figma.sh`
2. Create new component on matching Figma page (via `use_figma` or manually)
3. Import PNG into the component

## Asset Pipeline Rules (CRITICAL)

> Full audit: `docs/07_ui_ux/ASSET_CONSISTENCY_AUDIT.md`

- **Scale-aware loading**: `AssetManager` loads images with `UIImage(data: data, scale: UIScreen.main.scale)` — never bare `UIImage(data:)`
- **Interpolation hints**: All shared image components (`CachedAssetImage`, `ItemImageView`, `AvatarImageView`, `CityBuildingView`) use `.interpolation(.high)`; backgrounds use `.interpolation(.medium)`
- **sync-assets.sh max dimension**: 1024px (not 512). Never resize below display size × 3
- **No orphaned sidebar icons**: Only 32 active icons remain; verify before adding new ones
- **New assets require**: Figma DS component → export → xcassets → code reference. No direct xcassets addition
- **Naming**: kebab-case for UI assets (`building-arena`), snake_case exception for Supabase items (`wpn_excalibur`)
- **Oversized check**: Icons displayed at ≤36pt must not exceed 256×256 source PNG

## Game Enums (VERIFY BEFORE USE)

- **CharacterClass**: `warrior`, `rogue`, `mage`, `tank`
- **CharacterOrigin**: `human`, `orc`, `skeleton`, `demon`, `dogfolk` (NOT elf, NOT dwarf)
- **CharacterGender**: `male`, `female`
- **ItemType**: `weapon`, `helmet`, `chest`, `gloves`, `legs`, `boots`, `accessory`, `amulet`, `belt`, `relic`, `necklace`, `ring`, `consumable`
- **ItemRarity**: `common`, `uncommon`, `rare`, `epic`, `legendary`
- **DamageType**: `physical`, `magical`, `true_damage`, `poison`
- **QuestType**: `pvp_wins`, `dungeons_complete`, `gold_spent`, `item_upgrade`, `consumable_use`, `shell_game_play`, `gold_mine_collect` (NOT `pvp_win`, NOT `pvp_fight`)

## Achievement System (CRITICAL)

**3 categories, 21 achievements.** Do NOT add achievements without wiring tracking.

- **Catalog**: `backend/src/lib/game/achievement-catalog.ts`
- **Tracking**: `backend/src/lib/game/achievements.ts` — `updateMultipleAchievements()` with `absolute: true`
- **iOS**: `AchievementsViewModel.swift` → 3 tabs: `["PvP", "Progress", "Ranking"]` → `["pvp", "progression", "ranking"]`
- Categories tracked in: `pvp` → pvp/fight, pvp/resolve, pvp/revenge; `progression` → applyLevelUp, prestige; `ranking` → pvp/fight, pvp/resolve
- `absolute: true` for streaks/ratings/levels (values that can decrease)
- Adding new: catalog → tracking call → display metadata → verify iOS tab. **No tracking = stuck at 0/N forever**

## Prisma Schema Sync (CRITICAL)

`backend/prisma/schema.prisma` is the single source of truth. After ANY change:
1. Run migration: `cd backend && npm run db:migrate:dev -- --name your_change`
2. Copy: `cp backend/prisma/schema.prisma admin/prisma/schema.prisma`
3. Commit both together. **Skip step 2 = CI fail + admin crash.**

## Git & Deploy (CRITICAL)

Two remotes: `origin` (monorepo, backend auto-deploys) + `admin-deploy` (admin subtree, admin auto-deploys).

After `git push origin main`, if `admin/` changed:
```bash
git subtree push --prefix=admin admin-deploy main
```

### Git Watcher (VM Auto-Commit)

Script at `scripts/git-watcher.sh` — user runs it on Mac terminal. To trigger: `echo "commit message" > .git-trigger`. Watcher does `git add -A && git commit && git push`. Use this when direct `git commit` fails due to `index.lock`.

### Merge Conflict Resolution

After `git merge`/`git pull --no-rebase`, **NEVER** blindly `git add -A && git commit`. Always grep first:
```bash
grep -rn "^<<<<<<<\|^=======\$\|^>>>>>>>" . --include="*.swift" --include="*.ts" --include="*.prisma" | grep -v node_modules | grep -v ".git/"
```

## Documentation Quick Lookup

| Need to know | Read this file |
|---|---|
| DB models, fields, enums | `docs/04_database/SCHEMA_REFERENCE.md` |
| API endpoints | `docs/03_backend_and_api/API_REFERENCE.md` |
| Game balance, formulas | `docs/06_game_systems/BALANCE_CONSTANTS.md` |
| Combat, damage, ELO | `docs/06_game_systems/COMBAT.md` |
| Economy, currencies, IAP | `docs/02_product_and_features/ECONOMY.md` |
| Game systems overview | `docs/02_product_and_features/GAME_SYSTEMS.md` |
| Admin panel capabilities | `docs/05_admin_panel/ADMIN_CAPABILITIES.md` |
| iOS screens, components | `docs/07_ui_ux/SCREEN_INVENTORY.md` |
| Design tokens, colors | `docs/07_ui_ux/DESIGN_SYSTEM.md` |
| Figma DS (visual) | [Hexbound-DS](https://www.figma.com/design/uDjXIz7CdJxcEOI5jCBcjY/Hexbound-DS) |
| Art prompts | `docs/08_prompts/ASSET_PROMPTS_INDEX.md` |
| Deploy flow, Vercel | `docs/10_operations/DEPLOY.md` |
| Git workflow, subtree | `docs/10_operations/GIT_WORKFLOW.md` |
| DB migrations, Prisma | `docs/10_operations/DATABASE_MIGRATIONS.md` |
| iOS release, TestFlight | `docs/10_operations/RELEASE_IOS.md` |
| Error patterns catalog | `docs/09_rules_and_guidelines/ERROR_CATALOG.md` |
| Full doc index | `docs/01_source_of_truth/DOCUMENTATION_INDEX.md` |

## Landing Site (hexbound-landing)

The marketing landing page is a **separate repository and Vercel project** — NOT part of the main monorepo.

- **Repo**: `artosetrov/hexbound-landing` (GitHub, public)
- **Vercel project**: `hexbound-landing` (Art's projects)
- **Stack**: Single `index.html` (~102KB) with inline CSS/JS, GSAP animations, canvas particles
- **Assets**: `assets/` folder (51 files — JPG backgrounds, PNG bosses/buildings/classes/races, logo, appicon)
- **Domain**: `hexboundapp.com` (GoDaddy DNS → Vercel)
  - `A @ → 76.76.21.21` (Vercel)
  - `CNAME www → cname.vercel-dns.com`
- **Other subdomains**: `admin.hexboundapp.com` → Vercel (admin panel), `api.hexboundapp.com` → Vercel (backend)
- **Deploy**: Push to `main` branch of `artosetrov/hexbound-landing` → auto-deploys on Vercel
- **Local dev**: Open `index.html` in browser — no build step

**Do NOT confuse with the main game monorepo.**

## Deleted / Renamed Files (DO NOT REFERENCE)

| Old name (DELETED) | Replacement |
|---|---|
| `PROJECT_KNOWLEDGE_v2.md` | `docs/04_database/SCHEMA_REFERENCE.md` + `docs/03_backend_and_api/API_REFERENCE.md` |
| `UI_DESIGN_DOCUMENT.md` | `docs/07_ui_ux/SCREEN_INVENTORY.md` + `docs/07_ui_ux/DESIGN_SYSTEM.md` |
| `CLAUDE 2.md` | This file (`CLAUDE.md`) |
| `HEXBOUND_UI_UX_AUDIT_GUIDE.md` | `docs/07_ui_ux/UX_AUDIT.md` |
| `HEXBOUND_UX_AUDIT_V2.md` | `docs/07_ui_ux/UX_AUDIT.md` |
| `BALANCE_AUDIT_REPORT.md` | `docs/06_game_systems/BALANCE_CONSTANTS.md` |
| Prompt files in root | Moved to `docs/08_prompts/` |
| `ShopItemCardView.swift` | Use `ItemCardView` with `.shop` context |

## Error Prevention — Проверяла (Error Scanner)

Scanner at `.claude/skills/error-scanner/SKILL.md`, catalog at `docs/09_rules_and_guidelines/ERROR_CATALOG.md`.

Invoke: "проверяла", "error scan". Checks: Swift grep (SFX, tokens, force unwraps), pbxproj structure, TypeScript (PII, try/catch, await), Prisma sync, conflict markers.

## CDO Verification (MANDATORY — EVERY TASK)

After completing ANY task, scan:

```bash
# Invented font tokens
grep -rn 'DarkFantasyTheme\.\(largeTitleFont\|titleFont\|bodyFont\|bodyBoldFont\|headlineFont\|subtitleFont\|captionFont\)' Hexbound/ --include="*.swift"
# Invented spacing tokens
grep -rn 'LayoutConstants\.\(spacing\|padding\|margin\)[A-Z]' Hexbound/ --include="*.swift"
# Hardcoded colors in Views
grep -rn 'Color(hex:' Hexbound/Hexbound/Views/ --include="*.swift"
# Hardcoded system fonts in Views (must use DarkFantasyTheme tokens)
grep -rn '\.font(\.system(size:' Hexbound/Hexbound/Views/ --include="*.swift" | grep -v 'design: .monospaced\|design: .rounded\|// emoji\|// keep\|pillIconSize\|textCard\|iconSize'
# Raw Color usage in Views (must use DarkFantasyTheme)
grep -rn 'Color\.red\|Color\.orange\|Color\.green\|Color\.blue' Hexbound/Hexbound/Views/ --include="*.swift" | grep -v 'DarkFantasyTheme'
# SF Symbol currency icons
grep -rn 'dollarsign\.circle\|diamond\.fill.*currency' Hexbound/Hexbound/Views/ --include="*.swift"
# Hardcoded cornerRadius literals (must use LayoutConstants.radius*)
grep -rn 'RoundedRectangle(cornerRadius: [0-9]' Hexbound/Hexbound/Views/ --include="*.swift" | grep -v 'cornerRadius: 0'
# Junk files in xcodeproj
ls Hexbound/Hexbound.xcodeproj/ | grep -E '\.(bak|backup|tmp)$'
# Merge conflict markers
grep -rn '^<<<<<<<\|^=======\$\|^>>>>>>>' . --include="*.swift" --include="*.ts" --include="*.prisma" | grep -v node_modules
```

ALL pass → "CDO: CLEAN". Any fail → fix + re-scan. **Never skip.**

## Agent Orchestrator (META-AGENT PROTOCOL)

Claude operates as an **orchestrator-agent** for Hexbound — proactively deciding which agents to run, in what order.

### Auto-Dispatch (after every completed task)

| What happened | Agent(s) to spawn | Priority |
|---|---|---|
| Wrote/modified `.swift` files | `hexbound-swift-review` | Auto |
| Wrote/modified `.ts`/`.tsx` files or Prisma schema | `hexbound-backend-review` | Auto |
| Created new screen / major UI change | `hexbound-ux-audit` | Auto |
| Task is done, about to commit | `hexbound-preflight` | Auto |
| Changed 5+ files or refactored | `hexbound-build-verify` | Auto |
| End of session or after large audit | `hexbound-retro` | Suggest |

**Parallel dispatch:** `swift-review` + `backend-review` can run in parallel. `ux-audit` after code review. `preflight` last before commit.

**When NOT to auto-dispatch:** Trivial changes (typo fix, 1 line), user says "без проверки" / "skip review", only docs/markdown edited.

### Pattern Detection (after 3+ interactions)

1. **Repeated manual steps** (3+ times) → suggest new agent
2. **Recurring mistakes** → suggest check in existing agent
3. **Missing coverage** → suggest new agent
4. **Agent overlap** → suggest merge

### Agent Evolution

When a rule violation is found that **no agent caught**: identify which agent should have caught it → update that agent's SKILL.md → add pattern to scanner script.

### All Hexbound Agents

| Agent | Scope | Script |
|---|---|---|
| `hexbound-swift-review` | SwiftUI design system, architecture, tokens | `scripts/check_design_system.sh` |
| `hexbound-backend-review` | TypeScript/Prisma strict, async, schema sync | `scripts/check_async_await.sh` |
| `hexbound-ux-audit` | UX quality, states, touch targets, retention | — |
| `hexbound-preflight` | Pre-commit: pbxproj, Prisma, subtree, junk | `scripts/preflight_check.sh` |
| `hexbound-build-verify` | Full build + static analysis | `scripts/verify_build.sh` |
| `hexbound-retro` | Meta: lessons → rule/agent updates | `scripts/gather_metrics.sh` |
| `ds-code-audit` | DS compliance: tokens, duplicates, inline patterns, orphans | `.claude/skills/ds-code-audit/` |
| `ds-figma-sync` | Code↔Figma parity: tokens, components, text/effect styles | `.claude/skills/ds-figma-sync/` |
| `ds-extract-component` | Extract inline pattern → reusable Swift + Figma component | `.claude/skills/ds-extract-component/` |
| `ds-ecosystem` | Master plan: 10-phase Figma ecosystem build orchestrator | `.claude/skills/ds-ecosystem/` |
| `ds-screen-builder` | Build app screens in Figma from DS components | `.claude/skills/ds-screen-builder/` |
| `ds-prototype` | Create clickable prototype flows between screens | `.claude/skills/ds-prototype/` |
| `ds-qa-coverage` | Final QA: coverage, bindings, naming, connections | `.claude/skills/ds-qa-coverage/` |

## CLAUDE.md Hygiene (META)

- **Root CLAUDE.md** — only cross-domain rules (git, deploy, schema sync, Figma, enums, agents, CDO)
- **`Hexbound/CLAUDE.md`** — iOS/SwiftUI only (tokens, components, patterns, animations, SFX)
- **`backend/CLAUDE.md`** — TypeScript/Prisma only (async, economy, rate limiting, N+1)
- If a section concerns only one domain → move it to that domain's CLAUDE.md
- Target: root < 350 lines, domain < 400 lines. If exceeded → refactor.

## Self-Documenting Rules (META — MANDATORY)

After ANY task:
1. Re-read relevant `CLAUDE.md` (root + domain). Did I follow all rules?
2. If discovered a repeating pattern/gotcha → add rule to the appropriate `CLAUDE.md`
3. If behavior/schema/API/screens changed → update relevant doc in `/docs/`
4. Commit rule/doc updates with the task or as `docs(claude):` commit
