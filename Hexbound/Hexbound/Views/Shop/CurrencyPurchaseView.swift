import SwiftUI

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

    private let tabs = ["GOLD", "GEMS"]

    // Mock packages — replace with StoreKit products
    private let goldPackages: [CurrencyPackage] = [
        .init(id: "gold_500", currencyType: .gold, amount: 500, bonusAmount: 0,
              priceUSD: "$0.99", productId: "com.ironfist.gold500", isBestValue: false, isPopular: false),
        .init(id: "gold_1200", currencyType: .gold, amount: 1000, bonusAmount: 200,
              priceUSD: "$1.99", productId: "com.ironfist.gold1200", isBestValue: false, isPopular: true),
        .init(id: "gold_3500", currencyType: .gold, amount: 3000, bonusAmount: 500,
              priceUSD: "$4.99", productId: "com.ironfist.gold3500", isBestValue: true, isPopular: false),
        .init(id: "gold_8000", currencyType: .gold, amount: 7000, bonusAmount: 1000,
              priceUSD: "$9.99", productId: "com.ironfist.gold8000", isBestValue: false, isPopular: false),
        .init(id: "gold_20000", currencyType: .gold, amount: 17000, bonusAmount: 3000,
              priceUSD: "$19.99", productId: "com.ironfist.gold20000", isBestValue: false, isPopular: false),
    ]

    private let gemPackages: [CurrencyPackage] = [
        .init(id: "gems_50", currencyType: .gems, amount: 50, bonusAmount: 0,
              priceUSD: "$0.99", productId: "com.ironfist.gems50", isBestValue: false, isPopular: false),
        .init(id: "gems_120", currencyType: .gems, amount: 100, bonusAmount: 20,
              priceUSD: "$1.99", productId: "com.ironfist.gems120", isBestValue: false, isPopular: true),
        .init(id: "gems_350", currencyType: .gems, amount: 300, bonusAmount: 50,
              priceUSD: "$4.99", productId: "com.ironfist.gems350", isBestValue: true, isPopular: false),
        .init(id: "gems_800", currencyType: .gems, amount: 700, bonusAmount: 100,
              priceUSD: "$9.99", productId: "com.ironfist.gems800", isBestValue: false, isPopular: false),
        .init(id: "gems_2000", currencyType: .gems, amount: 1700, bonusAmount: 300,
              priceUSD: "$19.99", productId: "com.ironfist.gems2000", isBestValue: false, isPopular: false),
    ]

    private var currentPackages: [CurrencyPackage] {
        selectedTab == 0 ? goldPackages : gemPackages
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

                // Package list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: LayoutConstants.spaceMD) {
                        // Header illustration
                        currencyHeader

                        // Package cards
                        ForEach(currentPackages) { pkg in
                            CurrencyPackageCard(
                                package: pkg,
                                purchaseState: purchaseState,
                                onBuy: { buyPackage(pkg) }
                            )
                        }

                        // Restore purchases
                        Button {
                            // TODO: Integrate StoreKit restore
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
                .font(.system(size: 48))

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

    // MARK: - Success Overlay

    @ViewBuilder
    private var successOverlay: some View {
        ZStack {
            DarkFantasyTheme.bgModal.ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text("PURCHASE COMPLETE")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text("Currency has been added to your account.")
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

    // MARK: - Purchase Action

    private func buyPackage(_ pkg: CurrencyPackage) {
        guard purchaseState == .idle else { return }

        withAnimation { purchaseState = .purchasing(packageId: pkg.id) }

        // TODO: Replace with real StoreKit 2 purchase flow
        // Example integration point:
        // Task {
        //     do {
        //         let result = try await StoreKitService.shared.purchase(productId: pkg.productId)
        //         let receipt = result.receiptData
        //         try await APIClient.shared.post("/api/iap/verify", body: ["receipt": receipt])
        //         withAnimation { purchaseState = .success(packageId: pkg.id) }
        //         showSuccessOverlay = true
        //     } catch {
        //         withAnimation { purchaseState = .failed(message: error.localizedDescription) }
        //     }
        // }

        // Mock: simulate 1.5s purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                purchaseState = .success(packageId: pkg.id)
                showSuccessOverlay = true
            }
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
                        .font(.system(size: 28))
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
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .frame(width: 72, height: 40)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(isPurchasing ? AnyShapeStyle(DarkFantasyTheme.goldDim) : AnyShapeStyle(DarkFantasyTheme.goldGradient))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.borderOrnament, lineWidth: 1)
            )
            .buttonStyle(.plain)
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
