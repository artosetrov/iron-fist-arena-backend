import SwiftUI

private struct NameAvailabilityResponse: Decodable {
    let available: Bool
}

private struct CharacterCreateRequest: Encodable {
    let characterName: String
    let characterClass: String
    let origin: String
    let gender: String
    let avatar: String

    private enum CodingKeys: String, CodingKey {
        case characterName = "character_name"
        case characterClass = "class"
        case origin
        case gender
        case avatar
    }
}

private struct CharacterCreateResponse: Decodable {
    let character: Character

    private enum CodingKeys: String, CodingKey {
        case character
        case data
    }

    private struct NestedCharacterResponse: Decodable {
        let character: Character
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let character = try container.decodeIfPresent(Character.self, forKey: .character) {
            self.character = character
            return
        }

        if let nested = try container.decodeIfPresent(NestedCharacterResponse.self, forKey: .data) {
            self.character = nested.character
            return
        }

        if let character = try? Character(from: decoder) {
            self.character = character
            return
        }

        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath, debugDescription: "Expected character create response")
        )
    }
}

@MainActor @Observable
final class OnboardingViewModel {
    // 3-step wizard: 0 = Class, 1 = Appearance (race + gender + avatar), 2 = Name
    var step = 0
    var selectedClass: CharacterClass?
    var selectedOrigin: CharacterOrigin? = .human
    var selectedGender: CharacterGender = .male
    var selectedSkinKey: String?

    // Appearance step: avatar navigation
    var avatarIndex: Int = 0
    var slideDirection: SlideDirection = .none
    var diceRotation: Double = 0

    enum SlideDirection {
        case none, left, right
    }
    var characterName = ""
    var errorMessage = ""
    var isCreating = false

    // Skins fetched from API
    var allSkins: [AppearanceSkin] = []
    var isLoadingSkins = false

    // Name availability check
    enum NameAvailability: Equatable {
        case idle
        case checking
        case available
        case taken
        case invalid
    }
    var nameAvailability: NameAvailability = .idle
    private var nameCheckTask: Task<Void, Never>?
    private var skinsTask: Task<Void, Never>?
    /// Local cache: lowercased name → (result, timestamp). Entries expire after 30s.
    private var nameCache: [String: (result: NameAvailability, at: Date)] = [:]
    private let nameCacheTTL: TimeInterval = 30

    static let totalSteps = 3

    // MARK: - Step Bar Labels

    var stepLabels: [(number: Int, title: String, subtitle: String?)] {
        [
            (1, "CLASS", selectedClass?.sfName),
            (2, "APPEARANCE", nil),
            (3, "NAME", nil)
        ]
    }

    // MARK: - Can Proceed

    var canProceed: Bool {
        switch step {
        case 0: selectedClass != nil
        case 1: selectedOrigin != nil && selectedSkinKey != nil
        case 2: characterName.count >= 3 && characterName.count <= 16 && isValidName && nameAvailability == .available
        default: false
        }
    }

    // MARK: - Skins

    var availableSkins: [AppearanceSkin] {
        allSkins.filter { skin in
            let matchesOrigin = selectedOrigin.map { skin.origin == $0.rawValue } ?? true
            let matchesGender = skin.gender == selectedGender.rawValue
            return matchesOrigin && matchesGender
        }
    }

    /// Currently selected skin object (for preview)
    var selectedSkin: AppearanceSkin? {
        guard let key = selectedSkinKey else { return nil }
        return allSkins.first { $0.skinKey == key }
    }

    // MARK: - Fetch Skins

    func fetchSkins() {
        skinsTask?.cancel()
        skinsTask = Task {
            isLoadingSkins = true
            do {
                let response: AppearancesResponse = try await APIClient.shared.get(APIEndpoints.appearances)
                guard !Task.isCancelled else { return }
                allSkins = response.skins
                isLoadingSkins = false
                // Auto-select first skin for the default origin (human)
                if selectedSkinKey == nil, selectedOrigin != nil {
                    let valid = availableSkins
                    selectedSkinKey = valid.first?.skinKey
                }
                // Prefetch all skin images into cache so scrolling is instant
                for skin in response.skins {
                    Task {
                        _ = await AssetManager.shared.fetchIfNeeded(key: skin.resolvedImageKey, url: skin.imageUrl)
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                isLoadingSkins = false
            }
        }
    }

    // MARK: - Origin-Only Bonuses (for race selection widget)

    var originBonuses: [(stat: String, value: Int)] {
        guard let origin = selectedOrigin else { return [] }
        let order = ["Strength", "Agility", "Vitality", "Endurance", "Intelligence", "Wisdom", "Luck", "Charisma"]
        let bonuses = originBonusMap(origin)
        return order.compactMap { stat in
            guard let val = bonuses.first(where: { $0.0 == stat })?.1, val != 0 else { return nil }
            return (stat: stat, value: val)
        }
    }

    // MARK: - Combined Bonuses

    var combinedBonuses: [(stat: String, value: Int)] {
        var totals: [String: Int] = [:]

        if let origin = selectedOrigin {
            for (stat, val) in originBonusMap(origin) {
                totals[stat, default: 0] += val
            }
        }

        if let cls = selectedClass {
            for (stat, val) in classBonusMap(cls) {
                totals[stat, default: 0] += val
            }
        }

        let order = ["Strength", "Agility", "Vitality", "Endurance", "Intelligence", "Wisdom", "Luck", "Charisma"]
        return order.compactMap { stat in
            guard let val = totals[stat], val != 0 else { return nil }
            return (stat: stat, value: val)
        }
    }

    var heroSummary: String {
        let parts = [
            selectedGender.displayName,
            selectedOrigin?.displayName,
            selectedClass?.displayName
        ].compactMap { $0 }
        return parts.joined(separator: " ")
    }

    // MARK: - Validation

    private var isValidName: Bool {
        let allowed = CharacterSet.alphanumerics
        return characterName.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    // MARK: - Navigation

    func nextStep() {
        guard canProceed else { return }
        errorMessage = ""
        if step < Self.totalSteps - 1 {
            withAnimation(MotionConstants.smooth) {
                step += 1
            }
        }
    }

    func prevStep() {
        errorMessage = ""
        if step > 0 {
            withAnimation(MotionConstants.smooth) {
                step -= 1
            }
        }
    }

    func onGenderChanged() {
        slideDirection = .none
        let valid = availableSkins
        // Preserve current selection if still valid, otherwise pick first
        if let current = selectedSkinKey, valid.contains(where: { $0.skinKey == current }) {
            avatarIndex = valid.firstIndex(where: { $0.skinKey == current }) ?? 0
        } else {
            avatarIndex = 0
            selectedSkinKey = valid.first?.skinKey
        }
    }

    func onOriginChanged() {
        slideDirection = .none
        let valid = availableSkins
        // Preserve current selection if still valid, otherwise pick first
        if let current = selectedSkinKey, valid.contains(where: { $0.skinKey == current }) {
            avatarIndex = valid.firstIndex(where: { $0.skinKey == current }) ?? 0
        } else {
            avatarIndex = 0
            selectedSkinKey = valid.first?.skinKey
        }
    }

    func toggleGender() {
        selectedGender = selectedGender == .male ? .female : .male
        onGenderChanged()
    }

    func nextAvatar() {
        let skins = availableSkins
        guard !skins.isEmpty else { return }
        slideDirection = .left
        avatarIndex = (avatarIndex + 1) % skins.count
        selectedSkinKey = skins[avatarIndex].skinKey
    }

    func prevAvatar() {
        let skins = availableSkins
        guard !skins.isEmpty else { return }
        slideDirection = .right
        avatarIndex = (avatarIndex - 1 + skins.count) % skins.count
        selectedSkinKey = skins[avatarIndex].skinKey
    }

    func selectAvatar(at index: Int) {
        let skins = availableSkins
        guard index >= 0, index < skins.count else { return }
        slideDirection = .none
        avatarIndex = index
        selectedSkinKey = skins[index].skinKey
    }

    // MARK: - Name Availability Check (debounced + cached)

    /// Check name availability.
    /// - Parameter immediate: Skip debounce delay (use after dice roll — name is already complete).
    func checkNameAvailability(immediate: Bool = false) {
        nameCheckTask?.cancel()

        let name = characterName.trimmingCharacters(in: .whitespaces)
        guard name.count >= 3, isValidName else {
            nameAvailability = name.isEmpty ? .idle : .invalid
            return
        }

        // Return cached result instantly — expires after nameCacheTTL seconds
        if let cached = nameCache[name.lowercased()],
           Date().timeIntervalSince(cached.at) < nameCacheTTL {
            nameAvailability = cached.result
            return
        }

        nameAvailability = .checking

        nameCheckTask = Task {
            // Debounce: wait while user is still typing; skip for immediate calls (dice button)
            if !immediate {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
            }

            do {
                let result: NameAvailabilityResponse = try await APIClient.shared.get(
                    APIEndpoints.checkName,
                    params: ["name": name]
                )
                guard !Task.isCancelled else { return }

                let resolved: NameAvailability = result.available ? .available : .taken
                nameCache[name.lowercased()] = (result: resolved, at: Date())
                nameAvailability = resolved
            } catch {
                guard !Task.isCancelled else { return }
                // On network error, allow proceed (server will validate on create)
                nameAvailability = .available
            }
        }
    }

    // MARK: - Randomize (both genders within current race)

    func randomize() {
        // Pick from ALL default skins of current race — both genders
        let raceSkins = allSkins.filter { skin in
            let matchesOrigin = selectedOrigin.map { skin.origin == $0.rawValue } ?? true
            return matchesOrigin && skin.isDefault
        }
        guard !raceSkins.isEmpty else { return }

        let currentKey = selectedSkinKey
        var pick: AppearanceSkin
        if raceSkins.count == 1 {
            pick = raceSkins[0]
        } else {
            repeat {
                pick = raceSkins.randomElement()!
            } while pick.skinKey == currentKey
        }

        // Switch gender if the picked skin is different gender
        if let newGender = CharacterGender(rawValue: pick.gender), newGender != selectedGender {
            selectedGender = newGender
        }
        // Update avatar index within gender-filtered list (now matches new gender)
        let genderSkins = availableSkins
        avatarIndex = genderSkins.firstIndex(where: { $0.skinKey == pick.skinKey }) ?? 0
        slideDirection = .none
        selectedSkinKey = pick.skinKey
    }

    // MARK: - Random Name Generator

    private let namePrefixes = [
        "Shadow", "Iron", "Storm", "Dark", "Blood", "Flame", "Frost", "Thunder",
        "Night", "Steel", "Stone", "Ash", "Bone", "Wolf", "Raven", "Viper",
        "Grim", "War", "Death", "Doom", "Dread", "Ghost", "Skull", "Thorn"
    ]

    private let nameSuffixes = [
        "blade", "fang", "claw", "bane", "rage", "fury", "strike", "heart",
        "slayer", "hunter", "walker", "born", "forge", "guard", "axe", "fist",
        "maw", "fire", "tooth", "scale", "howl", "wind", "shade", "helm"
    ]

    func generateRandomName() {
        let prefix = namePrefixes.randomElement() ?? "Iron"
        let suffix = nameSuffixes.randomElement() ?? "fist"
        characterName = prefix + suffix
    }

    // MARK: - Select Class by Index

    func selectClass(at index: Int) {
        let classes = CharacterClass.allCases
        guard index >= 0, index < classes.count else { return }
        withAnimation(MotionConstants.snappy) {
            selectedClass = classes[index]
        }
    }

    var selectedClassIndex: Int {
        guard let cls = selectedClass else { return 0 }
        return CharacterClass.allCases.firstIndex(of: cls) ?? 0
    }

    func selectPreviousClass() {
        let classes = CharacterClass.allCases
        let current = selectedClassIndex
        let newIndex = (current - 1 + classes.count) % classes.count
        selectClass(at: newIndex)
    }

    func selectNextClass() {
        let classes = CharacterClass.allCases
        let current = selectedClassIndex
        let newIndex = (current + 1) % classes.count
        selectClass(at: newIndex)
    }

    // MARK: - Create Character

    func createCharacter(appState: AppState, cache: GameDataCache) async {
        guard !isCreating else { return } // prevent double-tap
        let gender = selectedGender
        guard let charClass = selectedClass,
              let origin = selectedOrigin,
              let skinKey = selectedSkinKey,
              characterName.count >= 3 else {
            errorMessage = "Please complete all steps"
            return
        }

        isCreating = true
        errorMessage = ""

        // BUG-08: Raise the root-level "Forging Your Hero..." overlay BEFORE
        // the API call. It stays up across the subsequent `currentScreen`
        // cross-fade, covering the window during which the destination view
        // (OnboardingCinematicView / CharacterSelectionView) is synchronously
        // decoding its backdrop assets. Cleared after a short settle delay
        // once the destination screen has had time to paint its first frame.
        appState.isForgingHero = true

        defer {
            // Whatever happens — success, parse fallback, or thrown error —
            // never leave the VM stuck in the "creating" state, and never
            // leave the root overlay stranded if an exception bypasses the
            // explicit success path below.
            isCreating = false
        }

        do {
            let body = CharacterCreateRequest(
                characterName: characterName,
                characterClass: charClass.rawValue,
                origin: origin.rawValue,
                gender: gender.rawValue,
                avatar: skinKey
            )

            let result: CharacterCreateResponse = try await APIClient.shared.post(
                APIEndpoints.characters,
                body: body
            )

            let character = result.character

            appState.currentCharacter = character
            appState.userCharacters.append(character)
            if !allSkins.isEmpty {
                cache.cacheSkins(allSkins)
            }
            // 2026-04-10 — scripted tutorial tunnel disabled (was broken).
            // Skip cinematicOpen → scriptedTutorial → tutorialVictory, go straight to loreIntro.
            // First hero flow is now:
            //   loreIntro → game
            // Additional heroes skip the whole onboarding tunnel as before.
            if appState.userCharacters.count <= 1 {
                // First hero — straight to lore cinematic, skipping the broken tutorial fight
                appState.currentScreen = .loreIntro(heroName: character.characterName)
            } else {
                // Additional hero — go to selection screen
                appState.currentScreen = .characterSelect
            }
            appState.authPath = NavigationPath()

            // BUG-08: give the destination view ~350 ms to mount + paint its
            // first frame under the overlay. 300 ms matches the currentScreen
            // cross-fade; the extra ~50 ms buys one frame of decode headroom
            // on older devices. Overlay fades out cleanly over its own
            // `.animation(.easeInOut(duration: 0.3), value: isForgingHero)`
            // binding in HexboundApp.
            try? await Task.sleep(for: .milliseconds(350))
            appState.isForgingHero = false
        } catch {
            // Drop the overlay so the user can see the error message we're
            // about to set on the onboarding form.
            appState.isForgingHero = false
            if let apiError = error as? APIError {
                errorMessage = apiError.localizedDescription
            } else {
                errorMessage = "Failed to create character"
            }
        }
    }

    // MARK: - Bonus Maps

    private func originBonusMap(_ origin: CharacterOrigin) -> [(String, Int)] {
        switch origin {
        case .human:    [("Charisma", 2), ("Luck", 1)]
        case .orc:      [("Strength", 3), ("Charisma", -1)]
        case .skeleton: [("Endurance", 2), ("Intelligence", 1)]
        case .demon:    [("Intelligence", 2), ("Strength", 1)]
        case .dogfolk:  [("Agility", 2), ("Wisdom", 1)]
        }
    }

    private func classBonusMap(_ cls: CharacterClass) -> [(String, Int)] {
        switch cls {
        case .warrior: [("Strength", 3), ("Vitality", 2)]
        case .rogue:   [("Agility", 3), ("Luck", 2)]
        case .mage:    [("Intelligence", 3), ("Wisdom", 2)]
        case .tank:    [("Vitality", 3), ("Endurance", 2)]
        }
    }
}
