import SwiftUI
import StoreKit

// MARK: - Currency Package Models

struct CurrencyPackage: Identifiable {
    let id: String
    let currencyType: CurrencyType
    let amount: Int
    let bonusAmount: Int
    let priceUSD: String
    let productId: String // StoreKit product ID
    let isBestValue: Bool
    let isPopular: Bool
    let isSubscription: Bool

    init(id: String, currencyType: CurrencyType, amount: Int, bonusAmount: Int,
         priceUSD: String, productId: String, isBestValue: Bool, isPopular: Bool,
         isSubscription: Bool = false) {
        self.id = id
        self.currencyType = currencyType
        self.amount = amount
        self.bonusAmount = bonusAmount
        self.priceUSD = priceUSD
        self.productId = productId
        self.isBestValue = isBestValue
        self.isPopular = isPopular
        self.isSubscription = isSubscription
    }

    var totalAmount: Int { amount + bonusAmount }
    var displayAmount: String {
        if totalAmount >= 1000 {
            let k = Double(totalAmount) / 1000.0
            return k.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(k))K" : String(format: "%.1fK", k)
        }
        return "\(totalAmount)"
    }

    enum CurrencyType: String {
        case gold, gems
        var icon: String { self == .gold ? "💰" : "💎" }
        var label: String { self == .gold ? "GOLD" : "GEMS" }
        var accentColor: Color { self == .gold ? DarkFantasyTheme.goldBright : DarkFantasyTheme.cyan }
    }
}

// MARK: - Purchase State

enum PurchaseState: Equatable {
    case idle
    case purchasing(packageId: String)
    case success(packageId: String)
    case failed(message: String)
}

// MARK: - CurrencyPurchaseView

struct CurrencyPurchaseView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Int = 0
    @State private var purchaseState: PurchaseState = .idle
    @State private var showSuccessOverlay = false
    @State private var successMessage = "Currency has been added to your account."

    private let tabs = ["GOLD", "GEMS", "SPECIAL"]

    // Gold packages
    private let goldPackages: [CurrencyPackage] = [
        .init(id: "gold_500", currencyType: .gold, amount: 500, bonusAmount: 0,
              priceUSD: "$0.99", productId: "com.hexbound.gold500", isBestValue: false, isPopular: false),
        .init(id: "gold_1200", currencyType: .gold, amount: 1000, bonusAmount: 200,
              priceUSD: "$1.99", productId: "com.hexbound.gold1200", isBestValue: false, isPopular: true),
        .init(id: "gold_3500", currencyType: .gold, amount: 3000, bonusAmount: 500,
              priceUSD: "$4.99", productId: "com.hexbound.gold3500", isBestValue: true, isPopular: false),
        .init(id: "gold_8000", currencyType: .gold, amount: 7000, bonusAmount: 1000,
              priceUSD: "$9.99", productId: "com.hexbound.gold8000", isBestValue: false, isPopular: false),
        .init(id: "gold_20000", currencyType: .gold, amount: 17000, bonusAmount: 3000,
              priceUSD: "$19.99", productId: "com.hexbound.gold20000", isBestValue: false, isPopular: false),
    ]

    // Gem packages — aligned with PROJECT_KNOWLEDGE IAP
    private let gemPackages: [CurrencyPackage] = [
        .init(id: "gems_small", currencyType: .gems, amount: 100, bonusAmount: 0,
              priceUSD: "$0.99", productId: "com.hexbound.gems_small", isBestValue: false, isPopular: false),
        .init(id: "gems_medium", currencyType: .gems, amount: 500, bonusAmount: 50,
              priceUSD: "$4.99", productId: "com.hexbound.gems_medium", isBestValue: false, isPopular: true),
        .init(id: "gems_large", currencyType: .gems, amount: 1000, bonusAmount: 200,
              priceUSD: "$9.99", productId: "com.hexbound.gems_large", isBestValue: true, isPopular: false),
        .init(id: "gems_mega", currencyType: .gems, amount: 5000, bonusAmount: 1500,
              priceUSD: "$49.99", productId: "com.hexbound.gems_mega", isBestValue: false, isPopular: false),
    ]

    private var currentPackages: [CurrencyPackage] {
        switch selectedTab {
        case 0: return goldPackages
        case 1: return gemPackages
        default: return []
        }
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Tab switcher
                TabSwitcher(
                    tabs: tabs,
                    selectedIndex: $selectedTab
                )
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.top, LayoutConstants.spaceSM)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: LayoutConstants.spaceMD) {
                        if selectedTab < 2 {
                            // Gold / Gems tab
                            currencyHeader

                            ForEach(currentPackages) { pkg in
                                CurrencyPackageCard(
                                    package: pkg,
                                    purchaseState: purchaseState,
                                    onBuy: { buyPackage(pkg) }
                                )
                            }
                        } else {
                            // Special tab — Monthly Gem Card + Premium
                            specialOffersContent
                        }

                        // Restore purchases
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
                    .padding(.top, LayoutConstants.spaceMD)
                }
            }

            // Error toast
            if case .failed(let message) = purchaseState {
                VStack {
                    Spacer()
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DarkFantasyTheme.danger)
                        Text(message)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                    }
                    .padding(LayoutConstants.spaceMD)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .fill(DarkFantasyTheme.bgElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .stroke(DarkFantasyTheme.danger.opacity(0.5), lineWidth: 1)
                    )
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceLG)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { purchaseState = .idle }
                    }
                }
            }

            // Success overlay
            if showSuccessOverlay {
                successOverlay
                    .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("GET CURRENCY")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
    }

    // MARK: - Currency Header

    @ViewBuilder
    private var currencyHeader: some View {
        let isGold = selectedTab == 0
        VStack(spacing: LayoutConstants.spaceSM) {
            Text(isGold ? "💰" : "💎")
                .font(.system(size: 48)) // emoji — keep

            Text(isGold ? "GOLD TREASURY" : "GEM VAULT")
                .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                .foregroundStyle(isGold ? DarkFantasyTheme.goldBright : DarkFantasyTheme.cyan)

            Text(isGold
                 ? "Gold fuels your journey — buy gear, potions, and upgrades."
                 : "Gems unlock premium content — skins, boosts, and rare items.")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LayoutConstants.spaceLG)
        }
        .padding(.vertical, LayoutConstants.spaceMD)
    }

    // MARK: - Special Offers (Monthly Gem Card + Premium Unlock)

    @ViewBuilder
    private var specialOffersContent: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            // Monthly Gem Card
            MonthlyGemCardOffer(
                purchaseState: purchaseState,
                onBuy: { buyMonthlyGemCard() }
            )

            // Divider
            HStack {
                Rectangle()
                    .fill(DarkFantasyTheme.borderSubtle)
                    .frame(height: 1)
                Text("OR")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Rectangle()
                    .fill(DarkFantasyTheme.borderSubtle)
                    .frame(height: 1)
            }

            // Premium One-Time
            PremiumUnlockCard(
                onBuy: { appState.mainPath.append(AppRoute.premiumPurchase) }
            )
        }
        .padding(.top, LayoutConstants.spaceMD)
    }

    // MARK: - Success Overlay

    @ViewBuilder
    private var successOverlay: some View {
        ZStack {
            DarkFantasyTheme.bgModal.ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64)) // SF Symbol icon — keep
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text("PURCHASE COMPLETE")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text(successMessage)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Button("CONTINUE") {
                    withAnimation { showSuccessOverlay = false }
                    purchaseState = .idle
                }
                .buttonStyle(.primary)
                .padding(.horizontal, LayoutConstants.spaceXL)
            }
            .padding(LayoutConstants.spaceLG)
        }
    }

    // MARK: - Purchase Actions

    private func buyPackage(_ pkg: CurrencyPackage) {
        guard purchaseState == .idle else { return }

        withAnimation { purchaseState = .purchasing(packageId: pkg.id) }
        successMessage = "\(pkg.currencyType.label) has been added to your account."

        Task {
            do {
                let transaction = try await StoreKitService.shared.purchase(productId: pkg.productId)
                // Verify with server & credit currency
                let body = IAPVerifyRequest(
                    productId: pkg.id,
                    transactionId: String(transaction.id),
                    receiptData: String(transaction.id)
                )
                let _: IAPVerifyResponse = try await APIClient.shared.post("/api/iap/verify", body: body)

                await MainActor.run {
                    withAnimation {
                        purchaseState = .success(packageId: pkg.id)
                        showSuccessOverlay = true
                    }
                    appState.invalidateCache("character")
                }
            } catch let error as StoreKitError where error == .purchaseCancelled {
                await MainActor.run {
                    withAnimation { purchaseState = .idle }
                }
            } catch {
                await MainActor.run {
                    withAnimation { purchaseState = .failed(message: error.localizedDescription) }
                }
            }
        }
    }

    private func buyMonthlyGemCard() {
        guard purchaseState == .idle else { return }

        withAnimation { purchaseState = .purchasing(packageId: "monthly_gem_card") }
        successMessage = "50 gems added now! You'll receive 10 gems daily for 30 days."

        Task {
            do {
                let transaction = try await StoreKitService.shared.purchase(
                    productId: IAPProduct.monthlyGemCard.rawValue
                )
                let body = IAPVerifyRequest(
                    productId: "monthly_gem_card",
                    transactionId: String(transaction.id),
                    receiptData: String(transaction.id)
                )
                let _: IAPVerifyResponse = try await APIClient.shared.post("/api/iap/verify", body: body)

                await MainActor.run {
                    withAnimation {
                        purchaseState = .success(packageId: "monthly_gem_card")
                        showSuccessOverlay = true
                    }
                    appState.invalidateCache("character")
                }
            } catch let error as StoreKitError where error == .purchaseCancelled {
                await MainActor.run {
                    withAnimation { purchaseState = .idle }
                }
            } catch {
                await MainActor.run {
                    withAnimation { purchaseState = .failed(message: error.localizedDescription) }
                }
            }
        }
    }

    private func restorePurchases() {
        Task {
            await StoreKitService.shared.restorePurchases()
            appState.showToast("Purchases restored!", type: .reward)
        }
    }
}

// MARK: - Currency Package Card

struct CurrencyPackageCard: View {
    let package: CurrencyPackage
    let purchaseState: PurchaseState
    let onBuy: () -> Void

    private var isPurchasing: Bool {
        if case .purchasing(let id) = purchaseState { return id == package.id }
        return false
    }

    private var accentColor: Color { package.currencyType.accentColor }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Currency icon + amount
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(package.currencyType.icon)
                        .font(.system(size: 28)) // emoji — keep
                    VStack(alignment: .leading, spacing: 0) {
                        Text(package.displayAmount)
                            .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                            .foregroundStyle(accentColor)
                        if package.bonusAmount > 0 {
                            Text("+\(package.bonusAmount) BONUS")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                .foregroundStyle(DarkFantasyTheme.textSuccess)
                        }
                    }
                }
            }

            Spacer(minLength: 4)

            // Badges
            if package.isBestValue {
                Text("BEST VALUE")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(DarkFantasyTheme.goldGradient)
                    )
            } else if package.isPopular {
                Text("POPULAR")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(DarkFantasyTheme.purple)
                    )
            }

            // Buy button
            Button(action: onBuy) {
                if isPurchasing {
                    ProgressView()
                        .tint(DarkFantasyTheme.textOnGold)
                        .frame(width: 72, height: 40)
                } else {
                    Text(package.priceUSD)
                        .frame(width: 72, height: 40)
                }
            }
            .buttonStyle(.compactPrimary)
            .disabled(isPurchasing)
            .contentShape(Rectangle())
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(package.isBestValue ? accentColor.opacity(0.08) : DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    package.isBestValue ? accentColor.opacity(0.5) : DarkFantasyTheme.borderSubtle,
                    lineWidth: package.isBestValue ? 2 : 1
                )
        )
        .shadow(color: package.isBestValue ? accentColor.opacity(0.15) : .clear, radius: 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Monthly Gem Card Offer

struct MonthlyGemCardOffer: View {
    let purchaseState: PurchaseState
    let onBuy: () -> Void

    private var isPurchasing: Bool {
        if case .purchasing(let id) = purchaseState { return id == "monthly_gem_card" }
        return false
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Header
            HStack(spacing: LayoutConstants.spaceSM) {
                Text("💎")
                    .font(.system(size: 36)) // emoji — keep
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text("MONTHLY GEM CARD")
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                        .foregroundStyle(DarkFantasyTheme.cyan)
                    Text("Best daily value!")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSuccess)
                }
                Spacer()
                // Badge
                Text("350 GEMS")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(DarkFantasyTheme.cyan.opacity(0.3))
                    )
            }

            // Breakdown
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "gift.fill")
                        .foregroundStyle(DarkFantasyTheme.cyan)
                        .font(.system(size: 14))
                    Text("50 gems instantly upon purchase")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                }
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "calendar")
                        .foregroundStyle(DarkFantasyTheme.cyan)
                        .font(.system(size: 14))
                    Text("10 gems daily for 30 days (300 total)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                }
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .font(.system(size: 14))
                    Text("7x more value than buying gems directly!")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSuccess)
                }
            }
            .padding(.horizontal, LayoutConstants.spaceSM)

            // Buy button
            Button(action: onBuy) {
                if isPurchasing {
                    ProgressView()
                        .tint(DarkFantasyTheme.textOnGold)
                        .frame(maxWidth: .infinity)
                        .frame(height: LayoutConstants.buttonHeightLG)
                } else {
                    Text("GET FOR $4.99")
                        .frame(maxWidth: .infinity)
                        .frame(height: LayoutConstants.buttonHeightLG)
                }
            }
            .buttonStyle(.primary)
            .disabled(isPurchasing)
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.cyan.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.cyan.opacity(0.4), lineWidth: 2)
        )
        .shadow(color: DarkFantasyTheme.cyan.opacity(0.1), radius: 12)
    }
}

// MARK: - Premium Unlock Card (Teaser — navigates to full screen)

struct PremiumUnlockCard: View {
    let onBuy: () -> Void

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Header
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(DarkFantasyTheme.premiumPink)
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text("UPGRADE TO PREMIUM")
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                        .foregroundStyle(DarkFantasyTheme.premiumPink)
                    Text("One-time purchase — unlock forever")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                Spacer()
            }

            // Quick benefits preview
            HStack(spacing: LayoutConstants.spaceSM) {
                PremiumBenefitChip(icon: "bolt.fill", text: "+20% XP")
                PremiumBenefitChip(icon: "dollarsign.circle.fill", text: "+20% Gold")
                PremiumBenefitChip(icon: "sparkles", text: "Exclusive")
            }

            // CTA
            Button(action: onBuy) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                    Text("VIEW DETAILS")
                }
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.buttonHeightLG)
            }
            .buttonStyle(PremiumButtonStyle())
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgPremium.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.premiumPink.opacity(0.4), lineWidth: 2)
        )
        .shadow(color: DarkFantasyTheme.premiumPink.opacity(0.1), radius: 12)
    }
}

// MARK: - Premium Benefit Chip

struct PremiumBenefitChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
        }
        .foregroundStyle(DarkFantasyTheme.premiumPink)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(DarkFantasyTheme.premiumPink.opacity(0.12))
        )
    }
}

// MARK: - Premium Button Style

struct PremiumButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    private let gradient = LinearGradient(
        colors: [DarkFantasyTheme.purple, DarkFantasyTheme.premiumPink],
        startPoint: .leading,
        endPoint: .trailing
    )

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(isEnabled ? AnyShapeStyle(gradient) : AnyShapeStyle(DarkFantasyTheme.bgDisabled))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.premiumPink.opacity(0.6), lineWidth: 2)
            )
            .shadow(color: DarkFantasyTheme.premiumPink.opacity(0.3), radius: 12, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
