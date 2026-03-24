import SwiftUI

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

    func fetchSkins() async {
        isLoadingSkins = true
        do {
            let response: AppearancesResponse = try await APIClient.shared.get(APIEndpoints.appearances)
            allSkins = response.skins
            isLoadingSkins = false
            // Auto-select first skin for the default origin (human)
            if selectedSkinKey == nil, selectedOrigin != nil {
                let valid = availableSkins
                selectedSkinKey = valid.first?.skinKey
            }
        } catch {
            isLoadingSkins = false
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
            withAnimation(.easeInOut(duration: 0.3)) {
                step += 1
            }
        }
    }

    func prevStep() {
        errorMessage = ""
        if step > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                step -= 1
            }
        }
    }

    func onGenderChanged() {
        avatarIndex = 0
        slideDirection = .none
        let valid = availableSkins
        selectedSkinKey = valid.first?.skinKey
    }

    func onOriginChanged() {
        avatarIndex = 0
        slideDirection = .none
        let valid = availableSkins
        selectedSkinKey = valid.first?.skinKey
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

    // MARK: - Name Availability Check (debounced)

    func checkNameAvailability() {
        nameCheckTask?.cancel()

        let name = characterName.trimmingCharacters(in: .whitespaces)
        guard name.count >= 3, isValidName else {
            nameAvailability = name.isEmpty ? .idle : .invalid
            return
        }

        nameAvailability = .checking

        nameCheckTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            do {
                let result = try await APIClient.shared.getRaw(
                    "\(APIEndpoints.checkName)?name=\(name)"
                )
                guard !Task.isCancelled else { return }

                let available = result["available"] as? Bool ?? false
                nameAvailability = available ? .available : .taken
            } catch {
                guard !Task.isCancelled else { return }
                // On error, allow proceed (server will validate on create)
                nameAvailability = .available
            }
        }
    }

    // MARK: - Randomize (only gender + avatar within current race)

    func randomize() {
        let skins = availableSkins
        guard skins.count > 1 else { return }
        var newIndex: Int
        repeat {
            newIndex = Int.random(in: 0..<skins.count)
        } while newIndex == avatarIndex
        slideDirection = .none
        avatarIndex = newIndex
        selectedSkinKey = skins[newIndex].skinKey
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
        withAnimation(.easeInOut(duration: 0.2)) {
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

        do {
            let body: [String: Any] = [
                "character_name": characterName,
                "class": charClass.rawValue,
                "origin": origin.rawValue,
                "gender": gender.rawValue,
                "avatar": skinKey
            ]

            let result = try await APIClient.shared.postRaw(
                APIEndpoints.characters,
                body: body
            )

            var charData: [String: Any]?
            if let nested = result["character"] as? [String: Any] {
                charData = nested
            } else if let nested = result["data"] as? [String: Any],
                      let inner = nested["character"] as? [String: Any] {
                charData = inner
            } else if result["id"] != nil {
                charData = result
            }

            if let charData {
                let jsonData = try JSONSerialization.data(withJSONObject: charData)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let character = try decoder.decode(Character.self, from: jsonData)

                appState.currentCharacter = character
                appState.userCharacters.append(character)
                if !allSkins.isEmpty {
                    cache.cacheSkins(allSkins)
                }
                // If this is the user's first hero, go straight to game
                // Otherwise, go back to character selection
                if appState.userCharacters.count <= 1 {
                    // First hero — load game data and enter
                    let initService = GameInitService(appState: appState, cache: cache)
                    await initService.loadGameData()
                    appState.currentScreen = .game
                } else {
                    // Additional hero — go to selection screen
                    appState.currentScreen = .characterSelect
                }
                appState.authPath = NavigationPath()
            } else {
                if !allSkins.isEmpty {
                    cache.cacheSkins(allSkins)
                }
                // Fallback — go to character selection
                appState.currentScreen = .characterSelect
                appState.authPath = NavigationPath()
            }
        } catch {
            isCreating = false
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
