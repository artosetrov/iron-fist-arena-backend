# Hexbound — iOS Release Guide

*Source of truth: this file + `Hexbound/fastlane/` + `Hexbound/Config/` + `Hexbound/Hexbound/App/AppConstants.swift`. Updated: 2026-04-19*

---

## Prerequisites

1. **Apple Developer Account** with App Store Connect access
2. **Xcode 15+** with iOS 17 SDK
3. **Fastlane** installed: `brew install fastlane`
4. **Fastlane identity configured**: use `FASTLANE_*` env vars or local ignored file `Hexbound/fastlane/Appfile.local`
5. **Signing**: valid provisioning profile "Hexbound AppStore" for `com.hexbound.app`

Current repo reality:

- `Fastfile` lanes exist and are usable as the release skeleton
- release identity is intentionally kept out of the tracked `Appfile`
- team/local overrides belong in ignored local files or CI env vars
- treat Fastlane release as **validated setup-required**, not ad hoc manual editing

## Environment Config

Runtime config is injected at build time:

- `Hexbound/Config/Shared.xcconfig`
- `Hexbound/Config/Debug.xcconfig`
- `Hexbound/Config/Release.xcconfig`
- `Hexbound/Config/Local.secrets.xcconfig` (ignored, local-only)

Important clarification:

- Swift no longer owns backend/auth/google IDs directly
- `AppConstants.swift` now reads values from `Info.plist`, which is fed by the xcconfig layer
- local machines should copy `Local.secrets.example.xcconfig` → `Local.secrets.xcconfig`
- today the local staging host may still equal production until dedicated staging infra exists; the preflight now warns about that explicitly

## Release Preflight

Before `fastlane build` or `fastlane beta`:

```bash
cd Hexbound
python3 scripts/check_release_config.py
```

The same preflight now runs automatically from Fastlane and from `scripts/deploy_testflight.sh`.

## Release Flow

### 1. Bump Version

```bash
cd Hexbound

# Patch: 1.0.0 → 1.0.1
fastlane bump_patch

# Minor: 1.0.x → 1.1.0
fastlane bump_minor

# Major: 1.x.x → 2.0.0
fastlane bump_major
```

### 2. Build + Upload to TestFlight

```bash
fastlane beta
```

This runs:
1. Increment build number
2. Archive with Release configuration
3. Upload to App Store Connect / TestFlight
4. Print success with version + build number

This step depends on:

- real Apple credentials/team configuration being present at runtime
- valid iOS runtime config in `Config/Local.secrets.xcconfig`

### 3. Test in TestFlight

1. Open TestFlight app on device
2. Install latest build
3. Test critical flows: login, PvP, shop, dungeons
4. Check for crashes in App Store Connect → TestFlight → Crashes

### 4. Submit to App Store

1. Go to App Store Connect → Hexbound → App Store tab
2. Create new version
3. Select TestFlight build
4. Fill in release notes
5. Submit for review

### 5. Tag in Git

```bash
# After successful TestFlight upload
git tag ios-v1.0.1-build42
git push origin --tags
```

## Build Only (No Upload)

```bash
fastlane build
```

Useful for verifying compilation before committing.

For repo-local smoke verification, `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` is still the cleanest non-upload gate.

## Fastlane Files

| File | Purpose |
|------|---------|
| `Hexbound/fastlane/Fastfile` | Lane definitions + release preflight |
| `Hexbound/fastlane/Appfile` | Bundle identifier + env/local identity loading |
| `Hexbound/fastlane/Appfile.local` | Ignored local release credentials |
| `Hexbound/Config/*.xcconfig` | Build-time runtime config by environment |

## Setup Checklist (First Time)

- [ ] Copy `Hexbound/Config/Local.secrets.example.xcconfig` → `Hexbound/Config/Local.secrets.xcconfig`
- [ ] Fill in API / Supabase / Google values
- [ ] Copy `Hexbound/fastlane/Appfile.local.example` → `Hexbound/fastlane/Appfile.local` or provide `FASTLANE_*` env vars
- [ ] Create App ID `com.hexbound.app` in Apple Developer Portal
- [ ] Create provisioning profile "Hexbound AppStore"
- [ ] Create app in App Store Connect (see `docs/10_operations/TESTFLIGHT_GUIDE.md` for details)
- [ ] Run `python3 scripts/check_release_config.py`
- [ ] Run `fastlane build` to verify everything works

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| "No signing certificate" | Open Xcode → Signing & Capabilities → enable Automatic Signing |
| "Provisioning profile not found" | Create "Hexbound AppStore" profile in developer.apple.com |
| Missing local Appfile identity | Create `fastlane/Appfile.local` or provide `FASTLANE_*` env vars |
| Build number conflict | Fastlane auto-increments, but if stuck: manually set in Xcode |
| Thought Swift hardcoded the backend config | Config now comes from `Config/*.xcconfig` + `Info.plist`, not from Swift source |

## Rollback

- **TestFlight**: Remove build from test group in App Store Connect
- **App Store**: Submit previous version as new release (cannot truly rollback)
- **Emergency**: Enable maintenance mode via backend feature flag, push hotfix
