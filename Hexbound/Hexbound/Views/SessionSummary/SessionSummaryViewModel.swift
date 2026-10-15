import SwiftUI

struct SessionSummaryData: Codable {
    let matchesPlayed: Int
    let wins: Int
    let losses: Int
    let goldEarned: Int
    let xpEarned: Int
    let ratingChange: Int
    let itemsGained: Int
    let questsCompleted: Int
    let questsTotal: Int
    // Added 2026-10-15 (Victory Ledger). Optional so an older backend still decodes.
    /// "W"/"L" per fight, oldest first.
    let results: [String]?
    let rating: SessionRating?
    let quests: [SessionQuest]?
    let loot: [SessionLoot]?

    /// Headline for the session, from the score alone.
    var verdict: String {
        if matchesPlayed == 0 { return "NO BATTLES YET" }
        if losses == 0 { return "UNDEFEATED" }
        if wins == 0 { return "BLOODIED" }
        if wins > losses { return "VICTORIOUS" }
        if wins == losses { return "EVEN BLADES" }
        return "HARD-FOUGHT"
    }
}

struct SessionRating: Codable, Equatable {
    let current: Int
    let tierKey: String
    let division: String?
    let label: String
    let nextLabel: String?
    let pointsToNext: Int?
    /// 0…1 inside the current division.
    let progress: Double
}

struct SessionQuest: Codable, Identifiable, Equatable {
    var id: String { type }
    let type: String
    let title: String
    let progress: Int
    let target: Int
    /// Progress reached the target.
    let done: Bool
    /// Reward already collected.
    let claimed: Bool
}

struct SessionLoot: Codable, Equatable {
    let name: String
    let rarity: String
    let imageKey: String?

    var rarityColor: Color {
        (ItemRarity(rawValue: rarity) ?? .common).color
    }
}

struct SessionSummaryResponse: Codable {
    let session: SessionSummaryData
}

@MainActor @Observable
final class SessionSummaryViewModel {
    var summary: SessionSummaryData?
    var isLoading = false
    var errorMessage: String?

    /// A failed load is an error state, not "no session data" — the two were
    /// indistinguishable before 2026-10-14, both rendering one grey line.
    var showsErrorState: Bool { errorMessage != nil && summary == nil }

    private let characterId: String

    init(characterId: String) {
        self.characterId = characterId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: SessionSummaryResponse = try await APIClient.shared.get(
                APIEndpoints.sessionSummary,
                params: ["character_id": characterId]
            )
            summary = response.session
        } catch {
            errorMessage = (error as? APIError)?.userMessage
                ?? "Couldn't load your session. Check your connection and try again."
        }
        isLoading = false
    }
}
