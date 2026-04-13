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

    /// Final `/match/complete` payload, emitted for navigation to CombatResultDetailView.
    var finalCombatData: CombatData?

    /// Opponent's historical zone pattern (for read strip). Empty in pure-blind mode.
    var opponentPattern: [InteractiveBodyZone] = []

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
    private let appState: AppState
    private let attackerCharacterId: String
    private let defenderCharacterId: String

    // MARK: - Init

    /// Initialize with opaque character IDs. Max HPs are provisional until
    /// `/match/start` returns the authoritative snapshot.
    init(appState: AppState,
         attackerCharacterId: String,
         defenderCharacterId: String,
         attackerMaxHp: Int,
         defenderMaxHp: Int,
         attackerCurrentHp: Int? = nil,
         defenderCurrentHp: Int? = nil) {
        self.appState = appState
        self.attackerCharacterId = attackerCharacterId
        self.defenderCharacterId = defenderCharacterId
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
        lastStrikeWasSkipped = false
        phase = .resolving
        strikeTask = Task { [weak self] in
            await self?.resolveStrike()
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

    /// Called by the view when the Reveal animation finishes.
    func revealCompleted() {
        guard case .reveal = phase else { return }
        if state.isFinished {
            completeMatch()
            return
        }
        lastOutcome = nil
        lastTurn = nil
        lastOpponentTurn = nil
        lastOpponentZones = nil
        predictTimeRemaining = Self.predictWindowSeconds
        startPredictTimer()
        phase = .predict
    }

    func cancel() {
        predictTimerTask?.cancel()
        strikeTask?.cancel()
        completeTask?.cancel()
        startTask?.cancel()
        revealAdvanceTask?.cancel()
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
            opponentId: defenderCharacterId
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
        predictTimeRemaining = Self.predictWindowSeconds
        startPredictTimer()
        phase = .predict
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
            defenderZone: selectedDefendZone
        )
        do {
            let response: InteractiveStrikeResponse = try await APIClient.shared.post(
                APIEndpoints.pvpStrike,
                body: request
            )
            await applyStrikeResponse(response)
        } catch let APIError.clientError(status, _, _) where status == 404 {
            phase = .unavailable
        } catch let APIError.clientError(status, _, _) where status == 410 {
            phase = .error(message: "Match timed out")
        } catch {
            let msg = (error as? APIError)?.errorDescription ?? "Strike failed"
            phase = .error(message: msg)
        }
    }

    private func applyStrikeResponse(_ response: InteractiveStrikeResponse) async {
        state.strikes.append(response.playerStrike)
        if let opp = response.opponentStrike {
            state.strikes.append(opp)
            lastOpponentTurn = opp
        }
        state.attackerHp = max(0, response.attackerHp)
        state.defenderHp = max(0, response.defenderHp)
        lastOpponentZones = response.oppZones

        let outcome = InteractiveStrikeOutcome.classify(
            turn: response.playerStrike,
            attackerZone: selectedAttackZone,
            defenderZone: selectedDefendZone
        )
        lastTurn = response.playerStrike
        lastOutcome = outcome

        // If server says match_finished, fast-path: still play reveal, then complete.
        phase = .reveal
        scheduleRevealAutoAdvance()
    }

    /// Since the view no longer mounts a dedicated Reveal screen (reveal is an
    /// in-place HP animation on the duel header), the VM drives the phase
    /// transition itself. After `revealDurationSeconds` we roll into the next
    /// predict round — or into `completing` if the match is over.
    private var revealAdvanceTask: Task<Void, Never>?
    private func scheduleRevealAutoAdvance() {
        revealAdvanceTask?.cancel()
        revealAdvanceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.revealDurationSeconds))
            if Task.isCancelled { return }
            await MainActor.run {
                guard let self else { return }
                if case .reveal = self.phase {
                    self.revealCompleted()
                }
            }
        }
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
            phase = .finished(winnerId: state.winnerId ?? state.defenderId)
        } catch let APIError.clientError(status, _, _) where status == 404 {
            phase = .unavailable
        } catch {
            let msg = (error as? APIError)?.errorDescription ?? "Failed to complete match"
            phase = .error(message: msg)
        }
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
