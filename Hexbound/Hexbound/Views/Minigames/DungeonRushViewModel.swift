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
        case "combat":   return "⚔️"
        case "elite":    return "🗡️"
        case "miniboss": return "👹"
        case "treasure": return "📦"
        case "event":    return "❓"
        case "shop":     return "🏪"
        default:         return "❔"
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

    // Room system
    var rooms: [RushRoom] = []
    var currentRoomIndex = 0
    var totalRooms = 12

    // HP & Buffs
    var currentHpPercent = 100
    var buffs: [RushBuff] = []

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
        let result = await service.rushStart()
        isLoading = false
        guard let result else { return }
        applyStartResult(result)
    }

    // MARK: - Check & Resume

    func checkActiveRush() async {
        isLoading = true
        let result = await service.rushStatus()
        isLoading = false
        guard let result else { return }
        if result["active"] as? Bool == true {
            applyStatusResult(result)
        }
    }

    // MARK: - Fight (combat/elite/miniboss rooms)

    func fight() async {
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
        guard let room = currentRoom, !room.isCombat, room.type != "shop" else { return }
        isLoading = true
        let result = await service.rushResolve(runId: runId)
        isLoading = false
        guard let result else { return }
        applyResolveResult(result)
    }

    // MARK: - Shop

    func openShop() async {
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
                    icon: item["icon"] as? String ?? "🛒",
                    description: item["description"] as? String ?? "",
                    price: item["price"] as? Int ?? 0,
                    purchased: item["purchased"] as? Bool ?? false
                )
            }
            showShop = true
        }
    }

    func buyShopItem(slot: Int) async {
        isProcessingShop = true
        let result = await service.rushShopBuy(runId: runId, slot: slot)
        isProcessingShop = false
        guard let result else {
            appState.showToast("Purchase failed", type: .error)
            return
        }

        if result["purchased"] as? Bool == true {
            // Update HP and buffs
            currentHpPercent = result["currentHpPercent"] as? Int ?? currentHpPercent
            parseBuffs(from: result["buffs"])

            // Update shop purchased state
            if let purchased = result["shopPurchased"] as? [Int] {
                shopItems = shopItems.map { item in
                    RushShopItem(
                        slot: item.slot,
                        type: item.type,
                        name: item.name,
                        icon: item.icon,
                        description: item.description,
                        price: item.price,
                        purchased: purchased.contains(item.slot)
                    )
                }
            }

            let itemName = (result["item"] as? [String: Any])?["name"] as? String ?? "Item"
            appState.showToast("Purchased \(itemName)!", type: .reward)
        }
    }

    func leaveShop() async {
        isLoading = true
        let result = await service.rushResolve(runId: runId, action: "leave_shop")
        isLoading = false
        showShop = false
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
        if accumulatedGold > 0 || accumulatedXp > 0 {
            appState.showToast("Escaped with \(accumulatedGold) gold!", type: .reward)
        }
    }

    func exit() {
        appState.pendingLoot = []
        if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
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

            // Count loot
            if let lootItems = result["loot"] as? [[String: Any]], !lootItems.isEmpty {
                accumulatedItems += lootItems.count
            }

            // Update HP
            currentHpPercent = result["currentHpPercent"] as? Int ?? currentHpPercent

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

            // Check level up
            if let leveledUp = result["leveled_up"] as? Bool, leveledUp,
               let newLevel = result["new_level"] as? Int {
                let statPoints = result["stat_points_awarded"] as? Int ?? 3
                appState.triggerLevelUpModal(newLevel: newLevel, statPoints: statPoints)
            }
        } else {
            isGameOver = true
            appState.showToast("Defeated!", type: .error)
        }
    }

    // MARK: - Private: Parse Resolve Result

    private func applyResolveResult(_ result: [String: Any]) {
        let type = result["type"] as? String ?? ""

        // Update HP and buffs
        currentHpPercent = result["currentHpPercent"] as? Int ?? currentHpPercent
        parseBuffs(from: result["buffs"])

        // Update rewards
        let rewards = result["rewards"] as? [String: Any]
        accumulatedGold = rewards?["totalGold"] as? Int ?? accumulatedGold
        accumulatedXp = rewards?["totalXp"] as? Int ?? accumulatedXp

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
            eventResultIcon = result["eventIcon"] as? String ?? "❓"
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
        guard response["player"] != nil, response["combat_log"] != nil else { return nil }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: response)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(CombatData.self, from: jsonData)
        } catch {
            return nil
        }
    }
}
