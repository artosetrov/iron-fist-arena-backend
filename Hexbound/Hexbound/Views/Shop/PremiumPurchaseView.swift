import SwiftUI
import StoreKit

// MARK: - Premium Feature

struct PremiumFeature: Identifiable {
    let id = UUID()
    let icon: String       // SF Symbol name
    let title: String
    let description: String
    let highlight: Bool    // gold accent for key features
}

// MARK: - PremiumPurchaseView

struct PremiumPurchaseView: View {
    @Environment(AppState.self) private var appState
    @State private var purchaseState: PurchaseState = .idle
    @State private var showSuccessOverlay = false
    @State private var shimmerOffset: CGFloat = -200

    private let price = "$9.99"
    private let productId = "com.hexbound.premium_forever"

    private let features: [PremiumFeature] = [
        .init(icon: "bolt.fill", title: "+20% XP from all sources",
              description: "Level up faster — PvP, dungeons, training, and quests all give 20% more experience.",
              highlight: true),
        .init(icon: "dollarsign.circle.fill", title: "+20% Gold from all sources",
              description: "Earn more gold from battles, dungeons, daily quests, and Gold Mine.",
              highlight: true),
        .init(icon: "shield.lefthalf.filled", title: "5 Free PvP fights per day",
              description: "Two extra stamina-free arena fights daily (up from 3).",
              highlight: false),
        .init(icon: "clock.arrow.circlepath", title: "Faster stamina regeneration",
              description: "Stamina regens every 6 minutes instead of 8. Get back into battle sooner.",
              highlight: true),
        .init(icon: "paintbrush.pointed.fill", title: "Exclusive premium cosmetics",
              description: "Access unique frames, titles, and visual effects only for Premium players.",
              highlight: false),
        .init(icon: "person.crop.rectangle.stack.fill", title: "Priority matchmaking",
              description: "Shorter queue times when finding PvP opponents.",
              highlight: false),
        .init(icon: "star.circle.fill", title: "Premium badge on profile",
              description: "Show off your Premium status with a golden crown next to your name.",
              highlight: false),
        .init(icon: "gift.fill", title: "Daily bonus reward",
              description: "Extra 50 gold added to your daily login rewards every day.",
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(DarkFantasyTheme.premiumPink)
                        .font(.system(size: 16))
                    Text("PREMIUM")
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
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
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DarkFantasyTheme.premiumPink, DarkFantasyTheme.goldBright],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("BECOME PREMIUM")
                .font(DarkFantasyTheme.title(size: LayoutConstants.textScreen))
                .foregroundStyle(DarkFantasyTheme.premiumPink)

            Text("One-time purchase. Premium forever.")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            // Price pill
            HStack(spacing: LayoutConstants.spaceXS) {
                Text("JUST")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Text(price)
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(.white)
                Text("ONE TIME")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
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
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.goldBright)

            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Feature")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Free")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .frame(width: 60)
                    Text("Premium")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.premiumPink)
                        .frame(width: 70)
                }
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.vertical, LayoutConstants.spaceSM)
                .background(DarkFantasyTheme.bgTertiary)

                // Comparison rows
                ComparisonRow(label: "XP Bonus", free: "0%", premium: "+20%")
                ComparisonRow(label: "Gold Bonus", free: "0%", premium: "+20%")
                ComparisonRow(label: "Free PvP/day", free: "3", premium: "5")
                ComparisonRow(label: "Stamina Regen", free: "8 min", premium: "6 min")
                ComparisonRow(label: "Cosmetics", free: "Basic", premium: "Exclusive")
                ComparisonRow(label: "Daily Bonus", free: "—", premium: "+50 Gold")
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
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: LayoutConstants.buttonHeightLG)
                } else {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18))
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
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textDanger)
                    .multilineTextAlignment(.center)
            }

            // Restore
            Button {
                Task {
                    await StoreKitService.shared.restorePurchases()
                    if StoreKitService.shared.isPremium {
                        // Re-verify with server
                        appState.invalidateCache("character")
                        appState.showToast("Premium restored!", type: .reward)
                    } else {
                        appState.showToast("No Premium purchase found.", type: .error)
                    }
                }
            } label: {
                Text("RESTORE PURCHASE")
            }
            .buttonStyle(.ghost)

            // Legal
            Text("One-time purchase. No subscriptions. No recurring charges.")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
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
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DarkFantasyTheme.premiumPink, DarkFantasyTheme.goldBright],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("WELCOME TO PREMIUM!")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textScreen))
                    .foregroundStyle(DarkFantasyTheme.premiumPink)

                Text("All Premium benefits are now active.\nEnjoy your enhanced adventure!")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
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
        withAnimation { purchaseState = .purchasing(packageId: "premium_forever") }

        Task {
            do {
                let transaction = try await StoreKitService.shared.purchase(productId: productId)
                // Verify with server — server sets premium_until on user
                let body = IAPVerifyRequest(
                    productId: "premium_forever",
                    transactionId: String(transaction.id),
                    receiptData: String(transaction.id)
                )
                let _: IAPVerifyResponse = try await APIClient.shared.post("/api/iap/verify", body: body)

                await MainActor.run {
                    withAnimation {
                        purchaseState = .success(packageId: "premium_forever")
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
            Image(systemName: feature.icon)
                .font(.system(size: 20))
                .foregroundStyle(feature.highlight ? DarkFantasyTheme.goldBright : DarkFantasyTheme.premiumPink)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(feature.highlight
                              ? DarkFantasyTheme.goldBright.opacity(0.1)
                              : DarkFantasyTheme.premiumPink.opacity(0.1))
                )

            // Text
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(feature.title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(feature.highlight ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary)

                Text(feature.description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
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
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(free)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .frame(width: 60)
            Text(premium)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.premiumPink)
                .frame(width: 70)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(DarkFantasyTheme.bgSecondary.opacity(0.3))
    }
}
