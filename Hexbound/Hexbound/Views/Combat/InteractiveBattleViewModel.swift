//
//  InteractiveBattleViewModel.swift
//  Hexbound
//
//  Interactive Combat v1 — match lifecycle orchestration.
//  Flow: startMatch → (predict → submitStrike → reveal)* → completeMatch → CombatData.
//  Server is authoritative: HP snapshots, opponent zones, and final rewards come
//  from /pvp/match/start, /pvp/strike, and /pvp/match/complete respectively.
//  Gated by INTERACTIVE_COMBAT_V1 on the server (404 → `unavailable` phase,
//  host can route back to classic /pvp/fight).
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class InteractiveBattleViewModel {

    // MARK: - Phase

    enum Phase: Equatable {
        case intro              // Waiting for /pvp/match/start
        case predict            // Player picks zones, timer ticking
        case resolving          // Awaiting /pvp/strike response
        case reveal             // Playing Reveal animation (player strike)
        case summary            // Finishing blow landed — showing full-battle log, awaiting CONTINUE
        case completing         // Awaiting /pvp/match/complete after finish
        case finished(winnerId: String)
        case unavailable        // Feature flag off — classic fight required
        case error(message: String)
    }

    // MARK: - Observable State

    var phase: Phase = .intro
    var state: InteractiveMatchState
    var predictTimeRemaining: Double = InteractiveBattleViewModel.predictWindowSeconds
    var selectedAttackZone: InteractiveBodyZone = .chest
    var selectedDefendZone: InteractiveBodyZone = .chest
    var lastOutcome: InteractiveStrikeOutcome?
    var lastTurn: InteractiveStrikeTurn?
    var lastOpponentTurn: InteractiveStrikeTurn?
    var lastOpponentZones: InteractiveOpponentZones?

    /// Authoritative fighter metadata — populated by `/match/start`.
    /// Used by the view to render YOU / ENEMY portrait cards (name, level, class, avatar).
    var attackerProfile: FighterProfile?
    var defenderProfile: FighterProfile?

    /// Whether the player just tapped SKIP (auto-pick zones).
    /// Purely presentational — flag used to visually highlight the auto-chosen zones.
    var lastStrikeWasSkipped: Bool = false

    /// Auto-submit tracking. `attackTouched` / `defendTouched` flip to `true`
    /// when the player *actively* picks a zone this round (not just the
    /// defaulted .chest). When both become true the VM schedules a short
    /// delayed submit so the player sees their pick land before the strike
    /// fires. Reset each round by `revealCompleted()` + `applyMatchStart()`.
    var attackTouched: Bool = false
    var defendTouched: Bool = false

    /// Transient micro-log ticker shown during `.predict` to remind the
    /// player what just happened. Populated when `applyStrikeResponse`
    /// settles, trimmed to the most recent 3 entries, and individual
    /// entries auto-expire (timestamp-driven TTL handled by the view).
    var microLogEntries: [MicroLogEntry] = []

    /// Final `/match/complete` payload, emitted for navigation to CombatResultDetailView.
    var finalCombatData: CombatData?

    /// Opponent's historical zone pattern (for read strip). Empty in pure-blind mode.
    var opponentPattern: [InteractiveBodyZone] = []

    // MARK: - Interactive Combat v3 — Round Exchange log

    /// The log card payload shown in the space the picker vacates during
    /// `.resolving` / `.reveal`. Populated inside `applyStrikeResponse`,
    /// cleared by `dismissExchange()` (tap or auto-timer) — that dismissal
    /// is ALSO what advances the phase machine to the next round.
    ///
    /// Rendering contract: when this is non-nil, `InteractiveBattleView`
    /// hides the picker and shows `InteractiveRoundLogCard`. The card owns
    /// its own countdown timer and calls back via `dismissExchange`.
    var currentExchange: RoundExchange?

    /// Phase 4 — player-side portrait framing derived from the current
    /// exchange's verdict. Non-nil only for peak verdicts (OUTPLAYED /
    /// OUTREAD). Middle outcomes (STRUCK / HELD) leave the portrait
    /// at its default look.
    var playerOutcomeRole: OutcomeRole? {
        guard let verdict = currentExchange?.verdict else { return nil }
        switch verdict {
        case .outplayed:     return .winner
        case .outread:       return .loser
        case .struck, .held: return nil
        }
    }

    /// Phase 4 — opponent-side portrait framing, mirror of `playerOutcomeRole`.
    var opponentOutcomeRole: OutcomeRole? {
        guard let verdict = currentExchange?.verdict else { return nil }
        switch verdict {
        case .outplayed:     return .loser
        case .outread:       return .winner
        case .struck, .held: return nil
        }
    }

    /// Full chronological log of every round exchange in the battle.
    /// Appended inside `applyStrikeResponse` at the same time `currentExchange`
    /// is set, so the end-of-battle summary can replay the entire sequence
    /// without needing to re-query the server. Cleared only by `cancel()`.
    var battleLog: [RoundExchange] = []

    // MARK: - Intent Hint (Phase 4 — Variant B2)

    /// Rolling history of opponent attack zones, most recent appended last.
    /// Populated from each `/strike` response's `oppZones.attack`. Capped at
    /// `intentHistoryCap` to keep the hint weighted toward recent behavior.
    var opponentAttackHistory: [InteractiveBodyZone] = []

    /// Rolling history of opponent defend zones, same shape as above.
    var opponentDefendHistory: [InteractiveBodyZone] = []

    /// Number of rounds before the intent hint becomes visible. Below this we
    /// don't have enough signal to claim a pattern.
    static let intentMinimumRounds: Int = 2

    /// How many recent rounds the mode picker considers.
    static let intentHistoryCap: Int = 5

    /// Most-frequent attack zone in the recent history — or `nil` when we
    /// don't have enough data yet. View surfaces this via `EnemyIntentPill`.
    var likelyOpponentAttack: InteractiveBodyZone? {
        Self.mostFrequent(opponentAttackHistory,
                          minimum: Self.intentMinimumRounds)
    }

    /// Most-frequent defend zone in the recent history (same rules).
    var likelyOpponentDefend: InteractiveBodyZone? {
        Self.mostFrequent(opponentDefendHistory,
                          minimum: Self.intentMinimumRounds)
    }

    /// Plurality vote over a zone history. Ties break by most-recent pick,
    /// which matches the "they just did X, probably again" player instinct.
    private static func mostFrequent(_ history: [InteractiveBodyZone],
                                     minimum: Int) -> InteractiveBodyZone? {
        guard history.count >= minimum else { return nil }
        var counts: [InteractiveBodyZone: Int] = [:]
        for zone in history { counts[zone, default: 0] += 1 }
        let maxCount = counts.values.max() ?? 0
        // Tiebreak: walk history from newest → oldest and take the first
        // zone whose count equals `maxCount`.
        for zone in history.reversed() where counts[zone] == maxCount {
            return zone
        }
        return nil
    }

    // MARK: - Phase 3: Active Slots

    /// Player's 3 equipped actives with live cooldown state (0 = ready).
    /// Populated by `/match/start`, refreshed by each `/strike` response.
    var playerActives: [InteractiveActiveSlotSnapshot] = []

    /// Opponent's 3 equipped actives (read-only — for UI tell). Cooldowns tick
    /// down but are not player-visible (Phase 3.B will surface opponent use).
    var opponentActives: [InteractiveActiveSlotSnapshot] = []

    /// Slot (0..2) the player queued for THIS pending strike; cleared after reveal.
    /// Nil = regular attack only.
    var pendingActiveSlot: Int? = nil

    /// Label for the active fired on the most recent strike — used for a
    /// floating-text cue ("BURST!" etc.) above the player avatar.
    var lastActiveFiredLabel: String? = nil

    /// Label for the opponent AI's fired active this round (Phase 3.B).
    var lastOpponentActiveFiredLabel: String? = nil

    /// Phase 4.C — `consumable_type` that fired on the most recent player
    /// strike. Drives `ConsumableFireBanner` and is cleared on the next strike
    /// response (or by the view's auto-dismiss timer after ~1.5s).
    var lastPlayerConsumableFired: String? = nil

    /// Phase 4.C — same shape for the opponent. Reserved (opponent AI does not
    /// fire consumables today — see `InteractiveStrikeResponse.opponentConsumableFired`).
    var lastOpponentConsumableFired: String? = nil

    // MARK: - VFX / SFX State

    /// Canvas particle VFX (sparks, flashes). Mounted by the view as an overlay.
    let vfxManager = CombatVFXManager()

    /// PNG image FX overlay (slash, crit text, shields, heal). Mounted above `vfxManager`.
    let fxImageManager = CombatFXImageManager()

    /// Avatar positions in the view's coordinate space, normalized to (0…1).
    /// Set by the view via `GeometryReader` so VFX land on the right avatar
    /// regardless of screen size. Defaults are the fallback layout used by
    /// classic `/fight` replay (attacker-left, defender-right on player turn).
    var playerAvatarPos: CGPoint = CGPoint(x: 0.25, y: 0.30)
    var enemyAvatarPos: CGPoint  = CGPoint(x: 0.75, y: 0.30)

    /// Per-side visual state driven by the animation pipeline. Mirrors
    /// `CombatViewModel.playTurn` — slide-in on attack, flash on hit.
    var playerSlideX: CGFloat = 0
    var enemySlideX: CGFloat = 0
    var playerFlash: Bool = false
    var enemyFlash: Bool = false

    /// Floating damage / heal popups on each fighter. Cap = 5 (GPU guard).
    var damagePopups: [DamagePopup] = []

    /// Whether an animation run is currently in flight. Prevents double-entry.
    private var isAnimating: Bool = false

    // MARK: - Config

    /// Predict window. Spec §3 calls for 6 s at level 1.
    static let predictWindowSeconds: Double = 6.0

    /// Reveal animation budget. Spec §3.4 scripted timeline: 1.4 s.
    static let revealDurationSeconds: Double = 1.4

    static let maxRounds: Int = 15

    // MARK: - Private

    private var predictTimerTask: Task<Void, Never>?
    private var strikeTask: Task<Void, Never>?
    private var completeTask: Task<Void, Never>?
    private var startTask: Task<Void, Never>?
    private var autoSubmitTask: Task<Void, Never>?

    /// Delay between the player's second zone pick and the auto-submit firing.
    /// Gives a reflex window to change mind on the final pick.
    static let autoSubmitDelaySeconds: Double = 0.35

    /// 1-based index of the round the player is currently picking for.
    /// Advances on round transition (after reveal completes). Used by the
    /// round strip above the predict panel.
    var currentRoundNumber: Int {
        battleLog.count + 1
    }

    /// Background `/pvp/match/complete` fired at the moment the match enters
    /// `.summary`, so that by the time the player taps CONTINUE the response
    /// is (usually) already in hand. Single-flight: bc the endpoint is NOT
    /// idempotent — a second call on an already-finalized match returns 409
    /// — we never re-issue once this task is launched.
    private var prefetchCompleteTask: Task<Void, Never>?

    /// Terminal state of the prefetch call. Populated when the task finishes:
    /// `.success(data)` on 2xx, `.failure(error)` otherwise. Consumed by
    /// `continueFromSummary()` so tapping CONTINUE never fires a second
    /// `/complete` request.
    private var prefetchCompleteResult: Result<CombatData, Error>?
    private let appState: AppState
    private let attackerCharacterId: String
    private let defenderCharacterId: String
    /// Tells the server to fork its /match/start logic: `.pvp` hits Character
    /// FKs and ELO; `.bot` synthesizes the opponent from `npc-bots.ts`;
    /// `.dungeonBoss` pulls the boss from the caller's active DungeonRun.
    let opponentType: InteractiveOpponentType

    /// For `.dungeonBoss` opponents — identifier of the active DungeonRun.
    /// Required on the server path; nil for PvP/bot.
    let dungeonRunId: String?

    /// Animation speed toggle — mirrors `CombatViewModel.speedMode` (0 = 1x, 1 = 2x).
    /// 2x halves every sleep/animation duration in `animateStrike`. Flipped by
    /// the SPEED pill in InteractiveBattleView's HUD.
    var speedMode: Int = 0
    var speedMultiplier: Double {
        speedMode == 1 ? 0.5 : 1.0
    }
    var speedLabel: String {
        speedMode == 0 ? "1x" : "2x"
    }

    // MARK: - Init

    /// Initialize with opaque character IDs. Max HPs are provisional until
    /// `/match/start` returns the authoritative snapshot.
    init(appState: AppState,
         attackerCharacterId: String,
         defenderCharacterId: String,
         attackerMaxHp: Int,
         defenderMaxHp: Int,
         attackerCurrentHp: Int? = nil,
         defenderCurrentHp: Int? = nil,
         opponentType: InteractiveOpponentType = .pvp,
         dungeonRunId: String? = nil) {
        self.appState = appState
        self.attackerCharacterId = attackerCharacterId
        self.defenderCharacterId = defenderCharacterId
        self.opponentType = opponentType
        self.dungeonRunId = dungeonRunId
        self.state = InteractiveMatchState(
            matchId: "",   // populated by /match/start
            attackerId: attackerCharacterId,
            defenderId: defenderCharacterId,
            attackerHp: attackerCurrentHp ?? attackerMaxHp,
            defenderHp: defenderCurrentHp ?? defenderMaxHp,
            attackerMaxHp: attackerMaxHp,
            defenderMaxHp: defenderMaxHp
        )
    }

    // NOTE: No deinit cancellation. @MainActor-isolated stored properties can't
    // be touched from a nonisolated deinit under Swift 6 strict concurrency,
    // and Swift 6.1 `isolated deinit` isn't available on our toolchain yet.
    // All tasks capture `[weak self]`; once the VM deallocates they early-
    // return on the next await. For deterministic teardown call `cancel()`
    // from the host view's screen-level `.onDisappear`.

    // MARK: - Lifecycle

    /// Kick off the match. Call from host view's `.onAppear`.
    func startMatch() {
        guard case .intro = phase else { return }
        startTask = Task { [weak self] in
            await self?.performStartMatch()
        }
    }

    /// Called when the player taps Strike or the timer expires.
    func submitStrike() {
        guard case .predict = phase else { return }
        predictTimerTask?.cancel()
        autoSubmitTask?.cancel()
        lastStrikeWasSkipped = false
        phase = .resolving
        strikeTask = Task { [weak self] in
            await self?.resolveStrike()
        }
    }

    /// Actively pick the attack zone and arm the auto-submit timer if both
    /// zones are now player-chosen this round.
    func pickAttack(_ zone: InteractiveBodyZone) {
        guard case .predict = phase else { return }
        selectedAttackZone = zone
        attackTouched = true
        scheduleAutoSubmitIfReady()
    }

    /// Actively pick the defend zone and arm the auto-submit timer if both
    /// zones are now player-chosen this round.
    func pickDefend(_ zone: InteractiveBodyZone) {
        guard case .predict = phase else { return }
        selectedDefendZone = zone
        defendTouched = true
        scheduleAutoSubmitIfReady()
    }

    /// Schedule a delayed auto-submit when both attack and defend have been
    /// actively picked this round. Re-arming (picking another zone again)
    /// cancels the prior task and restarts the delay so the most recent
    /// pick always controls timing.
    private func scheduleAutoSubmitIfReady() {
        autoSubmitTask?.cancel()
        guard attackTouched, defendTouched else { return }
        autoSubmitTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.autoSubmitDelaySeconds))
            if Task.isCancelled { return }
            await MainActor.run {
                guard let self, case .predict = self.phase else { return }
                self.submitStrike()
            }
        }
    }

    /// Called when the player taps SKIP — auto-picks random zones and submits.
    /// Server still resolves normally; from its POV there's no difference.
    func skipAndSubmit() {
        guard case .predict = phase else { return }
        selectedAttackZone = InteractiveBodyZone.allCases.randomElement() ?? .chest
        selectedDefendZone = InteractiveBodyZone.allCases.randomElement() ?? .chest
        predictTimerTask?.cancel()
        lastStrikeWasSkipped = true
        phase = .resolving
        strikeTask = Task { [weak self] in
            await self?.resolveStrike()
        }
    }

    /// Called by the Round Exchange log card on tap-to-skip or when the
    /// auto-dismiss timer elapses. This is the user-driven trigger that
    /// advances the round — when the log is showing, the animation
    /// pipeline does NOT auto-advance (see `animateReveal` tail).
    ///
    /// Guarded so tapping twice in flight can't double-advance the phase.
    func dismissExchange() {
        guard currentExchange != nil else { return }
        currentExchange = nil
        // If the match ended on this round, park in the summary phase so
        // the full-battle log + CONTINUE button can render. Player taps
        // CONTINUE → `continueFromSummary()` → `completeMatch()`.
        // Otherwise fall through to the standard reveal→predict transition.
        if state.isFinished {
            if case .reveal = phase {
                phase = .summary
                prefetchCompleteMatch()
            }
            return
        }
        if case .reveal = phase {
            revealCompleted()
        }
    }

    /// Called by the end-of-battle summary screen's CONTINUE button.
    ///
    /// Three paths:
    ///   1. Prefetch already resolved with success — apply cached data and
    ///      transition straight to `.finished`, skipping `.completing`.
    ///   2. Prefetch in-flight — move to `.completing`, await the same task,
    ///      then apply whatever it produces.
    ///   3. Prefetch never launched (defensive fallback) — run the original
    ///      `completeMatch()` pipeline.
    func continueFromSummary() {
        guard case .summary = phase else { return }

        if let cached = prefetchCompleteResult {
            applyCompleteResult(cached)
            return
        }

        if let task = prefetchCompleteTask {
            phase = .completing
            Task { [weak self] in
                await task.value
                guard let self, case .completing = self.phase else { return }
                if let result = self.prefetchCompleteResult {
                    self.applyCompleteResult(result)
                } else {
                    self.completeMatch()
                }
            }
            return
        }

        completeMatch()
    }

    /// Kick off `/pvp/match/complete` in the background at the moment the
    /// match enters `.summary`, so that by the time the player taps CONTINUE
    /// the response is usually already in hand. Single-flight: the endpoint
    /// is NOT idempotent — a second call returns 409 — so we launch at most
    /// one request per match.
    private func prefetchCompleteMatch() {
        guard prefetchCompleteTask == nil else { return }
        prefetchCompleteTask = Task { [weak self] in
            await self?.performPrefetchComplete()
        }
    }

    private func performPrefetchComplete() async {
        let body = InteractiveMatchCompleteRequest(matchId: state.matchId)
        do {
            let data: CombatData = try await APIClient.shared.post(
                APIEndpoints.pvpMatchComplete,
                body: body
            )
            prefetchCompleteResult = .success(data)
        } catch {
            prefetchCompleteResult = .failure(error)
        }
    }

    private func applyCompleteResult(_ result: Result<CombatData, Error>) {
        switch result {
        case .success(let data):
            finalCombatData = data
            let winnerId = data.result.winnerId ?? state.winnerId ?? state.defenderId
            phase = .finished(winnerId: winnerId)
        case .failure(let error):
            if case APIError.clientError(let status, _, _) = error, status == 404 {
                phase = .unavailable
                return
            }
            let msg = (error as? APIError)?.errorDescription ?? "Failed to complete match"
            phase = .error(message: msg)
        }
    }

    /// Called by the view when the Reveal animation finishes.
    func revealCompleted() {
        guard case .reveal = phase else { return }
        if state.isFinished {
            // Park in summary so the end-of-battle screen can render even
            // when the `currentExchange` log card isn't shown (degraded /
            // direct-advance paths). CONTINUE → `completeMatch()`.
            phase = .summary
            prefetchCompleteMatch()
            return
        }
        lastOutcome = nil
        lastTurn = nil
        lastOpponentTurn = nil
        lastOpponentZones = nil
        lastActiveFiredLabel = nil
        lastOpponentActiveFiredLabel = nil
        lastPlayerConsumableFired = nil
        lastOpponentConsumableFired = nil
        attackTouched = false
        defendTouched = false
        autoSubmitTask?.cancel()
        predictTimeRemaining = Self.predictWindowSeconds
        startPredictTimer()
        phase = .predict
    }

    func cancel() {
        predictTimerTask?.cancel()
        strikeTask?.cancel()
        completeTask?.cancel()
        startTask?.cancel()
        autoSubmitTask?.cancel()
    }

    // MARK: - Timer

    private func startPredictTimer() {
        predictTimerTask?.cancel()
        predictTimeRemaining = Self.predictWindowSeconds
        predictTimerTask = Task { [weak self] in
            guard let self else { return }
            let tickMs: UInt64 = 100
            while predictTimeRemaining > 0 {
                try? await Task.sleep(nanoseconds: tickMs * 1_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    self.predictTimeRemaining = max(0, self.predictTimeRemaining - Double(tickMs) / 1000.0)
                }
            }
            if Task.isCancelled { return }
            await MainActor.run {
                if case .predict = self.phase {
                    self.submitStrike()
                }
            }
        }
    }

    // MARK: - /match/start

    private func performStartMatch() async {
        let body = InteractiveMatchStartRequest(
            characterId: attackerCharacterId,
            opponentId: defenderCharacterId,
            opponentType: opponentType.rawValue,
            dungeonRunId: dungeonRunId
        )
        do {
            let response: InteractiveMatchStartResponse = try await APIClient.shared.post(
                APIEndpoints.pvpMatchStart,
                body: body
            )
            await applyMatchStart(response)
        } catch let APIError.clientError(status, _, _) where status == 404 {
            phase = .unavailable
        } catch {
            let msg = (error as? APIError)?.errorDescription ?? "Failed to start match"
            phase = .error(message: msg)
        }
    }

    private func applyMatchStart(_ response: InteractiveMatchStartResponse) async {
        state.matchId = response.matchId
        state.attackerHp = response.attacker.currentHp
        state.defenderHp = response.defender.currentHp
        attackerProfile = FighterProfile(snapshot: response.attacker)
        defenderProfile = FighterProfile(snapshot: response.defender)
        playerActives = response.actives?.p1 ?? []
        opponentActives = response.actives?.p2 ?? []
        state.serverFinished = false
        state.serverWinnerId = nil
        pendingActiveSlot = nil
        lastOutcome = nil
        lastTurn = nil
        lastOpponentTurn = nil
        lastOpponentZones = nil
        lastActiveFiredLabel = nil
        lastOpponentActiveFiredLabel = nil
        lastPlayerConsumableFired = nil
        lastOpponentConsumableFired = nil
        currentExchange = nil
        battleLog.removeAll(keepingCapacity: true)
        damagePopups.removeAll(keepingCapacity: true)
        microLogEntries.removeAll(keepingCapacity: true)
        attackTouched = false
        defendTouched = false
        autoSubmitTask?.cancel()
        // Fresh match — wipe any prior-match intent history so the hint
        // rebuilds from this duel's observations only.
        opponentAttackHistory.removeAll(keepingCapacity: true)
        opponentDefendHistory.removeAll(keepingCapacity: true)
        predictTimeRemaining = Self.predictWindowSeconds
        startPredictTimer()
        phase = .predict
    }

    // MARK: - Active Slots (Phase 3)

    /// Toggle the queued active for this pending strike. Only one active can
    /// fire per round. Tapping a ready slot arms it; tapping the armed slot
    /// cancels. Cooldown/empty slots are ignored.
    func toggleActiveSlot(_ slotIndex: Int) {
        guard case .predict = phase else { return }
        guard let slot = playerActives.first(where: { $0.slotIndex == slotIndex }) else { return }
        guard slot.isReady else { return }
        pendingActiveSlot = (pendingActiveSlot == slotIndex) ? nil : slotIndex
    }

    // MARK: - /strike

    private func resolveStrike() async {
        guard !state.matchId.isEmpty else {
            phase = .error(message: "Match not started")
            return
        }
        let request = InteractiveStrikeRequest(
            matchId: state.matchId,
            attackerZone: selectedAttackZone,
            defenderZone: selectedDefendZone,
            playerActiveSlot: pendingActiveSlot
        )
        do {
            let response: InteractiveStrikeResponse = try await APIClient.shared.post(
                APIEndpoints.pvpStrike,
                body: request
            )
            await applyStrikeResponse(response)
        } catch let apiError as APIError {
            if handleRecoverableStrikeError(apiError) {
                return
            }
            switch apiError {
            case .clientError(let status, _, _) where status == 404:
                phase = .unavailable
            case .clientError(let status, _, _) where status == 410:
                phase = .error(message: "Match timed out")
            default:
                phase = .error(message: apiError.userMessage)
            }
        } catch {
            phase = .error(message: "Strike failed")
        }
    }

    /// Recoverable server-side reconcile path: the match snapshot still had a
    /// potion slot, but the real inventory no longer does. In that case the
    /// backend strips the slot from the match, returns updated actives, and the
    /// duel should continue from predict instead of terminating the whole flow.
    private func handleRecoverableStrikeError(_ apiError: APIError) -> Bool {
        guard apiError.statusCode == 409,
              let payload = apiError.decodedResponseBody(InteractiveRecoverableStrikePayload.self),
              payload.code == "OUT_OF_CONSUMABLE" else {
            return false
        }

        if let reconciledActives = payload.actives {
            playerActives = reconciledActives.p1
            opponentActives = reconciledActives.p2
        }

        pendingActiveSlot = nil
        lastStrikeWasSkipped = false
        currentExchange = nil
        phase = .predict
        startPredictTimer()

        let removedConsumableType = payload.removedConsumableType
        let consumableName = removedConsumableType.flatMap { ConsumableCatalog.displayName(for: $0) } ?? "Potion"
        appState.showToast(
            "\(consumableName) unavailable",
            subtitle: "That slot was removed from this match.",
            type: .info
        )
        return true
    }

    private func applyStrikeResponse(_ response: InteractiveStrikeResponse) async {
        // Refresh actives state first — server is authoritative on cooldowns.
        if let actives = response.actives {
            playerActives = actives.p1
            opponentActives = actives.p2
        }
        lastActiveFiredLabel = response.playerActiveLabel
        lastOpponentActiveFiredLabel = response.opponentActiveLabel
        // Phase 4.C — surface consumable fire to the HUD banner. Server
        // emits these fields only on strikes where a potion actually fired,
        // so assignment-without-guard is safe (nil on normal rounds).
        lastPlayerConsumableFired = response.playerConsumableFired
        lastOpponentConsumableFired = response.opponentConsumableFired
        pendingActiveSlot = nil
        // Phase 4 polish — SFX per fired active. Opponent and player fire on
        // the same tick; dispatch both with a tiny stagger so they don't step
        // on each other. Player SFX plays first (their choice, their reward).
        Self.playActiveFireSFX(labelRaw: response.playerActiveLabel)
        if response.opponentActiveLabel != nil {
            Task { [label = response.opponentActiveLabel] in
                try? await Task.sleep(for: .milliseconds(120))
                await MainActor.run { Self.playActiveFireSFX(labelRaw: label) }
            }
        }
        // Dedicated potion SFX — distinct from talent-fire SFX. Fires once on
        // the round the player drinks. Uses the `.potionUse` case from SFXCatalog
        // so the moment never lands silently.
        if response.playerConsumableFired != nil {
            SFXManager.shared.play(.potionUse)
        }

        state.strikes.append(response.playerStrike)
        if let opp = response.opponentStrike {
            state.strikes.append(opp)
            lastOpponentTurn = opp
        }
        state.serverFinished = response.matchFinished
        state.serverWinnerId = response.winnerId
        lastOpponentZones = response.oppZones

        // Intent hint — append this round's opponent zones and clamp the
        // history to the most recent `intentHistoryCap` entries so the
        // mode picker stays weighted toward recent behavior.
        opponentAttackHistory.append(response.oppZones.attack)
        opponentDefendHistory.append(response.oppZones.defend)
        if opponentAttackHistory.count > Self.intentHistoryCap {
            opponentAttackHistory.removeFirst(opponentAttackHistory.count - Self.intentHistoryCap)
        }
        if opponentDefendHistory.count > Self.intentHistoryCap {
            opponentDefendHistory.removeFirst(opponentDefendHistory.count - Self.intentHistoryCap)
        }

        let outcome = InteractiveStrikeOutcome.classify(
            turn: response.playerStrike,
            attackerZone: selectedAttackZone,
            defenderZone: selectedDefendZone
        )
        lastTurn = response.playerStrike
        lastOutcome = outcome

        // v3 — build the Round Exchange log so the view can swap the
        // picker for the log card the moment phase flips to `.reveal`.
        let playerName  = attackerProfile?.name ?? "You"
        let enemyName   = defenderProfile?.name ?? "Enemy"
        let roundNumber = response.strikeIndex + 1
        let exchange = RoundExchange.build(
            from: response,
            roundNumber: roundNumber,
            playerName: playerName,
            opponentName: enemyName,
            playerAttackZone: selectedAttackZone,
            playerDefendZone: selectedDefendZone
        )
        currentExchange = exchange
        battleLog.append(exchange)
        appendMicroLog(
            response: response,
            playerAttackZone: selectedAttackZone,
            playerDefendZone: selectedDefendZone
        )

        // Enter reveal and run the scripted VFX/SFX/HP-tween sequence.
        // HP is NOT set to the final server value up front — `animateStrike`
        // tweens it per-turn so the duel header bar animates naturally.
        // A final reconcile step snaps to the authoritative server values
        // to paper over any rounding / status-tick divergence.
        phase = .reveal
        await animateReveal(
            player: response.playerStrike,
            opponent: response.opponentStrike,
            targetAttackerHp: response.attackerHp,
            targetDefenderHp: response.defenderHp
        )
    }

    // MARK: - Micro Log

    /// Push up to two entries (you + enemy) into `microLogEntries` for the
    /// round that just resolved. Entries auto-expire by TTL in the view;
    /// we also clamp the buffer to the 3 most recent so fast rounds don't
    /// accumulate stale lines if the view is backgrounded.
    private func appendMicroLog(response: InteractiveStrikeResponse,
                                playerAttackZone: InteractiveBodyZone,
                                playerDefendZone: InteractiveBodyZone) {
        let oppZones = response.oppZones
        let youEntry = makeMicroEntry(
            side: .you,
            turn: response.playerStrike,
            attackZone: playerAttackZone,
            defendZone: oppZones.defend
        )
        microLogEntries.append(youEntry)

        if let oppTurn = response.opponentStrike {
            let enemyEntry = makeMicroEntry(
                side: .enemy,
                turn: oppTurn,
                attackZone: oppZones.attack,
                defendZone: playerDefendZone
            )
            microLogEntries.append(enemyEntry)
        }

        // Keep the most recent 3 entries only — the view shows at most 3
        // lines, and a tight cap keeps the buffer obviously bounded.
        if microLogEntries.count > 3 {
            microLogEntries.removeFirst(microLogEntries.count - 3)
        }
    }

    private func makeMicroEntry(side: MicroLogEntry.Side,
                                turn: InteractiveStrikeTurn,
                                attackZone: InteractiveBodyZone,
                                defendZone: InteractiveBodyZone) -> MicroLogEntry {
        let kind: MicroLogEntry.Kind
        if turn.isDodge == true        { kind = .dodge }
        else if turn.isMiss == true    { kind = .miss }
        else if turn.isCrit == true    { kind = .crit }
        else if turn.damage <= 0       { kind = .block }
        else                           { kind = .hit }

        let label = "\(attackZone.rawValue.uppercased()) → \(defendZone.rawValue.uppercased())"
        return MicroLogEntry(
            side: side,
            kind: kind,
            zoneLabel: label,
            damage: max(0, turn.damage)
        )
    }

    // MARK: - Reveal Animation Pipeline

    /// Plays the scripted reveal for this round: player strike → (brief gap)
    /// → opponent counter-strike → HP reconcile → phase advance.
    /// Mirrors `CombatViewModel.playTurn` but driven by server Turns rather
    /// than a pre-computed log. Slide, VFX particles, PNG FX overlay, SFX,
    /// damage popups, flash, and HP tween all fire per strike.
    private func animateReveal(
        player: InteractiveStrikeTurn,
        opponent: InteractiveStrikeTurn?,
        targetAttackerHp: Int,
        targetDefenderHp: Int
    ) async {
        guard !isAnimating else { return }
        isAnimating = true
        defer { isAnimating = false }

        // 1) Player attacks defender
        let playerLog = combatLogFrom(turn: player, fallbackAttackerId: state.attackerId)
        await animateStrike(log: playerLog, isPlayerAttacking: true)

        // 2) Defender counters (if alive)
        if let opp = opponent {
            try? await Task.sleep(for: .seconds(0.25))
            let oppLog = combatLogFrom(turn: opp, fallbackAttackerId: state.defenderId)
            await animateStrike(log: oppLog, isPlayerAttacking: false)
        }

        // 3) Reconcile to authoritative server HP (handles status ticks / rounding)
        withAnimation(.easeInOut(duration: 0.2)) {
            state.attackerHp = max(0, targetAttackerHp)
            state.defenderHp = max(0, targetDefenderHp)
        }
        try? await Task.sleep(for: .seconds(0.2))

        // 4) Phase advance
        //
        // v3 Round Exchange log — when a `currentExchange` is on-screen,
        // the user (or the card's auto-dismiss timer) is responsible for
        // advancing the round via `dismissExchange()`. Auto-advancing here
        // would yank the picker back in while the log is still reading.
        // When there's no log (degraded mode / older clients), fall back
        // to the original automatic advance.
        if currentExchange != nil {
            return
        }
        if state.isFinished {
            // Route terminal rounds through the summary screen — same as
            // the log-card dismissal path in `dismissExchange()`.
            phase = .summary
            prefetchCompleteMatch()
        } else {
            revealCompleted()
        }
    }

    /// Animates a single strike using the classic `playTurn` pipeline:
    /// slide-in → VFX+SFX+PNG FX → flash → damage popup → HP tween → slide back.
    private func animateStrike(log: CombatLog, isPlayerAttacking: Bool) async {
        let sm: Double = speedMultiplier

        let defenderPos = isPlayerAttacking ? enemyAvatarPos  : playerAvatarPos
        let attackerPos = isPlayerAttacking ? playerAvatarPos : enemyAvatarPos

        // 1) Slide-in
        withAnimation(.easeOut(duration: 0.15 * sm)) {
            if isPlayerAttacking { playerSlideX = 40 } else { enemySlideX = -40 }
        }
        try? await Task.sleep(for: .seconds(0.15 * sm))

        let fxDescriptor = CombatFXAssetMap.fxForTurn(log, isPlayerAttacking: isPlayerAttacking)

        // 2) Outcome VFX / SFX / PNG FX
        if log.isDodge {
            vfxManager.trigger(.dodge, at: defenderPos, speed: sm)
            SFXManager.shared.play(.combatDodge)
            if let fx = fxDescriptor {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }
        } else if log.isMiss {
            vfxManager.trigger(.miss, at: defenderPos, speed: sm)
            SFXManager.shared.play(.combatMiss)
            if let fx = fxDescriptor {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }
        } else if log.isBlocked {
            vfxManager.trigger(.block, at: defenderPos, speed: sm)
            SFXManager.shared.play(.combatBlock)
            if let fx = fxDescriptor {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }
            withAnimation(.easeInOut(duration: 0.1)) {
                if isPlayerAttacking { enemyFlash = true } else { playerFlash = true }
            }
            try? await Task.sleep(for: .seconds(0.1 * sm))
            withAnimation(.easeInOut(duration: 0.1)) {
                enemyFlash = false
                playerFlash = false
            }
        }

        if !log.isMiss && !log.isDodge && !log.isBlocked && log.damage > 0 {
            let vfxType = VFXEffectType.from(log)
            vfxManager.trigger(vfxType, at: defenderPos, speed: sm)
            SFXManager.shared.play(SFX.from(vfxType: vfxType))
            if let fx = fxDescriptor {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }

            withAnimation(.easeInOut(duration: 0.1)) {
                if isPlayerAttacking { enemyFlash = true } else { playerFlash = true }
            }
            try? await Task.sleep(for: .seconds(0.15 * sm))
            withAnimation(.easeInOut(duration: 0.1)) {
                enemyFlash = false
                playerFlash = false
            }
        }

        // 3) Damage popup
        spawnDamagePopup(log: log, isPlayerAttacking: isPlayerAttacking)

        // 4) Heal FX (if any) + HP tween
        if let heal = log.heal, heal > 0 {
            vfxManager.trigger(.heal, at: attackerPos, speed: sm)
            SFXManager.shared.play(.combatHeal)
            let healFX = CombatFXAssetMap.healFX()
            fxImageManager.trigger(healFX, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
        }

        withAnimation(.easeInOut(duration: 0.3 * sm)) {
            if isPlayerAttacking {
                state.defenderHp = max(0, state.defenderHp - log.damage)
                if let heal = log.heal, heal > 0 {
                    state.attackerHp = min(state.attackerMaxHp, state.attackerHp + heal)
                }
            } else {
                state.attackerHp = max(0, state.attackerHp - log.damage)
                if let heal = log.heal, heal > 0 {
                    state.defenderHp = min(state.defenderMaxHp, state.defenderHp + heal)
                }
            }
        }
        try? await Task.sleep(for: .seconds(0.3 * sm))

        // 5) Slide back
        withAnimation(.easeIn(duration: 0.15 * sm)) {
            playerSlideX = 0
            enemySlideX = 0
        }
        try? await Task.sleep(for: .seconds(0.15 * sm))
    }

    private func spawnDamagePopup(log: CombatLog, isPlayerAttacking: Bool) {
        let popup: DamagePopup
        if log.isMiss {
            popup = DamagePopup(text: "Missed!", color: DarkFantasyTheme.textTertiary, isCrit: false, onDefender: !isPlayerAttacking)
        } else if log.isDodge {
            popup = DamagePopup(text: "Dodged!", color: DarkFantasyTheme.textTertiary, isCrit: false, onDefender: !isPlayerAttacking)
        } else {
            let text = log.isCrit ? "\(log.damage)!" : "\(log.damage)"
            let dmgStyle = DamageTypeStyle(from: log.damageType)
            popup = DamagePopup(text: text, color: dmgStyle.color, isCrit: log.isCrit, onDefender: !isPlayerAttacking)
        }
        if damagePopups.count >= 5 { damagePopups.removeFirst() }
        damagePopups.append(popup)

        if let heal = log.heal, heal > 0 {
            if damagePopups.count >= 5 { damagePopups.removeFirst() }
            let healPopup = DamagePopup(text: "+\(heal)", color: DarkFantasyTheme.success, isCrit: false, onDefender: isPlayerAttacking)
            damagePopups.append(healPopup)
        }

        let popupId = popup.id
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.0))
            self?.damagePopups.removeAll { $0.id == popupId }
        }
    }

    /// Adapt `InteractiveStrikeTurn` (match-aware DTO) → `CombatLog` so we can
    /// reuse `CombatFXAssetMap`, `VFXEffectType.from`, `SFX.from(vfxType:)` and
    /// `DamageTypeStyle` without duplicating mapping logic. `isBlocked` isn't
    /// a separate server flag — it's inferred when damage==0 with no miss/dodge.
    private func combatLogFrom(turn: InteractiveStrikeTurn, fallbackAttackerId: String) -> CombatLog {
        let miss = turn.isMiss ?? false
        let dodge = turn.isDodge ?? false
        let blocked = !miss && !dodge && turn.damage <= 0
        return CombatLog(
            attackerId: turn.attackerId ?? fallbackAttackerId,
            action: turn.skillUsed,
            targetZone: turn.targetZone,
            defendZone: turn.defendZone,
            damage: max(0, turn.damage),
            isCrit: turn.isCrit ?? false,
            isMiss: miss,
            isDodge: dodge,
            isBlocked: blocked,
            statusApplied: turn.statusApplied,
            heal: turn.healAmount,
            damageType: turn.damageType,
            skillUsed: turn.skillUsed
        )
    }

    // MARK: - /match/complete

    private func completeMatch() {
        phase = .completing
        completeTask = Task { [weak self] in
            await self?.performCompleteMatch()
        }
    }

    private func performCompleteMatch() async {
        let body = InteractiveMatchCompleteRequest(matchId: state.matchId)
        do {
            let data: CombatData = try await APIClient.shared.post(
                APIEndpoints.pvpMatchComplete,
                body: body
            )
            finalCombatData = data
            let winnerId = data.result.winnerId ?? state.winnerId ?? state.defenderId
            phase = .finished(winnerId: winnerId)
        } catch let APIError.clientError(status, _, _) where status == 404 {
            phase = .unavailable
        } catch {
            let msg = (error as? APIError)?.errorDescription ?? "Failed to complete match"
            phase = .error(message: msg)
        }
    }

    // MARK: - Active SFX dispatch (Phase 4 polish)

    /// Maps a TalentSlotAction raw label from the /strike response to the
    /// SFX file baked into the bundle. No-op when the label is nil or unknown.
    static func playActiveFireSFX(labelRaw: String?) {
        guard let raw = labelRaw, let action = TalentSlotAction(rawValue: raw) else { return }
        let sfx: SFX
        switch action {
        case .burstDamage: sfx = .hitCritical
        case .healSelf:    sfx = .combatHeal
        case .shieldSelf:  sfx = .combatShield
        case .stunEnemy:   sfx = .combatBuff
        case .execute:     sfx = .combatDeath
        }
        SFXManager.shared.play(sfx)
    }
}

// MARK: - Convenience

extension InteractiveBattleViewModel.Phase {
    var isPredicting: Bool {
        if case .predict = self { return true }
        return false
    }
    var isRevealing: Bool {
        if case .reveal = self { return true }
        return false
    }
    var isBusy: Bool {
        switch self {
        case .resolving, .reveal, .completing: return true
        default: return false
        }
    }
    var isSummary: Bool {
        if case .summary = self { return true }
        return false
    }
}

// MARK: - Micro Log Entry
//
// Transient one-line recap of a single strike within an exchange, shown as
// an inline auto-expiring ticker above the predict panel. Two entries are
// pushed per round (player strike + opponent strike), each with a creation
// timestamp so the view can fade them out after their TTL.

struct MicroLogEntry: Identifiable, Equatable, Sendable {
    enum Side: Sendable { case you, enemy }
    enum Kind: Sendable { case hit, crit, block, dodge, miss }

    let id: UUID
    let side: Side
    let kind: Kind
    let zoneLabel: String   // "HEAD → CHEST"
    let damage: Int         // 0 for block/dodge/miss
    let createdAt: Date

    init(id: UUID = UUID(),
         side: Side,
         kind: Kind,
         zoneLabel: String,
         damage: Int,
         createdAt: Date = Date()) {
        self.id = id
        self.side = side
        self.kind = kind
        self.zoneLabel = zoneLabel
        self.damage = damage
        self.createdAt = createdAt
    }

    /// Lifetime of a single ticker entry before the view fades it out.
    static let ttl: TimeInterval = 2.4
}

// MARK: - Fighter Profile (view-ready snapshot)

/// View-ready snapshot of a fighter populated from `/pvp/match/start`.
/// Decouples view code from the raw DTO and provides safe defaults so
/// portraits render even when the server omits optional fields.
struct FighterProfile: Equatable, Sendable {
    let id: String
    let name: String
    let level: Int
    let characterClass: CharacterClass
    let avatar: String?

    init(id: String,
         name: String,
         level: Int,
         characterClass: CharacterClass,
         avatar: String?) {
        self.id = id
        self.name = name
        self.level = level
        self.characterClass = characterClass
        self.avatar = avatar
    }

    /// Adapt the decoded snapshot — tolerate missing/invalid class strings.
    init(snapshot: InteractiveCharacterSnapshot) {
        self.id = snapshot.id
        self.name = snapshot.characterName?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? snapshot.characterName!
            : "Unknown"
        self.level = snapshot.level ?? 1
        self.characterClass = snapshot.characterClass
            .flatMap { CharacterClass(rawValue: $0.lowercased()) } ?? .warrior
        self.avatar = snapshot.avatar
    }
}

// MARK: - Combat Log Row (view-ready)

/// One row rendered in the combat log. Derived from `InteractiveStrikeTurn`
/// + fighter profiles so the view never has to cross-reference IDs itself.
struct InteractiveCombatLogRow: Identifiable, Equatable {
    let id: Int
    let attackerName: String
    let targetZone: String          // "Head" / "Chest" / "Legs"
    let damage: Int
    let healAmount: Int             // positive = healing tick
    let damageTypeLabel: String?    // "Physical" / "Magical" / "True" / "Poison"
    let damageTypeIcon: String?     // SF Symbol
    let outcomeLabel: String?       // "MISS" / "DODGE" / "CRIT" / nil for normal hit
    let isPlayer: Bool
}

extension InteractiveBattleViewModel {
    /// View-ready combat log — built on each access from `state.strikes`.
    /// Kept as a computed property (not stored) so it auto-updates when
    /// strikes append, without an extra @Observable property to coordinate.
    var combatLogRows: [InteractiveCombatLogRow] {
        let attackerId = state.attackerId
        return state.strikes.enumerated().map { idx, turn in
            let isPlayerStrike = (turn.attackerId ?? "") == attackerId
            let attackerName = isPlayerStrike
                ? (attackerProfile?.name ?? "You")
                : (defenderProfile?.name ?? "Enemy")
            let zone = (turn.targetZone ?? "").capitalized
            let zoneLabel = zone.isEmpty ? "—" : zone
            let heal = turn.healAmount ?? 0
            let outcome: String? = {
                if turn.isMiss == true { return "MISS" }
                if turn.isDodge == true { return "DODGE" }
                if turn.isCrit == true { return "CRIT" }
                return nil
            }()
            let type = turn.damageType?.lowercased()
            return InteractiveCombatLogRow(
                id: idx,
                attackerName: attackerName,
                targetZone: zoneLabel,
                damage: max(0, turn.damage),
                healAmount: max(0, heal),
                damageTypeLabel: Self.damageTypeLabel(type),
                damageTypeIcon: Self.damageTypeIcon(type),
                outcomeLabel: outcome,
                isPlayer: isPlayerStrike
            )
        }
    }

    private static func damageTypeLabel(_ type: String?) -> String? {
        switch type {
        case "physical": return "Physical"
        case "magical": return "Magical"
        case "true_damage", "true": return "True"
        case "poison": return "Poison"
        default: return nil
        }
    }

    private static func damageTypeIcon(_ type: String?) -> String? {
        switch type {
        case "physical": return "figure.walk"
        case "magical": return "sparkles"
        case "true_damage", "true": return "bolt.fill"
        case "poison": return "drop.fill"
        default: return nil
        }
    }
}
