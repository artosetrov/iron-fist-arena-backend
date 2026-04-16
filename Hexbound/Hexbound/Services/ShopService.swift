import Foundation

private struct ShopItemsResponse: Codable {
    let items: [ShopItem]?
    let shopItems: [ShopItem]?
    let characterLevel: Int?
}

private struct ShopCurrencySnapshot: Decodable {
    let gold: Int?
    let gems: Int?
}

private struct ShopBuyRequest: Encodable {
    let characterId: String
    let itemCatalogId: String
}

private struct ShopBuyResponse: Decodable {
    let gold: Int?
    let gems: Int?
    let character: ShopCurrencySnapshot?
}

private struct ShopBuyConsumableRequest: Encodable {
    let characterId: String
    let consumableType: String
    let quantity: Int
}

private struct ShopBuyConsumableResponse: Decodable {
    let gold: Int?
    let gems: Int?
    let character: ShopCurrencySnapshot?
}

private struct ShopBuyGemsRequest: Encodable {
    let characterId: String
    let catalogId: String
}

private struct ShopBuyGemsResponse: Decodable {
    let gold: Int
    let gems: Int
}

private struct ShopRepairRequest: Encodable {
    let characterId: String
    let inventoryId: String
}

private struct ShopRepairItemSnapshot: Decodable {
    let durability: Int
    let maxDurability: Int
}

private struct ShopRepairResponse: Decodable {
    let inventoryItem: ShopRepairItemSnapshot
    let repairCost: Int
    let gold: Int?
    let gems: Int?
    let character: ShopCurrencySnapshot?
}

private struct ShopUpgradeRequest: Encodable {
    let characterId: String
    let inventoryId: String
    let useProtection: Bool
}

private struct ShopUpgradeResponse: Decodable {
    let success: Bool
    let newLevel: Int
    let levelLost: Bool
    let protectionUsed: Bool
    let upgradeCost: Int
    let gold: Int?
    let gems: Int?
    let character: ShopCurrencySnapshot?
}

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
            let response: ShopItemsResponse = try await APIClient.shared.get(
                APIEndpoints.shopItems,
                params: ["character_id": charId]
            )
            return response.items ?? response.shopItems ?? []
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
            let response: ShopBuyResponse = try await APIClient.shared.post(
                APIEndpoints.shopBuy,
                body: ShopBuyRequest(characterId: charId, itemCatalogId: catalogId)
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
            let response: ShopBuyConsumableResponse = try await APIClient.shared.post(
                APIEndpoints.shopBuyConsumable,
                body: ShopBuyConsumableRequest(
                    characterId: charId,
                    consumableType: consumableType,
                    quantity: quantity
                )
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
            let response: ShopBuyGemsResponse = try await APIClient.shared.post(
                APIEndpoints.shopBuyGems,
                body: ShopBuyGemsRequest(characterId: charId, catalogId: catalogId)
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
            let response: ShopRepairResponse = try await APIClient.shared.post(
                APIEndpoints.shopRepair,
                body: ShopRepairRequest(characterId: charId, inventoryId: inventoryId)
            )
            let (gold, gems) = resolvedCurrency(fromGold: response.gold, gems: response.gems, nested: response.character)
            applyCharacterCurrency(gold: gold, gems: gems)
            return RepairResult(
                repairCost: response.repairCost, gold: gold, gems: gems,
                newDurability: response.inventoryItem.durability,
                maxDurability: response.inventoryItem.maxDurability
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
            let response: ShopUpgradeResponse = try await APIClient.shared.post(
                APIEndpoints.shopUpgrade,
                body: ShopUpgradeRequest(
                    characterId: charId,
                    inventoryId: inventoryId,
                    useProtection: useProtection
                )
            )
            let (gold, gems) = resolvedCurrency(fromGold: response.gold, gems: response.gems, nested: response.character)
            applyCharacterCurrency(gold: gold, gems: gems)
            appState.cachedInventory = nil // upgrade changed item stats
            return UpgradeResult(
                success: response.success, newLevel: response.newLevel, levelLost: response.levelLost,
                protectionUsed: response.protectionUsed, upgradeCost: response.upgradeCost,
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
    private func updateCharacter(from response: ShopBuyResponse) {
        let (gold, gems) = resolvedCurrency(fromGold: response.gold, gems: response.gems, nested: response.character)
        applyCharacterCurrency(gold: gold, gems: gems)
        appState.cachedInventory = nil
    }

    private func updateCharacter(from response: ShopBuyConsumableResponse) {
        let (gold, gems) = resolvedCurrency(fromGold: response.gold, gems: response.gems, nested: response.character)
        applyCharacterCurrency(gold: gold, gems: gems)
        appState.cachedInventory = nil
    }

    private func updateCharacter(from response: ShopBuyGemsResponse) {
        applyCharacterCurrency(gold: response.gold, gems: response.gems)
        appState.cachedInventory = nil
    }

    private func resolvedCurrency(
        fromGold gold: Int?,
        gems: Int?,
        nested: ShopCurrencySnapshot?
    ) -> (gold: Int, gems: Int) {
        let resolvedGold = nested?.gold ?? gold ?? appState.currentCharacter?.gold ?? 0
        let resolvedGems = nested?.gems ?? gems ?? appState.currentCharacter?.gems ?? 0
        return (resolvedGold, resolvedGems)
    }

    private func applyCharacterCurrency(gold: Int, gems: Int) {
        if var char = appState.currentCharacter {
            char.gold = gold
            char.gems = gems
            appState.currentCharacter = char
        }
    }
}
