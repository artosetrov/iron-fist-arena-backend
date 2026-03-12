import SwiftUI

@MainActor @Observable
final class AppearanceEditorViewModel {
    private let appState: AppState
    private let cache: GameDataCache

    var selectedOrigin: CharacterOrigin?
    var selectedGender: CharacterGender?
    var selectedSkinKey: String?
    var selectedSkinIndex: Int = 0

    var allSkins: [AppearanceSkin] = []
    var isLoadingSkins = false

    var isSaving = false
    var errorMessage = ""
    var didSave = false

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        if let char = appState.currentCharacter {
            selectedOrigin = char.origin
            selectedGender = char.gender ?? .male
            selectedSkinKey = char.avatar
        }
        // Serve cached skins instantly
        if !cache.skins.isEmpty {
            allSkins = cache.skins
            syncSkinIndex()
        }
    }

    var character: Character? { appState.currentCharacter }

    // MARK: - Skin Lists

    /// All skins for current gender — used for arrow navigation (not filtered by race)
    var browsableSkins: [AppearanceSkin] {
        allSkins
            .filter { skin in selectedGender.map { skin.gender == $0.rawValue } ?? true }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Skins filtered by both origin + gender (kept for backward compat)
    var availableSkins: [AppearanceSkin] {
        browsableSkins.filter { skin in
            selectedOrigin.map { skin.origin == $0.rawValue } ?? true
        }
    }

    // MARK: - Derived State

    var originChanged: Bool {
        guard let char = character else { return false }
        return selectedOrigin != char.origin
    }

    var hasChanges: Bool {
        guard let char = character else { return false }
        return selectedOrigin != char.origin
            || selectedGender != (char.gender ?? .male)
            || selectedSkinKey != char.avatar
    }

    var canSave: Bool {
        hasChanges && selectedOrigin != nil && selectedGender != nil && selectedSkinKey != nil && !isSaving
    }

    var costText: String? {
        originChanged ? "100 gold" : nil
    }

    /// Total browsable skins count (for counter display)
    var totalBrowsableCount: Int { browsableSkins.count }

    // MARK: - Selected Skin

    /// The currently selected skin object (uses browsableSkins for navigation)
    var selectedSkin: AppearanceSkin? {
        let skins = browsableSkins
        guard !skins.isEmpty else { return nil }
        let idx = max(0, min(selectedSkinIndex, skins.count - 1))
        return skins[idx]
    }

    // MARK: - Arrow Navigation (browses ALL skins of current gender)

    func selectNextSkin() {
        let skins = browsableSkins
        guard !skins.isEmpty else { return }
        selectedSkinIndex = (selectedSkinIndex + 1) % skins.count
        applySkinAtIndex(skins: skins)
    }

    func selectPreviousSkin() {
        let skins = browsableSkins
        guard !skins.isEmpty else { return }
        selectedSkinIndex = (selectedSkinIndex - 1 + skins.count) % skins.count
        applySkinAtIndex(skins: skins)
    }

    /// Apply the skin at current index — updates skinKey AND origin to match
    private func applySkinAtIndex(skins: [AppearanceSkin]) {
        let skin = skins[selectedSkinIndex]
        selectedSkinKey = skin.skinKey
        // Auto-update race to match the current skin
        if let origin = CharacterOrigin(rawValue: skin.origin) {
            selectedOrigin = origin
        }
    }

    // MARK: - Race Portrait Tap (jumps to first skin of that race)

    func jumpToOrigin(_ origin: CharacterOrigin) {
        selectedOrigin = origin
        let skins = browsableSkins
        if let idx = skins.firstIndex(where: { $0.origin == origin.rawValue }) {
            selectedSkinIndex = idx
            selectedSkinKey = skins[idx].skinKey
        }
    }

    // MARK: - Fetch Skins from API

    func fetchSkins() async {
        if allSkins.isEmpty { isLoadingSkins = true }
        do {
            let response: AppearancesResponse = try await APIClient.shared.get(APIEndpoints.appearances)
            allSkins = response.skins
            cache.cacheSkins(response.skins)
            isLoadingSkins = false
            syncSkinIndex()
        } catch {
            isLoadingSkins = false
        }
    }

    // MARK: - Gender Changed

    func onGenderChanged() {
        syncSkinIndex()
    }

    // MARK: - Sync Index

    /// Sync index within browsableSkins after gender change or initial load
    private func syncSkinIndex() {
        let skins = browsableSkins
        if let key = selectedSkinKey, let idx = skins.firstIndex(where: { $0.skinKey == key }) {
            selectedSkinIndex = idx
        } else if let origin = selectedOrigin, let idx = skins.firstIndex(where: { $0.origin == origin.rawValue }) {
            selectedSkinIndex = idx
            selectedSkinKey = skins[idx].skinKey
        } else {
            selectedSkinIndex = 0
            selectedSkinKey = skins.first?.skinKey
            if let first = skins.first, let o = CharacterOrigin(rawValue: first.origin) {
                selectedOrigin = o
            }
        }
    }

    // MARK: - Randomize

    func randomize() {
        let randomGender = CharacterGender.allCases.randomElement() ?? .male
        selectedGender = randomGender

        let skins = allSkins.filter { $0.gender == randomGender.rawValue }
        guard let randomSkin = skins.randomElement() else { return }

        selectedSkinKey = randomSkin.skinKey
        if let origin = CharacterOrigin(rawValue: randomSkin.origin) {
            selectedOrigin = origin
        }
        syncSkinIndex()
    }

    // MARK: - Save

    func save() async {
        guard canSave, let char = character else { return }

        isSaving = true
        errorMessage = ""

        do {
            var body: [String: Any] = [:]
            if selectedOrigin != char.origin {
                body["origin"] = selectedOrigin?.rawValue
            }
            if selectedGender != (char.gender ?? .male) {
                body["gender"] = selectedGender?.rawValue
            }
            if selectedSkinKey != char.avatar {
                body["avatar"] = selectedSkinKey
            }

            let result = try await APIClient.shared.patchRaw(
                APIEndpoints.changeAppearance(char.id),
                body: body
            )

            if let charData = result["character"] as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: charData)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let updated = try decoder.decode(Character.self, from: jsonData)

                appState.currentCharacter = updated
                isSaving = false
                didSave = true
            } else {
                isSaving = false
            }
        } catch {
            isSaving = false
            if let apiError = error as? APIError {
                errorMessage = apiError.localizedDescription
            } else {
                errorMessage = "Failed to update appearance"
            }
        }
    }
}
