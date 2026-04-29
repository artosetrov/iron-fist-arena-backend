# Feature: Characters

> Single-file map of every file that touches characters — creation, class/origin/gender selection, appearance, stat allocation, profile, respec.

## One-liner

Each player owns a Character with class (warrior/rogue/mage/tank), origin (human/orc/skeleton/demon/dogfolk), gender, name, appearance skin, allocated stats, level/XP.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Auth/OnboardingDetailView.swift` + steps (`NameStepView`, `ClassSelectionStepView`, `AppearanceStepView`) — first-time creation
  - `Hexbound/Hexbound/Views/Auth/CharacterSelectionView.swift` — returning-user slot picker
  - `Hexbound/Hexbound/Views/Hero/HeroDetailView.swift` — main hero screen (3 tabs: Inventory / Stats / Talents)
  - `Hexbound/Hexbound/Views/Hero/HeroStatsTab.swift` — stat allocation UI
  - `Hexbound/Hexbound/Views/Hero/BuyStatPointsView.swift` — gem-purchase stat points
  - `Hexbound/Hexbound/Views/Profile/CharacterProfileView.swift` — player-facing profile card
  - `Hexbound/Hexbound/Views/Profile/AppearanceEditorDetailView.swift` — appearance skin editor
- **Player action:** Onboarding wizard on first launch OR Hub → Hero building

## Backend

### Routes

- `GET  /api/characters`                       — `backend/src/app/api/characters/route.ts` — list my characters
- `POST /api/characters`                       — same file — create new character
- `GET  /api/characters/[id]`                  — `backend/src/app/api/characters/[id]/route.ts` — fetch single character
- `PATCH /api/characters/[id]`                 — same file — rename / basic updates
- `POST /api/characters/check-name`            — `backend/src/app/api/characters/check-name/route.ts` — name availability check
- `POST /api/characters/[id]/allocate-stats`   — `backend/src/app/api/characters/[id]/allocate-stats/route.ts` — spend stat points
- `POST /api/characters/[id]/respec-stats`     — `backend/src/app/api/characters/[id]/respec-stats/route.ts` — refund + re-allocate
- `POST /api/characters/[id]/buy-stat-points`  — `backend/src/app/api/characters/[id]/buy-stat-points/route.ts` — gem purchase of extra points
- `POST /api/characters/[id]/appearance`       — `backend/src/app/api/characters/[id]/appearance/route.ts` — change appearance skin
- `POST /api/characters/[id]/origin`           — `backend/src/app/api/characters/[id]/origin/route.ts` — change origin (post-creation re-pick)
- `POST /api/characters/[id]/stance`           — `backend/src/app/api/characters/[id]/stance/route.ts` — set combat stance
- `GET  /api/characters/[id]/profile`          — `backend/src/app/api/characters/[id]/profile/route.ts` — full profile for viewing
- `GET  /api/characters/[id]/set-bonuses`      — `backend/src/app/api/characters/[id]/set-bonuses/route.ts` — equipped set bonus totals
- `GET  /api/appearances`                      — `backend/src/app/api/appearances/route.ts` — available appearance skin catalog

### Business logic

- `backend/src/lib/game/character.ts` — creation / validation / stat allocation rules
- `backend/src/lib/game/stats.ts` — derived stats from allocation + gear + passives
- `backend/src/lib/game/set-bonuses.ts` — equipped-set resolver

### Prisma models touched

- `Character` (line 313) — id, userId, name, class, origin, gender, level, xp, prestige, allocated stats, referralCode, referredBy, derived flags
- `AppearanceSkin` (line 848) — per-class skin pool; owned/unlocked flags

### Game enums (CLAUDE.md-canonical)

- `CharacterClass`: warrior, rogue, mage, tank
- `CharacterOrigin`: human, orc, skeleton, demon, dogfolk (NOT elf/dwarf)
- `CharacterGender`: male, female

## iOS

### Views

- `Hexbound/Hexbound/Views/Hero/HeroDetailView.swift` — main hero host screen
- `Hexbound/Hexbound/Views/Hero/HeroInventoryTab.swift`, `HeroStatsTab.swift` — tabs
- `Hexbound/Hexbound/Views/Hero/Talents/*` — talent/passive/active-slot UI (tab 3 — see [[passive-tree]])
- `Hexbound/Hexbound/Views/Auth/*` onboarding steps — creation wizard (see [[auth]])
- `Hexbound/Hexbound/Views/Profile/CharacterProfileView.swift` + `AppearanceEditorDetailView.swift`

### ViewModels

- `Hexbound/Hexbound/Views/Hero/BuyStatPointsViewModel.swift`
- `Hexbound/Hexbound/Views/Auth/CharacterSelectionViewModel.swift`, `OnboardingViewModel.swift`
- `Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift`

### Services

- `Hexbound/Hexbound/Services/CharacterService.swift` — create / fetch / mutate

### Cache

- `GameDataCache.currentCharacter` — single active character
- `GameDataCache.appearanceSkins` — available skin list

### Components (Figma DS)

- `IntegratedCharacterCard` — unified Hero + Opponent card (see [[opponent-profile]])
- `Avatar` — 3 variants
- `ClassTagView`, `GlassStatPill` — profile display

## Admin

- `admin/src/app/(dashboard)/players/page.tsx` — player search / account review entry point
- `admin/src/app/(dashboard)/players/[id]/page.tsx` — character detail review plus gold/gems grant and inventory reset
- No dedicated `admin/src/app/(dashboard)/characters/` tree is checked in today

## Docs

- `docs/06_game_systems/COMBAT.md` — stats + class behavior
- `docs/04_database/SCHEMA_REFERENCE.md` — Character fields
- `docs/07_ui_ux/SCREEN_INVENTORY.md` — Hero/Profile screens

## Notable gotchas

- **Enum strictness.** `elf`/`dwarf` are NOT valid origins. Any case-sensitivity drift in backend enum = 400s.
- **Name uniqueness.** `check-name` must run before create — server re-checks at create time (race condition possible).
- **Stat allocation is server-authoritative.** Client NEVER computes derived stats — only displays what backend returns.
- **Respec cost.** Respec burns gold/gems — scale is in `balance.ts`, increases per respec.
- **Appearance fallback chain.** `AvatarImageView` falls back in a deterministic order: `deterministicSeed` render → class-pool skin → class icon.
- **Appearance skins are per-class.** Picking an off-class skin in editor = 400.
- **Referral fields on Character.** `referralCode` + `referredBy` live on Character — see [[referral]].

## Tests / fixtures

- `backend/tests/api/characters-list.test.ts`
- `backend/tests/api/character-progression-derived-stats.test.ts`
- No broader dedicated character CRUD/backend suite is checked in today

## Related features

- [[auth]] — character creation is step 2 of onboarding
- [[passive-tree]] — character's allocated passives + active slots
- [[inventory]] — equipped gear affects derived stats
- [[prestige]] — resets level + keeps some permanents on Character
