import Foundation

/// The PvP ladder, as authored by the server.
///
/// Until 2026-09-15 the client classified ratings itself: `PvPRank` held six
/// tiers, no divisions, and thresholds from an earlier balance pass (Silver at
/// 1200). The server had moved to eight tiers × three divisions with Silver at
/// 750 and never told the client. The same account therefore read
/// "Silver II" on the leaderboard — where the server attaches the tier — and
/// "Bronze" on the arena badge one screen away, computed locally from the same
/// number.
///
/// Attaching a resolved tier to every payload that carries a rating would have
/// meant touching a dozen endpoints and their models. The ladder itself is the
/// smaller contract: it arrives once in `/api/game/init` and the client renders
/// from it, holding no thresholds of its own.
///
/// Mirrors `PvPLadderContract` in `backend/src/lib/game/tier.ts`.
struct PvPLadder: Decodable, Equatable {

    struct Tier: Decodable, Equatable {
        /// Canonical, lowercase — the key styling and `TierBadge` switch on.
        let key: String
        /// Player-facing tier name, authored on the server. Never synthesized
        /// here by capitalizing `key`.
        let displayName: String
        /// Inclusive lower bound.
        let ratingStart: Int
        /// Exclusive upper bound; `nil` for the open-ended top tier.
        /// (`Infinity` does not survive JSON, so the server sends `null`.)
        let ratingEnd: Int?
        /// Number of divisions inside this tier. `0` means no division.
        let divisions: Int
    }

    let tiers: [Tier]
    /// Division labels, entry division first: `["III", "II", "I"]`.
    let divisionLabels: [String]
    let challengerKey: String
    let challengerDisplayName: String
    /// The tier Challenger promotes out of. Sent explicitly so the client does
    /// not have to assume "whichever tier happens to be last".
    let challengerPromotesFrom: String
    /// Leaderboard rank at or above which a player in `challengerPromotesFrom`
    /// becomes Challenger.
    let challengerRankCutoff: Int
    let startingRating: Int
}

// MARK: - The live ladder

extension PvPLadder {

    /// Bundled mirror of the frozen W3.D5 ladder in `tier.ts`.
    ///
    /// Used only until the first `/api/game/init` lands: on a cold start the
    /// arena has to draw a badge before the network answers. Everything after
    /// that is server-authored.
    static let fallback = PvPLadder(
        tiers: [
            Tier(key: "bronze",      displayName: "Bronze",      ratingStart: 0,    ratingEnd: 750,  divisions: 3),
            Tier(key: "silver",      displayName: "Silver",      ratingStart: 750,  ratingEnd: 1500, divisions: 3),
            Tier(key: "gold",        displayName: "Gold",        ratingStart: 1500, ratingEnd: 2250, divisions: 3),
            Tier(key: "platinum",    displayName: "Platinum",    ratingStart: 2250, ratingEnd: 3000, divisions: 3),
            Tier(key: "diamond",     displayName: "Diamond",     ratingStart: 3000, ratingEnd: 3750, divisions: 3),
            Tier(key: "master",      displayName: "Master",      ratingStart: 3750, ratingEnd: 4250, divisions: 0),
            Tier(key: "grandmaster", displayName: "Grandmaster", ratingStart: 4250, ratingEnd: nil,  divisions: 0),
        ],
        divisionLabels: ["III", "II", "I"],
        challengerKey: "challenger",
        challengerDisplayName: "Challenger",
        challengerPromotesFrom: "grandmaster",
        challengerRankCutoff: 100,
        startingRating: 1000
    )

    /// The ladder every screen reads.
    ///
    /// A plain static, like `Item.fallbackUpgradeStatBonusPerLevel`, because
    /// the models that need a tier (`Character`, `Opponent`, `Message`,
    /// `Challenge`, `Friend`) are plain structs whose computed properties
    /// cannot reach the main-actor-isolated `GameDataCache`.
    ///
    /// Written once per `/api/game/init`, on the main actor, via `adopt(_:)`.
    static var current: PvPLadder = .fallback

    /// A ladder is only renderable if it starts at 0 and strictly ascends —
    /// otherwise tiers overlap or become unreachable and a division width can
    /// be zero. The server rejects such a ladder too (`resolveTierRanges`);
    /// this is the client refusing to render one that somehow arrives anyway,
    /// rather than drawing a badge from a broken table.
    var isRenderable: Bool {
        let ordered = orderedTiers
        guard let first = ordered.first, first.ratingStart == 0 else { return false }

        let starts = ordered.map(\.ratingStart)
        guard zip(starts, starts.dropFirst()).allSatisfy({ $0 < $1 }) else { return false }

        // Every tier but the last has to end where the next one starts. A gap
        // is worse than an overlap: a rating inside it still selects the tier
        // below (selection reads `ratingStart` only), but that tier's upper
        // bound is now behind the rating, so the progress bar pins at 100% and
        // "rating to next" reads 0 for the whole gap.
        for (index, tier) in ordered.enumerated() {
            let isLast = index == ordered.count - 1
            if isLast {
                if let end = tier.ratingEnd, end <= tier.ratingStart { return false }
            } else if tier.ratingEnd != ordered[index + 1].ratingStart {
                return false
            }
        }

        if ordered.contains(where: { $0.divisions > 0 }) && divisionLabels.isEmpty { return false }
        return true
    }

    /// Adopt a server ladder, or keep the current one if it is unusable.
    @MainActor
    static func adopt(_ ladder: PvPLadder?) {
        guard let ladder, ladder.isRenderable else { return }
        current = ladder
    }

    var orderedTiers: [Tier] {
        tiers.sorted { $0.ratingStart < $1.ratingStart }
    }
}

// MARK: - Classification

extension PvPLadder {

    /// Resolve the tier and division for a rating.
    ///
    /// Mirrors `tierFromRating` in `tier.ts`, including the Challenger rule:
    /// Challenger is a leaderboard-rank cutoff inside the top tier, never a
    /// rating threshold, so it is only reachable where a rank is known.
    func rank(for rating: Int, leaderboardRank: Int? = nil) -> PvPRank {
        let ordered = orderedTiers
        guard !ordered.isEmpty else { return .unknown }

        let safe = max(0, rating)
        var matchIndex = 0
        for (index, tier) in ordered.enumerated() where safe >= tier.ratingStart {
            matchIndex = index
        }
        let tier = ordered[matchIndex]

        if tier.key == challengerPromotesFrom,
           let leaderboardRank, leaderboardRank > 0, leaderboardRank <= challengerRankCutoff {
            return PvPRank(
                key: challengerKey,
                displayName: challengerDisplayName,
                division: nil,
                index: slotOffset(before: ordered.count, in: ordered)
            )
        }

        let division = divisionLabel(in: tier, rating: safe)
        return PvPRank(
            key: tier.key,
            displayName: tier.displayName,
            division: division,
            index: slotOffset(before: matchIndex, in: ordered) + divisionOffset(division, in: tier)
        )
    }

    /// Progress toward the next promotion — the next division inside this
    /// tier, or the next tier when the player is in its top division.
    ///
    /// `nil` at the top of the ladder, where there is nothing to progress to.
    func progress(for rating: Int) -> PvPRankProgress? {
        let ordered = orderedTiers
        guard !ordered.isEmpty else { return nil }

        let safe = max(0, rating)
        var matchIndex = 0
        for (index, tier) in ordered.enumerated() where safe >= tier.ratingStart {
            matchIndex = index
        }
        let tier = ordered[matchIndex]

        // Top tier: open-ended, no promotion left.
        guard matchIndex < ordered.count - 1 || tier.ratingEnd != nil else { return nil }
        guard let end = upperBound(for: tier, in: ordered), end > tier.ratingStart else { return nil }

        let rangeStart: Int
        let rangeEnd: Int

        if tier.divisions > 0 {
            let width = Double(end - tier.ratingStart) / Double(tier.divisions)
            let offset = Double(safe - tier.ratingStart)
            let currentIndex = min(max(Int(floor(offset / width)), 0), tier.divisions - 1)
            rangeStart = Int(floor(Double(tier.ratingStart) + Double(currentIndex) * width))
            // Rounded up for the same reason the server rounds up: ratings are
            // integers, and a tier width that does not divide evenly puts the
            // true boundary mid-integer.
            rangeEnd = Int(ceil(Double(tier.ratingStart) + Double(currentIndex + 1) * width))
        } else {
            rangeStart = tier.ratingStart
            rangeEnd = end
        }

        guard rangeEnd > rangeStart else { return nil }

        return PvPRankProgress(
            rating: safe,
            current: rank(for: safe),
            next: rank(for: rangeEnd),
            rangeStart: rangeStart,
            rangeEnd: rangeEnd
        )
    }

    // MARK: Internals

    private func upperBound(for tier: Tier, in ordered: [Tier]) -> Int? {
        if let end = tier.ratingEnd { return end }
        guard let index = ordered.firstIndex(where: { $0.key == tier.key }),
              index + 1 < ordered.count else { return nil }
        return ordered[index + 1].ratingStart
    }

    private func divisionLabel(in tier: Tier, rating: Int) -> String? {
        guard tier.divisions > 0, !divisionLabels.isEmpty else { return nil }
        let ordered = orderedTiers
        guard let end = upperBound(for: tier, in: ordered), end > tier.ratingStart else {
            return divisionLabels.first
        }
        let width = Double(end - tier.ratingStart) / Double(tier.divisions)
        let raw = Int(floor(Double(rating - tier.ratingStart) / width))
        let ceiling = min(tier.divisions, divisionLabels.count) - 1
        return divisionLabels[min(max(raw, 0), max(ceiling, 0))]
    }

    /// Sort slots consumed by the tiers below `index` — one per division, or
    /// one for a tier without divisions. Mirrors `globalTierIndex`.
    private func slotOffset(before index: Int, in ordered: [Tier]) -> Int {
        ordered.prefix(index).reduce(0) { $0 + max(1, $1.divisions) }
    }

    private func divisionOffset(_ division: String?, in tier: Tier) -> Int {
        guard let division, let offset = divisionLabels.firstIndex(of: division) else { return 0 }
        return min(offset, max(tier.divisions - 1, 0))
    }
}

// MARK: - Progress

/// Where a rating sits between its current promotion threshold and the next.
struct PvPRankProgress: Equatable {
    let rating: Int
    let current: PvPRank
    let next: PvPRank
    /// Rating at which `current` was reached.
    let rangeStart: Int
    /// Rating at which `next` begins.
    let rangeEnd: Int

    var fraction: Double {
        let span = Double(rangeEnd - rangeStart)
        guard span > 0 else { return 0 }
        return min(max(Double(rating - rangeStart) / span, 0), 1)
    }

    var ratingToNext: Int { max(0, rangeEnd - rating) }
}
