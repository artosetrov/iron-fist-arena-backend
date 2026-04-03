import SwiftUI

struct FortuneWheelDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: FortuneWheelViewModel?

    // Wheel animation
    @State private var wheelRotation: Double = 0
    @State private var isAnimating = false

    // Result modal
    @State private var showResultModal = false
    @State private var resultScale: CGFloat = 0.5

    var body: some View {
        Group {
            if let vm {
                mainContent(vm)
                    .transaction { $0.animation = nil }
            } else {
                ProgressView()
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
                    VStack(spacing: LayoutConstants.spaceMD) {
                        // Payouts — ABOVE wheel (per Figma)
                        payoutSection(vm)

                        // Gold divider between payouts and wheel (per Figma)
                        GoldDivider()
                            .padding(.horizontal, LayoutConstants.screenPadding)

                        // The Wheel
                        wheelSection(vm)

                        // Spacer for NPC widget clearance
                        Spacer().frame(height: 240)
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

    // MARK: - Payout Section (above wheel)

    private func payoutSection(_ vm: FortuneWheelViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("PAYOUTS")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)

            HStack(spacing: LayoutConstants.spaceSM) {
                payoutPill(asset: "icon-fortune-x15", label: "x1.5", count: 3, color: DarkFantasyTheme.gold)
                payoutPill(asset: "icon-fortune-x2", label: "x2", count: 1, color: DarkFantasyTheme.goldBright)
                payoutPill(asset: "icon-fortune-x3", label: "x3", count: 1, color: DarkFantasyTheme.purple)
                payoutPill(asset: "icon-fortune-x5", label: "x5", count: 1, color: DarkFantasyTheme.info)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
        .padding(.top, LayoutConstants.spaceXS)
    }

    private func payoutPill(asset: String, label: String, count: Int, color: Color) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Image(asset)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)

            Text(label)
                .font(DarkFantasyTheme.uiLabel)
                .foregroundStyle(color)

            Text("\(count) sector\(count > 1 ? "s" : "")")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: color,
                glowIntensity: DarkFantasyTheme.opacityLight,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(color.opacity(DarkFantasyTheme.opacityMild), lineWidth: 1)
        )
        .compositingGroup()
    }

    // MARK: - Wheel Section

    private func wheelSection(_ vm: FortuneWheelViewModel) -> some View {
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
                        startRadius: 80,
                        endRadius: 220
                    )
                )
                .frame(width: 420, height: 420)

            // Wheel with sectors + asset icons
            FortuneWheelView(
                sectors: vm.sectors,
                rotation: wheelRotation
            )
            .frame(width: 350, height: 350)

            // Center ornament
            wheelCenter(vm)

            // Pointer (top) — asset-based dagger
            VStack {
                Image("fortune-pointer")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 56)
                    .rotationEffect(.degrees(135))
                    .shadow(color: DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityStrong), radius: 6)
                    .offset(y: -4)
                Spacer()
            }
            .frame(height: 350)
        }
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
            npcImageName: "lady-fortuna",
            plainMessage: vm.npcSpeech,
            wheelContent: AnyView(wheelWagerSection(vm))
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
                        .font(DarkFantasyTheme.badge)
                    Text("\(vm.spinsRemaining)/\(vm.spinsLimit)")
                        .font(DarkFantasyTheme.badge)
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
                    .disabled(vm.isSpinning || !canAfford)
                    .opacity(canAfford ? 1 : DarkFantasyTheme.opacityStrong)
                }
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
        let accentColor = result.won ? DarkFantasyTheme.gold : DarkFantasyTheme.danger

        ZStack {
            // Dimmed background
            DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityOpaque)
                .ignoresSafeArea()
                .onTapGesture { dismissModal(vm) }

            // Modal card
            VStack(spacing: 0) {
                // Result icon
                Image(vm.sectors[result.sectorIndex].sectorAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
                    .shadow(color: accentColor.opacity(DarkFantasyTheme.opacityStrong), radius: 8)
                    .padding(.bottom, LayoutConstants.spaceMD)

                // Title
                Text(resultTitle(result))
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(result.won ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger)
                    .padding(.bottom, LayoutConstants.spaceXS)

                // Amount
                Text(resultAmountText(vm, result: result))
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .padding(.bottom, LayoutConstants.spaceLG)

                // Dismiss button
                if result.won {
                    Button {
                        dismissModal(vm)
                    } label: {
                        Text("CONTINUE")
                            .font(DarkFantasyTheme.cardTitle)
                            .tracking(2)
                            .frame(maxWidth: .infinity)
                            .frame(height: LayoutConstants.buttonHeightMD)
                    }
                    .buttonStyle(.primary)
                } else {
                    Button {
                        dismissModal(vm)
                    } label: {
                        Text("CONTINUE")
                            .font(DarkFantasyTheme.cardTitle)
                            .tracking(2)
                            .frame(maxWidth: .infinity)
                            .frame(height: LayoutConstants.buttonHeightMD)
                    }
                    .buttonStyle(.danger)
                }
            }
            .padding(LayoutConstants.spaceLG)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: DarkFantasyTheme.opacityStrong,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(DarkFantasyTheme.opacityMild))
            .cornerBrackets(color: accentColor.opacity(DarkFantasyTheme.opacityMedium), length: 18, thickness: 1.5)
            .cornerDiamonds(color: accentColor.opacity(DarkFantasyTheme.opacityStrong), size: 5)
            .compositingGroup()
            .dualShadow(glowColor: accentColor, glowRadius: 12, depth: .modal)
            .frame(maxWidth: 300)
            .opacity(showResultModal ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showResultModal)
        }
        .transition(.opacity)
    }

    private func resultTitle(_ result: FortuneWheelViewModel.SpinResult) -> String {
        if !result.won { return "LOST" }
        if result.multiplier >= 5 { return "JACKPOT!" }
        if result.multiplier >= 3 { return "BIG WIN!" }
        return "YOU WON!"
    }

    private func resultAmountText(_ vm: FortuneWheelViewModel, result: FortuneWheelViewModel.SpinResult) -> String {
        if result.won {
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

        let sectorAngle = 360.0 / Double(vm.sectors.count)
        let sectorCenter = Double(spinResult.sectorIndex) * sectorAngle + sectorAngle / 2.0

        let fullSpins = Double(Int.random(in: 5...8)) * 360.0
        let finalAngle = fullSpins + (360.0 - sectorCenter)

        isAnimating = true
        showResultModal = false
        resultScale = 0.5

        wheelRotation += finalAngle

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

// MARK: - Fortune Wheel View (the actual pie chart wheel with asset icons)

struct FortuneWheelView: View {
    let sectors: [WheelSector]
    let rotation: Double

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2

            ZStack {
                // Wheel face texture (background)
                Image("fortune-wheel-face")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())

                // Semi-transparent sector overlays for color tinting
                ForEach(sectors) { sector in
                    sectorSlice(sector, center: center, radius: radius - 6)
                }

                // Inner divider lines
                ForEach(sectors) { sector in
                    dividerLine(index: sector.id, center: center, radius: radius - 6)
                }

                // Sector asset icons + labels
                ForEach(sectors) { sector in
                    sectorContent(sector, radius: radius - 6)
                }

                // Outer metallic ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                DarkFantasyTheme.goldBright,
                                DarkFantasyTheme.gold,
                                DarkFantasyTheme.goldDim,
                                DarkFantasyTheme.gold,
                                DarkFantasyTheme.goldBright
                            ],
                            center: .center
                        ),
                        lineWidth: 4
                    )

                // Inner circle border
                Circle()
                    .stroke(DarkFantasyTheme.goldDim.opacity(DarkFantasyTheme.opacityHeavy), lineWidth: 1)
                    .frame(width: 56, height: 56)
            }
            .rotationEffect(.degrees(rotation))
            .animation(.timingCurve(0.2, 0.8, 0.2, 1.0, duration: 4.0), value: rotation)
        }
        .aspectRatio(1, contentMode: .fit)
        .drawingGroup()
    }

    @ViewBuilder
    private func sectorSlice(_ sector: WheelSector, center: CGPoint, radius: CGFloat) -> some View {
        let sectorAngle = 360.0 / Double(sectors.count)
        let startAngle = Double(sector.id) * sectorAngle - 90
        let endAngle = startAngle + sectorAngle

        Path { path in
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle),
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(sectorFillColor(sector))
    }

    private func sectorFillColor(_ sector: WheelSector) -> some ShapeStyle {
        if sector.isLose {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityHeavy),
                        DarkFantasyTheme.bgSecondary.opacity(DarkFantasyTheme.opacityMedium)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        sector.color.opacity(DarkFantasyTheme.opacityMedium),
                        sector.color.opacity(DarkFantasyTheme.opacitySoft)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    @ViewBuilder
    private func dividerLine(index: Int, center: CGPoint, radius: CGFloat) -> some View {
        let sectorAngle = 360.0 / Double(sectors.count)
        let angle = Double(index) * sectorAngle - 90

        Path { path in
            path.move(to: center)
            let endX = center.x + radius * cos(angle * .pi / 180)
            let endY = center.y + radius * sin(angle * .pi / 180)
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        .stroke(DarkFantasyTheme.goldDim.opacity(DarkFantasyTheme.opacityMedium), lineWidth: 1)
    }

    @ViewBuilder
    private func sectorContent(_ sector: WheelSector, radius: CGFloat) -> some View {
        let sectorAngle = 360.0 / Double(sectors.count)
        let midAngle = (Double(sector.id) * sectorAngle + sectorAngle / 2.0 - 90) * .pi / 180

        // Icon position (closer to outer edge)
        let iconRadius = radius * 0.7
        let iconX = iconRadius * cos(midAngle)
        let iconY = iconRadius * sin(midAngle)

        // Sector asset icon
        Image(sector.sectorAsset)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(
                width: sector.isLose ? LayoutConstants.iconMD : LayoutConstants.iconLG,
                height: sector.isLose ? LayoutConstants.iconMD : LayoutConstants.iconLG
            )
            .opacity(sector.isLose ? DarkFantasyTheme.opacityHeavy : 0.9)
            .shadow(color: sector.color.opacity(sector.isLose ? 0 : DarkFantasyTheme.opacityHeavy), radius: 3)
            .offset(x: iconX, y: iconY)
            .rotationEffect(.degrees(Double(sector.id) * sectorAngle + sectorAngle / 2.0))

        // Multiplier label (closer to center)
        if !sector.isLose {
            let labelRadius = radius * 0.42
            let labelX = labelRadius * cos(midAngle)
            let labelY = labelRadius * sin(midAngle)

            Text(sector.label)
                .font(sector.multiplier >= 5 ? DarkFantasyTheme.uiLabel : DarkFantasyTheme.badge)
                .foregroundStyle(sector.color)
                .shadow(color: sector.color.opacity(DarkFantasyTheme.opacityHeavy), radius: 4)
                .offset(x: labelX, y: labelY)
                .rotationEffect(.degrees(Double(sector.id) * sectorAngle + sectorAngle / 2.0))
        }
    }
}
