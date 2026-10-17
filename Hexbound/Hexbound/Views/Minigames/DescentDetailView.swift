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

/// The doorway to the mode: the whole descent in one painting (three depths and
/// their guardians, labelled I–III), the title on its dark foot, one call to action.
/// The rules live in a sheet that opens by itself the first time.
private struct DescentIntroView: View {
    @Bindable var vm: DescentViewModel
    let isActive: Bool
    let onLeave: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("descent.rulesSeen") private var rulesSeen = false
    @State private var showRules = false
    @State private var panelHeight: CGFloat = 260
    @State private var appeared = false

    private var stamina: Int { appState.currentCharacter?.currentStamina ?? 0 }
    private var maxStamina: Int { appState.currentCharacter?.maxStamina ?? 0 }
    private var canAfford: Bool { stamina >= vm.staminaCost }

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geo in
                artLayer(size: geo.size, reserve: panelHeight + geo.safeAreaInsets.bottom)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    HubLogoButton()
                    Spacer()
                }
                .padding(.horizontal, LayoutConstants.spaceSM)
                .frame(minHeight: LayoutConstants.touchMin)
                Spacer(minLength: 0)
                panel
                    .background(
                        GeometryReader { g in
                            Color.clear.preference(key: DescentIntroPanelKey.self, value: g.size.height)
                        }
                    )
            }
        }
        .onPreferenceChange(DescentIntroPanelKey.self) { panelHeight = $0 }
        .overlay {
            if showRules {
                DescentRulesSheet {
                    rulesSeen = true
                    showRules = false
                }
            }
        }
        .onAppear { appeared = true }
        .task {
            guard !rulesSeen else { return }
            try? await Task.sleep(for: .milliseconds(900))
            if !Task.isCancelled { showRules = true }
        }
    }

    // MARK: Art

    /// The painting, top-anchored and full width; on short screens it shrinks so the
    /// guardians stay above the panel (the lava floor may slide under the title).
    private func artLayer(size: CGSize, reserve: CGFloat) -> some View {
        let aspect = DescentGeometry.keyArtAspect
        let room = max(size.height - reserve + 110, 240)
        let h = min(size.width / aspect, room)
        let w = h * aspect
        let x0 = (size.width - w) / 2
        let edge = min(0.2, 18 / max(w, 1))
        return ZStack(alignment: .topLeading) {
            DarkFantasyTheme.bgAbyss
            if w < size.width - 1 {
                Image("rush2-bg-descent-key")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .blur(radius: 16)
                    .brightness(-0.55)
                    .clipped()
            }
            Image("rush2-bg-descent-key")
                .resizable()
                .frame(width: w, height: h)
                .mask(LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: edge),
                        .init(color: .black, location: 1 - edge),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .leading, endPoint: .trailing
                ))
                .offset(x: x0)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared || reduceMotion ? 0 : -18)
                .animation(.easeOut(duration: 1.2), value: appeared)
                .accessibilityLabel("The three depths of the descent and their guardians")
            LinearGradient(
                colors: [DarkFantasyTheme.bgAbyss.opacity(0.55), DarkFantasyTheme.bgAbyss.opacity(0)],
                startPoint: .top, endPoint: .center
            )
            .frame(height: h * 0.28)
            .allowsHitTesting(false)
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !isActive)) { ctx in
                DescentTorchGlow(
                    center: CGPoint(x: x0 + w * DescentGeometry.keyArtTorch.x, y: h * DescentGeometry.keyArtTorch.y),
                    radius: w * 0.22,
                    t: ctx.date.timeIntervalSinceReferenceDate
                )
            }
            .allowsHitTesting(false)
            ForEach(Array(DescentGeometry.keyArtTiers.enumerated()), id: \.offset) { i, tier in
                DescentTierLabel(roman: tier.roman, name: tier.name)
                    .offset(x: x0 + 12, y: h * tier.y - 17)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.5 + Double(i) * 0.25), value: appeared)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    // MARK: Panel

    private var panel: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            VStack(spacing: LayoutConstants.space2XS) {
                Text("DUNGEON RUSH")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(6)
                    .foregroundStyle(DarkFantasyTheme.gold)
                Text("THE DESCENT")
                    .font(DarkFantasyTheme.bossNameHero)
                    .tracking(3)
                    .foregroundStyle(LinearGradient(
                        colors: [DarkFantasyTheme.rankChallenger, DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .shadow(color: DarkFantasyTheme.goldGlow, radius: 16)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 6, y: 3)
                Text("Three depths. Three guardians. Whatever you carry, you can lose.")
                    .font(DarkFantasyTheme.tale)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

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
            .buttonStyle(.descentGold)
            .disabled(vm.isStarting)
            .accessibilityLabel("Descend, costs \(vm.staminaCost) stamina")

            HStack {
                Text("STAMINA \(stamina) / \(maxStamina)")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(1.5)
                    .foregroundStyle(canAfford ? DarkFantasyTheme.textTertiaryAA : DarkFantasyTheme.textDanger)
                Spacer(minLength: LayoutConstants.spaceSM)
                Button {
                    SFXManager.shared.play(.uiOpen)
                    showRules = true
                } label: {
                    Text("How it works")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .tracking(1.5)
                        .underline()
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .frame(minHeight: LayoutConstants.touchMin)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, 40)
        .padding(.bottom, LayoutConstants.spaceXS)
        .background {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [DarkFantasyTheme.bgAbyss.opacity(0), DarkFantasyTheme.bgAbyss.opacity(0.82), DarkFantasyTheme.bgAbyss],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 64)
                DarkFantasyTheme.bgAbyss
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

private struct DescentIntroPanelKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// "I · THE OSSUARY": a numbered medallion with a pennant, pinned to a tier of the key art.
private struct DescentTierLabel: View {
    let roman: String
    let name: String

    var body: some View {
        HStack(spacing: -9) {
            Text(roman)
                .font(DarkFantasyTheme.buttonLabelCompact)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(RadialGradient(
                        colors: [DarkFantasyTheme.bgDungeonPurple, DarkFantasyTheme.bgAbyss],
                        center: .center, startRadius: 0, endRadius: 17
                    ))
                )
                .overlay(
                    Circle().strokeBorder(
                        LinearGradient(
                            colors: [DarkFantasyTheme.rankChallenger, DarkFantasyTheme.goldDim, DarkFantasyTheme.gold],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                )
                .zIndex(1)
            Text(name.uppercased())
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.vfxStunGlow)
                .padding(.leading, 17)
                .padding(.trailing, 18)
                .padding(.vertical, LayoutConstants.space2XS + 2)
                .background(
                    DescentPennantShape().fill(LinearGradient(
                        colors: [DarkFantasyTheme.bgAbyss.opacity(0.94), DarkFantasyTheme.bgAbyss.opacity(0.72)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                )
        }
        .fixedSize()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.85), radius: 4, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Depth \(roman): \(name)")
    }
}

/// The three rules, on the same plates as the choices in a run.
private struct DescentRulesSheet: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityHidden(true)

            VStack(spacing: LayoutConstants.spaceMS) {
                HStack {
                    Text("HOW THE DESCENT WORKS")
                        .font(DarkFantasyTheme.section)
                        .tracking(2)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: LayoutConstants.spaceSM)
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.closeButton)
                    .accessibilityLabel("Close the rules")
                }
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: LayoutConstants.spaceMS) {
                        DescentInfoPlate(
                            title: "Pick your path",
                            text: "Listen at every fork. Light a torch to see what waits in the dark.",
                            accent: DarkFantasyTheme.glowWarm
                        ) {
                            DescentRowIcon(asset: "rush2-icon-torch", size: 40)
                        }
                        DescentInfoPlate(
                            title: "Potions on your belt",
                            text: "Tap the flask any time, even mid-fight.",
                            accent: DarkFantasyTheme.danger
                        ) {
                            DescentRowIcon(asset: "rush2-icon-potion", size: 40)
                        }
                        DescentInfoPlate(
                            title: "Your bag is at risk",
                            text: "Fall, and you lose {-half your bag-}. Stash it at a campfire to keep it all, or {+climb out+} after a guardian.",
                            accent: DarkFantasyTheme.glowTreasure
                        ) {
                            DescentRowIcon(asset: "rush2-icon-goldpouch", size: 40)
                        }
                    }
                    .padding(.vertical, LayoutConstants.spaceXS)
                }
                Button("Got it", action: onClose)
                    .buttonStyle(.descentGold)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceMD)
        }
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
