import SwiftUI

struct GoldMineDetailView: View {
    @Environment(AppState.self) var appState
    @Environment(GameDataCache.self) private var cache
    @State var vm: GoldMineViewModel?
    @State var mineHint: NPCHint?

    /// Captured global center points of the currency icons inside
    /// `MineResourceHeader`. Used as `targetPoint` for live-tick coin flies.
    @State var resourceAnchors: [MineAnchorRole: CGPoint] = [:]
    /// Captured global center points of each active mine slot card. Used as
    /// `sourcePoint` for live-tick coin flies.
    @State var slotAnchors: [Int: CGPoint] = [:]
    /// Live in-flight coin/gem particle instances driven by `vm.advanceLiveTick`.
    @State var liveFlights: [LiveMineFlight] = []
    /// Last tick timestamp so we can pass real elapsed time to the VM.
    @State var lastTick: Date = Date()
    /// Currently expanded card index (nil = all collapsed).
    @State var expandedIndex: Int?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                Group {
                    if vm.isLoading && vm.slots.isEmpty {
                        mineLoadingState
                    } else if vm.slots.isEmpty {
                        ErrorStateView.loadFailed {
                            Task { await vm.loadStatus() }
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: LayoutConstants.spaceMD) {
                                MineResourceHeader(
                                    visualGold: vm.visualGold,
                                    visualGems: vm.visualGems,
                                    goldPerHour: vm.currentGoldPerHour,
                                    gemsPerHour: vm.currentGemsPerHour,
                                    activeSlotCount: vm.miningSlotCount
                                )
                                ActiveQuestBanner(questTypes: ["gold_mine_collect"])
                                if let shaft = vm.activeShaft {
                                    ActiveShaftBanner(
                                        shaft: shaft,
                                        onTap: vm.readySlotsCount > 0
                                            ? { Task { await vm.collectAll() } }
                                            : nil,
                                        isDisabled: vm.isCollectingAll || vm.readySlotsCount == 0
                                    )
                                }
                                miningOutputCard(vm: vm)
                                if vm.readySlotsCount >= 2 {
                                    collectAllButton(vm: vm)
                                }
                                mineCardsList(vm: vm)
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.bottom, LayoutConstants.spaceLG)
                        }
                    }
                }
                .transaction { $0.animation = nil }
                .onPreferenceChange(GoldMineAnchorPreferenceKey.self) { entries in
                    var next: [MineAnchorRole: CGPoint] = [:]
                    for entry in entries { next[entry.role] = entry.point }
                    resourceAnchors = next
                }
                .onPreferenceChange(MineSlotAnchorPreferenceKey.self) { entries in
                    var next: [Int: CGPoint] = [:]
                    for entry in entries { next[entry.slotIndex] = entry.point }
                    slotAnchors = next
                }
                // MARK: Variant D mini-game presentation
                // Shaft picker is a DS-styled overlay (not a native sheet) so it
                // carries the full modal chrome — gold border, brackets, diamonds,
                // radial glow — and never shows the iOS sheet's grey backing.
                .overlay {
                    if vm.showShaftPicker {
                        ShaftPickerSheet(
                            unlockedShafts: vm.unlockedShafts,
                            currentSlotLevel: vm.goldMineSlots,
                            onPick: { vm.pickShaft($0) },
                            onCancel: { vm.showShaftPicker = false }
                        )
                        .transition(.opacity)
                        .zIndex(900)
                    }
                }
                .animation(MotionConstants.snappy, value: vm.showShaftPicker)
                .fullScreenCover(item: Binding(
                    get: { vm.pendingMinigameSession },
                    set: { vm.pendingMinigameSession = $0 }
                )) { session in
                    GoldMineMiniGameView(
                        session: session,
                        character: appState.currentCharacter,
                        onFinish: { payload in vm.applySlotMinigameResult(payload) },
                        onSkip: { vm.cancelMinigameSession() }
                    )
                }
                .overlay {
                    if let clearedKey = vm.clearedShaftKey {
                        ShaftClearedOverlay(
                            clearedShaftKey: clearedKey,
                            onDismiss: { vm.dismissClearedOverlay() }
                        )
                    }
                }
                .overlay {
                    if let reward = vm.claimReward {
                        MineClaimRewardView(
                            goldEarned: reward.goldEarned,
                            gemsEarned: reward.gemsEarned,
                            onDismiss: { vm.claimReward = nil }
                        )
                        .transition(.opacity)
                    }
                }
            }

            // Live-tick coin/gem particle overlay
            liveFlightsOverlay
                .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .npcHint(.goldMine, isReady: vm != nil)
        .contextualHint(mineHint)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("GOLD MINE")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
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
            updateMineHint()
            lastTick = Date()
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { now in
            advanceLiveTick(now: now)
        }
    }

    // MARK: - Live Tick

    func advanceLiveTick(now: Date) {
        guard let vm else { return }
        let elapsed = max(0, min(5, now.timeIntervalSince(lastTick)))
        lastTick = now
        guard elapsed > 0 else { return }

        let delta = vm.advanceLiveTick(elapsedSec: elapsed)
        guard delta.coinsPerSlot > 0 || delta.gems > 0 else { return }

        let activeIndices = (0..<vm.slots.count).filter { idx in
            vm.slotStatus(vm.slots[idx]) == "mining"
        }
        guard !activeIndices.isEmpty else { return }

        if delta.coinsPerSlot > 0, let goldTarget = resourceAnchors[.gold] {
            for slotIdx in activeIndices {
                guard let source = slotAnchors[slotIdx] else { continue }
                for _ in 0..<delta.coinsPerSlot {
                    liveFlights.append(LiveMineFlight(
                        style: .gold,
                        source: source,
                        target: goldTarget
                    ))
                }
            }
        }

        if delta.gems > 0, let gemTarget = resourceAnchors[.gem] {
            if let sourceIdx = activeIndices.randomElement(),
               let source = slotAnchors[sourceIdx] {
                for _ in 0..<delta.gems {
                    liveFlights.append(LiveMineFlight(
                        style: .gems,
                        source: source,
                        target: gemTarget
                    ))
                }
            }
        }
    }

    // MARK: - Live Flights Overlay

    @ViewBuilder
    var liveFlightsOverlay: some View {
        ZStack {
            ForEach(liveFlights) { flight in
                CoinFlyAnimationView(
                    style: flight.style,
                    count: 1,
                    sourcePoint: flight.source,
                    targetPoint: flight.target,
                    onComplete: {
                        liveFlights.removeAll { $0.id == flight.id }
                    }
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Contextual Hint

    func updateMineHint() {
        guard let vm else { return }
        let readySlotsCount = vm.slots.filter { vm.slotStatus($0) == "ready" }.count
        let activeSlotsCount = vm.slots.filter { vm.slotStatus($0) == "mining" }.count
        let allSlotsBusy = activeSlotsCount == vm.maxSlots && readySlotsCount == 0
        let quests = appState.cachedTypedQuests ?? cache.cachedDailyQuests()?.quests ?? []
        mineHint = ContextualHintProvider.mineHint(
            readySlotsCount: readySlotsCount,
            allSlotsBusy: allSlotsBusy,
            quests: quests
        )
    }

    // MARK: - Mining Output Card

    func miningOutputCard(vm: GoldMineViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("MINING OUTPUT")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(1.5)

            HStack(spacing: LayoutConstants.spaceXS) {
                Image("icon-gold")
                    .resizable()
                    .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                    .accessibilityLabel("Gold per hour")
                    .accessibilityElement(children: .ignore)
                Text("\(vm.activeSlotCount * 200)/HR")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.4), value: vm.activeSlotCount)
                    .accessibilityLabel("Mining output: \(vm.activeSlotCount * 200) gold per hour")
            }

            Text("\(vm.activeSlotCount) Active Slots")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .accessibilityLabel("\(vm.activeSlotCount) active mining slots")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.goldBright.opacity(0.4), length: 16, thickness: 2.0)
        .shadow(color: DarkFantasyTheme.gold.opacity(0.1), radius: 8)
        .cardShadow()
    }

    // MARK: - Collect All Button (Variant D)

    func collectAllButton(vm: GoldMineViewModel) -> some View {
        Button {
            HapticManager.medium()
            Task { await vm.collectAll() }
        } label: {
            HStack(spacing: LayoutConstants.spaceXS) {
                Text("COLLECT ALL (\(vm.readySlotsCount))")
                Image("icon-gold")
                    .resizable()
                    .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary)
        .disabled(vm.isCollectingAll)
    }

    // MARK: - Mine Cards List (NEW — vertical expandable cards)

    func mineCardsList(vm: GoldMineViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ForEach(0..<vm.maxSlots, id: \.self) { index in
                MineShaftCard(
                    index: index,
                    vm: vm,
                    isExpanded: expandedIndex == index,
                    onToggle: {
                        withAnimation(MotionConstants.smooth) {
                            expandedIndex = expandedIndex == index ? nil : index
                        }
                    }
                )
                .staggeredAppear(index: index)
            }

            if vm.maxSlots < 6 {
                LockedMineCard(slotNumber: vm.maxSlots + 1, vm: vm)
                    .staggeredAppear(index: vm.maxSlots)
            }
        }
    }

    // MARK: - Loading State

    var mineLoadingState: some View {
        ScrollView {
            VStack(spacing: LayoutConstants.spaceMD) {
                // Skeleton output card
                VStack(spacing: LayoutConstants.spaceSM) {
                    SkeletonRect(width: 120, height: 14)
                    SkeletonRect(width: 160, height: 28)
                    SkeletonRect(width: 90, height: 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, LayoutConstants.spaceMD)
                .background(
                    RadialGlowBackground(
                        baseColor: DarkFantasyTheme.bgSecondary,
                        glowColor: DarkFantasyTheme.bgTertiary,
                        glowIntensity: 0.3,
                        cornerRadius: LayoutConstants.cardRadius
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                )

                // Skeleton cards (4 full-width)
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: LayoutConstants.spaceSM) {
                        SkeletonRect(width: 52, height: 52, cornerRadius: LayoutConstants.panelRadius)
                        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                            SkeletonRect(width: 120, height: 16)
                            SkeletonRect(width: 80, height: 12)
                        }
                        Spacer()
                        SkeletonRect(width: 32, height: 32, cornerRadius: LayoutConstants.panelRadius)
                    }
                    .padding(LayoutConstants.spaceSM)
                    .background(
                        RadialGlowBackground(
                            baseColor: DarkFantasyTheme.bgSecondary,
                            glowColor: DarkFantasyTheme.bgTertiary,
                            glowIntensity: 0.3,
                            cornerRadius: LayoutConstants.cardRadius
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
    }
}
