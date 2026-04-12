import SwiftUI

// MARK: - Stash Detail View

/// Account-level item chest accessible from the Tavern.
/// Shared across all characters of the same user — 100 slots.
/// Design mirrors the inventory grid in HeroDetailView.
struct StashDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: StashViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm = vm {
                stashContent(vm)

                // Item detail overlay
                if vm.showItemDetail, let item = vm.selectedItem {
                    stashItemDetailOverlay(vm: vm, item: item)
                        .transition(.opacity)
                }
            } else {
                HexPulseLoader(.compact)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("CHEST")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .task {
            if vm == nil {
                vm = StashViewModel(appState: appState)
            }
            await vm?.loadStash()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func stashContent(_ vm: StashViewModel) -> some View {
        ScrollView {
            VStack(spacing: LayoutConstants.spaceMD) {
                // Header info
                stashHeader(vm)

                // Sort picker
                sortPicker(vm)

                // Item grid
                if vm.isLoading && vm.items.isEmpty {
                    stashLoadingGrid()
                } else {
                    stashGrid(vm)
                }

                Spacer().frame(height: LayoutConstants.spaceLG)
            }
        }
    }

    // MARK: - Header

    private func stashHeader(_ vm: StashViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Chest icon
            Image(systemName: "shippingbox.fill")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.gold)

            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text("Shared Chest")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text("Shared across all your characters")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }

            Spacer()

            // Slot counter
            Text("\(vm.items.count)/\(vm.maxSlots)")
                .font(DarkFantasyTheme.uiLabel.bold())
                .foregroundStyle(vm.items.count >= vm.maxSlots
                    ? DarkFantasyTheme.danger
                    : DarkFantasyTheme.textSecondary)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceSM)
    }

    // MARK: - Sort Picker

    private func sortPicker(_ vm: StashViewModel) -> some View {
        @Bindable var bvm = vm
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LayoutConstants.spaceXS) {
                ForEach(InventorySortMode.allCases, id: \.self) { mode in
                    Button {
                        bvm.sortMode = mode
                    } label: {
                        HStack(spacing: LayoutConstants.space2XS) {
                            Image(systemName: mode.icon)
                                .font(DarkFantasyTheme.caption)
                            Text(mode.rawValue)
                                .font(DarkFantasyTheme.caption)
                        }
                        .padding(.horizontal, LayoutConstants.spaceSM)
                        .padding(.vertical, LayoutConstants.spaceXS)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .fill(vm.sortMode == mode
                                    ? DarkFantasyTheme.gold.opacity(0.2)
                                    : DarkFantasyTheme.bgTertiary.opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .stroke(vm.sortMode == mode
                                    ? DarkFantasyTheme.gold.opacity(0.4)
                                    : DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )
                        .foregroundStyle(vm.sortMode == mode
                            ? DarkFantasyTheme.gold
                            : DarkFantasyTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Item Grid

    @ViewBuilder
    private func stashGrid(_ vm: StashViewModel) -> some View {
        let slots = vm.gridSlots
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.inventoryGap), count: LayoutConstants.inventoryCols),
            spacing: LayoutConstants.inventoryGap
        ) {
            ForEach(slots) { slot in
                if let item = slot.item {
                    ItemCardView(
                        item: item,
                        context: .inventory(equippedItem: nil, canEquip: true)
                    ) {
                        vm.selectItem(item)
                    }
                } else {
                    // Empty slot
                    VStack {
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .fill(DarkFantasyTheme.bgTertiary.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                            )
                            .innerBorder(cornerRadius: LayoutConstants.cardRadius - 1, inset: 1, color: DarkFantasyTheme.borderMedium.opacity(0.06))
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)

        // Empty state
        if vm.items.isEmpty && !vm.isLoading {
            VStack(spacing: LayoutConstants.spaceMD) {
                Image(systemName: "shippingbox")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)

                Text("Your chest is empty")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Text("Store items here from your inventory\nto share them between characters")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, LayoutConstants.spaceXL)
        }
    }

    // MARK: - Loading Grid

    private func stashLoadingGrid() -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.inventoryGap), count: LayoutConstants.inventoryCols),
            spacing: LayoutConstants.inventoryGap
        ) {
            ForEach(0..<20, id: \.self) { _ in
                SkeletonInventoryItem()
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Item Detail Overlay

    @ViewBuilder
    private func stashItemDetailOverlay(vm: StashViewModel, item: Item) -> some View {
        ItemDetailSheet(
            item: item,
            comparedItem: nil,
            playerGems: appState.currentCharacter?.gems ?? 0,
            upgradeChances: cache.gameConfig?.upgradeChances ?? [100, 100, 100, 100, 100, 80, 60, 40, 25, 15],
            onEquip: {},
            onUnequip: {},
            onSell: {},
            onUse: {},
            onUpgrade: { _ in },
            onRepair: {},
            onClose: { vm.showItemDetail = false },
            playerLevel: appState.currentCharacter?.level ?? 1,
            playerClass: appState.currentCharacter?.characterClass,
            viewMode: true
        )
        .overlay(alignment: .bottom) {
            // Withdraw button at the bottom
            withdrawButton(vm: vm, item: item)
        }
    }

    private func withdrawButton(vm: StashViewModel, item: Item) -> some View {
        Button {
            let _ = Task { await vm.withdraw(item) }
            vm.showItemDetail = false
        } label: {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "arrow.down.to.line")
                Text("WITHDRAW TO INVENTORY")
            }
        }
        .buttonStyle(.primary)
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.bottom, LayoutConstants.spaceLG)
    }
}
