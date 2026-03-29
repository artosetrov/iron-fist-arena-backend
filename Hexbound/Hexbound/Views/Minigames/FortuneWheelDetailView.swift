import SwiftUI

struct FortuneWheelDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: FortuneWheelViewModel?

    // Wheel animation
    @State private var wheelRotation: Double = 0
    @State private var targetRotation: Double = 0
    @State private var isAnimating = false

    // Result flash
    @State private var showResultFlash = false
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
        .background(DarkFantasyTheme.bgPrimary.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("FORTUNE WHEEL")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .task {
            if vm == nil {
                vm = FortuneWheelViewModel(appState: appState)
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(_ vm: FortuneWheelViewModel) -> some View {
        VStack(spacing: 0) {
            // Gold balance
            goldHeader(vm)

            ScrollView(showsIndicators: false) {
                VStack(spacing: LayoutConstants.spaceLG) {
                    // The Wheel
                    wheelSection(vm)

                    // Bet selector
                    betSelector(vm)

                    // Spin button
                    spinButton(vm)

                    // Payout table
                    payoutTable(vm)

                    Spacer().frame(height: LayoutConstants.spaceLG)
                }
            }
        }
    }

    // MARK: - Gold Header

    private func goldHeader(_ vm: FortuneWheelViewModel) -> some View {
        HStack {
            Spacer()
            CurrencyDisplay(
                gold: vm.gold,
                gems: appState.currentCharacter?.gems ?? 0,
                size: .compact,
                animated: true
            )
            .padding(.trailing, LayoutConstants.screenPadding)
        }
        .padding(.vertical, LayoutConstants.spaceXS)
    }

    // MARK: - Wheel Section

    private func wheelSection(_ vm: FortuneWheelViewModel) -> some View {
        ZStack {
            // Wheel glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DarkFantasyTheme.gold.opacity(0.15),
                            DarkFantasyTheme.gold.opacity(0.02),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 180
                    )
                )
                .frame(width: 340, height: 340)

            // Wheel
            FortuneWheelView(
                sectors: vm.sectors,
                rotation: wheelRotation
            )
            .frame(width: 280, height: 280)

            // Center ornament
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [DarkFantasyTheme.bgSecondary, DarkFantasyTheme.bgAbyss],
                            center: .center,
                            startRadius: 5,
                            endRadius: 24
                        )
                    )
                    .frame(width: 48, height: 48)
                Circle()
                    .stroke(DarkFantasyTheme.gold, lineWidth: 2.5)
                    .frame(width: 48, height: 48)
                Circle()
                    .stroke(DarkFantasyTheme.goldBright.opacity(0.5), lineWidth: 1)
                    .frame(width: 42, height: 42)

                // Show result multiplier or default icon
                if let result = vm.result, !isAnimating {
                    Text(result.won ? "x\(String(format: "%.1f", result.multiplier))" : "💀")
                        .font(DarkFantasyTheme.section(size: result.won ? 14 : 20))
                        .foregroundStyle(result.won ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger)
                        .scaleEffect(resultScale)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: resultScale)
                } else {
                    Image("icon-gems")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(DarkFantasyTheme.gold)
                }
            }

            // Pointer (top)
            VStack {
                WheelPointer()
                    .frame(width: 28, height: 36)
                    .offset(y: -2)
                Spacer()
            }
            .frame(height: 280)
        }
        .padding(.top, LayoutConstants.spaceMD)
    }

    // MARK: - Bet Selector

    private func betSelector(_ vm: FortuneWheelViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("WAGER")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)

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
                            .font(DarkFantasyTheme.section(size: 13))
                            .foregroundStyle(
                                isSelected
                                    ? DarkFantasyTheme.textOnGold
                                    : canAfford
                                        ? DarkFantasyTheme.textPrimary
                                        : DarkFantasyTheme.textTertiary
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                    .fill(
                                        isSelected
                                            ? DarkFantasyTheme.goldGradient
                                            : LinearGradient(colors: [DarkFantasyTheme.bgTertiary], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                    .stroke(
                                        isSelected
                                            ? DarkFantasyTheme.goldBright.opacity(0.6)
                                            : DarkFantasyTheme.borderSubtle,
                                        lineWidth: isSelected ? 1.5 : 1
                                    )
                            )
                    }
                    .disabled(vm.isSpinning || !canAfford)
                    .opacity(canAfford ? 1 : 0.4)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Spin Button

    private func spinButton(_ vm: FortuneWheelViewModel) -> some View {
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
                    .font(.system(size: 18, weight: .bold))
                Text(vm.isSpinning ? "SPINNING..." : "SPIN — \(vm.selectedBet) GOLD")
            }
            .font(DarkFantasyTheme.section(size: 16))
            .tracking(1)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonStyle(.primary)
        .disabled(!vm.canSpin)
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Payout Table

    private func payoutTable(_ vm: FortuneWheelViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            GoldDivider()
                .padding(.horizontal, LayoutConstants.screenPadding)

            Text("PAYOUTS")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)

            HStack(spacing: LayoutConstants.spaceMD) {
                payoutPill(label: "x1.5", count: 3, color: DarkFantasyTheme.gold)
                payoutPill(label: "x2", count: 1, color: DarkFantasyTheme.goldBright)
                payoutPill(label: "x3", count: 1, color: DarkFantasyTheme.purple)
                payoutPill(label: "x5", count: 1, color: DarkFantasyTheme.info)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    private func payoutPill(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(DarkFantasyTheme.section(size: 16))
                .foregroundStyle(color)
            Text("\(count) sector\(count > 1 ? "s" : "")")
                .font(DarkFantasyTheme.body(size: 10))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Spin Animation

    private func performSpin(_ vm: FortuneWheelViewModel) async {
        guard let spinResult = await vm.spin() else { return }

        // Calculate target rotation:
        // Each sector = 360/12 = 30 degrees
        // We want the pointer (at top / 0°) to land on the winning sector
        // Sector 0 is at the top, going clockwise
        let sectorAngle = 360.0 / Double(vm.sectors.count)
        let sectorCenter = Double(spinResult.sectorIndex) * sectorAngle + sectorAngle / 2.0

        // Spin multiple full rotations + land on target sector
        // The wheel rotates clockwise, so to land pointer on sector N,
        // we rotate the wheel so sector N is at the top (0°)
        let fullSpins = Double(Int.random(in: 5...8)) * 360.0
        let finalAngle = fullSpins + (360.0 - sectorCenter)

        isAnimating = true
        showResultFlash = false
        resultScale = 0.5

        // Direct state change — animation is handled by explicit
        // .animation(.timingCurve(...), value: rotation) on FortuneWheelView.
        // Using withAnimation() here would be overridden by
        // .transaction { $0.animation = nil } on the parent view.
        wheelRotation += finalAngle

        // Wait for animation to complete
        try? await Task.sleep(for: .seconds(4.2))

        // Show result — animation driven by explicit .animation(value:) on resultScale
        isAnimating = false
        showResultFlash = true
        resultScale = 1.0

        vm.onAnimationComplete()
    }
}

// MARK: - Fortune Wheel View (the actual pie chart wheel)

struct FortuneWheelView: View {
    let sectors: [WheelSector]
    let rotation: Double

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2

            ZStack {
                // Outer ring
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

                // Sectors
                ForEach(sectors) { sector in
                    sectorSlice(sector, center: center, radius: radius - 6)
                }

                // Inner divider lines
                ForEach(sectors) { sector in
                    dividerLine(index: sector.id, center: center, radius: radius - 6)
                }

                // Sector labels
                ForEach(sectors) { sector in
                    sectorLabel(sector, radius: radius - 6)
                }

                // Inner circle border
                Circle()
                    .stroke(DarkFantasyTheme.goldDim.opacity(0.5), lineWidth: 1)
                    .frame(width: 56, height: 56)
            }
            .rotationEffect(.degrees(rotation))
        .animation(.timingCurve(0.2, 0.8, 0.2, 1.0, duration: 4.0), value: rotation)
        }
        .aspectRatio(1, contentMode: .fit)
        .drawingGroup() // Flatten wheel sectors to Metal texture for smooth spin
    }

    @ViewBuilder
    private func sectorSlice(_ sector: WheelSector, center: CGPoint, radius: CGFloat) -> some View {
        let sectorAngle = 360.0 / Double(sectors.count)
        let startAngle = Double(sector.id) * sectorAngle - 90 // -90 to start from top
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
                        DarkFantasyTheme.bgAbyss,
                        DarkFantasyTheme.bgSecondary.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        sector.color.opacity(0.35),
                        sector.color.opacity(0.15)
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
        .stroke(DarkFantasyTheme.goldDim.opacity(0.4), lineWidth: 1)
    }

    @ViewBuilder
    private func sectorLabel(_ sector: WheelSector, radius: CGFloat) -> some View {
        let sectorAngle = 360.0 / Double(sectors.count)
        let midAngle = (Double(sector.id) * sectorAngle + sectorAngle / 2.0 - 90) * .pi / 180
        let labelRadius = radius * 0.65
        let x = labelRadius * cos(midAngle)
        let y = labelRadius * sin(midAngle)

        VStack(spacing: 1) {
            if sector.isLose {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DarkFantasyTheme.danger.opacity(0.7))
            } else {
                Text(sector.label)
                    .font(DarkFantasyTheme.section(size: sector.multiplier >= 5 ? 14 : 12))
                    .foregroundStyle(sector.color)
                    .shadow(color: sector.color.opacity(0.5), radius: 4)
            }
        }
        .offset(x: x, y: y)
        .rotationEffect(.degrees(Double(sector.id) * sectorAngle + sectorAngle / 2.0))
    }
}

// MARK: - Wheel Pointer

struct WheelPointer: View {
    var body: some View {
        ZStack {
            // Pointer triangle
            Path { path in
                path.move(to: CGPoint(x: 14, y: 0))   // tip
                path.addLine(to: CGPoint(x: 4, y: 28))
                path.addLine(to: CGPoint(x: 24, y: 28))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Pointer outline
            Path { path in
                path.move(to: CGPoint(x: 14, y: 0))
                path.addLine(to: CGPoint(x: 4, y: 28))
                path.addLine(to: CGPoint(x: 24, y: 28))
                path.closeSubpath()
            }
            .stroke(DarkFantasyTheme.bgAbyss, lineWidth: 2)

            // Tiny diamond at tip
            Circle()
                .fill(DarkFantasyTheme.goldBright)
                .frame(width: 6, height: 6)
                .offset(y: 2)
        }
    }
}
