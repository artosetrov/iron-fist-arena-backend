import SwiftUI

@MainActor @Observable
final class CharacterSelectionViewModel {
    var characters: [Character] = []
    var selectedCharacterId: String?
    var isLoading = true
    var error: String?

    var selectedCharacter: Character? {
        characters.first { $0.id == selectedCharacterId }
    }

    var slotsUsed: Int { characters.count }
    var slotsLeft: Int { max(0, 5 - slotsUsed) }
    var canCreateNewHero: Bool { slotsLeft > 0 }

    // MARK: - Load Characters

    func loadCharacters(appState: AppState? = nil) async {
        isLoading = true
        error = nil

        do {
            let result = try await APIClient.shared.getRaw(APIEndpoints.characters)

            var charArray: [[String: Any]] = []
            if let characters = result["characters"] as? [[String: Any]] {
                charArray = characters
            } else if let data = result["data"] as? [[String: Any]] {
                charArray = data
            } else if result["id"] != nil {
                // Single character returned directly
                charArray = [result]
            } else if let errMessage = result["error"] as? String {
                // Backend returned an error envelope
                throw NSError(
                    domain: "CharacterSelection",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Server: \(errMessage)"]
                )
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            var decoded: [Character] = []
            var decodeErrors: [String] = []
            for charData in charArray {
                let jsonData = try JSONSerialization.data(withJSONObject: charData)
                do {
                    let character = try decoder.decode(Character.self, from: jsonData)
                    decoded.append(character)
                } catch {
                    let name = (charData["characterName"] as? String)
                        ?? (charData["character_name"] as? String)
                        ?? (charData["id"] as? String)
                        ?? "unknown"
                    decodeErrors.append("\(name): \(error.localizedDescription)")
                    #if DEBUG
                    print("[CharacterSelectionVM] decode failed for \(name): \(error)")
                    #endif
                }
            }

            // If backend returned characters but NONE decoded — surface that as an error
            // (instead of silently showing empty state).
            if !charArray.isEmpty && decoded.isEmpty {
                let detail = decodeErrors.first ?? "unknown decode error"
                throw NSError(
                    domain: "CharacterSelection",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Decode failed (\(charArray.count) heroes): \(detail)"]
                )
            }

            // Sort by level descending (highest level first)
            characters = decoded.sorted { $0.level > $1.level }

            // Auto-select: prefer just-created character, fall back to first
            if selectedCharacterId == nil {
                if let justCreated = appState?.currentCharacter?.id,
                   characters.contains(where: { $0.id == justCreated }) {
                    selectedCharacterId = justCreated
                } else {
                    selectedCharacterId = characters.first?.id
                }
            }

            isLoading = false
        } catch {
            // User-facing copy is generic; DEBUG builds get the underlying reason
            // so we can actually see what's wrong in the next run.
            #if DEBUG
            self.error = "Failed to load heroes\n\(error.localizedDescription)"
            print("[CharacterSelectionVM] loadCharacters error: \(error)")
            #else
            self.error = "Failed to load heroes"
            #endif
            isLoading = false
        }
    }

    // MARK: - Delete Character

    var isDeletingCharacter = false
    var deleteError: String?

    /// Permanently deletes a character. Returns true on success.
    func deleteCharacter(id: String) async -> Bool {
        guard !isDeletingCharacter else { return false } // prevent double-tap
        isDeletingCharacter = true
        deleteError = nil

        do {
            try await APIClient.shared.delete(APIEndpoints.character(id))
            // Remove from local list immediately
            characters.removeAll { $0.id == id }
            // If deleted hero was selected, auto-select first remaining
            if selectedCharacterId == id {
                selectedCharacterId = characters.first?.id
            }
            isDeletingCharacter = false
            return true
        } catch {
            deleteError = "Failed to delete hero"
            isDeletingCharacter = false
            return false
        }
    }

    /// Select a character and transition to hub.
    ///
    /// Phase 2 (2026-04-13, M-2): instant shell UI. Previously we awaited
    /// `GameInitService.loadGameData()` before switching screens, which
    /// blocked the Hub transition for 800-1500ms on cold start. Now we
    /// switch screens immediately and load game data in the background —
    /// HubView renders its frame + cached data instantly and @Observable
    /// re-renders each section as fresh data arrives.
    func selectAndEnter(
        characterId: String,
        appState: AppState,
        cache: GameDataCache
    ) async {
        guard let character = characters.first(where: { $0.id == characterId }) else { return }

        // Set the character on appState
        appState.currentCharacter = character
        appState.userCharacters = characters

        // Transition to game IMMEDIATELY — Hub renders with cached/empty
        // data, then fills in as loadGameData completes.
        appState.currentScreen = .game

        // Load game data in background. Fire-and-forget — HubView's own
        // .task hooks (prefetchOpponents, etc.) will still run; init data
        // (inventory/quests/config) populates the cache as it arrives.
        Task { [appState, cache] in
            let initService = GameInitService(appState: appState, cache: cache)
            await initService.loadGameData()
        }
    }
}
