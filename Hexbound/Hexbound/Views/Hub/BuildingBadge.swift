import SwiftUI

/// W2.D5 — Priority + cap-3 system for hub building badges.
///
/// Replaces the old `String?` badge API. Each building now returns a
/// structured `BuildingBadge` that carries text, priority, and a severity
/// tiebreaker used when more than three critical pills compete for attention.
///
/// Why it matters:
///   Before W2.D5 every building that had *anything* to show pasted a gold
///   pill over its label. At Lv8+ the hub looked like a slot machine —
///   Arena "FREE 3", Achievements "4", Battlepass "12", Gold Mine "READY",
///   Guild "7". The player's eye had nowhere to land and the important
///   signals drowned in the noise.
///
/// How it works (per `docs/07_ui_ux/W2_D5_BADGE_PRIORITY_DESIGN.md`):
///   1. `badgeFor(_:)` returns a `BuildingBadge` with `.info` or `.critical`
///      priority, or `BuildingBadge.none` to hide the pill.
///   2. `filteredBadges(_:)` sorts critical badges by severity and keeps the
///      top three. Any critical beyond that is DOWNGRADED to `.info` — we
///      never silently drop a signal, we just lower its volume.
///   3. `CityBuildingLabel` renders `.critical` as a danger-red pulsing pill
///      and `.info` as the existing gold pill.
///
/// Design decisions locked in W2 roadmap:
///   - Arena "FREE N" is `.info` — useful but not urgent.
///   - Achievements / Battlepass / Gold Mine "READY" are `.critical` —
///     each one represents a reward the player can actually claim.
///   - Guild Hall scales by social state: unread messages + incoming
///     challenges → `.critical`; friend requests + revenges → `.info`.
///   - Dungeon badge REMOVED — "X bosses left" is metadata, not action.
enum BadgePriority: Int, Comparable {
    /// Don't show a pill at all.
    case none = 0
    /// Gold, static pill. Informational only.
    case info = 1
    /// Danger-red, pulsing pill. Action required.
    case critical = 2

    static func < (lhs: BadgePriority, rhs: BadgePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A single badge attached to a hub building.
///
/// `severity` is the within-priority tiebreaker used by the cap-3 filter.
/// Higher = more urgent. Guideline:
///   - Critical badges: start at 40+ and scale with count (e.g. claimable × 5).
///   - Info badges:     start at 10+ for light urgency.
///   - .none entries:   severity = 0 (ignored).
struct BuildingBadge: Equatable {
    let text: String
    let priority: BadgePriority
    /// Tiebreaker used when more than 3 critical badges compete.
    /// Higher = keeps critical status; lower = downgraded to info.
    let severity: Int

    /// Singleton for "no badge" — avoids needing `BuildingBadge?` everywhere.
    static let none = BuildingBadge(text: "", priority: .none, severity: 0)

    /// True when this badge should actually render a pill.
    var shouldShow: Bool { priority != .none }

    /// True when this badge should render with the danger-red critical style.
    var isCritical: Bool { priority == .critical }

    // MARK: - Convenience

    static func info(_ text: String, severity: Int = 10) -> BuildingBadge {
        BuildingBadge(text: text, priority: .info, severity: severity)
    }

    static func critical(_ text: String, severity: Int = 40) -> BuildingBadge {
        BuildingBadge(text: text, priority: .critical, severity: severity)
    }

    /// Produce an info copy of this badge — used by the cap-3 downgrade pass.
    func downgradedToInfo() -> BuildingBadge {
        BuildingBadge(text: text, priority: .info, severity: severity)
    }
}

// MARK: - Cap-3 Filter

extension BuildingBadge {
    /// Apply the W2.D5 cap-3 rule to a full building set.
    ///
    /// Algorithm:
    ///   1. Collect the raw badge for each building.
    ///   2. Take all `.critical` badges, sort by severity descending.
    ///   3. Keep the top `limit` (default 3) as `.critical`.
    ///   4. DOWNGRADE the rest to `.info` — their text still shows, but the
    ///      red pulse stops so the player's eye can land somewhere.
    ///   5. `.info` badges pass through untouched. `.none` is filtered out.
    ///
    /// The input is an ordered list of `(buildingId, badge)` pairs so tie
    /// resolution matches the hub's left-to-right scan order.
    static func applyCap(
        _ raw: [(id: String, badge: BuildingBadge)],
        limit: Int = 3
    ) -> [String: BuildingBadge] {
        // Split by priority.
        var criticals: [(id: String, badge: BuildingBadge)] = []
        var infos: [(id: String, badge: BuildingBadge)] = []
        for pair in raw {
            switch pair.badge.priority {
            case .critical: criticals.append(pair)
            case .info:     infos.append(pair)
            case .none:     continue
            }
        }

        // Sort criticals by severity descending. `sorted` is stable, so
        // equal-severity items preserve the input (left-to-right) order.
        criticals.sort { $0.badge.severity > $1.badge.severity }

        // Split at the cap — top N stay critical, the rest downgrade.
        let kept = criticals.prefix(limit)
        let downgraded = criticals.dropFirst(limit).map { pair in
            (id: pair.id, badge: pair.badge.downgradedToInfo())
        }

        // Merge everything back into a dictionary keyed by building id.
        var result: [String: BuildingBadge] = [:]
        for pair in kept        { result[pair.id] = pair.badge }
        for pair in downgraded  { result[pair.id] = pair.badge }
        for pair in infos       { result[pair.id] = pair.badge }
        return result
    }
}
