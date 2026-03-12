import SwiftUI

@MainActor @Observable
final class GoldMineViewModel {
    private let appState: AppState
    private let cache: GameDataCache

    var slots: [[String: Any]] = []
    var maxSlots = 3
    var isLoading = false
    var actionSlotId: String?
    var isBuyingSlot = false

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
    }

    var gold: Int { appState.currentCharacter?.gold ?? 0 }
    var gems: Int { appState.currentCharacter?.gems ?? 0 }

    var activeSlots: [[String: Any]] {
        slots.filter { ($0["status"] as? String) != nil }
    }

    // MARK: - Load

    func loadStatus() async {
        // Serve cached data instantly
        if let cached = cache.cachedGoldMine() {
            slots = cached.slots
            maxSlots = cached.maxSlots
        } else {
            isLoading = true
        }

        guard let charId = appState.currentCharacter?.id else {
            isLoading = false
            return
        }

        do {
            let data = try await APIClient.shared.getRaw(
                APIEndpoints.goldMineStatus,
                params: ["character_id": charId]
            )
            slots = data["slots"] as? [[String: Any]] ?? []
            maxSlots = data["max_slots"] as? Int ?? 3
            cache.cacheGoldMine(slots: slots, maxSlots: maxSlots)
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    // MARK: - Start Mining

    func startMining(slotIndex: Int) async {
        guard let charId = appState.currentCharacter?.id else { return }
        actionSlotId = "\(slotIndex)"

        do {
            let data = try await APIClient.shared.postRaw(
                APIEndpoints.goldMineStart,
                body: ["character_id": charId, "slot_index": slotIndex]
            )
            if let updatedSlots = data["slots"] as? [[String: Any]] {
                slots = updatedSlots
            }
            actionSlotId = nil
            appState.showToast("Mining started!", type: .info)
        } catch {
            actionSlotId = nil
            appState.showToast("Failed to start mining", type: .error)
        }
    }

    // MARK: - Collect

    func collect(slotIndex: Int) async {
        guard let charId = appState.currentCharacter?.id else { return }
        actionSlotId = "\(slotIndex)"

        do {
            let data = try await APIClient.shared.postRaw(
                APIEndpoints.goldMineCollect,
                body: ["character_id": charId, "slot_index": slotIndex]
            )
            if let updatedSlots = data["slots"] as? [[String: Any]] {
                slots = updatedSlots
            }
            let collected = data["gold_collected"] as? Int ?? 0
            if let newGold = data["gold"] as? Int {
                appState.currentCharacter?.gold = newGold
            }
            actionSlotId = nil
            appState.showToast("Collected \(collected) gold!", type: .reward)
            appState.invalidateCache("quests")
        } catch {
            actionSlotId = nil
            appState.showToast("Failed to collect", type: .error)
        }
    }

    // MARK: - Boost

    func boost(slotIndex: Int) async {
        guard let charId = appState.currentCharacter?.id else { return }
        actionSlotId = "\(slotIndex)"

        do {
            let data = try await APIClient.shared.postRaw(
                APIEndpoints.goldMineBoost,
                body: ["character_id": charId, "slot_index": slotIndex]
            )
            if let updatedSlots = data["slots"] as? [[String: Any]] {
                slots = updatedSlots
            }
            if let newGems = data["gems"] as? Int {
                appState.currentCharacter?.gems = newGems
            }
            actionSlotId = nil
            appState.showToast("Slot boosted!", type: .info)
        } catch {
            actionSlotId = nil
            appState.showToast("Failed to boost", type: .error)
        }
    }

    // MARK: - Buy Slot

    func buySlot() async {
        guard !isBuyingSlot else { return }
        guard let charId = appState.currentCharacter?.id else { return }
        isBuyingSlot = true
        defer { isBuyingSlot = false }

        do {
            let data = try await APIClient.shared.postRaw(
                APIEndpoints.goldMineBuySlot,
                body: ["character_id": charId]
            )
            if let newMax = data["max_slots"] as? Int {
                maxSlots = newMax
            }
            if let updatedSlots = data["slots"] as? [[String: Any]] {
                slots = updatedSlots
            }
            if let newGems = data["gems"] as? Int {
                appState.currentCharacter?.gems = newGems
            }
            appState.showToast("New mining slot unlocked!", type: .reward)
        } catch {
            appState.showToast("Failed to buy slot", type: .error)
        }
    }

    // MARK: - Helpers

    func slotStatus(_ slot: [String: Any]) -> String {
        slot["status"] as? String ?? "idle"
    }

    func timeRemaining(_ slot: [String: Any]) -> String {
        guard let endStr = slot["ends_at"] as? String else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let endDate = formatter.date(from: endStr) else { return "" }
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 { return "Ready!" }
        let mins = Int(remaining) / 60
        let hrs = mins / 60
        if hrs > 0 { return "\(hrs)h \(mins % 60)m remaining" }
        return "\(mins)m remaining"
    }

    /// Returns mining progress as 0.0–1.0 (0 = just started, 1 = done)
    func miningProgress(_ slot: [String: Any]) -> Double {
        guard let endStr = slot["ends_at"] as? String,
              let startStr = slot["started_at"] as? String else { return 0 }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let endDate = formatter.date(from: endStr),
              let startDate = formatter.date(from: startStr) else { return 0 }
        let total = endDate.timeIntervalSince(startDate)
        guard total > 0 else { return 1 }
        let elapsed = Date().timeIntervalSince(startDate)
        return min(max(elapsed / total, 0), 1)
    }

    /// Number of currently active (mining or ready) slots
    var activeSlotCount: Int {
        slots.filter { ($0["status"] as? String) == "mining" || ($0["status"] as? String) == "ready" }.count
    }
}
