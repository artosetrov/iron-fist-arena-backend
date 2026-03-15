import SwiftUI

struct GoldMineDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: GoldMineViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                if vm.isLoading && vm.slots.isEmpty {
                    loadingState
                } else {
                    ScrollView {
                        VStack(spacing: LayoutConstants.spaceMD) {
                            // Active quest banner
                            ActiveQuestBanner(questTypes: ["gold_mine_collect"])

                            miningOutputCard(vm: vm)
                            slotsContainer(vm: vm)
                        }
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceLG)
                    }
                }
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
                Text("🪙")
                    .font(.system(size: 22)) // emoji — keep
                Text("\(vm.activeSlotCount * 200)/HR")
                    .font(DarkFantasyTheme.title(size: 32))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
            }

            Text("\(vm.activeSlotCount) Active Slots")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Slots Container

    private func slotsContainer(vm: GoldMineViewModel) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<vm.maxSlots, id: \.self) { index in
                if index > 0 {
                    Divider()
                        .background(DarkFantasyTheme.borderSubtle)
                }
                slotRow(index: index, vm: vm)
            }

            // Locked next slot
            if vm.maxSlots < 6 {
                Divider()
                    .background(DarkFantasyTheme.borderSubtle)
                lockedSlotRow(slotNumber: vm.maxSlots + 1, vm: vm)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
    }

    // MARK: - Slot Row

    private func slotRow(index: Int, vm: GoldMineViewModel) -> some View {
        let slot = index < vm.slots.count ? vm.slots[index] : [String: Any]()
        let status = vm.slotStatus(slot)
        let isActing = vm.actionSlotId == "\(index)"

        return HStack(spacing: LayoutConstants.spaceSM) {
            // Icon
            slotIcon(status: status)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text("SLOT \(index + 1)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                if status == "mining" {
                    Text("Mining... \(vm.timeRemaining(slot))")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    // Progress bar
                    miningProgressBar(progress: vm.miningProgress(slot), status: status)
                } else if status == "ready" {
                    Text("Ready to collect!")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.success)
                } else {
                    Text("Idle")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }

            Spacer()

            // Action button
            if isActing {
                ProgressView().tint(DarkFantasyTheme.gold)
            } else {
                slotActionButton(status: status, index: index, vm: vm)
            }
        }
        .padding(LayoutConstants.spaceMD)
    }

    // MARK: - Locked Slot Row

    private func lockedSlotRow(slotNumber: Int, vm: GoldMineViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Lock icon
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.textTertiary.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "lock.fill")
                    .font(.system(size: 20)) // SF Symbol icon — keep
                    .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("SLOT \(slotNumber)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                HStack(spacing: 3) {
                    Text("Unlock for")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Text("💎 50")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.cyan)
                }
            }

            Spacer()

            Button {
                Task { await vm.buySlot() }
            } label: {
                Text("UNLOCK")
                    .frame(width: 80, height: 34)
            }
            .buttonStyle(.compactOutline(color: DarkFantasyTheme.borderMedium, fillOpacity: 0.15))
            .disabled(vm.isBuyingSlot)
        }
        .padding(LayoutConstants.spaceMD)
        .opacity(0.7)
    }

    // MARK: - Slot Icon

    private func slotIcon(status: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(iconBgColor(status))
                .frame(width: 48, height: 48)

            switch status {
            case "mining":
                Image(systemName: "hammer.fill")
                    .font(.system(size: 20)) // SF Symbol icon — keep
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            case "ready":
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 22)) // SF Symbol icon — keep
                    .foregroundStyle(DarkFantasyTheme.success)
            default:
                Image(systemName: "circle.dashed")
                    .font(.system(size: 20)) // SF Symbol icon — keep
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
    }

    private func iconBgColor(_ status: String) -> Color {
        switch status {
        case "mining": DarkFantasyTheme.textTertiary.opacity(0.12)
        case "ready": DarkFantasyTheme.success.opacity(0.15)
        default: DarkFantasyTheme.textTertiary.opacity(0.08)
        }
    }

    // MARK: - Mining Progress Bar

    private func miningProgressBar(progress: Double, status: String) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(DarkFantasyTheme.borderSubtle)

                RoundedRectangle(cornerRadius: 3)
                    .fill(progressBarColor(progress: progress))
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 6)
        .frame(maxWidth: 200)
    }

    private func progressBarColor(progress: Double) -> LinearGradient {
        if progress > 0.5 {
            return LinearGradient(
                colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                startPoint: .leading, endPoint: .trailing
            )
        }
        return LinearGradient(
            colors: [DarkFantasyTheme.stamina, DarkFantasyTheme.gold],
            startPoint: .leading, endPoint: .trailing
        )
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func slotActionButton(status: String, index: Int, vm: GoldMineViewModel) -> some View {
        switch status {
        case "idle":
            Button {
                Task { await vm.startMining(slotIndex: index) }
            } label: {
                Text("MINE")
                    .frame(width: 80, height: 34)
            }
            .buttonStyle(.compactPrimary)

        case "mining":
            Button {
                Task { await vm.boost(slotIndex: index) }
            } label: {
                HStack(spacing: 4) {
                    Text("BOOST")
                    Text("💎")
                        .font(.system(size: 11)) // emoji — keep
                }
                .frame(width: 90, height: 34)
            }
            .buttonStyle(.compactOutline(color: DarkFantasyTheme.cyan))

        case "ready":
            Button {
                Task { await vm.collect(slotIndex: index) }
            } label: {
                HStack(spacing: 4) {
                    Text("COLLECT")
                    Text("🪙")
                        .font(.system(size: 11)) // emoji — keep
                }
                .frame(width: 100, height: 34)
            }
            .buttonStyle(.compactPrimary)

        default:
            EmptyView()
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
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
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                )

                // Skeleton slots
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { i in
                        if i > 0 {
                            Divider().background(DarkFantasyTheme.borderSubtle)
                        }
                        HStack(spacing: LayoutConstants.spaceSM) {
                            SkeletonRect(width: 48, height: 48, cornerRadius: LayoutConstants.panelRadius)
                            VStack(alignment: .leading, spacing: 6) {
                                SkeletonRect(width: 60, height: 14)
                                SkeletonRect(width: 120, height: 10)
                            }
                            Spacer()
                            SkeletonRect(width: 80, height: 34, cornerRadius: LayoutConstants.panelRadius)
                        }
                        .padding(LayoutConstants.spaceMD)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
    }
}
