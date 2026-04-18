# Feature: Onboarding

> Single-file map of every file that touches first-time character creation and the immediate cold-open flow before free play begins.

## One-liner

A new player picks class, appearance, and name in a three-step hero-forging flow, creates their first character, and then hands off into the cinematic/tutorial opening.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Auth/OnboardingDetailView.swift` — three-step creation wizard
  - `Hexbound/Hexbound/Views/Auth/ClassSelectionStepView.swift` — class pick
  - `Hexbound/Hexbound/Views/Auth/AppearanceStepView.swift` — origin/gender/skin pick
  - `Hexbound/Hexbound/Views/Auth/NameStepView.swift` — name entry + availability gate
  - `Hexbound/Hexbound/Views/Auth/OnboardingCinematicView.swift` — handoff cinematic after forge
  - `Hexbound/Hexbound/Views/Auth/HeroForgeOverlayView.swift` — root-mounted forging overlay that survives transition
- **Trigger:** first successful auth / guest start with no character yet
- **Player action:** pick class → pick appearance → pick name → create hero

## Backend

### Routes

- `GET  /api/appearances`             — `backend/src/app/api/appearances/route.ts` — appearance skin catalog for creation
- `POST /api/characters/check-name`   — `backend/src/app/api/characters/check-name/route.ts` — name availability check
- `POST /api/characters`              — `backend/src/app/api/characters/route.ts` — create first character

### Business logic

- character creation validates class/origin/gender/name server-side and applies the canonical fallback default skin for the chosen origin+gender
- onboarding is intentionally thin on business logic: it is mostly a UX/state shell over character creation
- after creation, control passes into the post-onboarding cinematic/tutorial flow rather than dropping straight into free play

### Prisma models touched

- `Character` — first character row is created here
- `AppearanceSkin` — catalog and default-skin resolution
- `User` — account row is ensured/upserted before first character create succeeds

## iOS

### Views

- `Hexbound/Hexbound/Views/Auth/OnboardingDetailView.swift` — host wizard and step bar
- `Hexbound/Hexbound/Views/Auth/ClassSelectionStepView.swift`
- `Hexbound/Hexbound/Views/Auth/AppearanceStepView.swift`
- `Hexbound/Hexbound/Views/Auth/NameStepView.swift`
- `Hexbound/Hexbound/Views/Auth/OnboardingCinematicView.swift`
- `Hexbound/Hexbound/Views/Auth/HeroForgeOverlayView.swift`

### ViewModel

- `Hexbound/Hexbound/Views/Auth/OnboardingViewModel.swift` — wizard state, skin fetch, name check debounce/cache, and create-character submit path

### Services / models

- creation uses typed request/response DTOs inside `OnboardingViewModel`
- resulting character is pushed into app/cache state and then handed to the next cold-open stage

### Cache

- `GameDataCache.currentCharacter` — first populated from successful create response
- `GameDataCache.appearanceSkins` / local skin fetch path — used to drive the appearance picker

## Admin

- no dedicated admin authoring surface; QA/admin can only reset downstream player state indirectly via player tools

## Docs

- `wiki/features/auth.md` — auth hosts and gates the onboarding entry
- `wiki/features/characters.md` — created character becomes the long-lived player entity
- `wiki/features/tutorial.md` — tutorial begins after onboarding completes

## Notable gotchas

- **Step order is fixed.** The wizard is intentionally class → appearance → name; later screens depend on earlier picks.
- **Server owns the final fallback skin.** Client tries to pick a valid skin, but backend still chooses a canonical default if the submitted avatar is missing/invalid.
- **Name checks are advisory until create.** Availability is preflighted in UI, but the create route still re-checks uniqueness and can return conflict.
- **Hero forge overlay must live at app root.** Re-embedding it inside the onboarding screen breaks the cross-fade into cinematic/tutorial.
- **Onboarding is not tutorial.** Character creation stops at first-hero forge; the scripted quest/fight flow is a separate feature that starts immediately after.

## Tests / fixtures

- creation and name-check behavior are covered by backend auth/character tests rather than a standalone onboarding test suite

## Related features

- [[auth]] — decides whether the player enters onboarding at all
- [[characters]] — resulting long-lived entity created here
- [[tutorial]] — scripted first-run flow that starts after onboarding
- [[session-summary]] — later launch-time reporting, not part of first-time onboarding
