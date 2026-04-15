import Foundation

@MainActor
final class InventoryService {
    private struct InventoryMutationBody: Encodable {
        let characterId: String
        let inventoryId: String
    }

    private struct InventorySnapshotResponse: Codable {
        let equipment: [EquipmentInventoryEntry]
        let consumables: [ConsumableInventoryEntry]
        let inventorySlots: Int

        func toItems(
            consumableMapper: (ConsumableInventoryEntry) -> Item?
        ) -> [Item] {
            equipment.map { $0.toItem() } + consumables.compactMap(consumableMapper)
        }
    }

    private struct EquipmentInventoryEntry: Codable {
        let id: String
        let upgradeLevel: Int
        let durability: Int
        let maxDurability: Int
        let isEquipped: Bool
        let equippedSlot: String?
        let rolledStats: [String: Int]?
        let isTwoHanded: Bool?
        let effectiveStats: [String: Int]?
        let item: InventoryItemRecord

        func toItem() -> Item {
            Item(
                id: id,
                itemName: item.itemName,
                itemType: item.itemType,
                rarity: item.rarity,
                itemLevel: item.itemLevel,
                upgradeLevel: upgradeLevel,
                isEquipped: isEquipped,
                equippedSlot: equippedSlot,
                baseStats: item.baseStats,
                rolledStats: rolledStats,
                buyPrice: item.buyPrice,
                sellPrice: item.sellPrice,
                setName: item.setName,
                specialEffect: item.specialEffect,
                uniquePassive: item.uniquePassive,
                durability: durability,
                maxDurability: maxDurability,
                description: item.description,
                catalogId: item.catalogId,
                classRestriction: item.classRestriction,
                imageUrl: item.imageUrl,
                imageKey: item.imageKey,
                quantity: nil,
                consumableType: nil,
                isTwoHanded: isTwoHanded,
                authoritativeEffectiveStats: effectiveStats
            )
        }
    }

    private struct InventoryItemRecord: Codable {
        let itemName: String
        let itemType: ItemType
        let rarity: ItemRarity
        let itemLevel: Int
        let baseStats: [String: Int]?
        let setName: String?
        let specialEffect: String?
        let uniquePassive: String?
        let imageUrl: String?
        let imageKey: String?
        let classRestriction: String?
        let description: String?
        let catalogId: String?
        let buyPrice: Int?
        let sellPrice: Int?
    }

    private struct ConsumableInventoryEntry: Codable {
        let id: String
        let consumableType: String
        let quantity: Int
    }

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Load Inventory

    func loadInventory() async -> [Item] {
        guard let charId = appState.currentCharacter?.id else { return [] }
        do {
            let response: InventorySnapshotResponse = try await APIClient.shared.get(
                APIEndpoints.inventory,
                params: ["character_id": charId]
            )
            appState.currentCharacter?.inventorySlots = response.inventorySlots
            let allItems = response.toItems(consumableMapper: mapConsumableToItem)

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
            appState.showToast("Failed to load inventory", subtitle: "Check connection and try again", type: .error, actionLabel: "Retry") { [weak self] in
                Task { @MainActor in
                    _ = await self?.loadInventory()
                }
            }
            return []
        }
    }

    // MARK: - Equip

    func equip(inventoryId: String) async -> [Item]? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let response: InventorySnapshotResponse = try await APIClient.shared.post(
                APIEndpoints.inventoryEquip,
                body: InventoryMutationBody(characterId: charId, inventoryId: inventoryId)
            )
            // FTUE: mark gear up complete on first equip
            TutorialManager.shared.completeFTUEObjective(.gearUp)
            HapticManager.light()
            appState.currentCharacter?.inventorySlots = response.inventorySlots
            return response.toItems(consumableMapper: mapConsumableToItem)
        } catch let error as APIError {
            if case .clientError(_, let message, _) = error {
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
            let response: InventorySnapshotResponse = try await APIClient.shared.post(
                APIEndpoints.inventoryUnequip,
                body: InventoryMutationBody(characterId: charId, inventoryId: inventoryId)
            )
            HapticManager.light()
            appState.currentCharacter?.inventorySlots = response.inventorySlots
            return response.toItems(consumableMapper: mapConsumableToItem)
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
                HapticManager.light()
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

            // Update character stats from server response (corrects optimistic estimates)
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
            // Don't nil cachedInventory — caller already applied optimistic update.
            // Server confirmed success, so the optimistic state is correct.

            // Bug #10: refresh quest cache in background so the Alchemist
            // (consumable_use) daily quest progress and Claim button update
            // across Hub widgets (QuestRewardWidget, ActiveQuestBanner) and
            // the Daily Quests screen after a consumable use.
            // STALE-WHILE-REVALIDATE: keep existing cachedTypedQuests visible
            // (don't nil it) so dependent widgets don't flash empty during the
            // ~200ms refetch — the background task overwrites on success.
            let appStateRef = appState
            Task { @MainActor in
                // Fire-and-forget: if the refresh fails, the next screen
                // appearance will retry. No UI surface here to show an error.
                _ = try? await QuestService(appState: appStateRef).loadQuests()
            }

            return true
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            case .serverError(_, let message):
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
                HapticManager.light()
                return slots
            }
            return nil
        } catch let error as APIError {
            if case .clientError(_, let message, _) = error {
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

    // MARK: - Consumable Helpers

    /// Maps a consumable inventory entry to an Item for display in the inventory grid.
    private func mapConsumableToItem(_ entry: ConsumableInventoryEntry) -> Item? {
        guard entry.quantity > 0 else { return nil }

        let id = entry.id
        let consumableType = entry.consumableType
        let quantity = entry.quantity
        let canonicalID = ConsumableCatalog.canonicalID(
            consumableType: consumableType,
            catalogId: consumableType,
            imageKey: nil
        )
        let displayName = canonicalID.map(ConsumableCatalog.displayName(for:))
            ?? ConsumableCatalog.displayName(forKnownOrRaw: consumableType)
        let imageKey = ConsumableCatalog.resolvedImageKey(
            consumableType: consumableType,
            catalogId: consumableType,
            imageKey: nil
        )
        let rarity = canonicalID.flatMap(ConsumableCatalog.rarity(for:)) ?? .common

        return Item(
            id: id,
            itemName: displayName,
            itemType: .consumable,
            rarity: rarity,
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
