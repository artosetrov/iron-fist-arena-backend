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

**Verify ID uniqueness:** Before adding new IDs, search `project.pbxproj` for collisions. Two files sharing the same PBXBuildFile ID causes one to silently not compile — no build error, just a missing-symbol crash at runtime.

**If you skip this step, the file will NOT compile in Xcode.**

## Design System

- Always use `DarkFantasyTheme` color/font tokens — never hardcode `Color(hex:)` or raw color values
- Always use `ButtonStyles.swift` styles (`.primary`, `.secondary`, `.neutral`, etc.) — never inline button styling
- **Close/dismiss buttons**: Always use `.buttonStyle(.closeButton)` (`CloseButtonStyle`) — never hand-roll close button styling. The label is just `Image(systemName: "xmark")`, the style handles everything (32×32 circle, `bgTertiary` fill, `textSecondary` 14pt bold icon, opacity press effect).
- Always use `LayoutConstants` for spacing/sizing — minimum font size is `LayoutConstants.textBadge` (11px)
- **NO SCALE ANIMATIONS** — never use `.scaleEffect()` for press feedback, pulsing, breathing, bounce, or appear/reveal. Use `.opacity(isPressed ? 0.85 : 1)` instead. Static `.scaleEffect(0.8)` for sizing and `.scaleEffect(x: -1)` for mirroring are OK. Particle effects (RewardBurst, CoinFly, VFX) are exempt.
- The theme file is at `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
- Button styles are at `Hexbound/Hexbound/Theme/ButtonStyles.swift`
- Layout constants are at `Hexbound/Hexbound/Theme/LayoutConstants.swift`

## Asset File Naming (CRITICAL)

**No spaces, colons, or special characters in asset filenames.** macOS silently allows them, but they cause issues with Xcode build systems, git, and CI.

- **Images**: lowercase with hyphens: `hub-bg-3.png`, `boss-arena-warden.png`
- **Audio**: lowercase with hyphens: `stray-city.mp3`, `arena-pvp.mp3`
- **Never**: `Hub bg 3.png`, `Arena : PvP.mp3`, `image 12.png`
- After renaming, update ALL references: `project.pbxproj`, Swift string literals (`AudioManager.shared.playBGM("...")`)
- Use `find Hexbound -name "* *"` to catch violations

## Art Style (for AI image generation prompts)

- Full art style guide: `Hexbound/ART_STYLE_GUIDE.md`
- Style: pen and ink illustration, bold black ink outlines, muted earth tones + 1-2 saturated accent colors, grimdark dark fantasy, isolated on white/transparent background
- Reference: D&D Monster Manual / Pathfinder rulebook illustrations (NOT digital painting, NOT concept art, NOT anime)
- Always start prompts with `Pen and ink illustration of...`
- Always end with `isolated on white background, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text`
- The icon `icon-gold-mine` is in a DIFFERENT casual/cartoon style — do NOT use as art style reference

## Section Spacing — `sectionGap` Token (CRITICAL)

**Use `LayoutConstants.sectionGap` (16pt)** for the main `ScrollView` → `VStack(spacing:)` on every content screen. This is the standard gap between major content blocks (widget → stance → tabs, header → grid → divider, etc.).

- **`sectionGap` (16pt)** — gap between major blocks on a screen. Use for `VStack(spacing:)` in the main `ScrollView` content.
- **`spaceLG` (24pt)** — reserved for dramatic separation inside modals, empty states, auth screens, or between large visual groups that need more breathing room.
- **Do NOT use `spaceLG` for main screen content VStacks** — it creates too much gap, especially when combined with component-level padding (e.g. TabSwitcher's `tabSwitcherPaddingV`).
- When adding a new screen with a `ScrollView { VStack(spacing: ...) { ... } }` pattern, always start with `sectionGap`.

## Design System — Verification Rules (CRITICAL)

- **NEVER guess token names.** Before using any `DarkFantasyTheme.xxx`, open `DarkFantasyTheme.swift` and confirm the property exists. There is no `.accent` — the primary accent is `.gold`.
- **NEVER guess button style names.** Open `ButtonStyles.swift` and verify before using.
- Common mistake: inventing `.accent`, `.primary`, `.background`, `.text` — these DO NOT exist. Use actual tokens: `.gold`, `.bgPrimary`, `.textPrimary`, etc.

## Swift Concurrency Rules (CRITICAL)

- Any enum, struct, or class that accesses `@MainActor`-isolated properties (e.g. `String.localized`, `LocalizationManager.shared`) MUST itself be marked `@MainActor`.
- `L10n` enum is `@MainActor`. Any new type-safe key enums/extensions follow the same pattern.
- When `getAdminUser()` or any function returns `T?`, and you guard with `if (!result) throw` — always use a non-optional binding after the guard: `const safeResult = result!` or use `guard let` in Swift. TypeScript strict mode may not narrow after throw.

## Architecture

- State management: `@MainActor @Observable` classes
- Navigation: `NavigationStack` with `AppRouter`
- Cache: `GameDataCache` environment object, cache-first pattern
- Views pass `@Bindable var vm` to child components (not `@State`)

## Hub ↔ Dungeon Map Transition (CRITICAL)

**The dungeon map is embedded inside HubView**, not presented as a fullScreenCover. Both maps (CityMapView and DungeonMapView) live in a ZStack and crossfade via `showDungeonMap` state.

- **HubView** owns `@State showDungeonMap` and `@State dungeonPath = NavigationPath()`
- **CityMapView** — visible when `showDungeonMap == false`
- **DungeonMapView** — inside its own `NavigationStack(path: $dungeonPath)`, visible when `showDungeonMap == true`
- **Bottom button** — toggles between ADVENTURES ↔ CASTLE, triggers `withAnimation(.easeInOut(duration: 0.45))` crossfade
- **HUD stays in place** — hero widget, floating icons, and bottom button don't move during transition
- **Top fade gradient** — 40pt `LinearGradient` from `bgPrimary` to clear, overlaid on map area for smooth visual transition from HUD to map
- **Dungeon navigation** — tapping a building pushes `DungeonRoomDetailView` inside `dungeonPath` NavigationStack. Back from room returns to dungeon map.
- **`DungeonMapCoverView` is DELETED** — do NOT recreate it or use fullScreenCover for the dungeon map
- **`MainRouterView.destination(for:)`** — static method for routing AppRoute → View. Used by both `mainPath` and `dungeonPath` NavigationStacks.

## dismiss() vs mainPath in Nested NavigationStacks (CRITICAL)

Views that can appear in **multiple NavigationStack contexts** (e.g. `DungeonRoomDetailView` appears in both `mainPath` and `dungeonPath`) **must use `@Environment(\.dismiss)`** for their back button — NOT `appState.mainPath.removeLast()`.

- `dismiss()` works correctly regardless of which NavigationStack the view is inside
- `appState.mainPath.removeLast()` only works when the view is in the main NavigationStack — if it's in `dungeonPath`, it will pop the wrong stack or crash
- **Exception**: `HubLogoButton` is only used in `mainPath` context, so it can keep using `appState.mainPath.removeLast()`

## Motion System (CRITICAL)

**Always use the unified Motion System** for animations, haptics, and micro-interactions. Never hardcode animation durations or haptic calls.

- **Timing**: `MotionConstants` (`Hexbound/Hexbound/Theme/MotionConstants.swift`) — 5 speed tiers (instant/fast/normal/reward/epic), easing presets, shake/progress/reveal constants
- **Haptics**: `HapticManager` (`Hexbound/Hexbound/Theme/HapticManager.swift`) — `@MainActor enum`, static methods. Use compound patterns for game events: `.victory()`, `.defeat()`, `.legendaryReveal()`, `.rankUp()`, `.shake()`, `.coinCascade(count:)`
- **Modifiers**: `.staggeredAppear(index:)`, `.glowPulse(color:intensity:isActive:)`, `.breathing(scale:isActive:)`, `.shimmer(color:duration:)` — in `Hexbound/Hexbound/Theme/` modifier files
- **Components**: `NumberTickUpText` (animated counters), `RewardBurstView` (particle burst with `BurstStyle` enum), `SeasonSummaryModalView` (end-of-season ceremony), `EventBannerView` (timed event banner with countdown)
- **Combat events**: `CombatViewModel.CombatEventType` enum (hit/crit/block/dodge/miss) → `CombatDetailView.handleCombatEvent()` for differentiated shake + haptics + crit flash
- **Modal queue**: `AppState.enqueueModal()` / `.presentNextModal()` / `.dismissXxxModal()` — prevents overlapping modals, auto-chains with delay
- **Slam overlay pattern**: For dramatic text reveals (VS screen, BOSS FIGHT, NEW SEASON BEGINS), use: `scaleEffect(vsScaleFrom→vsScaleTo)` + opacity + dimmed background + `DispatchQueue.main.asyncAfter` phase chain. Always pair with `HapticManager.heavy()`.
- **Rules**: Haptic = special moments only (never on scroll/passive). No persistent particles. No shimmer on prices. Respect `MotionConstants` speed tiers.

## SwiftUI Looping Animations (CRITICAL)

When using `.repeatForever()` on value-driven animations (offset, rotation, opacity, scale):

- **Back-and-forth effects** (shimmer sweep, breathing glow, pulsing scale): ALWAYS use `autoreverses: true`. With `autoreverses: false` the value snaps back to its initial state at the end of each cycle, causing a visible jump.
- **Continuous rotation** (spinning icons, border glow angle): use `autoreverses: false` — rotation 0→360 wraps naturally.
- **Rule of thumb**: if start ≠ end creates a visual discontinuity (e.g. offset -1.2 → 1.5), you MUST autoreverse.
- Never use `.delay()` with `.repeatForever(autoreverses: false)` on position/offset — the delay fires only once, then the snap repeats every cycle.

## SFX Sound System (CRITICAL)

**Always use `SFXManager` for sound effects.** Never use `AVAudioPlayer` directly for SFX — only `AudioManager` handles BGM.

- **Manager**: `SFXManager.shared` (`Hexbound/Hexbound/Persistence/SFXManager.swift`) — `@MainActor` singleton, pooled `AVAudioPlayer` instances (polyphonic), auto-caching, respects `sfxVolume` and `isMuted` from `SettingsManager`
- **Catalog**: `SFX` enum (same file) — all available sound effect keys. If a WAV file is missing from bundle, playback is silently skipped (no crash)
- **Audio files**: `Hexbound/Hexbound/Resources/Audio/SFX/*.wav` — 16-bit 44.1kHz WAV, dark fantasy style (synthesized)
- **Combat mapping**: `SFX.from(vfxType:)` maps `VFXEffectType` → `SFX` enum case. Always call SFX alongside VFX triggers in `CombatViewModel.animateTurn()`
- **UI sounds**: Button styles (`PrimaryButtonStyle`, `SecondaryButtonStyle`, `DangerButtonStyle`, `NavGridButtonStyle`) already trigger SFX via `onChange(of: configuration.isPressed)`. `TabSwitcher` triggers on tap and swipe.
- **Adding new SFX**: (1) Add `.wav` file to `Resources/Audio/SFX/`, (2) add case to `SFX` enum, (3) add file to `project.pbxproj` (PBXBuildFile + PBXFileReference + PBXGroup + PBXResourcesBuildPhase), (4) call `SFXManager.shared.play(.newCase)` at trigger point
- **Preloading**: Use `SFXManager.shared.preload([...])` on screen appear for latency-critical sounds (e.g. combat screen preloads all hit/block/miss sounds)
- **Rules**: SFX on meaningful interactions only (never on scroll/passive). Pair with `HapticManager` calls, not replace them. Keep sound files short (< 1s for UI, < 0.7s for hits). Respect `isMuted` (SFXManager already does this).

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
- Combines: equipment grid + portrait + name/class overlay + Stamina/HP/XP bars + stance card + action pills
- Replaces: `equipmentSection()` + `stanceSummaryCard()` + `UnifiedHeroWidget` on Hero tab
- Universal slots: `amulet` accepts amulet OR necklace; `relic` accepts relic OR accessory OR weapon off-hand
- **Card layout order** (top to bottom): Stamina bar → equipment grid → divider → HP bar → XP bar → stance card → action pills
- **Stamina bar ON TOP** — orange bar above equipment grid, not below. This is intentional per prototype.
- Portrait: 2×3 cell grid with name + CLASS overlay (gradient transparent→black, Oswald 16px), level badge "Lv. X" (gold capsule top-right), class icon badge (top-left), gradient fade on avatar bottom, low-HP red pulse overlay
- Portrait spacing: `LayoutConstants.heroPortraitSideGap` controls gap between side slots and portrait (wider than slot-to-slot gap)
- Bars: HP 24px tall with text centered inside; XP 20px tall with absolute values not percentage; Stamina 20px tall (orange gradient)
- **Stance preview** — full-width card with zone assets (NOT emoji pills). Shows attack zone left, "STANCE" label center, defense zone right. Uses `StanceSelectorViewModel.zoneAsset(for:)` and `.zoneColor(for:)`. Tappable → `onEditStance`.
- Other action pills: repair all (conditional), stat points (conditional), heal (conditional) — shown in HStack below stance card
- **Durability ring overlay** on equipment slots — `DurabilityRingOverlay` shows remaining durability as a partial border ring when < 100%
- Layout tokens: `LayoutConstants.hero*` for card/slot sizing and bar heights
- Integration: see `HeroDetailView.tabContent()` for callback pattern (onTapPortrait, onEditStance, onRepairAll, etc.)

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

## Landing Site (hexbound-landing)

The marketing landing page is a **separate repository and Vercel project** — NOT part of the main monorepo.

- **Repo**: `artosetrov/hexbound-landing` (GitHub, public)
- **Vercel project**: `hexbound-landing` (Art's projects)
- **Stack**: Single `index.html` (~102KB) with inline CSS/JS, GSAP animations, canvas particles
- **Assets**: `assets/` folder (51 files — JPG backgrounds, PNG bosses/buildings/classes/races, logo, appicon)
- **Domain**: `hexboundapp.com` (GoDaddy DNS → Vercel)
  - `A @ → 76.76.21.21` (Vercel)
  - `CNAME www → cname.vercel-dns.com`
- **Other subdomains on hexboundapp.com** (managed via GoDaddy DNS):
  - `admin.hexboundapp.com` → Vercel (admin panel)
  - `api.hexboundapp.com` → Vercel (backend)
- **Deploy**: Push to `main` branch of `artosetrov/hexbound-landing` → auto-deploys on Vercel
- **Local dev**: Open `index.html` in browser — no build step needed
- **.gitignore**: Excludes 5 large unused PNG backgrounds (~42MB total) — only JPG versions are used

**To update the landing page**: Edit `index.html` in the `hexbound-landing` repo, commit, push to `main`. Vercel picks it up automatically. Do NOT confuse this with the main game monorepo.

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
| Motion system, animation audit, juice | `docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md` |
| Landing site (separate repo) | See "Landing Site" section in this `CLAUDE.md` |
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
| `DungeonMapCoverView` (struct) | Removed — dungeon map is now embedded in `HubView` with crossfade transition |

## Game Enums (VERIFY BEFORE USE)

These are the **actual** backend enums. Do not invent values.

- **CharacterClass**: `warrior`, `rogue`, `mage`, `tank`
- **CharacterOrigin**: `human`, `orc`, `skeleton`, `demon`, `dogfolk` (NOT elf, NOT dwarf)
- **CharacterGender**: `male`, `female`
- **ItemType**: `weapon`, `helmet`, `chest`, `gloves`, `legs`, `boots`, `accessory`, `amulet`, `belt`, `relic`, `necklace`, `ring`, `consumable`
- **ItemRarity**: `common`, `uncommon`, `rare`, `epic`, `legendary`
- **DamageType**: `physical`, `magical`, `true_damage`, `poison`

## Property Access (CRITICAL)

- Before accessing a model property — **verify it exists** in the struct/class definition. Do NOT assume computed properties like `resolvedImageKey` exist — they may only be on some types.
- Different models (`Item`, `ShopItem`, `LootPreview`, `EquippedItem`, etc.) have **different property sets**, even if conceptually similar. Always check the specific type definition.

## Agent Orchestrator (CRITICAL — META-AGENT PROTOCOL)

Claude operates as an **orchestrator-agent** for Hexbound. This means Claude does NOT just respond to requests — Claude **proactively thinks about which agents to run, in what order, and whether new agents should be created**.

### Phase 1: Auto-Dispatch (run agents when needed)

**After EVERY completed task**, Claude runs the following decision tree:

| What happened | Agent(s) to spawn | Priority |
|---|---|---|
| Wrote/modified `.swift` files | `hexbound-swift-review` | Auto |
| Wrote/modified `.ts`/`.tsx` files or Prisma schema | `hexbound-backend-review` | Auto |
| Created new screen / major UI change | `hexbound-ux-audit` | Auto |
| Task is done, about to commit | `hexbound-preflight` | Auto |
| Changed 5+ files or refactored | `hexbound-build-verify` | Auto |
| End of session or after large audit | `hexbound-retro` | Suggest |

**Parallel dispatch rules:**
- `swift-review` + `backend-review` can run in parallel (independent)
- `ux-audit` runs after code review agents (may depend on their fixes)
- `preflight` runs last before commit
- `build-verify` only when structural changes are significant
- `retro` is end-of-session only

**How to dispatch:** Use the `Agent` tool with `subagent_type: "general-purpose"` and reference the SKILL.md of the relevant agent. Example: "Read `.skills/skills/hexbound-swift-review/SKILL.md` and perform a full review of the files I just changed: [list files]."

**When NOT to auto-dispatch:**
- Trivial changes (typo fix, comment edit, 1 line change in 1 file)
- User explicitly says "без проверки" / "skip review"
- Only docs/markdown were edited

### Phase 2: Pattern Detection (suggest new agents)

After every 3rd+ interaction in a session, Claude silently evaluates:

1. **Repeated manual steps** — Am I doing the same sequence of checks/actions 3+ times?
   → Suggest: "Я заметил что мы часто [паттерн]. Создать агента для автоматизации?"

2. **Recurring mistakes** — Does the same type of error keep appearing?
   → Suggest: "Ошибка [тип] повторяется. Добавить проверку в [existing agent] или создать новый?"

3. **Missing coverage** — Is there a category of work that no agent reviews?
   → Suggest: "Для [категория] у нас нет агента. Хочешь создать?"

4. **Agent overlap** — Do two agents flag the same thing?
   → Suggest: "hexbound-X и hexbound-Y оба проверяют [тема]. Объединить?"

**Pattern memory format** (save to auto-memory when detected):
```
Pattern: [описание повторяющегося действия]
Frequency: [сколько раз за сессию/неделю]
Suggestion: [новый агент / расширение существующего]
Status: suggested | accepted | rejected
```

### Phase 3: Agent Evolution (update existing agents)

When Claude finds a rule violation that **no agent caught**:
1. Identify which agent SHOULD have caught it
2. After fixing, update that agent's SKILL.md with the new check
3. If the agent has a scanner script, add the pattern there too
4. Log the evolution in `hexbound-retro` format

### Orchestrator Communication Style

- **Before dispatching**: Brief one-liner — "Запускаю swift-review и backend-review параллельно..."
- **After agents finish**: Consolidated summary — issues found, fixes needed, all-clear signals
- **Pattern suggestions**: Frame as questions, not commands — "Заметил паттерн X. Создать агента?"
- **Never surprise-create agents** — always ask first. Only dispatch EXISTING agents automatically.

### Quick Reference: All Hexbound Agents

| Agent | Scope | Script |
|---|---|---|
| `hexbound-swift-review` | SwiftUI design system, architecture, tokens | `scripts/check_design_system.sh` |
| `hexbound-backend-review` | TypeScript/Prisma strict, async, schema sync | `scripts/check_async_await.sh` |
| `hexbound-ux-audit` | UX quality, states, touch targets, game UX | — |
| `hexbound-preflight` | Pre-commit: pbxproj, Prisma, subtree, junk | `scripts/preflight_check.sh` |
| `hexbound-build-verify` | Full build + static analysis | `scripts/verify_build.sh` |
| `hexbound-retro` | Meta: lessons → rule/agent updates | `scripts/gather_metrics.sh` |
- If a needed property is **missing** — use the existing field directly (e.g. `imageKey` instead of `resolvedImageKey`) or **add** a computed property to the model.

## Manually Constructed Items (CRITICAL)

When creating `Item(...)` manually (not from JSON decoding), **pass ALL display-relevant fields** — especially `imageKey`, `catalogId`, and `consumableType`. The `ConsumableInventory` table does NOT store `imageKey` — it must be mapped client-side via `InventoryService.consumableImageKeys`. If you add a new consumable type, you MUST add its mapping to both `consumableDisplayNames` AND `consumableImageKeys` in `InventoryService.swift`, otherwise it will show an SF Symbol fallback instead of the real asset.

## Backend TypeScript Rules (CRITICAL)

- **All `get*Config()` functions in `src/lib/game/live-config.ts` are async.** Always `await` them. Missing `await` produces `Promise<number>` instead of `number` — the build will fail.
- **Never create files with spaces or " 2" in the name.** macOS sometimes creates `file 2.ts` copies. If you see them — delete them, they are junk.
- **`prisma generate` must run before `tsc`/`next build`.** Without it, TS reports false errors for all Prisma models (`mailRecipient`, `shopOffer`, etc. "not found on PrismaClient"). On Vercel this runs automatically via build command. Locally: `cd backend && npx prisma generate` first.
- **`ignoreBuildErrors` is REMOVED.** TypeScript errors now block the Vercel deploy. Do not reintroduce this flag. Fix TS errors properly.
- **Prisma `Json` fields need double cast.** When casting Prisma `Json` type to a concrete interface (e.g. `OfferContent[]`), use `as unknown as OfferContent[]` — direct cast fails in strict mode.

## Replacing / Refactoring Code (CRITICAL)

When replacing a struct, class, function, or view with a new version:
1. **Delete the old code first** — do not leave both old and new versions in the file. Duplicate symbols cause "Invalid redeclaration" and argument-mismatch build errors.
2. **Search the file for the old name** before finishing — if the old struct/function still exists anywhere, remove it.
3. **Search all callers** — if the old type was used in other files, update those call sites to match the new signature.
4. Common mistake: replacing `CloudLayer` → `SkyCloudsFrontLayer` but leaving the old `CloudLayer` + `DriftingCloud` in the same file → redeclaration error.

## Enum Switch Exhaustiveness (CRITICAL)

When adding a new case to ANY Swift enum that has computed properties with `switch self`:
1. **Search all `switch` statements** on that enum — every one must handle the new case.
2. `BurstStyle` enum (`RewardBurstView.swift`) has **5 computed properties** with switches: `colors`, `defaultCount`, `duration`, `radiusRange`, `sizeRange`. Adding a new case (e.g. `.levelUp`) requires updating ALL 5.
3. `VFXEffectType` enum has similar multiple switches. Same for `ItemRarity`, `ModalType`, etc.
4. Swift will catch this at compile time, but verify each switch to give correct values — don't just add `default:` to silence the compiler.

## ViewModifier Parameter Changes (CRITICAL)

When adding a new parameter to a `ViewModifier` struct (e.g. `ShimmerModifier`, `GlowPulseModifier`):
1. **Search ALL callers** — not just the `View` extension, but also any code that calls the struct initializer directly (e.g. `.modifier(ShimmerModifier(color: ..., duration: ...))`).
2. Direct struct initializers do NOT get default parameter values from the extension function — they break immediately.
3. **Prefer using the extension** (`.shimmer(...)`) everywhere. If you find direct `ShimmerModifier(...)` calls, refactor them to use the extension.
4. Always add default values to the struct's `let` properties OR make sure the extension is the only entry point.

## Navigation: dismiss() vs mainPath (CRITICAL)

**Never use `@Environment(\.dismiss)`** for screens in the programmatic `NavigationStack(path: $appState.mainPath)`. It can desync the path binding and cause navigation loops.

- Use `appState.mainPath.removeLast()` instead.
- `HubLogoButton` already implements this pattern — always use it for back navigation. It shows a `ui-arrow-left` back arrow (28×28) and calls `appState.mainPath.removeLast()`.
- `dismiss()` is only safe for sheets (`.sheet`, `.fullScreenCover`) and non-path-based navigation.
- **Do NOT use the hexbound-logo for back navigation.** The back button is a simple left arrow (`ui-arrow-left`), not the app logo.

## Enemy Avatar Mirroring (Combat/VS Screens)

In combat, VS, and comparison views, **mirror the enemy avatar horizontally** so characters face each other. Use `.scaleEffect(x: -1, y: 1)` on enemy portrait `Image` or `AvatarImageView`. The player's avatar faces right (default), the enemy's faces left (mirrored). This applies to: `CombatDetailView`, `ArenaComparisonSheet`, and any future combat/matchup screens.

## Combat Zone Icons — Assets, Not Emoji (CRITICAL)

**Never use emoji (⚔️, 🛡️, 🎯, 🦿) for attack/defense zone indicators.** Always use asset images from `Assets.xcassets`:

- `head` → `Image("icon-helmet")`
- `chest` → `Image("icon-chest")`
- `legs` → `Image("icon-legs")`

**Canonical mapping**: `StanceSelectorViewModel.zoneAsset(for:)` — use this everywhere, never hardcode asset names.

**Sizes by context**: 32×32 in zone selector buttons, 18×18 in inline labels/summaries, 16×16 in compact rows.

**WidgetPill**: Use `imageAsset:` parameter (not emoji `icon:`) when displaying zone icons in pills.

**Files that use zone assets**: `StanceSelectorDetailView`, `HeroDetailView` (stanceSummaryCard), `ArenaDetailView` (stancePreview), `CharacterDetailView` (stance button), `HeroIntegratedCard` (stance pill). If adding a new stance display — follow the same pattern.

## HUD Cards & Banners Over Map — Opaque Backgrounds (CRITICAL)

Any card, banner, or widget that floats over the map (HubView HUD area, ActiveQuestBanner, FirstWinBonusCard, DailyLoginCard, etc.) **must use `DarkFantasyTheme.bgSecondary`** as its background fill — NOT a translucent tint like `color.opacity(0.08)`. Translucent cards become invisible against the dark map artwork.

- Background: `RoundedRectangle(...).fill(DarkFantasyTheme.bgSecondary)`
- Stroke: at least `opacity(0.5)` and `lineWidth: 1.5` for visibility
- If a card is interactive (navigates somewhere), wrap in `Button` with `.buttonStyle(.plain)`, add `chevron.right` indicator, SFX + haptics on tap

## Card Icons — Assets, Not Emoji (CRITICAL)

**Never use emoji (🎯, 🎁, ❓, etc.) as icons in HUD cards, banners, or WidgetPills.** Always use asset images from `Assets.xcassets`. If a suitable asset exists (check `Resources/Assets.xcassets/`), use `Image("asset-name")`. For WidgetPill, use the `imageAsset:` parameter.

- `FirstWinBonusCard` → `Image("reward-first-win")`
- `DailyLoginCard` → `Image("hud-gift")`
- Quest banners → check `quest.icon` — if it's emoji, map to asset or use SF Symbol fallback

## Fight Button Style (No Animation)

`FightButtonStyle` in `ButtonStyles.swift` should have **no animation** — only `opacity(isPressed ? 0.85 : 1)` for minimal press feedback. Do not add shine overlays, `scaleEffect`, breathing animations, or `.animation()` modifiers to the fight button. The button should feel instant and decisive.

## Minimum Font Size (CRITICAL)

**Minimum font size is 16px.** No text in the app should be smaller than 16px — this includes SF Symbol icons used as text, price labels, captions, badges, etc.

- `LayoutConstants.textBadge`, `textCaption`, `textLabel` are all set to **16**. Do NOT lower them.
- When adding hardcoded `.font(.system(size: N))`, ensure N ≥ 16. The only exception is emoji glyphs (`.font(.system(size: 14))` on a `Text("🔥")`) where the size controls the emoji glyph, not readable text.
- If you find any font < 16 in the codebase — fix it.

## TabSwitcher Padding (CRITICAL)

**Every `TabSwitcher` must use the same padding pattern:**
```swift
.padding(.horizontal, LayoutConstants.screenPadding)
.padding(.vertical, LayoutConstants.tabSwitcherPaddingV)
```

- Token: `LayoutConstants.tabSwitcherPaddingV = 8` (vertical gap above & below)
- Do NOT use raw `spaceSM` or skip vertical padding — tabs will visually stick to adjacent bars/content
- Currently used on 5 screens: `ShopDetailView`, `CurrencyPurchaseView`, `ArenaDetailView`, `LeaderboardDetailView`, `AchievementsDetailView`
- When adding TabSwitcher to a new screen, always copy this exact pattern

## NPC Guide Widget (Reusable Pattern)

`MerchantStripView` is a **reusable NPC guide widget** — not shop-specific. It can be used on any screen with any NPC character for tutorials/tips.

- **Tokens**: All sizing lives in `LayoutConstants.npc*` — `npcAvatarSize`, `npcBarHeight`, `npcBarRadius`, `npcBarPaddingH/V`, `npcOuterPadding`, `npcAvatarOffset`, `npcMiniSize`
- **Layout**: ZStack — NPC image (back layer) + speech card (front layer). Card has rounded corners (`npcBarRadius = 12`), equal outer padding on all sides (`npcOuterPadding = 16`)
- **Reuse**: Pass `npcImageName:` to change the NPC portrait. Title text ("MERCHANT") should also be parameterized when creating new instances for other NPCs.
- **Placement**: Wrap in `VStack { Spacer(); widget.padding(.horizontal, npcOuterPadding).padding(.bottom, npcOuterPadding) }` to pin to bottom with equal margins.
- Legacy `merchant*` aliases exist in LayoutConstants — prefer `npc*` tokens for new code.

**Tutorial tooltips use the SAME NPC strip style.** `TutorialTooltipView` (`Tutorial/TutorialTooltipView.swift`) follows the identical visual pattern as `MerchantStripView`: ZStack with NPC image behind + speech card in front, same `npc*` tokens, same `bgElevated`/`borderOrnament` styling. It is always pinned to the bottom of the screen via `TutorialSpotlightOverlay`. If you change the NPC strip visual style — update BOTH `MerchantStripView` AND `TutorialTooltipView` to stay in sync.

## Asset Images: xcassets Imageset (CRITICAL)

When adding a new image to the iOS app:
1. Create an `.imageset` folder inside `Hexbound/Hexbound/Resources/Assets.xcassets/` (e.g. `shopkeeper.imageset/`)
2. Copy the image file into the imageset folder
3. Create a `Contents.json` with the correct `filename`, `idiom: "universal"`, and scale entries
4. Reference in code as `Image("shopkeeper")` — the name matches the folder name (without `.imageset`)
5. Use `UIImage(named:) != nil` guard for safe fallback

Do NOT place raw images in random project folders and reference them by path — they won't load at runtime.

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

## Quality Agents (Auto-Trigger Rules)

Custom agents live in `.skills/skills/hexbound-*`. Each has a clear zone of responsibility:

| Agent | Zone | When to Auto-Spawn |
|-------|------|--------------------|
| `hexbound-swift-review` | SwiftUI code quality: tokens, architecture, patterns | After writing/modifying any `.swift` view file |
| `hexbound-backend-review` | TypeScript/Prisma: types, async, game logic | After writing/modifying any `.ts` API route |
| `hexbound-ux-audit` | Player experience: states, touch targets, retention | When creating a new screen or major UI change |
| `hexbound-preflight` | Structural integrity: pbxproj, schema sync, junk files | Before every commit. After completing any task. |
| `hexbound-build-verify` | Builds & project-wide scans | After large refactors (5+ files). Before discussing deploy. |

**How they work together (typical workflow):**
1. Write code → `swift-review` or `backend-review` checks code quality
2. Ready to commit → `preflight` checks "did I forget a step?"
3. Major change → `build-verify` checks "will it compile?"
4. New screen → `ux-audit` checks "is it good for the player?"

**Rules:**
- Run agents as subagents (Agent tool) in parallel when possible
- `preflight` is the most frequent — run it before EVERY commit
- When an agent finds Critical issues, FIX THEM before proceeding
- Agents have scripts in `scripts/` — always run the script first, then do manual review for what scripts can't catch

## Color Shorthand Extensions (CRITICAL)

When using DarkFantasyTheme colors as `.bgAbyss`, `.textPrimary`, etc. (shorthand without `DarkFantasyTheme.` prefix), these must be registered as static properties on both `Color` and `ShapeStyle`. The extensions live at the bottom of `DarkFantasyTheme.swift`.

**Currently registered shorthand colors:** `bgAbyss`, `bgPrimary`, `bgBackdropLight`, `textPrimary`

**If you use a new shorthand** (e.g. `.bgSecondary` without `DarkFantasyTheme.` prefix), you MUST add it to BOTH extensions in `DarkFantasyTheme.swift`:
```swift
extension Color {
    static var bgSecondary: Color { DarkFantasyTheme.bgSecondary }
}
extension ShapeStyle where Self == Color {
    static var bgSecondary: Color { DarkFantasyTheme.bgSecondary }
}
```

**Preferred approach:** Always use the full `DarkFantasyTheme.xxx` prefix. Only use shorthand when it's already registered in the extensions. The shorthand approach creates a maintenance burden.

## Progress Bar Frame Guards (CRITICAL)

**All GeometryReader-based progress bars MUST clamp their width fraction to `[0, 1]`:**
```swift
.frame(width: geo.size.width * max(0, min(1, fraction)))
```

Without this, SwiftUI logs "Invalid frame dimension (negative or non-finite)" warnings when:
- Division by zero (e.g. `completed / total` when `total == 0`)
- Progress > 1.0 or < 0.0
- NaN from unexpected data

**Pattern:** Look at `UnifiedHeroWidget` and `HPBarView` for the correct pattern with `max(0.02, min(1, ...))`.

## Async Closures in Sync Parameters (CRITICAL)

`ErrorStateView` and similar components expect `() -> Void` closures (synchronous). When calling async functions inside them, ALWAYS wrap in `Task {}`:

```swift
// ❌ WRONG — async closure in sync parameter
ErrorStateView.loadFailed { await vm.loadData() }

// ✅ CORRECT — wrapped in Task
ErrorStateView.loadFailed { Task { await vm.loadData() } }
```

This applies to any factory/builder that takes `@escaping () -> Void` — if you need `await` inside, wrap in `Task`.

## pbxproj: Scan ALL .swift Files, Not Just New Ones (CRITICAL)

After any build failure with "Cannot find X in scope", check if the file exists on disk but is missing from `project.pbxproj`:
```bash
# Find ALL .swift files not in pbxproj
find Hexbound/Hexbound -name "*.swift" | while read f; do
  base=$(basename "$f")
  count=$(grep -c "$base" Hexbound/Hexbound.xcodeproj/project.pbxproj)
  [ "$count" -lt 3 ] && echo "MISSING: $f ($count refs)"
done
```

Files created on disk but not added to the Xcode project will silently not compile — no build error about the file itself, only "Cannot find X in scope" errors in OTHER files that try to use types from the missing file.
