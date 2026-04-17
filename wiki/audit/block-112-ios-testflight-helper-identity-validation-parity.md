---
title: Block 112 — iOS TestFlight helper identity validation parity
category: audit
tags: [audit, ios, release, fastlane, scripts, docs]
sources:
  - Hexbound/scripts/deploy_testflight.sh
  - docs/10_operations/TESTFLIGHT_GUIDE.md
  - Hexbound/fastlane/Appfile
  - Hexbound/Gemfile
updated: 2026-04-16
status: Fixed
---

# Block 112 — iOS TestFlight helper identity validation parity

## Scope

- `Hexbound/scripts/deploy_testflight.sh`
- `docs/10_operations/TESTFLIGHT_GUIDE.md`
- `Hexbound/fastlane/Appfile`
- `Hexbound/Gemfile`

## Why this block

After the release-doc sync work, one live helper still had a subtle mismatch:

- the TestFlight shell helper only looked for the placeholder Apple ID in `Appfile`
- but the repo also supports env-based Fastlane identity configuration

That meant it could:

- falsely fail when env vars were correctly provided, or
- pass too optimistically when Apple ID was configured but team setup was still missing

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-110-operations-git-workflow-and-ios-release-doc-parity]]

## File notes

### `Hexbound/scripts/deploy_testflight.sh`

- **Zone:** iOS / release helper
- **Purpose:** one-command local TestFlight launcher
- **Problems found:**
  - validated only placeholder Apple ID
  - did not treat env-based Fastlane identity as a first-class valid setup path
  - did not require team configuration with the same strictness as Apple ID
- **What was fixed:**
  - added identity validation for both setup modes:
    - populated `fastlane/Appfile`
    - or `FASTLANE_*` env vars
  - required team presence via `FASTLANE_TEAM_ID`, `FASTLANE_ITC_TEAM_ID`, or uncommented `team_id` / `itc_team_id`
  - improved operator-facing error text so the failure tells you exactly how to fix setup
- **Status:** Fixed

### `docs/10_operations/TESTFLIGHT_GUIDE.md`

- **Zone:** operations / iOS release docs
- **Purpose:** human runbook for TestFlight upload
- **Problems found:**
  - initial setup wording favored editing `Appfile` only, even though env-based setup is also valid
  - helper-script behavior was not described accurately after the script hardening
- **What was fixed:**
  - documented both supported identity-setup paths
  - documented that `deploy_testflight.sh` validates both
- **Status:** Fixed

### `Hexbound/fastlane/Appfile`

- **Zone:** iOS / Fastlane config
- **Purpose:** default identity/team config source
- **Review outcome:**
  - placeholders remain expected in repo and are now handled more honestly by the helper/docs
- **Action:** no code change
- **Status:** Needs review

### `Hexbound/Gemfile`

- **Zone:** iOS / release tooling
- **Purpose:** bundled Fastlane dependency source
- **Review outcome:**
  - confirms the script/docs are right to prefer `bundle install` / `bundle exec` when available
- **Action:** no code change
- **Status:** OK

## Problems found

1. **The helper validated only one identity setup mode**
   - Risk: false-negative local release failures when env-based Fastlane config is used correctly.
   - Fix: script now accepts both Appfile-based and env-based setup.

2. **The helper did not enforce team setup strongly enough**
   - Risk: release starts with incomplete Apple identity and then fails deeper in Fastlane.
   - Fix: team presence is now validated explicitly.

3. **Docs and helper were drifting apart**
   - Risk: operators follow a doc path the helper itself interprets differently.
   - Fix: updated the TestFlight guide to match the hardened helper behavior.

## Verification

- inspected `Hexbound/scripts/deploy_testflight.sh`
- inspected `docs/10_operations/TESTFLIGHT_GUIDE.md`
- inspected `Hexbound/fastlane/Appfile`
- inspected `Hexbound/Gemfile`
- `git diff --check`

## Follow-up

- The remaining iOS release debt is now the real one, not the wrapper mismatch:
  - repo `Appfile` still contains placeholders
  - staging/prod API host separation is still not implemented
