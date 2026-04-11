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
    private var activeActionSlots: Set<Int> = []  // prevents double-tap per slot

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
    }

    // MARK: - Mine Names (canonical — docs/08_prompts/mine-card-prompts.md)

    /// Thematic mine names per slot index. Used instead of "SLOT N" labels.
    static let mineNames: [String] = [
        "Amethyst Cavern",   // 0 — purple
        "Emerald Vein",      // 1 — green
        "Molten Forge",      // 2 — orange
        "Frozen Depths",     // 3 — cyan/ice
        "Blood Quarry",      // 4 — crimson
        "King's Treasury"    // 5 — gold
    ]

    static func mineName(for index: Int) -> String {
        guard index >= 0 && index < mineNames.count else { return "Mine \(index + 1)" }
        return mineNames[index]
    }

    // MARK: - Mining Economics (mirrors backend/src/lib/game/gold-mine.ts)

    /// Average gold reward per 4h session per slot (backend: 40–100, avg ~70).
    static let averageGoldPerSession: Double = 70
    /// Session duration in seconds (4 hours).
    static let sessionDurationSec: Double = 4 * 3600
    /// Average gold per second per actively mining slot (~0.00486).
    static var goldPerSecondPerSlot: Double {
        averageGoldPerSession / sessionDurationSec
    }
    /// Gem drop: 10% chance, 1–3 gems → average ~0.2 gems per session (~4h).
    static var gemsPerSecondPerSlot: Double {
        0.2 / sessionDurationSec
    }

    // MARK: - Live counters (visual-only, server remains authoritative)

    /// Visual gold value for tick-up counter. Re-synced to server on every response.
    var visualGold: Int = 0
    /// Visual gems value for tick-up counter.
    var visualGems: Int = 0
    /// Fractional accumulator so slow rates (1 gold / 200s) can still tick integer coins.
    private var goldAccumulator: Double = 0
    private var gemAccumulator: Double = 0

    var gold: Int { appState.currentCharacter?.gold ?? 0 }
    var gems: Int { appState.currentCharacter?.gems ?? 0 }

    /// Number of slots currently in "mining" status (not ready, not idle).
    var miningSlotCount: Int {
        slots.filter { slotStatus($0) == "mining" }.count
    }

    /// Current gold per hour from active mining slots (for the rate label).
    var currentGoldPerHour: Int {
        Int(Double(miningSlotCount) * Self.goldPerSecondPerSlot * 3600)
    }

    /// Current gems per hour (fractional, so display as 0.0 precision).
    var currentGemsPerHour: Double {
        Double(miningSlotCount) * Self.gemsPerSecondPerSlot * 3600
    }

    /// Sync visual counters to server-authoritative values. Call after any API update.
    func syncVisualCounters() {
        visualGold = gold
        visualGems = gems
        goldAccumulator = 0
        gemAccumulator = 0
    }

    /// Advance visual counters by one tick (called from a Timer in the view).
    /// Returns a `LiveTickDelta` describing how many coins/gems "arrived" this tick
    /// so the view can schedule fly-particles from each active slot.
    func advanceLiveTick(elapsedSec: Double) -> LiveTickDelta {
        let activeCount = miningSlotCount
        guard activeCount > 0 else { return LiveTickDelta(coinsPerSlot: 0, gems: 0) }

        let goldPerSec = Double(activeCount) * Self.goldPerSecondPerSlot
        goldAccumulator += goldPerSec * elapsedSec

        let gemPerSec = Double(activeCount) * Self.gemsPerSecondPerSlot
        gemAccumulator += gemPerSec * elapsedSec

        // Cap visual counter against server ceiling (never show more than real).
        let maxVisualGold = gold
        let maxVisualGems = gems

        var coinsEmittedPerSlot = 0
        if goldAccumulator >= 1.0 {
            let coinsTotal = Int(goldAccumulator.rounded(.down))
            goldAccumulator -= Double(coinsTotal)
            // Split across slots (coin flies from each active mine).
            coinsEmittedPerSlot = max(1, coinsTotal / max(1, activeCount))
            visualGold = min(maxVisualGold, visualGold + coinsTotal)
        }

        var gemsEmitted = 0
        if gemAccumulator >= 1.0 {
            gemsEmitted = Int(gemAccumulator.rounded(.down))
            gemAccumulator -= Double(gemsEmitted)
            visualGems = min(maxVisualGems, visualGems + gemsEmitted)
        }

        return LiveTickDelta(coinsPerSlot: coinsEmittedPerSlot, gems: gemsEmitted)
    }

    struct LiveTickDelta {
        let coinsPerSlot: Int
        let gems: Int
    }

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
            syncVisualCounters()
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    // MARK: - Start Mining

    func startMining(slotIndex: Int) async {
        guard !activeActionSlots.contains(slotIndex) else { return }
        guard let charId = appState.currentCharacter?.id else { return }
        activeActionSlots.insert(slotIndex)

        // Optimistic UI — update slot to "mining" instantly
        let savedSlots = slots
        let now = ISO8601DateFormatter().string(from: Date())
        let endsAt = ISO8601DateFormatter().string(from: Date().addingTimeInterval(4 * 3600))

        withAnimation(MotionConstants.smooth) {
            if slotIndex < slots.count {
                var slot = slots[slotIndex]
                slot["status"] = "mining"
                slot["started_at"] = now
                slot["ends_at"] = endsAt
                slots[slotIndex] = slot
            }
            actionSlotId = nil
        }
        HapticManager.medium()
        appState.showToast("Mining started!", type: .info)

        // Background API call — update with real server values
        do {
            let data = try await APIClient.shared.postRaw(
                APIEndpoints.goldMineStart,
                body: ["character_id": charId, "slot_index": slotIndex]
            )
            if let updatedSlots = data["slots"] as? [[String: Any]] {
                withAnimation(MotionConstants.smooth) {
                    slots = updatedSlots
                }
            }
        } catch {
            // Revert on failure
            withAnimation {
                slots = savedSlots
            }
            appState.showToast("Failed to start mining", subtitle: "Check connection and try again", type: .error)
        }
        activeActionSlots.remove(slotIndex)
    }

    // MARK: - Collect

    func collect(slotIndex: Int) async {
        guard !activeActionSlots.contains(slotIndex) else { return }
        guard let charId = appState.currentCharacter?.id else { return }
        activeActionSlots.insert(slotIndex)

        // Optimistic: update UI immediately
        let savedSlots = slots
        let savedGold = appState.currentCharacter?.gold
        // Estimate collected gold from slot data
        let estimatedGold: Int = {
            guard let slot = slots[safe: slotIndex] else { return 0 }
            return slot["gold_accumulated"] as? Int ?? slot["gold_mined"] as? Int ?? 50
        }()

        withAnimation(MotionConstants.smooth) {
            // Mark slot idle until server confirms and returns fresh session data.
            // Previously we set status = "mining" but kept old started_at/ends_at,
            // which made the progress bar render stuck at 100%.
            if slotIndex < slots.count {
                var slot = slots[slotIndex]
                slot["status"] = "idle"
                slot["started_at"] = nil
                slot["ends_at"] = nil
                slot["gold_accumulated"] = 0
                slot["gold_mined"] = 0
                slots[slotIndex] = slot
            }
            appState.currentCharacter?.gold = (savedGold ?? 0) + estimatedGold
            actionSlotId = nil
        }
        syncVisualCounters()
        HapticManager.success()

        // Background: actual API call
        do {
            let data = try await APIClient.shared.postRaw(
                APIEndpoints.goldMineCollect,
                body: ["character_id": charId, "slot_index": slotIndex]
            )
            // Update with real server values
            withAnimation(MotionConstants.smooth) {
                if let updatedSlots = data["slots"] as? [[String: Any]] {
                    slots = updatedSlots
                }
                if let newGold = data["gold"] as? Int {
                    appState.currentCharacter?.gold = newGold
                }
                if let newGems = data["gems"] as? Int {
                    appState.currentCharacter?.gems = newGems
                }
            }
            syncVisualCounters()
            appState.invalidateCache("quests")
        } catch {
            // Revert on failure
            withAnimation {
                slots = savedSlots
                appState.currentCharacter?.gold = savedGold ?? 0
            }
            appState.showToast("Failed to collect", subtitle: "Check connection and try again", type: .error)
        }
        activeActionSlots.remove(slotIndex)
    }

    // MARK: - Boost

    func boost(slotIndex: Int) {
        guard !activeActionSlots.contains(slotIndex) else { return }
        guard let charId = appState.currentCharacter?.id else { return }
        activeActionSlots.insert(slotIndex)
        actionSlotId = "\(slotIndex)"

        // Optimistic: deduct gems + show boosted
        let prevGems = appState.currentCharacter?.gems ?? 0
        let boostCost = 10
        appState.currentCharacter?.gems = max(0, prevGems - boostCost)
        HapticManager.success()
        appState.showToast("Slot boosted!", type: .info)

        // Fire API in background
        Task { [weak self] in
            guard let self else { return }
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
                syncVisualCounters()
            } catch {
                // Revert gems on failure
                appState.currentCharacter?.gems = prevGems
                appState.showToast("Failed to boost", subtitle: "Check your gem balance", type: .error)
            }
            actionSlotId = nil
            activeActionSlots.remove(slotIndex)
        }
    }

    // MARK: - Buy Slot

    func buySlot() {
        guard !isBuyingSlot else { return }
        guard let charId = appState.currentCharacter?.id else { return }
        isBuyingSlot = true

        // Optimistic: deduct gems + increase slot count instantly
        let prevGems = appState.currentCharacter?.gems ?? 0
        let prevMaxSlots = maxSlots
        let prevSlots = slots
        let slotCost = 50
        appState.currentCharacter?.gems = max(0, prevGems - slotCost)
        maxSlots += 1
        // Add an idle slot placeholder so UI shows the new slot immediately
        slots.append(["status": "idle", "slot_index": maxSlots - 1])
        HapticManager.success()
        appState.showToast("New mining slot unlocked!", type: .reward)

        // Fire API in background — server response overwrites with authoritative values
        Task { [weak self] in
            guard let self else { return }
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
            } catch {
                // Revert on failure
                appState.currentCharacter?.gems = prevGems
                maxSlots = prevMaxSlots
                slots = prevSlots
                appState.showToast("Failed to buy slot", subtitle: "Check your gem balance", type: .error)
            }
            isBuyingSlot = false
        }
    }

    // MARK: - Helpers

    func slotStatus(_ slot: [String: Any]) -> String {
        let raw = slot["status"] as? String ?? "idle"
        // Client-side upgrade: if mining but time has elapsed, show as "ready"
        if raw == "mining", let endStr = slot["ends_at"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let endDate = formatter.date(from: endStr), endDate <= Date() {
                return "ready"
            }
        }
        return raw
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
