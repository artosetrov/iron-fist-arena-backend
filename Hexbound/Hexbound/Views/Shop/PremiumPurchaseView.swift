import SwiftUI
import StoreKit

// MARK: - Premium Feature

struct PremiumFeature: Identifiable {
    let id = UUID()
    let icon: String       // SF Symbol name or asset name
    let title: String
    let description: String
    let highlight: Bool    // gold accent for key features
    var assetIcon: Bool = false  // whether icon is from asset catalog
}

// MARK: - PremiumPurchaseView

struct PremiumPurchaseView: View {
    @Environment(AppState.self) private var appState
    // Observed so the view re-renders when StoreKit finishes loading products —
    // otherwise the legally-binding price in the disclosure below stays on its
    // hardcoded USD fallback in every storefront.
    @ObservedObject private var store = StoreKitService.shared
    @State private var purchaseState: PurchaseState = .idle
    @State private var showSuccessOverlay = false
    @State private var shimmerOffset: CGFloat = -200

    // Economy v3: `premium_forever` is retired (backend returns 410).
    // Premium is now a 30-day auto-renewable pass — see
    // docs/06_game_systems/PREMIUM_PASS_MIGRATION.md.
    private let productId = IAPProduct.premiumPassMonthly.rawValue

    /// Localized App Store price, or nil while StoreKit is still loading.
    private var storePrice: String? {
        let formatted = store.formattedPrice(for: .premiumPassMonthly)
        return formatted == "—" ? nil : formatted
    }

    /// Price for display. Shows a placeholder rather than a guessed figure:
    /// quoting the US list price to a player in another storefront is a false
    /// price claim, and App Store review reads the displayed price.
    private var price: String { storePrice ?? "—" }

    // Only benefits the server actually grants. Until 2026-10-14 this list
    // promised nine; the backend implemented two. A paid auto-renewing
    // subscription whose purchase screen lists benefits it does not deliver is
    // a Guideline 3.1.2 problem as well as a broken promise — add a row here
    // only once the corresponding server code exists.
    private let features: [PremiumFeature] = [
        .init(icon: "bolt.fill", title: "+20% XP from arena fights",
              description: "Every PvP win and loss grants 20% more experience.",
              highlight: true),
        .init(icon: "icon-gold", title: "+10% Gold from battles",
              description: "Arena fights, dungeons, Dungeon Rush and duels all pay 10% more gold.",
              highlight: true, assetIcon: true),
        .init(icon: "shield.lefthalf.filled", title: "5 Free PvP fights per day",
              description: "Two extra stamina-free arena fights daily (up from 3).",
              highlight: false),
        .init(icon: "icon-gems", title: "300 gems every month",
              description: "Each renewal credits 300 gems to your account on top of every other benefit.",
              highlight: true, assetIcon: true),
        .init(icon: "gift.fill", title: "+25 gems with your daily login",
              description: "Claim 25 extra gems every day you log in while your pass is active.",
              highlight: false),
    ]

    private var isPurchasing: Bool {
        if case .purchasing = purchaseState { return true }
        return false
    }

    var body: some View {
        ZStack {
            // Background
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            // Subtle premium ambient glow at top
            VStack {
                RadialGradient(
                    gradient: Gradient(colors: [
                        DarkFantasyTheme.premiumPink.opacity(0.08),
                        .clear
                    ]),
                    center: .top,
                    startRadius: 0,
                    endRadius: 300
                )
                .frame(height: 300)
                .ignoresSafeArea()
                Spacer()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero section
                    premiumHero
                        .padding(.top, LayoutConstants.spaceMD)
                        .padding(.bottom, LayoutConstants.spaceLG)

                    // Features list
                    VStack(spacing: LayoutConstants.spaceSM) {
                        ForEach(features) { feature in
                            PremiumFeatureRow(feature: feature)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)

                    // Comparison
                    premiumComparison
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.top, LayoutConstants.spaceLG)

                    // Purchase CTA
                    purchaseSection
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.top, LayoutConstants.spaceLG)
                        .padding(.bottom, LayoutConstants.space2XL)
                }
            }

            // Success overlay
            if showSuccessOverlay {
                premiumSuccessOverlay
                    .transition(.opacity)
            }
        }
        // StoreKit loads products once at init; if that first attempt failed
        // (offline at launch) the price would stay unknown for the whole
        // session. Re-entering the screen retries it.
        .task { await store.loadProducts() }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(DarkFantasyTheme.premiumPink)
                        .font(DarkFantasyTheme.body)
                    Text("PREMIUM")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.premiumPink)
                }
            }
        }
    }

    // MARK: - Premium Hero

    @ViewBuilder
    private var premiumHero: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Crown icon with glow
            ZStack {
                Circle()
                    .fill(DarkFantasyTheme.premiumPink.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                Image(systemName: "crown.fill")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DarkFantasyTheme.premiumPink, DarkFantasyTheme.goldBright],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("BECOME PREMIUM")
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(DarkFantasyTheme.premiumPink)

            Text("Auto-renewing monthly subscription. Cancel anytime.")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            // Price pill
            HStack(spacing: LayoutConstants.spaceXS) {
                Text(price)
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text("PER MONTH")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            .padding(.horizontal, LayoutConstants.spaceLG)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                Capsule().fill(DarkFantasyTheme.bgPremium)
            )
            .overlay(
                Capsule().stroke(DarkFantasyTheme.premiumPink.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: - Free vs Premium Comparison

    @ViewBuilder
    private var premiumComparison: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("FREE VS PREMIUM")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.goldBright)

            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Feature")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Free")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .frame(width: 60)
                    Text("Premium")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.premiumPink)
                        .frame(width: 70)
                }
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.vertical, LayoutConstants.spaceSM)
                .background(DarkFantasyTheme.bgTertiary)

                // Comparison rows
                ComparisonRow(label: "Arena XP", free: "0%", premium: "+20%")
                ComparisonRow(label: "Battle Gold", free: "0%", premium: "+10%")
                ComparisonRow(label: "Monthly Gems", free: "0", premium: "300")
                ComparisonRow(label: "Free PvP/day", free: "3", premium: "5")
                ComparisonRow(label: "Daily Login Gems", free: "—", premium: "+25")
            }
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
        }
    }

    // MARK: - Purchase Section

    @ViewBuilder
    private var purchaseSection: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Button {
                buyPremium()
            } label: {
                if isPurchasing {
                    HexPulseLoader(.compact)
                        .tint(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: LayoutConstants.buttonHeightLG)
                } else {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "crown.fill")
                            .font(DarkFantasyTheme.cardTitle)
                        Text("UNLOCK PREMIUM — \(price)")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.buttonHeightLG)
                }
            }
            .buttonStyle(PremiumButtonStyle())
            .disabled(isPurchasing)

            // Error message
            if case .failed(let message) = purchaseState {
                Text(message)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textDanger)
                    .multilineTextAlignment(.center)
            }

            // Restore
            Button {
                Task {
                    let result = await store.restorePurchases()
                    if result.hasUnresolved {
                        appState.showToast(
                            "Some purchases could not be restored. Check your connection and try again.",
                            type: .error
                        )
                    } else if result.hasUndeliverable {
                        appState.showToast(
                            "A purchase could not be delivered. Please contact support with your receipt.",
                            type: .error
                        )
                    } else if store.isPremium {
                        appState.showToast("Premium restored.", type: .reward)
                        appState.invalidateCache("character")
                    } else {
                        appState.showToast("No Premium purchase found.", type: .info)
                    }
                }
            } label: {
                Text("RESTORE PURCHASE")
            }
            .buttonStyle(.secondary)

            // Legal — App Store Review Guideline 3.1.2 requires the length of
            // the subscription, the per-period price, the auto-renew terms and
            // working Terms of Use / Privacy Policy links at the point of sale.
            // The price is only stated once StoreKit has the real storefront
            // price: quoting a guessed one here would be a false price claim.
            VStack(spacing: LayoutConstants.spaceSM) {
                Text(renewalTerms)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: LayoutConstants.spaceLG) {
                    if let eulaURL = URL(string: AppConstants.eulaURL) {
                        Link(destination: eulaURL) {
                            Text("Terms of Use")
                                .font(DarkFantasyTheme.body)
                                .underline()
                                .frame(minHeight: LayoutConstants.touchMin)
                                .contentShape(Rectangle())
                        }
                    }
                    if let privacyURL = URL(string: AppConstants.privacyURL) {
                        Link(destination: privacyURL) {
                            Text("Privacy Policy")
                                .font(DarkFantasyTheme.body)
                                .underline()
                                .frame(minHeight: LayoutConstants.touchMin)
                                .contentShape(Rectangle())
                        }
                    }
                }
                .tint(DarkFantasyTheme.goldBright)
            }
        }
    }

    /// Renewal disclosure. Names the real storefront price when StoreKit has
    /// it, and stays price-free until then rather than quoting a US figure to
    /// a player in another market.
    private var renewalTerms: String {
        let opening = storePrice.map { "\($0) per month." }
            ?? "Billed monthly at the price shown on the purchase sheet."
        return opening + " Payment is charged to your Apple Account at confirmation of purchase. "
            + "The subscription renews automatically unless cancelled at least 24 hours before the "
            + "end of the current period. Manage or cancel it any time in your Apple Account settings."
    }

    // MARK: - Success Overlay

    @ViewBuilder
    private var premiumSuccessOverlay: some View {
        ZStack {
            DarkFantasyTheme.bgModal.ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                ZStack {
                    Circle()
                        .fill(DarkFantasyTheme.premiumPink.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .blur(radius: 25)
                    Image(systemName: "crown.fill")
                        .font(DarkFantasyTheme.cinematicTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DarkFantasyTheme.premiumPink, DarkFantasyTheme.goldBright],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("WELCOME TO PREMIUM!")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .foregroundStyle(DarkFantasyTheme.premiumPink)

                Text("All Premium benefits are now active.\nEnjoy your enhanced adventure!")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Button("CONTINUE") {
                    withAnimation { showSuccessOverlay = false }
                    purchaseState = .idle
                    // Navigate back to hub
                    if !appState.mainPath.isEmpty {
                        appState.mainPath.removeLast()
                    }
                }
                .buttonStyle(.primary)
                .padding(.horizontal, LayoutConstants.spaceXL)
            }
            .padding(LayoutConstants.spaceLG)
        }
    }

    // MARK: - Buy Action

    private func buyPremium() {
        guard purchaseState == .idle else { return }
        withAnimation { purchaseState = .purchasing(packageId: "premium_pass_monthly") }

        Task {
            do {
                // Redemption happens inside StoreKitService, before the
                // transaction is finished — so getting here means the server
                // granted the pass.
                _ = try await store.purchase(productId: productId)

                await MainActor.run {
                    withAnimation {
                        purchaseState = .success(packageId: "premium_pass_monthly")
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
}

// MARK: - Premium Feature Row

struct PremiumFeatureRow: View {
    let feature: PremiumFeature

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Icon
            Group {
                if feature.assetIcon {
                    Image(feature.icon)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: feature.icon)
                }
            }
            .font(DarkFantasyTheme.section)
            .foregroundStyle(feature.highlight ? DarkFantasyTheme.goldBright : DarkFantasyTheme.premiumPink)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .fill(feature.highlight
                              ? DarkFantasyTheme.goldBright.opacity(0.1)
                              : DarkFantasyTheme.premiumPink.opacity(0.1))
                )

            // Text
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(feature.title)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(feature.highlight ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary)

                Text(feature.description)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(LayoutConstants.spaceSM + 2)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(feature.highlight
                      ? DarkFantasyTheme.bgElevated.opacity(0.6)
                      : DarkFantasyTheme.bgSecondary.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    feature.highlight
                    ? DarkFantasyTheme.goldBright.opacity(0.15)
                    : DarkFantasyTheme.borderSubtle.opacity(0.5),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Comparison Row

struct ComparisonRow: View {
    let label: String
    let free: String
    let premium: String

    var body: some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(free)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .frame(width: 60)
            Text(premium)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.premiumPink)
                .frame(width: 70)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(DarkFantasyTheme.bgSecondary.opacity(0.3))
    }
}
