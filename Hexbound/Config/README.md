# Hexbound iOS Config

This folder holds build-time runtime configuration for the iOS app.

Files:

- `Shared.xcconfig` — tracked defaults and required keys
- `Debug.xcconfig` — debug/staging environment wiring
- `Release.xcconfig` — release/production environment wiring
- `Local.secrets.example.xcconfig` — template for the ignored local override file
- `Local.secrets.xcconfig` — local real values, ignored by Git

How to use:

1. Copy `Local.secrets.example.xcconfig` to `Local.secrets.xcconfig`
2. Fill in the real API / Supabase / Google values
3. Keep `Release.xcconfig` pointed at production
4. Point `Debug.xcconfig` at a true staging backend when one exists

Validation:

- Run `python3 scripts/check_release_config.py`
- `fastlane build` / `fastlane beta` now run the same preflight automatically
