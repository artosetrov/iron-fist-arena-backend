import SwiftUI

struct FortuneWheelDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: FortuneWheelViewModel?

    // Wheel animation
    @State private var wheelRotation: Double = 0
    @State private var isAnimating = false
    /// Painted slot the last spin stopped on — outlined once the wheel rests.
    @State private var landedSlot: Int?

    // Result modal
    @State private var showResultModal = false
    @State private var resultScale: CGFloat = 0.5

    var body: some View {
        Group {
            if let vm, vm.showsErrorState {
                ErrorStateView.loadFailed(message: vm.errorMessage) {
                    Task { await vm.loadStatus() }
                }
            } else if let vm, !vm.isLoading {
                mainContent(vm)
                    .transaction { $0.animation = nil }
            } else {
                HexPulseLoader(.compact)
                    .tint(DarkFantasyTheme.gold)
            }
        }
        .background(backgroundLayer.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("FORTUNE WHEEL")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .onAppear {
            AmbientManager.shared.setZone(.tavern)
        }
        .onDisappear {
            vm?.applyPending()
            AmbientManager.shared.setZone(.hub)
        }
        .task {
            if vm == nil {
                let newVM = FortuneWheelViewModel(appState: appState)
                vm = newVM
                await newVM.loadStatus()
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary

            Image("bg-fortune-wheel")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(DarkFantasyTheme.opacityHeavy)

            LinearGradient(
                colors: [
                    DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityMedium),
                    Color.clear,
                    DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityDense)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(_ vm: FortuneWheelViewModel) -> some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Scrollable content: payouts + divider + wheel
                ScrollView(showsIndicators: false) {
                    VStack(spacing: LayoutConstants.spaceSM) {
                        // Treasury jackpot + the way to Fortune's Table
                        fortuneHeader(vm)

                        // Payouts — ABOVE wheel (per Figma)
                        payoutSection(vm)

                        // Gold divider between payouts and wheel (per Figma)
                        GoldDivider()
                            .padding(.horizontal, LayoutConstants.screenPadding)

                        // The Wheel
                        wheelSection(vm)

                        // Spacer for NPC widget clearance (matches npcAvatarSize)
                        Spacer().frame(height: LayoutConstants.npcAvatarSize)
                    }
                }
            }

            // NPC Widget — fixed at bottom
            npcWidget(vm)

            // Result Modal overlay
            if showResultModal, let result = vm.result {
                resultModal(vm, result: result)
            }
        }
    }

    // MARK: - Treasury + Fortune's Table entry

    private func fortuneHeader(_ vm: FortuneWheelViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Hidden until the server reports a Treasury (older backends don't).
            if vm.treasury != nil {
                treasuryPanel(vm)
            }
            tableEntry(wide: vm.treasury == nil)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceXS)
    }

    /// Fortuna's Treasury — every bet feeds it, the x5 sector pays it out.
    private func treasuryPanel(_ vm: FortuneWheelViewModel) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
            Text("FORTUNA'S TREASURY")
                .font(DarkFantasyTheme.body)
                .tracking(1)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("icon-gold")
                    .resizable()
                    .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                NumberTickUpText(
                    value: vm.treasury ?? 0,
                    color: DarkFantasyTheme.goldBright,
                    font: DarkFantasyTheme.section
                )
            }
            if let share = vm.treasuryShareForSelectedBet {
                Text("x5 adds \(share.formatted()) at this bet")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.info)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LayoutConstants.spaceMS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(DarkFantasyTheme.info.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
                )
        )
        .depthShadow(.card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fortuna's Treasury \(vm.treasury ?? 0) gold. Paid on the x5 sector.")
    }

    /// The table game: play against the tavern regulars for one shared pot.
    private func tableEntry(wide: Bool) -> some View {
        Button {
            HapticManager.light()
            SFXManager.shared.play(.uiTap)
            appState.mainPath.append(AppRoute.fortuneTable)
        } label: {
            VStack(spacing: LayoutConstants.space2XS) {
                Image(systemName: "person.3.fill")
                    .font(DarkFantasyTheme.iconMedium)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Text("FORTUNE'S TABLE")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text("Winner takes the pot")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: wide ? .infinity : 128, maxHeight: .infinity)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityMild))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                            .stroke(DarkFantasyTheme.gold, lineWidth: 1.5)
                    )
            )
            .depthShadow(.card)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Fortune's Table. Play against the regulars, winner takes the pot.")
    }

    // MARK: - Payout Section (above wheel — Figma: Speech Card Payout Pill)

    private func payoutSection(_ vm: FortuneWheelViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            payoutPill(asset: "reward-gold", label: "x1.5", count: 3, color: DarkFantasyTheme.goldBright)
            payoutPill(asset: "reward-loot", label: "x2", count: 1, color: DarkFantasyTheme.goldBright)
            payoutPill(asset: "reward-level-up", label: "x3", count: 1, color: DarkFantasyTheme.purple)
            payoutPill(asset: "neck_emerald", label: "x5", count: 1, color: DarkFantasyTheme.info)
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(DarkFantasyTheme.borderMedium.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
                )
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    /// Figma: PayoutPill — flat color tint bg + color border, Inter fonts
    private func payoutPill(asset: String, label: String, count: Int, color: Color) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Image(asset)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)

            Text(label)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(color)

            Text("\(count) sector\(count > 1 ? "s" : "")")
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, LayoutConstants.spaceXS)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(color.opacity(DarkFantasyTheme.opacitySoft))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(color.opacity(DarkFantasyTheme.opacityMild), lineWidth: 1)
        )
    }

    // MARK: - Wheel Section

    private func wheelSection(_ vm: FortuneWheelViewModel) -> some View {
        GeometryReader { geo in
            // Figma: fortune-wheel-face size-[401px] on 393px screen (left: -5px, full-bleed)
            let wheelSize = geo.size.width + 30 // Bigger wheel, centered
            let glowSize = wheelSize + 40

            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityMild),
                                DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityMicro),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: wheelSize * 0.2,
                            endRadius: glowSize / 2
                        )
                    )
                    .frame(width: glowSize, height: glowSize)

                // Wheel with sectors + asset icons
                FortuneWheelView(
                    sectors: vm.sectors,
                    rotation: wheelRotation,
                    highlightedSlot: isAnimating ? nil : landedSlot
                )
                .frame(width: wheelSize, height: wheelSize)

                // Center ornament
                wheelCenter(vm)

                // Pointer (top) — asset-based dagger
                VStack {
                    Image("fortune-pointer")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 96, height: 120)
                        .rotationEffect(.degrees(-15))
                        .shadow(color: DarkFantasyTheme.gold, radius: 10)
                        .offset(y: -2)
                    Spacer()
                }
                .frame(height: wheelSize)
            }
            .position(x: geo.size.width / 2, y: (wheelSize + 20) / 2)
        }
        .aspectRatio(0.95, contentMode: .fit)
    }

    // MARK: - Wheel Center

    private func wheelCenter(_ vm: FortuneWheelViewModel) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DarkFantasyTheme.bgSecondary, DarkFantasyTheme.bgAbyss],
                        center: .center,
                        startRadius: 5,
                        endRadius: 26
                    )
                )
                .frame(width: 52, height: 52)
            Circle()
                .stroke(DarkFantasyTheme.gold, lineWidth: 2.5)
                .frame(width: 52, height: 52)
            Circle()
                .stroke(DarkFantasyTheme.goldBright.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
                .frame(width: 44, height: 44)

            // Show result multiplier or default icon
            if let result = vm.result, !isAnimating {
                Image(vm.sectors[result.sectorIndex].sectorAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(
                        width: result.won ? LayoutConstants.iconXL : LayoutConstants.iconLG,
                        height: result.won ? LayoutConstants.iconXL : LayoutConstants.iconLG
                    )
                    .opacity(resultScale < 1 ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: resultScale)
            } else {
                Image("icon-gems")
                    .resizable()
                    .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
            }
        }
    }

    // MARK: - NPC Widget (fixed bottom) — uses NPCGuideWidget State=Wheel

    private func npcWidget(_ vm: FortuneWheelViewModel) -> some View {
        NPCGuideWidget(
            npcTitle: "LADY FORTUNA",
            onDismiss: { /* no dismiss on fortune wheel */ },
            npcImageName: NPCSpeaker.fortuna.portrait,
            plainMessage: vm.npcSpeech,
            wheelContent: AnyView(wheelWagerSection(vm)),
            overlapCardPx: 8
        )
    }

    // MARK: - Wager Section (inside NPC Widget wheelContent)

    /// Figma: State=Wheel → Wager Section
    /// Spins badge + bet buttons + SPIN CTA
    @ViewBuilder
    private func wheelWagerSection(_ vm: FortuneWheelViewModel) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            // Spins row — Figma: Spins Badge + Currency Display
            HStack {
                // Spins badge — Figma: capsule, bgTertiary fill, borderSubtle stroke, Inter Bold 11
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                    Text("\(vm.spinsRemaining)/\(vm.spinsLimit)")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                }
                .foregroundStyle(vm.spinsRemaining > 0 ? DarkFantasyTheme.gold : DarkFantasyTheme.danger)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    Capsule()
                        .fill(DarkFantasyTheme.bgTertiary)
                        .overlay(
                            Capsule()
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )
                )

                Spacer()

                // Currency Display — Figma: Gold + Gems (Standard size)
                CurrencyDisplay(
                    gold: vm.gold,
                    gems: appState.currentCharacter?.gems ?? 0,
                    size: .standard,
                    animated: true
                )
            }

            // Bet buttons — Figma: 5× Wager Button (Oswald 18, letterSpacing 2)
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(FortuneWheelViewModel.bets, id: \.self) { bet in
                    let isSelected = vm.selectedBet == bet
                    let canAfford = vm.gold >= bet

                    Button {
                        guard !vm.isSpinning else { return }
                        HapticManager.light()
                        SFXManager.shared.play(.uiTap)
                        vm.selectedBet = bet
                    } label: {
                        Text("\(bet)")
                            .font(DarkFantasyTheme.cardTitle)
                            .tracking(2)
                            .foregroundStyle(
                                isSelected
                                    ? DarkFantasyTheme.textOnGold
                                    : canAfford
                                        ? DarkFantasyTheme.textPrimary
                                        : DarkFantasyTheme.textTertiary
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                    .fill(
                                        isSelected
                                            ? DarkFantasyTheme.goldGradient
                                            : LinearGradient(colors: [DarkFantasyTheme.bgTertiary], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                    .stroke(
                                        isSelected
                                            ? DarkFantasyTheme.goldBright.opacity(DarkFantasyTheme.opacityHeavy)
                                            : DarkFantasyTheme.borderSubtle,
                                        lineWidth: isSelected ? 1.5 : 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isSpinning || !canAfford)
                    .opacity(canAfford ? 1 : DarkFantasyTheme.opacityStrong)
                }
            }

            // Odds disclosure — App Store 3.1.1. Server-published, never hardcoded.
            if !vm.odds.isEmpty {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Odds")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    ForEach(vm.odds) { odd in
                        Text("\(odd.displayLabel) \(odd.displayPercent)")
                            .foregroundStyle(odd.multiplier == 0 ? DarkFantasyTheme.textTertiary : DarkFantasyTheme.textSecondary)
                    }
                }
                .font(DarkFantasyTheme.body)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Odds: " + vm.odds.map { "\($0.displayLabel) \($0.displayPercent)" }.joined(separator: ", "))
            }

            // Gold Divider before SPIN button (per Figma State=Wheel)
            GoldDivider()

            // SPIN CTA — Figma: Button/Primary instance, Oswald 18, textOnGold, borderOrnament stroke
            Button {
                guard vm.canSpin else { return }
                HapticManager.heavy()
                SFXManager.shared.play(.uiConfirm)
                Task {
                    await performSpin(vm)
                }
            } label: {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "hurricane")
                        .font(DarkFantasyTheme.cardTitle.bold())
                    Text(vm.isSpinning ? "SPINNING..." : "SPIN — \(vm.selectedBet) GOLD")
                }
                .font(DarkFantasyTheme.cardTitle)
                .tracking(1)
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.buttonHeightMD)
            }
            .buttonStyle(.primary)
            .disabled(!vm.canSpin)
        }
    }

    // MARK: - Result Modal

    @ViewBuilder
    private func resultModal(_ vm: FortuneWheelViewModel, result: FortuneWheelViewModel.SpinResult) -> some View {
        // A full-screen fortune card with its own backdrop (no GameModal);
        // its metal follows the sector: ×1.5 bronze … ×5 or the Treasury mythic.
        MinigameResultModal(
            isWin: result.won,
            title: resultTitle(result),
            amountText: resultAmountText(vm, result: result),
            amountLineLimit: 2,
            winnings: result.won ? result.winAmount : 0,
            tier: !result.won ? nil
                : result.jackpotShare > 0 || result.multiplier >= 5 ? .mythic
                : result.multiplier >= 3 ? .gold
                : result.multiplier >= 2 ? .silver : .bronze,
            onContinue: { dismissModal(vm) }
        ) {
            Image(vm.sectors[result.sectorIndex].sectorAsset)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .opacity(showResultModal ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showResultModal)
    }

    private func resultTitle(_ result: FortuneWheelViewModel.SpinResult) -> String {
        if !result.won { return "LOST" }
        if result.multiplier >= 5 { return "JACKPOT!" }
        if result.multiplier >= 3 { return "BIG WIN!" }
        return "YOU WON!"
    }

    private func resultAmountText(_ vm: FortuneWheelViewModel, result: FortuneWheelViewModel.SpinResult) -> String {
        if result.won, result.jackpotShare > 0 {
            return "+\(result.winAmount.formatted()) Gold\nincl. \(result.jackpotShare.formatted()) from the Treasury"
        } else if result.won {
            return "+\(result.winAmount.formatted()) Gold (\(vm.sectors[result.sectorIndex].label))"
        } else {
            return "-\(vm.selectedBet.formatted()) Gold"
        }
    }

    private func dismissModal(_ vm: FortuneWheelViewModel) {
        showResultModal = false
        vm.reset()
    }

    // MARK: - Spin Animation

    private func performSpin(_ vm: FortuneWheelViewModel) async {
        guard let spinResult = await vm.spin() else { return }

        // Land on the painted slot that shows the server's sector, from
        // wherever the wheel rested after the last spin. (The old maths
        // assumed every spin started at 0°, so from the second spin on the
        // pointer stopped on a different slot than the one that paid.)
        let slot = FortuneWheelLayout.slot(forSector: spinResult.sectorIndex, in: vm.sectors)
        let slotAngle = FortuneWheelLayout.slotAngle
        let jitter = Double.random(in: -0.3...0.3) * slotAngle
        let target = 360.0 - (Double(slot) * slotAngle + slotAngle / 2.0) + jitter
        let current = wheelRotation.truncatingRemainder(dividingBy: 360.0)
        var delta = (target - current).truncatingRemainder(dividingBy: 360.0)
        if delta < 0 { delta += 360.0 }
        let fullSpins = Double(Int.random(in: 5...8)) * 360.0

        isAnimating = true
        showResultModal = false
        resultScale = 0.5
        landedSlot = slot

        wheelRotation += fullSpins + delta

        // Wait for animation to complete
        try? await Task.sleep(for: .seconds(4.2))

        // Show result in center
        isAnimating = false
        resultScale = 1.0

        vm.onAnimationComplete()

        // Small delay then show modal
        try? await Task.sleep(for: .seconds(0.5))
        showResultModal = true
    }
}

// MARK: - Fortune Wheel Layout

/// The painted face (`fortune-wheel-face`) already carries the sector art —
/// 12 slots clockwise from 12 o'clock: rune ×5, coins, crown ×3, skull,
/// coins, skull, skull, coins, skull, coins, skull, skull. The server's
/// sector table alternates differently, so each server sector is shown on
/// a slot painted for its multiplier (the n-th sector of a multiplier on the
/// n-th slot painted for it). Odds are the server's; this is display only.
enum FortuneWheelLayout {
    static let slots: [Double] = [5, 2, 3, 0, 1.5, 0, 0, 1.5, 0, 1.5, 0, 0]
    static var slotAngle: Double { 360.0 / Double(slots.count) }

    static func slot(forSector index: Int, in sectors: [WheelSector]) -> Int {
        guard sectors.indices.contains(index) else { return max(index, 0) % slots.count }
        let multiplier = sectors[index].multiplier
        let occurrence = sectors[..<index].filter { $0.multiplier == multiplier }.count
        let painted = slots.indices.filter { slots[$0] == multiplier }
        return painted.indices.contains(occurrence) ? painted[occurrence] : index % slots.count
    }

    static func label(for multiplier: Double) -> String {
        multiplier == 1.5 ? "x1.5" : "x\(Int(multiplier))"
    }

    static func color(for multiplier: Double) -> Color {
        switch multiplier {
        case 1.5: return DarkFantasyTheme.gold
        case 2: return DarkFantasyTheme.goldBright
        case 3: return DarkFantasyTheme.purple
        default: return DarkFantasyTheme.info
        }
    }
}

// MARK: - Fortune Wheel View

/// The painted wheel with code-drawn multiplier labels on the paying slots
/// and, once it rests, an outline on the slot that won or lost.
struct FortuneWheelView: View {
    let sectors: [WheelSector]
    let rotation: Double
    var highlightedSlot: Int?

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2

            ZStack {
                Image("fortune-wheel-face")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())

                if let highlightedSlot {
                    let wedge = WheelWedge(slot: highlightedSlot, count: FortuneWheelLayout.slots.count)
                    wedge.fill(DarkFantasyTheme.goldBright.opacity(DarkFantasyTheme.opacityMild))
                    wedge.stroke(DarkFantasyTheme.goldBright, lineWidth: 3)
                }

                ForEach(FortuneWheelLayout.slots.indices, id: \.self) { slot in
                    let multiplier = FortuneWheelLayout.slots[slot]
                    if multiplier > 0 {
                        Text(FortuneWheelLayout.label(for: multiplier))
                            .font(DarkFantasyTheme.cardTitle)
                            .foregroundStyle(FortuneWheelLayout.color(for: multiplier))
                            .padding(.horizontal, LayoutConstants.spaceXS)
                            .background(Capsule().fill(DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityHeavy)))
                            // Out by the rim, then turned to the slot's middle
                            // (offset first, so the turn swings it round the hub).
                            .offset(y: -radius * 0.78)
                            .rotationEffect(.degrees(Double(slot) * FortuneWheelLayout.slotAngle
                                                     + FortuneWheelLayout.slotAngle / 2))
                    }
                }
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .animation(.timingCurve(0.2, 0.8, 0.2, 1.0, duration: 4.0), value: rotation)
        }
        .aspectRatio(1, contentMode: .fit)
        .drawingGroup()
    }
}

/// One slot of the wheel, inside the iron rim.
private struct WheelWedge: Shape {
    let slot: Int
    let count: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.86
        let span = 360.0 / Double(max(count, 1))
        let start = Double(slot) * span - 90
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(start), endAngle: .degrees(start + span), clockwise: false)
        path.closeSubpath()
        return path
    }
}

// MARK: - Static Preview (no network, no AppState dependency)

#if DEBUG
#Preview("Fortune Wheel — Layout") {
    // Static wheel + NPC widget preview for layout tuning
    ZStack(alignment: .bottom) {
        // Background
        ZStack {
            DarkFantasyTheme.bgPrimary
            Image("bg-fortune-wheel")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(DarkFantasyTheme.opacityHeavy)
        }
        .ignoresSafeArea()

        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: LayoutConstants.spaceSM) {
                    // Payout pills
                    HStack(spacing: LayoutConstants.spaceSM) {
                        ForEach(["reward-gold", "reward-loot", "reward-level-up", "neck_emerald"], id: \.self) { asset in
                            VStack(spacing: LayoutConstants.spaceXS) {
                                Image(asset)
                                    .resizable()
                                    .interpolation(.high)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
                                Text("x1.5")
                                    .font(DarkFantasyTheme.body)
                                    .foregroundStyle(DarkFantasyTheme.goldBright)
                                Text("3 sectors")
                                    .font(DarkFantasyTheme.body.weight(.semibold))
                                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, LayoutConstants.spaceSM)
                            .background(
                                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                                    .fill(DarkFantasyTheme.goldBright.opacity(DarkFantasyTheme.opacitySoft))
                            )
                        }
                    }
                    .padding(LayoutConstants.spaceSM)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                            .fill(DarkFantasyTheme.bgSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                                    .stroke(DarkFantasyTheme.borderMedium.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.top, LayoutConstants.spaceXS)

                    // Gold divider
                    GoldDivider()
                        .padding(.horizontal, LayoutConstants.screenPadding)

                    // Wheel (static — Figma: 401px full-bleed)
                    GeometryReader { geo in
                        let wheelSize = geo.size.width + 30
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityMild),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: wheelSize * 0.2,
                                        endRadius: wheelSize / 2 + 20
                                    )
                                )
                                .frame(width: wheelSize + 40, height: wheelSize + 40)

                            FortuneWheelView(
                                sectors: FortuneWheelViewModel.previewSectors,
                                rotation: 0
                            )
                            .frame(width: wheelSize, height: wheelSize)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .aspectRatio(0.95, contentMode: .fit)

                    Spacer().frame(height: LayoutConstants.npcAvatarSize)
                }
            }
        }

        // NPC Widget (static)
        NPCGuideWidget(
            npcTitle: "LADY FORTUNA",
            onDismiss: {},
            npcImageName: NPCSpeaker.fortuna.portrait,
            plainMessage: nil,
            wheelContent: AnyView(
                VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                    // Spins row
                    HStack {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                                .font(DarkFantasyTheme.body.weight(.semibold))
                            Text("8/10")
                                .font(DarkFantasyTheme.body.weight(.semibold))
                        }
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .padding(.horizontal, LayoutConstants.spaceSM)
                        .padding(.vertical, LayoutConstants.spaceXS)
                        .background(
                            Capsule()
                                .fill(DarkFantasyTheme.bgTertiary)
                                .overlay(Capsule().stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
                        )
                        Spacer()
                        CurrencyDisplay(gold: 12450, gems: 385, size: .standard, animated: false)
                    }

                    // Bet buttons
                    HStack(spacing: LayoutConstants.spaceSM) {
                        ForEach([50, 100, 200, 500, 1000], id: \.self) { bet in
                            Text("\(bet)")
                                .font(DarkFantasyTheme.cardTitle)
                                .tracking(2)
                                .foregroundStyle(bet == 100 ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(
                                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                        .fill(bet == 100 ? DarkFantasyTheme.goldGradient : LinearGradient(colors: [DarkFantasyTheme.bgTertiary], startPoint: .top, endPoint: .bottom))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                        .stroke(bet == 100 ? DarkFantasyTheme.goldBright.opacity(DarkFantasyTheme.opacityHeavy) : DarkFantasyTheme.borderSubtle, lineWidth: bet == 100 ? 1.5 : 1)
                                )
                        }
                    }

                    GoldDivider()

                    // SPIN CTA
                    Button {} label: {
                        HStack(spacing: LayoutConstants.spaceSM) {
                            Image(systemName: "hurricane")
                                .font(DarkFantasyTheme.cardTitle.bold())
                            Text("SPIN — 100 GOLD")
                        }
                        .font(DarkFantasyTheme.cardTitle)
                        .tracking(1)
                        .frame(maxWidth: .infinity)
                        .frame(height: LayoutConstants.buttonHeightMD)
                    }
                    .buttonStyle(.primary)
                }
            ),
            overlapCardPx: 8
        )
    }
    .preferredColorScheme(.dark)
}
#endif
