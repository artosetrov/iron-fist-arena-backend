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
    var pendingFightResult: [String: Any]?

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
        if result["active"] as? Bool == true {
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
        let lootItems = result["loot"] as? [[String: Any]] ?? []
        if !lootItems.isEmpty {
            appState.pendingLoot.append(contentsOf: lootItems)
        }

        // Navigate to combat animation
        if let combatData = parseCombatData(from: result) {
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

        // Parse shop items
        if let items = result["items"] as? [[String: Any]] {
            shopItems = items.map { item in
                RushShopItem(
                    slot: item["slot"] as? Int ?? 0,
                    type: item["type"] as? String ?? "buff",
                    name: item["name"] as? String ?? "",
                    icon: item["icon"] as? String ?? "shoppingcart",
                    description: item["description"] as? String ?? "",
                    price: item["price"] as? Int ?? 0,
                    purchased: item["purchased"] as? Bool ?? false
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

        guard let result, result["purchased"] as? Bool == true else {
            // Revert on failure
            shopItems = savedShopItems
            appState.currentCharacter?.gold = savedGold
            appState.showToast("Purchase failed", subtitle: "Not enough gold for this item", type: .error)
            return
        }

        // Sync with server values
        currentHpPercent = result["currentHpPercent"] as? Int ?? currentHpPercent
        updateHpFromPercent(result)
        parseBuffs(from: result["buffs"])
        if let newGold = result["gold"] as? Int {
            appState.currentCharacter?.gold = newGold
        }

        if let purchased = result["shopPurchased"] as? [Int] {
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

    // MARK: - Dismiss Event/Treasure overlays

    func dismissEventResult() {
        showEventResult = false
    }

    func dismissTreasureResult() {
        showTreasureResult = false
    }

    // MARK: - Private: Parse Status (GET response)

    private func applyStatusResult(_ result: [String: Any]) {
        runId = result["run_id"] as? String ?? ""
        isActive = true
        isGameOver = false
        rushComplete = false

        // Parse rooms
        if let rawRooms = result["rooms"] as? [[String: Any]] {
            rooms = rawRooms.map { r in
                RushRoom(
                    index: r["index"] as? Int ?? 0,
                    type: r["type"] as? String ?? "combat",
                    resolved: r["resolved"] as? Bool ?? false,
                    seed: r["seed"] as? Int ?? 0
                )
            }
        }

        currentRoomIndex = result["currentRoomIndex"] as? Int ?? 0
        totalRooms = result["totalRooms"] as? Int ?? 12
        currentHpPercent = result["currentHpPercent"] as? Int ?? 100
        updateHpFromPercent(result)

        // Parse buffs
        parseBuffs(from: result["buffs"])

        // Parse rewards
        let rewards = result["rewards"] as? [String: Any]
        accumulatedGold = rewards?["totalGold"] as? Int ?? 0
        accumulatedXp = rewards?["totalXp"] as? Int ?? 0

        // Parse enemy (status uses "currentEnemy" not "current_enemy")
        if let enemy = result["currentEnemy"] as? [String: Any] {
            enemyName = enemy["name"] as? String ?? "???"
            enemyLevel = enemy["level"] as? Int ?? 1
        }
    }

    // MARK: - Private: Parse Start (POST response)

    private func applyStartResult(_ result: [String: Any]) {
        runId = result["run_id"] as? String ?? result["id"] as? String ?? ""
        isActive = true
        isGameOver = false
        rushComplete = false

        // Parse rooms
        if let rawRooms = result["rooms"] as? [[String: Any]] {
            rooms = rawRooms.map { r in
                RushRoom(
                    index: r["index"] as? Int ?? 0,
                    type: r["type"] as? String ?? "combat",
                    resolved: r["resolved"] as? Bool ?? false,
                    seed: r["seed"] as? Int ?? 0
                )
            }
        }

        currentRoomIndex = result["currentRoomIndex"] as? Int ?? 0
        totalRooms = result["totalRooms"] as? Int ?? 12
        currentHpPercent = result["currentHpPercent"] as? Int ?? 100
        updateHpFromPercent(result)

        // Parse buffs
        parseBuffs(from: result["buffs"])

        // Parse rewards
        let rewards = result["rewards"] as? [String: Any]
        accumulatedGold = rewards?["totalGold"] as? Int ?? 0
        accumulatedXp = rewards?["totalXp"] as? Int ?? 0

        // Reset items count on fresh start
        if result["resumed"] as? Bool != true {
            accumulatedItems = 0
            appState.pendingLoot = []
        }

        // Parse enemy
        if let enemy = result["current_enemy"] as? [String: Any] {
            enemyName = enemy["name"] as? String ?? "???"
            enemyLevel = enemy["level"] as? Int ?? 1
        }
    }

    // MARK: - Private: Parse Fight Result

    private func applyFightResult(_ result: [String: Any]) {
        let won = result["victory"] as? Bool ?? false
        lastFightWon = won

        if won {
            let rewards = result["rewards"] as? [String: Any]
            accumulatedGold = rewards?["totalGold"] as? Int ?? accumulatedGold
            accumulatedXp = rewards?["totalXp"] as? Int ?? accumulatedXp
            applyCharacterRewardState(from: result)

            // Count loot
            if let lootItems = result["loot"] as? [[String: Any]], !lootItems.isEmpty {
                accumulatedItems += lootItems.count
            }

            // Update HP
            currentHpPercent = result["currentHpPercent"] as? Int ?? currentHpPercent
            updateHpFromPercent(result)

            // Update buffs
            parseBuffs(from: result["buffs"])

            // Check rush completion
            if result["rushComplete"] as? Bool == true {
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

    private func applyResolveResult(_ result: [String: Any]) {
        let type = result["type"] as? String ?? ""

        // Update HP and buffs
        currentHpPercent = result["currentHpPercent"] as? Int ?? currentHpPercent
        updateHpFromPercent(result)
        parseBuffs(from: result["buffs"])

        // Update rewards
        let rewards = result["rewards"] as? [String: Any]
        accumulatedGold = rewards?["totalGold"] as? Int ?? accumulatedGold
        accumulatedXp = rewards?["totalXp"] as? Int ?? accumulatedXp
        applyCharacterRewardState(from: result)

        switch type {
        case "treasure":
            treasureGold = result["gold"] as? Int ?? 0
            if let buffData = result["buffGranted"] as? [String: Any] {
                treasureBuff = RushBuff(
                    id: buffData["id"] as? String ?? "",
                    name: buffData["name"] as? String ?? "",
                    stat: buffData["stat"] as? String ?? "",
                    value: buffData["value"] as? Int ?? 0,
                    icon: buffData["icon"] as? String ?? ""
                )
            } else {
                treasureBuff = nil
            }
            showTreasureResult = true

        case "event":
            eventResultIcon = result["eventIcon"] as? String ?? "questionmark.circle"
            eventResultTitle = result["eventName"] as? String ?? "Event"
            eventResultDescription = result["description"] as? String ?? ""
            showEventResult = true

        default:
            break
        }

        // Check completion
        if result["rushComplete"] as? Bool == true {
            rushComplete = true
            isGameOver = true
            return
        }

        // Advance
        advanceFromResult(result)
    }

    private func applyCharacterRewardState(from result: [String: Any]) {
        guard let char = appState.currentCharacter else { return }
        let previousLevel = char.level
        var resolvedGold: Int?
        var resolvedXp: Int?

        if let rewards = result["rewards"] as? [String: Any],
           let goldDelta = rewards["gold"] as? Int,
           goldDelta != 0 {
            resolvedGold = char.gold + goldDelta
        }

        if let currentXp = result["current_xp"] as? Int {
            resolvedXp = currentXp
        } else if let rewards = result["rewards"] as? [String: Any],
                  let xpDelta = rewards["xp"] as? Int,
                  xpDelta != 0 {
            resolvedXp = (char.experience ?? 0) + xpDelta
        }

        let leveledUp = result["leveled_up"] as? Bool ?? false
        let newLevel = result["new_level"] as? Int
        let statPointsAwarded = result["stat_points_awarded"] as? Int ?? 0

        appState.applyAuthoritativeRewardState(
            gold: resolvedGold,
            xp: resolvedXp,
            leveledUp: leveledUp,
            newLevel: newLevel,
            statPointsAwarded: statPointsAwarded,
            previousLevel: previousLevel
        )
    }

    // MARK: - Private: Advance to Next Room

    private func advanceFromResult(_ result: [String: Any]) {
        if let nextRoom = result["nextRoom"] as? [String: Any] {
            let idx = nextRoom["index"] as? Int ?? (currentRoomIndex + 1)
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

            let nextType = nextRoom["type"] as? String ?? "combat"
            if nextType == "combat" || nextType == "elite" || nextType == "miniboss" {
                if let nextEnemy = result["nextEnemy"] as? [String: Any] {
                    enemyName = nextEnemy["name"] as? String ?? "???"
                    enemyLevel = nextEnemy["level"] as? Int ?? currentFloor
                }
            }
        } else {
            currentRoomIndex += 1
        }
    }

    // MARK: - Private: Update HP from result

    private func updateHpFromPercent(_ result: [String: Any]) {
        // Prefer real HP values if backend provides them
        if let hp = result["currentHp"] as? Int {
            currentHp = hp
        } else {
            currentHp = maxHp * currentHpPercent / 100
        }
        if let mhp = result["maxHp"] as? Int {
            maxHp = mhp
        }
    }

    // MARK: - Private: Parse Buffs

    private func parseBuffs(from raw: Any?) {
        guard let rawBuffs = raw as? [[String: Any]] else { return }
        buffs = rawBuffs.map { b in
            RushBuff(
                id: b["id"] as? String ?? "",
                name: b["name"] as? String ?? "",
                stat: b["stat"] as? String ?? "",
                value: b["value"] as? Int ?? 0,
                icon: b["icon"] as? String ?? ""
            )
        }
    }

    // MARK: - Private: Parse Combat Data

    private func parseCombatData(from response: [String: Any]) -> CombatData? {
        guard response["player"] != nil, response["combat_log"] != nil, response["result"] != nil else {
            #if DEBUG
            let keys = Array(response.keys).sorted()
            print("[DUNGEON-RUSH] parseCombatData: missing required keys. Available: \(keys)")
            print("[DUNGEON-RUSH]   player=\(response["player"] != nil), combat_log=\(response["combat_log"] != nil), result=\(response["result"] != nil)")
            #endif
            return nil
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: response)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let data = try decoder.decode(CombatData.self, from: jsonData)
            #if DEBUG
            print("[DUNGEON-RUSH] parseCombatData OK: \(data.combatLog.count) turns, isWin=\(data.result.isWin)")
            #endif
            return data
        } catch {
            #if DEBUG
            print("[DUNGEON-RUSH] parseCombatData decode FAILED: \(error)")
            // Print the raw JSON to help diagnose which field failed
            if let jsonData = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("[DUNGEON-RUSH] Raw response (first 2000 chars): \(String(jsonString.prefix(2000)))")
            }
            #endif
            return nil
        }
    }
}
