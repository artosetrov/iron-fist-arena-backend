# Arena — Restore Rating Widget in Place of Stance Tile

**Date:** 2026-05-04
**Status:** Historical restore proposal — Arena later shipped the compact rating widget back into this slot with stance access preserved as a smaller dedicated CTA.
**Trigger:** Artem: «на месте виджета стойки должен быть виджет рейтинга персонажа — мы его уже делали ранее».

> **Status boundary:** preserve this file as the original restore proposal from `2026-05-04`, not as a currently waiting approval step. Current shipped truth lives in `Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift` and `Hexbound/Hexbound/Views/Components/PvPStatsWidget.swift`.

---

## TL;DR

The widget already exists. We are not designing anything new — we are putting back a component that previously lived on Arena and got displaced.

- Component: **`PvPStatsWidget(.compact, data: vm.character)`**
- File: `Hexbound/Hexbound/Views/Components/PvPStatsWidget.swift`
- Doc comment in source: `/// Single-row compact bar for Arena lobby` (line 51)
- Marker still in `ArenaDetailView.swift:367-369`: `// MARK: - PvP Stats (moved to PvPStatsWidget)` — confirms this lived here historically.
- Already in production use on `HeroStatsTab` and `CharacterProfileView` (in `.full` layout).

## The change (one call site)

`ArenaDetailView.swift` — replace the body of `stancePreview(_ stance:)` (line 373‑381) with the rating widget. The `stancePreview` helper itself can be deleted; rename its call site too.

```diff
- stancePreview(stance)
+ ratingPreview(vm)
```

```swift
@ViewBuilder
private func ratingPreview(_ vm: ArenaViewModel) -> some View {
    if let char = vm.character {
        Button {
            appState.mainPath.append(AppRoute.leaderboard)
        } label: {
            PvPStatsWidget(
                .compact,
                data: char,
                leaderboardRank: vm.leaderboardRank,    // optional, see below
                totalPlayers: vm.totalPlayers           // optional
            )
        }
        .buttonStyle(BrightnessPressStyle())            // existing, no scale animation
        .padding(.horizontal, LayoutConstants.screenPadding)
    }
}
```

What the user sees: rating (1082, in tier color) │ W / L │ win rate % │ streak │ optional `RANK #N`. Whole card tappable → leaderboard.

## What `PvPStatsWidget(.compact)` already gives us out of the box

- Tier-colored hero rating with `contentTransition(.numericText())` for smooth rating changes after a fight.
- Win/loss with success/danger color split, win rate %, streak with hot‑streak flame.
- Optional `RANK #N` slot — already wired with `if let rank = leaderboardRank`.
- Top tier accent line, ornamental chrome (`RadialGlowBackground`, `surfaceLighting`, `innerBorder`, `cornerBrackets`, `cardShadow`).
- All `DarkFantasyTheme` tokens, no raw colors, no custom font sizes.

## Open question — should `RANK #N` be live in v1?

The `.compact` layout already has a `RANK` slot wired. The only thing missing is **fetching the player's leaderboard position** when entering Arena. Two options:

| Option | Cost | Trade-off |
| --- | --- | --- |
| **(A) Ship without rank** — pass `leaderboardRank: nil`. The `RANK` cell hides automatically. | Zero. | We lose the "position in league" half of the original ask. Tap → leaderboard still answers it. |
| **(B) Add rank to `/api/character/me`** | ~5 LoC backend (`leaderboardRank`, `tierKey`, `division`); same migration we'd already want for the existing client/server tier drift. | Best UX, no extra round-trip, fixes the tier drift drift in `PvPStatsWidget` while we're here. **Recommended.** |
| **(C) Call `LeaderboardService.loadLeaderboard()` in `ArenaViewModel.loadOpponents()`** | One extra GET per Arena entry. | Works without backend changes, but wastes ~1 round-trip and 100 leaderboard rows per visit. |

## Things this change does NOT touch

- `StanceDisplayView` is untouched — still used by the stance editor and other surfaces.
- No new `.swift` files → **`project.pbxproj` is not edited**.
- No new component types → reusability‑first rule respected.
- Figma: needs a 1‑instance swap on the Arena screen (stance instance → existing `PvP Stats / Compact` instance, if it's already on the DS file; otherwise add the instance variant). No new tokens.

## Risks

- **Stance editor entry point disappears from Arena.** Confirm players can still reach the stance editor via Hero or wherever — otherwise we orphan that flow. (Quick grep: Hero tab has stance access? If not, add a small "Stance" pill in the Hero/Combat area as a follow‑up.)
- **Existing tier drift inside `PvPStatsWidget.compact`** — currently uses client‑derived `PvPRank.fromRating(rating)` for the icon/color, not server `tierKey`. Not a new bug introduced by this change, but worth fixing in the same PR if we go with Option B above.

## Original decision branch at proposal time

1. **Option A, B, or C** for the rank slot?
2. **Stance editor** — is there already an entry point elsewhere, or should we add one in this PR?

This section is preserved as the original decision frame. The later shipped Arena restore kept the compact rating widget in this slot, left the optional rank cell unset for now, and retained a smaller dedicated stance CTA so the Arena tutorial anchor and direct stance access did not disappear.
