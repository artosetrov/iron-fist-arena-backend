# Hexbound — Project Rules

> **Full documentation**: See `docs/01_source_of_truth/DOCUMENTATION_INDEX.md` for the complete docs structure.
> **Canonical rules**: See `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md` for the extended version.
> **iOS/SwiftUI rules**: See `Hexbound/CLAUDE.md`
> **Backend/TypeScript rules**: See `backend/CLAUDE.md`

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
| `.body` | Inter | 16 | Body text |
| `.uiLabel` | Inter | 14 | Labels |
| `.caption` | Inter | 12 | Captions |
| `.badge` | Inter | 11 bold | Badges |

**DO NOT exist:** `.largeTitleFont`, `.titleFont`, `.bodyFont`, `.headlineFont`, `.subtitleFont`, `.captionFont`. Bold: `.body.bold()`, `.uiLabel.bold()`.

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
| Art prompts | `docs/08_prompts/ASSET_PROMPTS_INDEX.md` |
| Deploy flow, Vercel | `docs/10_operations/DEPLOY.md` |
| Git workflow, subtree | `docs/10_operations/GIT_WORKFLOW.md` |
| DB migrations, Prisma | `docs/10_operations/DATABASE_MIGRATIONS.md` |
| iOS release, TestFlight | `docs/10_operations/RELEASE_IOS.md` |
| Error patterns catalog | `docs/09_rules_and_guidelines/ERROR_CATALOG.md` |
| Full doc index | `docs/01_source_of_truth/DOCUMENTATION_INDEX.md` |

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
# SF Symbol currency icons
grep -rn 'dollarsign\.circle\|diamond\.fill.*currency' Hexbound/Hexbound/Views/ --include="*.swift"
# Junk files in xcodeproj
ls Hexbound/Hexbound.xcodeproj/ | grep -E '\.(bak|backup|tmp)$'
# Merge conflict markers
grep -rn '^<<<<<<<\|^=======\$\|^>>>>>>>' . --include="*.swift" --include="*.ts" --include="*.prisma" | grep -v node_modules
```

ALL pass → "CDO: CLEAN". Any fail → fix + re-scan. **Never skip.**

## Self-Documenting Rules (META — MANDATORY)

After ANY task:
1. Re-read relevant `CLAUDE.md` (root + domain). Did I follow all rules?
2. If discovered a repeating pattern/gotcha → add rule to the appropriate `CLAUDE.md`
3. If behavior/schema/API/screens changed → update relevant doc in `/docs/`
4. Commit rule/doc updates with the task or as `docs(claude):` commit
