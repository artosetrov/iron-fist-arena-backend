# Hexbound — Root Project Rules

This file is the cross-domain bootstrap for the monorepo.

- Full docs index: `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`
- Canonical development rules: `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md`
- iOS / SwiftUI domain rules: `Hexbound/CLAUDE.md`
- Backend / Prisma domain rules: `backend/CLAUDE.md`
- Wiki source of truth: `wiki/index.md`, `wiki/audit/audit-index.md`, `wiki/audit/project-file-inventory.md`

Use this file for repo-wide invariants only. Domain-specific detail belongs in the iOS/backend docs above.

## Repo Truths

- Client is never authoritative for combat results, rewards, ratings, economy values, or balance formulas.
- `backend/prisma/schema.prisma` is the single database schema source of truth.
- `wiki/` is the living audit/source-of-truth layer for file coverage and architectural drift.
- Before inventing enums, token names, API shapes, or file paths, open the real source and verify.

## Quick References

- Generated indexes: `wiki/_generated/`
  - `tokens.json`
  - `api-routes.json`
  - `prisma-models.json`
  - `balance-constants.json`
  - `ios-screens.json`
- Feature maps: `wiki/features/`
- API reference: `docs/03_backend_and_api/API_REFERENCE.md`
- Schema reference: `docs/04_database/SCHEMA_REFERENCE.md`
- Balance constants: `docs/06_game_systems/BALANCE_CONSTANTS.md`
- Design system: `docs/07_ui_ux/DESIGN_SYSTEM.md`
- Screen inventory: `docs/07_ui_ux/SCREEN_INVENTORY.md`
- Deploy/runbooks: `docs/10_operations/`

## Architecture

- iOS state: `@MainActor @Observable`
- Navigation: `NavigationStack` with `AppRouter`
- Cache-first flows: prefer warm cache display, then background refresh
- Child views receive `@Bindable var vm`, not `@State` copies of parent view models
- Shared gameplay/business rules must live in backend/runtime contracts, not be rederived separately in admin/iOS

## Xcode Project File

When adding any new `.swift` file under `Hexbound/`, also add it to:

1. `PBXBuildFile`
2. `PBXFileReference`
3. the correct `PBXGroup.children`
4. `PBXSourcesBuildPhase.files`

If you skip `project.pbxproj`, the file will not compile.

## Design System

For exhaustive token/component rules, read `Hexbound/CLAUDE.md`.

Repo-wide summary:

- Use `DarkFantasyTheme` tokens, never raw `Color(hex:)`
- Use shared `ButtonStyles.swift`, `CardStyles.swift`, `OrnamentalStyles.swift`
- Use `LayoutConstants` spacing/radius tokens
- Confirm token names in source before use; do not guess

## Figma

Two-file rule:

- DS file: `Hexbound-DS` — components/tokens/assets only
- Screen file: `Hexbound-Design` — app screens only

Screen-creation rules live in:

- `docs/07_ui_ux/FIGMA_SCREEN_RULES.md`

Do not treat old prototype HTML files as current design truth. Historical design branches now live in docs/wiki, not detached prototype files.

## Enums and Contracts

Verify from source before use. Common examples that frequently drift:

- `CharacterClass`: `warrior`, `rogue`, `mage`, `tank`
- `CharacterOrigin`: `human`, `orc`, `skeleton`, `demon`, `dogfolk`
- `CharacterGender`: `male`, `female`
- `QuestType`: confirm in backend before adding/changing
- Item and reward types: confirm in backend contract helpers before using in admin/iOS

## Prisma Schema Sync

After any Prisma schema change:

1. create/apply the migration in `backend/`
2. copy `backend/prisma/schema.prisma` to `admin/prisma/schema.prisma`
3. commit both together

Mandatory drift check before deploy:

```bash
python3 scripts/check_schema_drift.py
```

## Git / Deploy

Backend deploy path and admin deploy path are different:

- `origin` -> monorepo / backend flow
- `admin-deploy` -> admin subtree deploy flow

If `admin/` changed and you are shipping admin:

```bash
git subtree push --prefix=admin admin-deploy main
```

Production migrations are still an explicit step. Do not assume Vercel build applies Prisma migrations automatically.

Canonical runbooks:

- `docs/10_operations/DEPLOY.md`
- `docs/10_operations/GIT_WORKFLOW.md`
- `docs/10_operations/DATABASE_MIGRATIONS.md`
- `docs/10_operations/RELEASE_IOS.md`

## Validation Before Ship

Minimum repo-wide sanity checks:

```bash
python3 scripts/check_schema_drift.py
git diff --check
grep -rn '^<<<<<<<\\|^=======$\\|^>>>>>>>' . --include='*.swift' --include='*.ts' --include='*.prisma' | grep -v node_modules
```

Then run the appropriate domain builds/tests for the surfaces you touched.

## Landing Site

The marketing landing page is a separate repo/project:

- repo: `artosetrov/hexbound-landing`
- not part of this monorepo runtime

Do not treat landing/legal/static-site work as living inside this repo unless explicitly reintroduced.

## Root File Hygiene

Root should stay small and intentional:

- repo policy/bootstrap files belong here
- dated audits, QA snapshots, feature plans, and implementation history belong in `docs/`, `qa-reports/`, or `wiki/`
- editor residue, ad-hoc prototypes, and generated junk should not accumulate in root

If a rule becomes domain-specific or too detailed, move it into the proper domain CLAUDE or canonical doc and keep this file compact.
