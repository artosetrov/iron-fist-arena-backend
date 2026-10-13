import SwiftUI

/// A tier the server placed a rating in.
///
/// This used to be a `String`-backed enum with its own `fromRating` table —
/// six tiers, no divisions, Silver at 1200 — which disagreed with the server's
/// eight-tier ladder on almost every rating in the game. It is now a value
/// produced by `PvPLadder`, and carries no thresholds: construct it with
/// `PvPLadder.current.rank(for: rating)`, never by hand.
///
/// What lives here is presentation only — the symbol and color for a tier key,
/// in one place, so `TierBadge`, the arena pills and the rank-up ceremony
/// cannot drift into three different-looking answers for "gold".
struct PvPRank: Equatable, Hashable {

    /// Canonical lowercase tier key, e.g. `"silver"`. Unknown keys are
    /// rendered with neutral styling rather than dropped, so a tier added on
    /// the server does not require a client release to be legible.
    let key: String

    /// Player-facing tier name authored on the server, e.g. `"Silver"`.
    let displayName: String

    /// Roman-numeral division, or `nil` for tiers that have none.
    let division: String?

    /// Global ladder position, ascending. Bronze III is 0. Used for ordering
    /// and for deciding whether a rating moved up or down.
    let index: Int

    /// `"Silver II"`, `"Master"`, `"Challenger"`.
    var label: String {
        guard let division, !division.isEmpty else { return displayName }
        return "\(displayName) \(division)"
    }

    var icon: String { Self.icon(forTierKey: key) }

    /// Kept so existing call sites can stay `Image(systemName:)` without a
    /// branch. Every tier symbol is an SF Symbol.
    var iconIsSFSymbol: Bool { true }

    var color: Color { DarkFantasyTheme.rankColor(forTierKey: key) }

    /// Placeholder for the impossible case of an empty ladder. Renders as a
    /// neutral badge instead of crashing or showing a wrong tier.
    static let unknown = PvPRank(key: "", displayName: "Unranked", division: nil, index: 0)
}

// MARK: - Styling

extension PvPRank {

    /// SF Symbol for a tier key — the apex theme of each tier.
    ///
    /// Single source for the whole app: `TierBadge` and the inline rank pills
    /// both read this.
    static func icon(forTierKey key: String) -> String {
        // One distinct glyph per tier. `TierBadge` previously drew the same
        // half-filled shield for Bronze and Silver, and the same crown for Gold
        // and Challenger — at the compact size (a 10pt glyph) that left a brown
        // vs grey tint as the only difference between the bottom two tiers, and
        // dressed the top-100 tier as Gold.
        switch key {
        case "bronze":      "shield.fill"
        case "silver":      "shield.lefthalf.filled"
        case "gold":        "crown.fill"
        case "platinum":    "hexagon.fill"
        case "diamond":     "diamond.fill"
        case "master":      "star.fill"
        case "grandmaster": "laurel.leading"
        case "challenger":  "flame.fill"
        default:            "shield.fill"
        }
    }

    /// Recover a tier key from a label like `"Silver II"`.
    ///
    /// Only for the few places that receive a rendered label rather than a
    /// rating — the rank-up ceremony takes its old/new rank as strings. Prefer
    /// passing a `PvPRank` wherever that is possible.
    static func tierKey(fromLabel label: String) -> String {
        label
            .split(separator: " ")
            .first
            .map { $0.lowercased() }
            ?? ""
    }
}
