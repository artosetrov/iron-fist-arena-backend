import Foundation

@MainActor
final class LeaderboardService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadLeaderboard() async -> [String: [LeaderboardEntry]] {
        do {
            let data = try await APIClient.shared.getRaw(
                APIEndpoints.leaderboard,
                params: ["limit": "100"]
            )

            var result: [String: [LeaderboardEntry]] = [:]
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            for key in ["rating", "level", "gold"] {
                if let arr = data[key] as? [[String: Any]] {
                    let jsonData = try JSONSerialization.data(withJSONObject: arr)
                    var entries = try decoder.decode([LeaderboardEntry].self, from: jsonData)
                    // Assign ranks
                    for i in entries.indices {
                        entries[i].rank = i + 1
                    }
                    result[key] = entries
                }
            }
            return result
        } catch {
            return [:]
        }
    }
}
