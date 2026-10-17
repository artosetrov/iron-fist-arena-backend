import SwiftUI

/// Gold Mine screen state (2026-10-16 rework).
///
/// Server-authoritative: payouts, prices and expedition progress come from
/// /status and the collect routes. On a tap the client only applies what it
/// already knows (a full cart's revealed haul) and takes it back if the
/// server refuses.
@MainActor @Observable
final class GoldMineViewModel {
    private let appState: AppState
    private let cache: GameDataCache

    var slots: [GoldMineSlotResponse] = []
    var maxSlots = 3
    var isLoading = false
    var isBuyingSlot = false
    /// Tunnels with a send / collect / boost request in flight (Collect All
    /// marks every cart it drains).
    private(set) var busySlots: Set<Int> = []

    /// The running expedition: every cart collected is one haul, the last
    /// haul opens the chest. Always sent by current backends.
    var expedition: ActiveShaft?
    /// Prices, payout ranges and bonus-round terms from /status.
    var economy: GoldMineEconomy?

    // MARK: Bonus round (optional coin rush)

    /// Non-nil while the bonus round is on screen (fullScreenCover).
    var pendingMinigameSession: MinigameSessionInfo?
    var isStartingSlotMinigame = false

    var isCollectingAll = false

    // MARK: Rewards

    /// Reward celebration: Collect All, an expedition chest or a bonus round.
    var claimReward: ClaimRewardData?
    /// Last single-cart payout — that tunnel shows "+86" for a moment.
    var recentHaul: RecentHaul?

    struct ClaimRewardData: Equatable {
        enum Kind { case haul, bonus }
        let kind: Kind
        let goldEarned: Int
        let gemsEarned: Int
        let chest: GoldMineExpeditionChest?
    }

    struct RecentHaul: Equatable {
        let id = UUID()
        let slotIndex: Int
        let gold: Int
        let gems: Int
    }

    enum TunnelPhase { case idle, mining, ready }

    /// Bumped when a mutating request starts and again when it ends. A
    /// /status asked for under an older value may predate that change and is
    /// dropped instead of reverting it.
    private var mutationEpoch = 0
    /// `ends_at` → when its finished timer last asked /status for the payout.
    private var payoutRefreshes: [String: Date] = [:]

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
    }

    // MARK: - Derived

    var gold: Int { appState.currentCharacter?.gold ?? 0 }
    var gems: Int { appState.currentCharacter?.gems ?? 0 }

    /// Slot by index, or an empty tunnel when the server has not listed it yet.
    func slot(_ index: Int) -> GoldMineSlotResponse {
        slots.first { $0.slotIndex == index } ?? .idle(index)
    }

    func phase(_ index: Int, now: Date = Date()) -> TunnelPhase {
        switch slot(index).resolvedStatus(now: now) {
        case .idle: return .idle
        case .mining: return .mining
        case .ready: return .ready
        }
    }

    func isBusy(_ index: Int) -> Bool { busySlots.contains(index) }

    var readyIndices: [Int] { (0..<maxSlots).filter { phase($0) == .ready } }
    var readyCount: Int { readyIndices.count }
    /// Gold in the full carts the server has already revealed.
    var readyGold: Int { readyIndices.reduce(0) { $0 + (slot($1).reward ?? 0) } }
    var readyGems: Int { readyIndices.reduce(0) { $0 + (slot($1).gemReward ?? 0) } }

    /// Gem price of a double haul; nil until the server has told us.
    var boostCost: Int? { economy?.boostCostGems ?? cache.gameConfig?.goldMineBoostGems }
    /// How many times a boosted cart pays; nil until the server has told us.
    var boostMultiplier: Int? { economy?.boostMultiplier }
    /// Gem price of the next tunnel; nil until the server has told us.
    var slotCost: Int? { economy?.slotCostGems ?? cache.gameConfig?.goldMineSlotCostGems }
    /// Most tunnels a mine can have (server cap). Unknown → no sealed tunnel shown.
    var slotLimit: Int { economy?.slotLimit ?? maxSlots }
    var canOpenTunnel: Bool { maxSlots < slotLimit }

    static let mineNames: [String] = [
        "Amethyst Cavern", "Emerald Vein", "Molten Forge",
        "Frozen Depths", "Blood Quarry", "King's Treasury"
    ]

    static func mineName(for index: Int) -> String {
        index >= 0 && index < mineNames.count ? mineNames[index] : "Tunnel \(index + 1)"
    }

    // MARK: - Time

    func timeLeft(_ index: Int, now: Date = Date()) -> TimeInterval? {
        guard let end = slot(index).endDate else { return nil }
        return max(0, end.timeIntervalSince(now))
    }

    /// 0 = cart just left, 1 = cart is up.
    func progress(_ index: Int, now: Date = Date()) -> Double {
        let s = slot(index)
        guard let start = s.startDate, let end = s.endDate else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 1 }
        return min(max(now.timeIntervalSince(start) / total, 0), 1)
    }

    /// "3h 05m", "12m", "45s".
    static func clock(_ seconds: TimeInterval) -> String {
        let s = Int(seconds.rounded(.up))
        if s >= 3600 {
            let minutes = (s % 3600) / 60
            return "\(s / 3600)h \(minutes < 10 ? "0" : "")\(minutes)m"
        }
        if s >= 60 { return "\(Int((Double(s) / 60).rounded(.up)))m" }
        return "\(max(s, 0))s"
    }

    /// "4 hours" from the server's run length.
    var runLengthLabel: String? {
        guard let hours = economy?.runHours else { return nil }
        let value = hours.formatted(.number.precision(.fractionLength(0...1)))
        return hours == 1 ? "\(value) hour" : "\(value) hours"
    }

    /// Called every second by the screen. When a cart's timer runs out the
    /// server already knows its haul, so ask /status for it (again at most
    /// every 15 s if the server still says "mining").
    func tick(now: Date) {
        for s in slots where s.status == .mining {
            guard let raw = s.endsAt, let end = s.endDate, end <= now else { continue }
            if let last = payoutRefreshes[raw], now.timeIntervalSince(last) < 15 { continue }
            payoutRefreshes[raw] = now
            Task { await loadStatus() }
            return
        }
    }

    // MARK: - Foreman

    /// What the foreman says: the first line is about right now, the rest
    /// explain the mine (tap the foreman to hear the next one). Each line
    /// must fit the header bubble's three lines (~55 characters).
    func foremanLines(now: Date = Date()) -> [String] {
        var lines = [statusLine(now: now)]
        if let economy, let run = runLengthLabel {
            lines.append("A cart takes \(run): \(economy.rewardMin)–\(economy.rewardMax) gold, sometimes gems.")
        }
        if let economy, let total = expedition?.total {
            lines.append("Every \(total) carts open the chest: \(economy.chestGold) gold, \(economy.chestGems) gems.")
        }
        if let cap = economy?.bonusCapPercent {
            lines.append("The bonus run is optional — up to \(cap)% more gold.")
        }
        if let cost = boostCost, let times = boostMultiplier {
            lines.append("\(cost) gems make any cart bring \(times == 2 ? "twice" : "\(times)×") its haul.")
        }
        return lines
    }

    private func statusLine(now: Date) -> String {
        let ready = (0..<maxSlots).filter { phase($0, now: now) == .ready }
        if ready.count > 1 { return "\(ready.count) carts are full, boss. Haul them up!" }
        if let index = ready.first { return "The \(Self.mineName(for: index)) cart is full, boss. Haul it up!" }
        if let idle = (0..<maxSlots).first(where: { phase($0, now: now) == .idle }) {
            return "\(Self.mineName(for: idle)) stands empty. Send a cart down!"
        }
        if let shaft = expedition, shaft.total - shaft.progress == 1 {
            return "One more cart and the expedition chest is ours."
        }
        let next = (0..<maxSlots).compactMap { timeLeft($0, now: now) }.min()
        if let next { return "All carts are down. The next one is up in \(Self.clock(next))." }
        return "Pick a tunnel and send a cart down."
    }

    // MARK: - Load

    func loadStatus() async {
        if slots.isEmpty, let cached = cache.staleGoldMine() {
            slots = cached.slots
            maxSlots = cached.maxSlots
        }
        if economy == nil { economy = cache.goldMineEconomy }
        if expedition == nil { expedition = cache.goldMineExpedition }
        if slots.isEmpty { isLoading = true }

        guard let charId = appState.currentCharacter?.id else {
            isLoading = false
            return
        }

        let epoch = mutationEpoch
        do {
            let data: GoldMineStatusResponse = try await APIClient.shared.get(
                APIEndpoints.goldMineStatus,
                params: ["character_id": charId]
            )
            isLoading = false
            if let economy = data.economy { self.economy = economy }
            // A change made since this was asked for (or still in flight)
            // owns the tunnels; this answer could undo it.
            guard epoch == mutationEpoch, busySlots.isEmpty, !isCollectingAll,
                  !isBuyingSlot, !isStartingSlotMinigame else { return }
            slots = merged(data.slots)
            maxSlots = data.maxSlots
            if let shaft = data.activeShaft { expedition = shaft }
            cache.cacheGoldMine(status: data)
        } catch {
            isLoading = false
        }
    }

    // MARK: - Send a cart

    func startMining(slotIndex: Int) async {
        guard phase(slotIndex) == .idle, !busySlots.contains(slotIndex),
              let charId = appState.currentCharacter?.id else { return }
        busySlots.insert(slotIndex)
        mutationEpoch &+= 1
        defer {
            busySlots.remove(slotIndex)
            mutationEpoch &+= 1
        }

        // Optimistic: the cart leaves on the tap (when we know the run length).
        let saved = slot(slotIndex)
        if let hours = economy?.runHours {
            let now = Date()
            var next = GoldMineSlotResponse.idle(slotIndex)
            next.status = .mining
            next.startedAt = Self.iso(now)
            next.endsAt = Self.iso(now.addingTimeInterval(hours * 3600))
            next.stats = saved.stats
            replace(next)
        }
        SFXManager.shared.play(.goldMine)

        do {
            let data: GoldMineStartResponse = try await APIClient.shared.post(
                APIEndpoints.goldMineStart,
                body: GoldMineSlotActionRequest(characterId: charId, slotIndex: slotIndex)
            )
            apply(data.slots, only: [slotIndex])
            cache.cacheGoldMine(slots: slots, maxSlots: maxSlots)
        } catch {
            replace(saved)
            appState.showToast("Couldn't send the cart", subtitle: Self.reason(error), type: .error)
            reloadIfOutOfSync(error)
        }
    }

    // MARK: - Collect one cart

    func collect(slotIndex: Int) async {
        guard phase(slotIndex) == .ready, !busySlots.contains(slotIndex), !isCollectingAll,
              let charId = appState.currentCharacter?.id else { return }
        busySlots.insert(slotIndex)
        mutationEpoch &+= 1
        defer {
            busySlots.remove(slotIndex)
            mutationEpoch &+= 1
        }

        // Optimistic: the cart empties and its revealed haul lands now.
        let saved = slot(slotIndex)
        let savedExpedition = expedition
        let knownGold = saved.reward ?? 0
        let knownGems = saved.gemReward ?? 0
        markCollected([slotIndex])
        let credit = appState.creditRewardOptimistically(gold: knownGold, gems: knownGems, xp: 0)
        advanceExpeditionLocally(by: 1)
        if knownGold > 0 || knownGems > 0 {
            recentHaul = RecentHaul(slotIndex: slotIndex, gold: knownGold, gems: knownGems)
        }
        SFXManager.shared.play(.coinDrop)

        do {
            let data: GoldMineCollectResponse = try await APIClient.shared.post(
                APIEndpoints.goldMineCollect,
                body: GoldMineSlotActionRequest(characterId: charId, slotIndex: slotIndex)
            )
            apply(data.slots, only: [slotIndex])
            applyBalances(gold: data.gold, gems: data.gems)
            if let shaft = data.activeShaft { expedition = shaft }
            cache.cacheGoldMine(slots: slots, maxSlots: maxSlots)
            cache.cacheGoldMineExpedition(expedition)
            if knownGold == 0, knownGems == 0, data.goldCollected > 0 || data.gemsCollected > 0 {
                recentHaul = RecentHaul(slotIndex: slotIndex, gold: data.goldCollected, gems: data.gemsCollected)
            }
            if let chest = data.expeditionChest {
                claimReward = ClaimRewardData(
                    kind: .haul,
                    goldEarned: data.goldCollected,
                    gemsEarned: data.gemsCollected,
                    chest: chest
                )
            }
            refreshQuestsInBackground()
        } catch {
            replace(saved)
            expedition = savedExpedition
            appState.revertRewardCredit(credit)
            recentHaul = nil
            appState.showToast("Couldn't collect the cart", subtitle: Self.reason(error), type: .error)
            reloadIfOutOfSync(error)
        }
    }

    // MARK: - Collect all

    /// Drains every full cart in one call. The bonus round is optional, so
    /// nothing here waits on it; every cart counts as one haul.
    func collectAll() async {
        guard !isCollectingAll, busySlots.isEmpty,
              let charId = appState.currentCharacter?.id else { return }
        let ready = readyIndices
        guard !ready.isEmpty else { return }
        isCollectingAll = true
        busySlots.formUnion(ready)
        mutationEpoch &+= 1
        defer {
            isCollectingAll = false
            busySlots.subtract(ready)
            mutationEpoch &+= 1
        }

        let saved = ready.map { slot($0) }
        let savedExpedition = expedition
        let knownGold = readyGold
        let knownGems = readyGems
        // When this collect likely fills the expedition, the celebration
        // waits for the server's chest instead of showing twice.
        let chestLikely = expedition.map { $0.progress + ready.count >= $0.total } ?? false

        markCollected(ready)
        let credit = appState.creditRewardOptimistically(gold: knownGold, gems: knownGems, xp: 0)
        advanceExpeditionLocally(by: ready.count)
        var showedOptimistic = false
        if !chestLikely, knownGold > 0 || knownGems > 0 {
            claimReward = ClaimRewardData(kind: .haul, goldEarned: knownGold, gemsEarned: knownGems, chest: nil)
            showedOptimistic = true
        }
        SFXManager.shared.play(.coinDrop)

        do {
            let data: GoldMineCollectAllResponse = try await APIClient.shared.post(
                APIEndpoints.goldMineCollectAll,
                body: GoldMineCharacterRequest(characterId: charId)
            )
            apply(data.slots, only: Set(ready))
            applyBalances(gold: data.gold, gems: data.gems)
            if let shaft = data.activeShaft { expedition = shaft }
            cache.cacheGoldMine(slots: slots, maxSlots: maxSlots)
            cache.cacheGoldMineExpedition(expedition)

            let reward = ClaimRewardData(
                kind: .haul,
                goldEarned: data.goldCollected,
                gemsEarned: data.gemsCollected,
                chest: data.expeditionChest
            )
            let hasReward = reward.goldEarned > 0 || reward.gemsEarned > 0 || reward.chest != nil
            if showedOptimistic {
                // Correct the open celebration; reopen it only for a chest.
                if claimReward != nil || reward.chest != nil, claimReward != reward, hasReward {
                    claimReward = reward
                }
            } else if hasReward {
                claimReward = reward
            }
            refreshQuestsInBackground()
        } catch {
            for previous in saved { replace(previous) }
            expedition = savedExpedition
            appState.revertRewardCredit(credit)
            claimReward = nil
            if (error as? APIError)?.statusCode != 400 {
                appState.showToast("Couldn't collect", subtitle: Self.reason(error), type: .error)
            }
            // 400 NO_READY_SLOTS: our clock ran ahead of the server's.
            reloadIfOutOfSync(error)
        }
    }

    // MARK: - Bonus round

    /// Opens the optional coin rush for a cart. Idempotent server-side: a
    /// round already in flight comes back as-is.
    func startSlotMinigame(slotIndex: Int) async {
        guard !isStartingSlotMinigame, let charId = appState.currentCharacter?.id else { return }
        isStartingSlotMinigame = true
        mutationEpoch &+= 1
        defer {
            isStartingSlotMinigame = false
            mutationEpoch &+= 1
        }

        do {
            let data: GoldMineSlotMinigameStartResponse = try await APIClient.shared.post(
                APIEndpoints.goldMineSlotMinigameStart,
                body: GoldMineSlotActionRequest(characterId: charId, slotIndex: slotIndex)
            )
            apply(data.slots, only: [slotIndex])
            if let shaft = data.activeShaft { expedition = shaft }
            if let session = data.minigameSession {
                pendingMinigameSession = session
                HapticManager.medium()
            }
        } catch {
            appState.showToast("Couldn't start the bonus run", subtitle: Self.reason(error), type: .error)
        }
    }

    /// Applies /slot-minigame/submit (via the round's `onFinish`).
    func applySlotMinigameResult(_ data: GoldMineSlotMinigameSubmitResponse) {
        mutationEpoch &+= 1
        applyBalances(gold: data.gold, gems: data.gems)
        if let index = pendingMinigameSession?.slotIndex {
            apply(data.slots, only: [index])
        } else {
            slots = merged(data.slots)
        }
        pendingMinigameSession = nil
        if data.bonusGold > 0 || data.bonusGems > 0 {
            claimReward = ClaimRewardData(kind: .bonus, goldEarned: data.bonusGold, gemsEarned: data.bonusGems, chest: nil)
        }
    }

    func cancelMinigameSession() {
        pendingMinigameSession = nil
    }

    // MARK: - Double haul

    func boost(slotIndex: Int) async {
        let current = slot(slotIndex)
        guard let cost = boostCost, phase(slotIndex) != .idle, !current.isBoosted,
              !busySlots.contains(slotIndex), !isCollectingAll,
              let charId = appState.currentCharacter?.id else { return }
        guard gems >= cost else {
            appState.showToast("Not enough gems", subtitle: "A double haul costs \(cost) gems.", type: .info)
            return
        }
        busySlots.insert(slotIndex)
        mutationEpoch &+= 1
        defer {
            busySlots.remove(slotIndex)
            mutationEpoch &+= 1
        }

        let credit = appState.applyOptimisticCurrencyDelta(gold: 0, gems: -cost)
        var boosted = current
        boosted.boosted = true
        if let times = boostMultiplier {
            boosted.reward = current.reward.map { $0 * times }
            boosted.gemReward = current.gemReward.map { $0 * times }
        }
        replace(boosted)
        SFXManager.shared.play(.coinsJingle)

        do {
            let data: GoldMineBoostResponse = try await APIClient.shared.post(
                APIEndpoints.goldMineBoost,
                body: GoldMineSlotActionRequest(characterId: charId, slotIndex: slotIndex)
            )
            apply(data.slots, only: [slotIndex])
            appState.currentCharacter?.gems = data.gems
            appState.noteAuthoritativeCurrencyWrite(gold: false, gems: true, xp: false)
        } catch {
            replace(current)
            appState.revertRewardCredit(credit)
            appState.showToast("Couldn't double the haul", subtitle: Self.reason(error), type: .error)
            reloadIfOutOfSync(error)
        }
    }

    // MARK: - Open a tunnel

    func buySlot() async {
        guard !isBuyingSlot, canOpenTunnel, let cost = slotCost,
              let charId = appState.currentCharacter?.id else { return }
        guard gems >= cost else {
            appState.showToast("Not enough gems", subtitle: "A new tunnel costs \(cost) gems.", type: .info)
            return
        }
        isBuyingSlot = true
        mutationEpoch &+= 1
        defer {
            isBuyingSlot = false
            mutationEpoch &+= 1
        }

        let credit = appState.applyOptimisticCurrencyDelta(gold: 0, gems: -cost)
        let prevMax = maxSlots
        maxSlots += 1
        replace(.idle(prevMax))
        SFXManager.shared.play(.chestOpen)

        do {
            let data: GoldMineBuySlotResponse = try await APIClient.shared.post(
                APIEndpoints.goldMineBuySlot,
                body: GoldMineCharacterRequest(characterId: charId)
            )
            maxSlots = data.maxSlots
            // Only the new tunnels — the others may have moved on meanwhile.
            apply(data.slots, only: Set(prevMax..<max(prevMax, data.maxSlots)))
            appState.currentCharacter?.gems = data.gems
            appState.noteAuthoritativeCurrencyWrite(gold: false, gems: true, xp: false)
            cache.cacheGoldMine(slots: slots, maxSlots: maxSlots)
        } catch {
            maxSlots = prevMax
            slots.removeAll { $0.slotIndex >= prevMax }
            appState.revertRewardCredit(credit)
            appState.showToast("Couldn't open the tunnel", subtitle: Self.reason(error), type: .error)
        }
    }

    // MARK: - Helpers

    /// Start / boost / bonus responses list slots without `stats`; keep the
    /// history we already have instead of blanking it.
    private func merged(_ incoming: [GoldMineSlotResponse]) -> [GoldMineSlotResponse] {
        incoming.map(keepingStats)
    }

    private func keepingStats(_ next: GoldMineSlotResponse) -> GoldMineSlotResponse {
        guard next.stats == nil,
              let old = slots.first(where: { $0.slotIndex == next.slotIndex }) else { return next }
        var copy = next
        copy.stats = old.stats
        return copy
    }

    /// Takes only the acted-on tunnels from a response: requests can overlap,
    /// and an older answer must not roll another tunnel back.
    private func apply(_ incoming: [GoldMineSlotResponse], only indices: Set<Int>) {
        for next in incoming where indices.contains(next.slotIndex) {
            replace(keepingStats(next))
        }
    }

    /// Puts a slot in place by its `slotIndex` (appends, keeping order, if new).
    private func replace(_ next: GoldMineSlotResponse) {
        if let position = slots.firstIndex(where: { $0.slotIndex == next.slotIndex }) {
            slots[position] = next
        } else {
            slots.append(next)
            slots.sort { $0.slotIndex < $1.slotIndex }
        }
    }

    private func markCollected(_ indices: [Int]) {
        for index in indices {
            var next = GoldMineSlotResponse.idle(index)
            next.stats = slot(index).stats
            replace(next)
        }
    }

    private func advanceExpeditionLocally(by hauls: Int) {
        guard let shaft = expedition else { return }
        expedition = ActiveShaft(key: shaft.key, progress: min(shaft.total, shaft.progress + hauls), total: shaft.total)
    }

    private func applyBalances(gold: Int?, gems: Int?) {
        if let gold { appState.currentCharacter?.gold = gold }
        if let gems { appState.currentCharacter?.gems = gems }
        appState.noteAuthoritativeCurrencyWrite(gold: gold != nil, gems: gems != nil, xp: false)
    }

    /// A 400/404/409 means our picture of the mine is stale (collected on
    /// another device, clock drift…): fetch the truth once the request that
    /// failed has released its locks.
    private func reloadIfOutOfSync(_ error: Error) {
        guard let code = (error as? APIError)?.statusCode, [400, 404, 409].contains(code) else { return }
        Task { await loadStatus() }
    }

    private func refreshQuestsInBackground() {
        let service = QuestService(appState: appState)
        Task { _ = try? await service.loadQuests() }
    }

    private static func iso(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func reason(_ error: Error) -> String {
        (error as? APIError)?.userMessage ?? "Check your connection and try again."
    }
}
