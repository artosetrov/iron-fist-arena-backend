import Foundation

@MainActor
final class StashService {
    private struct StashPayload: Codable {
        let items: [StashItemEntry]
        let maxSlots: Int
        let usedSlots: Int

        func toResponse() -> StashResponse {
            StashResponse(
                items: items.map { $0.toItem() },
                maxSlots: maxSlots,
                usedSlots: usedSlots
            )
        }
    }

    private struct StashItemEntry: Codable {
        let id: String
        let upgradeLevel: Int
        let durability: Int
        let maxDurability: Int
        let rolledStats: [String: Int]?
        let effectiveStats: [String: Int]?
        let item: StashCatalogItem

        func toItem() -> Item {
            Item(
                id: id,
                itemName: item.itemName,
                itemType: item.itemType,
                rarity: item.rarity,
                itemLevel: item.itemLevel,
                upgradeLevel: upgradeLevel,
                isEquipped: false,
                equippedSlot: nil,
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
                isTwoHanded: nil,
                authoritativeEffectiveStats: effectiveStats
            )
        }
    }

    private struct StashCatalogItem: Codable {
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

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Load Stash

    /// Fetches all items in the account-level stash.
    func loadStash() async -> StashResponse? {
        do {
            let response: StashPayload = try await APIClient.shared.get(APIEndpoints.stash)
            return response.toResponse()
        } catch {
            #if DEBUG
            print("[StashService] loadStash error: \(error)")
            #endif
            appState.showToast("Failed to load stash", subtitle: "Check connection", type: .error)
            return nil
        }
    }

    // MARK: - Deposit (Inventory → Stash)

    /// Moves an unequipped item from character inventory to the account stash.
    func deposit(equipmentId: String) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let body: [String: Any] = [
                "character_id": charId,
                "equipment_id": equipmentId
            ]
            _ = try await APIClient.shared.postRaw(
                APIEndpoints.stashDeposit,
                body: body
            )
            HapticManager.light()
            return true
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to deposit item", type: .error)
            }
            return false
        } catch {
            appState.showToast("Failed to deposit item", type: .error)
            return false
        }
    }

    // MARK: - Withdraw (Stash → Inventory)

    /// Moves an item from the account stash to the current character's inventory.
    func withdraw(stashItemId: String) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let body: [String: Any] = [
                "character_id": charId,
                "stash_item_id": stashItemId
            ]
            _ = try await APIClient.shared.postRaw(
                APIEndpoints.stashWithdraw,
                body: body
            )
            HapticManager.light()
            return true
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to withdraw item", type: .error)
            }
            return false
        } catch {
            appState.showToast("Failed to withdraw item", type: .error)
            return false
        }
    }

}

// MARK: - Stash Response

struct StashResponse {
    let items: [Item]
    let maxSlots: Int
    let usedSlots: Int
}
