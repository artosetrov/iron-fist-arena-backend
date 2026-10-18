import SwiftUI

/// Fortune's Table — sit down with a stake, watch the regulars join, top up
/// before bets close, then the wheel decides who takes the pot.
///
/// The server owns everything: who sits where, the draw, the payout. The
/// client polls `/state` about once a second while the lobby is open and
/// only animates what the server already decided.
@MainActor @Observable
final class FortuneTableViewModel {
    enum Phase: Equatable {
        /// Choosing a table and a stake.
        case seating
        /// Seated; others are joining; top-ups open.
        case lobby
        /// Bets closed; waiting for the server to draw.
        case drawing
        /// The draw is known; the view is spinning the wheel to it.
        case spinning
        /// The wheel stopped; the result modal is up.
        case result
    }

    private let appState: AppState

    // Lobby info
    var tiers: [FortuneTableTier] = []
    var selectedTierKey = "copper"
    var selectedStake = 50
    var rake = 0.05
    var roundsToday = 0
    var roundsLimit = 20
    var history: [FortuneTableHistoryEntry] = []

    // The round at the table
    var round: FortuneTableRound?
    var phase: Phase = .seating
    /// Local moment bets close, re-anchored on every server response.
    var lockAt: Date?
    /// Local moment top-ups close (a second before the lock).
    var topUpCloseAt: Date?

    var isLoading = true
    var isBusy = false
    var errorMessage: String?
    var showsErrorState: Bool { errorMessage != nil && !hasLoaded }

    var npcSpeech = "Take a seat, darling. The wheel loves a full table."

    /// The wheel stopped while the screen was away — show the result on return.
    var resultUnseen = false

    private var hasLoaded = false
    private var pollTask: Task<Void, Never>?
    private var pollFailures = 0

    private enum PollOutcome { case pending, settled, gone, failed }
    /// Gold after the draw, held back until the wheel stops so the counter
    /// doesn't give the result away mid-spin.
    private var pendingGold: Int?

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Derived

    var gold: Int { appState.currentCharacter?.gold ?? 0 }

    var selectedTier: FortuneTableTier? { tiers.first { $0.key == selectedTierKey } }

    var roundsRemaining: Int { max(0, roundsLimit - roundsToday) }

    var canJoin: Bool {
        guard let tier = selectedTier else { return false }
        return phase == .seating && !isBusy && tier.unlocked
            && gold >= selectedStake && roundsRemaining > 0
            && selectedStake >= tier.minStake && selectedStake <= tier.maxStake
    }

    /// Top-ups still open (by the local clock) and the seat isn't at the cap.
    func canTopUp(_ amount: Int, now: Date = .now) -> Bool {
        guard phase == .lobby, !isBusy, let round, let tier = tiers.first(where: { $0.key == round.tier }) else { return false }
        if let topUpCloseAt, now >= topUpCloseAt { return false }
        return gold >= amount && round.yourStake + amount <= tier.maxStake
    }

    var roundTier: FortuneTableTier? {
        guard let round else { return selectedTier }
        return tiers.first { $0.key == round.tier }
    }

    // MARK: - Load

    func loadStatus() async {
        guard let charId = appState.currentCharacter?.id else {
            isLoading = false
            return
        }
        errorMessage = nil
        do {
            let data: FortuneTableStatusResponse = try await APIClient.shared.get(
                APIEndpoints.fortuneTableStatus,
                params: ["character_id": charId]
            )
            apply(status: data)
            hasLoaded = true
        } catch {
            errorMessage = (error as? APIError)?.userMessage
                ?? "Couldn't reach Fortune's Table. Check your connection and try again."
        }
        isLoading = false
    }

    private func apply(status data: FortuneTableStatusResponse) {
        tiers = data.tiers
        rake = data.rake
        roundsToday = data.roundsToday
        roundsLimit = data.roundsLimit
        history = data.history
        if phase == .seating || phase == .result {
            appState.currentCharacter?.gold = data.gold
        }

        // Keep the chosen table if it's open, else the richest open one the
        // player can afford a seat at.
        if selectedTier?.unlocked != true {
            let affordable = tiers.last { $0.unlocked && $0.minStake <= data.gold }
            selectedTierKey = (affordable ?? tiers.first(where: \.unlocked) ?? tiers.first)?.key ?? "copper"
        }
        clampStake()

        // A round still in its lobby (the player stepped away) is picked back up.
        if let open = data.activeRound, phase == .seating {
            adopt(open)
            startPolling()
        }
    }

    func selectTier(_ key: String) {
        guard phase == .seating, let tier = tiers.first(where: { $0.key == key }), tier.unlocked else { return }
        selectedTierKey = key
        clampStake()
    }

    private func clampStake() {
        guard let tier = selectedTier else { return }
        if !tier.stakePresets.contains(selectedStake) {
            // The most a player can afford among the presets, at least the minimum.
            selectedStake = tier.stakePresets.last(where: { $0 <= gold }) ?? tier.minStake
        }
    }

    // MARK: - Join / top up

    func join() async {
        guard canJoin, let charId = appState.currentCharacter?.id, let tier = selectedTier else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let data: FortuneTableJoinResponse = try await APIClient.shared.post(
                APIEndpoints.fortuneTableJoin,
                body: FortuneTableJoinRequest(characterId: charId, tier: tier.key, stake: selectedStake)
            )
            appState.currentCharacter?.gold = data.gold
            roundsToday = data.roundsToday
            roundsLimit = data.roundsLimit
            guard let round = data.round else {
                appState.showToast("The table is busy", subtitle: "Try again in a moment", type: .error)
                return
            }
            SFXManager.shared.play(.coinDrop)
            npcSpeech = data.resumed
                ? "Back already? Your seat was kept warm."
                : "Bets are open! Watch who sits down — and how much they bring."
            appState.invalidateCache("quests")
            adopt(round)
            startPolling()
        } catch {
            handle(error, fallback: "Couldn't take a seat")
        }
    }

    func topUp(_ amount: Int) async {
        guard canTopUp(amount), let charId = appState.currentCharacter?.id, let round else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let data: FortuneTableRoundResponse = try await APIClient.shared.post(
                APIEndpoints.fortuneTableTopUp,
                body: FortuneTableTopUpRequest(characterId: charId, roundId: round.id, amount: amount)
            )
            appState.currentCharacter?.gold = data.gold
            if let updated = data.round { adopt(updated) }
            SFXManager.shared.play(.coinDrop)
            npcSpeech = [
                "Bold! Your slice grows.",
                "More gold, more wheel. Fortune notices.",
                "Ooh, the others felt that.",
            ].randomElement() ?? "Bold! Your slice grows."
        } catch {
            handle(error, fallback: "Couldn't add to your stake")
        }
    }

    private func handle(_ error: Error, fallback: String) {
        guard let apiError = error as? APIError else {
            appState.showToast(fallback, subtitle: "Try again later", type: .error)
            return
        }
        switch apiError {
        case .rateLimited(let message), .clientError(_, let message, _):
            appState.showToast(message, type: .error)
        default:
            appState.showToast(fallback, subtitle: apiError.userMessage, type: .error)
        }
    }

    // MARK: - Round state

    /// Take a round from the server: re-anchor the clock and move the phase on.
    private func adopt(_ next: FortuneTableRound) {
        let received = Date.now
        lockAt = received.addingTimeInterval(Double(next.msToLock) / 1000)
        // Half a second earlier than the server: the response was already
        // late by the trip, and a tap still has to travel back.
        topUpCloseAt = received.addingTimeInterval(Double(max(0, next.msToLock - next.topUpCloseMs - 500)) / 1000)

        if let current = round, current.id == next.id {
            // Someone new sat down or raised — the coins land on the table.
            if next.seats.count > current.seats.count || next.pot > current.pot + (next.yourStake - current.yourStake) {
                SFXManager.shared.play(.coinDrop)
            }
        }
        round = next

        switch next.status {
        case "settled":
            if phase != .spinning && phase != .result { phase = .spinning }
        case "drawing":
            if phase == .seating || phase == .lobby { phase = .drawing }
        default:
            if phase == .seating { phase = .lobby }
        }
    }

    /// Poll `/state` until the round is settled: once a second in the lobby,
    /// right at the lock, then backing off if the server stops answering.
    private func startPolling() {
        pollTask?.cancel()
        pollFailures = 0
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let wait: Double
                if self.pollFailures > 0 {
                    wait = min(8, 0.5 * pow(2, Double(self.pollFailures)))
                } else if let lockAt = self.lockAt {
                    let left = lockAt.timeIntervalSinceNow
                    wait = left > 1.2 ? 1.0 : max(0.5, left + 0.15)
                } else {
                    wait = 1.0
                }
                try? await Task.sleep(for: .seconds(wait))
                if Task.isCancelled { return }
                if self.lockAt.map({ $0 <= .now }) == true, self.phase == .lobby {
                    self.phase = .drawing
                    self.npcSpeech = "Bets are closed! Round and round she goes…"
                }
                switch await self.pollOnce() {
                case .settled, .gone:
                    return
                case .pending:
                    self.pollFailures = 0
                case .failed:
                    self.pollFailures += 1
                    if self.pollFailures >= 8 {
                        // The draw is fixed and the server pays it anyway; the
                        // table's history shows it once we can reach it again.
                        self.appState.showToast("Lost track of the table",
                                                subtitle: "Your round is safe — reopen the table to see it",
                                                type: .error)
                        self.resetToSeating()
                        Task { await self.loadStatus() }
                        return
                    }
                }
            }
        }
    }

    /// One `/state` call.
    private func pollOnce() async -> PollOutcome {
        guard let charId = appState.currentCharacter?.id, let round else { return .gone }
        do {
            let data: FortuneTableRoundResponse = try await APIClient.shared.get(
                APIEndpoints.fortuneTableState,
                params: ["character_id": charId, "round_id": round.id]
            )
            // The screen went away while this was in flight: leave() already
            // banked what it could; don't move the phase behind its back.
            if Task.isCancelled { return .gone }
            guard let next = data.round else {
                // A round the server couldn't read was refunded and voided.
                appState.currentCharacter?.gold = data.gold
                appState.showToast("The round was called off", subtitle: "Your stake was returned", type: .info)
                resetToSeating()
                return .gone
            }
            if next.isSettled {
                pendingGold = data.gold
            } else {
                appState.currentCharacter?.gold = data.gold
            }
            adopt(next)
            return next.isSettled ? .settled : .pending
        } catch APIError.clientError(404, _, _) {
            // Character switched or round gone — nothing left to watch.
            resetToSeating()
            Task { await self.loadStatus() }
            return .gone
        } catch {
            return Task.isCancelled ? .gone : .failed
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    /// Screen went away: stop polling; a draw already known is banked quietly.
    func leave() {
        stopPolling()
        if let pendingGold {
            appState.currentCharacter?.gold = pendingGold
            self.pendingGold = nil
        }
        if phase == .spinning {
            // Left mid-spin: the round is decided and paid; show it on return.
            phase = .result
            resultUnseen = true
            appState.invalidateCache("quests")
            appState.invalidateCache("inventory")
        }
    }

    /// Screen came back: pick polling up again for an open round.
    func resume() {
        if phase == .lobby || phase == .drawing { startPolling() }
    }

    /// Called by the view when the wheel has stopped.
    func finishSpin() {
        guard let round, let result = round.result else { return }
        if let pendingGold {
            appState.currentCharacter?.gold = pendingGold
            self.pendingGold = nil
        }
        phase = .result
        if result.won {
            SFXManager.shared.play(.coinsJingle)
            HapticManager.victory()
            npcSpeech = [
                "The pot is yours! Fortune adores you tonight.",
                "Ha! Look at their faces. Spend it well, darling.",
                "The wheel chose you. Again?",
            ].randomElement() ?? "The pot is yours!"
        } else {
            SFXManager.shared.play(.uiError)
            HapticManager.defeat()
            let name = round.winner?.name ?? "Someone"
            npcSpeech = [
                "\(name) takes it this time. The night is young.",
                "So close to your slice… the wheel is fickle.",
                "\(name) won't stop grinning. Win it back?",
            ].randomElement() ?? "\(name) takes it this time."
        }
        appState.invalidateCache("quests")
        appState.invalidateCache("inventory")
    }

    /// Back to choosing a table after the result.
    func playAgain() async {
        resetToSeating()
        await loadStatus()
    }

    private func resetToSeating() {
        stopPolling()
        round = nil
        lockAt = nil
        topUpCloseAt = nil
        pendingGold = nil
        phase = .seating
        npcSpeech = "Another round? The regulars are still at it."
    }
}
