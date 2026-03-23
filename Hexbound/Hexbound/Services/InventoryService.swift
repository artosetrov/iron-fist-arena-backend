import Foundation

@MainActor
final class InventoryService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Load Inventory

    func loadInventory() async -> [Item] {
        guard let charId = appState.currentCharacter?.id else { return [] }
        do {
            let response = try await APIClient.shared.getRaw(
                APIEndpoints.inventory,
                params: ["character_id": charId]
            )
            // Update inventorySlots from response
            if let slots = response["inventorySlots"] as? Int {
                appState.currentCharacter?.inventorySlots = slots
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            var allItems: [Item] = []

            // Parse equipment
            let itemsArray = extractEquipmentArray(from: response)
            let flattened = flattenEquipmentItems(itemsArray)
            if let jsonData = try? JSONSerialization.data(withJSONObject: flattened) {
                if let equipItems = try? decoder.decode([Item].self, from: jsonData) {
                    allItems.append(contentsOf: equipItems)
                } else {
                    #if DEBUG
                    print("[InventoryService] Failed to decode equipment items")
                    #endif
                }
            }

            // Parse consumables
            if let consumablesArray = response["consumables"] as? [[String: Any]] {
                let consumableItems = consumablesArray.compactMap { mapConsumableToItem($0) }
                allItems.append(contentsOf: consumableItems)
            }

            appState.cachedInventory = allItems
            return allItems
        } catch {
            #if DEBUG
            print("[InventoryService] Network error: \(error)")
            #endif
            // Fallback to cache
            if let cached = appState.cachedInventory {
                return cached
            }
            appState.showToast("Failed to load inventory", subtitle: "Check connection and try again", type: .error)
            return []
        }
    }

    // MARK: - Equip

    func equip(inventoryId: String) async -> [Item]? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let body: [String: Any] = [
                "character_id": charId,
                "inventory_id": inventoryId
            ]
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.inventoryEquip,
                body: body
            )
            // FTUE: mark gear up complete on first equip
            TutorialManager.shared.completeFTUEObjective(.gearUp)
            return parseInventoryResponse(response)
        } catch let error as APIError {
            if case .clientError(_, let message) = error {
                appState.showToast(message, type: .error)
            } else {
                appState.showToast("Equip failed", subtitle: "Item may have class or level restrictions", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Equip failed", subtitle: "Item may have class or level restrictions", type: .error)
            return nil
        }
    }

    // MARK: - Unequip

    func unequip(inventoryId: String) async -> [Item]? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let body: [String: Any] = [
                "character_id": charId,
                "inventory_id": inventoryId
            ]
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.inventoryUnequip,
                body: body
            )
            return parseInventoryResponse(response)
        } catch {
            appState.showToast("Unequip failed", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    // MARK: - Sell

    /// Sells an item. Returns true on success, false on failure.
    /// Does NOT reload full inventory — caller should remove item locally.
    func sell(inventoryId: String) async -> SellResult? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let body: [String: Any] = [
                "character_id": charId,
                "inventory_id": inventoryId
            ]
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.inventorySell,
                body: body
            )
            let gold = response["gold"] as? Int
            let soldFor = response["soldFor"] as? Int ?? response["sold_for"] as? Int ?? 0
            if let gold {
                appState.currentCharacter?.gold = gold
                appState.cachedInventory = nil // invalidate so next load fetches fresh data
            }
            return SellResult(gold: gold ?? 0, soldFor: soldFor)
        } catch {
            appState.showToast("Sell failed", subtitle: "Unequip item first, then try again", type: .error)
            return nil
        }
    }

    struct SellResult {
        let gold: Int
        let soldFor: Int
    }

    // MARK: - Use Consumable

    /// Uses an item/consumable. Returns true on success, false on failure.
    /// Does NOT reload full inventory — caller should update quantity locally.
    func useItem(inventoryId: String, consumableType: String? = nil) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let response: [String: Any]

            if let consumableType = consumableType {
                // Consumable from consumableInventory — use /api/consumables/use
                let body: [String: Any] = [
                    "character_id": charId,
                    "consumable_type": consumableType
                ]
                response = try await APIClient.shared.postRaw(
                    APIEndpoints.consumablesUse,
                    body: body
                )
            } else {
                // Equipment-based consumable — use /api/inventory/use
                let body: [String: Any] = [
                    "character_id": charId,
                    "inventory_id": inventoryId
                ]
                response = try await APIClient.shared.postRaw(
                    APIEndpoints.inventoryUse,
                    body: body
                )
            }

            // Single write-back to avoid @Observable re-entrant access
            if var char = appState.currentCharacter {
                if let stamina = response["stamina"] as? [String: Any],
                   let after = stamina["after"] as? Int {
                    char.currentStamina = after
                }
                if let health = response["health"] as? [String: Any],
                   let after = health["after"] as? Int {
                    char.currentHp = after
                }
                appState.currentCharacter = char
            }
            // Invalidate inventory cache (consumable quantity changed)
            appState.cachedInventory = nil
            return true
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message), .serverError(_, let message):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to use item", subtitle: "Item may be on cooldown", type: .error)
            }
            return false
        } catch {
            appState.showToast("Failed to use item", subtitle: "Item may be on cooldown", type: .error)
            return false
        }
    }

    // MARK: - Expand Inventory

    func expandInventory() async -> Int? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let body: [String: Any] = ["character_id": charId]
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.inventoryExpand,
                body: body
            )
            if let slots = response["inventorySlots"] as? Int,
               let gold = response["gold"] as? Int {
                // Single write-back to avoid @Observable re-entrant access
                if var char = appState.currentCharacter {
                    char.inventorySlots = slots
                    char.gold = gold
                    appState.currentCharacter = char
                }
                return slots
            }
            return nil
        } catch let error as APIError {
            if case .clientError(_, let message) = error {
                appState.showToast(message, type: .error)
            } else {
                appState.showToast("Failed to expand inventory", subtitle: "Check your gold balance", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Failed to expand inventory", subtitle: "Check your gold balance", type: .error)
            return nil
        }
    }

    // MARK: - Helpers

    /// Extracts the equipment array from the API response.
    /// Backend returns { "equipment": [...] }
    private func extractEquipmentArray(from response: [String: Any]) -> [[String: Any]] {
        if let items = response["equipment"] as? [[String: Any]] {
            return items
        } else if let items = response["items"] as? [[String: Any]] {
            return items
        } else if let items = response["inventory"] as? [[String: Any]] {
            return items
        }
        #if DEBUG
        print("[InventoryService] No equipment/items/inventory key found in response. Keys: \(response.keys.sorted())")
        #endif
        return []
    }

    /// Flattens nested EquipmentInventory + Item structure into flat Item dicts.
    /// Backend returns: { id, upgradeLevel, isEquipped, ..., item: { itemName, itemType, rarity, ... } }
    /// iOS expects:     { id, upgradeLevel, isEquipped, itemName, itemType, rarity, ... }
    private func flattenEquipmentItems(_ items: [[String: Any]]) -> [[String: Any]] {
        items.map { entry in
            var flat = entry
            if let nested = entry["item"] as? [String: Any] {
                for (key, value) in nested {
                    // Parent id (EquipmentInventory.id) takes precedence over nested Item.id
                    if key == "id" { continue }
                    flat[key] = value
                }
            }
            flat.removeValue(forKey: "item")
            return flat
        }
    }

    /// Parses an inventory response from equip/unequip endpoints.
    private func parseInventoryResponse(_ response: [String: Any]) -> [Item]? {
        let itemsArray = extractEquipmentArray(from: response)
        guard !itemsArray.isEmpty else {
            #if DEBUG
            print("[InventoryService] parseInventoryResponse: empty equipment array")
            #endif
            return nil
        }
        let flattened = flattenEquipmentItems(itemsArray)
        guard let jsonData = try? JSONSerialization.data(withJSONObject: flattened) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let items = try decoder.decode([Item].self, from: jsonData)
            appState.cachedInventory = items
            return items
        } catch {
            #if DEBUG
            print("[InventoryService] parseInventoryResponse decode error: \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Consumable Helpers

    private static let consumableDisplayNames: [String: String] = [
        "stamina_potion_small": "Small Stamina Potion",
        "stamina_potion_medium": "Medium Stamina Potion",
        "stamina_potion_large": "Large Stamina Potion",
        "health_potion_small": "Small Health Potion",
        "health_potion_medium": "Medium Health Potion",
        "health_potion_large": "Large Health Potion",
    ]

    /// Maps consumableType → local asset key in Assets.xcassets/Items/
    private static let consumableImageKeys: [String: String] = [
        "stamina_potion_small": "pot_stamina_small",
        "stamina_potion_medium": "pot_stamina_medium",
        "stamina_potion_large": "pot_stamina_large",
        "health_potion_small": "pot_health_small",
        "health_potion_medium": "pot_health_medium",
        "health_potion_large": "pot_health_large",
        "gem_pack_small": "gem_pack_small",
        "gem_pack_medium": "gem_pack_medium",
        "gem_pack_large": "gem_pack_large",
    ]

    /// Maps a ConsumableInventory JSON dict to an Item for display in the inventory grid.
    private func mapConsumableToItem(_ dict: [String: Any]) -> Item? {
        guard let id = dict["id"] as? String,
              let consumableType = dict["consumableType"] as? String,
              let quantity = dict["quantity"] as? Int,
              quantity > 0 else { return nil }

        let displayName = Self.consumableDisplayNames[consumableType] ?? consumableType.replacingOccurrences(of: "_", with: " ").capitalized
        let imageKey = Self.consumableImageKeys[consumableType]

        return Item(
            id: id,
            itemName: displayName,
            itemType: .consumable,
            rarity: .common,
            itemLevel: 1,
            upgradeLevel: nil,
            isEquipped: false,
            equippedSlot: nil,
            baseStats: nil,
            rolledStats: nil,
            buyPrice: nil,
            sellPrice: nil,
            setName: nil,
            specialEffect: nil,
            uniquePassive: nil,
            durability: nil,
            maxDurability: nil,
            description: nil,
            catalogId: consumableType,
            classRestriction: nil,
            imageUrl: nil,
            imageKey: imageKey,
            quantity: quantity,
            consumableType: consumableType
        )
    }
}
