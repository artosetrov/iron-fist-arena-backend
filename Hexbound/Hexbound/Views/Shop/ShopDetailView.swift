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
                                    .font(.system(size: 16, weight: .bold))
                                Text("GET MORE")
                            }
                        }
                        .buttonStyle(.getMore)
                        .shimmer(color: DarkFantasyTheme.goldBright, duration: 3)
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

                    // Content
                    if let error = vm.errorMessage {
                        ErrorStateView.loadFailed { await vm.loadItems() }
                    } else if vm.isLoading && vm.items.isEmpty {
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
                    } else if vm.filteredItems.isEmpty {
                        // TODO: Add error property to ShopViewModel
                        Spacer()
                        EmptyStateView.shopEmpty
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
                                            ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                                                ShopItemCardView(
                                                    item: item,
                                                    canAfford: vm.canAfford(item),
                                                    meetsLevel: vm.meetsLevel(item),
                                                    isBuying: vm.buyingItemId == item.id,
                                                    onTap: { vm.selectItem(item) }
                                                )
                                                .staggeredAppear(index: index)
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
                                    ForEach(Array(vm.filteredItems.enumerated()), id: \.element.id) { index, item in
                                        ShopItemCardView(
                                            item: item,
                                            canAfford: vm.canAfford(item),
                                            meetsLevel: vm.meetsLevel(item),
                                            isBuying: vm.buyingItemId == item.id,
                                            onTap: { vm.selectItem(item) }
                                        )
                                        .staggeredAppear(index: index)
                                    }
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.vertical, LayoutConstants.spaceSM)
                        }
<<<<<<< HEAD
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        // Bottom padding so items don't hide behind merchant
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
=======
                        // Bottom padding so items don't hide behind merchant
                        .contentMargins(.bottom, showMerchant ? 80 : 0, for: .scrollContent)
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
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

<<<<<<< HEAD
            // NPC Guide Widget — equal padding like UnifiedHeroWidget
            if showMerchant {
                VStack {
                    Spacer()
                    NPCGuideWidget(
                        npcTitle: "Merchant",
=======
            // Merchant overlay — pinned to bottom-left of screen, above all content
            if showMerchant {
                VStack {
                    Spacer()
                    MerchantStripView(
                        tipProvider: tipProvider,
                        onCollapse: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showMerchant = false
                                showMerchantMini = true
                            }
                        },
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showMerchant = false
                            }
<<<<<<< HEAD
                        },
                        npcImageName: "shopkeeper",
                        attributedMessage: tipProvider.currentTip.attributedText,
                        onTapCard: { tipProvider.nextTip() },
                        messageId: AnyHashable(tipProvider.currentTip)
                    )
                    .padding(.horizontal, LayoutConstants.npcOuterPadding)
                    .padding(.bottom, LayoutConstants.npcOuterPadding)
                }
=======
                        }
                    )
                }
                .ignoresSafeArea(edges: .bottom)
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Collapsed merchant mini avatar
            if showMerchantMini {
                VStack {
                    Spacer()
                    HStack {
<<<<<<< HEAD
                        NPCMiniButton(npcImageName: "shopkeeper", onTap: {
=======
                        MerchantMiniButton {
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                            withAnimation(.easeOut(duration: 0.3)) {
                                showMerchantMini = false
                                showMerchant = true
                            }
<<<<<<< HEAD
                        })
=======
                        }
>>>>>>> 42894bc5d3ff4f0da2a833ecefb491bd7e423e73
                        .padding(.leading, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceMD)
                        Spacer()
                    }
                }
                .transition(.scale.combined(with: .opacity))
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
