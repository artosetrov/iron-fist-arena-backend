import SwiftUI

/// Dungeon Rush v2 — "The Descent". Route: `AppRoute.dungeonRush`.
///
/// Three depths of forking passages. Every room, die and reward is decided by
/// `/api/dungeon-rush/v2/*`; this screen renders the server's snapshot: a HUD,
/// the scene (painted art + code-driven light) and an action panel under the thumb.
struct DescentDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: DescentViewModel?
    @State private var isVisible = false

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.ignoresSafeArea()
            if let vm {
                content(vm)
                    .transaction { $0.animation = nil }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            isVisible = true
            if let vm {
                Task { await vm.load() }
            } else {
                let model = DescentViewModel(appState: appState, cache: cache)
                vm = model
                Task { await model.load() }
            }
        }
        .onDisappear {
            isVisible = false
            vm?.onDisappear()
        }
    }

    @ViewBuilder
    private func content(_ vm: DescentViewModel) -> some View {
        switch vm.phase {
        case .loading:
            VStack(spacing: 0) {
                DescentPlainHeader(title: "Dungeon Rush")
                Spacer()
                HexPulseLoader(.standard)
                Spacer()
            }
        case .failed:
            VStack(spacing: 0) {
                DescentPlainHeader(title: "Dungeon Rush")
                ErrorStateView.loadFailed {
                    Task { await vm.load() }
                }
            }
        case .intro:
            DescentIntroView(vm: vm, isActive: isVisible) {
                leave()
            }
        case .playing:
            if let snapshot = vm.snapshot {
                DescentRunView(vm: vm, snapshot: snapshot, isActive: isVisible) {
                    leave()
                }
            } else {
                HexPulseLoader(.standard)
            }
        }
    }

    private func leave() {
        SFXManager.shared.play(.uiBack)
        if !appState.mainPath.isEmpty {
            appState.mainPath.removeLast()
        }
    }
}

// MARK: - Header used before a run exists

struct DescentPlainHeader: View {
    let title: String

    var body: some View {
        ZStack {
            Text(title.uppercased())
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.goldBright)
            HStack {
                HubLogoButton()
                Spacer()
            }
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .frame(minHeight: LayoutConstants.touchMin)
    }
}

// MARK: - Intro (no active run)

private struct DescentIntroView: View {
    @Bindable var vm: DescentViewModel
    let isActive: Bool
    let onLeave: () -> Void

    @Environment(AppState.self) private var appState

    private var stamina: Int { appState.currentCharacter?.currentStamina ?? 0 }
    private var maxStamina: Int { appState.currentCharacter?.maxStamina ?? 0 }
    private var canAfford: Bool { stamina >= vm.staminaCost }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                DescentPlainHeader(title: "Dungeon Rush")
                ZStack {
                    DescentBackdrop(asset: "rush2-bg-entrance", dim: 0.42, focusY: 0.5)
                    DescentVignette()
                    DescentTitleCard(
                        eyebrow: "Dungeon Rush",
                        title: "The Descent",
                        text: "Three depths beneath the city. Every fork a choice. Fill your bag, slay the guardians, and climb out before the dark takes **half of it**."
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                DescentPanel(maxHeight: geo.size.height * 0.55) {
                    rule("rush2-node-mystery", "Choose your path", "Monsters, treasure and stranger things wait behind every fork. Listen before you pick.")
                    rule("rush2-icon-goldpouch", "Your bag is at risk", "Fall in the dark and you lose {-half your bag-}. Experience is never lost.")
                    rule("rush2-node-camp", "Bank it or go deeper", "Stash at campfires, or {+climb out+} after a guardian with everything you carry.")
                    Button {
                        Task { await vm.start() }
                    } label: {
                        HStack(spacing: LayoutConstants.spaceSM) {
                            Text("Descend")
                            Image("icon-stamina")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text("\(vm.staminaCost)")
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(vm.isStarting)
                    .accessibilityLabel("Descend, costs \(vm.staminaCost) stamina")
                    Text("Stamina \(stamina) / \(maxStamina)")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .foregroundStyle(canAfford ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textDanger)
                }
            }
        }
    }

    private func rule(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceMS) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(title.uppercased())
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(1.5)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text(DescentText.attributed(text, base: DarkFantasyTheme.textSecondary))
                    .font(DarkFantasyTheme.tale)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - A run in progress

private struct DescentRunView: View {
    @Bindable var vm: DescentViewModel
    let snapshot: DescentSnapshot
    let isActive: Bool
    let onLeave: () -> Void

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                DescentHUD(
                    snapshot: snapshot,
                    canDrink: vm.canDrink,
                    onMap: { vm.showMap = true; SFXManager.shared.play(.scrollUnfurl) },
                    onBag: { vm.showBag = true; SFXManager.shared.play(.uiOpen) },
                    onDrink: { vm.perform(.drink) }
                )

                ZStack {
                    stage
                    DescentFloatersLayer(floaters: vm.floaters)
                    DescentCoinRain(token: vm.coinRainToken, count: vm.coinRainCount)
                    DescentFlashLayer(hurtToken: vm.hurtFlashToken, critToken: vm.critFlashToken)
                    if let banner = vm.banner {
                        DescentBanner(text: banner)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .descentShake(vm.shakeToken)

                DescentPanel(maxHeight: geo.size.height * 0.52) {
                    DescentRunPanel(vm: vm, snapshot: snapshot, onLeave: onLeave)
                }
                .background(DarkFantasyTheme.bgPrimary.ignoresSafeArea(edges: .bottom))
            }
        }
        .overlay {
            if vm.showMap {
                DescentMapSheet(snapshot: snapshot) { vm.showMap = false }
            }
        }
        .overlay {
            if vm.showBag {
                DescentBagSheet(snapshot: snapshot, onClose: { vm.showBag = false }) {
                    vm.showAbandonConfirm = true
                }
            }
        }
        .alert("Abandon the descent?", isPresented: $vm.showAbandonConfirm) {
            Button("Abandon", role: .destructive) { vm.confirmAbandon() }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("You climb out, but half of your bag stays in the dark. Stashed loot and experience are safe.")
        }
    }

    @ViewBuilder
    private var stage: some View {
        let s = snapshot
        switch s.screenKind {
        case .depthCard:
            ZStack {
                DescentBackdrop(asset: "rush2-fork-\(s.depthKey)-1", dim: 0.58)
                DescentVignette()
                DescentTitleCard(eyebrow: "Depth \(s.depthRoman)", title: s.depthName, text: s.depthBlurb)
            }
        case .fork:
            if let fork = s.fork {
                DescentForkScene(
                    snapshot: s,
                    fork: fork,
                    selectedId: vm.selectedNodeId,
                    revealedId: vm.revealedNodeId,
                    revealToken: vm.revealToken,
                    isActive: isActive && !vm.showMap && !vm.showBag
                ) { option in
                    vm.select(option)
                }
            }
        case .combat:
            if let combat = s.combat {
                DescentCombatStage(combat: combat, hitToken: vm.enemyHitToken, isActive: isActive)
            }
        case .spoils:
            ZStack {
                DescentBackdrop(asset: s.spoils?.bg ?? "rush2-bg-\(s.depthKey)-hall", dim: 0.3)
                DescentVignette()
            }
        case .chest:
            if let chest = s.chest {
                DescentChestStage(chest: chest, openToken: vm.chestOpenToken, isActive: isActive)
            }
        case .event:
            if let event = s.event {
                DescentEventStage(event: event, isActive: isActive) { i in
                    vm.perform(.choose(i))
                }
            }
        case .camp:
            DescentCampStage(rested: s.camp?.done == true && s.camp?.choice == "rest", isActive: isActive)
        case .merchant:
            DescentMerchantStage(isActive: isActive)
        case .relic:
            ZStack {
                DescentBackdrop(asset: "rush2-bg-\(s.depthKey)-arena", dim: 0.45)
                DescentVignette()
            }
        case .depthClear:
            ZStack {
                DescentBackdrop(asset: "rush2-bg-\(s.depthKey)-arena", dim: 0.5)
                DescentVignette()
                DescentTitleCard(
                    eyebrow: "Depth \(s.depthRoman) cleared",
                    title: "The way down opens",
                    text: "Below waits \(s.depthClear?.nextDepthName ?? "the next depth"). Your bag holds **\(s.bag.gold)** gold at risk.",
                    titleColor: DarkFantasyTheme.goldBright
                )
            }
        case .result:
            resultStage(s)
        case .unknown:
            DescentBackdrop(asset: "rush2-bg-\(s.depthKey)-hall", dim: 0.4)
        }
    }

    private func resultStage(_ s: DescentSnapshot) -> some View {
        let outcome = s.result?.outcome ?? "dead"
        let asset: String = switch outcome {
        case "victory": "rush2-bg-treasure"
        case "escaped": "rush2-bg-entrance"
        default: "rush2-bg-\(s.depthKey)-hall"
        }
        let eyebrow: String = switch outcome {
        case "victory": "Victory"
        case "escaped": "Escaped"
        case "abandoned": "Abandoned"
        default: "Defeat"
        }
        let title: String = switch outcome {
        case "victory": "The deep is conquered"
        case "escaped": "Back in the daylight"
        case "abandoned": "You turned back"
        default: "You fell in the dark"
        }
        let rooms = s.result?.rooms ?? s.stats.rooms
        let kills = s.result?.kills ?? s.stats.kills
        return ZStack {
            DescentBackdrop(asset: asset, dim: 0.5)
            DescentVignette()
            DescentTitleCard(
                eyebrow: eyebrow,
                title: title,
                text: "Depth \(s.depthRoman) · \(rooms) rooms · \(kills) foes slain",
                titleColor: outcome == "dead" ? DarkFantasyTheme.textDanger : DarkFantasyTheme.goldBright
            )
        }
    }
}
