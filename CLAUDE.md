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
- Always use `ButtonStyles.swift` styles (`.primary`, `.secondary`, `.neutral`, etc.) — never inline button styling
- Always use `LayoutConstants` for spacing/sizing — minimum font size is `LayoutConstants.textBadge` (11px)
- The theme file is at `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
- Button styles are at `Hexbound/Hexbound/Theme/ButtonStyles.swift`
- Layout constants are at `Hexbound/Hexbound/Theme/LayoutConstants.swift`

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

## Swift Concurrency Rules (CRITICAL)

- Any enum, struct, or class that accesses `@MainActor`-isolated properties (e.g. `String.localized`, `LocalizationManager.shared`) MUST itself be marked `@MainActor`.
- `L10n` enum is `@MainActor`. Any new type-safe key enums/extensions follow the same pattern.
- When `getAdminUser()` or any function returns `T?`, and you guard with `if (!result) throw` — always use a non-optional binding after the guard: `const safeResult = result!` or use `guard let` in Swift. TypeScript strict mode may not narrow after throw.

## Architecture

- State management: `@MainActor @Observable` classes
- Navigation: `NavigationStack` with `AppRouter`
- Cache: `GameDataCache` environment object, cache-first pattern
- Views pass `@Bindable var vm` to child components (not `@State`)

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
- If a needed property is **missing** — use the existing field directly (e.g. `imageKey` instead of `resolvedImageKey`) or **add** a computed property to the model.

## Self-Documenting Rules (META)

If during work you discover a pattern, bug, or practice that:
- **repeats** across sessions (same mistake / same manual step),
- **breaks the build** or causes a runtime crash,
- requires **non-obvious project knowledge** (API quirks, model specifics, dependencies),

then **automatically add a new rule** to this `CLAUDE.md` without asking. Format: brief problem description + what to do / what not to do. Choose the section by topic or create a new one.
