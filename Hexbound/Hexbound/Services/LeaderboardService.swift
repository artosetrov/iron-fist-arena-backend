import Foundation

private struct LeaderboardResponse: Codable {
    let rating: [LeaderboardEntry]
    let level: [LeaderboardEntry]
    let gold: [LeaderboardEntry]
}

@MainActor
final class LeaderboardService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadLeaderboard() async -> [String: [LeaderboardEntry]] {
        do {
            let response: LeaderboardResponse = try await APIClient.shared.get(
                APIEndpoints.leaderboard,
                params: ["limit": "100"]
            )
            var result: [String: [LeaderboardEntry]] = [
                "rating": response.rating,
                "level": response.level,
                "gold": response.gold,
            ]
            for key in result.keys {
                guard var entries = result[key] else { continue }
                for i in entries.indices where entries[i].rank == 0 {
                    entries[i].rank = i + 1
                }
                result[key] = entries
            }
            return result
        } catch {
            return [:]
        }
    }

    func searchPlayers(query: String) async throws -> [LeaderboardSearchResult] {
        let response: LeaderboardSearchResponse = try await APIClient.shared.get(
            APIEndpoints.leaderboardSearch,
            params: ["q": query]
        )
        return response.results
    }
}
