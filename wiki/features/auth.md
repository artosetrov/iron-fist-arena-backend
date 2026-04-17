# Feature: Auth

> Single-file map of every file that touches authentication — guest → email/Google/Apple → upgrade flow, account linking, password reset, deletion.

## One-liner

Players launch as guest; upgrade to a persisted account via Email / Google / Apple, link providers, reset password, or delete account.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Auth/WelcomeView.swift` — first splash, guest CTA
  - `Hexbound/Hexbound/Views/Auth/AuthView.swift` — unified auth host
  - `Hexbound/Hexbound/Views/Auth/LoginView.swift` — email+password login
  - `Hexbound/Hexbound/Views/Auth/RegisterDetailView.swift` — email+password registration
  - `Hexbound/Hexbound/Views/Auth/UpgradeGuestView.swift` — guest → persisted upgrade
  - `Hexbound/Hexbound/Views/Auth/EmailConfirmationView.swift` — post-register confirmation screen
  - `Hexbound/Hexbound/Views/Auth/AuthBackground.swift` — shared cinematic backdrop
- **Player action:** First launch lands on Welcome → "Continue as Guest" OR email/Google/Apple sign-in

## Backend

### Routes

#### Guest + session
- `POST /api/auth/guest`                  — `backend/src/app/api/auth/guest/route.ts` — anon account creation
- `POST /api/auth/guest-login`            — `backend/src/app/api/auth/guest-login/route.ts` — guest session resume
- `POST /api/auth/sync-user`              — `backend/src/app/api/auth/sync-user/route.ts` — sync Supabase Auth user → `User` row

#### Email/password
- `POST /api/auth/register`               — `backend/src/app/api/auth/register/route.ts` — email signup
- `POST /api/auth/login`                  — `backend/src/app/api/auth/login/route.ts` — email login
- `POST /api/auth/forgot-password`        — `backend/src/app/api/auth/forgot-password/route.ts` — password reset email

#### OAuth
- `POST /api/auth/google`                 — `backend/src/app/api/auth/google/route.ts` — Google Sign-In token exchange
- `POST /api/auth/apple`                  — `backend/src/app/api/auth/apple/route.ts` — Apple Sign-In token exchange

#### Upgrade + linking
- `POST /api/auth/upgrade-guest`          — `backend/src/app/api/auth/upgrade-guest/route.ts` — guest → email+password
- `POST /api/auth/upgrade-guest-oauth`    — `backend/src/app/api/auth/upgrade-guest-oauth/route.ts` — guest → Google/Apple
- `POST /api/auth/link-account`           — `backend/src/app/api/auth/link-account/route.ts` — link extra provider to existing account

#### User account mgmt
- `POST /api/user/email`                  — `backend/src/app/api/user/email/route.ts` — change email
- `POST /api/user/password`               — `backend/src/app/api/user/password/route.ts` — change password
- `POST /api/user/delete`                 — `backend/src/app/api/user/delete/route.ts` — full account deletion (cascade)

### Business logic

- `backend/src/lib/auth/*` — token verification helpers (Supabase Auth + provider-specific)
- Supabase Auth is the identity provider — backend validates JWTs; `User` row is the in-app profile linked by `authUserId`

### Prisma models touched

- `User` (line 247) — in-app profile; `authUserId` links to Supabase Auth user
- `Character` (line 313) — belongs to User; created at first successful auth

## iOS

### Views

- `Hexbound/Hexbound/Views/Auth/AuthView.swift` — auth host / state switcher
- `Hexbound/Hexbound/Views/Auth/LoginView.swift`, `RegisterDetailView.swift`, `UpgradeGuestView.swift`, `EmailConfirmationView.swift`, `WelcomeView.swift`
- `Hexbound/Hexbound/Views/Auth/CharacterSelectionView.swift` + VM — select existing character on returning login
- `Hexbound/Hexbound/Views/Auth/OnboardingDetailView.swift`, `OnboardingCinematicView.swift`, `HeroForgeOverlayView.swift`, `NameStepView.swift`, `ClassSelectionStepView.swift`, `AppearanceStepView.swift` — first-time character creation flow
- `Hexbound/Hexbound/Views/Onboarding/TutorialFightView.swift`, `CombatColdOpenView.swift`, `VictoryOverlayView.swift` — tutorial fight immediately after onboarding

### ViewModels

- `Hexbound/Hexbound/Views/Auth/LoginViewModel.swift`, `RegisterViewModel.swift`, `OnboardingViewModel.swift`, `CharacterSelectionViewModel.swift`
- `Hexbound/Hexbound/Views/Onboarding/TutorialFightViewModel.swift`

### Services

- `Hexbound/Hexbound/Services/AuthService.swift` — Supabase Auth wrapper, session persistence, guest token handling
- `Hexbound/Hexbound/Services/GoogleSignInHelper.swift` — Google SDK wrapper

### Cache

- `GameDataCache.currentUser`, `.currentCharacter` — populated on successful auth

## Admin

- `admin/src/app/(dashboard)/users/` — user lookup, account unlocking, manual email verify

## Docs

- `docs/03_backend_and_api/API_REFERENCE.md` — auth routes
- `docs/10_operations/DEPLOY.md` — Supabase Auth keys + JWT secrets

## Notable gotchas

- **Supabase JWT on every authed request.** Backend validates via shared secret; rotating the secret requires matching admin + backend redeploy.
- **Guest accounts persist.** A `User` row with `authUserId == null` (or guest flag) survives app uninstall only if `guest-login` token was saved by client — otherwise orphaned row.
- **Upgrade is atomic.** Guest → email/oauth must transact `User` update AND bring all `Character`/inventory rows with it; partial upgrade = player loses progress.
- **OAuth account collision.** If a Google email matches an existing email-only account, backend must return "link me" path, not "already exists" error.
- **Deletion cascade.** `POST /api/user/delete` must cascade into all 60+ character-owned tables; any missing `onDelete: Cascade` = orphaned rows forever.
- **Email-only via Supabase.** Email confirmation + password-reset emails are Supabase-hosted — custom template lives in Supabase dashboard.

## Tests / fixtures

- `backend/src/__tests__/auth/*` (if present)

## Related features

- [[tutorial]] — runs immediately after first-ever auth
- [[characters]] — character creation is step 2 of onboarding
- [[session-summary]] — reads current user on every launch
