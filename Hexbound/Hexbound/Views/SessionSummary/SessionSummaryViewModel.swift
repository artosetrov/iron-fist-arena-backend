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
    var error: String?

    private let characterId: String

    init(characterId: String) {
        self.characterId = characterId
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            let response: SessionSummaryResponse = try await APIClient.shared.get(
                "/api/session-summary",
                params: ["character_id": characterId]
            )
            summary = response.session
        } catch {
            self.error = "Failed to load session summary"
        }
        isLoading = false
    }
}
