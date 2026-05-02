---
title: Audit Block 275 — PvP Resolve Absolute Rating Bounds (Combat V2 D-1)
category: audit
tags: [audit, backend, ios, pvp, combat, interactive-combat, contract, codable]
sources:
  - backend/src/app/api/pvp/resolve/route.ts
  - Hexbound/Hexbound/Models/CombatData.swift
  - Hexbound/Hexbound/Services/BattlePreloader.swift
  - Hexbound/Hexbound/Services/CombatEngine.swift
  - Hexbound/Hexbound/Views/Combat/CombatViewModel.swift
  - Hexbound/Hexbound/Views/Hub/HubBannerCards.swift
  - Hexbound/Hexbound/Views/Social/GuildHallViewModel.swift
  - Hexbound/Hexbound/Views/Dev/MockData.swift
  - docs/07_ui_ux/COMBAT_UX_INTEGRATION_PLAN.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 275 — PvP Resolve Absolute Rating Bounds (Combat V2 D-1)

## Scope

Combat V2 §8 decision **D-1** (locked 2026-04-29 in `block-262`) requires the
END-screen `RewardsBlock` to render *delta + new total* (e.g. `+24 / 1248`)
instead of delta-only. This block plumbs the absolute pre/post rating bounds
end-to-end across the live PvP resolve path.

## Why this block

`CombatResultInfo` (`Hexbound/Hexbound/Models/CombatData.swift`) gained two
optional fields earlier on 2026-04-29:

```swift
let ratingBefore: Int?
let ratingAfter: Int?
```

`CombatResultInfo` is `Codable` with no explicit `init`, so Swift uses the
auto-synthesized memberwise init — even optional fields require explicit
arguments at every call site. Adding these two fields silently broke five
constructors and four `ResolveResult` constructors. Xcode surfaced two
errors first (`CombatEngine` + `CombatViewModel`), but a repo grep showed the
real blast radius before any of them were fixed.

Without the plumb-through, the iOS `RewardsBlock` would have nothing to
render in the new D-1 mode — Combat V2 PR-3 / PR-5 cannot land.

## Changes shipped

### 1. Backend resolve response (`/api/pvp/resolve`)

Both response payloads now expose absolute rating bounds:

- **PvP block** (`route.ts` ~line 522, after the ELO calc at line 488):

  ```ts
  result: {
    // …existing fields…
    rating_change: ratingChange,
    // Combat V2 D-1 (2026-04-29): absolute bounds for delta+total render.
    rating_before: attacker.pvpRating,
    rating_after: attackerNewRating,
    // …
  }
  ```

- **Bot block** (`route.ts` ~line 827, after `attackerNewRating` calc at
  line 664):

  ```ts
  result: {
    // …existing fields…
    rating_change: ratingChange,
    rating_before: attacker.pvpRating,
    rating_after: attackerNewRating,
    // …
  }
  ```

Bots surface the pair too so the iOS view doesn't need to branch on opponent
type. Live PvP and bot fights both feed the same `RewardsBlock`.

### 2. iOS decode + propagation (`BattlePreloader.swift`)

- `PvpResolveResultPayload` (private decode struct) gained:

  ```swift
  let ratingBefore: Int?
  let ratingAfter: Int?
  ```

  Both optional so an older client against an older backend still decodes —
  `nil` propagates and `RewardsBlock` falls back to delta-only.

- `ResolveResult` (the main app-facing struct) gained the same pair.

- The `resolve()` constructor passes `response.result.ratingBefore` /
  `response.result.ratingAfter` straight through.

The decoder uses `.convertFromSnakeCase`, so `rating_before` ↔ `ratingBefore`
maps automatically — no explicit `CodingKeys` needed.

### 3. iOS `CombatResultInfo` callsites (5 total)

| Site | Path | Values |
| ---- | ---- | ------ |
| Server resolve merge | `Views/Combat/CombatViewModel.swift:560` | `resolve.ratingBefore` / `resolve.ratingAfter` |
| Offline prediction | `Services/CombatEngine.swift:724` | `nil` / `nil` (no server bounds) |
| Challenge accept | `Views/Hub/HubBannerCards.swift:310` | `nil` / `nil` (challenge endpoint doesn't expose them yet) |
| Guild challenge accept | `Views/Social/GuildHallViewModel.swift:559` | `nil` / `nil` (same reason) |
| Mock data | `Views/Dev/MockData.swift:79` | `1230` / `1248` (exercises delta+total branch in previews) |

### 4. iOS `ResolveResult` callsites (4 total)

| Site | Path | Values |
| ---- | ---- | ------ |
| Server resolve | `Services/BattlePreloader.swift:449` | `response.result.ratingBefore` / `response.result.ratingAfter` |
| Challenge accept | `Views/Hub/HubBannerCards.swift:333` | `nil` / `nil` |
| Guild challenge accept | `Views/Social/GuildHallViewModel.swift:600` | `nil` / `nil` |
| Mock data | `Views/Dev/MockData.swift:101` | `1230` / `1248` |

`TutorialService.swift` defines its own internal `struct ResolveResult` (not
the same type) — out of scope, no change required.

## Verification

- Repo grep for `CombatResultInfo(` returns 5 sites; all now pass
  `ratingBefore` and `ratingAfter`.
- Repo grep for `ResolveResult(` returns 4 production sites + 1 tutorial-local
  type; all 4 production sites now pass the pair.
- No new files added → no `project.pbxproj` work; no Prisma schema change →
  no migration. The change is shape-additive on the response, so no
  migration-before-deploy gate applies.
- Backend `attacker.pvpRating` / `attackerNewRating` are already defined
  at the top of both PvP and bot resolve blocks (lines 224 / 664) — no new
  variables introduced.

## Result

- `/api/pvp/resolve` now emits `rating_before` / `rating_after` for both PvP
  and bot fights.
- The iOS `RewardsBlock` (Combat V2 PR-3 / PR-5) can render the locked
  D-1 *delta + new total* layout end-to-end on the live `pvp` resolve path.
- Pre-D-1 backends remain decode-compatible — clients fall back to
  delta-only when both fields decode as `nil`.

## Open follow-ups (deferred, not blockers)

- **Challenge / guild challenge endpoints still don't expose absolute
  rating bounds.** `Views/Hub/HubBannerCards.swift` and
  `Views/Social/GuildHallViewModel.swift` still pass `nil`. Accepting a
  challenge from the Hub or Guild Hall will show delta-only on the END
  screen until those endpoints follow the same pattern.
- **Generated indexes.** `wiki/_generated/api-routes.json` is produced by
  `scripts/`; regen via the existing wiki-generation tooling rather than
  hand-edit. Same regen also touches the auto-generated balance docs if
  any constants moved (not the case here).

## Cross-references

- Combat V2 plan: `docs/07_ui_ux/COMBAT_UX_INTEGRATION_PLAN.md` §8 (D-1)
- Talents v2 + V2 §8 close: `block-262-talents-v2-ult-action-types-and-class-trees`
- ELO derivation: `wiki/systems/pvp-rating.md`
- PvP feature map: `wiki/features/pvp-combat.md`
- Codable memberwise-init bug pattern (this block reinforces): adding any
  field — optional or not — to a `Codable` struct without an explicit
  `init` breaks every direct constructor across the codebase, even when
  decode itself stays backwards-compatible.
