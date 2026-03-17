import Foundation

/// Calls /api/game/init and populates AppState + GameDataCache with all hub data.
/// Replaces 5+ individual API calls the client would otherwise make on startup.
@MainActor
final class GameInitService {
    private let appState: AppState
    private let cache: GameDataCache

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
    }

    /// Load all game data in a single request.
    /// Falls back to individual CharacterService if game/init fails.
    func loadGameData() async {
        guard let charId = appState.currentCharacter?.id else { return }

        do {
            let response = try await APIClient.shared.getRaw(
                APIEndpoints.gameInit,
                params: ["character_id": charId]
            )

            // Parse character
            if let charDict = response["character"] as? [String: Any] {
                let charDecoder = JSONDecoder()
                charDecoder.keyDecodingStrategy = .convertFromSnakeCase
                if let charData = try? JSONSerialization.data(withJSONObject: charDict),
                   let character = try? charDecoder.decode(Character.self, from: charData) {
                    appState.currentCharacter = character
                }
            }

            // Parse user (gems live on User, not Character)
            if let userDict = response["user"] as? [String: Any] {
                appState.currentUser = userDict
                if let gems = userDict["gems"] as? Int {
                    appState.currentCharacter?.gems = gems
                }
            }

            // Parse inventory — same flattening as InventoryService
            if let equipment = response["equipment"] as? [[String: Any]] {
                let flattened = flattenEquipmentItems(equipment)
                let itemDecoder = JSONDecoder()
                itemDecoder.keyDecodingStrategy = .convertFromSnakeCase
                if let jsonData = try? JSONSerialization.data(withJSONObject: flattened),
                   let items = try? itemDecoder.decode([Item].self, from: jsonData) {
                    appState.cachedInventory = items
                }
            }

            // Parse quests
            if let quests = response["quests"] as? [[String: Any]] {
                appState.cachedQuests = quests
                let questDecoder = JSONDecoder()
                if let questData = try? JSONSerialization.data(withJSONObject: quests),
                   let typedQuests = try? questDecoder.decode([Quest].self, from: questData) {
                    appState.cachedTypedQuests = typedQuests
                }
            }

            // Parse daily login
            if let dailyLogin = response["dailyLogin"] as? [String: Any] {
                appState.cachedDailyLogin = dailyLogin
            }

            // Parse game config
            if let config = response["config"] as? [String: Any] {
                cache.gameConfig = GameConfig(from: config)
            }

            // Parse feature flags (resolved server-side)
            if let flags = response["featureFlags"] as? [String: Any] {
                cache.cacheFeatureFlags(flags)
            }

            // Calculate server time delta for client-side stamina calculation
            if let serverTimeStr = response["serverTime"] as? String {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let serverDate = formatter.date(from: serverTimeStr) {
                    cache.serverTimeDelta = Date().timeIntervalSince(serverDate)
                }
            }

            cache.isInitLoaded = true

            // Load skins catalog (fire-and-forget, non-blocking)
            if cache.skins.isEmpty {
                await loadSkins()
            }
        } catch {
            #if DEBUG
            print("[GameInitService] game/init failed: \(error). Falling back to individual loads.")
            #endif
            // Fallback — load character individually
            let charService = CharacterService(appState: appState)
            await charService.loadCharacter()
        }
    }

    // MARK: - Skins Loader

    private func loadSkins() async {
        do {
            let response: AppearancesResponse = try await APIClient.shared.get(APIEndpoints.appearances)
            cache.cacheSkins(response.skins)
        } catch {
            // Non-critical — avatar images will show placeholder
        }
    }

    // MARK: - Helpers

    /// Same flattening as InventoryService — merges nested item fields into parent.
    private func flattenEquipmentItems(_ items: [[String: Any]]) -> [[String: Any]] {
        items.map { entry in
            var flat = entry
            if let nested = entry["item"] as? [String: Any] {
                for (key, value) in nested {
                    if key == "id" { continue }
                    flat[key] = value
                }
            }
            flat.removeValue(forKey: "item")
            return flat
        }
    }
}
