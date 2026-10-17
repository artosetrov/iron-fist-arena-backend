import SwiftUI

/// Gold Mine (2026-10-16 rework, art pass 2 on 2026-10-17): the foreman's
/// signboard header over the mine backdrop, the counter with gold and gems,
/// then the expedition chest track and the shaft — one tunnel level per mine
/// slot, with the cart riding each tunnel's rails. One big button collects
/// every full cart at once.
struct GoldMineDetailView: View {
    @Environment(AppState.self) var appState
    @Environment(GameDataCache.self) private var cache
    @State var vm: GoldMineViewModel?
    /// Tunnel whose details sheet is open.
    @State private var openTunnel: MineTunnelTarget?
    /// Bonus round asked for from the sheet — opened once the sheet is gone.
    @State private var bonusAfterSheet: Int?

    var body: some View {
        ZStack {
            MineBackdrop()

            if let vm {
                content(vm)
            } else {
                HexPulseLoader(.compact)
            }
        }
        .overlay {
            if let vm, let reward = vm.claimReward {
                MineClaimRewardView(reward: reward, onDismiss: {
                    // A correction (e.g. the chest) that landed while the
                    // modal was closing stays up instead of being dropped.
                    if vm.claimReward == reward { vm.claimReward = nil }
                })
                .transition(.opacity)
                .zIndex(ZLayer.takeover)
            }
        }
        .animation(MotionConstants.smooth, value: vm?.claimReward != nil)
        .onChange(of: vm?.claimReward != nil) { _, shown in
            // The celebration lives on this screen — don't leave it behind
            // the tunnel sheet (a chest opened from the sheet's COLLECT).
            if shown { openTunnel = nil }
        }
        .fullScreenCover(item: Binding(
            get: { vm?.pendingMinigameSession },
            set: { vm?.pendingMinigameSession = $0 }
        )) { session in
            GoldMineMiniGameView(
                session: session,
                character: appState.currentCharacter,
                onFinish: { payload in vm?.applySlotMinigameResult(payload) },
                onSkip: { vm?.cancelMinigameSession() }
            )
        }
        .sheet(item: $openTunnel, onDismiss: {
            guard let index = bonusAfterSheet else { return }
            bonusAfterSheet = nil
            Task { await vm?.startSlotMinigame(slotIndex: index) }
        }) { target in
            if let vm {
                MineTunnelSheet(index: target.id, vm: vm) {
                    bonusAfterSheet = target.id
                    openTunnel = nil
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .npcHint(.goldMine, isReady: vm != nil)
        .toolbar {
            // The title lives on the signboard (like the shop and the black
            // market) — nothing in the bar's middle to collide with it.
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
        }
        .onAppear {
            AmbientManager.shared.setZone(.goldMine)
        }
        .onDisappear {
            AmbientManager.shared.setZone(.hub)
        }
        .task {
            if vm == nil { vm = GoldMineViewModel(appState: appState, cache: cache) }
            await vm?.loadStatus()
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { now in
            vm?.tick(now: now)
        }
    }

    // MARK: - Content

    private func content(_ vm: GoldMineViewModel) -> some View {
        VStack(spacing: 0) {
            // The foreman's first line is about right now (full carts, an
            // empty tunnel, the next cart's time) — refreshed every 30 s.
            TimelineView(.periodic(from: .now, by: 30)) { context in
                ShopkeeperHeader(
                    style: .goldMine,
                    title: "GOLD MINE",
                    tagline: "Dig deep · Haul gold",
                    keeperName: "Mine Foreman",
                    keeperImage: NPCSpeaker.mine.portrait,
                    // Silent until the tunnels are known, so he never
                    // calls an unloaded tunnel "empty".
                    lines: vm.slots.isEmpty ? [] : vm.foremanLines(now: context.date),
                    startIndex: 0
                )
            }

            MineCounterBar(gold: vm.gold, gems: vm.gems) {
                appState.mainPath.append(AppRoute.currencyPurchase())
            }

            if vm.isLoading && vm.slots.isEmpty {
                loadingState
            } else if vm.slots.isEmpty {
                ErrorStateView.loadFailed {
                    Task { await vm.loadStatus() }
                }
                .frame(maxHeight: .infinity)
            } else {
                mine(vm)
            }
        }
    }

    // MARK: - Mine

    private func mine(_ vm: GoldMineViewModel) -> some View {
        ScrollView {
            VStack(spacing: LayoutConstants.spaceMD) {
                if let expedition = vm.expedition {
                    MineExpeditionTrack(expedition: expedition, economy: vm.economy)
                }
                ActiveQuestBanner(questTypes: ["gold_mine_collect"])
                shaft(vm)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceMD)
            .padding(.bottom, LayoutConstants.space2XL)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            if vm.readyCount >= 2 {
                collectAllBar(vm)
            }
        }
    }

    /// Tunnel levels down the ladder, then the sealed one (if the cap allows more).
    private func shaft(_ vm: GoldMineViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            ForEach(0..<vm.maxSlots, id: \.self) { index in
                MineTunnelLevel(index: index, vm: vm) {
                    openTunnel = MineTunnelTarget(id: index)
                }
            }
            if vm.canOpenTunnel {
                MineSealedLevel(number: vm.maxSlots + 1, vm: vm)
            }
        }
        .background(alignment: .leading) {
            // Ladder centred under the level plates.
            MineShaftLadder()
                .padding(.leading, (MineLevelBadge.width - MineShaftLadder.width) / 2)
        }
    }

    private func collectAllBar(_ vm: GoldMineViewModel) -> some View {
        Button {
            Task { await vm.collectAll() }
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                Text("COLLECT ALL \(vm.readyCount) CARTS")
                if vm.readyGold > 0 {
                    MineIcon(name: "icon-gold", size: 22)
                    Text("+\(vm.readyGold)")
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary)
        .disabled(vm.isCollectingAll)
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(DarkFantasyTheme.bgPrimary.opacity(0.95))
    }

    // MARK: - Loading

    private var loadingState: some View {
        ScrollView {
            VStack(spacing: LayoutConstants.spaceMD) {
                SkeletonRect(height: 132, cornerRadius: LayoutConstants.cardRadius)
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonRect(height: MineTunnelLevel.height, cornerRadius: LayoutConstants.cardRadius)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceMD)
        }
        .scrollIndicators(.hidden)
    }
}
