---
title: Audit Block 187 — Backend Forgot Password Canonical Host Fallback
category: audit
tags: [audit, auth, backend, reset-password, supabase]
sources:
  - backend/src/app/api/auth/forgot-password/route.ts
  - backend/tests/api/auth-forgot-password.test.ts
  - wiki/features/auth.md
  - wiki/audit/block-161-auth-reset-password-surface-parity.md
  - docs/10_operations/DEPLOY.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 187 — Backend Forgot Password Canonical Host Fallback

## Scope

- `backend/src/app/api/auth/forgot-password/route.ts`
- `backend/tests/api/auth-forgot-password.test.ts`
- `wiki/features/auth.md`
- `wiki/audit/block-161-auth-reset-password-surface-parity.md`
- `docs/10_operations/DEPLOY.md`

## Why this block

Block 161 already established that the repo owns the password-reset landing page and template source.

But the runtime still had one stale seam left:

- if `NEXT_PUBLIC_APP_URL` was unset, `forgot-password` fell back to `https://iron-fist-arena-backend.vercel.app`

That hostname no longer matched the live production backend identity documented in deploy docs (`api.hexboundapp.com`), so the flow could quietly drift back to an old host whenever environment config was missing or incomplete.

## Fix applied

### `backend/src/app/api/auth/forgot-password/route.ts`

- introduced a single `DEFAULT_APP_URL` constant
- changed the fallback from the old Vercel hostname to `https://api.hexboundapp.com`
- kept the existing trailing-slash trim before appending `/reset-password`

### `backend/tests/api/auth-forgot-password.test.ts`

- added regression coverage proving that:
  - the route uses the canonical production backend host when `NEXT_PUBLIC_APP_URL` is unset
  - the route still respects an explicit env override and trims a trailing slash

### `wiki/features/auth.md`

- added a gotcha note so the auth feature page now records the fallback-host contract explicitly

## File records

| Path | Role | Status |
|------|------|--------|
| `backend/src/app/api/auth/forgot-password/route.ts` | Password-reset mail trigger and redirect bootstrap | Fixed |
| `backend/tests/api/auth-forgot-password.test.ts` | Regression coverage for canonical reset redirect host behavior | Fixed |
| `wiki/features/auth.md` | Auth feature map and runtime gotchas | Fixed |
| `wiki/audit/block-161-auth-reset-password-surface-parity.md` | Earlier reset-flow truth-sync block, now linked to this fallback-host follow-up | Fixed |
| `docs/10_operations/DEPLOY.md` | Deploy truth source confirming the canonical backend host | OK |

## Result

The reset-password flow now has one coherent host story:

- `NEXT_PUBLIC_APP_URL` wins when configured
- otherwise the route falls back to the canonical production backend origin
- the old temporary Vercel hostname is no longer baked into runtime behavior

## Verification

- `cd backend && npx vitest run tests/api/auth-forgot-password.test.ts`
- `cd backend && npx eslint src/app/api/auth/forgot-password/route.ts tests/api/auth-forgot-password.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed.
