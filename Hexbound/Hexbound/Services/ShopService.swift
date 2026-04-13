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
            // BUG-58: server incremented Big Spender (gold_spent) quest — refresh.
            refreshDailyQuestsAfterGoldSpend()
            return true
        } catch let error as APIError {
            if case .clientError(_, let message, _) = error {
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
            // BUG-58: consumable purchase now tracks gold_spent on the server —
            // invalidate the quest cache so Big Spender counter updates live.
            refreshDailyQuestsAfterGoldSpend()
            return true
        } catch let error as APIError {
            if case .clientError(_, let message, _) = error {
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

    /// Buys a gem pack by its catalog id (`gem_pack_small`/`medium`/`large`).
    /// Price and gems amount are resolved server-side from the shared
    /// `gem-packs.ts` table — clients never send the gold cost.
    func buyGems(catalogId: String) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let body: [String: Any] = [
                "character_id": charId,
                "catalog_id": catalogId
            ]
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.shopBuyGems,
                body: body
            )
            // Flat response: { gold, gems, goldSpent, gemsReceived, catalogId }
            updateCharacter(from: response)
            return true
        } catch let error as APIError {
            if case .clientError(_, let message, _) = error {
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
            // BUG-58: legacy potion purchase also tracks gold_spent now.
            refreshDailyQuestsAfterGoldSpend()
            return true
        } catch {
            appState.showToast("Purchase failed", subtitle: "Check your gold balance and try again", type: .error)
            return false
        }
    }

    // MARK: - Daily Quest Cache Invalidation

    /// BUG-58 (QA 2026-04-10): After any gold-spending shop action, invalidate
    /// the typed quest cache and kick off a background reload so the Big Spender
    /// (`gold_spent`) daily quest progress and Claim state propagate to every
    /// widget reading from `appState.cachedTypedQuests` (Hub banner, Daily
    /// Quests screen, ActiveQuestBanner). Same pattern as Bug #10 fix in
    /// InventoryService for consumable_use.
    private func refreshDailyQuestsAfterGoldSpend() {
        // STALE-WHILE-REVALIDATE: keep the previously cached quest list on
        // screen so Hub banner / ActiveQuestBanner don't blink to an empty
        // state during the 150-400ms refetch. The background task will
        // overwrite `cachedTypedQuests` with fresh data when it lands.
        // (Pre-2026-04-13 this set `cachedTypedQuests = nil` which caused
        //  visible quest-list flicker on every shop purchase.)
        let appStateRef = appState
        Task { @MainActor in
            _ = try? await QuestService(appState: appStateRef).loadQuests()
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
            // Handle nested `{ character: { gold, gems } }` shape from /shop/repair
            let repairCurrency = (response["character"] as? [String: Any]) ?? response
            let gold = repairCurrency["gold"] as? Int ?? (appState.currentCharacter?.gold ?? 0)
            let gems = repairCurrency["gems"] as? Int ?? (appState.currentCharacter?.gems ?? 0)
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
            if case .clientError(_, let message, _) = error {
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
            // Handle nested `{ character: { gold, gems } }` shape from /shop/upgrade
            let upgradeCurrency = (response["character"] as? [String: Any]) ?? response
            let gold = upgradeCurrency["gold"] as? Int ?? (appState.currentCharacter?.gold ?? 0)
            let gems = upgradeCurrency["gems"] as? Int ?? (appState.currentCharacter?.gems ?? 0)
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
            if case .clientError(_, let message, _) = error {
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

    /// Reads `gold`/`gems` from the server response and updates character state.
    /// Handles two response shapes:
    ///   - Flat:   `{ gold, gems, ... }`  (buy-gems, offers)
    ///   - Nested: `{ character: { gold, gems }, ... }`  (buy, buy-consumable, repair, upgrade)
    private func updateCharacter(from response: [String: Any]) {
        // Try nested shape first (most shop endpoints), fall back to flat
        let currencySource: [String: Any]
        if let nested = response["character"] as? [String: Any] {
            currencySource = nested
        } else {
            currencySource = response
        }

        if var char = appState.currentCharacter {
            if let gold = currencySource["gold"] as? Int { char.gold = gold }
            if let gems = currencySource["gems"] as? Int { char.gems = gems }
            appState.currentCharacter = char
            // Invalidate inventory cache since items changed (new purchase)
            appState.cachedInventory = nil
        }
    }
}
