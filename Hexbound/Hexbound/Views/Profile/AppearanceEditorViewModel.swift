import SwiftUI

private struct AppearanceChangeRequest: Encodable {
    let origin: CharacterOrigin?
    let gender: CharacterGender?
    let avatar: String?
}

private struct AppearanceChangeResponse: Decodable {
    let character: Character
    let gold: Int?
    let gems: Int?
    let wallet: AppearanceWallet?

    var confirmedCharacter: Character {
        var value = character
        if let resolvedGold = wallet?.gold ?? gold {
            value.gold = resolvedGold
        }
        if let resolvedGems = wallet?.gems ?? gems {
            value.gems = resolvedGems
        }
        return value
    }
}

private struct AppearanceWallet: Decodable {
    let gold: Int
    let gems: Int?
}

/// What the player can do with a skin in the appearance editor.
enum SkinStatus: Equatable {
    case equipped       // the hero wears it now
    case owned          // default, reward or earlier purchase — equip for free
    case gold(Int)      // buy for gold
    case gems(Int)      // buy for gems

    var isPurchase: Bool {
        switch self {
        case .gold, .gems: true
        case .equipped, .owned: false
        }
    }
}

/// Filter chips above the skin gallery.
enum SkinFilter: String, CaseIterable, Identifiable {
    case all, owned, gold, gems

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .owned: "Owned"
        case .gold: "Gold"
        case .gems: "Gems"
        }
    }

    func matches(_ status: SkinStatus) -> Bool {
        switch (self, status) {
        case (.all, _): true
        case (.owned, .owned), (.owned, .equipped): true
        case (.gold, .gold): true
        case (.gems, .gems): true
        default: false
        }
    }
}

@MainActor @Observable
final class AppearanceEditorViewModel {
    private let appState: AppState
    private let cache: GameDataCache

    static let originChangeCost = 100

    var selectedOrigin: CharacterOrigin?
    var selectedGender: CharacterGender = .male
    var selectedSkinKey: String?
    var filter: SkinFilter = .all
    var diceRotation: Double = 0

    var allSkins: [AppearanceSkin] = []
    var isLoadingSkins = false

    var isSaving = false
    var errorMessage = ""
    var didSave = false

    /// Purchase confirmation sheet.
    var showPurchaseSheet = false
    /// Set by the sheet's Buy button. The purchase fires from the sheet's
    /// `onDismiss`, so the sheet is gone before the screen pops back.
    private var purchaseConfirmed = false

    /// Skins bought during this visit — the cached catalog's `owned` flag
    /// is stale until the next fetch.
    private var purchasedKeys: Set<String> = []

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
            syncSelection()
        }
    }

    var character: Character? { appState.currentCharacter }

    // MARK: - Skin Lists

    /// Every skin for the current origin + gender (free and paid), catalog order.
    var availableSkins: [AppearanceSkin] {
        allSkins.filter { skin in
            let matchesOrigin = selectedOrigin.map { skin.origin == $0.rawValue } ?? true
            return matchesOrigin && skin.gender == selectedGender.rawValue
        }.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Skins shown in the gallery under the active filter.
    var gallerySkins: [AppearanceSkin] {
        availableSkins.filter { filter.matches(status(of: $0)) }
    }

    func count(for filter: SkinFilter) -> Int {
        availableSkins.filter { filter.matches(status(of: $0)) }.count
    }

    func status(of skin: AppearanceSkin) -> SkinStatus {
        if skin.skinKey == character?.avatar { return .equipped }
        if isOwned(skin) { return .owned }
        if skin.priceGems > 0 { return .gems(skin.priceGems) }
        if skin.priceGold > 0 { return .gold(skin.priceGold) }
        return .owned
    }

    private func isOwned(_ skin: AppearanceSkin) -> Bool {
        skin.isDefault || skin.owned == true || purchasedKeys.contains(skin.skinKey)
    }

    // MARK: - Selection

    var selectedSkin: AppearanceSkin? {
        guard let key = selectedSkinKey else { return nil }
        return allSkins.first { $0.skinKey == key }
    }

    var selectedStatus: SkinStatus? {
        selectedSkin.map { status(of: $0) }
    }

    func select(_ skin: AppearanceSkin) {
        selectedSkinKey = skin.skinKey
        errorMessage = ""
    }

    /// Equipped skin if it is in the list, else the first owned one, else the first.
    private func preferredSkinKey(in skins: [AppearanceSkin]) -> String? {
        if let equipped = skins.first(where: { status(of: $0) == .equipped }) { return equipped.skinKey }
        if let owned = skins.first(where: { status(of: $0) == .owned }) { return owned.skinKey }
        return skins.first?.skinKey
    }

    private func syncSelection() {
        let skins = availableSkins
        if let key = selectedSkinKey, skins.contains(where: { $0.skinKey == key }) { return }
        selectedSkinKey = preferredSkinKey(in: skins)
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

    /// Primary button is live for anything but the look the hero already wears.
    var primaryEnabled: Bool {
        guard let status = selectedStatus, !isSaving else { return false }
        return status != .equipped && hasChanges
    }

    private var canAffordSelected: Bool {
        guard let status = selectedStatus else { return false }
        let gold = character?.gold ?? 0
        let originCost = originChanged ? Self.originChangeCost : 0
        switch status {
        case .gold(let price): return gold >= price + originCost
        case .gems(let price): return (character?.gems ?? 0) >= price && gold >= originCost
        case .equipped, .owned: return gold >= originCost
        }
    }

    // MARK: - Actions

    func primaryTapped() {
        guard let skin = selectedSkin, let status = selectedStatus, !isSaving else { return }
        switch status {
        case .equipped:
            return
        case .owned:
            save()
        case .gold(let price), .gems(let price):
            guard canAffordSelected else {
                let isGems = status == .gems(price)
                HapticManager.light()
                appState.showToast(
                    isGems ? "Not enough gems" : "Not enough gold",
                    subtitle: "\(skin.name) costs \(price) \(isGems ? "gems" : "gold").",
                    type: .error,
                    actionLabel: "Shop"
                ) { [appState] in
                    appState.mainPath.append(AppRoute.currencyPurchase(initialTab: isGems ? 1 : 0))
                }
                return
            }
            purchaseConfirmed = false
            showPurchaseSheet = true
        }
    }

    /// Purchase sheet "Buy & Equip".
    func confirmPurchase() {
        purchaseConfirmed = true
        showPurchaseSheet = false
    }

    /// Purchase sheet `onDismiss` — buys only when "Buy & Equip" was tapped.
    func purchaseSheetDismissed() {
        guard purchaseConfirmed else { return }
        purchaseConfirmed = false
        save()
    }

    // MARK: - Gender Toggle

    func toggleGender() {
        selectedGender = selectedGender == .male ? .female : .male
        selectedSkinKey = preferredSkinKey(in: availableSkins)
        errorMessage = ""
    }

    // MARK: - Randomize (owned looks of the current race, either gender)

    func randomize() {
        let pool = allSkins.filter { skin in
            let matchesOrigin = selectedOrigin.map { skin.origin == $0.rawValue } ?? true
            let status = self.status(of: skin)
            return matchesOrigin
                && (status == .owned || status == .equipped)
                && skin.skinKey != selectedSkinKey
        }
        guard let pick = pool.randomElement() else { return }
        if let gender = CharacterGender(rawValue: pick.gender) {
            selectedGender = gender
        }
        selectedSkinKey = pick.skinKey
        errorMessage = ""
    }

    // MARK: - Fetch Skins from API

    func fetchSkins() async {
        if allSkins.isEmpty { isLoadingSkins = true }
        do {
            let response: AppearancesResponse = try await APIClient.shared.get(APIEndpoints.appearances)
            allSkins = response.skins
            cache.cacheSkins(response.skins)
            isLoadingSkins = false
            syncSelection()
        } catch {
            isLoadingSkins = false
        }
    }

    // MARK: - Save (equip, or buy + equip)

    func save() {
        guard hasChanges, !isSaving, let char = character, let skin = selectedSkin else { return }
        let status = self.status(of: skin)

        // Previous state for revert
        let prevOrigin = char.origin
        let prevGender = char.gender ?? .male
        let prevAvatar = char.avatar
        let prevGold = char.gold
        let prevGems = char.gems

        // Optimistic: wear it and pay for it now
        if let newOrigin = selectedOrigin { appState.currentCharacter?.origin = newOrigin }
        appState.currentCharacter?.gender = selectedGender
        appState.currentCharacter?.avatar = skin.skinKey
        var goldCost = originChanged ? Self.originChangeCost : 0
        switch status {
        case .gold(let price): goldCost += price
        case .gems(let price): appState.currentCharacter?.gems = (prevGems ?? 0) - price
        case .equipped, .owned: break
        }
        if goldCost > 0 { appState.currentCharacter?.gold = prevGold - goldCost }
        let newlyPurchased = status.isPurchase && purchasedKeys.insert(skin.skinKey).inserted

        HapticManager.success()
        if status.isPurchase {
            appState.showToast("\(skin.name) unlocked", subtitle: "New look equipped", type: .reward)
        }
        isSaving = true
        didSave = true
        errorMessage = ""

        let request = AppearanceChangeRequest(
            origin: selectedOrigin != prevOrigin ? selectedOrigin : nil,
            gender: selectedGender != prevGender ? selectedGender : nil,
            avatar: skin.skinKey != prevAvatar ? skin.skinKey : nil
        )

        // Fire API in background
        let charId = char.id
        Task { [weak self] in
            guard let self else { return }
            defer { isSaving = false }
            do {
                let result: AppearanceChangeResponse = try await APIClient.shared.patch(
                    APIEndpoints.changeAppearance(charId),
                    body: request
                )
                // Update with server-confirmed character data
                appState.currentCharacter = result.confirmedCharacter
            } catch {
                // Revert on failure
                appState.currentCharacter?.origin = prevOrigin
                appState.currentCharacter?.gender = prevGender
                appState.currentCharacter?.avatar = prevAvatar
                appState.currentCharacter?.gold = prevGold
                appState.currentCharacter?.gems = prevGems
                if newlyPurchased { purchasedKeys.remove(skin.skinKey) }
                didSave = false
                let message = (error as? APIError)?.localizedDescription ?? "Failed to update appearance"
                errorMessage = message
                appState.showToast(
                    "Appearance change failed",
                    subtitle: message,
                    type: .error,
                    actionLabel: "Retry"
                ) {
                    self.save()
                }
            }
        }
    }
}
