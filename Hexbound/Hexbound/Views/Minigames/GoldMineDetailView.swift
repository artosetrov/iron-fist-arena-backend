import SwiftUI

struct GoldMineDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: GoldMineViewModel?

    private let columns = [
        GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
        GridItem(.flexible(), spacing: LayoutConstants.spaceSM)
    ]

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                Group {
                    if vm.isLoading && vm.slots.isEmpty {
                        mineLoadingState
                    } else if vm.slots.isEmpty {
                        // Error state — loading failed
                        ErrorStateView.loadFailed {
                            Task { await vm.loadStatus() }
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: LayoutConstants.spaceMD) {
                                ActiveQuestBanner(questTypes: ["gold_mine_collect"])
                                miningOutputCard(vm: vm)
                                slotsGrid(vm: vm)
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.bottom, LayoutConstants.spaceLG)
                        }
                    }
                }
                .transaction { $0.animation = nil }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("GOLD MINE")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .task {
            if vm == nil { vm = GoldMineViewModel(appState: appState, cache: cache) }
            await vm?.loadStatus()
        }
    }

    // MARK: - Mining Output Card

    private func miningOutputCard(vm: GoldMineViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("MINING OUTPUT")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(1.5)

            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 22))
                    .accessibilityLabel("Gold per hour")
                    .accessibilityElement(children: .ignore)
                Text("\(vm.activeSlotCount * 200)/HR")
                    .font(DarkFantasyTheme.title(size: 32))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.4), value: vm.activeSlotCount)
                    .accessibilityLabel("Mining output: \(vm.activeSlotCount * 200) gold per hour")
            }

            Text("\(vm.activeSlotCount) Active Slots")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
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
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    // MARK: - Slots Grid

    private func slotsGrid(vm: GoldMineViewModel) -> some View {
        LazyVGrid(columns: columns, spacing: LayoutConstants.spaceSM) {
            ForEach(0..<vm.maxSlots, id: \.self) { index in
                MineSlotCard(index: index, vm: vm)
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

                // Skeleton grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
                    GridItem(.flexible(), spacing: LayoutConstants.spaceSM)
                ], spacing: LayoutConstants.spaceSM) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(spacing: 0) {
                            SkeletonRect(height: 110, cornerRadius: 0)
                            VStack(spacing: LayoutConstants.spaceXS) {
                                SkeletonRect(width: 60, height: 14)
                                SkeletonRect(width: 80, height: 10)
                                SkeletonRect(height: 32, cornerRadius: LayoutConstants.panelRadius)
                            }
                            .padding(LayoutConstants.spaceSM)
                        }
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
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
    }
}

// MARK: - Mine Slot Card

private struct MineSlotCard: View {
    let index: Int
    let vm: GoldMineViewModel

    @State private var glowPulse = false
    @State private var showCollectBurst = false
    @State private var showCoinFly = false
    @State private var previousStatus: String = ""

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

    var body: some View {
        VStack(spacing: 0) {
            mineIllustration
            infoPanel
        }
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    cardBorderColor,
                    lineWidth: status == "ready" ? 2 : 1
                )
                .opacity(glowPulse && status != "idle" ? 1 : 0.6)
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
        .overlay {
            if showCoinFly {
                GeometryReader { geo in
                    let sourcePoint = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    // Target is top-right corner (approximately where currency display would be)
                    let targetPoint = CGPoint(x: UIScreen.main.bounds.width - 20, y: 60)
                    CoinFlyAnimationView(
                        style: .gold,
                        count: 6,
                        sourcePoint: sourcePoint,
                        targetPoint: targetPoint,
                        onComplete: { showCoinFly = false }
                    )
                    .allowsHitTesting(false)
                }
            }
        }
        .animation(
            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
            value: glowPulse
        )
        .onAppear {
            previousStatus = status
            startGlowIfNeeded()
        }
        .onChange(of: status) { oldVal, newVal in
            startGlowIfNeeded()
            // Detect collect: was "ready" → now "idle" (gold collected)
            if previousStatus == "ready" && newVal == "idle" {
                HapticManager.success()
                showCollectBurst = true
                showCoinFly = true
            }
            previousStatus = newVal
        }
    }

    // MARK: - Mine Illustration

    private var mineIllustration: some View {
        ZStack {
            // Unique gradient background per slot (uses theme tokens only)
            LinearGradient(
                colors: [slotAccent.opacity(0.2), DarkFantasyTheme.bgTertiary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // AI-generated mine illustration per slot
            Image("mine-slot-\(index + 1)")
                .resizable()
                .scaledToFill()
                .opacity(status == "idle" ? 0.6 : 1.0)
                .breathing(scale: 0.006, isActive: status == "mining")

            // Status-specific overlays
            switch status {
            case "mining":
                // Warm glow rising from bottom
                LinearGradient(
                    colors: [DarkFantasyTheme.gold.opacity(0.35), .clear],
                    startPoint: .bottom, endPoint: .center
                )

                // Animated sparkle particles
                MiningSparklesOverlay(tint: slotAccent)

            case "ready":
                // Golden shimmer wash
                LinearGradient(
                    colors: [
                        DarkFantasyTheme.goldBright.opacity(0.25),
                        .clear,
                        DarkFantasyTheme.goldBright.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Coin sparkle in corner
                Image(systemName: "sparkles")
                    .font(.system(size: 24)) // SF Symbol — keep
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .shadow(color: DarkFantasyTheme.goldGlow, radius: 12)
                    .offset(x: 35, y: -20)
                    .opacity(glowPulse ? 1.0 : 0.5)

            case "idle":
                DarkFantasyTheme.bgScrim

            default:
                EmptyView()
            }
        }
        .frame(height: 110)
        .clipped()
    }

    // MARK: - Info Panel

    private var infoPanel: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("SLOT \(index + 1)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .accessibilityLabel("Mining slot \(index + 1)")

            statusLabel

            if status == "mining" {
                mineProgressBar
            }

            // Action button area
            if isActing {
                ProgressView()
                    .tint(DarkFantasyTheme.gold)
                    .frame(height: 34)
            } else {
                actionButton
            }
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceSM)
    }

    // MARK: - Status Label

    @ViewBuilder
    private var statusLabel: some View {
        switch status {
        case "mining":
            Text("Mining... \(vm.timeRemaining(slot))")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        case "ready":
            Text("Ready to collect!")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.success)
        default:
            Text("Idle")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
    }

    // MARK: - Progress Bar

    private var mineProgressBar: some View {
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
                    .frame(width: geo.size.width * max(0, min(1, vm.miningProgress(slot))))
                    .animation(.linear(duration: 1), value: vm.miningProgress(slot))
            }
        }
        .frame(height: 5)
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        switch status {
        case "idle":
            Button {
                HapticManager.medium()
                Task { await vm.startMining(slotIndex: index) }
            } label: {
                Text("MINE")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.compactPrimary)

        case "mining":
            Button {
                HapticManager.light()
                Task { await vm.boost(slotIndex: index) }
            } label: {
                HStack(spacing: LayoutConstants.space2XS) {
                    Text("BOOST")
                    Image(systemName: "diamond")
                        .font(.system(size: 10))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.compactOutline(color: DarkFantasyTheme.cyan))

        case "ready":
            Button {
                HapticManager.medium()
                Task { await vm.collect(slotIndex: index) }
            } label: {
                HStack(spacing: LayoutConstants.space2XS) {
                    Text("COLLECT")
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 10))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.compactPrimary)
            .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.5, isActive: true)

        default:
            EmptyView()
        }
    }

    // MARK: - Card Colors

    private var cardBorderColor: Color {
        switch status {
        case "mining": slotAccent
        case "ready": DarkFantasyTheme.goldBright
        default: DarkFantasyTheme.borderSubtle
        }
    }

    private var cardShadowColor: Color {
        switch status {
        case "mining": slotAccent.opacity(0.3)
        case "ready": DarkFantasyTheme.goldGlow
        default: .clear
        }
    }

    // MARK: - Animation

    private func startGlowIfNeeded() {
        glowPulse = (status == "mining" || status == "ready")
    }
}

// MARK: - Locked Mine Card

private struct LockedMineCard: View {
    let slotNumber: Int
    let vm: GoldMineViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Locked mine illustration
            ZStack {
                Image("mine-slot-locked")
                    .resizable()
                    .scaledToFill()

                // Darken overlay
                DarkFantasyTheme.bgScrim

                Image(systemName: "lock.fill")
                    .font(.system(size: 28)) // SF Symbol icon — keep
                    .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.6))
            }
            .frame(height: 110)
            .clipped()

            // Info
            VStack(spacing: LayoutConstants.spaceXS) {
                Text("SLOT \(slotNumber)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)

                HStack(spacing: LayoutConstants.space2XS) {
                    Text("Unlock for")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Image(systemName: "diamond")
                        .font(.system(size: 10))
                    Text("50")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.cyan)
                }

                Button {
                    Task { await vm.buySlot() }
                } label: {
                    Text("UNLOCK")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.compactOutline(color: DarkFantasyTheme.borderMedium, fillOpacity: 0.15))
                .disabled(vm.isBuyingSlot)
            }
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.spaceSM)
        }
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
                    // Each particle loops through its own lifecycle
                    let cycle: Double = 2.5
                    let raw = (time * seed.speed + seed.phaseOffset)
                    let t = (raw - floor(raw / cycle) * cycle) / cycle

                    let alpha = sin(t * .pi) // smooth fade in/out
                    let y = size.height * (1.0 - t * 0.85) // rise from bottom
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
