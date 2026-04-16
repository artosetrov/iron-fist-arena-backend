import SwiftUI

// MARK: - Mine Shaft Card (Expandable)

/// Full-width expandable card for each mine slot. Collapsed shows thumbnail,
/// name, status, and shaft progress. Expanded reveals stats, lore, progress
/// bar, and action buttons. Mine art is used as 10% opacity background.
struct MineShaftCard: View {
    let index: Int
    let vm: GoldMineViewModel
    let isExpanded: Bool
    let onToggle: () -> Void

    @State private var showCollectBurst = false
    @State private var previousStatus: String = ""
    @State private var progressTick: Date = Date()

    private var slot: GoldMineSlotResponse {
        index < vm.slots.count
            ? vm.slots[index]
            : GoldMineSlotResponse(
                slotIndex: index,
                status: .idle,
                sessionId: nil,
                startedAt: nil,
                endsAt: nil,
                reward: nil,
                gemReward: nil,
                boosted: nil,
                minigamePlayed: nil,
                minigameSessionId: nil,
                stats: nil
            )
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
        // Unified with expandedMiningProgress — same shape, radius, and height
        // so the bar reads identically whether the card is collapsed or open.
        return GeometryReader { geo in
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
                    label: "MINED",
                    value: stats.map { formatCompact($0.totalGoldMined) } ?? "—"
                )
                mineStatBox(
                    label: "RUNS",
                    value: stats.map { "\($0.sessionsCompleted)" } ?? "—"
                )
                mineStatBox(
                    label: "BEST",
                    value: stats.map { "\($0.bestHaul)" } ?? "—"
                )
                mineStatBox(
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

    private func mineStatBox(label: String, value: String) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(label)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .tracking(0.5)

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
            HStack(alignment: .lastTextBaseline) {
                Text("TIME REMAINING")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .tracking(0.5)
                Spacer()
                Text(vm.timeRemaining(slot))
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .monospacedDigit()
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

                    // Only show BOOST when the session is not already boosted.
                    // Server returns 400 ALREADY_BOOSTED otherwise, which surfaced as a
                    // misleading "not enough gems" toast.
                    if !slot.isBoosted {
                        Button {
                            vm.boost(slotIndex: index)
                        } label: {
                            HStack(spacing: LayoutConstants.space2XS) {
                                Text("BOOST")
                                Text("\(vm.boostCost)")
                                    .monospacedDigit()
                                Image("icon-gems")
                                    .resizable()
                                    .frame(width: LayoutConstants.iconXS, height: LayoutConstants.iconXS)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.compactPrimary)
                    }
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

struct LockedMineCard: View {
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

struct MiningSparklesOverlay: View {
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

struct MineParticleSeed {
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
