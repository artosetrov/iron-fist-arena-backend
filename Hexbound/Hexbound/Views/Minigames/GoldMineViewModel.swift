import SwiftUI

private struct GoldMineCollectAllErrorPayload: Decodable {
    let code: String
    let slots: [GoldMineSlotResponse]?
    let unplayedReadySlotIndices: [Int]?
}

@MainActor @Observable
final class GoldMineViewModel {
    private let appState: AppState
    private let cache: GameDataCache

    var slots: [GoldMineSlotResponse] = []
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

    // MARK: - Claim Reward Modal
    /// When non-nil, the view presents the shared Gold Mine reward
    /// celebration modal for collect and bonus-round payouts.
    var claimReward: ClaimRewardData?

    struct ClaimRewardData {
        let goldEarned: Int
        let gemsEarned: Int
    }

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
        guard let stats = slots[index].stats else { return nil }
        return SlotStats(
            totalGoldMined: stats.totalGoldMined,
            sessionsCompleted: stats.sessionsCompleted,
            bestHaul: stats.bestHaul,
            currentStreak: stats.currentStreak
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
            let data: GoldMineStatusResponse = try await APIClient.shared.get(
                APIEndpoints.goldMineStatus,
                params: ["character_id": charId]
            )
            slots = data.slots
            maxSlots = data.maxSlots
            cache.cacheGoldMine(status: data)
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
                slots[slotIndex].status = .mining
                slots[slotIndex].startedAt = now
                slots[slotIndex].endsAt = endsAt
            }
            actionSlotId = nil
        }
        HapticManager.medium()
        appState.showToast("Mining started!", type: .info)

        // Background API call — update with real server values
        do {
            let data: GoldMineStartResponse = try await APIClient.shared.post(
                APIEndpoints.goldMineStart,
                body: GoldMineSlotActionRequest(characterId: charId, slotIndex: slotIndex)
            )
            withAnimation(MotionConstants.smooth) {
                slots = data.slots
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
            return slot.reward ?? 50
        }()

        withAnimation(MotionConstants.smooth) {
            // Mark slot idle until server confirms and returns fresh session data.
            // Previously we set status = "mining" but kept old started_at/ends_at,
            // which made the progress bar render stuck at 100%.
            if slotIndex < slots.count {
                slots[slotIndex].status = .idle
                slots[slotIndex].startedAt = nil
                slots[slotIndex].endsAt = nil
                slots[slotIndex].reward = nil
                slots[slotIndex].gemReward = nil
            }
            appState.currentCharacter?.gold = (savedGold ?? 0) + estimatedGold
            actionSlotId = nil
        }
        syncVisualCounters()
        HapticManager.success()

        // Background: actual API call
        do {
            let data: GoldMineCollectResponse = try await APIClient.shared.post(
                APIEndpoints.goldMineCollect,
                body: GoldMineSlotActionRequest(characterId: charId, slotIndex: slotIndex)
            )
            // Update with real server values
            withAnimation(MotionConstants.smooth) {
                slots = data.slots
                appState.currentCharacter?.gold = data.gold
                appState.currentCharacter?.gems = data.gems
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

        // Capture pre-collect totals for reward delta
        let goldBefore = appState.currentCharacter?.gold ?? 0
        let gemsBefore = appState.currentCharacter?.gems ?? 0

        do {
            let data: GoldMineCollectAllResponse = try await APIClient.shared.post(
                APIEndpoints.goldMineCollectAll,
                body: GoldMineCollectAllRequest(
                    characterId: charId,
                    pickedShaftKey: pickedShaftKey
                )
            )

            // Branch 1: server wants us to show the picker.
            if data.needsShaftPick == true {
                unlockedShafts = data.unlockedShafts ?? []
                shaftPickerSlotIndex = nil  // collectAll context
                showShaftPicker = true
                return
            }

            // Branch 2: success — update slots, gold, active shaft.
            withAnimation(MotionConstants.smooth) { slots = data.slots }
            let newGold = data.gold ?? goldBefore
            let newGems = data.gems ?? gemsBefore
            appState.currentCharacter?.gold = newGold
            appState.currentCharacter?.gems = newGems
            syncVisualCounters()
            appState.invalidateCache("quests")

            // Show claim reward celebration modal with earned amounts
            let goldDelta = max(0, newGold - goldBefore)
            let gemsDelta = max(0, newGems - gemsBefore)
            if goldDelta > 0 || gemsDelta > 0 {
                claimReward = ClaimRewardData(goldEarned: goldDelta, gemsEarned: gemsDelta)
            }

            // Active shaft — may be nil if this cycle cleared the shaft.
            if let nextShaft = data.activeShaft {
                let previousKey = activeShaft?.key
                activeShaft = nextShaft
                // If the shaft key flipped under us mid-cycle, treat as
                // completion celebration for the previous shaft.
                if let previousKey, previousKey != nextShaft.key {
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
               let payload = apiError.decodedResponseBody(GoldMineCollectAllErrorPayload.self),
               payload.code == "NO_PLAYABLE_SLOTS" {
                // Keep the slots snapshot the server sent so the board
                // reflects reality.
                let updatedSlots = payload.slots ?? []
                if !updatedSlots.isEmpty {
                    withAnimation(MotionConstants.smooth) { slots = updatedSlots }
                }
                let unplayed = payload.unplayedReadySlotIndices ?? []
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

        do {
            let data: GoldMineSlotMinigameStartResponse = try await APIClient.shared.post(
                APIEndpoints.goldMineSlotMinigameStart,
                body: GoldMineSlotMinigameStartRequest(
                    characterId: charId,
                    slotIndex: slotIndex,
                    pickedShaftKey: pickedShaftKey
                )
            )

            // Shaft picker branch — remember which slot triggered it so
            // pickShaft routes back to startSlotMinigame (not collectAll).
            if data.needsShaftPick == true {
                unlockedShafts = data.unlockedShafts ?? []
                shaftPickerSlotIndex = slotIndex
                showShaftPicker = true
                return
            }

            withAnimation(MotionConstants.smooth) { slots = data.slots }
            activeShaft = data.activeShaft

            if let session = data.minigameSession {
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

    /// Applies the typed response from /slot-minigame/submit. The view
    /// calls this via its `onFinish` callback once the 15s round ends or
    /// the player skips. No shaft update happens here — shaft progress is
    /// owned by /collect-all and /collect.
    func applySlotMinigameResult(_ data: GoldMineSlotMinigameSubmitResponse) {
        let bonusGold = data.bonusGold
        let bonusGems = data.bonusGems

        withAnimation(MotionConstants.smooth) {
            appState.currentCharacter?.gold = data.gold
            appState.currentCharacter?.gems = data.gems
            slots = data.slots
            pendingMinigameSession = nil
        }
        syncVisualCounters()

        if bonusGold > 0 || bonusGems > 0 {
            claimReward = ClaimRewardData(goldEarned: bonusGold, gemsEarned: bonusGems)
        }
    }

    /// Slot dict accessor — true once the per-slot bonus minigame has been
    /// completed (server-side `minigame_played_at != null`).
    func isSlotMinigamePlayed(_ slot: GoldMineSlotResponse) -> Bool {
        slot.hasPlayedMinigame
    }

    /// Slot dict accessor — true when a minigame session is currently in
    /// flight for this slot (player backgrounded mid-round).
    func hasInFlightMinigameSession(_ slot: GoldMineSlotResponse) -> Bool {
        slot.hasInFlightMinigameSession
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

    // MARK: - Boost

    func boost(slotIndex: Int) {
        guard !activeActionSlots.contains(slotIndex) else { return }
        guard let charId = appState.currentCharacter?.id else { return }
        activeActionSlots.insert(slotIndex)
        actionSlotId = "\(slotIndex)"

        // Optimistic: deduct gems + show boosted
        let prevGems = appState.currentCharacter?.gems ?? 0
        let boostCost = cache.gameConfig?.goldMineBoostGems ?? 3
        appState.currentCharacter?.gems = max(0, prevGems - boostCost)
        HapticManager.success()
        appState.showToast("Slot boosted!", type: .info)

        // Fire API in background
        Task { [weak self] in
            guard let self else { return }
            do {
                let data: GoldMineBoostResponse = try await APIClient.shared.post(
                    APIEndpoints.goldMineBoost,
                    body: GoldMineSlotActionRequest(characterId: charId, slotIndex: slotIndex)
                )
                slots = data.slots
                appState.currentCharacter?.gems = data.gems
                syncVisualCounters()
            } catch {
                // Revert gems on failure
                appState.currentCharacter?.gems = prevGems
                // Surface the actual server reason instead of blaming gems for every failure.
                // Common real reasons: ALREADY_BOOSTED, NO_SESSION, rate-limit.
                let reason = (error as? APIError)?.userMessage ?? "Please try again"
                appState.showToast("Failed to boost", subtitle: reason, type: .error)
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
        slots.append(
            GoldMineSlotResponse(
                slotIndex: maxSlots - 1,
                status: .idle,
                sessionId: nil,
                startedAt: nil,
                endsAt: nil,
                reward: nil,
                gemReward: nil,
                boosted: nil,
                minigamePlayed: nil,
                minigameSessionId: nil,
                stats: nil
            )
        )
        HapticManager.success()
        appState.showToast("New mining slot unlocked!", type: .reward)

        // Fire API in background — server response overwrites with authoritative values
        Task { [weak self] in
            guard let self else { return }
            do {
                let data: GoldMineBuySlotResponse = try await APIClient.shared.post(
                    APIEndpoints.goldMineBuySlot,
                    body: GoldMineCharacterRequest(characterId: charId)
                )
                maxSlots = data.maxSlots
                slots = data.slots
                appState.currentCharacter?.gems = data.gems
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

    func slotStatus(_ slot: GoldMineSlotResponse) -> String {
        slot.resolvedStatus().rawValue
    }

    /// Gem cost for boosting a mining slot (server config with fallback).
    var boostCost: Int {
        cache.gameConfig?.goldMineBoostGems ?? 3
    }

    func timeRemaining(_ slot: GoldMineSlotResponse) -> String {
        guard let endStr = slot.endsAt,
              let endDate = slotDate(from: endStr) else { return "" }
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 { return "Ready!" }
        let mins = Int(remaining) / 60
        let hrs = mins / 60
        if hrs > 0 { return "\(hrs)h \(mins % 60)m remaining" }
        return "\(mins)m remaining"
    }

    /// Returns mining progress as 0.0–1.0 (0 = just started, 1 = done)
    func miningProgress(_ slot: GoldMineSlotResponse) -> Double {
        guard let endStr = slot.endsAt,
              let startStr = slot.startedAt,
              let endDate = slotDate(from: endStr),
              let startDate = slotDate(from: startStr) else { return 0 }
        let total = endDate.timeIntervalSince(startDate)
        guard total > 0 else { return 1 }
        let elapsed = Date().timeIntervalSince(startDate)
        return min(max(elapsed / total, 0), 1)
    }

    /// Number of currently active (mining or ready) slots
    var activeSlotCount: Int {
        slots.filter { slot in
            let status = slot.resolvedStatus()
            return status == .mining || status == .ready
        }.count
    }

    private func slotDate(from raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) {
            return date
        }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: raw)
    }
}
