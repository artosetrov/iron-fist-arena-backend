import Foundation

@MainActor
final class DungeonService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - List Dungeons (Dynamic)

    /// Fetches all active dungeons from the server.
    /// Returns array of dungeon dicts with bosses, or nil on failure.
    func listDungeons() async -> [[String: Any]]? {
        guard let result = try? await APIClient.shared.getRaw(
            APIEndpoints.dungeonsList
        ) else { return nil }
        return result["dungeons"] as? [[String: Any]]
    }

    // MARK: - Dungeon Progress

    func getProgress() async -> [String: Any]? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        return try? await APIClient.shared.getRaw(
            APIEndpoints.dungeons,
            params: ["character_id": charId]
        )
    }

    // MARK: - Start Dungeon

    func start(dungeonId: String, difficulty: String) async -> [String: Any]? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            return try await APIClient.shared.postRaw(
                APIEndpoints.dungeonsStart,
                body: [
                    "character_id": charId,
                    "dungeon_id": dungeonId,
                    "difficulty": difficulty
                ]
            )
        } catch let error as APIError {
            switch error {
            case .clientError(409, _):
                appState.showToast("Active run exists — continue or abandon first", type: .error)
            case .clientError(_, let message):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to enter dungeon", subtitle: "Check connection and try again", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Failed to enter dungeon", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    // MARK: - Fight Room

    func fight(runId: String) async -> [String: Any]? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            return try await APIClient.shared.postRaw(
                APIEndpoints.dungeonsFight,
                body: ["character_id": charId, "run_id": runId]
            )
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Fight failed", subtitle: "Check connection and try again", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Fight failed", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    // MARK: - Dungeon Rush

    func rushStatus() async -> [String: Any]? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        return try? await APIClient.shared.getRaw(
            APIEndpoints.dungeonRushStatus,
            params: ["character_id": charId]
        )
    }

    func rushStart() async -> [String: Any]? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            return try await APIClient.shared.postRaw(
                APIEndpoints.dungeonRushStart,
                body: ["character_id": charId]
            )
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to start rush", subtitle: "Check connection and try again", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Failed to start rush", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    func rushFight(runId: String) async -> [String: Any]? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            return try await APIClient.shared.postRaw(
                APIEndpoints.dungeonRushFight,
                body: ["character_id": charId, "run_id": runId]
            )
        } catch {
            return nil
        }
    }

    func rushAbandon() async {
        guard let charId = appState.currentCharacter?.id else { return }
        _ = try? await APIClient.shared.postRaw(
            APIEndpoints.dungeonRushAbandon,
            body: ["character_id": charId]
        )
    }

    func rushResolve(runId: String, action: String? = nil) async -> [String: Any]? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            var body: [String: Any] = ["character_id": charId, "run_id": runId]
            if let action { body["action"] = action }
            return try await APIClient.shared.postRaw(
                APIEndpoints.dungeonRushResolve,
                body: body
            )
        } catch {
            return nil
        }
    }

    func rushShopBuy(runId: String, slot: Int) async -> [String: Any]? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            return try await APIClient.shared.postRaw(
                APIEndpoints.dungeonRushShopBuy,
                body: ["character_id": charId, "run_id": runId, "slot": slot]
            )
        } catch {
            return nil
        }
    }
}
