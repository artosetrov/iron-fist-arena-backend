import Foundation

@MainActor
final class ShopService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Get Items

    func getItems() async -> [ShopItem] {
        guard let charId = appState.currentCharacter?.id else { return [] }
        do {
            let response = try await APIClient.shared.getRaw(
                APIEndpoints.shopItems,
                params: ["character_id": charId]
            )
            let itemsArray: [[String: Any]]
            if let items = response["items"] as? [[String: Any]] {
                itemsArray = items
            } else if let items = response["shop_items"] as? [[String: Any]] {
                itemsArray = items
            } else {
                itemsArray = []
            }
            let jsonData = try JSONSerialization.data(withJSONObject: itemsArray)
            let decoder = JSONDecoder()
            return try decoder.decode([ShopItem].self, from: jsonData)
        } catch {
            appState.showToast("Failed to load shop", subtitle: "Check connection and try again", type: .error, actionLabel: "Retry") { [weak self] in
                Task { @MainActor in
                    _ = await self?.getItems()
                }
            }
            return []
        }
    }

    // MARK: - Buy Item

    func buy(catalogId: String) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let body: [String: Any] = [
                "character_id": charId,
                "item_catalog_id": catalogId
            ]
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.shopBuy,
                body: body
            )
            // Update character currency from response
            updateCharacter(from: response)
            return true
        } catch let error as APIError {
            if case .clientError(_, let message) = error {
                appState.showToast(message, type: .error)
            } else {
                appState.showToast("Purchase failed", subtitle: "Check your gold balance and try again", type: .error)
            }
            return false
        } catch {
            appState.showToast("Purchase failed", subtitle: "Check your gold balance and try again", type: .error)
            return false
        }
    }

    // MARK: - Buy Consumable

    func buyConsumable(consumableType: String, quantity: Int = 1) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let body: [String: Any] = [
                "character_id": charId,
                "consumable_type": consumableType,
                "quantity": quantity
            ]
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.shopBuyConsumable,
                body: body
            )
            updateCharacter(from: response)
            return true
        } catch let error as APIError {
            if case .clientError(_, let message) = error {
                appState.showToast(message, type: .error)
            } else {
                appState.showToast("Purchase failed", subtitle: "Check your gold balance and try again", type: .error)
            }
            return false
        } catch {
            appState.showToast("Purchase failed", subtitle: "Check your gold balance and try again", type: .error)
            return false
        }
    }

    // MARK: - Buy Gems (gold → gems)

    func buyGems(gemsAmount: Int) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let body: [String: Any] = [
                "character_id": charId,
                "gems_amount": gemsAmount
            ]
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.shopBuyGems,
                body: body
            )
            updateCharacter(from: response)
            return true
        } catch let error as APIError {
            if case .clientError(_, let message) = error {
                appState.showToast(message, type: .error)
            } else {
                appState.showToast("Purchase failed", subtitle: "Check your gold balance and try again", type: .error)
            }
            return false
        } catch {
            appState.showToast("Purchase failed", subtitle: "Check your gold balance and try again", type: .error)
            return false
        }
    }

    // MARK: - Buy Potion (Legacy)

    func buyPotion(potionType: String) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let body: [String: Any] = [
                "character_id": charId,
                "potion_type": potionType
            ]
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.shopBuyPotion,
                body: body
            )
            updateCharacter(from: response)
            return true
        } catch {
            appState.showToast("Purchase failed", subtitle: "Check your gold balance and try again", type: .error)
            return false
        }
    }

    // MARK: - Repair Item

    struct RepairResult {
        let repairCost: Int
        let gold: Int
        let gems: Int
        let newDurability: Int
        let maxDurability: Int
    }

    func repair(inventoryId: String) async -> RepairResult? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let body: [String: Any] = [
                "character_id": charId,
                "inventory_id": inventoryId
            ]
            let response = try await APIClient.shared.postRaw(APIEndpoints.shopRepair, body: body)
            let repairCost = response["repairCost"] as? Int ?? 0
            let character = response["character"] as? [String: Any] ?? [:]
            let gold = character["gold"] as? Int ?? (appState.currentCharacter?.gold ?? 0)
            let gems = character["gems"] as? Int ?? (appState.currentCharacter?.gems ?? 0)
            let inventoryItem = response["inventoryItem"] as? [String: Any] ?? [:]
            let newDurability = inventoryItem["durability"] as? Int ?? 0
            let maxDurability = inventoryItem["maxDurability"] as? Int ?? 0
            if var char = appState.currentCharacter {
                char.gold = gold
                char.gems = gems
                appState.currentCharacter = char
            }
            return RepairResult(
                repairCost: repairCost, gold: gold, gems: gems,
                newDurability: newDurability, maxDurability: maxDurability
            )
        } catch let error as APIError {
            if case .clientError(_, let message) = error {
                appState.showToast(message, type: .error)
            } else {
                appState.showToast("Repair failed", subtitle: "Check your gold and try again", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Repair failed", subtitle: "Check your gold and try again", type: .error)
            return nil
        }
    }

    // MARK: - Upgrade Item

    struct UpgradeResult {
        let success: Bool
        let newLevel: Int
        let levelLost: Bool
        let protectionUsed: Bool
        let upgradeCost: Int
        let gold: Int
        let gems: Int
    }

    func upgrade(inventoryId: String, useProtection: Bool) async -> UpgradeResult? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let body: [String: Any] = [
                "character_id": charId,
                "inventory_id": inventoryId,
                "use_protection": useProtection
            ]
            let response = try await APIClient.shared.postRaw(APIEndpoints.shopUpgrade, body: body)
            let success = response["success"] as? Bool ?? false
            let newLevel = response["newLevel"] as? Int ?? 0
            let levelLost = response["level_lost"] as? Bool ?? false
            let protectionUsed = response["protection_used"] as? Bool ?? false
            let upgradeCost = response["upgradeCost"] as? Int ?? 0
            let character = response["character"] as? [String: Any] ?? [:]
            let gold = character["gold"] as? Int ?? (appState.currentCharacter?.gold ?? 0)
            let gems = character["gems"] as? Int ?? (appState.currentCharacter?.gems ?? 0)
            if var char = appState.currentCharacter {
                char.gold = gold
                char.gems = gems
                appState.currentCharacter = char
            }
            appState.cachedInventory = nil // upgrade changed item stats
            return UpgradeResult(
                success: success, newLevel: newLevel, levelLost: levelLost,
                protectionUsed: protectionUsed, upgradeCost: upgradeCost,
                gold: gold, gems: gems
            )
        } catch let error as APIError {
            if case .clientError(_, let message) = error {
                appState.showToast(message, type: .error)
            } else {
                appState.showToast("Upgrade failed", subtitle: "Check your gold and try again", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Upgrade failed", subtitle: "Check your gold and try again", type: .error)
            return nil
        }
    }

    // MARK: - Helpers

    private func updateCharacter(from response: [String: Any]) {
        if let character = response["character"] as? [String: Any],
           var char = appState.currentCharacter {
            if let gold = character["gold"] as? Int { char.gold = gold }
            if let gems = character["gems"] as? Int { char.gems = gems }
            appState.currentCharacter = char
            // Invalidate inventory cache since items changed (new purchase)
            appState.cachedInventory = nil
        }
    }
}
