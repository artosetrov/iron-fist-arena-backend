import Foundation

@MainActor
final class PvPService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Get Opponents

    func getOpponents() async -> [Opponent] {
        guard let charId = appState.currentCharacter?.id else { return [] }

        // Retry once on failure (handles Vercel cold starts)
        for attempt in 0..<2 {
            do {
                let response = try await APIClient.shared.getRaw(
                    APIEndpoints.pvpOpponents,
                    params: ["character_id": charId]
                )
                guard let opponentsArray = response["opponents"] as? [[String: Any]] else { return [] }
                let jsonData = try JSONSerialization.data(withJSONObject: opponentsArray)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                do {
                    return try decoder.decode([Opponent].self, from: jsonData)
                } catch {
                    #if DEBUG
                    print("[PvPService] Failed to decode opponents: \(error)")
                    #endif
                    return []
                }
            } catch {
                if attempt == 0 {
                    try? await Task.sleep(for: .seconds(1))
                    continue
                }
                let msg = (error as? APIError)?.errorDescription ?? "Failed to load opponents"
                appState.showToast(msg, subtitle: msg == "Failed to load opponents" ? "Pull to refresh or try later" : "", type: .error)
                return []
            }
        }
        return []
    }

    // MARK: - Revenge

    func getRevengeList() async -> [RevengeEntry] {
        guard let charId = appState.currentCharacter?.id else { return [] }
        do {
            let response = try await APIClient.shared.getRaw(
                APIEndpoints.pvpRevenge,
                params: ["character_id": charId]
            )
            guard let revengeArray = response["revenge_list"] as? [[String: Any]] else { return [] }
            let jsonData = try JSONSerialization.data(withJSONObject: revengeArray)
            let decoder = JSONDecoder()
            do {
                return try decoder.decode([RevengeEntry].self, from: jsonData)
            } catch {
                #if DEBUG
                print("[PvPService] Failed to decode revenge list: \(error)")
                #endif
                return []
            }
        } catch {
            #if DEBUG
            print("[PvPService] Failed to load revenge list: \(error)")
            #endif
            return []
        }
    }

    // MARK: - Match History

    func getHistory() async -> [MatchHistory] {
        guard let charId = appState.currentCharacter?.id else { return [] }
        do {
            let response = try await APIClient.shared.getRaw(
                APIEndpoints.pvpHistory,
                params: ["character_id": charId]
            )
            guard let historyArray = response["history"] as? [[String: Any]] else { return [] }
            let jsonData = try JSONSerialization.data(withJSONObject: historyArray)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                return try decoder.decode([MatchHistory].self, from: jsonData)
            } catch {
                #if DEBUG
                print("[PvPService] Failed to decode match history: \(error)")
                #endif
                return []
            }
        } catch {
            #if DEBUG
            print("[PvPService] Failed to load match history: \(error)")
            #endif
            return []
        }
    }

}
