//
//  CombatUXState.swift
//  Hexbound
//
//  Interactive Combat v2 — 3-state UX mapping layer.
//
//  The VM's `Phase` enum (`intro`/`predict`/`resolving`/`reveal`/`summary`/
//  `completing`/`finished`/`unavailable`/`error`) is a BACKEND contract and
//  is never renamed — it maps 1:1 to the `/pvp/match/start` → `/pvp/strike` →
//  `/pvp/match/complete` lifecycle.
//
//  `CombatUXState` is the PRESENTATION contract the V2 view tree consumes.
//  Three visual states — CHOOSE (interactive decision), RESOLVE (read-only
//  damage + verdict), END (rewards + stats + Continue) — plus a few transient
//  passthrough states for intro / completing / error / unavailable that the
//  V1 view also had to handle.
//
//  Rationale for the split: combat surfaces eleven overlapping UI contexts
//  on one frame in V1 (see COMBAT_UX_REFACTOR_3_STATE.md §2 M1–M11). The
//  V2 layout treats each UX state as its OWN screen so the player never has
//  to re-parse mid-animation. See §3.1 of the architecture doc for the
//  phase→UX state mapping table.
//

import Foundation

/// Presentation-layer state for `InteractiveBattleV2View`. Derived purely
/// from the VM's current `Phase` + the existence of `currentExchange` —
/// this type OWNS no new server state and cannot disagree with the VM.
///
/// Transition rules (copied verbatim from refactor doc §3.1):
///   Phase.intro                               → .intro
///   Phase.predict           && exchange==nil  → .choose
///   Phase.resolving         && exchange==nil  → .choose   (lock state — server round-tripping)
///   Phase.resolving/.reveal && exchange!=nil  → .resolve
///   Phase.reveal            && exchange==nil  → .resolve  (degraded / no-card path)
///   Phase.summary                              → .end
///   Phase.completing                           → .end     (loader overlay)
///   Phase.finished                             → .end     (rewards populated)
///   Phase.unavailable                          → .unavailable
///   Phase.error                                → .error
///
/// The `locked: Bool` associate on `.choose` tells the view to dim + disable
/// the pickers while the round-trip is in flight. This is the ONE moment the
/// CHOOSE screen is not fully interactive; we keep it on the CHOOSE screen
/// rather than flipping to RESOLVE because the exchange card hasn't landed
/// yet and flashing through an empty RESOLVE state would read as a flicker.
enum CombatUXState: Equatable {
    case intro
    case choose(locked: Bool)
    case resolve
    case end
    case unavailable
    case error(message: String)
}

extension InteractiveBattleViewModel {
    /// Derived 3-state UX presentation state. Safe to read any time —
    /// pure function of `phase` + `currentExchange`.
    var uxState: CombatUXState {
        switch phase {
        case .intro:
            return .intro
        case .predict:
            return .choose(locked: false)
        case .resolving:
            // Picker stays mounted but locked while the server resolves.
            // If the exchange payload has already landed (fast network),
            // cut straight to RESOLVE so the transition doesn't stutter.
            return currentExchange == nil ? .choose(locked: true) : .resolve
        case .reveal:
            return currentExchange == nil ? .resolve : .resolve
        case .summary, .completing:
            return .end
        case .finished:
            return .end
        case .unavailable:
            return .unavailable
        case .error(let message):
            return .error(message: message)
        }
    }

    /// Whether the STRIKE CTA should be enabled on the CHOOSE screen.
    /// V2 requirement: both zones must be ACTIVELY picked this round —
    /// the default `.chest` doesn't count. Matches prototype §§4.1–4.2.
    var canSubmitStrike: Bool {
        guard case .predict = phase else { return false }
        return attackTouched && defendTouched
    }

    /// Whether the RESOLVE screen should render the "finishing blow"
    /// freeze-frame ceremony instead of a normal damage card.
    /// True only on the round the match actually ends.
    var isFinishingBlow: Bool {
        state.isFinished && currentExchange != nil
    }

    /// One-line phase identity for `.animation(_, value:)` bindings in V2.
    /// Mirrors the private `phaseKey` helper in `InteractiveBattleView`.
    var uxStateKey: String {
        switch uxState {
        case .intro:                return "intro"
        case .choose(let locked):   return "choose:\(locked)"
        case .resolve:              return "resolve"
        case .end:                  return "end"
        case .unavailable:          return "unavailable"
        case .error(let msg):       return "error:\(msg)"
        }
    }
}
