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
                mainContent(vm)
                    .transaction { $0.animation = nil }
            }

            merchantOverlay()
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

    // MARK: - Main Content (VStack + Item Detail)

    @ViewBuilder
    private func mainContent(_ vm: ShopViewModel) -> some View {
        VStack(spacing: 0) {
            // Screen title
            OrnamentalTitle("SHOP")
                .padding(.top, LayoutConstants.spaceSM)

            currencyBar(vm)

            // Active quest banner
            ActiveQuestBanner(questTypes: ["gold_spent"])
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.top, LayoutConstants.spaceSM)
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
            .padding(.vertical, LayoutConstants.tabSwitcherPaddingV)
            .accessibilityLabel("Shop tabs: \(ShopViewModel.tabs.joined(separator: ", "))")
            .accessibilityValue("Current tab: \(ShopViewModel.tabs[vm.selectedTab])")
            .onChange(of: vm.selectedTab) { _, newTab in
                tipProvider.updateTab(newTab)
            }

            // Content area
            shopContent(vm)
        }

        // Item detail modal (unified template)
        itemDetailOverlay(vm)
    }

    // MARK: - Currency Bar

    @ViewBuilder
    private func currencyBar(_ vm: ShopViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            CurrencyDisplay(gold: vm.gold, gems: vm.gems)

            Spacer()

            Button {
                appState.mainPath.append(AppRoute.currencyPurchase)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text("GET MORE")
                }
            }
            .buttonStyle(.getMore)
            .shimmer(color: DarkFantasyTheme.goldBright, duration: 3)
            .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.4, isActive: true)
        }
        .tutorialAnchor(.shopGems)
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceMD)
        .padding(.bottom, LayoutConstants.spaceSM)
        .background(DarkFantasyTheme.bgSecondary)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DarkFantasyTheme.borderSubtle)
                .frame(height: 1)
        }
    }

    // MARK: - Shop Content (grid states)

    @ViewBuilder
    private func shopContent(_ vm: ShopViewModel) -> some View {
        if vm.errorMessage != nil {
            ErrorStateView.loadFailed { let _ = Task { await vm.loadItems() } }
        } else if vm.isLoading && vm.items.isEmpty {
            skeletonGrid()
        } else if vm.filteredItems.isEmpty {
            Spacer()
            EmptyStateView.shopEmpty
            Spacer()
        } else {
            itemGrid(vm)
        }
    }

    // MARK: - Skeleton Grid

    private func skeletonGrid() -> some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.shopGap), count: LayoutConstants.shopCols),
                spacing: LayoutConstants.shopGap
            ) {
                ForEach(0..<8, id: \.self) { index in
                    SkeletonShopItemCard()
                        .staggeredAppear(index: index)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceSM)
        }
    }

    // MARK: - Item Grid

    @ViewBuilder
    private func itemGrid(_ vm: ShopViewModel) -> some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.shopGap), count: LayoutConstants.shopCols),
                spacing: LayoutConstants.shopGap
            ) {
                if vm.selectedTab == 0 {
                    sectionedItemsContent(vm)
                } else {
                    filteredItemsContent(vm)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceSM)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .contentMargins(.bottom, showMerchant ? 80 : 0, for: .scrollContent)
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = abs(value.translation.height)
                    guard abs(horizontal) > vertical * 1.5 else { return }
                    if horizontal < 0 && vm.selectedTab < ShopViewModel.tabs.count - 1 {
                        HapticManager.selection()
                        withAnimation(MotionConstants.tabIndicatorSlide) {
                            vm.selectedTab += 1
                        }
                    } else if horizontal > 0 && vm.selectedTab > 0 {
                        HapticManager.selection()
                        withAnimation(MotionConstants.tabIndicatorSlide) {
                            vm.selectedTab -= 1
                        }
                    }
                }
        )
    }

    // MARK: - Sectioned Items (All tab)

    @ViewBuilder
    private func sectionedItemsContent(_ vm: ShopViewModel) -> some View {
        ForEach(vm.sectionedItems) { section in
            Section {
                ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                    shopItemCard(vm: vm, item: item, index: index)
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
    }

    // MARK: - Filtered Items (category tabs)

    @ViewBuilder
    private func filteredItemsContent(_ vm: ShopViewModel) -> some View {
        ForEach(Array(vm.filteredItems.enumerated()), id: \.element.id) { index, item in
            shopItemCard(vm: vm, item: item, index: index)
        }
    }

    // MARK: - Single Shop Item Card

    private func shopItemCard(vm: ShopViewModel, item: ShopItem, index: Int) -> some View {
        ItemCardView(
            shopItem: item,
            context: .shop(
                price: item.isGemPurchase ? item.gemPrice : item.goldPrice,
                isGem: item.isGemPurchase,
                canAfford: vm.canAfford(item),
                meetsLevel: vm.meetsLevel(item),
                isBuying: vm.buyingItemId == item.id
            )
        ) { vm.selectItem(item) }
        .staggeredAppear(index: index)
    }

    // MARK: - Item Detail Overlay

    @ViewBuilder
    private func itemDetailOverlay(_ vm: ShopViewModel) -> some View {
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
                    price: shopItem.isGemPurchase ? shopItem.gemPrice : shopItem.goldPrice,
                    isGemPurchase: shopItem.isGemPurchase,
                    canAfford: vm.canAfford(shopItem),
                    meetsLevel: vm.meetsLevel(shopItem),
                    isBuying: vm.buyingItemId == shopItem.id,
                    requiredLevel: shopItem.requiredLevel,
                    onBuy: { vm.requestBuy(shopItem) }
                ),
                playerLevel: vm.playerLevel
            )
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: vm.showItemDetail)
        }
    }

    // MARK: - Merchant Overlay

    @ViewBuilder
    private func merchantOverlay() -> some View {
        // NPC Guide Widget — equal padding like UnifiedHeroWidget
        if showMerchant {
            VStack {
                Spacer()
                NPCGuideWidget(
                    npcTitle: "Merchant",
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showMerchant = false
                        }
                    },
                    npcImageName: "shopkeeper",
                    attributedMessage: tipProvider.currentTip.attributedText,
                    onTapCard: { tipProvider.nextTip() },
                    messageId: AnyHashable(tipProvider.currentTip)
                )
                .padding(.horizontal, LayoutConstants.npcOuterPadding)
                .padding(.bottom, LayoutConstants.npcOuterPadding)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        // Collapsed merchant mini avatar
        if showMerchantMini {
            VStack {
                Spacer()
                HStack {
                    NPCMiniButton(npcImageName: "shopkeeper", onTap: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showMerchantMini = false
                            showMerchant = true
                        }
                    })
                    .padding(.leading, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceMD)
                    Spacer()
                }
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
}
