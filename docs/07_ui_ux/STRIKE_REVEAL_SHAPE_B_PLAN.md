# Strike Reveal — Shape B Implementation Plan

Status: Partial implementation snapshot · 2026-04-17 · Phases 1-2 are live in code; phases 3-4 remain proposal
Owner: iOS Combat surface
Prototype: `prototypes/strike-reveal-integration.html`

## Reality check

This plan is no longer a pure pre-code proposal.

Already live in the app:

- Phase 1 core verdict wiring:
  - `Hexbound/Hexbound/Models/RoundVerdict.swift`
  - `RoundExchange.verdict`
  - `CombatVerdictFlash` mounted in `InteractiveBattleView`
- Phase 2 verdict header:
  - `RoundVerdictHeader` mounted at the top of `InteractiveRoundLogCard`

Still proposal-only:

- Phase 3 clash strip row
- Phase 4 portrait winner/loser treatment and peak amp

Treat this document as a mixed implementation record plus remaining design plan, not as an "approval before any code exists" artifact.

## TL;DR

Augment the existing `InteractiveRoundLogCard` with four new elements — a verdict band, a clash-chip strip, a screen-level verdict flash, and portrait winner/loser states — so that each resolved round explicitly frames the rock-paper-scissors read outcome. Ship in four phases. No backend changes required. No scale animations anywhere (per `feedback_no_scale_animations`). All new tokens use `DarkFantasyTheme`.

## Goals and non-goals

Goals — the shipped behavior must satisfy each of these before Phase 5 is considered:

1. Every resolved round exposes a single-word verdict (`OUTPLAYED` / `STRUCK` / `HELD` / `OUTREAD`) that reads correctly from the player's perspective regardless of who attacked whom.
2. Correct reads feel distinct from wrong reads without words — color (gold vs red), card glow (on vs off), and portrait opacity do the work even with the screen muted.
3. `OUTPLAYED` peak feels noticeably more rewarding than `HELD`, and `OUTREAD` feels noticeably worse than `STRUCK`, without extending the 1.4 s reveal window on middle outcomes.
4. All existing behaviors survive: log-row stagger, tap-to-skip, auto-dismiss countdown, active-fire banner, consumable banner, HP tween, VFX particles.
5. Classifier is a pure function of `InteractiveStrikeResponse` fields that already exist — no backend field additions for v1.

Non-goals for this plan (can revisit in Phase 5):

- Full-stage "peak overlay" (Shape C) for OUTPLAYED / OUTREAD.
- Haptic feedback design — separate spec.
- Sound design for verdict band — will reuse existing `SFXManager` cues where possible.
- Verdict distribution telemetry — separate analytics PR.

## Why Shape B

- Additive change. The reveal slot (`InteractiveBattleView.swift` line 465–481) already swaps the picker for `InteractiveRoundLogCard` via ZStack. We add rows *inside* that card and one overlay *outside* it. Nothing currently on screen gets removed.
- Phase-able. Each of the four phases is a standalone PR with its own revert path. Phase 1 is pure data work.
- Backend stable. The five fields we need (`playerStrike.damage`, `opponentStrike?.damage`, `selectedAttackZone`, `selectedDefendZone`, `oppZones.*`) are all present in `InteractiveStrikeResponse`.

Alternatives rejected:
- Shape A (modal-replace the log card) — deletes the `CombatLogRow` stagger that players already read; high regression risk.
- Shape C (hybrid peak overlay) — doubles QA surface and `ActiveFireBanner` / `ConsumableFireBanner` stacking risk; deferred to Phase 5 pending telemetry.

## Architecture summary

```
InteractiveBattleView (root)
├─ ... existing tree ...
├─ ZStack (reveal slot)
│   └─ InteractiveRoundLogCard(exchange:)    ← existing
│       ├─ RoundVerdictHeader (NEW, Phase 2)
│       ├─ ClashStripRow       (NEW, Phase 3)
│       ├─ header              ← existing ROUND N / EXCHANGE
│       ├─ logList              ← existing log rows
│       └─ footer               ← existing countdown
├─ ... existing ...
└─ CombatVerdictFlash (NEW, Phase 1, top z-layer)
```

Data additions:

```
RoundVerdict enum (new file Models/RoundVerdict.swift)
RoundExchange gains `verdict: RoundVerdict` field
InteractiveBattleViewModel gains `currentVerdict` computed (read-through)
DuelFighterCard gains `outcomeRole: OutcomeRole?` parameter (winner / loser / nil)
```

Classifier lives at `RoundExchange.build(...)` next to the existing `InteractiveStrikeOutcome.classify(...)` call. The verdict is derived; the backend stays server-authoritative for damage and crit/dodge — we only classify the *framing*.

## Data model

### RoundVerdict enum

New file: `Hexbound/Hexbound/Models/RoundVerdict.swift`

```swift
//
//  RoundVerdict.swift
//  Hexbound
//
//  Player-perspective round classification derived from server strike data.
//  This is presentation-only — the backend remains authoritative for damage,
//  crit, dodge, and match state. The verdict drives the reveal card framing:
//  verdict band color, clash-chip glow, portrait winner/loser shadow, and
//  the screen-level flash overlay.
//

import Foundation

/// The four RPS read outcomes, always from the local player's perspective.
/// Names are chosen to be readable in the reveal banner; internal raw strings
/// stay snake-cased for analytics compatibility.
enum RoundVerdict: String, Sendable, Equatable, CaseIterable {

    /// You landed a clean hit AND their attack was absorbed (blocked/dodge/miss).
    /// Emotional peak — reserved gold treatment.
    case outplayed

    /// You landed a clean hit AND they also landed on you. Aggressive exchange.
    /// Net HP result may still favor you, but the read was imperfect.
    case struck

    /// Neither landed — mutual block / dodge. Calm, defensive-positive.
    case held

    /// Their attack landed clean AND yours was absorbed. Read-loss peak.
    case outread

    /// User-facing banner text (ALL CAPS).
    var bannerText: String {
        switch self {
        case .outplayed: return "OUTPLAYED"
        case .struck:    return "STRUCK THROUGH"
        case .held:      return "HELD THE LINE"
        case .outread:   return "OUTREAD"
        }
    }

    /// Whether this is a "peak" verdict that warrants extra polish (gold pulse,
    /// gold border, extended portrait treatment). Used by Phase 4 peak amp.
    var isPeak: Bool {
        self == .outplayed || self == .outread
    }

    /// Pure classifier. All inputs come from server-authoritative
    /// `InteractiveStrikeResponse` fields. A nil opponent strike (match ended
    /// on the player's hit) is treated as "their attack didn't land".
    static func classify(
        playerStrike: InteractiveStrikeTurn,
        opponentStrike: InteractiveStrikeTurn?
    ) -> RoundVerdict {
        let youHit  = didLand(playerStrike)
        let theyHit = opponentStrike.map { didLand($0) } ?? false

        switch (youHit, theyHit) {
        case (true,  false): return .outplayed
        case (true,  true):  return .struck
        case (false, false): return .held
        case (false, true):  return .outread
        }
    }

    private static func didLand(_ turn: InteractiveStrikeTurn) -> Bool {
        if turn.isMiss  == true { return false }
        if turn.isDodge == true { return false }
        return turn.damage > 0
    }
}
```

Lines of code estimate: ~60.

### RoundExchange field addition

`Hexbound/Hexbound/Models/RoundExchange.swift`

```
+ let verdict: RoundVerdict
```

In `RoundExchange.build(from:...)` (line 56 of RoundExchange.swift), after the existing ally/enemy arrays are built and before the `return RoundExchange(...)`:

```swift
let verdict = RoundVerdict.classify(
    playerStrike: response.playerStrike,
    opponentStrike: response.opponentStrike
)
```

Add `verdict: verdict` to the `RoundExchange(...)` initializer call. Update the `#Preview` in `InteractiveRoundLogCard.swift` line 180 to pass `verdict: .outplayed` (see Phase 2 for the preview shape).

### DuelFighterCard parameter

`Hexbound/Hexbound/Views/Combat/InteractiveCombatComponents.swift` (grep for `DuelFighterCard`)

Add an optional role parameter:

```swift
enum OutcomeRole: Sendable, Equatable { case winner, loser }

// in DuelFighterCard:
var outcomeRole: OutcomeRole? = nil  // default nil preserves existing call sites
```

Existing call sites in `InteractiveBattleView.swift` remain unchanged until Phase 3.

## Phase-by-phase plan

Each phase is a single PR. Phase N does not depend on Phase N+1 except where noted. Each phase is behind nothing — no feature flag — because the reveal surface is internal and the classifier cannot regress existing behavior (it's additive data).

### Phase 1 — Classifier + Screen Verdict Flash

**Ships:** `RoundVerdict` enum, verdict computed in `RoundExchange.build(...)`, screen-level `CombatVerdictFlash` overlay that fires at the start of `.reveal` with a color tinted by verdict. The log card itself is unchanged — players still see exactly what they see today, plus a subtle radial flash behind the card.

**Risk level:** Low. Pure addition. Classifier is pure; flash is a new overlay on top of existing z-stack.

**Files created:**

| File | Purpose | LoC est |
|------|---------|--------:|
| `Hexbound/Hexbound/Models/RoundVerdict.swift` | Enum + classifier | ~60 |
| `Hexbound/Hexbound/Views/Combat/VFX/CombatVerdictFlash.swift` | Screen flash overlay | ~110 |

**Files modified:**

| File | Change |
|------|--------|
| `Hexbound/Hexbound/Models/RoundExchange.swift` | Add `verdict: RoundVerdict` field; derive in `build(...)` |
| `Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift` | Add `CombatVerdictFlash` overlay at end of root `ZStack` (after existing VFX) |

**Xcode project:** 2 new files require `project.pbxproj` entries in `PBXBuildFile`, `PBXFileReference`, correct `PBXGroup.children` (`Models` and `Views/Combat/VFX` groups), and `PBXSourcesBuildPhase.files`. Generate IDs via `openssl rand -hex 12` per `feedback_pbxproj_unique_ids`.

**CombatVerdictFlash specification:**

A pure opacity-animated overlay. No scale. Mounted in the root ZStack at a z-level above `CombatVFXOverlay` (line 46 of `InteractiveBattleView.swift`) and above `CombatFXImageOverlay` (line 50), but below any modal layers.

```swift
struct CombatVerdictFlash: View {
    let verdict: RoundVerdict?
    let triggerId: UUID?  // pass exchange.id — changes trigger a new flash

    @State private var opacity: Double = 0

    private var flashColor: Color {
        guard let verdict else { return .clear }
        switch verdict {
        case .outplayed: return DarkFantasyTheme.gold
        case .held:      return DarkFantasyTheme.success
        case .struck:    return DarkFantasyTheme.success.opacity(0.7)
        case .outread:   return DarkFantasyTheme.danger
        }
    }

    private var peakOpacity: Double {
        guard let verdict else { return 0 }
        return verdict.isPeak ? 0.22 : 0.14
    }

    var body: some View {
        RadialGradient(
            colors: [flashColor.opacity(peakOpacity), .clear],
            center: .center,
            startRadius: 0,
            endRadius: 520
        )
        .opacity(opacity)
        .allowsHitTesting(false)
        .task(id: triggerId) {
            guard triggerId != nil, verdict != nil else { return }
            opacity = 0
            withAnimation(.easeOut(duration: 0.22)) { opacity = 1 }
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeOut(duration: 0.48)) { opacity = 0 }
        }
    }
}
```

Total flash lifetime: 700 ms. Peak opacity reached at 220 ms. Fades to 0 by 700 ms. This matches the prototype and leaves the remaining ~700 ms of the 1.4 s reveal window free for HP drain and log-row stagger to read cleanly.

**Design token verification required before Phase 1 ships:**

- `DarkFantasyTheme.gold` — exists per memory `reference_darkfantasytheme_color_tokens`. Verify.
- `DarkFantasyTheme.success` — exists. Verify.
- `DarkFantasyTheme.danger` — exists. Verify.

Open `Hexbound/Hexbound/DesignSystem/DarkFantasyTheme.swift` and grep for each name before writing the enum — do not assume. (Reference memory: `feedback_no_custom_font_sizes` — only static tokens.)

**Acceptance criteria Phase 1:**

1. A round resolving with `OUTPLAYED` produces a visible gold flash at ~220 ms after phase entry to `.reveal`.
2. An `OUTREAD` produces a red flash at the same timing.
3. `HELD` and `STRUCK` produce a dimmer green flash.
4. No visual regressions on the existing log card.
5. Flash does not intercept taps (`allowsHitTesting(false)` present).
6. Running the interactive battle in the simulator 20 rounds produces no state leaks, no over-animation loops, no log card layout shifts.

### Phase 2 — Verdict band at top of log card

**Ships:** A gold-bordered `RoundVerdictHeader` subview inside `InteractiveRoundLogCard` above the existing `header` (`ROUND N · EXCHANGE`). Shows the verdict text with verdict-specific background tint and text color.

**Risk level:** Low-medium. Adds visible UI to a shipped component. Needs SwiftUI layout regression testing across all variants (talent fired, finishing blow, short rounds).

**Files modified:**

| File | Change |
|------|--------|
| `Hexbound/Hexbound/Views/Combat/InteractiveRoundLogCard.swift` | Insert `RoundVerdictHeader(verdict:)` as first child of root `VStack` (line 38) |

**Files created:**

| File | Purpose | LoC est |
|------|---------|--------:|
| Private subview inside `InteractiveRoundLogCard.swift` (no new file) | `RoundVerdictHeader` | ~90 |

Keep `RoundVerdictHeader` as a private struct in the same file — it's specific to this card, not reusable elsewhere. Avoid premature abstraction.

**RoundVerdictHeader specification:**

```swift
private struct RoundVerdictHeader: View {
    let verdict: RoundVerdict
    @State private var pulseOn = false

    var body: some View {
        Text(verdict.bannerText)
            .font(DarkFantasyTheme.cardTitle)   // verify token exists
            .tracking(4)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(background)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(DarkFantasyTheme.border)  // verify
                    .frame(height: 1)
            }
            .task { if verdict == .outplayed { pulseOn = true } }
    }

    @ViewBuilder
    private var background: some View {
        switch verdict {
        case .outplayed:
            LinearGradient(
                colors: [
                    DarkFantasyTheme.gold.opacity(0.26),
                    DarkFantasyTheme.gold.opacity(0.06)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .overlay(
                Rectangle()
                    .fill(DarkFantasyTheme.gold.opacity(pulseOn ? 0.16 : 0.04))
                    .animation(
                        .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                        value: pulseOn
                    )
            )
        case .held, .struck:
            DarkFantasyTheme.success.opacity(0.14)
        case .outread:
            DarkFantasyTheme.danger.opacity(0.16)
        }
    }

    private var textColor: Color {
        switch verdict {
        case .outplayed: return DarkFantasyTheme.gold
        case .held, .struck: return DarkFantasyTheme.success
        case .outread: return DarkFantasyTheme.danger
        }
    }
}
```

**Tokens to verify before writing:**

- `DarkFantasyTheme.cardTitle` — font token
- `DarkFantasyTheme.border` — neutral divider color
- `LayoutConstants.spaceSM` — padding token
- `LayoutConstants.radiusLG` — already used by card

Use Grep on `DarkFantasyTheme.swift` and `LayoutConstants.swift` for each name before adding. Per memory `feedback_no_custom_font_sizes`, no `.font(.system(size: ...))`.

**Integration point:** `InteractiveRoundLogCard.body` at line 38:

```swift
var body: some View {
    VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
        RoundVerdictHeader(verdict: exchange.verdict)   // NEW
        header
        logList
        footer
    }
    .padding(LayoutConstants.spaceMD)
    .background(cardSurface)
    ...
}
```

**Acceptance criteria Phase 2:**

1. Verdict band renders above `ROUND N · EXCHANGE` row.
2. `OUTPLAYED` band pulses gradient opacity (0.04 → 0.16, 1.1 s) without scale.
3. `OUTREAD` band is red-tinted and does not pulse.
4. Card height on `OUTPLAYED + talent-fired` round stays ≤ 320 pt (budget: logList already maxes at 300).
5. No regressions on tap-to-skip (`onTapGesture` on root VStack still calls `onDismiss`).
6. `#Preview` builds and renders all four verdict variants.

**Preview shape:** Add four `#Preview` traits — one per verdict — so design QA can eyeball all states in Xcode canvas without running the app.

### Phase 3 — Clash strip row

**Ships:** A compact `ClashStripRow` inserted between the verdict band and the log list. Shows `YOU: ATK <zone> / DEF <zone>` vs `OPP: ATK <zone> / DEF <zone>` with per-chip glow coding (landed-hit glow vs held-block glow).

**Risk level:** Medium. This is the densest new UI element and it sits above the log rows. Needs careful layout review at small widths (iPhone SE width = 320 pt).

**Files modified:**

| File | Change |
|------|--------|
| `Hexbound/Hexbound/Views/Combat/InteractiveRoundLogCard.swift` | Insert `ClashStripRow(exchange:)` between `RoundVerdictHeader` and `header` |
| `Hexbound/Hexbound/Models/RoundExchange.swift` | Add `playerAttackZone`, `playerDefendZone`, `opponentAttackZone`, `opponentDefendZone` fields (already available at `build(...)` time — just pass through) |

**ClashStripRow specification:**

Two `HStack` sides separated by a `VS` divider. Each side has the actor label (`YOU` / `OPP`) above a pair of chips — `ATK <zone>` and `DEF <zone>`. Chip glow rules:

- Player `ATK` chip glows red-tinted (`DarkFantasyTheme.danger`) if `playerStrike.damage > 0`; neutral gray if blocked.
- Player `DEF` chip glows green-tinted (`DarkFantasyTheme.success`) if `opponentStrike.damage <= 0` or nil (you blocked); neutral if their attack landed.
- Opponent chips inverse of the above.

Data for the chips comes from `RoundExchange` fields we just added — no cross-referencing into the VM.

```swift
private struct ClashStripRow: View {
    let exchange: RoundExchange

    var body: some View {
        HStack(alignment: .center, spacing: LayoutConstants.spaceSM) {
            side(
                label: "YOU",
                atkZone: exchange.playerAttackZone,
                defZone: exchange.playerDefendZone,
                youHit: exchange.verdict == .outplayed || exchange.verdict == .struck,
                youHeld: exchange.verdict == .outplayed || exchange.verdict == .held
            )

            Text("VS")
                .font(DarkFantasyTheme.badge)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            side(
                label: "OPP",
                atkZone: exchange.opponentAttackZone,
                defZone: exchange.opponentDefendZone,
                youHit: !(exchange.verdict == .outplayed || exchange.verdict == .struck),
                youHeld: !(exchange.verdict == .outplayed || exchange.verdict == .held)
            )
        }
        .padding(.vertical, LayoutConstants.spaceXS)
    }

    private func side(label: String,
                      atkZone: InteractiveBodyZone,
                      defZone: InteractiveBodyZone,
                      youHit: Bool,
                      youHeld: Bool) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(label)
                .font(DarkFantasyTheme.badge)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            HStack(spacing: LayoutConstants.space2XS) {
                ZoneChip(kind: .attack, zone: atkZone, glowing: youHit)
                ZoneChip(kind: .defense, zone: defZone, glowing: youHeld)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ZoneChip: View {
    enum Kind { case attack, defense }
    let kind: Kind
    let zone: InteractiveBodyZone
    let glowing: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(kind == .attack ? "ATK" : "DEF")
                .font(DarkFantasyTheme.badge)
                .tracking(1)
            Text(zone.rawValue.uppercased())
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(1.2)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, LayoutConstants.spaceXS)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(borderColor, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgElevated)
                )
        )
        .shadow(color: glowColor, radius: glowing ? 8 : 0, y: 0)
    }

    private var foregroundColor: Color {
        switch kind {
        case .attack:  return DarkFantasyTheme.danger
        case .defense: return DarkFantasyTheme.gold
        }
    }
    private var borderColor: Color {
        switch kind {
        case .attack:  return DarkFantasyTheme.danger.opacity(0.4)
        case .defense: return DarkFantasyTheme.gold.opacity(0.4)
        }
    }
    private var glowColor: Color {
        guard glowing else { return .clear }
        switch kind {
        case .attack:  return DarkFantasyTheme.danger.opacity(0.5)
        case .defense: return DarkFantasyTheme.success.opacity(0.5)
        }
    }
}
```

**Tokens to verify:** `LayoutConstants.spaceXS`, `space2XS`, `radiusSM`, `DarkFantasyTheme.bgElevated`, `DarkFantasyTheme.textTertiary`, `DarkFantasyTheme.buttonLabelCompact`, `DarkFantasyTheme.badge`. Confirm in source.

**Why chips live in `InteractiveRoundLogCard.swift` as private, not as shared components:** per `feedback_reusability_first_rule` reusability is #1. I argue for *deferred* extraction — if Phase 5 ever adds these chips to a spectator view or replay screen, promote `ZoneChip` to `Hexbound/Views/Components/`. Premature hoisting risks over-generalization for a single use site.

**Acceptance criteria Phase 3:**

1. On a 320 pt wide device, both sides + `VS` divider fit without truncation.
2. `OUTPLAYED` renders with player `ATK` glowing red and player `DEF` glowing green.
3. `OUTREAD` inverses — opponent side glows, player chips are cold.
4. Chip glow is pure `shadow(color:radius:)` — no scale animation.
5. No regression in card tap-to-skip.

### Phase 4 — Portrait winner/loser + peak amp

**Ships:** Two things in one PR — (a) `DuelFighterCard` accepts the `outcomeRole` parameter and renders opacity 0.72 on loser / 16 pt gold shadow on winner during the reveal window, and (b) `OUTPLAYED` gets a one-shot card-border tween from `gold-dim` → `gold` → `gold-dim` over 1.2 s.

**Risk level:** Medium. Touches `DuelFighterCard` which is the most-used combat view. Need to verify all call sites of `DuelFighterCard` per `feedback_check_all_callers`.

**Files modified:**

| File | Change |
|------|--------|
| `Hexbound/Hexbound/Views/Combat/InteractiveCombatComponents.swift` | Add `outcomeRole: OutcomeRole?` param to `DuelFighterCard`, default `nil` |
| `Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift` | Pass `outcomeRole:` based on `vm.currentExchange?.verdict` for player and opponent cards |
| `Hexbound/Hexbound/Views/Combat/InteractiveRoundLogCard.swift` | Add `.overlay` border color animation on `OUTPLAYED` |
| `Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift` | Add `playerOutcomeRole`/`opponentOutcomeRole` computed on VM |

**Computed VM properties:**

```swift
// InteractiveBattleViewModel.swift
var playerOutcomeRole: OutcomeRole? {
    guard let verdict = currentExchange?.verdict else { return nil }
    switch verdict {
    case .outplayed: return .winner
    case .outread:   return .loser
    case .struck, .held: return nil  // middle outcomes — no portrait treatment
    }
}

var opponentOutcomeRole: OutcomeRole? {
    guard let verdict = currentExchange?.verdict else { return nil }
    switch verdict {
    case .outplayed: return .loser
    case .outread:   return .winner
    case .struck, .held: return nil
    }
}
```

**DuelFighterCard changes:**

```swift
// pseudocode, exact spec depends on current DuelFighterCard structure
var body: some View {
    existingContent
        .opacity(opacity)
        .shadow(color: shadowColor, radius: shadowRadius, y: 0)
        .animation(.easeOut(duration: 0.4), value: outcomeRole)
}

private var opacity: Double {
    outcomeRole == .loser ? 0.72 : 1.0
}
private var shadowColor: Color {
    outcomeRole == .winner ? DarkFantasyTheme.gold.opacity(0.4) : .clear
}
private var shadowRadius: CGFloat {
    outcomeRole == .winner ? 16 : 0
}
```

**Callers of `DuelFighterCard` to verify before shipping:**

Run `grep -rn "DuelFighterCard(" Hexbound/` and confirm every instance still compiles with the new `outcomeRole:` defaulting to nil. Zero-arg callers keep working. Per `feedback_check_all_callers`.

**Acceptance criteria Phase 4:**

1. `OUTPLAYED` round: player card gets gold shadow, opponent card dims to 0.72, reverts smoothly on next `.predict`.
2. `OUTREAD` round: inverse.
3. Middle outcomes (`STRUCK`, `HELD`) leave both cards at default appearance.
4. `OUTPLAYED` card border tweens gold-dim → gold → gold-dim once per reveal.
5. No regression on any other `DuelFighterCard` call site.

## File touch summary

| File | Phase 1 | Phase 2 | Phase 3 | Phase 4 |
|------|:---:|:---:|:---:|:---:|
| `Models/RoundVerdict.swift` (new) | NEW | — | — | — |
| `Models/RoundExchange.swift` | edit | — | edit | — |
| `Models/InteractiveCombatModels.swift` | — | — | — | — |
| `Views/Combat/VFX/CombatVerdictFlash.swift` (new) | NEW | — | — | — |
| `Views/Combat/InteractiveBattleView.swift` | edit | — | — | edit |
| `Views/Combat/InteractiveBattleViewModel.swift` | — | — | — | edit |
| `Views/Combat/InteractiveRoundLogCard.swift` | — | edit | edit | edit |
| `Views/Combat/InteractiveCombatComponents.swift` | — | — | — | edit |
| `Hexbound.xcodeproj/project.pbxproj` | edit | — | — | — |

pbxproj edits in Phase 1 only. Remaining phases modify files that already exist in the project. Phase 1 adds 2 new files — use `openssl rand -hex 12` for IDs per `feedback_pbxproj_unique_ids`.

## Animation and timing reference

All animations are opacity or box-shadow only. No scale, per `feedback_no_scale_animations`.

| Element | Property | Timing | Curve |
|---------|----------|--------|-------|
| Verdict flash ramp in | opacity 0 → 1 | 220 ms | easeOut |
| Verdict flash hold | opacity 1 | 0 ms | — |
| Verdict flash fade out | opacity 1 → 0 | 480 ms | easeOut |
| `OUTPLAYED` verdict band pulse | opacity 0.04 → 0.16 → 0.04 | 1100 ms, repeatForever | easeInOut |
| `OUTPLAYED` card border color | border `gold-dim` → `gold` → `gold-dim` | 1200 ms | easeInOut |
| Portrait winner shadow fade-in | radius 0 → 16 | 400 ms | easeOut |
| Portrait loser dim | opacity 1.0 → 0.72 | 400 ms | easeOut |
| Clash chip glow | shadow radius 0 → 8 | 280 ms | easeOut |

Total per-round reveal budget stays at the existing `InteractiveBattleViewModel.revealDurationSeconds = 1.4` (line 189). No pacing changes for v1.

## Tokens to confirm before writing code

Per `feedback_figma_ds_tokens_only` and `feedback_no_custom_font_sizes` — no raw hex, no `.font(.system(size:))`. Before each phase, confirm the token name exists in source:

```bash
grep -n "static let gold" Hexbound/Hexbound/DesignSystem/DarkFantasyTheme.swift
grep -n "static let success" Hexbound/Hexbound/DesignSystem/DarkFantasyTheme.swift
grep -n "static let danger" Hexbound/Hexbound/DesignSystem/DarkFantasyTheme.swift
grep -n "static let border" Hexbound/Hexbound/DesignSystem/DarkFantasyTheme.swift
grep -n "cardTitle\|badge\|buttonLabelCompact" Hexbound/Hexbound/DesignSystem/DarkFantasyTheme.swift
grep -n "spaceXS\|space2XS\|spaceSM\|spaceMD\|radiusSM\|radiusLG" Hexbound/Hexbound/DesignSystem/LayoutConstants.swift
```

Any miss here means the plan needs revising before Phase 2 — do not invent token names.

## Test plan

Automated:

- `RoundVerdictTests.swift` (new) — unit tests for `RoundVerdict.classify(...)` covering the 4 × 2 = 8 landing combinations (player hit yes/no × opponent hit yes/no × crit yes/no × dodge yes/no).
- `RoundExchangeTests.swift` (existing? or new) — verify `verdict` field is populated from `build(...)` for a representative `InteractiveStrikeResponse` fixture.

Manual QA (before merge of each phase):

1. **Simulate all 4 verdicts.** Use the admin dev panel or force-feed strike responses in a debug build to produce all four verdicts within one match. Eyeball each.
2. **Short-match OUTPLAYED.** Force a finishing-blow OUTPLAYED on round 1. Ensure verdict band + finishing-blow marker coexist in the header.
3. **Talent-fired OUTPLAYED.** Round with ally active firing + OUTPLAYED. Confirm card height stays within `maxListHeight + 300`, no ScrollView weirdness.
4. **Rapid rounds.** 3 rounds in 10 seconds with tap-to-skip on each. Verify flash does not leak between rounds (`task(id: triggerId)` cancels correctly).
5. **Screenshot diff.** No dedicated `HexboundUI` snapshot-test target is checked in today, so capture screenshots of all 4 verdicts + `OUTPLAYED + crit` + `OUTPLAYED + talent` for visual review instead of relying on a nonexistent snapshot suite.

Playtest gate before Phase 5 consideration:

- 5–10 internal testers play ≥10 ranked matches.
- Post-match survey: "Did the `OUTPLAYED` moment feel rewarding? 1–5."
- Target: mean ≥ 4.0. If < 4.0, evaluate C-peak overlay upgrade.
- Log verdict distribution. If `OUTPLAYED + OUTREAD` > 25% of turns, C-peak overlay is too frequent — stay on Shape B and iterate visual polish instead.

## Rollback

Each phase is a discrete commit and revertable:

- Phase 1 revert: delete 2 new files, remove `CombatVerdictFlash` mount in `InteractiveBattleView`, remove `verdict:` param from `RoundExchange` initializer. Classifier call can stay dead in `RoundExchange.build(...)` — it's pure and harmless.
- Phase 2 revert: remove `RoundVerdictHeader` mount call in `InteractiveRoundLogCard.body`. Private struct can stay dead or be deleted.
- Phase 3 revert: remove `ClashStripRow` mount call. Private structs can stay dead or be deleted.
- Phase 4 revert: default `outcomeRole: nil` everywhere; remove border-color animation modifier from card surface.

No schema changes in any phase — Prisma sync check is a no-op.

## Risks and open questions

1. **Verdict classifier edge case — nil opponent strike.** When the match ends on the player's strike, `response.opponentStrike` is nil. Classifier treats that as "they didn't hit", which produces `OUTPLAYED` or `HELD` depending on whether the player landed. *Is that the right framing for a finishing blow?* My lean: yes — a finishing-blow `OUTPLAYED` is the natural read-win climax. `HELD` as a finisher reads strangely (no damage dealt on the killing turn?) but is only possible in a rare status-tick death case. Flag for review during Phase 1 playtest.
2. **`STRUCK` nomenclature collision.** Current log event `.strike` already exists in `CombatLogEvent.swift`. Using `STRUCK THROUGH` as the banner label avoids direct collision, but we should make sure neither QA nor support copy conflates `STRIKE` (the button) with `STRUCK` (the verdict). Narrative/Lore review before Phase 2.
3. **Stacking with `ActiveFireBanner`.** Both the verdict band and the active-fire banner can surface on the same round. Spec'd order: verdict band is inside the log card (fixed position); active-fire banner floats above the fighter card (existing behavior). They occupy different layers. *But* the log card pulse on `OUTPLAYED` + simultaneous active-fire banner pulse = two simultaneous glow animations in peripheral vision. Need to verify this feels rich rather than noisy in playtest. If noisy, stagger active-fire banner by 200 ms.
4. **Landscape / larger-width devices.** Plan specs chip layout at 320 pt width. iPad sizes unverified. If iPad is in scope, verify clash strip doesn't look empty/stretched at 768 pt.
5. **Localization.** All verdict copy is English. Shape B locks in 4 strings — `OUTPLAYED`, `STRUCK THROUGH`, `HELD THE LINE`, `OUTREAD`. Per `feedback_english_only` we're English-only for now, but if localization lands later, these need to be `String(localized:)` wrapped — cheap to retrofit.

## Out of scope (explicitly)

- SFX per verdict. Deferred. Current SFX fires on strike landing (damage, crit, block); adding a per-verdict sting would be a separate PR and risks audio clutter.
- Haptic feedback. Deferred.
- `OUTPLAYED` full-screen (Shape C peak). Deferred pending playtest data.
- Backend-emitted verdict field (for analytics). Deferred — if we ever want distribution telemetry, expose `verdict` on the client via existing analytics events.
- Verdict on combat replay / history screens. Deferred — `RoundExchange.verdict` is now persistent in the log, so replay could opt in later without new work.

## Estimated effort

- Landed already:
  - Phase 1: classifier + flash + project wiring
  - Phase 2: verdict band inside the reveal card
- Remaining if we continue this direction:
  - Phase 3: ~1 day (clash strip + layout QA across widths)
  - Phase 4: ~1 day (portrait plumbing + caller verification + border animation)

Original full estimate was ~3 days of focused iOS work. As of 2026-04-17, the remaining work is the later half of that plan, plus playtest/review.

## Remaining approval checklist before Phase 3 starts

- [ ] Banner copy approved (`OUTPLAYED` / `STRUCK THROUGH` / `HELD THE LINE` / `OUTREAD`) or alternatives proposed.
- [ ] Design tokens confirmed in source (`DarkFantasyTheme` + `LayoutConstants`).
- [ ] `RoundVerdict` 4-case taxonomy confirmed — no need for a 5th `TRADED` state.
- [ ] Screen-flash z-ordering agreed (above VFX, above FX image, below modals).
- [ ] Finishing-blow + `OUTPLAYED` coexistence approved for Phase 2 header.
- [ ] Playtest gate criteria agreed (wow-rate ≥ 0.7, peak-frequency ≤ 0.25 for C-peak upgrade).
