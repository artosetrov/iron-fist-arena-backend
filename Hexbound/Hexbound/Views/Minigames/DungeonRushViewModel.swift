import SwiftUI

// MARK: - Room Data Models

struct RushRoom {
    let index: Int
    let type: String   // "combat", "elite", "miniboss", "treasure", "event", "shop"
    let resolved: Bool
    let seed: Int

    var isCombat: Bool {
        type == "combat" || type == "elite" || type == "miniboss"
    }

    var icon: String {
        switch type {
        case "combat":   return "swords"
        case "elite":    return "figure.fencing"
        case "miniboss": return "figure.wave"
        case "treasure": return "shippingbox"
        case "event":    return "questionmark.circle"
        case "shop":     return "storefront"
        default:         return "questionmark"
        }
    }

    var label: String {
        switch type {
        case "combat":   return "Combat"
        case "elite":    return "Elite"
        case "miniboss": return "Boss"
        case "treasure": return "Treasure"
        case "event":    return "Event"
        case "shop":     return "Shop"
        default:         return "Unknown"
        }
    }
}

struct RushBuff {
    let id: String
    let name: String
    let stat: String
    let value: Int
    let icon: String
}

struct RushShopItem {
    let slot: Int
    let type: String     // "buff" or "heal"
    let name: String
    let icon: String
    let description: String
    let price: Int
    let purchased: Bool
}

// MARK: - ViewModel

@MainActor @Observable
final class DungeonRushViewModel {
    private let appState: AppState
    private let service: DungeonService

    // Core state
    var runId = ""
    var isActive = false
    var isFighting = false
    var isLoading = false
    var isGameOver = false
    var lastFightWon = true
    var errorMessage: String?

    // Room system
    var rooms: [RushRoom] = []
    var currentRoomIndex = 0
    var totalRooms = 12

    // HP & Buffs — real values for HPBarView
    var currentHpPercent = 100
    var currentHp = 1000
    var maxHp = 1000
    var buffs: [RushBuff] = []

    // Abandon confirmation
    var showAbandonConfirm = false

    // Enemy (for combat rooms)
    var enemyName = "???"
    var enemyLevel = 1

    // Accumulated rewards
    var accumulatedGold = 0
    var accumulatedXp = 0
    var accumulatedItems = 0

    // Shop state
    var showShop = false
    var shopItems: [RushShopItem] = []
    var isProcessingShop = false

    // Event state
    var showEventResult = false
    var eventResultIcon = ""
    var eventResultTitle = ""
    var eventResultDescription = ""

    // Treasure state
    var showTreasureResult = false
    var treasureGold = 0
    var treasureBuff: RushBuff?

    // Rush completion
    var rushComplete = false

    // Pending result to apply after combat animation returns
    var pendingFightResult: DungeonRushFightResponse?

    init(appState: AppState) {
        self.appState = appState
        self.service = DungeonService(appState: appState)
    }

    // MARK: - Computed

    var currentRoom: RushRoom? {
        guard currentRoomIndex < rooms.count else { return nil }
        return rooms[currentRoomIndex]
    }

    var progressFraction: Double {
        guard totalRooms > 0 else { return 0 }
        return Double(currentRoomIndex) / Double(totalRooms)
    }

    var currentFloor: Int {
        currentRoomIndex + 1
    }

    // MARK: - Start Rush

    func startRush() async {
        isLoading = true
        errorMessage = nil
        let result = await service.rushStart()
        isLoading = false
        guard let result else {
            errorMessage = "Failed to start the dungeon rush. Please check your connection and try again."
            return
        }
        applyStartResult(result)
    }

    // MARK: - Check & Resume

    func checkActiveRush() async {
        isLoading = true
        errorMessage = nil
        let result = await service.rushStatus()
        isLoading = false
        guard let result else {
            errorMessage = "Failed to load dungeon rush. Please check your connection and try again."
            return
        }
        if result.active == true, (result.runId?.isEmpty == false) {
            applyStatusResult(result)
        }
    }

    // MARK: - Fight (combat/elite/miniboss rooms)

    func fight() async {
        guard !isFighting else { return } // prevent double-tap
        guard currentRoom?.isCombat == true else { return }
        isFighting = true
        let result = await service.rushFight(runId: runId)
        isFighting = false
        guard let result else {
            isGameOver = true
            lastFightWon = false
            return
        }

        // Store loot before navigation
        let lootItems = result.loot ?? []
        if !lootItems.isEmpty {
            appState.pendingLoot.append(contentsOf: lootItems.map(Self.pendingLootItem))
        }

        // Navigate to combat animation
        let combatData = result.combatData
        if !combatData.combatLog.isEmpty {
            appState.combatData = combatData
            pendingFightResult = result
            appState.mainPath.append(AppRoute.combat)
        } else {
            applyFightResult(result)
        }
    }

    // MARK: - Resolve (treasure/event rooms)

    func resolveRoom() async {
        guard !isLoading else { return } // prevent double-tap
        guard let room = currentRoom, !room.isCombat, room.type != "shop" else { return }
        isLoading = true
        let result = await service.rushResolve(runId: runId)
        isLoading = false
        guard let result else { return }
        applyResolveResult(result)
    }

    // MARK: - Shop

    func openShop() async {
        guard !isLoading else { return } // prevent double-tap
        guard currentRoom?.type == "shop" else { return }
        isLoading = true
        let result = await service.rushResolve(runId: runId)
        isLoading = false
        guard let result else { return }

        if let items = result.items {
            shopItems = items.map { item in
                RushShopItem(
                    slot: item.slot,
                    type: item.type,
                    name: item.name,
                    icon: item.icon,
                    description: item.description,
                    price: item.price,
                    purchased: item.purchased
                )
            }
            showShop = true
        }
    }

    func buyShopItem(slot: Int) async {
        guard !isProcessingShop else { return }
        isProcessingShop = true

        // Optimistic: mark item purchased + deduct gold locally
        let savedShopItems = shopItems
        let savedGold = appState.currentCharacter?.gold ?? 0
        let itemPrice = shopItems.first(where: { $0.slot == slot })?.price ?? 0

        shopItems = shopItems.map { item in
            if item.slot == slot {
                return RushShopItem(slot: item.slot, type: item.type, name: item.name,
                                    icon: item.icon, description: item.description,
                                    price: item.price, purchased: true)
            }
            return item
        }
        appState.currentCharacter?.gold = savedGold - itemPrice
        HapticManager.light()

        // Background API call
        let result = await service.rushShopBuy(runId: runId, slot: slot)
        isProcessingShop = false

        guard let result, result.purchased else {
            // Revert on failure
            shopItems = savedShopItems
            appState.currentCharacter?.gold = savedGold
            appState.showToast("Purchase failed", subtitle: "Not enough gold for this item", type: .error)
            return
        }

        // Sync with server values
        currentHpPercent = result.currentHpPercent
        updateHpFromPercent(currentHpPercent)
        buffs = (result.buffs ?? []).map(Self.mapBuff)
        if let newGold = result.playerGold {
            appState.currentCharacter?.gold = newGold
        }

        if let purchased = result.shopPurchased {
            shopItems = shopItems.map { item in
                RushShopItem(
                    slot: item.slot, type: item.type, name: item.name,
                    icon: item.icon, description: item.description,
                    price: item.price, purchased: purchased.contains(item.slot)
                )
            }
        }
    }

    func leaveShop() async {
        // Close shop UI instantly
        showShop = false

        // Resolve in background
        let result = await service.rushResolve(runId: runId, action: "leave_shop")
        guard let result else { return }
        advanceFromResult(result)
    }

    // MARK: - Apply Pending Result (after combat animation)

    func applyPendingResult() {
        guard let result = pendingFightResult else { return }
        pendingFightResult = nil
        applyFightResult(result)
    }

    // MARK: - Abandon

    func abandon() async {
        await service.rushAbandon()
        isGameOver = true
        lastFightWon = true // Abandoned = kept rewards
        HapticManager.light()
    }

    func exit() {
        appState.pendingLoot = []
        if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
    }

    /// Reset state for "Try Again" after defeat.
    func resetForRetry() {
        isGameOver = false
        isActive = false
        lastFightWon = true
        rushComplete = false
        rooms = []
        currentRoomIndex = 0
        currentHpPercent = 100
        currentHp = 1000
        maxHp = 1000
        buffs = []
        accumulatedGold = 0
        accumulatedXp = 0
        accumulatedItems = 0
        appState.pendingLoot = []
    }

    private static func mapRoom(_ room: RushRoomSnapshot) -> RushRoom {
        RushRoom(
            index: room.index,
            type: room.type,
            resolved: room.resolved,
            seed: room.seed
        )
    }

    private static func mapBuff(_ buff: RushBuffSnapshot) -> RushBuff {
        RushBuff(
            id: buff.id,
            name: buff.name,
            stat: buff.stat,
            value: buff.value,
            icon: buff.icon
        )
    }

    private static func pendingLootItem(_ item: CombatLootItem) -> PendingLootItem {
        PendingLootItem(item)
    }

    // MARK: - Dismiss Event/Treasure overlays

    func dismissEventResult() {
        showEventResult = false
    }

    func dismissTreasureResult() {
        showTreasureResult = false
    }

    // MARK: - Private: Parse Status (GET response)

    private func applyStatusResult(_ result: DungeonRushStateResponse) {
        runId = result.runId ?? ""
        isActive = true
        isGameOver = false
        rushComplete = false

        rooms = (result.rooms ?? []).map(Self.mapRoom)

        currentRoomIndex = result.currentRoomIndex ?? 0
        totalRooms = result.totalRooms ?? 12
        currentHpPercent = result.currentHpPercent ?? 100
        updateHpFromPercent(currentHpPercent)

        buffs = (result.buffs ?? []).map(Self.mapBuff)

        accumulatedGold = result.rewards?.totalGold ?? 0
        accumulatedXp = result.rewards?.totalXp ?? 0

        if let enemy = result.currentEnemy {
            enemyName = enemy.name
            enemyLevel = enemy.level
        }
    }

    // MARK: - Private: Parse Start (POST response)

    private func applyStartResult(_ result: DungeonRushStateResponse) {
        runId = result.runId ?? ""
        isActive = true
        isGameOver = false
        rushComplete = false

        rooms = (result.rooms ?? []).map(Self.mapRoom)

        currentRoomIndex = result.currentRoomIndex ?? 0
        totalRooms = result.totalRooms ?? 12
        currentHpPercent = result.currentHpPercent ?? 100
        updateHpFromPercent(currentHpPercent)

        buffs = (result.buffs ?? []).map(Self.mapBuff)

        accumulatedGold = result.rewards?.totalGold ?? 0
        accumulatedXp = result.rewards?.totalXp ?? 0

        // Reset items count on fresh start
        if result.resumed != true {
            accumulatedItems = 0
            appState.pendingLoot = []
        }

        if let enemy = result.currentEnemy {
            enemyName = enemy.name
            enemyLevel = enemy.level
        }
    }

    // MARK: - Private: Parse Fight Result

    private func applyFightResult(_ result: DungeonRushFightResponse) {
        let won = result.victory
        lastFightWon = won

        if won {
            accumulatedGold = result.rewards?.totalGold ?? accumulatedGold
            accumulatedXp = result.rewards?.totalXp ?? accumulatedXp
            applyCharacterRewardState(from: result)

            // Count loot
            if let lootItems = result.loot, !lootItems.isEmpty {
                accumulatedItems += lootItems.count
            }

            // Update HP
            currentHpPercent = result.currentHpPercent ?? currentHpPercent
            updateHpFromPercent(currentHpPercent)

            // Update buffs
            buffs = (result.buffs ?? []).map(Self.mapBuff)

            // Check rush completion
            if result.rushComplete == true {
                rushComplete = true
                isGameOver = true
                return
            }

            // Advance to next room
            advanceFromResult(result)
        } else {
            isGameOver = true
            appState.showToast("Defeated!", subtitle: "Rewards saved — try again anytime", type: .error)
        }
    }

    // MARK: - Private: Parse Resolve Result

    private func applyResolveResult(_ result: DungeonRushResolveResponse) {
        let type = result.type ?? ""

        // Update HP and buffs
        currentHpPercent = result.currentHpPercent ?? currentHpPercent
        updateHpFromPercent(currentHpPercent)
        buffs = (result.buffs ?? []).map(Self.mapBuff)

        // Update rewards
        accumulatedGold = result.rewards?.totalGold ?? accumulatedGold
        accumulatedXp = result.rewards?.totalXp ?? accumulatedXp
        applyCharacterRewardState(from: result)

        switch type {
        case "treasure":
            treasureGold = result.gold ?? 0
            treasureBuff = result.buffGranted.map(Self.mapBuff)
            showTreasureResult = true

        case "event":
            eventResultIcon = result.eventIcon ?? "questionmark.circle"
            eventResultTitle = result.eventName ?? "Event"
            eventResultDescription = result.description ?? ""
            showEventResult = true

        default:
            break
        }

        // Check completion
        if result.rushComplete == true {
            rushComplete = true
            isGameOver = true
            return
        }

        // Advance
        advanceFromResult(result)
    }

    private func applyCharacterRewardState(from result: DungeonRushFightResponse) {
        guard let char = appState.currentCharacter else { return }
        let previousLevel = char.level
        var resolvedGold: Int?
        var resolvedXp: Int?

        if let goldDelta = result.rewards?.gold, goldDelta != 0 {
            resolvedGold = char.gold + goldDelta
        }

        if let currentXp = result.currentXp {
            resolvedXp = currentXp
        } else if let xpDelta = result.rewards?.xp, xpDelta != 0 {
            resolvedXp = (char.experience ?? 0) + xpDelta
        }

        let leveledUp = result.leveledUp ?? result.result.leveledUp ?? false
        let newLevel = result.newLevel ?? result.result.newLevel
        let statPointsAwarded = result.statPointsAwarded ?? result.result.statPointsAwarded ?? 0
        let passivePointsAwarded = result.passivePointsAwarded ?? result.result.passivePointsAwarded ?? 0

        appState.applyAuthoritativeRewardState(
            gold: resolvedGold,
            xp: resolvedXp,
            leveledUp: leveledUp,
            newLevel: newLevel,
            statPointsAwarded: statPointsAwarded,
            passivePointsAwarded: passivePointsAwarded,
            previousLevel: previousLevel
        )
    }

    private func applyCharacterRewardState(from result: DungeonRushResolveResponse) {
        guard let char = appState.currentCharacter else { return }
        let previousLevel = char.level
        var resolvedGold: Int?
        var resolvedXp: Int?

        if let goldDelta = result.rewards?.gold, goldDelta != 0 {
            resolvedGold = char.gold + goldDelta
        }

        if let currentXp = result.currentXp {
            resolvedXp = currentXp
        } else if let xpDelta = result.rewards?.xp, xpDelta != 0 {
            resolvedXp = (char.experience ?? 0) + xpDelta
        }

        let leveledUp = result.leveledUp ?? false
        let newLevel = result.newLevel
        let statPointsAwarded = result.statPointsAwarded ?? 0
        let passivePointsAwarded = result.passivePointsAwarded ?? 0

        appState.applyAuthoritativeRewardState(
            gold: resolvedGold,
            xp: resolvedXp,
            leveledUp: leveledUp,
            newLevel: newLevel,
            statPointsAwarded: statPointsAwarded,
            passivePointsAwarded: passivePointsAwarded,
            previousLevel: previousLevel
        )
    }

    // MARK: - Private: Advance to Next Room

    private func advanceFromResult(_ result: DungeonRushFightResponse) {
        if let nextRoom = result.nextRoom {
            let idx = nextRoom.index
            currentRoomIndex = idx

            // Update room in local array
            if idx < rooms.count && currentRoomIndex > 0 {
                // Mark previous room as resolved
                let prevIdx = currentRoomIndex - 1
                if prevIdx < rooms.count {
                    rooms[prevIdx] = RushRoom(
                        index: rooms[prevIdx].index,
                        type: rooms[prevIdx].type,
                        resolved: true,
                        seed: rooms[prevIdx].seed
                    )
                }
            }

            let nextType = nextRoom.type
            if nextType == "combat" || nextType == "elite" || nextType == "miniboss" {
                if let nextEnemy = result.nextEnemy {
                    enemyName = nextEnemy.name
                    enemyLevel = nextEnemy.level
                }
            }
        } else {
            currentRoomIndex += 1
        }
    }

    private func advanceFromResult(_ result: DungeonRushResolveResponse) {
        if let nextRoom = result.nextRoom {
            let idx = nextRoom.index
            currentRoomIndex = idx

            if idx < rooms.count && currentRoomIndex > 0 {
                let prevIdx = currentRoomIndex - 1
                if prevIdx < rooms.count {
                    rooms[prevIdx] = RushRoom(
                        index: rooms[prevIdx].index,
                        type: rooms[prevIdx].type,
                        resolved: true,
                        seed: rooms[prevIdx].seed
                    )
                }
            }

            let nextType = nextRoom.type
            if nextType == "combat" || nextType == "elite" || nextType == "miniboss" {
                if let nextEnemy = result.nextEnemy {
                    enemyName = nextEnemy.name
                    enemyLevel = nextEnemy.level
                }
            }
        } else {
            currentRoomIndex += 1
        }
    }

    // MARK: - Private: Update HP from result

    private func updateHpFromPercent(_ percent: Int) {
        currentHp = maxHp * percent / 100
    }

}
