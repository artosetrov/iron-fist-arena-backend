import SwiftUI

@MainActor @Observable
final class AppearanceEditorViewModel {
    private let appState: AppState
    private let cache: GameDataCache

    var selectedOrigin: CharacterOrigin?
    var selectedGender: CharacterGender = .male
    var selectedSkinKey: String?

    // Avatar navigation (same pattern as onboarding)
    var avatarIndex: Int = 0
    var slideDirection: AvatarSlideDirection = .none
    var diceRotation: Double = 0

    enum AvatarSlideDirection {
        case none, left, right
    }

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
            syncAvatarIndex()
        }
    }

    var character: Character? { appState.currentCharacter }

    // MARK: - Skin Lists

    /// Default (free) skins filtered by origin + gender — shown in thumbnail row & arrows
    var defaultSkins: [AppearanceSkin] {
        allSkins.filter { skin in
            let matchesOrigin = selectedOrigin.map { skin.origin == $0.rawValue } ?? true
            let matchesGender = skin.gender == selectedGender.rawValue
            return matchesOrigin && matchesGender && skin.isDefault
        }.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// All skins for current origin + gender (includes premium) — used for main preview
    var availableSkins: [AppearanceSkin] {
        allSkins.filter { skin in
            let matchesOrigin = selectedOrigin.map { skin.origin == $0.rawValue } ?? true
            let matchesGender = skin.gender == selectedGender.rawValue
            return matchesOrigin && matchesGender
        }.sorted { $0.sortOrder < $1.sortOrder }
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
        hasChanges && selectedOrigin != nil && selectedSkinKey != nil && !isSaving
    }

    var showPremiumSkins: Bool = false

    /// Cost breakdown for save button
    var totalGoldCost: Int {
        var cost = 0
        if originChanged { cost += 100 }
        // Avatar change costs gold (based on skin price, default skins are free)
        if let char = character, selectedSkinKey != char.avatar,
           let skin = selectedSkin {
            cost += skin.priceGold
        }
        return cost
    }

    var costText: String? {
        let cost = totalGoldCost
        return cost > 0 ? "\(cost) gold" : nil
    }

    /// Premium skins for current origin + gender (non-default, purchasable with gems)
    var premiumSkins: [AppearanceSkin] {
        allSkins.filter { skin in
            let matchesOrigin = selectedOrigin.map { skin.origin == $0.rawValue } ?? true
            let matchesGender = skin.gender == selectedGender.rawValue
            return matchesOrigin && matchesGender && !skin.isDefault && skin.priceGems > 0
        }.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Selected Skin

    var selectedSkin: AppearanceSkin? {
        guard let key = selectedSkinKey else { return nil }
        return allSkins.first { $0.skinKey == key }
    }

    // MARK: - Avatar Navigation (same as onboarding)

    func nextAvatar() {
        let skins = defaultSkins
        guard !skins.isEmpty else { return }
        slideDirection = .left
        avatarIndex = (avatarIndex + 1) % skins.count
        selectedSkinKey = skins[avatarIndex].skinKey
    }

    func prevAvatar() {
        let skins = defaultSkins
        guard !skins.isEmpty else { return }
        slideDirection = .right
        avatarIndex = (avatarIndex - 1 + skins.count) % skins.count
        selectedSkinKey = skins[avatarIndex].skinKey
    }

    func selectAvatar(at index: Int) {
        let skins = defaultSkins
        guard index >= 0, index < skins.count else { return }
        slideDirection = .none
        avatarIndex = index
        selectedSkinKey = skins[index].skinKey
    }

    // MARK: - Gender Toggle

    func toggleGender() {
        selectedGender = selectedGender == .male ? .female : .male
        onGenderChanged()
    }

    func onGenderChanged() {
        avatarIndex = 0
        slideDirection = .none
        let valid = defaultSkins
        selectedSkinKey = valid.first?.skinKey
    }

    // MARK: - Race Change

    func selectOrigin(_ origin: CharacterOrigin) {
        selectedOrigin = origin
        avatarIndex = 0
        slideDirection = .none
        let valid = defaultSkins
        selectedSkinKey = valid.first?.skinKey
    }

    // MARK: - Randomize (avatar only, within current race + gender)

    func randomize() {
        let skins = defaultSkins
        guard skins.count > 1 else { return }
        var newIndex: Int
        repeat {
            newIndex = Int.random(in: 0..<skins.count)
        } while newIndex == avatarIndex
        slideDirection = .none
        avatarIndex = newIndex
        selectedSkinKey = skins[newIndex].skinKey
    }

    // MARK: - Fetch Skins from API

    func fetchSkins() async {
        if allSkins.isEmpty { isLoadingSkins = true }
        do {
            let response: AppearancesResponse = try await APIClient.shared.get(APIEndpoints.appearances)
            allSkins = response.skins
            cache.cacheSkins(response.skins)
            isLoadingSkins = false
            syncAvatarIndex()
        } catch {
            isLoadingSkins = false
        }
    }

    // MARK: - Sync Index

    private func syncAvatarIndex() {
        let skins = defaultSkins
        if let key = selectedSkinKey, let idx = skins.firstIndex(where: { $0.skinKey == key }) {
            avatarIndex = idx
        } else {
            avatarIndex = 0
            selectedSkinKey = skins.first?.skinKey
        }
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
                body["gender"] = selectedGender.rawValue
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
