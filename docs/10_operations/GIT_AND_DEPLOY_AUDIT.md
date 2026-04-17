# Hexbound — Git & Deploy Audit

*Date: 2026-04-16. Derived from live repo config, current remotes/branches, Vercel configs, package scripts, Fastlane files, and Herald deploy verification.*

---

## 1. Executive Summary

Hexbound currently operates as **one monorepo with two Git remotes**:

| Remote | GitHub repo | Contents | Deploy target |
|--------|-------------|----------|---------------|
| `origin` | `artosetrov/iron-fist-arena-backend` | Full monorepo (`backend`, `admin`, `Hexbound`, docs, assets) | Backend Vercel project |
| `admin-deploy` | `artosetrov/iron-fist-arena-admin` | `admin/` subtree only | Admin Vercel project |

Current deploy reality:

- **Backend**: automatic Vercel deploy from `origin/main`
- **Admin**: separate Vercel project, updated only after `git subtree push --prefix=admin admin-deploy main`
- **iOS**: manual local/TestFlight flow through Fastlane and Xcode
- **CI**: present and active via `.github/workflows/ci.yml`

Resolved since the older March snapshot:

- GitHub Actions CI now exists
- `ignoreBuildErrors` is gone from backend/admin Next configs
- backend/admin Prisma schemas are synchronized
- local repo state used for Herald verification was clean and `main` was `0 ahead / 0 behind origin/main`

Still open:

- admin deploy remains a manual subtree step
- production migration apply is still an explicit step, not part of Vercel build
- iOS Fastlane `Appfile` still contains placeholder Apple identity/team values
- iOS staging currently points at the same production API URL as release
- landing/legal static deploy flow is still not fully codified in this repo

---

## 2. Git Structure

### Remotes

| Remote | Role | Notes |
|--------|------|-------|
| `origin` | canonical monorepo remote | backend deploy source, main collaboration remote |
| `admin-deploy` | admin-only deploy remote | target for `git subtree push --prefix=admin` |

### Branches

Operationally relevant branches:

| Branch | Role |
|--------|------|
| `main` | primary integration + backend production branch |
| `admin-deploy/main` | admin production branch in the separate deploy repo |
| `admin-subtree` | optional local helper branch for subtree recovery/re-push flows |

Short-lived local scratch branches may exist, but they are not part of the deploy contract.

### Branch Strategy

Current intended workflow remains:

```text
feature/*  -> preview/testing
main       -> production backend deploy
admin-deploy/main <- subtree-pushed admin production deploy
```

This is still effectively trunk-based development with optional short-lived feature branches.

---

## 3. CI / Build Verification

CI now exists and is repo-local:

| Workflow | File | Trigger | What it verifies |
|----------|------|---------|------------------|
| CI - Build Check | `.github/workflows/ci.yml` | `push`, `pull_request` on `main`-relevant paths | backend build/test, admin build, Prisma schema + migration drift |

### Current jobs

1. `Backend Build & Test`
   - `npm ci`
   - `npx prisma generate`
   - `npx vitest run`
   - `npm run docs:balance:check`
   - `npx next build`

2. `Admin Build`
   - `npm ci`
   - `npx prisma generate`
   - `npx next build`

3. `Prisma Schema & Migration Drift Check`
   - `diff backend/prisma/schema.prisma admin/prisma/schema.prisma`
   - `python3 scripts/check_schema_drift.py`

### What CI does not do

- it does **not** deploy
- it does **not** run `prisma migrate deploy`
- it does **not** build or sign iOS

---

## 4. Deploy Flow

### Backend

```text
local changes
  -> git push origin <branch>
  -> preview deploys for non-main branches
  -> git push origin main
  -> Vercel production deploy for backend
```

Source of truth:

- `backend/package.json` -> `build = prisma generate && next build`
- `backend/next.config.ts`
- Vercel backend project config/dashboard

Important:

- backend build currently **fails on real Next build errors**
- backend Vercel build does **not** apply Prisma migrations automatically

### Admin

```text
local changes in admin/
  -> git push origin <branch>   # monorepo only, useful for review/backup
  -> git subtree push --prefix=admin admin-deploy main
  -> Vercel production deploy for admin
```

Source of truth:

- `admin/vercel.json`
- `admin/package.json`
- admin Vercel project

Important:

- ordinary `git push origin main` does **not** update admin production
- admin preview/production lifecycle is coupled to the separate `admin-deploy` repo

### iOS

```text
Xcode / local repo
  -> fastlane build
  -> fastlane beta
  -> TestFlight
  -> manual App Store Connect submit
```

Source of truth:

- `Hexbound/fastlane/Fastfile`
- `Hexbound/fastlane/Appfile`
- `Hexbound/Hexbound/App/AppConstants.swift`

Important:

- Fastlane lanes exist and are usable in structure
- `Appfile` still has placeholder Apple identity/team setup, so release automation is not fully ready

### Landing / legal static pages

This repo no longer carries a maintained local `privacy.html` / `terms.html` working-tree surface. The unresolved gap is documentation for the hosted landing/legal surface and its deployment ownership, not an automated repo-local static-page pipeline.

---

## 5. Database Migration Flow

### Current source of truth

- schema authority: `backend/prisma/schema.prisma`
- admin must mirror backend schema: `admin/prisma/schema.prisma`
- migration history: `backend/prisma/migrations/`

### Current reality

- backend/admin schemas are synchronized right now
- CI enforces schema parity and migration drift checks
- production migration apply is still explicit:

```bash
cd backend
npm run db:migrate:deploy
```

### Important clarification

Neither backend nor admin Vercel build command runs `prisma migrate deploy`.
That means “push + build green” is **not** the same thing as “database has been migrated”.

---

## 6. iOS Release Reality

### Works today

- `Fastfile` contains `beta`, `build`, and version bump lanes
- repo builds locally with `xcodebuild`
- production API base URL is wired in `AppConstants.swift`

### Still incomplete

| Issue | Status | Impact |
|------|--------|--------|
| `Appfile` placeholder Apple ID | unresolved | blocks clean Fastlane/TestFlight ownership setup |
| Team ID / ITC team ID placeholders | unresolved | release setup still environment-dependent/manual |
| staging URL equals production URL | unresolved | debug/staging traffic still points at prod API unless future URL is introduced |
| hardcoded Supabase anon key in app bundle | known | key rotation requires app update |

---

## 7. Risk Snapshot

### High

| Risk | Why it matters |
|------|----------------|
| Admin subtree push is manual | easy to ship backend and forget admin production update |
| Migrations are not auto-applied | green build can still leave prod DB behind code |
| Fastlane Appfile still placeholder-backed | iOS release flow is not fully “turnkey” |

### Medium

| Risk | Why it matters |
|------|----------------|
| iOS staging currently equals production | no clean client-side environment split yet |
| Landing/static deploy contract is undocumented | legal/support surface can drift from the rest of operations |
| branch protection status is undocumented here | human process still carries part of the release safety |

### Resolved since the previous audit snapshot

| Old risk | Current state |
|---------|---------------|
| No CI/CD at all | resolved: `.github/workflows/ci.yml` exists and runs build/test/drift checks |
| Backend `ignoreBuildErrors: true` | resolved: no such flag in current backend/admin Next config |
| Backend/admin schema drift | resolved in current repo state; CI now checks it continuously |
| “136 uncommitted files” local chaos snapshot | stale; no longer a useful standing repo fact |

---

## 8. Recommended Operating Workflow

### Safe normal path

1. Work in `feature/*` for non-trivial changes
2. Push branch and use CI + preview deploys where available
3. Merge or push to `main` for backend production
4. If admin changed, run:

```bash
git subtree push --prefix=admin admin-deploy main
```

5. If schema changed, run production migration apply explicitly:

```bash
cd backend
npm run db:migrate:deploy
```

### iOS release path

1. configure real Fastlane Apple credentials/team values
2. `fastlane build`
3. `fastlane beta`
4. TestFlight validation
5. optional git tag after upload/release

---

## 9. Source-of-Truth Map

| Topic | Current source of truth | Status |
|------|--------------------------|--------|
| Backend deploy | `origin/main` + backend Vercel project + `backend/package.json` | OK |
| Admin deploy | `admin-deploy/main` + subtree push + `admin/vercel.json` | Manual but defined |
| CI build checks | `.github/workflows/ci.yml` | OK |
| Prisma schema authority | `backend/prisma/schema.prisma` | OK |
| Prisma schema parity | CI schema diff + current synced admin schema | OK |
| Migration history | `backend/prisma/migrations/` | OK |
| Migration apply | explicit `npm run db:migrate:deploy` | Manual but defined |
| iOS release lanes | `Hexbound/fastlane/Fastfile` | OK |
| iOS release identity/team setup | `Hexbound/fastlane/Appfile` | Needs setup |
| iOS environment targeting | `Hexbound/Hexbound/App/AppConstants.swift` | Needs review |
| Landing/static deploy | repo docs not fully codified | Needs review |

---

## 10. Bottom Line

The project is no longer in the state described by the older March audit.
Today’s deploy picture is:

- **backend/admin builds and CI checks are real**
- **schema sync is enforced**
- **TypeScript/build failures are no longer being silently ignored**
- **the main remaining operational risks are manual admin subtree deploys, explicit DB migration apply, and unfinished iOS release setup**

That is a much narrower and more actionable risk surface than “no CI/CD, broken schemas, and ignored build errors”.
