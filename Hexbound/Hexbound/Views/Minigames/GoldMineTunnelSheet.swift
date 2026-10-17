import SwiftUI

/// Which tunnel's details sheet is open.
struct MineTunnelTarget: Identifiable, Equatable {
    let id: Int
}

/// Tap on a tunnel: what this cart brings, the optional bonus run, the
/// double haul, and the tunnel's main action (send / collect).
struct MineTunnelSheet: View {
    let index: Int
    @Bindable var vm: GoldMineViewModel
    /// The bonus round is a full-screen cover; the parent closes this sheet
    /// first and opens the round once it is gone.
    let onPlayBonus: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let phase = vm.phase(index, now: now)
            let slot = vm.slot(index)
            ScrollView {
                VStack(alignment: .leading, spacing: LayoutConstants.spaceMD) {
                    header(phase: phase)
                    artPanel(phase: phase, now: now)
                    haulRow(phase: phase, slot: slot)
                    if phase != .idle {
                        bonusRow(slot: slot)
                        boostRow(slot: slot)
                    }
                    primaryAction(phase: phase, slot: slot)
                    if let stats = slot.stats, stats.sessionsCompleted > 0 {
                        statsLine(stats)
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.top, LayoutConstants.spaceLG)
                .padding(.bottom, LayoutConstants.spaceLG)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DarkFantasyTheme.bgSecondary)
    }

    // MARK: Header

    private func header(phase: GoldMineViewModel.TunnelPhase) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(GoldMineViewModel.mineName(for: index))
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text(subtitle(phase))
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.closeButton)
            .accessibilityLabel("Close tunnel details")
        }
    }

    private func subtitle(_ phase: GoldMineViewModel.TunnelPhase) -> String {
        switch phase {
        case .idle: return "The rails are empty."
        case .mining: return "The cart is on its way up."
        case .ready: return "The cart is full. Haul it up!"
        }
    }

    // MARK: Art + rails + timer

    private func artPanel(phase: GoldMineViewModel.TunnelPhase, now: Date) -> some View {
        ZStack(alignment: .topTrailing) {
            MineTunnelArt(index: index, dimmed: phase == .idle)
            LinearGradient(
                colors: [DarkFantasyTheme.bgPrimary.opacity(0.1), DarkFantasyTheme.bgPrimary.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .accessibilityHidden(true)

            if phase == .mining, let left = vm.timeLeft(index, now: now) {
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        MineIcon(name: "icon-hourglass", size: 24)
                        Text(GoldMineViewModel.clock(left))
                            .font(DarkFantasyTheme.title)
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .monospacedDigit()
                    }
                    if let run = vm.runLengthLabel {
                        Text("of \(run)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                }
                .padding(.horizontal, LayoutConstants.spaceMS)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .fill(DarkFantasyTheme.bgPrimary.opacity(0.8))
                )
                .padding(LayoutConstants.spaceMS)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(GoldMineViewModel.clock(left)) left")
            }

            MineRails(
                progress: phase == .idle ? 0 : (phase == .ready ? 1 : vm.progress(index, now: now)),
                cart: phase == .idle ? MineRails.emptyCart : MineRails.fullCart,
                cartWidth: 84,
                cartInset: LayoutConstants.spaceMS
            )
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 176)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(phase == .ready ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: What the cart brings

    @ViewBuilder
    private func haulRow(phase: GoldMineViewModel.TunnelPhase, slot: GoldMineSlotResponse) -> some View {
        if phase == .ready, let reward = slot.reward {
            infoRow(label: "In the cart") {
                MineIcon(name: "icon-gold", size: 20)
                Text("\(reward)")
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                if let gems = slot.gemReward, gems > 0 {
                    Text("·").foregroundStyle(DarkFantasyTheme.textTertiary)
                    MineIcon(name: "icon-gems", size: 20)
                    Text("\(gems)")
                        .foregroundStyle(DarkFantasyTheme.cyan)
                }
            }
        } else if let economy = vm.economy {
            let times = slot.isBoosted && phase != .idle ? (vm.boostMultiplier ?? 1) : 1
            infoRow(label: "This cart brings") {
                MineIcon(name: "icon-gold", size: 20)
                Text("\(economy.rewardMin * times)–\(economy.rewardMax * times)")
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Text("·").foregroundStyle(DarkFantasyTheme.textTertiary)
                MineIcon(name: "icon-gems", size: 20)
                Text("\(economy.gemMin * times)–\(economy.gemMax * times)")
                    .foregroundStyle(DarkFantasyTheme.cyan)
                Text("(\(Int((economy.gemChance * 100).rounded()))%)")
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
    }

    private func infoRow<Value: View>(label: String, @ViewBuilder value: () -> Value) -> some View {
        // One line when it fits, label above the numbers when it doesn't —
        // never shrink the 16 pt text.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: LayoutConstants.spaceXS) {
                Text(label)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Spacer(minLength: LayoutConstants.spaceSM)
                value()
            }
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text(label)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                HStack(spacing: LayoutConstants.spaceXS) {
                    value()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(DarkFantasyTheme.body)
        .lineLimit(1)
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceMS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgPrimary.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: Bonus run (optional)

    private func bonusRow(slot: GoldMineSlotResponse) -> some View {
        optionRow(
            icon: "icon-mine-bonus",
            title: "Bonus run",
            tag: "Optional",
            text: bonusText,
            accent: DarkFantasyTheme.gold
        ) {
            if slot.hasPlayedMinigame {
                doneLabel("Played", color: DarkFantasyTheme.success)
            } else {
                Button {
                    onPlayBonus()
                } label: {
                    Text("PLAY")
                }
                .buttonStyle(.compactPrimary)
                .disabled(vm.isStartingSlotMinigame)
                .accessibilityLabel("Play the bonus run")
            }
        }
    }

    private var bonusText: String {
        guard let economy = vm.economy, let cap = economy.bonusCapPercent else {
            return "Catch falling coins for extra gold on this cart."
        }
        let seconds = economy.bonusSeconds.map { " for \($0) s" } ?? ""
        var text = "Catch falling coins\(seconds): up to +\(cap)% gold"
        if let gemCap = economy.bonusGemCap, gemCap > 0, let share = economy.bonusGemCatchPercent {
            text += gemCap == 1
                ? ", and a gem if you catch \(share)% of them."
                : ", and up to \(gemCap) gems if you catch \(share)% of them."
        } else {
            text += "."
        }
        return text
    }

    // MARK: Double haul

    private func boostRow(slot: GoldMineSlotResponse) -> some View {
        optionRow(
            icon: "icon-mine-boost",
            title: "Double haul",
            tag: nil,
            text: boostText,
            accent: DarkFantasyTheme.cyan
        ) {
            if slot.isBoosted {
                doneLabel("Active", color: DarkFantasyTheme.cyan)
            } else {
                Button {
                    Task { await vm.boost(slotIndex: index) }
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text(vm.boostCost.map { "\($0)" } ?? "—")
                        MineIcon(name: "icon-gems", size: 18)
                    }
                }
                .buttonStyle(.compactOutline(color: DarkFantasyTheme.cyan))
                .disabled(vm.boostCost == nil || vm.isBusy(index))
                .accessibilityLabel(vm.boostCost.map { "Double the haul for \($0) gems" } ?? "Double the haul")
            }
        }
    }

    private var boostText: String {
        switch vm.boostMultiplier {
        case 2?: return "This cart comes back with twice the gold and gems."
        case let times?: return "This cart comes back with \(times)× the gold and gems."
        case nil: return "This cart comes back with more gold and gems."
        }
    }

    // MARK: Main action

    @ViewBuilder
    private func primaryAction(phase: GoldMineViewModel.TunnelPhase, slot: GoldMineSlotResponse) -> some View {
        switch phase {
        case .idle:
            Button {
                Task { await vm.startMining(slotIndex: index) }
            } label: {
                Text("SEND CART")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .disabled(vm.isBusy(index))
        case .ready:
            Button {
                Task { await vm.collect(slotIndex: index) }
            } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(slot.reward.map { "COLLECT +\($0)" } ?? "COLLECT")
                    MineIcon(name: "icon-gold", size: 20)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .disabled(vm.isBusy(index) || vm.isCollectingAll)
        case .mining:
            EmptyView()
        }
    }

    // MARK: History

    private func statsLine(_ stats: GoldMineSlotStatsResponse) -> some View {
        Text("From this tunnel so far: \(compact(stats.totalGoldMined)) gold in \(stats.sessionsCompleted) carts, best cart \(stats.bestHaul).")
            .font(DarkFantasyTheme.body)
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func compact(_ value: Int) -> String {
        value >= 1000 ? String(format: "%.1fK", Double(value) / 1000) : "\(value)"
    }

    // MARK: Building blocks

    private func optionRow<Trailing: View>(
        icon: String,
        title: String,
        tag: String?,
        text: String,
        accent: Color,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .center, spacing: LayoutConstants.spaceMS) {
            MineIcon(name: icon, size: 40)
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .fill(accent.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(title)
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    if let tag {
                        Text(tag)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                }
                Text(text)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            trailing()
        }
        .padding(LayoutConstants.spaceMS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgPrimary.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(accent.opacity(0.4), lineWidth: 1)
        )
    }

    private func doneLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(DarkFantasyTheme.buttonLabelCompact)
            .tracking(1)
            .foregroundStyle(color)
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.spaceXS)
            .overlay(Capsule().stroke(color.opacity(0.6), lineWidth: 1))
    }
}
