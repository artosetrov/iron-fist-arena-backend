import Foundation

@MainActor
final class StashService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Load Stash

    /// Fetches all items in the account-level stash.
    func loadStash() async -> StashResponse? {
        do {
            let response = try await APIClient.shared.getRaw(APIEndpoints.stash)
            return parseStashResponse(response)
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

    // MARK: - Parsing

    private func parseStashResponse(_ response: [String: Any]) -> StashResponse? {
        let maxSlots = response["maxSlots"] as? Int ?? 100
        let usedSlots = response["usedSlots"] as? Int ?? 0

        guard let itemsArray = response["items"] as? [[String: Any]] else {
            return StashResponse(items: [], maxSlots: maxSlots, usedSlots: usedSlots)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let flattened = flattenStashItems(itemsArray)
        guard let jsonData = try? JSONSerialization.data(withJSONObject: flattened) else {
            return StashResponse(items: [], maxSlots: maxSlots, usedSlots: usedSlots)
        }

        do {
            let items = try decoder.decode([Item].self, from: jsonData)
            return StashResponse(items: items, maxSlots: maxSlots, usedSlots: usedSlots)
        } catch {
            #if DEBUG
            print("[StashService] decode error: \(error)")
            #endif
            return StashResponse(items: [], maxSlots: maxSlots, usedSlots: usedSlots)
        }
    }

    /// Flattens nested StashItem + Item structure into flat Item dicts.
    /// Backend returns: { id, upgradeLevel, ..., item: { itemName, itemType, ... } }
    /// iOS expects:     { id, upgradeLevel, itemName, itemType, ... }
    private func flattenStashItems(_ items: [[String: Any]]) -> [[String: Any]] {
        items.map { entry in
            var flat = entry
            if let nested = entry["item"] as? [String: Any] {
                for (key, value) in nested {
                    if key == "id" { continue }
                    flat[key] = value
                }
            }
            flat.removeValue(forKey: "item")
            // Merge effectiveStats into flat item
            if let effectiveStats = entry["effectiveStats"] as? [String: Any] {
                flat["effectiveStats"] = effectiveStats
            }
            return flat
        }
    }
}

// MARK: - Stash Response

struct StashResponse {
    let items: [Item]
    let maxSlots: Int
    let usedSlots: Int
}
