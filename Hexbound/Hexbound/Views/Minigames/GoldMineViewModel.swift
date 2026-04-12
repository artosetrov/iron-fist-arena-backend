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

    // MARK: - Mini-game / Shaft state (Variant D)

    /// Active expedition shaft, if any. Nil when the player must pick one.
    var activeShaft: ActiveShaft?
    /// Pending mini-game session. Variant D Phase 2: opened per slot via
    /// `startSlotMinigame(slotIndex:)`. When non-nil the view presents
    /// `GoldMineMiniGameView` as a fullScreenCover.
    var pendingMinigameSession: MinigameSessionInfo?
    /// True while a /slot-minigame/start call is in flight — blocks the UI
    /// from double-opening the bonus cover.
    var isStartingSlotMinigame: Bool = false
    /// Unlocked shaft keys, exposed so the picker sheet can filter rows.
    var unlockedShafts: [ShaftKey] = []
    /// True when the backend responded with `needs_shaft_pick` and the view
    /// should present the picker sheet.
    var showShaftPicker: Bool = false
    /// Tracks which flow triggered the shaft picker so `pickShaft` can route
    /// back to the correct function. When `nil`, defaults to collectAll.
    private var shaftPickerSlotIndex: Int?
    /// Set after /minigame-bonus responds with `shaft_completed: true`.
    /// The view renders `ShaftClearedOverlay` while this is non-nil.
    var clearedShaftKey: ShaftKey?
    /// Prevents concurrent /collect-all calls.
    var isCollectingAll: Bool = false

    /// Current gold-mine slot level — proxied from `maxSlots` (the number of
    /// slots the player has unlocked). Used by the picker sheet to label
    /// locked rows. Server remains authoritative on actual shaft gating.
    var goldMineSlots: Int { maxSlots }

    /// Number of slots whose server-side status is "ready" (timer elapsed +
    /// backend confirmed). Used to decide whether to show the Collect All CTA.
    var readySlotsCount: Int {
        slots.filter { slotStatus($0) == "ready" }.count
    }

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
    }

    // MARK: - Per-Slot Statistics (aggregated from backend)

    /// Parsed stats per slot index. Populated on /status response.
    struct SlotStats {
        let totalGoldMined: Int
        let sessionsCompleted: Int
        let bestHaul: Int
        let currentStreak: Int
    }

    /// Returns parsed stats for the given slot, or nil if not available.
    func slotStats(at index: Int) -> SlotStats? {
        guard index < slots.count else { return nil }
        guard let statsDict = slots[index]["stats"] as? [String: Any] else { return nil }
        return SlotStats(
            totalGoldMined: statsDict["total_gold_mined"] as? Int ?? 0,
            sessionsCompleted: statsDict["sessions_completed"] as? Int ?? 0,
            bestHaul: statsDict["best_haul"] as? Int ?? 0,
            currentStreak: statsDict["current_streak"] as? Int ?? 0
        )
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

    // MARK: - Collect All (Variant D Phase 2 — played slots only)

    /// Drain all ready AND played slots in one call. Unplayed ready slots
    /// are left behind — the player must open their per-slot bonus minigame
    /// via `startSlotMinigame(slotIndex:)` first.
    ///
    /// Branches:
    ///   - `needs_shaft_pick` → sets `showShaftPicker = true`
    ///   - 409 `NO_PLAYABLE_SLOTS` → toast + auto-open minigame on the
    ///     first unplayed ready slot, so the player flows straight into it
    ///   - success → update slots, gold, gems, active shaft
    func collectAll(pickedShaftKey: ShaftKey? = nil) async {
        guard !isCollectingAll else { return }
        guard let charId = appState.currentCharacter?.id else { return }
        isCollectingAll = true
        defer { isCollectingAll = false }

        var body: [String: Any] = ["character_id": charId]
        if let pickedShaftKey {
            body["picked_shaft_key"] = pickedShaftKey.rawValue
        }

        do {
            let data = try await APIClient.shared.postRaw(
                APIEndpoints.goldMineCollectAll,
                body: body
            )

            // Branch 1: server wants us to show the picker.
            if let needs = data["needs_shaft_pick"] as? Bool, needs {
                let unlockedRaw = (data["unlocked_shafts"] as? [String]) ?? []
                unlockedShafts = unlockedRaw.compactMap { ShaftKey(rawValue: $0) }
                shaftPickerSlotIndex = nil  // collectAll context
                showShaftPicker = true
                return
            }

            // Branch 2: success — update slots, gold, active shaft.
            if let updatedSlots = data["slots"] as? [[String: Any]] {
                withAnimation(MotionConstants.smooth) { slots = updatedSlots }
            }
            if let newGold = data["gold"] as? Int {
                appState.currentCharacter?.gold = newGold
            }
            if let newGems = data["gems"] as? Int {
                appState.currentCharacter?.gems = newGems
            }
            syncVisualCounters()
            appState.invalidateCache("quests")

            // Active shaft — may be nil if this cycle cleared the shaft.
            if let shaftDict = data["active_shaft"] as? [String: Any],
               let keyRaw = shaftDict["key"] as? String,
               let key = ShaftKey(rawValue: keyRaw),
               let progress = shaftDict["progress"] as? Int,
               let total = shaftDict["total"] as? Int {
                let previousKey = activeShaft?.key
                let nextShaft = ActiveShaft(key: key, progress: progress, total: total)
                activeShaft = nextShaft
                // If the shaft key flipped under us mid-cycle, treat as
                // completion celebration for the previous shaft.
                if let previousKey, previousKey != key {
                    clearedShaftKey = previousKey
                }
            } else {
                // Shaft cleared this cycle — remember it for the overlay,
                // reset active so the picker opens on next call.
                if let previousKey = activeShaft?.key {
                    clearedShaftKey = previousKey
                }
                activeShaft = nil
            }

            HapticManager.success()
        } catch let apiError as APIError {
            // NO_PLAYABLE_SLOTS → server returns 409 with payload telling us
            // which slots are ready-but-unplayed. Auto-route the player into
            // the first one's bonus minigame so the flow stays one-tap.
            if apiError.statusCode == 409,
               let payload = apiError.responsePayload,
               let code = payload["code"] as? String,
               code == "NO_PLAYABLE_SLOTS" {
                // Keep the slots snapshot the server sent so the board
                // reflects reality.
                if let updatedSlots = payload["slots"] as? [[String: Any]] {
                    withAnimation(MotionConstants.smooth) { slots = updatedSlots }
                }
                let unplayed = (payload["unplayed_ready_slot_indices"] as? [Int]) ?? []
                if let firstUnplayed = unplayed.first {
                    appState.showToast(
                        "Finish the bonus round",
                        subtitle: "Play the bonus on a ready slot before collecting.",
                        type: .info
                    )
                    await startSlotMinigame(slotIndex: firstUnplayed)
                } else {
                    appState.showToast(
                        "No playable slots",
                        subtitle: "Play a slot's bonus round to enable collect.",
                        type: .info
                    )
                }
                return
            }
            appState.showToast(
                "Failed to collect",
                subtitle: "Check connection and try again",
                type: .error
            )
        } catch {
            appState.showToast(
                "Failed to collect",
                subtitle: "Check connection and try again",
                type: .error
            )
        }
    }

    // MARK: - Per-Slot Bonus Minigame (Variant D Phase 2)

    /// Opens a per-slot bonus minigame session. Idempotent on the server
    /// side — if a session is already in flight it comes back as-is.
    /// Sets `pendingMinigameSession` on success so the view presents the
    /// fullScreenCover.
    func startSlotMinigame(slotIndex: Int, pickedShaftKey: ShaftKey? = nil) async {
        guard !isStartingSlotMinigame else { return }
        guard let charId = appState.currentCharacter?.id else { return }
        isStartingSlotMinigame = true
        defer { isStartingSlotMinigame = false }

        var body: [String: Any] = [
            "character_id": charId,
            "slot_index": slotIndex,
        ]
        if let pickedShaftKey {
            body["picked_shaft_key"] = pickedShaftKey.rawValue
        }

        do {
            let data = try await APIClient.shared.postRaw(
                APIEndpoints.goldMineSlotMinigameStart,
                body: body
            )

            // Shaft picker branch — remember which slot triggered it so
            // pickShaft routes back to startSlotMinigame (not collectAll).
            if let needs = data["needs_shaft_pick"] as? Bool, needs {
                let unlockedRaw = (data["unlocked_shafts"] as? [String]) ?? []
                unlockedShafts = unlockedRaw.compactMap { ShaftKey(rawValue: $0) }
                shaftPickerSlotIndex = slotIndex
                showShaftPicker = true
                return
            }

            if let updatedSlots = data["slots"] as? [[String: Any]] {
                withAnimation(MotionConstants.smooth) { slots = updatedSlots }
            }
            if let shaftDict = data["active_shaft"] as? [String: Any],
               let keyRaw = shaftDict["key"] as? String,
               let key = ShaftKey(rawValue: keyRaw),
               let progress = shaftDict["progress"] as? Int,
               let total = shaftDict["total"] as? Int {
                activeShaft = ActiveShaft(key: key, progress: progress, total: total)
            }

            if let sessionDict = data["minigame_session"] as? [String: Any],
               let session = Self.decodeMinigameSession(from: sessionDict) {
                pendingMinigameSession = session
                HapticManager.medium()
            }
        } catch {
            appState.showToast(
                "Failed to open bonus round",
                subtitle: "Check connection and try again",
                type: .error
            )
        }
    }

    /// Applies the raw response dict from /slot-minigame/submit. The view
    /// calls this via its `onFinish` callback once the 15s round ends or
    /// the player skips. No shaft update happens here — shaft progress is
    /// owned by /collect-all and /collect.
    func applySlotMinigameResult(_ data: [String: Any]) {
        let bonusGold = (data["bonus_gold"] as? Int) ?? 0
        let bonusGems = (data["bonus_gems"] as? Int) ?? 0

        withAnimation(MotionConstants.smooth) {
            if let newGold = data["gold"] as? Int {
                appState.currentCharacter?.gold = newGold
            }
            if let newGems = data["gems"] as? Int {
                appState.currentCharacter?.gems = newGems
            }
            if let updatedSlots = data["slots"] as? [[String: Any]] {
                slots = updatedSlots
            }
            pendingMinigameSession = nil
        }
        syncVisualCounters()

        if bonusGold > 0 || bonusGems > 0 {
            let parts: [String] = [
                bonusGold > 0 ? "+\(bonusGold) gold" : nil,
                bonusGems > 0 ? "+\(bonusGems) gem" : nil,
            ].compactMap { $0 }
            appState.showToast(
                "Bonus secured!",
                subtitle: parts.joined(separator: " · "),
                type: .reward
            )
        }
    }

    /// Slot dict accessor — true once the per-slot bonus minigame has been
    /// completed (server-side `minigame_played_at != null`).
    func isSlotMinigamePlayed(_ slot: [String: Any]) -> Bool {
        return (slot["minigame_played"] as? Bool) ?? false
    }

    /// Slot dict accessor — true when a minigame session is currently in
    /// flight for this slot (player backgrounded mid-round).
    func hasInFlightMinigameSession(_ slot: [String: Any]) -> Bool {
        guard let id = slot["minigame_session_id"] as? String else { return false }
        return !id.isEmpty
    }

    /// Called by `ShaftPickerSheet` when the player confirms a shaft. Dismisses
    /// the sheet and routes back to whichever flow triggered the picker:
    /// - `shaftPickerSlotIndex != nil` → re-enter `startSlotMinigame` so the
    ///   bonus round opens directly after shaft selection.
    /// - `shaftPickerSlotIndex == nil` → re-enter `collectAll` (Collect All flow).
    func pickShaft(_ key: ShaftKey) {
        let slotIndex = shaftPickerSlotIndex
        shaftPickerSlotIndex = nil
        showShaftPicker = false
        Task {
            if let slotIndex {
                await startSlotMinigame(slotIndex: slotIndex, pickedShaftKey: key)
            } else {
                await collectAll(pickedShaftKey: key)
            }
        }
    }

    /// Called by `GoldMineMiniGameView` via its `onFinish` callback once the
    /// player completes (or skips) the 15s round. Server is authoritative —
    /// this just wires the bonus into local state.
    func applyBonusResult(_ result: MinigameBonusResult) {
        // Capture the shaft key BEFORE we clear the pending session — the
        // overlay needs it to render the cleared banner.
        let sessionShaftKey = pendingMinigameSession?.shaftKey
        withAnimation(MotionConstants.smooth) {
            appState.currentCharacter?.gold = result.gold
            appState.currentCharacter?.gems = result.gems
            activeShaft = result.activeShaft
            pendingMinigameSession = nil
        }
        syncVisualCounters()

        if result.shaftCompleted, let cleared = sessionShaftKey ?? result.activeShaft?.key {
            clearedShaftKey = cleared
        }

        if result.bonusGold > 0 || result.bonusGems > 0 {
            let parts: [String] = [
                result.bonusGold > 0 ? "+\(result.bonusGold) gold" : nil,
                result.bonusGems > 0 ? "+\(result.bonusGems) gem" : nil,
            ].compactMap { $0 }
            appState.showToast(
                "Bonus secured!",
                subtitle: parts.joined(separator: " · "),
                type: .reward
            )
        }
    }

    /// Called when the player taps Skip + confirms, or the server rejects the
    /// bonus call. Cleans up local state without applying any reward.
    func cancelMinigameSession() {
        withAnimation(MotionConstants.smooth) {
            pendingMinigameSession = nil
        }
    }

    /// Dismisses the shaft-cleared celebration overlay.
    func dismissClearedOverlay() {
        clearedShaftKey = nil
    }

    // Decodes the nested `minigame_session` dict returned by /collect-all
    // into a typed `MinigameSessionInfo`. Uses JSONSerialization +
    // JSONDecoder round-trip so CodingKeys drive field mapping.
    private static func decodeMinigameSession(from dict: [String: Any]) -> MinigameSessionInfo? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(MinigameSessionInfo.self, from: data)
    }

    // MARK: - Boost

    func boost(slotIndex: Int) {
        guard !activeActionSlots.contains(slotIndex) else { return }
        guard let charId = appState.currentCharacter?.id else { return }
        activeActionSlots.insert(slotIndex)
        actionSlotId = "\(slotIndex)"

        // Optimistic: deduct gems + show boosted
        let prevGems = appState.currentCharacter?.gems ?? 0
        let boostCost = cache.gameConfig?.goldMineBoostGems ?? 10
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
        let slotCost = cache.gameConfig?.goldMineSlotCostGems ?? 50
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
