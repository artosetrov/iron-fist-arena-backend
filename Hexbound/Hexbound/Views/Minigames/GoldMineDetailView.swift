import SwiftUI

struct GoldMineDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: GoldMineViewModel?
    @State private var mineHint: NPCHint?

    /// Captured global center points of the currency icons inside
    /// `MineResourceHeader`. Used as `targetPoint` for live-tick coin flies.
    @State private var resourceAnchors: [MineAnchorRole: CGPoint] = [:]
    /// Captured global center points of each active mine slot card. Used as
    /// `sourcePoint` for live-tick coin flies.
    @State private var slotAnchors: [Int: CGPoint] = [:]
    /// Live in-flight coin/gem particle instances driven by `vm.advanceLiveTick`.
    @State private var liveFlights: [LiveMineFlight] = []
    /// Last tick timestamp so we can pass real elapsed time to the VM.
    @State private var lastTick: Date = Date()
    /// Currently expanded card index (nil = all collapsed).
    @State private var expandedIndex: Int?

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
                .sheet(isPresented: Binding(
                    get: { vm.showShaftPicker },
                    set: { vm.showShaftPicker = $0 }
                )) {
                    ShaftPickerSheet(
                        unlockedShafts: vm.unlockedShafts,
                        currentSlotLevel: vm.goldMineSlots,
                        onPick: { vm.pickShaft($0) },
                        onCancel: { vm.showShaftPicker = false }
                    )
                }
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

    private func advanceLiveTick(now: Date) {
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
    private var liveFlightsOverlay: some View {
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

    private func updateMineHint() {
        guard let vm else { return }
        let readySlotsCount = vm.slots.filter { ($0["status"] as? String) == "ready" }.count
        let activeSlotsCount = vm.slots.filter { ($0["status"] as? String) == "mining" }.count
        let allSlotsBusy = activeSlotsCount == vm.maxSlots && readySlotsCount == 0
        let quests = appState.cachedTypedQuests ?? cache.cachedDailyQuests()?.quests ?? []
        mineHint = ContextualHintProvider.mineHint(
            readySlotsCount: readySlotsCount,
            allSlotsBusy: allSlotsBusy,
            quests: quests
        )
    }

    // MARK: - Mining Output Card

    private func miningOutputCard(vm: GoldMineViewModel) -> some View {
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

    private func collectAllButton(vm: GoldMineViewModel) -> some View {
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

    private func mineCardsList(vm: GoldMineViewModel) -> some View {
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

    private var mineLoadingState: some View {
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

// MARK: - Mine Shaft Card (Expandable)

/// Full-width expandable card for each mine slot. Collapsed shows thumbnail,
/// name, status, and shaft progress. Expanded reveals stats, lore, progress
/// bar, and action buttons. Mine art is used as 10% opacity background.
private struct MineShaftCard: View {
    let index: Int
    let vm: GoldMineViewModel
    let isExpanded: Bool
    let onToggle: () -> Void

    @State private var showCollectBurst = false
    @State private var previousStatus: String = ""
    @State private var progressTick: Date = Date()

    private var slot: [String: Any] {
        index < vm.slots.count ? vm.slots[index] : [:]
    }
    private var status: String { vm.slotStatus(slot) }
    private var isActing: Bool { vm.actionSlotId == "\(index)" }

    /// Theme-based accent color per slot index — no hardcoded hex
    private var slotAccent: Color {
        let accents: [Color] = [
            DarkFantasyTheme.purple,
            DarkFantasyTheme.success,
            DarkFantasyTheme.stamina,
            DarkFantasyTheme.cyan,
            DarkFantasyTheme.danger,
            DarkFantasyTheme.goldBright
        ]
        return index < accents.count ? accents[index] : DarkFantasyTheme.gold
    }

    /// Lore flavor text per mine slot
    private var mineLore: String {
        let lore = [
            "Ancient amethyst deposits shimmer in the dark, whispering of forgotten riches.",
            "Veins of pure emerald pulse with an inner light, as if the mountain breathes.",
            "Liquid gold streams through volcanic rock. The forge never sleeps.",
            "Ice-locked caverns where time stands still and diamonds form in eternal frost.",
            "Crimson quartz veins run deep, stained by the blood of the mountain.",
            "A king's ransom lies buried beneath gilded stone and ancient wards."
        ]
        return index < lore.count ? lore[index] : "Uncharted depths await."
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Collapsed header — always visible
            collapsedHeader

            // MARK: Mining progress bar — visible when mining (collapsed)
            if status == "mining" && !isExpanded {
                collapsedProgressBar
            }

            // MARK: Expanded content
            if isExpanded {
                expandedContent
            }
        }
        .background(
            // Mine art as 10% opacity background across entire card
            ZStack {
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.cardRadius
                )

                Image("mine-slot-\(index + 1)")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.1)
                    .clipped()
            }
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: DarkFantasyTheme.borderMedium.opacity(0.15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(cardBorderColor, lineWidth: status == "ready" ? 2 : 1)
                .opacity(status != "idle" ? 0.8 : 0.6)
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .shadow(color: cardShadowColor, radius: status != "idle" ? 8 : 3, y: 2)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
        .overlay {
            if showCollectBurst {
                GeometryReader { geo in
                    RewardBurstView(style: .gold, isActive: $showCollectBurst)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .allowsHitTesting(false)
                }
            }
        }
        // Publish slot center for coin-fly source
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: MineSlotAnchorPreferenceKey.self,
                        value: [MineSlotAnchorEntry(
                            slotIndex: index,
                            point: CGPoint(
                                x: geo.frame(in: .global).midX,
                                y: geo.frame(in: .global).midY
                            )
                        )]
                    )
            }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .onAppear {
            previousStatus = status
        }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { now in
            if status == "mining" { progressTick = now }
        }
        .onChange(of: status) { oldVal, newVal in
            if previousStatus == "ready" && newVal == "idle" {
                HapticManager.success()
                showCollectBurst = true
            }
            previousStatus = newVal
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(GoldMineViewModel.mineName(for: index)), \(status). \(status == "mining" ? vm.timeRemaining(slot) : "")"
        )
        .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand details")
    }

    // MARK: - Collapsed Header

    private var collapsedHeader: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Mine thumbnail
            Image("mine-slot-\(index + 1)")
                .resizable()
                .scaledToFill()
                .frame(width: LayoutConstants.mineThumbnailSize, height: LayoutConstants.mineThumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(slotAccent.opacity(0.4), lineWidth: 1)
                )
                .opacity(status == "idle" ? 0.6 : 1.0)

            // Name + status
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(GoldMineViewModel.mineName(for: index).uppercased())
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)

                    // Streak badge (collapsed)
                    if let stats = vm.slotStats(at: index), stats.currentStreak >= 3 {
                        HStack(spacing: LayoutConstants.space2XS) {
                            Image(systemName: stats.currentStreak >= 5 ? "flame.fill" : "bolt.fill")
                                .font(DarkFantasyTheme.badge)
                            Text("\(stats.currentStreak)")
                                .font(DarkFantasyTheme.badge)
                        }
                        .foregroundStyle(stats.currentStreak >= 5 ? DarkFantasyTheme.stamina : DarkFantasyTheme.gold)
                        .padding(.horizontal, LayoutConstants.spaceXS)
                        .padding(.vertical, LayoutConstants.space2XS)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .fill(
                                    (stats.currentStreak >= 5 ? DarkFantasyTheme.stamina : DarkFantasyTheme.gold)
                                        .opacity(0.12)
                                )
                        )
                    }

                    // Bonus badge (compact)
                    if status == "mining" || status == "ready" {
                        compactBonusBadge
                    }
                }

                HStack(spacing: LayoutConstants.spaceXS) {
                    statusIndicator
                    if status == "mining" {
                        Text("· \(vm.timeRemaining(slot))")
                            .font(DarkFantasyTheme.caption)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Shaft progress mini
            if let shaft = vm.activeShaft {
                VStack(spacing: 0) {
                    Text("Shaft")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text(shaft.progressLabel)
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(slotAccent)
                }
            }

            // Chevron
            Image(systemName: "chevron.down")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceSM)
    }

    // MARK: - Compact Bonus Badge

    @ViewBuilder
    private var compactBonusBadge: some View {
        if vm.isSlotMinigamePlayed(slot) {
            HStack(spacing: LayoutConstants.space2XS) {
                Image(systemName: "checkmark")
                    .font(DarkFantasyTheme.badge)
            }
            .foregroundStyle(DarkFantasyTheme.textPrimary)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(DarkFantasyTheme.success.opacity(0.85))
            )
        } else {
            HStack(spacing: LayoutConstants.space2XS) {
                Image(systemName: "sparkles")
                    .font(DarkFantasyTheme.badge)
            }
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(DarkFantasyTheme.goldGradient)
            )
        }
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Circle()
                .fill(statusColor)
                .frame(width: LayoutConstants.spaceSM, height: LayoutConstants.spaceSM)
                .shadow(color: statusColor.opacity(status != "idle" ? 0.6 : 0), radius: 4)

            Text(statusLabel)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(statusColor)
                .tracking(1.0)
        }
    }

    private var statusColor: Color {
        switch status {
        case "mining": return DarkFantasyTheme.gold
        case "ready": return DarkFantasyTheme.success
        default: return DarkFantasyTheme.textTertiary
        }
    }

    private var statusLabel: String {
        switch status {
        case "mining": return "MINING"
        case "ready": return "READY"
        default: return "IDLE"
        }
    }

    // MARK: - Collapsed Progress Bar

    private var collapsedProgressBar: some View {
        let _ = progressTick
        let progress = vm.miningProgress(slot)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(DarkFantasyTheme.borderSubtle)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [slotAccent, DarkFantasyTheme.gold],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * max(0, min(1, progress)))
                    .animation(.linear(duration: 1), value: progress)
            }
        }
        .frame(height: LayoutConstants.mineProgressCollapsed)
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.bottom, LayoutConstants.spaceSM)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Divider
            Rectangle()
                .fill(DarkFantasyTheme.borderSubtle)
                .frame(height: 1)
                .padding(.horizontal, LayoutConstants.spaceSM)

            // Lore text
            Text(mineLore)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .italic()
                .opacity(0.7)
                .lineLimit(2)
                .padding(.horizontal, LayoutConstants.spaceSM)

            // Stats row
            HStack(spacing: LayoutConstants.spaceXS) {
                let stats = vm.slotStats(at: index)
                mineStatBox(
                    icon: "hammer.fill",
                    label: "MINED",
                    value: stats.map { formatCompact($0.totalGoldMined) } ?? "—"
                )
                mineStatBox(
                    icon: "chart.bar.fill",
                    label: "RUNS",
                    value: stats.map { "\($0.sessionsCompleted)" } ?? "—"
                )
                mineStatBox(
                    icon: "trophy.fill",
                    label: "BEST",
                    value: stats.map { "\($0.bestHaul)" } ?? "—"
                )
                mineStatBox(
                    icon: "bolt.fill",
                    label: "RATE",
                    value: "\(200)/h"
                )
            }
            .padding(.horizontal, LayoutConstants.spaceSM)

            // Streak badge (if active)
            if let stats = vm.slotStats(at: index), stats.currentStreak >= 2 {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: stats.currentStreak >= 5 ? "flame.fill" : "bolt.fill")
                        .font(DarkFantasyTheme.caption)
                    Text("\(stats.currentStreak) streak")
                        .font(DarkFantasyTheme.caption)
                        .bold()
                }
                .foregroundStyle(stats.currentStreak >= 5 ? DarkFantasyTheme.stamina : DarkFantasyTheme.gold)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .fill(
                            (stats.currentStreak >= 5 ? DarkFantasyTheme.stamina : DarkFantasyTheme.gold)
                                .opacity(0.08)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(
                            (stats.currentStreak >= 5 ? DarkFantasyTheme.stamina : DarkFantasyTheme.gold)
                                .opacity(0.2),
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, LayoutConstants.spaceSM)
            }

            // Mining progress (when mining)
            if status == "mining" {
                expandedMiningProgress
            }

            // Action buttons
            actionButtons
                .padding(.horizontal, LayoutConstants.spaceSM)
        }
        .padding(.bottom, LayoutConstants.spaceSM)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Stat Box

    private func mineStatBox(icon: String, label: String, value: String) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            HStack(spacing: LayoutConstants.space2XS) {
                Image(systemName: icon)
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Text(label)
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .tracking(0.5)
            }

            Text(value)
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgPrimary.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Expanded Mining Progress

    private var expandedMiningProgress: some View {
        let _ = progressTick
        let progress = vm.miningProgress(slot)
        return VStack(spacing: LayoutConstants.spaceXS) {
            HStack {
                Text("TIME REMAINING")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .tracking(0.5)
                Spacer()
                Text(vm.timeRemaining(slot))
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .bold()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.borderSubtle)

                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(
                            LinearGradient(
                                colors: [slotAccent, DarkFantasyTheme.gold],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                        .frame(width: geo.size.width * max(0, min(1, progress)))
                        .animation(.linear(duration: 1), value: progress)
                }
            }
            .frame(height: LayoutConstants.mineProgressHeight)

            // Vein hint based on progress
            veinHint(progress: progress)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
    }

    // MARK: - Vein Hint (NEW — progressive discovery during mining)

    @ViewBuilder
    private func veinHint(progress: Double) -> some View {
        let hint: (String, Color)? = {
            if progress >= 0.75 {
                return ("Rare deposit detected!", DarkFantasyTheme.gold)
            } else if progress >= 0.50 {
                return ("Rich vein found", DarkFantasyTheme.purple)
            } else if progress >= 0.25 {
                return ("Detecting minerals...", DarkFantasyTheme.textSecondary)
            }
            return nil
        }()

        if let (text, color) = hint {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: progress >= 0.75 ? "exclamationmark.triangle.fill" : "sparkle")
                    .font(DarkFantasyTheme.caption)
                Text(text)
                    .font(DarkFantasyTheme.caption)
            }
            .foregroundStyle(color)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.spaceXS)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(color.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if isActing {
            HexPulseLoader(.compact)
                .tint(DarkFantasyTheme.gold)
                .frame(height: LayoutConstants.mineLoaderHeight)
        } else {
            switch status {
            case "idle":
                Button {
                    HapticManager.medium()
                    Task { await vm.startMining(slotIndex: index) }
                } label: {
                    Text("START MINING")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.compactPrimary)

            case "mining":
                HStack(spacing: LayoutConstants.spaceSM) {
                    if !vm.isSlotMinigamePlayed(slot) {
                        Button {
                            HapticManager.medium()
                            Task { await vm.startSlotMinigame(slotIndex: index) }
                        } label: {
                            HStack(spacing: LayoutConstants.space2XS) {
                                Text("BONUS")
                                Image(systemName: "sparkles")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.compactOutline(color: DarkFantasyTheme.gold))
                        .disabled(vm.isStartingSlotMinigame)
                    }

                    Button {
                        vm.boost(slotIndex: index)
                    } label: {
                        HStack(spacing: LayoutConstants.space2XS) {
                            Text("BOOST")
                            Image("icon-gems")
                                .resizable()
                                .frame(width: LayoutConstants.iconXS, height: LayoutConstants.iconXS)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.compactOutline(color: DarkFantasyTheme.cyan))
                }

            case "ready":
                if vm.isSlotMinigamePlayed(slot) {
                    Button {
                        HapticManager.medium()
                        Task { await vm.collectAll() }
                    } label: {
                        HStack(spacing: LayoutConstants.space2XS) {
                            Text("COLLECT")
                            Image("icon-gold")
                                .resizable()
                                .frame(width: LayoutConstants.iconXS, height: LayoutConstants.iconXS)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.compactPrimary)
                    .disabled(vm.isCollectingAll)
                } else {
                    Button {
                        HapticManager.medium()
                        Task { await vm.startSlotMinigame(slotIndex: index) }
                    } label: {
                        HStack(spacing: LayoutConstants.space2XS) {
                            Text("PLAY BONUS")
                            Image(systemName: "sparkles")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.compactPrimary)
                    .disabled(vm.isStartingSlotMinigame)
                }

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Card Colors

    private var cardBorderColor: Color {
        switch status {
        case "mining": return slotAccent
        case "ready": return DarkFantasyTheme.goldBright
        default: return DarkFantasyTheme.borderSubtle
        }
    }

    private var cardShadowColor: Color {
        switch status {
        case "mining": return slotAccent.opacity(0.3)
        case "ready": return DarkFantasyTheme.goldGlow
        default: return .clear
        }
    }

    // MARK: - Helpers

    /// Compact number formatting: 1234 → "1.2K", 530 → "530"
    private func formatCompact(_ value: Int) -> String {
        if value >= 1000 {
            let k = Double(value) / 1000.0
            return String(format: "%.1fK", k)
        }
        return "\(value)"
    }
}

// MARK: - Locked Mine Card

private struct LockedMineCard: View {
    let slotNumber: Int
    let vm: GoldMineViewModel

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Locked mine thumbnail
            ZStack {
                Image("mine-slot-locked")
                    .resizable()
                    .scaledToFill()
                    .frame(width: LayoutConstants.mineThumbnailSize, height: LayoutConstants.mineThumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))

                DarkFantasyTheme.bgScrim
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))

                Image(systemName: "lock.fill")
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.6))
            }
            .frame(width: LayoutConstants.mineThumbnailSize, height: LayoutConstants.mineThumbnailSize)

            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text("SLOT \(slotNumber)")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)

                HStack(spacing: LayoutConstants.space2XS) {
                    Text("Unlock for")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Image("icon-gems")
                        .resizable()
                        .frame(width: LayoutConstants.iconXS, height: LayoutConstants.iconXS)
                    Text("50")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.cyan)
                }
            }

            Spacer()

            Button {
                vm.buySlot()
            } label: {
                Text("UNLOCK")
            }
            .buttonStyle(.compactOutline(color: DarkFantasyTheme.borderMedium, fillOpacity: 0.15))
            .disabled(vm.isBuyingSlot)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceSM)
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
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .opacity(0.6)
    }
}

// MARK: - Mining Sparkles Overlay (Particle Animation)
// Pure SwiftUI — no timers, no state mutation.
// Uses TimelineView + Canvas to compute particles from current time.

private struct MiningSparklesOverlay: View {
    let tint: Color

    // Pre-computed particle seeds — golden ratio for quasi-random spread
    private static let seeds: [MineParticleSeed] = {
        let phi = 0.6180339887
        return (0..<12).map { i in
            let h = (Double(i) * phi).truncatingRemainder(dividingBy: 1.0)
            let h2 = (Double(i + 5) * phi).truncatingRemainder(dividingBy: 1.0)
            return MineParticleSeed(
                x: 0.1 + h * 0.8,
                xDrift: -0.04 + h2 * 0.08,
                size: 2 + h * 3,
                speed: 0.3 + h2 * 0.4,
                phaseOffset: Double(i) * 0.22
            )
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for seed in Self.seeds {
                    let cycle: Double = 2.5
                    let raw = (time * seed.speed + seed.phaseOffset)
                    let t = (raw - floor(raw / cycle) * cycle) / cycle

                    let alpha = sin(t * .pi)
                    let y = size.height * (1.0 - t * 0.85)
                    let x = (seed.x + seed.xDrift * sin(time * 2 + seed.phaseOffset * 6)) * size.width
                    let s = seed.size * (0.6 + 0.4 * (1 - t))

                    context.opacity = alpha * 0.7
                    context.fill(
                        Circle().path(in: CGRect(
                            x: x - s / 2,
                            y: y - s / 2,
                            width: s,
                            height: s
                        )),
                        with: .color(tint)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct MineParticleSeed {
    let x: CGFloat
    let xDrift: CGFloat
    let size: CGFloat
    let speed: Double
    let phaseOffset: Double
}

// MARK: - Slot Anchor Preference Key

struct MineSlotAnchorEntry: Equatable {
    let slotIndex: Int
    let point: CGPoint
}

struct MineSlotAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [MineSlotAnchorEntry] = []

    static func reduce(value: inout [MineSlotAnchorEntry], nextValue: () -> [MineSlotAnchorEntry]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - Live Flight (coin / gem particle in transit)

struct LiveMineFlight: Identifiable, Equatable {
    let id = UUID()
    let style: CoinStyle
    let source: CGPoint
    let target: CGPoint
}
