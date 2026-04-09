import SwiftUI

struct BuyStatPointsView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: BuyStatPointsViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                mainContent(vm)
            } else {
                LoadingOverlay()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton {
                    if !appState.mainPath.isEmpty {
                        appState.mainPath.removeLast()
                    }
                }
            }
        }
        .task {
            let service = CharacterService(appState: appState)
            let viewModel = BuyStatPointsViewModel(service: service)
            vm = viewModel
            await viewModel.loadStatus()
        }
    }

    @ViewBuilder
    private func mainContent(_ vm: BuyStatPointsViewModel) -> some View {
        ScrollView {
            VStack(spacing: LayoutConstants.spaceLG) {
                // Screen header
                OrnamentalTitle("BUY STAT POINTS")
                    .padding(.top, LayoutConstants.spaceSM)

                // Crystal balance
                crystalBalanceCard()

                // Free points badge
                if let pts = appState.currentCharacter?.statPoints, pts > 0 {
                    freePointsBadge(pts)
                }

                GoldDivider()
                    .padding(.horizontal, LayoutConstants.screenPadding)

                // Daily purchases section
                dailyPurchaseSection(vm)

                GoldDivider()
                    .padding(.horizontal, LayoutConstants.screenPadding)

                // Global cap progress
                globalCapCard(vm)

                // Reset timer
                resetTimerView()

                Spacer(minLength: LayoutConstants.spaceLG)
            }
        }

        // Confirmation sheet
        .sheet(isPresented: Binding(
            get: { vm.showConfirmation },
            set: { vm.showConfirmation = $0 }
        )) {
            confirmationSheet(vm)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(DarkFantasyTheme.bgSecondary)
        }
    }

    // MARK: - Crystal Balance

    @ViewBuilder
    private func crystalBalanceCard() -> some View {
        let gems = appState.currentCharacter?.gems ?? 0

        HStack {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image("icon-gems")
                    .resizable()
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text("CRYSTALS")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    Text("\(gems)")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.cyan)
                }
            }

            Spacer()

            Button {
                appState.mainPath.append(AppRoute.currencyPurchase())
            } label: {
                Text("+ BUY")
                    .font(DarkFantasyTheme.badge)
            }
            .buttonStyle(.ghost)
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.cyan.opacity(0.05),
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.cyan.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Free Points Badge

    @ViewBuilder
    private func freePointsBadge(_ points: Int) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "star.fill")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.gold)

            Text("FREE POINTS AVAILABLE:")
                .font(DarkFantasyTheme.uiLabel)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            Text("\(points)")
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.gold)
        }
        .padding(LayoutConstants.spaceMS)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.gold.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Daily Purchase Section

    @ViewBuilder
    private func dailyPurchaseSection(_ vm: BuyStatPointsViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Header with daily dots
            HStack {
                Text("TODAY'S OFFERS")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Spacer()

                HStack(spacing: LayoutConstants.spaceXS) {
                    ForEach(0..<vm.dailyLimit, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                i < vm.purchasesToday
                                    ? DarkFantasyTheme.textDisabled
                                    : DarkFantasyTheme.cyan
                            )
                            .frame(width: 8, height: 8)
                            .rotationEffect(.degrees(45))
                            .opacity(i < vm.purchasesToday ? 0.4 : 1)
                    }

                    Text("\(vm.dailyRemaining)/\(vm.dailyLimit)")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            // Purchase rows
            VStack(spacing: LayoutConstants.spaceSM) {
                ForEach(0..<vm.prices.count, id: \.self) { index in
                    purchaseRow(vm: vm, index: index)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Purchase Row

    @ViewBuilder
    private func purchaseRow(vm: BuyStatPointsViewModel, index: Int) -> some View {
        let price = vm.prices[index]
        let isPurchased = index < vm.purchasesToday
        let isNext = index == vm.purchasesToday && !vm.isDailyLimitReached && !vm.isGlobalCapReached
        let gems = appState.currentCharacter?.gems ?? 0
        let canAfford = gems >= price

        HStack(spacing: LayoutConstants.spaceSM) {
            // Step indicator
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isPurchased
                            ? DarkFantasyTheme.bgTertiary
                            : isNext
                                ? DarkFantasyTheme.cyan
                                : DarkFantasyTheme.bgTertiary
                    )
                    .frame(width: 32, height: 32)

                if isPurchased {
                    Image(systemName: "checkmark")
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textDisabled)
                } else {
                    Text("#\(index + 1)")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(isNext ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textDisabled)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text("+1 STAT POINT")
                    .font(DarkFantasyTheme.uiLabel.bold())
                    .foregroundStyle(isPurchased ? DarkFantasyTheme.textDisabled : DarkFantasyTheme.textPrimary)

                Text(
                    isPurchased ? "Purchased today"
                    : index == 0 ? "Best price today"
                    : "+\(Int((Double(price) / Double(vm.prices[0]) - 1) * 100))% escalation"
                )
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            Spacer()

            // Price button
            if isPurchased {
                Text("DONE")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textDisabled)
                    .padding(.horizontal, LayoutConstants.spaceMS)
                    .padding(.vertical, LayoutConstants.spaceSM)
            } else if isNext {
                Button {
                    HapticManager.light()
                    vm.showConfirmation = true
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("icon-gems")
                            .resizable()
                            .frame(width: 12, height: 12)
                        Text("\(price)")
                            .font(DarkFantasyTheme.uiLabel.bold())
                    }
                }
                .buttonStyle(.primary)
                .disabled(!canAfford)
                .opacity(canAfford ? 1 : 0.5)
            } else {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("icon-gems")
                        .resizable()
                        .frame(width: 12, height: 12)
                    Text("\(price)")
                        .font(DarkFantasyTheme.uiLabel)
                }
                .foregroundStyle(DarkFantasyTheme.textDisabled)
                .padding(.horizontal, LayoutConstants.spaceMS)
                .padding(.vertical, LayoutConstants.spaceSM)
            }
        }
        .padding(LayoutConstants.spaceMS)
        .background(
            RadialGlowBackground(
                baseColor: isNext ? DarkFantasyTheme.bgSecondary : DarkFantasyTheme.bgSecondary.opacity(0.6),
                glowColor: isNext ? DarkFantasyTheme.cyan.opacity(0.04) : .clear,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(
                    isNext ? DarkFantasyTheme.cyan.opacity(0.3)
                    : DarkFantasyTheme.borderSubtle,
                    lineWidth: 1
                )
        )
        .opacity(isPurchased ? 0.5 : 1)
    }

    // MARK: - Global Cap

    @ViewBuilder
    private func globalCapCard(_ vm: BuyStatPointsViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack {
                Text("LIFETIME PURCHASES")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Spacer()

                Text("\(vm.totalPurchased) / \(vm.globalCap)")
                    .font(DarkFantasyTheme.uiLabel.bold())
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DarkFantasyTheme.bgTertiary)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [DarkFantasyTheme.cyan.opacity(0.8), DarkFantasyTheme.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(vm.totalPurchased) / CGFloat(max(vm.globalCap, 1)))
                }
            }
            .frame(height: 6)

            Text("\(vm.globalCap - vm.totalPurchased) purchases remaining")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textDisabled)
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Reset Timer

    @ViewBuilder
    private func resetTimerView() -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("Daily limit resets at midnight UTC")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textDisabled)
        }
    }

    // MARK: - Confirmation Sheet

    @ViewBuilder
    private func confirmationSheet(_ vm: BuyStatPointsViewModel) -> some View {
        let price = vm.nextPrice ?? 0
        let gems = appState.currentCharacter?.gems ?? 0
        let freePoints = appState.currentCharacter?.statPoints ?? 0

        VStack(spacing: LayoutConstants.spaceLG) {
            Text("CONFIRM PURCHASE")
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .padding(.top, LayoutConstants.spaceMD)

            VStack(spacing: LayoutConstants.spaceSM) {
                confirmRow("You receive", value: "+1 Stat Point", color: DarkFantasyTheme.gold)
                confirmRow("Cost", value: "\(price) Crystals", color: DarkFantasyTheme.cyan)
                confirmRow("Balance after", value: "\(gems - price) Crystals", color: DarkFantasyTheme.cyan)
            }
            .padding(.horizontal, LayoutConstants.spaceMD)

            // Before → After
            HStack(spacing: LayoutConstants.spaceLG) {
                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("\(freePoints)")
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text("NOW")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textDisabled)
                }

                Image(systemName: "arrow.right")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.cyan)

                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("\(freePoints + 1)")
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(DarkFantasyTheme.cyan)
                    Text("AFTER")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textDisabled)
                }
            }
            .padding(LayoutConstants.spaceMD)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.cyan.opacity(0.04))
            )
            .padding(.horizontal, LayoutConstants.spaceMD)

            // Buttons
            HStack(spacing: LayoutConstants.spaceSM) {
                Button("CANCEL") {
                    vm.showConfirmation = false
                }
                .buttonStyle(.ghost)

                Button {
                    vm.purchase()
                } label: {
                    if vm.isPurchasing {
                        HexPulseLoader.onGold()
                    } else {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Text("BUY FOR \(price)")
                            Image("icon-gems")
                                .resizable()
                                .frame(width: 14, height: 14)
                        }
                        .font(DarkFantasyTheme.body)
                    }
                }
                .buttonStyle(.primary)
                .disabled(vm.isPurchasing)
            }
            .padding(.horizontal, LayoutConstants.spaceMD)

            Spacer()
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func confirmRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.uiLabel)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            Text(value)
                .font(DarkFantasyTheme.uiLabel.bold())
                .foregroundStyle(color)
        }
        .padding(.vertical, LayoutConstants.spaceXS)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DarkFantasyTheme.borderSubtle)
                .frame(height: 1)
        }
    }
}
