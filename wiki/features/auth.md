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
- `GET /reset-password`                   — `backend/src/app/reset-password/page.tsx` — hosted password-reset landing page for Supabase email links

#### OAuth
- `POST /api/auth/google`                 — `backend/src/app/api/auth/google/route.ts` — Google Sign-In token exchange
- `POST /api/auth/apple`                  — `backend/src/app/api/auth/apple/route.ts` — Apple Sign-In token exchange

#### Upgrade + linking
- `POST /api/auth/upgrade-guest`          — `backend/src/app/api/auth/upgrade-guest/route.ts` — guest → email+password
- `POST /api/auth/upgrade-guest-oauth`    — `backend/src/app/api/auth/upgrade-guest-oauth/route.ts` — guest → Google/Apple
- `POST /api/auth/link-account`           — `backend/src/app/api/auth/link-account/route.ts` — legacy compatibility route for local profile-link sync after external provider linking

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
- `backend/email-templates/reset-password.html` — repo-owned source for the Supabase reset email template

## Notable gotchas

- **Supabase JWT on every authed request.** Backend validates via shared secret; rotating the secret requires matching admin + backend redeploy.
- **Guest accounts persist.** A `User` row with `authUserId == null` (or guest flag) survives app uninstall only if `guest-login` token was saved by client — otherwise orphaned row.
- **Upgrade is atomic.** Guest → email/oauth must transact `User` update AND bring all `Character`/inventory rows with it; partial upgrade = player loses progress.
- **`/auth/upgrade-guest` now rolls back the full Supabase identity on local persistence failure.** If guest→email updates Supabase email/password successfully but both local `User` update attempts fail, the route now reverts the auth user back to guest metadata and restores the previous guest email instead of leaving Supabase upgraded while Prisma still says anonymous.
- **Guest → OAuth merge policy is now explicit.** When an OAuth-side `User` row already exists without a character, guest upgrade merges `gold` + `gems`, keeps the later premium expiry/claim date, and preserves the longer-lived `dailyGemCard`.
- **`/auth/upgrade-guest-oauth` now cleans fresh OAuth auth residue on transfer failure.** If Supabase OAuth sign-in succeeds but the guest→OAuth transfer transaction fails before the local attach completes, the route now deletes the fresh OAuth auth user when there was no pre-existing local OAuth row instead of leaving an auth-only identity behind.
- **Reset-password fallback host is now canonical.** If `NEXT_PUBLIC_APP_URL` is unset, forgot-password mail falls back to `https://api.hexboundapp.com/reset-password`, not the old temporary Vercel hostname.
- **`/auth/link-account` is not the main upgrade path.** The live iOS settings flow sends guests to `upgradeGuest`; `link-account` remains a narrower compatibility surface for syncing local profile fields after an already-authenticated provider-link step, and now returns `409` for duplicate-email collisions instead of bubbling a generic update failure.
- **`/auth/sync-user` now hard-fails cleanly on identity collisions.** If the incoming email already belongs to another user row, the route returns `409` instead of relying on a later unique-constraint failure during upsert.
- **`/auth/guest-login` no longer returns orphan guest sessions on device races.** If a fresh guest creation loses a `deviceId` race at local `User` creation time, the route now deletes the just-created Supabase guest and restores the already-linked guest account instead of returning tokens for a session with no local profile row.
- **Fresh guest sign-in failure now cleans both sides.** If `guest-login` has already created the local guest row and the follow-up sign-in still fails, the route now deletes both the fresh Supabase guest and the local `User` row instead of leaving a local orphan behind.
- **OAuth first-login collisions now fail cleanly.** If Google or Apple sign-in comes in for an email that already belongs to another local account, the route now deletes the fresh Supabase OAuth user and returns `409` with an explicit “log in and link from settings” direction instead of falling through to a generic local-create failure.
- **OAuth first-login local init failures now clean up Supabase too.** If Google or Apple sign-in creates/authenticates the Supabase user but local `User` initialization still fails, the route now deletes the fresh auth user instead of leaving an auth-only orphan behind for the next retry.
- **Email register local-init failures now clean up Supabase too.** If `/auth/register` creates the Supabase user and even signs in successfully but local `User` initialization still fails, the route now deletes the fresh auth user and returns `500 Failed to initialize account` instead of keeping an auth-only email account alive.
- **Deletion cascade.** `POST /api/user/delete` must cascade into all 60+ character-owned tables; any missing `onDelete: Cascade` = orphaned rows forever.
- **Email delivery still runs through Supabase.** The password-reset email is still sent by Supabase Auth, but the repo now keeps the source template at `backend/email-templates/reset-password.html` and the reset flow lands on the hosted `backend/src/app/reset-password/page.tsx`.

## Tests / fixtures

- `backend/src/__tests__/auth/*` (if present)

## Related features

- [[tutorial]] — runs immediately after first-ever auth
- [[characters]] — character creation is step 2 of onboarding
- [[session-summary]] — reads current user on every launch
