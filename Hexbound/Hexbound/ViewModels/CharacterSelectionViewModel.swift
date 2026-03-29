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
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            var decoded: [Character] = []
            for charData in charArray {
                let jsonData = try JSONSerialization.data(withJSONObject: charData)
                if let character = try? decoder.decode(Character.self, from: jsonData) {
                    decoded.append(character)
                }
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
            self.error = "Failed to load heroes"
            isLoading = false
            #if DEBUG
            print("[CharacterSelectionVM] loadCharacters error: \(error)")
            #endif
        }
    }

    // MARK: - Delete Character

    var isDeletingCharacter = false
    var deleteError: String?

    /// Permanently deletes a character. Returns true on success.
    func deleteCharacter(id: String) async -> Bool {
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

    /// Select a character and load game data, then transition to hub.
    func selectAndEnter(
        characterId: String,
        appState: AppState,
        cache: GameDataCache
    ) async {
        guard let character = characters.first(where: { $0.id == characterId }) else { return }

        isLoading = true

        // Set the character on appState
        appState.currentCharacter = character
        appState.userCharacters = characters

        // Load game data for this character
        let initService = GameInitService(appState: appState, cache: cache)
        await initService.loadGameData()

        isLoading = false

        // Transition to game
        appState.currentScreen = .game
    }
}
