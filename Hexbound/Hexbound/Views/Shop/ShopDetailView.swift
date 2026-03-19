import SwiftUI

struct ShopDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: ShopViewModel?

    // Merchant strip state (UI-only, not in VM)
    @State private var showMerchant = true
    @State private var showMerchantMini = false
    @State private var tipProvider = MerchantTipProvider()

    var body: some View {
        ZStack {
            // Background image with dark overlay
            GeometryReader { geo in
                Image("bg-shop")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            DarkFantasyTheme.bgBackdrop
                .ignoresSafeArea()

            if let vm {
                VStack(spacing: 0) {
                    // Currency bar — redesigned: balance LEFT, GET MORE button RIGHT
                    HStack(spacing: LayoutConstants.spaceSM) {
                        CurrencyDisplay(gold: vm.gold, gems: vm.gems)

                        Spacer()

                        Button {
                            appState.mainPath.append(AppRoute.currencyPurchase)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                Text("GET MORE")
                            }
                        }
                        .buttonStyle(.getMore)
                    }
                    .tutorialAnchor(.shopGems)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.vertical, LayoutConstants.spaceSM)
                    .background(DarkFantasyTheme.bgSecondary)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(DarkFantasyTheme.borderSubtle)
                            .frame(height: 1)
                    }

                    // Active quest banner
                    ActiveQuestBanner(questTypes: ["gold_spent"])
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceSM)

                    // Special Offers carousel
                    if !vm.offers.isEmpty {
                        ShopOfferBannerView(
                            offers: vm.offers,
                            canAfford: { vm.canAffordOffer($0) },
                            buyingId: vm.buyingOfferId,
                            onBuy: { offer in Task { await vm.buyOffer(offer) } }
                        )
                        .padding(.bottom, LayoutConstants.spaceSM)
                    }

                    // Tab switcher
                    TabSwitcher(
                        tabs: ShopViewModel.tabs,
                        selectedIndex: Binding(
                            get: { vm.selectedTab },
                            set: { vm.selectedTab = $0 }
                        )
                    )
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceSM)
                    .onChange(of: vm.selectedTab) { _, newTab in
                        tipProvider.updateTab(newTab)
                    }

                    // Content
                    if vm.isLoading && vm.items.isEmpty {
                        ScrollView {
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.shopGap), count: LayoutConstants.shopCols),
                                spacing: LayoutConstants.shopGap
                            ) {
                                ForEach(0..<8, id: \.self) { _ in
                                    SkeletonShopItemCard()
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.vertical, LayoutConstants.spaceSM)
                        }
                    } else if vm.filteredItems.isEmpty {
                        Spacer()
                        VStack(spacing: LayoutConstants.spaceSM) {
                            Text("🛒")
                                .font(.system(size: 40)) // emoji — keep
                            Text("No items available")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.shopGap), count: LayoutConstants.shopCols),
                                spacing: LayoutConstants.shopGap
                            ) {
                                if vm.selectedTab == 0 {
                                    // All tab — sectioned by category
                                    ForEach(vm.sectionedItems) { section in
                                        Section {
                                            ForEach(section.items) { item in
                                                ShopItemCardView(
                                                    item: item,
                                                    canAfford: vm.canAfford(item),
                                                    meetsLevel: vm.meetsLevel(item),
                                                    isBuying: vm.buyingItemId == item.id,
                                                    onTap: { vm.selectItem(item) }
                                                )
                                            }
                                        } header: {
                                            HStack(spacing: LayoutConstants.spaceXS) {
                                                Text(section.icon)
                                                    .font(.system(size: 14)) // emoji — keep
                                                Text(section.title.uppercased())
                                                    .font(DarkFantasyTheme.section(size: LayoutConstants.textSection))
                                                    .foregroundStyle(DarkFantasyTheme.goldBright)
                                                Spacer()
                                            }
                                            .padding(.top, LayoutConstants.spaceSM)
                                        }
                                    }
                                } else {
                                    // Filtered tab — flat grid
                                    ForEach(vm.filteredItems) { item in
                                        ShopItemCardView(
                                            item: item,
                                            canAfford: vm.canAfford(item),
                                            meetsLevel: vm.meetsLevel(item),
                                            isBuying: vm.buyingItemId == item.id,
                                            onTap: { vm.selectItem(item) }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.vertical, LayoutConstants.spaceSM)
                        }
                        // Merchant strip as bottom inset
                        .safeAreaInset(edge: .bottom) {
                            if showMerchant {
                                MerchantStripView(
                                    tipProvider: tipProvider,
                                    onCollapse: {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            showMerchant = false
                                            showMerchantMini = true
                                        }
                                    },
                                    onDismiss: {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            showMerchant = false
                                        }
                                    }
                                )
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                }

                // Collapsed merchant mini avatar
                .overlay(alignment: .bottomLeading) {
                    if showMerchantMini {
                        MerchantMiniButton {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showMerchantMini = false
                                showMerchant = true
                            }
                        }
                        .padding(.leading, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceMD)
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                // Item detail modal (unified template)
                if vm.showItemDetail, let shopItem = vm.selectedItem {
                    ItemDetailSheet(
                        item: shopItem.toItem(),
                        comparedItem: vm.equippedItemForSlot(shopItem),
                        playerGems: vm.gems,
                        upgradeChances: [],
                        onEquip: {},
                        onUnequip: {},
                        onSell: {},
                        onUse: {},
                        onUpgrade: { _ in },
                        onRepair: {},
                        onClose: { vm.closeDetail() },
                        shopMode: .init(
                            displayPrice: shopItem.displayPrice,
                            isGemPurchase: shopItem.isGemPurchase,
                            canAfford: vm.canAfford(shopItem),
                            meetsLevel: vm.meetsLevel(shopItem),
                            isBuying: vm.buyingItemId == shopItem.id,
                            requiredLevel: shopItem.requiredLevel,
                            onBuy: { vm.requestBuy(shopItem) }
                        )
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: vm.showItemDetail)
                }
            }
        }
        .confirmationDialog(
            "CONFIRM PURCHASE",
            isPresented: Binding(
                get: { vm?.showPurchaseConfirm ?? false },
                set: { if !$0 { vm?.cancelPendingPurchase() } }
            ),
            presenting: vm?.pendingPurchaseItem
        ) { item in
            Button("Buy for \(item.displayPrice)") {
                vm?.confirmPendingPurchase()
            }
            Button("Cancel", role: .cancel) {
                vm?.cancelPendingPurchase()
            }
        } message: { item in
            Text("Spend \(item.displayPrice) on \(item.itemName)?")
        }
        .navigationBarBackButtonHidden(true)
        .tutorialOverlay(steps: [.shopGems])
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("SHOP")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .task {
            if vm == nil {
                let shopVM = ShopViewModel(appState: appState, cache: cache)
                if appState.shopInitialTab > 0 {
                    shopVM.selectedTab = appState.shopInitialTab
                    appState.shopInitialTab = 0
                    tipProvider.updateTab(shopVM.selectedTab)
                }
                vm = shopVM
            }
            await vm?.loadItems()
        }
    }
}
