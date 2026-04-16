---
title: Block 108 — iOS intentional raw boundaries and dead APIResponse removal
category: audit
tags: [audit, ios, networking, keychain, cleanup]
sources:
  - Hexbound/Hexbound/Network/APIClient.swift
  - Hexbound/Hexbound/Network/APIError.swift
  - Hexbound/Hexbound/Persistence/KeychainManager.swift
  - Hexbound/Hexbound/Services/GameDataCache.swift
  - Hexbound/Hexbound/Models/DailyLoginRewardDef.swift
updated: 2026-04-16
status: Fixed
---

# Block 108 — iOS intentional raw boundaries and dead APIResponse removal

## Scope

- `Hexbound/Hexbound/Network/APIClient.swift`
- `Hexbound/Hexbound/Network/APIError.swift`
- `Hexbound/Hexbound/Persistence/KeychainManager.swift`
- `Hexbound/Hexbound/Services/GameDataCache.swift`
- `Hexbound/Hexbound/Models/DailyLoginRewardDef.swift`

## Why this block

After blocks `105–107`, the residual raw-pattern grep in `Hexbound` had narrowed to three places:

- generic error-body extraction in `APIClient` / `APIError`
- `Security` framework keychain query dictionaries in `KeychainManager`
- one last dead `APIResponse` helper and the now-dead `GameConfig` raw fallback path that had briefly kept `DailyLoginRewardDef.init(dictionary:)` alive

That is a very different situation from earlier raw network debt. At this point the real job was to separate:

- **intentional framework-level raw boundaries** from
- **actual leftover dead compatibility code**

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-102-ios-network-infrastructure-raw-surface-retirement]]
- [[block-105-ios-typed-error-body-and-combat-model-bridge-cleanup]]
- [[block-107-ios-dead-model-parse-bridge-cleanup]]

## File notes

### `Hexbound/Hexbound/Network/APIClient.swift`

- **Zone:** iOS / networking
- **Purpose:** generic request execution, auth retry, and status-code handling
- **Review outcome:**
  - the remaining `JSONSerialization` use is intentional and centralized
  - it exists only to parse arbitrary 4xx/5xx error bodies into a generic structure before callers optionally decode typed recoverable payloads on top
- **Action:** left in place as an intentional boundary
- **Status:** OK

### `Hexbound/Hexbound/Network/APIError.swift`

- **Zone:** iOS / networking
- **Purpose:** shared typed error surface for transport and server failures
- **Problems found:**
  - `APIResponse` was a dead leftover helper with no callers
- **What was fixed:**
  - removed dead `APIResponse`
  - kept `clientError(... body: [String: Any]?)` and `responsePayload` as the single centralized raw error-body boundary
- **Status:** Fixed

### `Hexbound/Hexbound/Persistence/KeychainManager.swift`

- **Zone:** iOS / persistence / auth
- **Purpose:** wrapper around the system `Security` keychain API for token and device-id persistence
- **Review outcome:**
  - the `[String: Any]` query dictionaries are required by the `Security` API and are not project-specific contract drift
- **Action:** left in place as an intentional framework boundary
- **Status:** OK

### `Hexbound/Hexbound/Services/GameDataCache.swift`

- **Zone:** iOS / shared cache
- **Purpose:** typed shared cache for init/bootstrap and screen-level data
- **Problems found:**
  - `GameConfig.init(from dict:)` was fully dead after the typed bootstrap migration
- **What was fixed:**
  - removed the dead raw `GameConfig` initializer and its raw daily-login parsing fallback
- **Status:** Fixed

### `Hexbound/Hexbound/Models/DailyLoginRewardDef.swift`

- **Zone:** iOS / daily login model
- **Purpose:** typed daily-login reward definition shared by bootstrap and presentation
- **Problems found:**
  - the compatibility `init(dictionary:)` restored during block `107` was only needed because the dead raw `GameConfig` path still existed
- **What was fixed:**
  - removed `init(dictionary:)` again once the dead caller was retired
- **Status:** Fixed

## Problems found

1. **One dead response helper survived inside the network layer**
   - Risk: it kept implying there was still a second generic response abstraction in use.
   - Fix: removed dead `APIResponse`.

2. **`GameConfig` still carried a raw fallback constructor after the typed bootstrap migration**
   - Risk: it kept a misleading raw parsing tail alive and forced `DailyLoginRewardDef` to preserve a compatibility initializer the app no longer needed.
   - Fix: removed the dead raw `GameConfig` path and then deleted the no-longer-needed daily-login dictionary helper.

3. **The remaining raw grep hits needed explicit classification**
   - Risk: future audits could mistake intentional framework-level code for unfinished feature-level migration work.
   - Fix: documented `APIClient`/`APIError` generic error extraction and `KeychainManager` security queries as intentional raw boundaries.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`
- `rg -n 'APIResponse\\b|getRaw\\(|postRaw\\(|patchRaw\\(|JSONSerialization|\\[String: Any\\]|responsePayload' Hexbound/Hexbound -g'*.swift'`

## Follow-up

- After this block, the residual raw grep in `Hexbound` is down to:
  - centralized generic error-body parsing in networking
  - `Security` framework keychain query dictionaries
- That is now a deliberate infrastructure boundary, not a lingering feature-contract cleanup tail.
