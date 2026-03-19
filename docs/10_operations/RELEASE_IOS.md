# Hexbound — iOS Release Guide

*Source of truth: this file + Hexbound/fastlane/. Updated: 2026-03-19*

---

## Prerequisites

1. **Apple Developer Account** with App Store Connect access
2. **Xcode 15+** with iOS 17 SDK
3. **Fastlane** installed: `brew install fastlane`
4. **Appfile configured**: `Hexbound/fastlane/Appfile` — set your Apple ID + Team ID
5. **Signing**: valid provisioning profile "Hexbound AppStore" for `com.hexbound.app`

## Environment Config

API endpoints are configured in `Hexbound/Hexbound/App/AppConstants.swift`:

- **DEBUG builds**: use staging URL (currently same as production)
- **RELEASE builds**: use production URL (`api.hexboundapp.com`)
- **Override**: set `HEXBOUND_ENV=staging` in Xcode scheme environment variables

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

## Fastlane Files

| File | Purpose |
|------|---------|
| `Hexbound/fastlane/Fastfile` | Lane definitions (beta, build, bump_*) |
| `Hexbound/fastlane/Appfile` | Apple ID, Team ID, bundle identifier |

## Setup Checklist (First Time)

- [ ] Set Apple ID in `Appfile` (or `FASTLANE_APPLE_ID` env var)
- [ ] Set Team ID in `Appfile` (or `FASTLANE_TEAM_ID` env var)
- [ ] Create App ID `com.hexbound.app` in Apple Developer Portal
- [ ] Create provisioning profile "Hexbound AppStore"
- [ ] Create app in App Store Connect (see `docs/10_operations/TESTFLIGHT_GUIDE.md` for details)
- [ ] Run `fastlane build` to verify everything works

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| "No signing certificate" | Open Xcode → Signing & Capabilities → enable Automatic Signing |
| "Provisioning profile not found" | Create "Hexbound AppStore" profile in developer.apple.com |
| Appfile still has placeholder | Set real Apple ID and Team ID |
| Build number conflict | Fastlane auto-increments, but if stuck: manually set in Xcode |
| Wrong API URL in build | Check `AppConstants.swift` Environment enum |

## Rollback

- **TestFlight**: Remove build from test group in App Store Connect
- **App Store**: Submit previous version as new release (cannot truly rollback)
- **Emergency**: Enable maintenance mode via backend feature flag, push hotfix
