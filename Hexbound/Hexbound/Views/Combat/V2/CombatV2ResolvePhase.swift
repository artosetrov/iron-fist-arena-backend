//
//  CombatV2ResolvePhase.swift
//  Hexbound
//
//  Interactive Combat v2 — RESOLVE state view.
//
//  The RESOLVE screen is a READ-ONLY damage report. It replaces the V1
//  InteractiveRoundLogCard + the persistent picker underneath with a
//  single coherent frame. The player has ZERO interactive affordances
//  here — they cannot pick, re-pick, fire an active, or change their
//  mind. The only thing to do is acknowledge (tap anywhere) or wait
//  out the auto-dismiss timer on `vm.currentExchange.autoDismissDelay`.
//
//  Architecture doc §4.2. Layout (top → bottom):
//
//    1. Round strip          (ROUND N · BEST OF M · REVEAL)
//    2. Verdict chip         (OUTPLAYED / STRUCK / HELD / OUTREAD)
//    3. Stance summary       (both sides' ATK / DEF as read-only pills)
//    4. Result rows          (YOU: atk → def  = N DMG / CRIT / BLOCK /…
//                             ENEMY: atk → def = M DMG / CRIT / BLOCK /…)
//    5. Tap-to-continue hint (soft, auto-dismisses on card TTL)
//
//  Finishing-blow ceremony: when `vm.isFinishingBlow` is true the
//  verdict chip gets a longer shadow + tracking, and the hint becomes
//  "THE DUEL IS DECIDED". No confetti / no scale-flash — the damage
//  popup on the header already did the celebrating.
//

import SwiftUI

struct CombatV2ResolvePhase: View {
    @Bindable var vm: InteractiveBattleViewModel

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            CombatV2RoundStrip(
                roundNumber: vm.currentRoundNumber,
                bestOf: InteractiveBattleViewModel.maxRounds,
                stateTag: vm.isFinishingBlow ? "FINISHING BLOW" : "REVEAL"
            )

            if let verdict = vm.currentExchange?.verdict {
                CombatV2VerdictChip(verdict: verdict)
                    .transition(.opacity)
            }

            if let exchange = vm.currentExchange {
                CombatV2StanceSummaryStrip(
                    playerAttack: exchange.playerAttackZone,
                    playerDefend: exchange.playerDefendZone,
                    opponentAttack: exchange.opponentAttackZone,
                    opponentDefend: exchange.opponentDefendZone
                )
            } else if let oppZones = vm.lastOpponentZones {
                // Degraded / no-exchange path (older clients, rare).
                // Fall back to VM's confirmed snapshot so the strip is
                // never empty when we know what both sides picked.
                CombatV2StanceSummaryStrip(
                    playerAttack: vm.selectedAttackZone,
                    playerDefend: vm.selectedDefendZone,
                    opponentAttack: oppZones.attack,
                    opponentDefend: oppZones.defend
                )
            }

            resultRows

            Spacer(minLength: LayoutConstants.spaceSM)

            tapToContinueHint
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard vm.currentExchange != nil else { return }
            HapticManager.selection()
            vm.dismissExchange()
        }
        .animation(.easeInOut(duration: 0.2), value: vm.currentExchange?.id)
    }

    // MARK: - Result Rows

    /// Two per-side result rows. Uses VM's `lastTurn` / `lastOpponentTurn`
    /// so the outcome (CRIT / BLOCK / DODGE / MISS / N DMG) stays aligned
    /// with the damage popups and verdict flash — no extra interpretation
    /// of the server payload on this side of the split.
    @ViewBuilder
    private var resultRows: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            CombatV2ResultRow(
                side: .player,
                attackZone: vm.selectedAttackZone,
                defendZone: vm.selectedDefendZone,
                damage: vm.lastTurn?.damage ?? 0,
                outcome: .from(turn: vm.lastTurn)
            )

            if let oppZones = vm.lastOpponentZones {
                CombatV2ResultRow(
                    side: .enemy,
                    attackZone: oppZones.attack,
                    defendZone: oppZones.defend,
                    damage: vm.lastOpponentTurn?.damage ?? 0,
                    outcome: .from(turn: vm.lastOpponentTurn)
                )
            }
        }
    }

    // MARK: - Tap-to-continue hint

    /// Soft prompt at the bottom of the screen. Gives the player explicit
    /// agency: they can tap to skip the card's auto-dismiss timer and
    /// move straight to the next round (or to END on the finishing blow).
    /// Copy swaps on the finishing-blow round so the CTA matches the
    /// moment: "THE DUEL IS DECIDED" reads cleaner than "TAP TO CONTINUE"
    /// when the next screen is the END summary.
    @ViewBuilder
    private var tapToContinueHint: some View {
        if vm.currentExchange != nil {
            HStack(spacing: LayoutConstants.space2XS) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Text(vm.isFinishingBlow ? "THE DUEL IS DECIDED" : "TAP TO CONTINUE")
                    .font(DarkFantasyTheme.caption)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LayoutConstants.spaceSM)
        }
    }
}
