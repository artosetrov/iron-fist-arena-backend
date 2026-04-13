//
//  InteractiveBattleViewModel.swift
//  Hexbound
//
//  Interactive Combat v1 — client-side match state + strike orchestration.
//  Parallel to existing CombatViewModel. Gated by INTERACTIVE_COMBAT_V1 on server.
//  If server returns 404 (flag off), the VM falls back to `unavailable` state
//  and the screen can gracefully route back to classic /pvp/fight.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class InteractiveBattleViewModel {

    // MARK: - Phase

    enum Phase: Equatable {
        case intro              // Opponent reveal / loadout lock
        case predict            // Player picks zones + optional skill, timer ticking
        case resolving          // Waiting for /pvp/strike response
        case reveal             // Playing Reveal animation
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

    /// Opponent's historical zone pattern (for read strip). Populated from
    /// loadout preload. Empty in pure-blind mode.
    var opponentPattern: [InteractiveBodyZone] = []

    // MARK: - Config

    /// Predict window. Spec §3 calls for 6 s at level 1, tightening possible
    /// in later phases based on telemetry.
    static let predictWindowSeconds: Double = 6.0

    /// Reveal animation budget. Spec §3.4 scripted timeline: 1.4 s.
    static let revealDurationSeconds: Double = 1.4

    // MARK: - Private

    private var predictTimerTask: Task<Void, Never>?
    private var strikeTask: Task<Void, Never>?
    private let appState: AppState

    // MARK: - Init

    init(appState: AppState,
         matchId: String = UUID().uuidString,
         attackerId: String,
         defenderId: String,
         attackerMaxHp: Int,
         defenderMaxHp: Int,
         attackerCurrentHp: Int? = nil,
         defenderCurrentHp: Int? = nil) {
        self.appState = appState
        self.state = InteractiveMatchState(
            matchId: matchId,
            attackerId: attackerId,
            defenderId: defenderId,
            attackerHp: attackerCurrentHp ?? attackerMaxHp,
            defenderHp: defenderCurrentHp ?? defenderMaxHp,
            attackerMaxHp: attackerMaxHp,
            defenderMaxHp: defenderMaxHp
        )
    }

    deinit {
        predictTimerTask?.cancel()
        strikeTask?.cancel()
    }

    // MARK: - Lifecycle

    /// Begin the first predict window. Call after intro animation completes.
    func beginPredictPhase() {
        guard case .intro = phase else { return }
        startPredictTimer()
        phase = .predict
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
            phase = .finished(winnerId: state.winnerId ?? state.defenderId)
            return
        }
        // Reset selections to defaults for the next round.
        lastOutcome = nil
        lastTurn = nil
        predictTimeRemaining = Self.predictWindowSeconds
        startPredictTimer()
        phase = .predict
    }

    func cancel() {
        predictTimerTask?.cancel()
        strikeTask?.cancel()
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
            // Timer expired — auto-submit with current selection (spec §6 fallback).
            await MainActor.run {
                if case .predict = self.phase {
                    self.submitStrike()
                }
            }
        }
    }

    // MARK: - Strike Resolution

    private func resolveStrike() async {
        let strikeIndex = state.strikes.count
        let request = InteractiveStrikeRequest(
            matchId: state.matchId,
            strikeIndex: strikeIndex,
            attackerId: state.attackerId,
            defenderId: state.defenderId,
            attackerZone: selectedAttackZone,
            defenderZone: selectedDefendZone,
            defenderHp: state.defenderHp
        )

        do {
            let response: InteractiveStrikeResponse = try await APIClient.shared.post(
                APIEndpoints.pvpStrike,
                body: request
            )
            await applyStrikeResponse(response)
        } catch let APIError.clientError(status, _, _) where status == 404 {
            // Feature flag is off on server. Surface unavailable so the screen
            // can route back to classic /pvp/fight.
            phase = .unavailable
        } catch {
            let msg = (error as? APIError)?.errorDescription ?? "Strike failed"
            phase = .error(message: msg)
        }
    }

    private func applyStrikeResponse(_ response: InteractiveStrikeResponse) async {
        // Mutate match state.
        state.strikes.append(response.turn)
        state.defenderHp = max(0, response.newDefenderHp)
        if let heal = response.turn.healAmount, heal > 0,
           response.turn.attackerId == state.attackerId {
            state.attackerHp = min(state.attackerMaxHp, state.attackerHp + heal)
        }
        // Classify outcome for reveal.
        let outcome = InteractiveStrikeOutcome.classify(
            turn: response.turn,
            attackerZone: selectedAttackZone,
            defenderZone: selectedDefendZone
        )
        lastTurn = response.turn
        lastOutcome = outcome
        phase = .reveal
    }
}

// MARK: - Convenience

extension InteractiveBattleViewModel.Phase {
    /// Whether the player should see the Predict UI active.
    var isPredicting: Bool {
        if case .predict = self { return true }
        return false
    }

    /// Whether the Reveal animation should be playing.
    var isRevealing: Bool {
        if case .reveal = self { return true }
        return false
    }
}
