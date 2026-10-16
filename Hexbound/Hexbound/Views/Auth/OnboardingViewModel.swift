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

// MARK: - Creation options (GET /api/characters/creation-options)

/// Starting-stat rules as the server applies them. Fetched so the Forge Stage
/// never advertises a bonus the server doesn't grant (2026-10-16: class
/// bonuses became real on the server; origin numbers on the client had drifted).
struct CreationOptions: Decodable {
    struct ClassOption: Decodable {
        let bonus: [String: Int]
        let mainStat: String
    }

    let baseStat: Int
    let origins: [String: [String: Int]]
    let classes: [String: ClassOption]

    /// Mirror of backend/src/lib/game/creation-stats.ts — used until (or if)
    /// the request fails. Keep in sync with the server file.
    static let fallback = CreationOptions(
        baseStat: 10,
        origins: [
            "human": ["cha": 2, "wis": 1],
            "orc": ["str": 3, "int": -1],
            "skeleton": ["end": 2, "agi": 1],
            "demon": ["int": 2, "wis": 2, "cha": -1],
            "dogfolk": ["agi": 2, "luk": 1],
        ],
        classes: [
            "warrior": .init(bonus: ["str": 3, "vit": 2], mainStat: "str"),
            "rogue": .init(bonus: ["agi": 3, "luk": 2], mainStat: "agi"),
            "mage": .init(bonus: ["int": 3, "wis": 2], mainStat: "int"),
            "tank": .init(bonus: ["vit": 3, "end": 2], mainStat: "vit"),
        ]
    )
}

/// One stat change shown as a chip ("Strength +3").
struct StatBonus: Identifiable, Equatable {
    let key: String
    let value: Int
    var id: String { key }
    var label: String { ForgeStat.name(key) }
}

/// Stat key helpers shared by the Forge Stage views.
enum ForgeStat {
    static let order = ["str", "agi", "vit", "end", "int", "wis", "luk", "cha"]

    static func name(_ key: String) -> String {
        switch key {
        case "str": "Strength"
        case "agi": "Agility"
        case "vit": "Vitality"
        case "end": "Endurance"
        case "int": "Intellect"
        case "wis": "Wisdom"
        case "luk": "Luck"
        case "cha": "Charisma"
        default: key.uppercased()
        }
    }

    static func value(_ key: String, of character: Character) -> Int? {
        switch key {
        case "str": character.strength
        case "agi": character.agility
        case "vit": character.vitality
        case "end": character.endurance
        case "int": character.intelligence
        case "wis": character.wisdom
        case "luk": character.luck
        case "cha": character.charisma
        default: nil
        }
    }
}

@MainActor @Observable
final class OnboardingViewModel {
    // Forge Stage: 0 = Origin (race + gender + look), 1 = Class, 2 = Name.
    // Then the in-view ceremony: forging → reveal.
    var step = 0
    var selectedClass: CharacterClass? = .warrior
    var selectedOrigin: CharacterOrigin? = .human
    var selectedGender: CharacterGender = .male
    var selectedSkinKey: String?

    enum Phase: Equatable {
        case editing
        case forging
        case revealed
    }
    var phase: Phase = .editing
    /// The hero returned by the server — the reveal shows its real stats.
    var createdCharacter: Character?

    var avatarIndex: Int = 0
    var characterName = ""
    var errorMessage = ""
    var isCreating = false

    // Skins fetched from API
    var allSkins: [AppearanceSkin] = []
    var isLoadingSkins = false

    // Server starting-stat rules
    var options: CreationOptions = .fallback
    private var optionsTask: Task<Void, Never>?

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

    /// Minimum time the forging ceremony stays on screen, even if the
    /// server answers instantly — the anvil needs a moment.
    static let minForgeDuration: Duration = .milliseconds(2600)
    static let totalSteps = 3

    // MARK: - Can Proceed

    var canProceed: Bool {
        switch step {
        case 0: selectedOrigin != nil && selectedSkinKey != nil
        case 1: selectedClass != nil
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

    /// Currently selected skin object (portrait on the stage)
    var selectedSkin: AppearanceSkin? {
        guard let key = selectedSkinKey else { return nil }
        return allSkins.first { $0.skinKey == key }
    }

    var lookLabel: String {
        let count = availableSkins.count
        guard count > 1 else { return "" }
        return "Look \(avatarIndex + 1) of \(count)"
    }

    func fetchSkins() {
        skinsTask?.cancel()
        skinsTask = Task {
            isLoadingSkins = true
            do {
                let response: AppearancesResponse = try await APIClient.shared.get(APIEndpoints.appearances)
                guard !Task.isCancelled else { return }
                allSkins = response.skins
                isLoadingSkins = false
                if selectedSkinKey == nil, selectedOrigin != nil {
                    selectedSkinKey = availableSkins.first?.skinKey
                }
                // Prefetch all skin images into cache so switching looks is instant
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

    // MARK: - Creation options

    func fetchCreationOptions() {
        optionsTask?.cancel()
        optionsTask = Task {
            do {
                let fetched: CreationOptions = try await APIClient.shared.get(APIEndpoints.creationOptions)
                guard !Task.isCancelled else { return }
                options = fetched
            } catch {
                // Keep the bundled fallback (same numbers as the server file).
            }
        }
    }

    var originBonuses: [StatBonus] {
        guard let origin = selectedOrigin else { return [] }
        return bonusList(options.origins[origin.rawValue] ?? [:])
    }

    var classBonuses: [StatBonus] {
        guard let cls = selectedClass else { return [] }
        return bonusList(options.classes[cls.rawValue]?.bonus ?? [:])
    }

    var mainStatKey: String {
        guard let cls = selectedClass else { return "str" }
        return options.classes[cls.rawValue]?.mainStat ?? "str"
    }

    private func bonusList(_ map: [String: Int]) -> [StatBonus] {
        ForgeStat.order.compactMap { key in
            guard let value = map[key], value != 0 else { return nil }
            return StatBonus(key: key, value: value)
        }
    }

    /// Accent of the stage: gold while choosing origin, class colour after.
    var accentColor: Color {
        guard step >= 1 || phase != .editing, let cls = selectedClass else { return DarkFantasyTheme.gold }
        return DarkFantasyTheme.classColor(for: cls)
    }

    var heroLine: String {
        [selectedGender.displayName, selectedOrigin?.displayName]
            .compactMap { $0 }
            .joined(separator: " ")
            .uppercased()
    }

    var stageTitle: String {
        switch step {
        case 0: return (selectedOrigin?.displayName ?? "Hero").uppercased()
        case 1: return (selectedClass?.displayName ?? "Hero").uppercased()
        default:
            let trimmed = characterName.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? (selectedClass?.displayName ?? "Hero").uppercased() : trimmed.uppercased()
        }
    }

    var displayName: String {
        let trimmed = characterName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "HERO" : trimmed.uppercased()
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

    func selectOrigin(_ origin: CharacterOrigin) {
        guard selectedOrigin != origin else { return }
        selectedOrigin = origin
        reconcileSkin()
    }

    func selectGender(_ gender: CharacterGender) {
        guard selectedGender != gender else { return }
        selectedGender = gender
        reconcileSkin()
    }

    /// Keep the current look if it still matches race + gender, else pick the first.
    private func reconcileSkin() {
        let valid = availableSkins
        if let current = selectedSkinKey, let index = valid.firstIndex(where: { $0.skinKey == current }) {
            avatarIndex = index
        } else {
            avatarIndex = 0
            selectedSkinKey = valid.first?.skinKey
        }
    }

    func nextLook() {
        let skins = availableSkins
        guard !skins.isEmpty else { return }
        avatarIndex = (avatarIndex + 1) % skins.count
        selectedSkinKey = skins[avatarIndex].skinKey
    }

    func prevLook() {
        let skins = availableSkins
        guard !skins.isEmpty else { return }
        avatarIndex = (avatarIndex - 1 + skins.count) % skins.count
        selectedSkinKey = skins[avatarIndex].skinKey
    }

    // MARK: - Name Availability Check (debounced + cached)

    /// - Parameter immediate: Skip debounce delay (use after dice roll — name is already complete).
    func checkNameAvailability(immediate: Bool = false) {
        nameCheckTask?.cancel()

        let name = characterName.trimmingCharacters(in: .whitespaces)
        guard name.count >= 3, isValidName else {
            nameAvailability = name.isEmpty ? .idle : .invalid
            return
        }

        if let cached = nameCache[name.lowercased()],
           Date().timeIntervalSince(cached.at) < nameCacheTTL {
            nameAvailability = cached.result
            return
        }

        nameAvailability = .checking

        nameCheckTask = Task {
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

    // MARK: - Randomize

    /// Dice in the top bar: a whole random hero (race, gender, look, class —
    /// and a name when already on the name step).
    func randomizeHero() {
        let origin = CharacterOrigin.allCases.randomElement() ?? .human
        let gender: CharacterGender = Bool.random() ? .male : .female
        selectedOrigin = origin
        selectedGender = gender
        let skins = availableSkins
        if !skins.isEmpty {
            avatarIndex = Int.random(in: 0..<skins.count)
            selectedSkinKey = skins[avatarIndex].skinKey
        } else {
            reconcileSkin()
        }
        selectedClass = CharacterClass.allCases.randomElement() ?? .warrior
        if step == 2 {
            generateRandomName()
            checkNameAvailability(immediate: true)
        }
    }

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

    // MARK: - Forge (create on server + ceremony)

    func forge() async {
        guard !isCreating, canProceed else { return }
        let gender = selectedGender
        guard let charClass = selectedClass,
              let origin = selectedOrigin,
              let skinKey = selectedSkinKey else {
            errorMessage = "Please complete all steps"
            return
        }

        isCreating = true
        errorMessage = ""
        withAnimation(MotionConstants.smooth) { phase = .forging }
        let started = ContinuousClock.now
        defer { isCreating = false }

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

            let elapsed = ContinuousClock.now - started
            if elapsed < Self.minForgeDuration {
                try? await Task.sleep(for: Self.minForgeDuration - elapsed)
            }
            createdCharacter = result.character
            SFXManager.shared.play(.uiLevelUp)
            withAnimation(MotionConstants.smooth) { phase = .revealed }
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.localizedDescription
            } else {
                errorMessage = "Failed to create character"
            }
            SFXManager.shared.play(.uiError)
            withAnimation(MotionConstants.smooth) { phase = .editing }
        }
    }

    /// "Enter the city" on the reveal — hands the new hero to the app.
    func enterCity(appState: AppState, cache: GameDataCache) async {
        guard let character = createdCharacter else { return }

        // BUG-08: root-level cover stays up across the `currentScreen`
        // cross-fade while the destination decodes its large backdrops.
        appState.isForgingHero = true

        appState.currentCharacter = character
        appState.userCharacters.append(character)
        if !allSkins.isEmpty {
            cache.cacheSkins(allSkins)
        }
        // First hero → lore cinematic; additional heroes → selection screen.
        if appState.userCharacters.count <= 1 {
            appState.currentScreen = .loreIntro(heroName: character.characterName)
        } else {
            appState.currentScreen = .characterSelect
        }
        appState.authPath = NavigationPath()

        try? await Task.sleep(for: .milliseconds(350))
        appState.isForgingHero = false
    }
}
