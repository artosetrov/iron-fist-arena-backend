import SwiftUI
import StoreKit

// MARK: - CurrencyPurchaseView

/// GET CURRENCY — the real-money shop: bundles, gem packs and the two
/// recurring offers. Cards live in CurrencyOfferCards.swift, the "purchase
/// complete" ceremony in PurchaseRewardRevealView.swift.
struct CurrencyPurchaseView: View {
    var initialTab: Int = 0
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    // Observed so prices re-render when StoreKit finishes loading products.
    @ObservedObject private var store = StoreKitService.shared
    @State private var selectedTab: Int = 0
    @State private var purchaseState: PurchaseState = .idle
    @State private var reveal: PurchaseRevealContent?
    @State private var productLoadFinished = false

    /// Starter Bundle availability and Monthly Gem Card terms/status, from
    /// GET /api/iap/offers. Observable, so the cards follow it.
    private var offers: IAPOffersService { .shared }

    private let tabs = ["BUNDLES", "GEMS", "SPECIAL"]

    private static let monthlyGemCardOfferId = "monthly_gem_card"

    // Contents mirror IAP_PRODUCTS in backend/src/lib/game/balance.ts.

    // Once per account: hidden after the first purchase (IAPOffersService).
    private let starterBundle = CurrencyPackage(
        id: "starter_bundle", currencyType: .gold, amount: 3000,
        productId: IAPProduct.starterBundle.rawValue, title: "Starter Bundle",
        extras: [.gems(200)]
    )

    // Adventurer's Bundles (Economy v3). The old flat gold packs (gold_500 …
    // gold_20000) are retired: the backend returns 410 for them, so listing
    // them charged the player and delivered nothing.
    // BEST VALUE is on III: per dollar it matches II on gold and beats it on
    // gems (+14%) and Legendary Shards (2.5×); II only leads on scrolls.
    private let adventurerBundles: [CurrencyPackage] = [
        .init(id: "adventurer_bundle_I", currencyType: .gold, amount: 3000,
              productId: IAPProduct.adventurerBundleI.rawValue, title: "Adventurer's Bundle I",
              extras: [.gems(600), .protectionScrolls(1)]),
        .init(id: "adventurer_bundle_II", currencyType: .gold, amount: 10000,
              productId: IAPProduct.adventurerBundleII.rawValue, title: "Adventurer's Bundle II",
              extras: [.gems(1400), .protectionScrolls(3), .legendaryShards(1)]),
        .init(id: "adventurer_bundle_III", currencyType: .gold, amount: 20000,
              productId: IAPProduct.adventurerBundleIII.rawValue, title: "Adventurer's Bundle III",
              isBestValue: true,
              extras: [.gems(3200), .protectionScrolls(5), .legendaryShards(5)]),
    ]

    // Gem packs — docs/02_product_and_features/ECONOMY.md. Every pack is ~100
    // gems per dollar before its bonus, so the biggest bonus is the best value.
    private let gemPackages: [CurrencyPackage] = [
        .init(id: "gems_small", currencyType: .gems, amount: 100,
              productId: IAPProduct.gemsSmall.rawValue),
        .init(id: "gems_medium", currencyType: .gems, amount: 500, bonusAmount: 50,
              productId: IAPProduct.gemsMedium.rawValue, isPopular: true),
        .init(id: "gems_large", currencyType: .gems, amount: 1000, bonusAmount: 200,
              productId: IAPProduct.gemsLarge.rawValue),
        .init(id: "gems_huge", currencyType: .gems, amount: 2000, bonusAmount: 500,
              productId: IAPProduct.gemsHuge.rawValue),
        .init(id: "gems_mega", currencyType: .gems, amount: 5000, bonusAmount: 1500,
              productId: IAPProduct.gemsMega.rawValue, isBestValue: true),
    ]

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                balanceBar

                TabSwitcher(
                    tabs: tabs,
                    selectedIndex: $selectedTab
                )
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.vertical, LayoutConstants.tabSwitcherPaddingV)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: LayoutConstants.sectionGap) {
                        // Kill switch (admin → Feature Flags → iap_enabled). The
                        // server rejects receipts too; this keeps the player from
                        // paying Apple for something we cannot grant right now.
                        if !cache.isKillSwitchOn("iap_enabled") {
                            purchasesPausedNotice
                        }

                        switch selectedTab {
                        case 0: bundlesTab
                        case 1: gemsTab
                        default: specialTab
                        }

                        Button {
                            restorePurchases()
                        } label: {
                            Text("RESTORE PURCHASES")
                        }
                        .buttonStyle(.ghost)
                        .padding(.top, LayoutConstants.spaceSM)
                        .padding(.bottom, LayoutConstants.spaceLG)
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    // Room above the first card for its ribbon.
                    .padding(.top, LayoutConstants.spaceLG)
                }
            }

            if let reveal {
                PurchaseRewardRevealView(content: reveal) {
                    withAnimation(.easeOut(duration: MotionConstants.overlayFade)) {
                        self.reveal = nil
                    }
                    purchaseState = .idle
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            if initialTab != 0 && initialTab < tabs.count {
                selectedTab = initialTab
            }
        }
        // StoreKit loads products once at init; if that attempt failed
        // (offline at launch) every price would stay unknown for the session.
        // Entering the screen retries it.
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
            }
            productLoadFinished = true
        }
        .task {
            await offers.refresh(userId: appState.currentUser?.id)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("GET CURRENCY")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
    }

    // MARK: - Balance

    /// Both balances, always — including a zero gem balance, which is exactly
    /// when the player is most likely to be on this screen.
    private var balanceBar: some View {
        HStack(spacing: LayoutConstants.spaceLG) {
            CurrencyDisplay(
                gold: appState.currentCharacter?.gold ?? 0,
                size: .standard,
                currencyType: .gold
            )
            Rectangle()
                .fill(DarkFantasyTheme.borderSubtle)
                .frame(width: 1, height: LayoutConstants.iconXL)
                .accessibilityHidden(true)
            CurrencyDisplay(
                gold: 0,
                gems: appState.currentCharacter?.gems ?? 0,
                size: .standard,
                currencyType: .gems
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(DarkFantasyTheme.bgSecondary)
        .overlay(alignment: .bottom) {
            EtchedGroove()
        }
    }

    private var purchasesPausedNotice: some View {
        Text("Purchases are temporarily unavailable. Please check back soon.")
            .font(DarkFantasyTheme.body)
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(LayoutConstants.cardPadding)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
    }

    // MARK: - Tabs

    @ViewBuilder
    private var bundlesTab: some View {
        if offers.isStarterBundleAvailable(for: appState.currentUser?.id) {
            StarterBundleCard(
                package: starterBundle,
                price: price(for: starterBundle.productId),
                priceLoading: isPriceLoading,
                isPurchasing: isPurchasing(starterBundle.id),
                onBuy: { buy(starterBundle) }
            )

            OrnamentalSectionHeader(title: "Adventurer's Bundles")
                .padding(.top, LayoutConstants.spaceSM)
        }

        ForEach(adventurerBundles) { pkg in
            BundleOfferCard(
                package: pkg,
                price: price(for: pkg.productId),
                priceLoading: isPriceLoading,
                isPurchasing: isPurchasing(pkg.id),
                onBuy: { buy(pkg) }
            )
        }
    }

    /// Two tiles per row; the last pack (the hoard) closes the grid full-width.
    @ViewBuilder
    private var gemsTab: some View {
        let tiles = Array(gemPackages.dropLast())

        ForEach(Array(stride(from: 0, to: tiles.count, by: 2)), id: \.self) { start in
            HStack(alignment: .top, spacing: LayoutConstants.spaceMS) {
                gemTile(tiles[start])
                if start + 1 < tiles.count {
                    gemTile(tiles[start + 1])
                } else {
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }

        if let hoard = gemPackages.last {
            GemPackWideCard(
                package: hoard,
                price: price(for: hoard.productId),
                priceLoading: isPriceLoading,
                isPurchasing: isPurchasing(hoard.id),
                onBuy: { buy(hoard) }
            )
        }
    }

    private func gemTile(_ pkg: CurrencyPackage) -> some View {
        GemPackTile(
            package: pkg,
            price: price(for: pkg.productId),
            priceLoading: isPriceLoading,
            isPurchasing: isPurchasing(pkg.id),
            onBuy: { buy(pkg) }
        )
    }

    @ViewBuilder
    private var specialTab: some View {
        MonthlyGemCardOffer(
            terms: offers.gemCard,
            valueLine: gemCardValueLine,
            price: price(for: IAPProduct.monthlyGemCard.rawValue),
            priceLoading: isPriceLoading,
            isPurchasing: isPurchasing(Self.monthlyGemCardOfferId),
            onBuy: { buyMonthlyGemCard() }
        )

        PremiumUnlockCard(
            price: price(for: IAPProduct.premiumPassMonthly.rawValue),
            onOpen: { appState.mainPath.append(AppRoute.premiumPurchase) }
        )
    }

    // MARK: - Prices

    /// Localized App Store price, or nil until StoreKit has the product.
    private func price(for productId: String) -> String? {
        store.products.first { $0.id == productId }?.displayPrice
    }

    /// True while the first product fetch is still running, so cards show a
    /// placeholder rather than a guessed price.
    private var isPriceLoading: Bool {
        store.products.isEmpty && !productLoadFinished
    }

    private func isPurchasing(_ offerId: String) -> Bool {
        purchaseState == .purchasing(packageId: offerId)
    }

    /// "Up to 3× the gems of the 550-gem pack, same price" (Economy Rule 10:
    /// show the value comparison). Only when StoreKit confirms both SKUs cost
    /// the same in this storefront; rounded down, never up.
    private var gemCardValueLine: String? {
        guard let pack = gemPackages.first(where: { $0.id == "gems_medium" }),
              let cardPrice = store.product(for: .monthlyGemCard)?.price,
              let packPrice = store.products.first(where: { $0.id == pack.productId })?.price,
              cardPrice == packPrice, pack.totalAmount > 0
        else { return nil }
        let multiple = (Double(offers.gemCard.maxGems) / Double(pack.totalAmount) * 10).rounded(.down) / 10
        guard multiple >= 1.5 else { return nil }
        let shown = multiple == multiple.rounded() ? String(Int(multiple)) : String(format: "%.1f", multiple)
        return "Up to \(shown)× the gems of the \(pack.totalAmount.formatted())-gem pack, same price"
    }

    // MARK: - Purchase Actions

    private func buy(_ pkg: CurrencyPackage) {
        startPurchase(productId: pkg.productId, offerId: pkg.id,
                      content: PurchaseRevealContent(package: pkg))
    }

    private func buyMonthlyGemCard() {
        startPurchase(productId: IAPProduct.monthlyGemCard.rawValue,
                      offerId: Self.monthlyGemCardOfferId,
                      content: .monthlyGemCard(terms: offers.gemCard))
    }

    private func startPurchase(productId: String, offerId: String, content: PurchaseRevealContent) {
        guard purchaseState == .idle else { return }
        guard cache.isKillSwitchOn("iap_enabled") else {
            appState.showToast("Purchases unavailable", subtitle: "Please check back soon", type: .info)
            return
        }

        withAnimation(MotionConstants.snappy) { purchaseState = .purchasing(packageId: offerId) }

        Task {
            do {
                // StoreKitService redeems on the server before finishing the
                // transaction, so reaching this line means the account was
                // actually credited.
                _ = try await store.purchase(productId: productId)
                await MainActor.run { celebrate(content, offerId: offerId) }
            } catch {
                await MainActor.run {
                    handlePurchaseFailure(error, content: content, offerId: offerId) {
                        startPurchase(productId: productId, offerId: offerId, content: content)
                    }
                }
            }
        }
    }

    private func celebrate(_ content: PurchaseRevealContent, offerId: String) {
        purchaseState = .success(packageId: offerId)
        appState.invalidateCache("character")
        updateOffers(after: offerId)
        withAnimation(.easeOut(duration: MotionConstants.overlayFade)) {
            reveal = content
        }
    }

    /// Optimistic: the Starter Bundle goes away and the Gem Card shows its new
    /// days at once; the refresh then takes the server's word for both.
    private func updateOffers(after offerId: String) {
        let userId = appState.currentUser?.id
        switch offerId {
        case starterBundle.id:
            offers.starterBundleBought(userId: userId)
        case Self.monthlyGemCardOfferId:
            offers.gemCardBought()
        default:
            return
        }
        Task { await offers.refresh(userId: userId) }
    }

    /// Routes a failed purchase to the right message. Once Apple has charged,
    /// "Retry" must never start a new purchase — that would charge twice.
    private func handlePurchaseFailure(
        _ error: Error,
        content: PurchaseRevealContent,
        offerId: String,
        retryPurchase: @escaping () -> Void
    ) {
        withAnimation(MotionConstants.snappy) { purchaseState = .idle }

        switch error as? StoreKitError {
        case .purchaseCancelled?:
            return

        case .pending?:
            // Ask to Buy / bank confirmation: not a failure. The transaction
            // listener credits it once it is approved.
            appState.showToast(
                "Waiting for approval",
                subtitle: "Your purchase arrives as soon as it's approved.",
                type: .info
            )

        case .deliveryDeferred?:
            appState.showToast(
                "Payment received — delivery delayed",
                subtitle: "It will arrive automatically. Retry to deliver it now.",
                type: .error,
                actionLabel: "Retry",
                action: { retryDelivery(content: content, offerId: offerId) }
            )

        case .unknownProduct?, .verificationFailed?:
            // Charged but permanently undeliverable. No Retry on purpose
            // (exception to the toast rule): buying again would charge again.
            appState.showToast(
                "Purchase couldn't be delivered",
                subtitle: "Your receipt is saved. Please contact support.",
                type: .error
            )

        case .productNotFound?, .purchaseFailed?:
            appState.showToast(
                "Purchase failed",
                subtitle: error.localizedDescription,
                type: .error,
                actionLabel: "Retry",
                action: retryPurchase
            )

        case nil:
            // StoreKit failed before charging (network, App Store unavailable),
            // so buying again is the right retry.
            appState.showToast(
                "Purchase failed",
                subtitle: "Check your connection and try again.",
                type: .error,
                actionLabel: "Retry",
                action: retryPurchase
            )
        }
    }

    /// Retry for `.deliveryDeferred`: hands the unfinished transaction back to
    /// the server instead of buying again.
    private func retryDelivery(content: PurchaseRevealContent, offerId: String) {
        guard purchaseState == .idle else { return }
        withAnimation(MotionConstants.snappy) { purchaseState = .purchasing(packageId: offerId) }

        Task {
            let result = await store.redeemUnfinished()
            await MainActor.run {
                if result.hasUnresolved {
                    withAnimation(MotionConstants.snappy) { purchaseState = .idle }
                    appState.showToast(
                        "Still couldn't deliver it",
                        subtitle: "Check your connection. It will also arrive automatically.",
                        type: .error,
                        actionLabel: "Retry",
                        action: { retryDelivery(content: content, offerId: offerId) }
                    )
                } else if result.hasUndeliverable {
                    withAnimation(MotionConstants.snappy) { purchaseState = .idle }
                    appState.showToast(
                        "Purchase couldn't be delivered",
                        subtitle: "Your receipt is saved. Please contact support.",
                        type: .error
                    )
                } else {
                    // Redeemed now, or already credited by an earlier attempt.
                    celebrate(content, offerId: offerId)
                }
            }
        }
    }

    private func restorePurchases() {
        Task {
            let result = await store.restorePurchases()
            await MainActor.run {
                if result.hasUnresolved {
                    appState.showToast(
                        "Some purchases couldn't be restored",
                        subtitle: "Check your connection and try again.",
                        type: .error,
                        actionLabel: "Retry",
                        action: { restorePurchases() }
                    )
                } else if result.hasUndeliverable {
                    // Permanent — retrying cannot help, so no Retry.
                    appState.showToast(
                        "A purchase couldn't be delivered",
                        subtitle: "Please contact support with your receipt.",
                        type: .error
                    )
                } else if result.recoveredPurchases > 0 {
                    appState.invalidateCache("character")
                    appState.showToast(
                        "Purchases restored",
                        subtitle: "Your account has been credited.",
                        type: .reward
                    )
                } else {
                    appState.showToast(
                        "You're all set",
                        subtitle: "Everything you bought has already been delivered.",
                        type: .info
                    )
                }
            }
        }
    }
}
