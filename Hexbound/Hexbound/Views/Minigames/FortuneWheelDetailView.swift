import SwiftUI

struct FortuneWheelDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: FortuneWheelViewModel?

    // Wheel animation
    @State private var wheelRotation: Double = 0
    @State private var isAnimating = false
    /// Painted slot the last spin stopped on — outlined once the wheel rests.
    @State private var landedSlot: Int?

    /// The last spin's outcome, said on the stage until the next spin
    /// (variant A, 2026-11-04 — no modal for every spin).
    @State private var stageResult: FortuneWheelViewModel.SpinResult?
    /// Stake of the spin `stageResult` belongs to (the bet may change after).
    @State private var lastStake = 0
    /// Big wins — ×3, ×5, a Treasury share — still get the reward card.
    @State private var showResultModal = false
    @State private var showOdds = false

    /// `tavern-npc-fortuna` is 521 × 790; the straight `fortune-pointer` 57 × 156.
    private static let fortunaAspect: CGFloat = 521.0 / 790.0
    private static let pointerAspect: CGFloat = 57.0 / 156.0

    var body: some View {
        Group {
            if let vm, vm.showsErrorState {
                ErrorStateView.loadFailed(message: vm.errorMessage) {
                    Task { await vm.loadStatus() }
                }
            } else if let vm, !vm.isLoading {
                mainContent(vm)
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
            ToolbarItem(placement: .navigationBarTrailing) {
                MinigameGoldPill(gold: vm?.gold ?? appState.currentCharacter?.gold ?? 0)
            }
        }
        .sheet(isPresented: $showOdds) {
            oddsSheet
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

    // MARK: - Main Content (stage + dock, no scroll)

    @ViewBuilder
    private func mainContent(_ vm: FortuneWheelViewModel) -> some View {
        ZStack {
            VStack(spacing: 0) {
                stage(vm)

                MinigameBetDock(
                    bets: FortuneWheelViewModel.bets,
                    selectedBet: Binding(get: { vm.selectedBet }, set: { vm.selectedBet = $0 }),
                    gold: vm.gold,
                    isLocked: vm.isSpinning,
                    ctaTitle: vm.isSpinning ? "SPINNING…" : (stageResult == nil ? "SPIN" : "SPIN AGAIN"),
                    ctaEnabled: vm.canSpin,
                    remainingText: "\(vm.spinsRemaining) of \(vm.spinsLimit) spins left",
                    remainingIsEmpty: vm.spinsRemaining == 0,
                    infoTitle: "Odds",
                    onInfo: { showOdds = true },
                    onCTA: { spinTapped(vm) }
                )
            }

            if showResultModal, let result = vm.result {
                resultModal(vm, result: result)
            }
        }
    }

    // MARK: - Stage

    /// Fortuna stands behind her wheel, her line by her head, the dagger
    /// straight down into the top slot, Fortune's Table and the Treasury
    /// under the wheel — or, after a spin, what it paid.
    private func stage(_ vm: FortuneWheelViewModel) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let rowHeight: CGFloat = 56
            let gap = LayoutConstants.spaceMD
            let wheel = max(200, min(w - 40, h - rowHeight - gap * 2 - h * 0.16))
            let wheelTop = h - rowHeight - gap * 2 - wheel
            let fortunaH = wheel * 0.88
            let fortunaW = fortunaH * Self.fortunaAspect
            let fortunaTop = max(0, wheelTop - fortunaH * 0.36)
            let pointerH = wheel * 0.34
            let pointerW = pointerH * Self.pointerAspect
            let tipY = wheelTop + wheel * 0.15

            ZStack(alignment: .topLeading) {
                Image("tavern-npc-fortuna")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: fortunaW, height: fortunaH)
                    .position(x: w + LayoutConstants.spaceMS - fortunaW / 2, y: fortunaTop + fortunaH / 2)
                    .accessibilityHidden(true)

                FortuneWheelView(
                    sectors: vm.sectors,
                    rotation: wheelRotation,
                    highlightedSlot: isAnimating ? nil : landedSlot
                )
                .frame(width: wheel, height: wheel)
                .depthShadow(.modal)
                .position(x: w / 2, y: wheelTop + wheel / 2)
                .accessibilityLabel("Fortune wheel")

                // The dagger points straight down into the top slot.
                Image("fortune-pointer")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: pointerW, height: pointerH)
                    .depthShadow(.elevated)
                    .position(x: w / 2, y: tipY - pointerH / 2)
                    .accessibilityHidden(true)

                // Over the dagger, never under it.
                MinigameSpeechBubble(text: vm.npcSpeech)
                    .frame(width: min(w * 0.56, 240), alignment: .leading)
                    .padding(.leading, LayoutConstants.screenPadding)
                    .padding(.top, max(LayoutConstants.spaceSM, fortunaTop + LayoutConstants.spaceMD))
                    .zIndex(3)

                bottomRow(vm)
                    .frame(width: w, height: rowHeight)
                    .position(x: w / 2, y: h - gap - rowHeight / 2)
            }
            .frame(width: w, height: h)
        }
    }

    @ViewBuilder
    private func bottomRow(_ vm: FortuneWheelViewModel) -> some View {
        if let result = stageResult, !isAnimating {
            MinigameResultPlaque(
                isWin: result.won,
                badge: result.multiplier == 1.5 ? "×1.5" : "×\(Int(result.multiplier))",
                amount: result.won ? result.winAmount : lastStake,
                caption: result.won
                    ? (result.jackpotShare > 0
                        ? "incl. \(result.jackpotShare.formatted()) from the Treasury"
                        : "gold, straight to your purse")
                    : "the wheel keeps your stake"
            )
        } else {
            HStack(spacing: LayoutConstants.spaceSM) {
                tablePill
                if let treasury = vm.treasury {
                    treasuryPill(vm, treasury: treasury)
                }
            }
            .transition(.opacity)
        }
    }

    /// The table game: play against the regulars for one shared pot.
    private var tablePill: some View {
        Button {
            HapticManager.light()
            SFXManager.shared.play(.uiTap)
            appState.mainPath.append(AppRoute.fortuneTable)
        } label: {
            MinigameStagePill {
                Image(systemName: "person.3.fill")
                    .font(DarkFantasyTheme.body)
                Text("FORTUNE'S TABLE")
                    .font(DarkFantasyTheme.cardTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "chevron.right")
                    .font(DarkFantasyTheme.body.weight(.semibold))
            }
            .foregroundStyle(DarkFantasyTheme.goldBright)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Fortune's Table. Play against the regulars, winner takes the pot.")
    }

    /// Fortuna's Treasury — every bet feeds it, the ×5 slot pays a share of it.
    private func treasuryPill(_ vm: FortuneWheelViewModel, treasury: Int) -> some View {
        MinigameStagePill(accent: DarkFantasyTheme.info) {
            Image("icon-gold")
                .resizable()
                .interpolation(.high)
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
            VStack(alignment: .leading, spacing: 0) {
                NumberTickUpText(value: treasury, color: DarkFantasyTheme.goldBright, font: DarkFantasyTheme.cardTitle)
                if let share = vm.treasuryShareForSelectedBet {
                    Text("+\(share.formatted()) on ×5")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.info)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fortuna's Treasury \(treasury) gold. The ×5 slot adds a share of it.")
    }

    // MARK: - Odds

    private var oddsSheet: some View {
        MinigameInfoSheet(
            title: "ODDS",
            rows: (vm?.odds ?? []).map { (label: $0.displayLabel, value: $0.displayPercent) },
            notes: [
                "Every bet adds 2% to Fortuna's Treasury. Landing on ×5 also pays a share of it: a 1,000 bet takes a fifth, smaller bets less.",
                "The odds come from the server and are the same on every spin."
            ]
        )
    }

    // MARK: - Result card (big wins only)

    @ViewBuilder
    private func resultModal(_ vm: FortuneWheelViewModel, result: FortuneWheelViewModel.SpinResult) -> some View {
        // A full-screen fortune card with its own backdrop (no GameModal);
        // its metal follows the sector: ×3 gold, ×5 or the Treasury mythic.
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
            onContinue: { showResultModal = false }
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
            return "-\(lastStake.formatted()) Gold"
        }
    }

    // MARK: - Spin

    private func spinTapped(_ vm: FortuneWheelViewModel) {
        guard vm.canSpin else { return }
        HapticManager.heavy()
        SFXManager.shared.play(.uiConfirm)
        Task { await performSpin(vm) }
    }

    private func performSpin(_ vm: FortuneWheelViewModel) async {
        let stake = vm.selectedBet
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

        withAnimation(MotionConstants.smooth) { stageResult = nil }
        isAnimating = true
        showResultModal = false
        landedSlot = slot
        lastStake = stake

        wheelRotation += fullSpins + delta

        // Wait for the wheel to stop
        try? await Task.sleep(for: .seconds(4.2))

        isAnimating = false
        vm.onAnimationComplete()
        withAnimation(MotionConstants.springBouncy) { stageResult = spinResult }

        // Big wins still get the reward card.
        if spinResult.won, spinResult.multiplier >= 3 || spinResult.jackpotShare > 0 {
            try? await Task.sleep(for: .seconds(0.6))
            showResultModal = true
        }
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
