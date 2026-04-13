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
    var predictTimeRemaining: Double = Self.predictWindowSeconds
    var selectedAttackZone: InteractiveBodyZone = .chest
    var selectedDefendZone: InteractiveBodyZone = .chest
    var lastOutcome: InteractiveStrikeOutcome?
    var lastTurn: InteractiveStrikeTurn?
    var lastOpponentTurn: InteractiveStrikeTurn?
    var lastOpponentZones: InteractiveOpponentZones?

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

    deinit {
        predictTimerTask?.cancel()
        strikeTask?.cancel()
        completeTask?.cancel()
        startTask?.cancel()
    }

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
}
