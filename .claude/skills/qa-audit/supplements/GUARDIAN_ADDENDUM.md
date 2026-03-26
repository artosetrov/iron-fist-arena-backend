# Guardian Agent — QA Audit Addendum (2026-03-25)

These findings should be checked by the Guardian agent during iOS code reviews, in addition to its standard checklist.

## New Check: Force Unwraps

- **Zero force unwrap policy.** Grep for `randomElement()!` — found 5 instances in animation views (CoinFlyAnimationView, SpinningRaysView, particle systems).
- **Replace with:** `randomElement() ?? defaultValue` or `guard let` pattern.
- **Also check:** `URL(string:)!`, `TimeZone(identifier:)!` — use `?? .gmt` / `guard let` fallbacks.

## New Check: Error Surfacing

- **GoogleSignInHelper:** Sign-in errors are silently swallowed. Must add do/catch with error toast.
- **StoreKitService:** IAP failures silently fail. Must surface errors via toast with support contact CTA.
- **All mutating actions:** Must show error toast with Retry button on failure.

## New Check: Cache TTL

- **All GameDataCache entries must have TTL.** Some entries were found without TTL, leading to indefinitely stale data.
- **Standard TTLs:** opponents (30s), dailyQuests (60s), achievements (120s), battlePass (120s), shop (300s).

## New Check: Toast API

- **showToast signature:** `appState.showToast(_ title: String, subtitle: String = "", type: ToastType)`. First arg positional.
- **NO `.success` type.** Use `.info` or `.reward` instead.
- **NO `message:` parameter.** Use `subtitle:`.
- **Known past incident:** LeaderboardPlayerDetailSheet and GuildHallDetailView used wrong signatures.

## New Check: Compositioning

- **`.compositingGroup()` is MANDATORY after 2+ ornamental overlays.** Check that surfaceLighting + innerBorder + cornerBrackets stacks end with `.compositingGroup()` BEFORE `.shadow()`.

## Known Open Issues (track status)

| ID | Severity | Issue | Status |
|---|---|---|---|
| BUG-002 | CRITICAL | 5 force unwraps in animation views | OPEN |
| BUG-004 | HIGH | GoogleSignInHelper missing error handling | OPEN |
| BUG-005 | HIGH | StoreKit purchase error not surfaced | OPEN |
| BUG-009 | HIGH | Some caches missing TTL | OPEN |
| BUG-012 | MEDIUM | 1 ViewModel not @MainActor | OPEN |
