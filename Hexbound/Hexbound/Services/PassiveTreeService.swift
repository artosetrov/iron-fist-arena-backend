//
//  PassiveTreeService.swift
//  Hexbound
//
//  API client for the passive skill tree (Talents tab).
//  Wraps /api/passives/{tree,character,unlock,respec}.
//

import Foundation

@MainActor
final class PassiveTreeService {
    private struct UnlockBody: Encodable {
        let characterId: String
        let nodeId: String
    }

    private struct RespecBody: Encodable {
        let characterId: String
    }

    private struct ActiveSlotMutationBody: Encodable {
        let characterId: String
        let slotIndex: Int
        let nodeId: String?
        let consumableType: String?
    }

    private struct ActiveSlotBatchSaveBody: Encodable {
        let characterId: String
        let slots: [ActiveSlotLoadoutEntry]
    }

    private struct MutationSuccessResponse: Decodable {
        let success: Bool
    }

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Catalog (tree definition)

    /// Fetches the full passive-tree catalog (nodes + connections). Backend caches 10 min.
    func loadTree() async -> PassiveTreeResponse? {
        do {
            let response: PassiveTreeResponse = try await APIClient.shared.get(APIEndpoints.passivesTree)
            return response
        } catch {
            #if DEBUG
            print("[PassiveTreeService] loadTree error: \(error)")
            #endif
            appState.showToast("Failed to load talent tree", subtitle: "Check connection", type: .error)
            return nil
        }
    }

    // MARK: - Character unlocks

    /// Fetches the current character's unlocked nodes + available points. Backend caches 5 min.
    func loadCharacterPassives(characterId: String) async -> CharacterPassiveResponse? {
        do {
            let response: CharacterPassiveResponse = try await APIClient.shared.get(
                APIEndpoints.passivesCharacter,
                params: ["character_id": characterId]
            )
            return response
        } catch {
            #if DEBUG
            print("[PassiveTreeService] loadCharacterPassives error: \(error)")
            #endif
            appState.showToast("Failed to load talents", subtitle: "Check connection", type: .error)
            return nil
        }
    }

    // MARK: - Unlock node

    /// Spends one or more passive points to unlock a node. Server validates connectivity + cost.
    func unlock(characterId: String, nodeId: String) async -> PassiveUnlockResponse? {
        do {
            let response: PassiveUnlockResponse = try await APIClient.shared.post(
                APIEndpoints.passivesUnlock,
                body: UnlockBody(characterId: characterId, nodeId: nodeId)
            )
            HapticManager.light()
            return response
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to unlock talent", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Failed to unlock talent", type: .error)
            return nil
        }
    }

    // MARK: - Active Slots (Interactive Combat v1)

    /// Fetches equipped active-skill slots for a character.
    func loadActiveSlots(characterId: String) async -> ActiveSlotsResponse? {
        do {
            let response: ActiveSlotsResponse = try await APIClient.shared.get(
                APIEndpoints.passivesActiveSlots,
                params: ["character_id": characterId]
            )
            return response
        } catch {
            #if DEBUG
            print("[PassiveTreeService] loadActiveSlots error: \(error)")
            #endif
            // Silent fail — feature degrades gracefully if endpoint unavailable.
            return nil
        }
    }

    /// Equips an unlocked activatable node into the given 0-based slot.
    /// Server enforces: node is activatable + unlocked + class-allowed.
    @discardableResult
    func equipActiveSlot(characterId: String, slotIndex: Int, nodeId: String) async -> Bool {
        do {
            let _: MutationSuccessResponse = try await APIClient.shared.post(
                APIEndpoints.passivesActiveSlots,
                body: ActiveSlotMutationBody(
                    characterId: characterId,
                    slotIndex: slotIndex,
                    nodeId: nodeId,
                    consumableType: nil
                )
            )
            HapticManager.light()
            return true
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to equip skill", type: .error)
            }
            return false
        } catch {
            appState.showToast("Failed to equip skill", type: .error)
            return false
        }
    }

    /// Equips a health potion into a slot (Phase 4.B). Server enforces:
    /// max-1-consumable-per-loadout + consumable_type is in allow-list.
    @discardableResult
    func equipConsumableSlot(characterId: String, slotIndex: Int, consumableType: String) async -> Bool {
        do {
            let _: MutationSuccessResponse = try await APIClient.shared.post(
                APIEndpoints.passivesActiveSlots,
                body: ActiveSlotMutationBody(
                    characterId: characterId,
                    slotIndex: slotIndex,
                    nodeId: nil,
                    consumableType: consumableType
                )
            )
            HapticManager.light()
            return true
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to equip potion", type: .error)
            }
            return false
        } catch {
            appState.showToast("Failed to equip potion", type: .error)
            return false
        }
    }

    /// Clears the given slot.
    @discardableResult
    func clearActiveSlot(characterId: String, slotIndex: Int) async -> Bool {
        do {
            // APIClient.delete() doesn't take params — embed in the path.
            let path = "\(APIEndpoints.passivesActiveSlots)?character_id=\(characterId)&slot_index=\(slotIndex)"
            try await APIClient.shared.delete(path)
            return true
        } catch {
            appState.showToast("Failed to clear slot", type: .error)
            return false
        }
    }

    /// Atomic batch save — commits all 3 slots in one server transaction.
    /// Preferred over per-slot POST from the Active Skill Picker so the server
    /// never observes a partially-updated loadout.
    ///
    /// `slots` MUST contain exactly 3 entries covering slot_index 0/1/2; empty
    /// slots are represented via `ActiveSlotLoadoutEntry.empty(slotIndex:)`.
    @discardableResult
    func saveLoadout(characterId: String, slots: [ActiveSlotLoadoutEntry]) async -> Bool {
        do {
            let _: MutationSuccessResponse = try await APIClient.shared.post(
                APIEndpoints.passivesActiveSlotsBatch,
                body: ActiveSlotBatchSaveBody(characterId: characterId, slots: slots)
            )
            HapticManager.light()
            return true
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to save loadout", type: .error)
            }
            return false
        } catch {
            appState.showToast("Failed to save loadout", type: .error)
            return false
        }
    }

    // MARK: - Unlock premium (4th) active slot

    /// Unlocks the 4th active-skill slot. Flat gem cost on server.
    /// Returns the new `maxSlots` and remaining gems on success.
    func unlockPremiumSlot(characterId: String) async -> PremiumSlotUnlockResponse? {
        do {
            let response: PremiumSlotUnlockResponse = try await APIClient.shared.post(
                APIEndpoints.passivesActiveSlotsUnlockPremium,
                body: RespecBody(characterId: characterId)
            )
            HapticManager.success()
            return response
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to unlock slot", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Failed to unlock slot", type: .error)
            return nil
        }
    }

    // MARK: - Respec

    /// Refunds all points, deletes all unlocked nodes, spends RESPEC_GEM_COST gems.
    func respec(characterId: String) async -> PassiveRespecResponse? {
        do {
            let decoded: PassiveRespecResponse = try await APIClient.shared.post(
                APIEndpoints.passivesRespec,
                body: RespecBody(characterId: characterId)
            )
            HapticManager.medium()
            return decoded
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message, _):
                appState.showToast(message, type: .error)
            default:
                appState.showToast("Failed to respec talents", type: .error)
            }
            return nil
        } catch {
            appState.showToast("Failed to respec talents", type: .error)
            return nil
        }
    }
}
