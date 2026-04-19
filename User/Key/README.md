# Apple Keys (Local Only)

This folder is for local Apple private keys that must never be committed to git.

Rules:

- Keep `.p8` files local-only.
- Use environment variables or secret storage for hosted environments.
- If a key was ever committed, revoke and rotate it in Apple immediately.

Local backend setup for Apple IAP verification:

1. Put the downloaded In-App Purchase key here, for example:
   `User/Key/SubscriptionKey_LOCAL_ONLY.p8`
2. Set these variables in `backend/.env` or your local shell:
   `APPLE_IAP_KEY_ID=...`
   `APPLE_IAP_ISSUER_ID=...`
   `APPLE_IAP_PRIVATE_KEY_PATH=../User/Key/SubscriptionKey_LOCAL_ONLY.p8`

Notes:

- `APPLE_IAP_PRIVATE_KEY_PATH` is resolved from the current backend working directory, so the example above works when commands run from `backend/`.
- `APPLE_IAP_PRIVATE_KEY` is still supported for secret stores like Vercel, but local files are safer than pasting key contents into repo-adjacent env files.
- Fastlane/TestFlight upload auth is a separate App Store Connect API key flow and should not reuse the IAP key by assumption.
