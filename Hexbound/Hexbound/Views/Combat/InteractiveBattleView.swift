//
//  InteractiveBattleView.swift
//  Hexbound
//
//  Interactive Combat v1 — host screen.
//
//  Layout (mirrors the reference old-combat screen):
//    • Duel header — YOU (green frame) / ENEMY (red frame) portraits with
//      class + level + HP bar inline. Reserved FX slot over each avatar.
//    • Zone badges — last picked Attack / Defend zones.
//    • Predict panel — big ornamental timer, zone pickers, STRIKE + SKIP.
//
//  Combat log is intentionally NOT rendered here — per product decision
//  2026-04-13 it surfaces only in the post-match result modal, so players
//  can review who struck which stance. Data still accumulates on the VM
//  (`combatLogRows`) and is consumed by the result screen in Commit 2.
//
//  VFX burst overlays + result modal are Commit 2 (wired in separately).
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
                duelHeader
                Spacer(minLength: 0)
                predictPanel
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceLG)

            // Canvas particle VFX — mounted behind PNG FX so sparks sit
            // under the slash/crit/text layer but above the UI chrome.
            CombatVFXOverlay(vfxManager: vm.vfxManager, speedMultiplier: 1.0)
                .allowsHitTesting(false)

            // PNG image FX overlay — slash, crit text, shield, heal.
            CombatFXImageOverlay(fxManager: vm.fxImageManager)
                .allowsHitTesting(false)
        }
        // Resolve fighter-card anchors in screen coordinates and push them
        // to the VM so VFX/FX land on the right avatar. Attached to the root
        // so `proxy.size` === screen size.
        .overlayPreferenceValue(FighterAnchorKey.self) { entries in
            GeometryReader { proxy in
                Color.clear
                    .onAppear { publishAnchors(entries: entries, proxy: proxy) }
                    .onChange(of: proxy.size.width) { _, _ in
                        publishAnchors(entries: entries, proxy: proxy)
                    }
            }
            .allowsHitTesting(false)
        }
        .onAppear { vm.startMatch() }
        .onChange(of: phaseKey(vm.phase)) { _, _ in
            switch vm.phase {
            case .finished, .unavailable, .error:
                onFinished?(vm.phase)
            default:
                break
            }
        }
    }

    // MARK: - Duel Header (YOU vs ENEMY)

    /// Duel header with live avatar anchor reporting. After layout, each
    /// `DuelFighterCard` publishes its frame via an anchor preference; the
    /// root `overlayPreferenceValue` resolves those anchors in screen
    /// coordinates and feeds the VM so VFX/FX land on the correct avatar.
    /// Slide-in offsets + hit flash also live here.
    private var duelHeader: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
            // YOU
            VStack(spacing: LayoutConstants.spaceXS) {
                DuelFighterCard(
                    side: .player,
                    profile: vm.attackerProfile,
                    currentHp: vm.state.attackerHp,
                    maxHp: vm.state.attackerMaxHp,
                    slideX: vm.playerSlideX,
                    flash: vm.playerFlash,
                    popups: vm.damagePopups.filter { !$0.onDefender }
                )
                .anchorPreference(key: FighterAnchorKey.self, value: .bounds) {
                    [FighterAnchorKey.Entry(side: .player, bounds: $0)]
                }
                stanceOverlayRow(
                    attack: vm.selectedAttackZone,
                    defend: vm.selectedDefendZone,
                    isGhost: false
                )
                if let playerLabel = vm.lastActiveFiredLabel {
                    ActiveFireBanner(actionType: playerLabel, isOpponent: false)
                        .id("you-fire-\(playerLabel)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)

            // FOE
            VStack(spacing: LayoutConstants.spaceXS) {
                DuelFighterCard(
                    side: .enemy,
                    profile: vm.defenderProfile,
                    currentHp: vm.state.defenderHp,
                    maxHp: vm.state.defenderMaxHp,
                    slideX: vm.enemySlideX,
                    flash: vm.enemyFlash,
                    popups: vm.damagePopups.filter { $0.onDefender }
                )
                .anchorPreference(key: FighterAnchorKey.self, value: .bounds) {
                    [FighterAnchorKey.Entry(side: .enemy, bounds: $0)]
                }
                stanceOverlayRow(
                    attack: vm.lastOpponentZones?.attack,
                    defend: vm.lastOpponentZones?.defend,
                    isGhost: true
                )
                if !vm.opponentActives.isEmpty {
                    OpponentActivesPreview(actives: vm.opponentActives)
                }
                // Intent hint — "LIKELY HITS: CHEST" style pill, visible
                // only during the predict window once we have ≥2 rounds
                // of signal. Ghost styling signals "read, not a tell".
                if vm.phase.isPredicting,
                   let likely = vm.likelyOpponentAttack {
                    EnemyIntentPill(channel: .attack, likelyZone: likely)
                        .transition(.opacity)
                }
                if let oppLabel = vm.lastOpponentActiveFiredLabel {
                    ActiveFireBanner(actionType: oppLabel, isOpponent: true)
                        .id("opp-fire-\(oppLabel)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .animation(.easeInOut(duration: 0.2), value: vm.lastActiveFiredLabel)
        .animation(.easeInOut(duration: 0.2), value: vm.lastOpponentActiveFiredLabel)
        .animation(.easeInOut(duration: 0.25), value: vm.likelyOpponentAttack)
    }

    /// Compact row of Attack / Defend `StanceOverlay` chips under a fighter
    /// card. Opponent side uses `isGhost = true` to dim until reveal.
    private func stanceOverlayRow(attack: InteractiveBodyZone?,
                                  defend: InteractiveBodyZone?,
                                  isGhost: Bool) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            StanceOverlay(kind: .attack, zone: attack, isGhost: isGhost)
            StanceOverlay(kind: .defend, zone: defend, isGhost: isGhost)
        }
    }

    /// Convert each fighter's anchor bounds → normalized screen-space position,
    /// then write into the VM for VFX placement. Called from the root-attached
    /// `overlayPreferenceValue`, where `proxy.size` equals the screen size.
    private func publishAnchors(entries: [FighterAnchorKey.Entry],
                                proxy: GeometryProxy) {
        let screen = proxy.size
        guard screen.width > 0, screen.height > 0 else { return }
        for entry in entries {
            let rect = proxy[entry.bounds]
            // Aim FX at the avatar tile: card mid-x, card top third.
            let p = CGPoint(
                x: rect.midX / screen.width,
                y: (rect.minY + rect.height * 0.30) / screen.height
            )
            switch entry.side {
            case .player: vm.playerAvatarPos = p
            case .enemy:  vm.enemyAvatarPos  = p
            }
        }
    }

    // MARK: - Predict Panel (pickers + actives + bottom bar)

    @ViewBuilder
    private var predictPanel: some View {
        switch vm.phase {
        case .intro:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(DarkFantasyTheme.gold)
                .frame(maxWidth: .infinity, minHeight: 180)
        case .unavailable:
            unavailableBanner
        case .error(let message):
            errorBanner(message: message)
        case .finished(let winnerId):
            finishedBanner(winnerId: winnerId)
        case .completing:
            ProgressView("Finalizing…")
                .tint(DarkFantasyTheme.gold)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 180)
        default:
            // .predict / .resolving / .reveal — controls stay mounted so layout
            // doesn't jump, but get disabled while the server is resolving.
            // Timer is integrated into the STRIKE button (TimerRingStrikeButton)
            // — no separate PredictTimerBar anymore.
            InteractivePredictView(vm: vm)
                .disabled(vm.phase.isBusy)
                .opacity(vm.phase.isBusy ? 0.6 : 1.0)
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
        .frame(maxWidth: .infinity, minHeight: 180)
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
        .frame(maxWidth: .infinity, minHeight: 180)
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
        .frame(maxWidth: .infinity, minHeight: 180)
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

// MARK: - Duel Fighter Card

enum DuelSide { case player, enemy }

/// Preference key that carries each fighter card's layout anchor up to the
/// screen root, so we can normalize its position into (0…1) coordinates
/// and feed the VFX/FX overlay managers.
struct FighterAnchorKey: PreferenceKey {
    struct Entry: Equatable {
        let side: DuelSide
        let bounds: Anchor<CGRect>
        // Anchor<CGRect> is not Equatable; we compare by side identity only,
        // which is enough to dedupe two player-side or two enemy-side anchors.
        static func == (lhs: Entry, rhs: Entry) -> Bool { lhs.side == rhs.side }
    }
    static var defaultValue: [Entry] = []
    static func reduce(value: inout [Entry], nextValue: () -> [Entry]) {
        value.append(contentsOf: nextValue())
    }
}

private struct DuelFighterCard: View {
    typealias Side = DuelSide

    let side: Side
    let profile: FighterProfile?
    let currentHp: Int
    let maxHp: Int
    var slideX: CGFloat = 0
    var flash: Bool = false
    var popups: [DamagePopup] = []

    private var borderColor: Color {
        side == .player ? DarkFantasyTheme.success : DarkFantasyTheme.danger
    }

    private var sideLabel: String {
        side == .player ? "YOU" : "ENEMY"
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text(sideLabel)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(borderColor)

            avatarTile
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .stroke(borderColor, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusMD))
                // Hit flash — mirrors CombatDetailView
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .fill(DarkFantasyTheme.danger.opacity(flash ? 0.35 : 0.0))
                        .allowsHitTesting(false)
                )
                // Floating damage / heal popups over the avatar
                .overlay(alignment: .top) {
                    ZStack {
                        ForEach(popups) { popup in
                            DamagePopupBubble(popup: popup)
                        }
                    }
                    .allowsHitTesting(false)
                }
                // Attacker slide-in X offset (per side)
                .offset(x: slideX)

            Text(profile?.name.uppercased() ?? "…")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(profileSubtitle)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            HPBarView(
                currentHp: currentHp,
                maxHp: maxHp,
                size: .compact,
                showTextInside: false,
                pulseOnCritical: true
            )

            Text("\(currentHp) / \(maxHp)")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.hpBlood)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.25), value: currentHp)
        }
    }

    private var profileSubtitle: String {
        guard let profile else { return "—" }
        return "Lv.\(profile.level) \(profile.characterClass.displayName)"
    }

    @ViewBuilder
    private var avatarTile: some View {
        ZStack {
            DarkFantasyTheme.bgSecondary
            if let profile {
                AvatarImageView(
                    skinKey: profile.avatar,
                    characterClass: profile.characterClass,
                    size: 200
                )
                .scaleEffect(x: side == .player ? 1 : -1, y: 1)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(DarkFantasyTheme.gold)
            }
        }
    }
}

// MARK: - Predict View (zone pickers + actives + commit bar)

struct InteractivePredictView: View {
    @Bindable var vm: InteractiveBattleViewModel

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // 1) Stance pickers — ATTACK + DEFEND
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

            // 2) Active skills — sit directly beneath the picker rows
            //    so the player's gaze travels naturally from stance →
            //    talents → commit button.
            if !vm.playerActives.isEmpty {
                VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                    Text("ACTIVE SKILLS")
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    ActiveSkillsHUD(
                        actives: vm.playerActives,
                        pendingSlot: vm.pendingActiveSlot,
                        isInteractive: true,
                        onTap: { vm.toggleActiveSlot($0) }
                    )
                }
            }

            // 3) Bottom bar — SKIP on the left, STRIKE (with integrated
            //    radial timer) on the right. Equal-weight so the CTAs
            //    form a balanced commit row.
            HStack(spacing: LayoutConstants.spaceSM) {
                Button(action: { vm.skipAndSubmit() }) {
                    Text("SKIP")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .frame(maxWidth: .infinity, minHeight: LayoutConstants.buttonHeightLG)
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(maxWidth: .infinity)

                TimerRingStrikeButton(
                    remainingFraction: timerFraction,
                    isCritical: vm.predictTimeRemaining <= 1.5,
                    isBusy: false,
                    action: { vm.submitStrike() }
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var timerFraction: Double {
        let total = InteractiveBattleViewModel.predictWindowSeconds
        guard total > 0 else { return 0 }
        return max(0, min(1, vm.predictTimeRemaining / total))
    }

    private func zonePicker(title: String, selection: Binding<InteractiveBodyZone>) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
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
                    .font(.system(size: 22)) // keep — SF Symbol icon size, no theme token for icons
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
                // CombatResultDetailView reads appState.combatResult (NOT
                // combatData) — setting the wrong property triggers the
                // fallback "Battle Failed" error state. Set both so any
                // downstream consumer (in-progress playback vs result modal)
                // sees the final data.
                appState.combatResult = data
                appState.combatData = data
                if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
                appState.mainPath.append(AppRoute.combatResult)
            } else {
                appState.showToast("Match ended", type: .info)
                if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
            }
        case .unavailable:
            // /pvp/match/start returned 404 — endpoint not deployed (feature
            // flag on client but backend rolled back, or race between deploys).
            // Disable interactive combat for the rest of this session, then
            // signal ArenaDetailView to re-run the fight in classic mode for
            // the same opponent. No user-visible "unavailable" toast — the
            // fallback should be transparent.
            appState.interactiveCombatLocallyDisabled = true
            let oppId = opponentId
            if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
            // Set pending id AFTER pop so ArenaDetailView's onChange fires
            // once the arena screen is back in scope.
            appState.pendingClassicFightOpponentId = oppId
        case .error(let message):
            appState.showToast("Match failed", subtitle: message, type: .error)
            if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
        default:
            break
        }
    }
}
