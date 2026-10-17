import SwiftUI

// Gold Mine — the shaft (2026-10-16 rework, hybrid "tunnels + cross-section").
//
// Each mine slot is a tunnel level down a ladder. Its state reads from the
// art, not from labels: an empty cart parked = send one, a cart riding the
// rails = on its way up, a full cart at the end = collect. Tap a tunnel for
// the optional bonus run and the double haul (`MineTunnelSheet`).

// MARK: - Tunnel level

struct MineTunnelLevel: View {
    let index: Int
    @Bindable var vm: GoldMineViewModel
    let onOpen: () -> Void

    private static let height: CGFloat = 164

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let phase = vm.phase(index, now: now)
            HStack(spacing: LayoutConstants.spaceSM) {
                MineLevelBadge(number: index + 1, phase: phase)
                card(phase: phase, now: now)
            }
        }
    }

    private var name: String { GoldMineViewModel.mineName(for: index) }

    private func card(phase: GoldMineViewModel.TunnelPhase, now: Date) -> some View {
        ZStack(alignment: .topLeading) {
            MineTunnelArt(index: index, dimmed: phase == .idle)

            LinearGradient(
                colors: [
                    DarkFantasyTheme.bgPrimary.opacity(0.2),
                    DarkFantasyTheme.bgPrimary.opacity(0.55),
                    DarkFantasyTheme.bgPrimary.opacity(0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text(name)
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 0)
                    MineStatePill(phase: phase, timeLeft: vm.timeLeft(index, now: now))
                }

                // One view per phase, cross-faded (opacity only — nothing slides).
                ZStack(alignment: .bottomLeading) {
                    switch phase {
                    case .idle: idleBody
                    case .mining: miningBody(now: now)
                    case .ready: readyBody
                    }
                }
                .id(phase)
                .transition(.opacity)
            }
            .padding(LayoutConstants.spaceMS)
            .animation(MotionConstants.smooth, value: phase)

            if let haul = vm.recentHaul, haul.slotIndex == index {
                MineHaulPop(haul: haul, vm: vm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            }
        }
        .frame(height: Self.height)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    phase == .ready ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle,
                    lineWidth: phase == .ready ? 2 : 1
                )
        )
        .animation(MotionConstants.smooth, value: vm.recentHaul)
        .contentShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .onTapGesture {
            HapticManager.light()
            onOpen()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityText(phase: phase, now: now))
        .accessibilityAction(named: "Tunnel details", onOpen)
    }

    // MARK: Idle — empty cart parked, send it down

    private var idleBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: LayoutConstants.spaceSM) {
                Image("mine-cart-empty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 48)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    if let run = vm.runLengthLabel {
                        Text(run)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                    }
                    if let economy = vm.economy {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            MineIcon(name: "icon-gold", size: 18)
                            Text("\(economy.rewardMin)–\(economy.rewardMax)")
                                .font(DarkFantasyTheme.body)
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(economy.rewardMin) to \(economy.rewardMax) gold per cart")
                    }
                }
                Spacer(minLength: 0)
                Button {
                    Task { await vm.startMining(slotIndex: index) }
                } label: {
                    Text("SEND CART")
                }
                .buttonStyle(.compactOutline(color: DarkFantasyTheme.gold))
                .disabled(vm.isBusy(index))
            }
        }
    }

    // MARK: Mining — the cart rides up the rails

    private func miningBody(now: Date) -> some View {
        let slot = vm.slot(index)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: LayoutConstants.spaceSM) {
                MineChip(
                    icon: "icon-mine-bonus",
                    text: slot.hasPlayedMinigame ? "Bonus played" : "Bonus run",
                    color: slot.hasPlayedMinigame ? DarkFantasyTheme.success : DarkFantasyTheme.goldBright,
                    action: onOpen
                )
                MineChip(
                    icon: "icon-mine-boost",
                    text: boostChipText(boosted: slot.isBoosted),
                    price: slot.isBoosted ? nil : vm.boostCost,
                    color: DarkFantasyTheme.cyan,
                    action: onOpen
                )
            }
            Spacer(minLength: 0)
            MineRails(progress: vm.progress(index, now: now), cart: "mine-cart-full")
        }
    }

    // MARK: Ready — full cart at the top, collect it

    private var readyBody: some View {
        let slot = vm.slot(index)
        return VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: LayoutConstants.spaceSM) {
                Image("mine-cart-full")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 56)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    if let reward = slot.reward {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            MineIcon(name: "icon-gold", size: 24)
                            Text("\(reward)")
                                .font(DarkFantasyTheme.title)
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                                .monospacedDigit()
                        }
                    } else {
                        Text("Full!")
                            .font(DarkFantasyTheme.title)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                    if let gems = slot.gemReward, gems > 0 {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Text("+\(gems)")
                                .font(DarkFantasyTheme.body)
                                .foregroundStyle(DarkFantasyTheme.cyan)
                            MineIcon(name: "icon-gems", size: 18)
                            Text("found")
                                .font(DarkFantasyTheme.body)
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                        }
                    }
                }
                Spacer(minLength: 0)
                Button {
                    Task { await vm.collect(slotIndex: index) }
                } label: {
                    Text("COLLECT")
                }
                .buttonStyle(.compactPrimary)
                .disabled(vm.isBusy(index) || vm.isCollectingAll)
            }
        }
    }

    private func boostChipText(boosted: Bool) -> String {
        let times = vm.boostMultiplier.map { "×\($0)" } ?? "Double"
        return boosted ? "\(times) haul" : times
    }

    private func accessibilityText(phase: GoldMineViewModel.TunnelPhase, now: Date) -> String {
        let slot = vm.slot(index)
        switch phase {
        case .idle:
            return "\(name), empty. Send a cart down."
        case .mining:
            let left = vm.timeLeft(index, now: now).map { GoldMineViewModel.clock($0) } ?? ""
            return "\(name), cart on its way up, \(left) left."
        case .ready:
            let amount = slot.reward.map { "\($0) gold" } ?? "a full cart"
            return "\(name), ready: \(amount)."
        }
    }
}

// MARK: - Tunnel art

/// The slot's tunnel painting, cropped to fill; desaturated while empty.
struct MineTunnelArt: View {
    let index: Int
    var dimmed: Bool = false

    var body: some View {
        Color.clear
            .overlay(
                Image("mine-slot-\(min(index, 5) + 1)")
                    .resizable()
                    .scaledToFill()
            )
            .clipped()
            .saturation(dimmed ? 0.5 : 1)
            .opacity(dimmed ? 0.75 : 1)
            .accessibilityHidden(true)
    }
}

// MARK: - Rails + cart

/// Code-drawn track with the cart at `progress` (0 = bottom of the tunnel,
/// 1 = arrived). Gold marks the stretch already travelled.
struct MineRails: View {
    let progress: Double
    let cart: String
    var cartWidth: CGFloat = 52

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let p = CGFloat(min(max(progress, 0), 1))
            ZStack(alignment: .bottomLeading) {
                Canvas { context, size in
                    let top = size.height - 12
                    // Sleepers
                    var x: CGFloat = 3
                    while x < size.width {
                        context.fill(
                            Path(CGRect(x: x, y: top - 1, width: 4, height: 12)),
                            with: .color(DarkFantasyTheme.borderSubtle)
                        )
                        x += 14
                    }
                    // Rails, gold where the cart has been
                    for y in [top, top + 8] {
                        context.fill(
                            Path(CGRect(x: 0, y: y, width: size.width, height: 2)),
                            with: .color(DarkFantasyTheme.borderMedium)
                        )
                        context.fill(
                            Path(CGRect(x: 0, y: y, width: size.width * p, height: 2)),
                            with: .color(DarkFantasyTheme.gold)
                        )
                    }
                }
                Image(cart)
                    .resizable()
                    .scaledToFit()
                    .frame(width: cartWidth, height: cartWidth * 0.86)
                    .offset(x: (width - cartWidth) * p, y: -8)
            }
        }
        .frame(height: cartWidth * 0.86 + 8)
        // The cart's position follows the clock; never animate it (no sliding).
        .transaction { $0.animation = nil }
        .accessibilityHidden(true)
    }
}

// MARK: - Pieces

/// Numbered stop on the shaft ladder; a padlock for the sealed tunnel.
struct MineLevelBadge: View {
    let number: Int
    /// nil = sealed tunnel.
    let phase: GoldMineViewModel.TunnelPhase?

    var body: some View {
        ZStack {
            Circle().fill(fill)
            Circle().stroke(stroke, lineWidth: 2)
            if phase == nil {
                MineIcon(name: "icon-mine-lock", size: 18)
            } else {
                Text("\(number)")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(textColor)
            }
        }
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
    }

    private var fill: Color {
        phase == .ready ? DarkFantasyTheme.gold : DarkFantasyTheme.bgSecondary
    }

    private var stroke: Color {
        switch phase {
        case .ready: return DarkFantasyTheme.goldBright
        case .mining: return DarkFantasyTheme.success
        default: return DarkFantasyTheme.borderMedium
        }
    }

    private var textColor: Color {
        switch phase {
        case .ready: return DarkFantasyTheme.textOnGold
        case .mining: return DarkFantasyTheme.success
        default: return DarkFantasyTheme.textSecondary
        }
    }
}

/// EMPTY / hourglass + time left / READY.
struct MineStatePill: View {
    let phase: GoldMineViewModel.TunnelPhase
    let timeLeft: TimeInterval?

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            switch phase {
            case .idle:
                Text("EMPTY")
            case .mining:
                MineIcon(name: "icon-hourglass", size: 18)
                Text(timeLeft.map { GoldMineViewModel.clock($0) } ?? "")
                    .monospacedDigit()
            case .ready:
                Text("READY")
            }
        }
        .font(DarkFantasyTheme.buttonLabelCompact)
        .tracking(phase == .mining ? 0 : 1)
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(Capsule().fill(background))
        .overlay(Capsule().stroke(border, lineWidth: 1))
        .accessibilityHidden(true)
    }

    private var foreground: Color {
        switch phase {
        case .idle: return DarkFantasyTheme.textSecondary
        case .mining: return DarkFantasyTheme.textPrimary
        case .ready: return DarkFantasyTheme.textOnGold
        }
    }

    private var background: Color {
        phase == .ready ? DarkFantasyTheme.gold : DarkFantasyTheme.bgPrimary.opacity(0.72)
    }

    private var border: Color {
        switch phase {
        case .idle: return DarkFantasyTheme.borderMedium
        case .mining: return DarkFantasyTheme.success.opacity(0.7)
        case .ready: return DarkFantasyTheme.goldBright
        }
    }
}

/// Small tappable tag on a mining tunnel (bonus run, double haul).
struct MineChip: View {
    let icon: String
    let text: String
    var price: Int? = nil
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutConstants.spaceXS) {
                MineIcon(name: icon, size: 18)
                Text(price.map { "\(text) · \($0)" } ?? text)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(color)
                    .lineLimit(1)
                if price != nil {
                    MineIcon(name: "icon-gems", size: 16)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(Capsule().fill(DarkFantasyTheme.bgPrimary.opacity(0.72)))
            .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(price.map { "\(text) for \($0) gems" } ?? text)
    }
}

/// Asset icon at a fixed size (never an SF Symbol on this screen).
struct MineIcon: View {
    let name: String
    let size: CGFloat

    var body: some View {
        Image(name)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// "+86" over a tunnel right after its cart is collected; clears itself.
private struct MineHaulPop: View {
    let haul: GoldMineViewModel.RecentHaul
    let vm: GoldMineViewModel

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            if haul.gold > 0 {
                MineIcon(name: "icon-gold", size: 28)
                Text("+\(haul.gold)")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
            if haul.gems > 0 {
                MineIcon(name: "icon-gems", size: 24)
                Text("+\(haul.gems)")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.cyan)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(Capsule().fill(DarkFantasyTheme.bgPrimary.opacity(0.85)))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: haul.id) {
            try? await Task.sleep(for: .seconds(1.6))
            if vm.recentHaul?.id == haul.id { vm.recentHaul = nil }
        }
    }
}

// MARK: - Sealed tunnel

struct MineSealedLevel: View {
    let number: Int
    @Bindable var vm: GoldMineViewModel

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            MineLevelBadge(number: number, phase: nil)
            ZStack(alignment: .topLeading) {
                Color.clear
                    .overlay(Image("mine-slot-locked").resizable().scaledToFill())
                    .clipped()
                    .opacity(0.55)
                    .accessibilityHidden(true)
                DarkFantasyTheme.bgPrimary.opacity(0.45)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Sealed tunnel")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Spacer(minLength: 0)
                    HStack(alignment: .bottom, spacing: LayoutConstants.spaceSM) {
                        Text(vm.runLengthLabel.map { "One more cart\nevery \($0)" } ?? "One more cart\nat a time")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Button {
                            Task { await vm.buySlot() }
                        } label: {
                            HStack(spacing: LayoutConstants.spaceXS) {
                                Text(vm.slotCost.map { "OPEN · \($0)" } ?? "OPEN")
                                MineIcon(name: "icon-gems", size: 18)
                            }
                        }
                        .buttonStyle(.compactOutline(color: DarkFantasyTheme.cyan))
                        .disabled(vm.isBuyingSlot || vm.slotCost == nil)
                        .accessibilityLabel(vm.slotCost.map { "Open a new tunnel for \($0) gems" } ?? "Open a new tunnel")
                    }
                }
                .padding(LayoutConstants.spaceMS)
            }
            .frame(height: 132)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.borderMedium, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            )
        }
    }
}

// MARK: - Shaft ladder

/// Timber ladder running down behind the level badges.
struct MineShaftLadder: View {
    var body: some View {
        Canvas { context, size in
            let wood = DarkFantasyTheme.goldDim
            context.fill(Path(CGRect(x: 0, y: 0, width: 3, height: size.height)), with: .color(wood.opacity(0.55)))
            context.fill(Path(CGRect(x: size.width - 3, y: 0, width: 3, height: size.height)), with: .color(wood.opacity(0.55)))
            var y: CGFloat = 10
            while y < size.height {
                context.fill(Path(CGRect(x: 3, y: y, width: size.width - 6, height: 3)), with: .color(wood.opacity(0.32)))
                y += 22
            }
        }
        .frame(width: 24)
        .accessibilityHidden(true)
    }
}

// MARK: - Expedition track

/// Five cart stops and the chest: every collected cart fills one stop.
struct MineExpeditionTrack: View {
    let expedition: ActiveShaft
    let economy: GoldMineEconomy?

    private var progress: Int { min(expedition.progress, expedition.total) }
    private var remaining: Int { max(expedition.total - progress, 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceMS) {
            HStack(alignment: .firstTextBaseline) {
                Text("EXPEDITION")
                    .font(DarkFantasyTheme.cardTitle)
                    .tracking(1.5)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Spacer()
                Text("\(progress) of \(expedition.total) carts")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .monospacedDigit()
            }

            HStack(spacing: 0) {
                ForEach(0..<expedition.total, id: \.self) { stop in
                    node(stop)
                    Rectangle()
                        .fill(stop < progress ? DarkFantasyTheme.gold : DarkFantasyTheme.borderMedium)
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                }
                Image(remaining == 0 ? "mine-chest-open" : "mine-chest-closed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 44)
            }

            if let economy {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(remaining == 1 ? "One more cart opens it:" : "The chest holds")
                    MineIcon(name: "icon-gold", size: 18)
                    Text("\(economy.chestGold)")
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    MineIcon(name: "icon-gems", size: 18)
                    Text("\(economy.chestGems)")
                        .foregroundStyle(DarkFantasyTheme.cyan)
                }
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
        )
        .animation(MotionConstants.smooth, value: expedition)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func node(_ stop: Int) -> some View {
        let done = stop < progress
        let next = stop == progress
        return ZStack {
            Circle()
                .fill(done ? DarkFantasyTheme.gold.opacity(0.18) : DarkFantasyTheme.bgPrimary)
            Circle()
                .stroke(
                    done ? DarkFantasyTheme.gold : (next ? DarkFantasyTheme.goldDim : DarkFantasyTheme.borderMedium),
                    lineWidth: 2
                )
            Image(done ? "mine-cart-full" : "mine-cart-empty")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 22)
                .opacity(done ? 1 : (next ? 0.55 : 0.25))
        }
        .frame(width: 34, height: 34)
    }

    private var accessibilityText: String {
        var text = "Expedition: \(progress) of \(expedition.total) carts hauled."
        if let economy {
            text += " The chest holds \(economy.chestGold) gold and \(economy.chestGems) gems."
        }
        return text
    }
}
