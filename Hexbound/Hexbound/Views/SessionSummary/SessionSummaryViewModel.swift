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
