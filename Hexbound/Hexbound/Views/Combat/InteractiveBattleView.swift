//
//  InteractiveBattleView.swift
//  Hexbound
//
//  Interactive Combat v1 — host screen + Predict + Reveal sub-views.
//  Additive UI. Mounted only when feature flag is on the server side; if server
//  returns 404 the screen routes back to classic CombatDetailView.
//

import SwiftUI

// MARK: - Host Screen

struct InteractiveBattleView: View {
    @Bindable var vm: InteractiveBattleViewModel

    /// Called when the battle finishes (winner or unavailable). Host presents
    /// the result or falls back to classic flow.
    var onFinished: ((InteractiveBattleViewModel.Phase) -> Void)? = nil

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()
            VStack(spacing: LayoutConstants.spaceMD) {
                hpHeader
                Spacer(minLength: 0)
                contentForPhase
                Spacer(minLength: 0)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceLG)
        }
        .onAppear { vm.startMatch() }
        .onChange(of: phaseKey(vm.phase)) { _, _ in
            // Notify host on terminal phases.
            switch vm.phase {
            case .finished, .unavailable, .error:
                onFinished?(vm.phase)
            default:
                break
            }
        }
    }

    // MARK: - HP Header

    private var hpHeader: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            HPBarView(
                currentHp: vm.state.attackerHp,
                maxHp: vm.state.attackerMaxHp,
                size: .compact,
                showTextInside: true,
                pulseOnCritical: true,
                label: "YOU"
            )
            HPBarView(
                currentHp: vm.state.defenderHp,
                maxHp: vm.state.defenderMaxHp,
                size: .compact,
                showTextInside: true,
                pulseOnCritical: true,
                label: "FOE"
            )
        }
    }

    // MARK: - Phase Routing

    @ViewBuilder
    private var contentForPhase: some View {
        switch vm.phase {
        case .intro:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(DarkFantasyTheme.gold)
        case .predict:
            InteractivePredictView(vm: vm)
        case .resolving:
            ProgressView("Resolving…")
                .tint(DarkFantasyTheme.gold)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        case .completing:
            ProgressView("Finalizing…")
                .tint(DarkFantasyTheme.gold)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        case .reveal:
            InteractiveRevealView(
                outcome: vm.lastOutcome ?? .hit,
                turn: vm.lastTurn,
                onComplete: { vm.revealCompleted() }
            )
        case .finished(let winnerId):
            finishedBanner(winnerId: winnerId)
        case .unavailable:
            unavailableBanner
        case .error(let message):
            errorBanner(message: message)
        }
    }

    // MARK: - Terminal Banners

    private func finishedBanner(winnerId: String) -> some View {
        let won = (winnerId == vm.state.attackerId)
        return VStack(spacing: LayoutConstants.spaceSM) {
            Text(won ? "VICTORY" : "DEFEAT")
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(won ? DarkFantasyTheme.gold : DarkFantasyTheme.danger)
            Text("\(vm.state.strikes.count) strike\(vm.state.strikes.count == 1 ? "" : "s")")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
    }

    private var unavailableBanner: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("Interactive mode unavailable")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
            Text("Falling back to classic battle")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
    }

    private func errorBanner(message: String) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("Strike failed")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.danger)
            Text(message)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Phase Diffing

    /// `Phase` has associated values — reduce to a stable string key for `onChange`.
    private func phaseKey(_ p: InteractiveBattleViewModel.Phase) -> String {
        switch p {
        case .intro: return "intro"
        case .predict: return "predict"
        case .resolving: return "resolving"
        case .reveal: return "reveal"
        case .completing: return "completing"
        case .finished(let id): return "finished:\(id)"
        case .unavailable: return "unavailable"
        case .error(let m): return "error:\(m)"
        }
    }
}

// MARK: - Predict View

struct InteractivePredictView: View {
    @Bindable var vm: InteractiveBattleViewModel

    var body: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            timerBar
            zonePicker(
                title: "ATTACK",
                selection: Binding(
                    get: { vm.selectedAttackZone },
                    set: { vm.selectedAttackZone = $0 }
                )
            )
            zonePicker(
                title: "DEFEND",
                selection: Binding(
                    get: { vm.selectedDefendZone },
                    set: { vm.selectedDefendZone = $0 }
                )
            )
            strikeButton
        }
    }

    private var timerBar: some View {
        let fraction = vm.predictTimeRemaining / InteractiveBattleViewModel.predictWindowSeconds
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(DarkFantasyTheme.bgSecondary)
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(DarkFantasyTheme.gold)
                    .frame(width: max(0, geo.size.width * fraction))
                    .animation(.linear(duration: 0.1), value: vm.predictTimeRemaining)
            }
        }
        .frame(height: 6)
    }

    private func zonePicker(title: String, selection: Binding<InteractiveBodyZone>) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text(title)
                .font(DarkFantasyTheme.uiLabel)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(InteractiveBodyZone.allCases, id: \.self) { zone in
                    zoneTile(zone: zone, isSelected: selection.wrappedValue == zone) {
                        selection.wrappedValue = zone
                    }
                }
            }
        }
    }

    private func zoneTile(zone: InteractiveBodyZone,
                          isSelected: Bool,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: iconForZone(zone))
                    .font(.system(size: 24)) // keep — SF Symbol icon size, no theme token for icons
                Text(zone.rawValue.uppercased())
                    .font(DarkFantasyTheme.badge)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(isSelected ? DarkFantasyTheme.gold.opacity(0.2) : DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle,
                            lineWidth: isSelected ? 2 : 1)
            )
            .foregroundStyle(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.textPrimary)
            .opacity(isSelected ? 1.0 : 0.85)
        }
        .buttonStyle(.plain)
    }

    private func iconForZone(_ zone: InteractiveBodyZone) -> String {
        switch zone {
        case .head: return "brain.head.profile"
        case .chest: return "heart.fill"
        case .legs: return "figure.walk"
        }
    }

    private var strikeButton: some View {
        Button(action: { vm.submitStrike() }) {
            Text("STRIKE")
                .font(DarkFantasyTheme.buttonLabel)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

// MARK: - Reveal View

struct InteractiveRevealView: View {
    let outcome: InteractiveStrikeOutcome
    let turn: InteractiveStrikeTurn?
    let onComplete: () -> Void

    @State private var badgeOpacity: Double = 0
    @State private var damageOpacity: Double = 0
    @State private var damageOffset: CGFloat = 20

    var body: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            Text(outcome.label)
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(outcomeColor)
                .opacity(badgeOpacity)

            if let damage = turn?.damage, damage > 0 {
                Text("-\(damage)")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.danger)
                    .opacity(damageOpacity)
                    .offset(y: damageOffset)
            } else if let heal = turn?.healAmount, heal > 0 {
                Text("+\(heal)")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.success)
                    .opacity(damageOpacity)
                    .offset(y: damageOffset)
            }

            if let skill = turn?.skillUsed {
                Text(skill.uppercased())
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .opacity(damageOpacity)
            }
        }
        .onAppear { runAnimation() }
    }

    private var outcomeColor: Color {
        switch outcome {
        case .crit, .antiRead, .execute: return DarkFantasyTheme.gold
        case .miss, .dodge, .blocked: return DarkFantasyTheme.textSecondary
        case .fatigue: return DarkFantasyTheme.danger
        case .glancing: return DarkFantasyTheme.textSecondary
        case .hit: return DarkFantasyTheme.textPrimary
        }
    }

    /// Scripted Reveal timeline from COMBAT_MECHANIC_SPEC.md §3.4.
    /// t=80 ms    badge fade in
    /// t=220 ms   damage number enters (opacity + translate, NO scale per rule)
    /// t=1200 ms  hold
    /// t=1400 ms  complete → next predict round
    private func runAnimation() {
        // t=80 ms
        withAnimation(.easeOut(duration: 0.2).delay(0.08)) {
            badgeOpacity = 1
        }
        // t=220 ms
        withAnimation(.easeOut(duration: 0.28).delay(0.22)) {
            damageOpacity = 1
            damageOffset = 0
        }
        // t=1400 ms — signal completion
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(InteractiveBattleViewModel.revealDurationSeconds))
            onComplete()
        }
    }
}

// MARK: - Route Wrapper

/// Thin wrapper that owns the `InteractiveBattleViewModel` lifecycle and wires
/// the terminal phases back into AppState navigation. Mounted by `AppRouter`
/// for the `.interactiveBattle` route.
struct InteractiveBattleRouteView: View {
    @Environment(AppState.self) private var appState
    let characterId: String
    let opponentId: String
    let attackerMaxHp: Int
    let defenderMaxHp: Int

    @State private var vm: InteractiveBattleViewModel?

    var body: some View {
        Group {
            if let vm {
                InteractiveBattleView(
                    vm: vm,
                    onFinished: { phase in
                        handleTerminal(phase, vm: vm)
                    }
                )
            } else {
                ZStack {
                    DarkFantasyTheme.bgPrimary.ignoresSafeArea()
                    ProgressView()
                        .tint(DarkFantasyTheme.gold)
                }
            }
        }
        .onAppear {
            if vm == nil {
                vm = InteractiveBattleViewModel(
                    appState: appState,
                    attackerCharacterId: characterId,
                    defenderCharacterId: opponentId,
                    attackerMaxHp: attackerMaxHp,
                    defenderMaxHp: defenderMaxHp
                )
            }
        }
        .onDisappear {
            vm?.cancel()
        }
        .navigationBarBackButtonHidden(true)
    }

    private func handleTerminal(_ phase: InteractiveBattleViewModel.Phase,
                                vm: InteractiveBattleViewModel) {
        switch phase {
        case .finished:
            if let data = vm.finalCombatData {
                appState.combatData = data
                if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
                appState.mainPath.append(AppRoute.combatResult)
            } else {
                appState.showToast("Match ended", type: .info)
                if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
            }
        case .unavailable:
            // Feature flag flipped off between /game/init and /match/start —
            // rare race. Fall back: pop and toast; user can tap Fight again
            // and will get the classic flow on the next tap.
            appState.showToast("Interactive combat unavailable",
                               subtitle: "Returning to classic mode",
                               type: .info)
            if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
        case .error(let message):
            appState.showToast("Match failed", subtitle: message, type: .error)
            if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
        default:
            break
        }
    }
}
