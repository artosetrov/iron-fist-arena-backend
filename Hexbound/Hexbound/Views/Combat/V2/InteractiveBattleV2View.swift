//
//  InteractiveBattleV2View.swift
//  Hexbound
//
//  Interactive Combat v2 — host view.
//
//  This is the V2 replacement for `InteractiveBattleView`. It owns the
//  same VM, the same background, the same VFX / FX / verdict-flash
//  stack, and the same fighter-anchor publishing. What changes is the
//  BODY of the screen: instead of a fixed `duel header + round strip +
//  predict panel` stack that re-reads itself on every phase, the V2
//  host mounts a single `CombatV2DuelHeader` at the root and swaps a
//  state-specific panel underneath via `vm.uxState`.
//
//  Why the DuelHeader lives at the root (outside the state switch):
//  the fighter-card anchor preferences only fire on first layout of the
//  tile. Re-mounting the header on state transitions would reset
//  `FighterAnchorKey` to the default (0.25, 0.75) positions mid-battle
//  and VFX bursts would appear to "jump" to screen-center for the first
//  frame of each new state. Keeping the header in a stable position in
//  the view tree is the single cheapest way to preserve VFX placement.
//
//  Gating: this view is mounted from `InteractiveBattleRouteView` when
//  `appState.combatUXV2 == true`. Default is off. Flip the flag for
//  one-tap rollback to V1 without a new build.
//

import SwiftUI

struct InteractiveBattleV2View: View {
    @Bindable var vm: InteractiveBattleViewModel

    /// Called when the battle finishes (winner or unavailable). Host
    /// presents the result or falls back to classic flow. Same contract
    /// as `InteractiveBattleView.onFinished` so the route wrapper can
    /// swap V1/V2 without branching its terminal handling.
    var onFinished: ((InteractiveBattleViewModel.Phase) -> Void)? = nil

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceMD) {
                // 1. Stable header (mounted once — see file header comment).
                CombatV2DuelHeader(vm: vm)

                // 2. Transient state panel (CHOOSE / RESOLVE / END / …).
                statePanel
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceLG)

            // 3. VFX overlays — identical to V1 so anchor math doesn't drift.
            CombatVFXOverlay(vfxManager: vm.vfxManager, speedMultiplier: vm.speedMultiplier)
                .allowsHitTesting(false)

            CombatFXImageOverlay(fxManager: vm.fxImageManager)
                .allowsHitTesting(false)

            CombatVerdictFlash(
                verdict: vm.currentExchange?.verdict,
                triggerId: vm.currentExchange?.id
            )
        }
        // Resolve fighter-card anchors → feed VM for VFX placement.
        // `proxy.size` === screen size here (attached to the root ZStack).
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
        .animation(.easeInOut(duration: 0.25), value: vm.uxStateKey)
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

    // MARK: - State Panel (the only thing that swaps on state change)

    @ViewBuilder
    private var statePanel: some View {
        switch vm.uxState {
        case .intro:
            HexPulseLoader(.standard, message: "PREPARING DUEL")
                .frame(maxWidth: .infinity, minHeight: 180)
                .transition(.opacity)

        case .choose(let locked):
            CombatV2ChoosePhase(vm: vm, locked: locked)
                .transition(.opacity)

        case .resolve:
            CombatV2ResolvePhase(vm: vm)
                .transition(.opacity)

        case .end:
            CombatV2EndPhase(vm: vm)
                .transition(.opacity)

        case .unavailable:
            unavailableBanner
                .transition(.opacity)

        case .error(let message):
            errorBanner(message: message)
                .transition(.opacity)
        }
    }

    // MARK: - Terminal Banners
    //
    // Same text + tokens as the V1 versions — the route wrapper pops
    // immediately on these phases, so these views are on screen for a
    // frame or two. Keeping them consistent avoids a visible "flash of
    // different copy" on the error/unavailable edge cases.

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

    // MARK: - Anchor plumbing (parity with V1)

    /// Convert each fighter's anchor bounds → normalized screen-space
    /// position, then write into the VM for VFX placement. Called from
    /// the root-attached `overlayPreferenceValue`, where `proxy.size` ==
    /// the screen size. Mirror of `InteractiveBattleView.publishAnchors`.
    private func publishAnchors(entries: [FighterAnchorKey.Entry],
                                proxy: GeometryProxy) {
        let screen = proxy.size
        guard screen.width > 0, screen.height > 0 else { return }
        for entry in entries {
            let rect = proxy[entry.bounds]
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

    // MARK: - Phase Diffing

    /// Stable diffing key for terminal-phase detection. Mirrors the V1
    /// helper so `.onChange(of:)` fires exactly the same times whether
    /// the V1 or V2 host is mounted.
    private func phaseKey(_ p: InteractiveBattleViewModel.Phase) -> String {
        switch p {
        case .intro:            return "intro"
        case .predict:          return "predict"
        case .resolving:        return "resolving"
        case .reveal:           return "reveal"
        case .summary:          return "summary"
        case .completing:       return "completing"
        case .finished(let id): return "finished:\(id)"
        case .unavailable:      return "unavailable"
        case .error(let m):     return "error:\(m)"
        }
    }
}
