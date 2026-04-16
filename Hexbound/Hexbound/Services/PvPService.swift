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
                let response: PvPOpponentsResponse = try await APIClient.shared.get(
                    APIEndpoints.pvpOpponents,
                    params: ["character_id": charId]
                )
                return response.opponents
            } catch let apiError as APIError {
                if case .decodingError(let error) = apiError {
                    #if DEBUG
                    print("[PvPService] Failed to decode opponents: \(error)")
                    #endif
                    return []
                }
                if attempt == 0 {
                    try? await Task.sleep(for: .seconds(1))
                    continue
                }
                let msg = apiError.errorDescription ?? "Failed to load opponents"
                appState.showToast(msg, subtitle: "Check connection and try again", type: .error, actionLabel: "Retry") { [weak self] in
                    Task { @MainActor in
                        _ = await self?.getOpponents()
                    }
                }
                return []
            } catch {
                if attempt == 0 {
                    try? await Task.sleep(for: .seconds(1))
                    continue
                }
                let msg = "Failed to load opponents"
                appState.showToast(msg, subtitle: "Check connection and try again", type: .error, actionLabel: "Retry") { [weak self] in
                    Task { @MainActor in
                        _ = await self?.getOpponents()
                    }
                }
                return []
            }
        }
        return []
    }

    // MARK: - Revenge

    func getRevengeList() async -> [RevengeEntry] {
        guard let charId = appState.currentCharacter?.id else { return [] }
        do {
            let response: PvPRevengeListResponse = try await APIClient.shared.get(
                APIEndpoints.pvpRevenge,
                params: ["character_id": charId]
            )
            return response.revengeList
        } catch let apiError as APIError {
            if case .decodingError(let error) = apiError {
                #if DEBUG
                print("[PvPService] Failed to decode revenge list: \(error)")
                #endif
            }
            return []
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
            let response: PvPHistoryResponse = try await APIClient.shared.get(
                APIEndpoints.pvpHistory,
                params: ["character_id": charId]
            )
            return response.history
        } catch let apiError as APIError {
            if case .decodingError(let error) = apiError {
                #if DEBUG
                print("[PvPService] Failed to decode match history: \(error)")
                #endif
            }
            return []
        } catch {
            #if DEBUG
            print("[PvPService] Failed to load match history: \(error)")
            #endif
            return []
        }
    }

}

private struct PvPOpponentsResponse: Decodable {
    let opponents: [Opponent]
}

private struct PvPRevengeListResponse: Decodable {
    let revengeList: [RevengeEntry]
}

private struct PvPHistoryResponse: Decodable {
    let history: [MatchHistory]
}
