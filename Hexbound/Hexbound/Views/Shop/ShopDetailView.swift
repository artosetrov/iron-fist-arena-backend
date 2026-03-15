import SwiftUI

struct ShopDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: ShopViewModel?

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
                    // Currency bar
                    HStack(spacing: LayoutConstants.spaceMD) {
                        Spacer()
                        CurrencyDisplay(
                            gold: vm.gold,
                            gems: vm.gems,
                            showAddButton: true,
                            onAdd: { appState.mainPath.append(AppRoute.currencyPurchase) }
                        )
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.vertical, LayoutConstants.spaceSM)

                    // Merchant banner
                    ShopMerchantBanner()
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceSM)

                    // Active quest banner
                    ActiveQuestBanner(questTypes: ["gold_spent"])
                        .padding(.horizontal, LayoutConstants.screenPadding)

                    // Tab switcher
                    TabSwitcher(
                        tabs: ShopViewModel.tabs,
                        selectedIndex: Binding(
                            get: { vm.selectedTab },
                            set: { vm.selectedTab = $0 }
                        )
                    )
                    .padding(.horizontal, LayoutConstants.screenPadding)

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
                            onBuy: { Task { await vm.buy(shopItem) } }
                        )
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: vm.showItemDetail)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
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
                }
                vm = shopVM
            }
            await vm?.loadItems()
        }
    }
}

// MARK: - Shop Merchant Banner

struct ShopMerchantBanner: View {
    private let greetings = [
        "Welcome, warrior! Browse my finest wares.",
        "Ah, a customer! I have just what you need.",
        "Step closer, friend. Only the best in stock.",
        "Gold burns a hole in the pocket. Spend it wisely!"
    ]

    @State private var greeting: String = ""

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Merchant portrait — uses knight avatar with remote fallback
            Group {
                if UIImage(named: "avatar_knight") != nil {
                    Image("avatar_knight")
                        .resizable()
                        .scaledToFill()
                } else {
                    Text("🛒")
                        .font(.system(size: 28)) // emoji — keep
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(DarkFantasyTheme.gold.opacity(0.6), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("MERCHANT")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text(greeting)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(LayoutConstants.spaceSM + 2)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(
                    LinearGradient(
                        colors: [DarkFantasyTheme.bgSecondary, DarkFantasyTheme.bgTertiary.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            greeting = greetings.randomElement() ?? greetings[0]
        }
    }
}
