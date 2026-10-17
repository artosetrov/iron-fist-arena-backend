import SwiftUI

// Gold Mine — the shaft (2026-10-16 rework, hybrid "tunnels + cross-section").
//
// Each mine slot is a tunnel level down a ladder. Its state reads from the
// art, not from labels: an empty cart parked at the start of the rails =
// send one, a full cart riding them = on its way up, a full cart at the end
// = collect. Tap a tunnel for the optional bonus run and the double haul
// (`MineTunnelSheet`).
//
// Art pass 2 (2026-10-17): side-view carts standing on a tiled iron track
// (`mine-rail-tile`), a tiled timber ladder (`mine-ladder-tile`) and round
// level plates (`mine-level-plate`) — all assets; only the plate's number
// is code (text never goes into a PNG).

// MARK: - Tunnel level

struct MineTunnelLevel: View {
    let index: Int
    @Bindable var vm: GoldMineViewModel
    let onOpen: () -> Void

    static let height: CGFloat = 180

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
                ZStack(alignment: .leading) {
                    switch phase {
                    case .idle: idleBody
                    case .mining: miningBody
                    case .ready: readyBody
                    }
                }
                .id(phase)
                .transition(.opacity)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.top, LayoutConstants.spaceMS)
            .animation(MotionConstants.smooth, value: phase)

            // The track runs the full width of the tunnel floor; the cart
            // stands on it. Its position follows the clock (never slides),
            // and only the empty ↔ full swap cross-fades.
            MineRails(
                progress: railProgress(phase: phase, now: now),
                cart: phase == .idle ? MineRails.emptyCart : MineRails.fullCart
            )
            .id(phase)
            .transition(.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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

    private func railProgress(phase: GoldMineViewModel.TunnelPhase, now: Date) -> Double {
        switch phase {
        case .idle: return 0
        case .mining: return vm.progress(index, now: now)
        case .ready: return 1
        }
    }

    // MARK: Idle — empty cart parked at the start, send it down

    private var idleBody: some View {
        HStack(alignment: .center, spacing: LayoutConstants.spaceSM) {
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

    // MARK: Mining — the cart rides up the rails (drawn below)

    private var miningBody: some View {
        let slot = vm.slot(index)
        return HStack(spacing: LayoutConstants.spaceSM) {
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
    }

    // MARK: Ready — full cart at the end of the rails, collect it

    private var readyBody: some View {
        let slot = vm.slot(index)
        return HStack(alignment: .center, spacing: LayoutConstants.spaceSM) {
            HStack(spacing: LayoutConstants.spaceXS) {
                if let reward = slot.reward {
                    MineIcon(name: "icon-gold", size: 24)
                    Text("\(reward)")
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .monospacedDigit()
                } else {
                    Text("Full!")
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
                if let gems = slot.gemReward, gems > 0 {
                    Text("+\(gems)")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.cyan)
                        .padding(.leading, LayoutConstants.spaceXS)
                    MineIcon(name: "icon-gems", size: 20)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(readyAmountLabel(slot))
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

    private func readyAmountLabel(_ slot: GoldMineSlotResponse) -> String {
        var text = slot.reward.map { "\($0) gold" } ?? "A full cart"
        if let gems = slot.gemReward, gems > 0 { text += " and \(gems) gems" }
        return text
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

/// Tiled iron track (`mine-rail-tile`) with the side-view cart standing on
/// it at `progress` (0 = start of the tunnel, 1 = arrived). The wheels rest
/// on the rail top; a thin gold line marks the stretch already travelled.
struct MineRails: View {
    let progress: Double
    let cart: String
    var cartWidth: CGFloat = 68
    /// Keeps the cart off the card's rounded corners at either end.
    var cartInset: CGFloat = LayoutConstants.spaceSM

    static let emptyCart = "mine-cart-side-empty"
    static let fullCart = "mine-cart-side-full"

    /// `mine-rail-tile` is 24 × 14 pt; its top row is the rail top.
    static let trackHeight: CGFloat = 14
    /// Height ÷ width of the taller cart (`mine-cart-side-full`, 360 × 325 px
    /// @3x: ore heaped over the rim). Both carts share the width, wheels at
    /// the bottom edge, so either one stands on the same line.
    private static let cartAspect: CGFloat = 325.0 / 360.0
    /// The wheels overlap the rail top by this much, so they rest on it.
    private static let wheelSink: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let p = CGFloat(min(max(progress, 0), 1))
            let travel = max(width - cartWidth - cartInset * 2, 0)
            VStack(alignment: .leading, spacing: -Self.wheelSink) {
                Image(cart)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: cartWidth)
                    .offset(x: cartInset + travel * p)
                    .zIndex(1)
                track(width: width, travelled: cartInset + travel * p + cartWidth / 2)
            }
            .frame(width: width, height: geo.size.height, alignment: .bottomLeading)
        }
        .frame(height: cartWidth * Self.cartAspect + Self.trackHeight - Self.wheelSink)
        // The cart's position follows the clock; never animate it (no sliding).
        .transaction { $0.animation = nil }
        .accessibilityHidden(true)
    }

    private func track(width: CGFloat, travelled: CGFloat) -> some View {
        Image("mine-rail-tile")
            .resizable(resizingMode: .tile)
            .frame(width: width, height: Self.trackHeight)
            .overlay(alignment: .topLeading) {
                Rectangle()
                    .fill(DarkFantasyTheme.gold.opacity(0.85))
                    .frame(width: max(travelled, 0), height: 2)
            }
    }
}

// MARK: - Pieces

/// Numbered plate on the shaft ladder (`mine-level-plate`, iron-rimmed
/// wood hanging from a ring); a padlock for the sealed tunnel. The number is
/// cut into the wood in code — text never goes into a PNG.
struct MineLevelBadge: View {
    let number: Int
    /// nil = sealed tunnel.
    let phase: GoldMineViewModel.TunnelPhase?

    static let width: CGFloat = 44
    /// The plate art is 136 × 144 px @3x.
    private static let height: CGFloat = width * 144 / 136
    /// The ring on top pushes the wooden disc's centre 2.8 % below the
    /// image's centre.
    private static let discOffset: CGFloat = height * 0.028

    var body: some View {
        ZStack {
            Image("mine-level-plate")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .opacity(phase == nil ? 0.7 : 1)
            Group {
                if phase == nil {
                    MineIcon(name: "icon-mine-lock", size: 20)
                } else {
                    Text("\(number)")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(digitColor)
                        .monospacedDigit()
                        // Engraved: a hard dark edge under the figure.
                        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 0, y: 1.5)
                }
            }
            .offset(y: Self.discOffset)
        }
        .frame(width: Self.width, height: Self.height)
        .accessibilityHidden(true)
    }

    private var digitColor: Color {
        switch phase {
        case .ready: return DarkFantasyTheme.goldBright
        case .mining: return DarkFantasyTheme.success
        default: return DarkFantasyTheme.textPrimary
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

/// Timber ladder running down behind the level plates, tiled from one rung
/// (`mine-ladder-tile`, 30 × 12 pt) so it is as long as the shaft.
struct MineShaftLadder: View {
    static let width: CGFloat = 30

    var body: some View {
        Image("mine-ladder-tile")
            .resizable(resizingMode: .tile)
            .frame(width: Self.width)
            .frame(maxHeight: .infinity)
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
            // A touch of the mine shows through.
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.9))
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
            Image(done ? MineRails.fullCart : MineRails.emptyCart)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 26, height: 24)
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
