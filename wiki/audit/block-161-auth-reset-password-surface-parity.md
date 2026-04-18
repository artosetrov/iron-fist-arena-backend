---
title: Audit Block 161 — Auth Reset Password Surface Parity
category: audit
tags: [audit, auth, backend, docs, supabase]
sources:
  - backend/src/app/api/auth/forgot-password/route.ts
  - backend/src/app/reset-password/page.tsx
  - backend/email-templates/reset-password.html
  - wiki/features/auth.md
  - docs/03_backend_and_api/API_REFERENCE.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 161 — Auth Reset Password Surface Parity

> Later follow-up: [block-187-backend-forgot-password-canonical-host-fallback](/Users/artosetrov/Documents/Cursor%20AI/PVP%20RPG/wiki/audit/block-187-backend-forgot-password-canonical-host-fallback.md) removed the stale Vercel fallback host from `forgot-password` and locked the route to the canonical production backend origin when `NEXT_PUBLIC_APP_URL` is unset.

## Scope

- `backend/src/app/api/auth/forgot-password/route.ts`
- `backend/src/app/reset-password/page.tsx`
- `backend/email-templates/reset-password.html`
- `wiki/features/auth.md`
- `docs/03_backend_and_api/API_REFERENCE.md`

## Why this block

The password-reset flow was already materially present in the repo, but the docs still described it like an almost entirely Supabase-dashboard concern.

That created two false impressions:

1. the reset-email template looked like it lived only in hosted dashboard state;
2. the reset link looked like it had no first-party web surface in the repo.

Neither was true anymore.

## What is live

- `POST /api/auth/forgot-password` triggers Supabase reset mail and points `redirectTo` at `/reset-password`
- `backend/src/app/reset-password/page.tsx` is the actual reset landing screen that exchanges the code, updates the password, and signs the user out
- `backend/email-templates/reset-password.html` is the repo-owned source template to paste into the Supabase dashboard

So the runtime is hybrid:

- Supabase still sends the email
- but the template source and the landing page are both now first-party repo surfaces

## Fix applied

### `wiki/features/auth.md`

- added the hosted reset page as a real backend-owned surface
- updated the password-reset note so it no longer says the custom template lives only in the Supabase dashboard
- clarified that the repo keeps the source HTML template and the hosted `/reset-password` landing page

### `docs/03_backend_and_api/API_REFERENCE.md`

- tightened the `/auth/forgot-password` description so it mentions the reset-mail role and the `/reset-password` redirect target

## File records

| Path | Role | Status |
|------|------|--------|
| `backend/src/app/api/auth/forgot-password/route.ts` | Password-reset mail trigger and redirect bootstrap | OK |
| `backend/src/app/reset-password/page.tsx` | Hosted password-reset landing page for the emailed link | OK |
| `backend/email-templates/reset-password.html` | Repo-owned source for the Supabase reset email template | OK |
| `wiki/features/auth.md` | Auth feature map and operator-facing truth layer | Fixed |
| `docs/03_backend_and_api/API_REFERENCE.md` | Human-readable route catalog | Fixed |

## Result

The auth docs now match the real surface area:

- reset password is not "just a dashboard thing";
- the repo owns both the landing page and the template source;
- Supabase still remains the delivery mechanism.

## Verification

- `rg -n "reset-password|forgot-password|Supabase dashboard|password reset" backend/src docs wiki -S`
- `git diff --check`

Both passed for this block.
